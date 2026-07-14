"""
ValidationPipeline — top-level orchestrator that wires together all
components and executes the full validation workflow.

Workflow
--------
  1. Parse the paper (PaperParser)
  2. Extract claims, dataset references, methodology summary,
     paper-stated hyperparameters, AND any reference-code URLs the
     paper links to (ClaimExtractor)
  3. Resolve and download the dataset (DatasetRegistry +
     DatasetDownloader)
  4. Optionally fetch reference code from any linked GitHub repos
     and select a prompt-friendly subset of source files
     (CodeDownloader + select_relevant_files).  Best-effort: paper
     doesn't link code / git missing / clone fails → no baseline,
     pipeline continues normally.
  5. Generate reproduction code (CodeGenerator), seeded with the
     selected reference files when available
  6. Execute the code (CodeExecutor / DockerExecutor)
      - Phase 1: on Python error or empty output, call
        ``CodeGenerator.refine`` up to ``max_refinements`` times.
      - Phase 2: if the code runs cleanly but any claim is outside
        tolerance, call ``CodeGenerator.refine_for_claims`` up to
        ``max_claim_refinements`` times to close the gap.  Stops early
        on no-progress, identical-code, or refinement-broke-the-code.
  7. Compare results (ResultComparator); per-attempt comparisons happen
     inside step 6 so the loop can decide when to stop.
  8. Audit the final generated code against the paper's stated
     hyperparameters (``validation.hyperparam_audit``).  Independent
     of claim validation: passing claims with mismatched hyperparameters
     is a real signal that the reproduction deviated from the paper.
  9. Build and return a ValidationReport (ValidationReporter), which
     surfaces ``DEVIATION:`` methodology changes the generator declared
     while closing the gap and any non-MATCH hyperparameter audits.

The pipeline is intentionally linear and stateless — each call to
``validate`` is independent.  For batch validation, call it in a loop
or use a process pool.
"""

from __future__ import annotations

import math
import re
from pathlib import Path
from typing import Any

from openra.code.downloader import CodeDownloader
from openra.code.selector import select_relevant_files
from openra.codegen.docker_executor import DEFAULT_R_IMAGE, DockerExecutor, RDockerExecutor
from openra.codegen.executor import CodeExecutor
from openra.codegen.generator import CodeGenerator
from openra.dataset.downloader import DatasetDownloader
from openra.dataset.registry import DatasetRegistry
from openra.models import (
    Claim,
    ClaimValidationResult,
    CodeReference,
    DatasetReference,
    ExecutionResult,
    Language,
    ValidationReport,
)
from openra.paper.extractor import ClaimExtractor
from openra.paper.parser import PaperParser
from openra.validation.comparator import ResultComparator
from openra.validation.hyperparam_audit import audit_hyperparameters
from openra.validation.reporter import ValidationReporter

AnyExecutor = CodeExecutor | DockerExecutor | RDockerExecutor


def _outputs_close(
    a: dict[str, float],
    b: dict[str, float],
    *,
    rel_tol: float = 1e-9,
    abs_tol: float = 1e-9,
) -> bool:
    """Return True if two output dicts agree on every key within numeric tolerance.

    Used by the claim-refinement loop to detect "no progress" without
    treating ordinary float jitter as meaningful change.  Different key
    sets always count as different — a refinement that adds or drops a
    metric is real progress.
    """
    if a.keys() != b.keys():
        return False
    return all(math.isclose(a[k], b[k], rel_tol=rel_tol, abs_tol=abs_tol) for k in a)


class ValidationPipeline:
    """Orchestrates the full paper-validation workflow.

    Parameters
    ----------
    parser, extractor, downloader, registry, generator, executor,
    comparator, reporter:
        Component instances.  Use ``ValidationPipeline.default()`` to get a
        pipeline wired with sensible defaults.
    max_refinements:
        How many times the pipeline will ask the CodeGenerator to fix
        broken code (i.e. ``refine()`` calls) after the initial
        ``generate()``.  Total executions is therefore up to
        ``max_refinements + 1``.
    max_claim_refinements:
        After the initial refinement phase produces a working script,
        OpenRA compares the reproduced values against the paper's
        claims.  If any claim ran but is outside tolerance (a "soft"
        failure), the pipeline asks the generator to close the gap up
        to this many times.  Setting it to 0 disables claim-targeted
        refinement entirely.
    include_code_references:
        When True (default) the pipeline runs an additional LLM pass
        to extract repository URLs from the paper, shallow-clones the
        GitHub ones, and seeds the generator with a selection of files
        from each repo.  Set to False to skip the extra LLM call and
        the clone — useful when running offline, when minimising
        per-paper cost, or when you know the paper doesn't link code.
    code_downloader:
        ``CodeDownloader`` instance.  A default one is constructed if
        omitted.  Injectable mainly for tests.
    """

    def __init__(
        self,
        parser: PaperParser,
        extractor: ClaimExtractor,
        downloader: DatasetDownloader,
        registry: DatasetRegistry,
        generator: CodeGenerator,
        executor: AnyExecutor,
        comparator: ResultComparator,
        reporter: ValidationReporter,
        r_executor: AnyExecutor | None = None,
        max_refinements: int = 3,
        max_claim_refinements: int = 3,
        include_code_references: bool = True,
        code_downloader: CodeDownloader | None = None,
    ) -> None:
        self.parser = parser
        self.extractor = extractor
        self.downloader = downloader
        self.registry = registry
        self.generator = generator
        # ``executor`` is the Python executor (the historical positional name
        # — kept for backwards-compat with tests).  ``r_executor`` is the
        # R-language executor; left None for Python-only pipelines.
        self.executor = executor
        self.r_executor = r_executor
        self.comparator = comparator
        self.reporter = reporter
        self.max_refinements = max_refinements
        self.max_claim_refinements = max_claim_refinements
        self.include_code_references = include_code_references
        self.code_downloader = code_downloader or CodeDownloader()

    def _executor_for(self, language: Language) -> AnyExecutor:
        """Return the executor for ``language``, raising if not configured.

        R papers need ``r_executor`` to be set at construction time.  Python
        papers use ``executor``.  Stata never reaches this method — the
        generator raises ``UnsupportedLanguageError`` first.
        """
        if language is Language.R:
            if self.r_executor is None:
                raise RuntimeError(
                    "This pipeline has no R executor configured.  Construct it via "
                    "ValidationPipeline.default() (which builds an RDockerExecutor "
                    "automatically) or pass r_executor= explicitly."
                )
            return self.r_executor
        return self.executor

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def validate(
        self,
        paper_source: str | Path,
        *,
        dataset_reference: DatasetReference | None = None,
        language: Language | None = None,
        claims: list[Claim] | None = None,
    ) -> ValidationReport:
        """Run the full pipeline on a paper.

        Parameters
        ----------
        paper_source:
            A local file path (PDF or .txt), an arXiv ID, a DOI, or a URL.
            Dispatch logic:
              - Path / str ending in .pdf or .txt → parse as local file
              - Matches r'^\\d{4}\\.\\d{4,5}(v\\d+)?$' → arXiv ID
              - Starts with '10.' → DOI
              - Starts with 'http' → URL
        dataset_reference:
            When provided, the pipeline skips the dataset-extraction LLM
            call and the registry / URL resolution step, and downloads
            this reference directly.  Useful when the extractor cannot
            find the dataset, when you want to pin a specific version,
            or when running without an LLM-detectable dataset mention
            in the paper text.
        language:
            When provided, overrides ``paper.language`` after parsing so
            the generator and executor dispatch to the right runtime
            (Python vs R).  The parser does not infer language from the
            paper text — it always yields ``Language.PYTHON`` — so any
            caller reproducing a non-Python paper (e.g. the benchmark
            runner driving an R catalog entry) must pass this explicitly.
        claims:
            When provided, these claims are used verbatim and the
            claims-extraction LLM call — the single most expensive call
            in the pipeline — is skipped entirely.  Beyond the cost
            saving, pinned claims make repeat runs comparable: the
            extractor can return a slightly different claim set each
            live call, which silently moves the yardstick between runs.
            The benchmark runner passes the catalog's ``original_claims``
            here when an entry has them curated.
        """
        # Step 1: parse the paper
        paper = self._parse_paper(paper_source)
        if language is not None:
            paper.language = language

        # Step 2: extract claims (skipped when the caller pinned them)
        paper.claims = claims if claims is not None else self.extractor.extract_claims(paper)

        # Step 3: extract dataset references (skipped when the caller
        # supplied one — we have nothing to resolve in that case)
        if dataset_reference is None:
            paper.dataset_references = self.extractor.extract_dataset_references(paper)

        # Step 4: extract methodology summary
        paper.methodology_summary = self.extractor.extract_methodology(paper)

        # Step 5: extract paper-stated hyperparameters (consumed post-execution
        # by the AST hyperparameter auditor)
        paper.hyperparameters = self.extractor.extract_hyperparameters(paper)

        # Step 6: extract & download paper-linked reference code (opt-in;
        # silently skipped when include_code_references is False or no
        # repo URLs are found in the paper).
        reference_files = self._fetch_reference_code(paper)

        # Step 7: resolve dataset reference (or use the supplied one verbatim)
        ref = dataset_reference or self._resolve_dataset(paper.dataset_references)

        # Step 8: download dataset
        dataset = self.downloader.download(ref)

        # Step 9: generate, execute, and refine until claims pass or we give up.
        # Comparison happens inside the refinement loop so it can decide when
        # to stop; the returned claim_results reflect the final attempt.
        code, exec_result, claim_results = self._run_with_refinement(paper, dataset, reference_files)

        # Step 10: audit hyperparameters in the final code against the spec
        exec_result.hyperparameter_audits = audit_hyperparameters(code, paper.hyperparameters)

        # Propagate language for the reporter (markdown code-fence tag etc.)
        exec_result.language = paper.language

        # Step 11: build report
        return self.reporter.build(paper, dataset, exec_result, claim_results)

    # ------------------------------------------------------------------
    # Internal steps
    # ------------------------------------------------------------------

    def _parse_paper(self, source: str | Path):
        """Dispatch ``source`` to the appropriate PaperParser method.

        See ``validate`` for the dispatch logic.
        """
        source_str = str(source)

        # URLs must be checked first — parse_url handles PDF/HTML detection internally
        if source_str.startswith("http://") or source_str.startswith("https://"):
            return self.parser.parse_url(source_str)

        # Local PDF file
        if isinstance(source, Path) or source_str.endswith(".pdf"):
            return self.parser.parse_pdf(Path(source))

        # Local plain text file
        if source_str.endswith(".txt"):
            return self.parser.parse_text(Path(source).read_text())

        # arXiv ID, e.g. "2301.00001" or "2301.00001v2"
        if re.match(r"^\d{4}\.\d{4,5}(v\d+)?$", source_str):
            return self.parser.parse_arxiv(source_str)

        # DOI, e.g. "10.1145/1234567.1234568"
        if source_str.startswith("10."):
            return self.parser.parse_doi(source_str)

        # Fall back to treating the string as raw paper text
        return self.parser.parse_text(source_str)

    def _resolve_dataset(self, references: list[DatasetReference]) -> DatasetReference:
        """Choose the best dataset reference to use.

        Algorithm:
          1. For each reference in ``references``, check the registry via
             ``registry.lookup(reference.name)``.
          2. Return the first registry hit (registry entries have been
             validated and have complete download details).
          3. If no registry hit, return the first reference that has a URL.
          4. If still nothing, raise ``ValueError`` with a helpful message
             listing what was found.
        """
        # Pass 1: registry lookup
        for ref in references:
            hit = self.registry.lookup(ref.name)
            if hit:
                return hit

        # Pass 2: first reference with a URL
        for ref in references:
            if ref.url:
                return ref

        raise ValueError(f"Could not resolve dataset from references: {[r.name for r in references]}")

    def _fetch_reference_code(self, paper) -> list:
        """Extract code references, download GitHub ones, select files.

        Three layers of opt-out, in priority order:

        1. ``include_code_references=False`` on the pipeline → no LLM
           call, no clone, empty list returned.
        2. The extractor returns no URLs (the common case for older
           papers) → no clones attempted, empty list.
        3. ``CodeDownloader.download`` fails or returns
           ``local_path=None`` (non-GitHub source, git missing, clone
           failed) → that reference contributes nothing to the file
           list; we move on.

        Files from all successfully-cloned repos are concatenated; the
        selector's MAX_FILES / MAX_TOTAL_BYTES caps apply per repo, not
        across the whole list.  In practice a paper rarely links more
        than one repo.

        Also updates ``paper.code_references`` so the report can show
        the references regardless of whether they cloned successfully.
        """
        if not self.include_code_references:
            return []

        references: list[CodeReference] = self.extractor.extract_code_references(paper)
        if not references:
            paper.code_references = []
            return []

        resolved = self.code_downloader.download_all(references)
        paper.code_references = resolved

        files = []
        for ref in resolved:
            if ref.local_path is None:
                continue
            files.extend(select_relevant_files(ref.local_path))
        return files

    def _run_with_refinement(
        self, paper, dataset, reference_files: list | None = None
    ) -> tuple[str, ExecutionResult, list[ClaimValidationResult]]:
        """Generate code, execute it, and refine until the claims pass or we give up.

        Returns ``(final_code, ExecutionResult, claim_results)``.  The
        ``ExecutionResult.claim_refinement_attempts`` field reports how
        many claim-targeted refinement passes ran; ``deviation_notes``
        captures any methodology changes the generator declared.

        ``reference_files`` (optional) is forwarded only to the initial
        ``generate()`` call.  Refinement prompts deliberately do not
        repaste the reference repo on every call — they have the
        previous code and the specific error/gap to focus on, and the
        reference is already baked into the original generation.

        Two phases:

        **Phase 1 — execution refinement.**  Up to ``max_refinements``
        retries on Python errors or empty output.  Existing behaviour,
        unchanged.

        **Phase 2 — claim-value refinement.**  Once the code runs and
        captures values, compare against claims.  For any claim that
        produced a value but is outside tolerance, ask the generator to
        close the gap.  Stops on any of:

        * All soft-failed claims now pass.
        * ``max_claim_refinements`` attempts reached.
        * Two consecutive runs produced identical outputs (no progress).
        * Generator returned byte-identical code (model giving up).
        * Refinement broke the code (revert and stop).
        """
        executor = self._executor_for(paper.language)

        # ── Phase 1: get a clean execution ────────────────────────────
        code = self.generator.generate(paper, dataset, reference_files=reference_files or None)
        result = executor.execute(code, dataset)

        for _attempt in range(self.max_refinements):
            if result.exit_code == 0 and result.outputs:
                break
            error = result.stderr or "No RESULT: lines found in output"
            code = self.generator.refine(code, error, paper, dataset)
            result = executor.execute(code, dataset)

        # Compare once so we know what (if anything) needs Phase 2.
        claim_results = self.comparator.compare_all(paper.claims, result.outputs)

        # ── Phase 2: close the gap on soft-failed claims ──────────────
        if result.exit_code == 0 and result.outputs and self.max_claim_refinements > 0:
            code, result, claim_results = self._refine_for_failed_claims(
                code, result, claim_results, paper, dataset
            )

        result.generated_code = code
        return code, result, claim_results

    def _refine_for_failed_claims(
        self,
        code: str,
        exec_result: ExecutionResult,
        claim_results: list[ClaimValidationResult],
        paper,
        dataset,
    ) -> tuple[str, ExecutionResult, list[ClaimValidationResult]]:
        """Iteratively narrow the gap between reproduced values and paper claims.

        See :meth:`_run_with_refinement` for the contract and termination
        rules.  This method only runs when Phase 1 produced a working
        script and at least one claim is soft-failed (ran but outside
        tolerance).  A claim with ``reproduced_value is None`` is a hard
        failure and is not targeted here — refining wouldn't help.

        Internally we keep a ``history`` list of every attempt's
        ``outputs`` dict (oldest first).  It serves two purposes:

        * It's passed to ``refine_for_claims`` so the generator can see
          what has already been tried and avoid repeating itself.
        * The no-progress check compares each new attempt against the
          most recent history entry; if the outputs are identical we
          adopt the new code (so any new ``DEVIATION:`` lines surface)
          but stop the loop.
        """
        executor = self._executor_for(paper.language)
        history: list[dict[str, float]] = [dict(exec_result.outputs)]
        attempts = 0

        for _ in range(self.max_claim_refinements):
            soft_failed = [c for c in claim_results if not c.passed and c.reproduced_value is not None]
            if not soft_failed:
                break

            new_code = self.generator.refine_for_claims(
                code, soft_failed, exec_result, paper, dataset, history
            )

            # Model returned the same code → it's signalling that the gap
            # is unreproducible.  Honour the signal and stop.
            if new_code.strip() == code.strip():
                break

            new_result = executor.execute(new_code, dataset)

            # Refinement broke the code.  Revert to the last working
            # state and stop — partial progress beats no progress.
            if new_result.exit_code != 0 or not new_result.outputs:
                break

            attempts += 1

            # No progress: outputs match the previous attempt to within
            # numeric noise.  Plain ``==`` on float dicts is too strict —
            # 0.95000000001 vs 0.95 is the same model run; calling that
            # "progress" wastes a refinement slot on no real change.
            if _outputs_close(new_result.outputs, history[-1]):
                # Still adopt the new code (so deviation notes from this
                # attempt are surfaced) but stop looping.
                code, exec_result = new_code, new_result
                claim_results = self.comparator.compare_all(paper.claims, exec_result.outputs)
                break

            code, exec_result = new_code, new_result
            history.append(dict(exec_result.outputs))
            claim_results = self.comparator.compare_all(paper.claims, exec_result.outputs)

        # Surface the attempt count on the result so reports can show it.
        exec_result.claim_refinement_attempts = attempts

        # Any claim that is still failing should record what we tried so
        # a reader of the final report doesn't wonder whether we just
        # gave up immediately.
        if attempts > 0:
            for cr in claim_results:
                if cr.passed:
                    continue
                suffix = (
                    f" (claim-targeted refinement ran {attempts} time"
                    f"{'s' if attempts != 1 else ''} without closing the gap)"
                )
                cr.notes = (cr.notes + suffix) if cr.notes else suffix.lstrip()

        return code, exec_result, claim_results

    # ------------------------------------------------------------------
    # Factory
    # ------------------------------------------------------------------

    @classmethod
    def default(
        cls,
        anthropic_api_key: str | None = None,
        use_docker: bool = True,
        allow_unsafe_subprocess: bool = False,
        docker_image: str = "openra-sandbox:latest",
        docker_r_image: str = DEFAULT_R_IMAGE,
        docker_memory: str = "4g",
        docker_cpus: float = 1.0,
        llm_cache_dir: Path | None = None,
    ) -> "ValidationPipeline":
        """Create a pipeline with default components.

        Parameters
        ----------
        anthropic_api_key:
            API key for the Anthropic client.  If None, reads
            ``ANTHROPIC_API_KEY`` from the environment.
        use_docker:
            If True (the default), run generated code inside the Docker
            sandbox.  Requires the Python sandbox image to be built first
            (``make build-sandbox``).  If Docker is unavailable, raises a
            ``RuntimeError`` unless ``allow_unsafe_subprocess=True``.
        allow_unsafe_subprocess:
            Opt-in fallback to the subprocess ``CodeExecutor`` when Docker
            is unavailable.  The subprocess executor runs Claude-generated
            code in a plain Python process on the host with only an AST
            preflight guard, which is trivially bypassable — set this to
            True only when you have other isolation (e.g. ephemeral VM,
            container around the pipeline itself) or you are running known
            test code.  Has no effect when ``use_docker=False`` and does
            not apply to R papers (no host R fallback ships).
        docker_image:
            Docker image tag used by the Python ``DockerExecutor``.
        docker_r_image:
            Docker image tag used by ``RDockerExecutor`` for R papers.
            Build with ``make build-r-sandbox``.  Construction is
            unconditional — the image is only required when an R paper
            actually arrives, and the missing-image check happens at
            ``execute()`` time, so Python-only users don't have to build
            the R image.
        docker_memory:
            Memory limit for Docker containers (e.g. ``"4g"``).
        docker_cpus:
            CPU limit for Docker containers.
        llm_cache_dir:
            When set, every Claude call made by the pipeline (extraction,
            generation, refinement) is cached on disk under this
            directory, keyed by the full request content.  Identical
            calls replay from disk instead of hitting the API — which is
            what makes iterating on one pipeline stage affordable: only
            the calls whose prompts actually changed re-run.  Leave None
            (the default) for fully live behaviour.
        """
        import anthropic

        # Duck-typed: every component only calls ``client.messages.create``
        # and reads ``response.content[0].text``, which the caching wrapper
        # preserves exactly.
        client: Any = anthropic.Anthropic(api_key=anthropic_api_key)
        if llm_cache_dir is not None:
            from openra.llm_cache import CachingLLMClient

            client = CachingLLMClient(client, llm_cache_dir)

        registry = DatasetRegistry()
        registry.load()

        executor: AnyExecutor
        if use_docker:
            docker_exec = DockerExecutor(
                image=docker_image,
                memory_limit=docker_memory,
                cpu_count=docker_cpus,
            )
            if docker_exec.is_available() and docker_exec.is_image_built():
                executor = docker_exec
            elif allow_unsafe_subprocess:
                import warnings

                warnings.warn(
                    "Docker is not available or sandbox image not built; "
                    "falling back to CodeExecutor (subprocess mode) because "
                    "allow_unsafe_subprocess=True.  Generated code will run on "
                    "the host with no OS-level isolation.",
                    RuntimeWarning,
                    stacklevel=2,
                )
                executor = CodeExecutor()
            else:
                raise RuntimeError(
                    "Docker is not available or sandbox image not built.  "
                    "Run 'make build-sandbox' to enable the Docker sandbox, or "
                    "pass ValidationPipeline.default(allow_unsafe_subprocess=True) "
                    "to opt into running Claude-generated code on the host without "
                    "OS-level isolation."
                )
        else:
            executor = CodeExecutor()

        # R executor is always constructed when use_docker=True — the
        # availability + image-built checks happen lazily at execute() time
        # via RDockerExecutor's own _require_docker.  This keeps Python-only
        # callers from having to build the R image just to import the
        # pipeline.  When use_docker=False there is no R path at all (no
        # subprocess R executor ships); r_executor stays None and an R
        # paper raises a clear error from _executor_for.
        r_executor: AnyExecutor | None = None
        if use_docker:
            r_executor = RDockerExecutor(
                image=docker_r_image,
                memory_limit=docker_memory,
                cpu_count=docker_cpus,
            )

        return cls(
            parser=PaperParser(),
            extractor=ClaimExtractor(client),
            downloader=DatasetDownloader(),
            registry=registry,
            generator=CodeGenerator(client),
            executor=executor,
            r_executor=r_executor,
            comparator=ResultComparator(),
            reporter=ValidationReporter(),
        )
