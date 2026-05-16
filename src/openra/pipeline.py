"""
ValidationPipeline — top-level orchestrator that wires together all
components and executes the full validation workflow.

Workflow
--------
  1. Parse the paper (PaperParser)
  2. Extract claims and dataset references (ClaimExtractor)
  3. Resolve the dataset: registry lookup → manual reference → raise
  4. Download the dataset (DatasetDownloader)
  5. Generate reproduction code (CodeGenerator)
  6. Execute the code (CodeExecutor)
      - On failure, call CodeGenerator.refine and retry up to N times
  7. Compare results (ResultComparator)
  8. Build and return a ValidationReport (ValidationReporter)

The pipeline is intentionally linear and stateless — each call to
``validate`` is independent.  For batch validation, call it in a loop
or use a process pool.
"""

from __future__ import annotations

import re
from pathlib import Path

from openra.codegen.docker_executor import DockerExecutor
from openra.codegen.executor import CodeExecutor
from openra.codegen.generator import CodeGenerator
from openra.dataset.downloader import DatasetDownloader
from openra.dataset.registry import DatasetRegistry
from openra.models import DatasetReference, ExecutionResult, ValidationReport
from openra.paper.extractor import ClaimExtractor
from openra.paper.parser import PaperParser
from openra.validation.comparator import ResultComparator
from openra.validation.reporter import ValidationReporter


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
        broken code before giving up and recording a failed execution.
    """

    def __init__(
        self,
        parser: PaperParser,
        extractor: ClaimExtractor,
        downloader: DatasetDownloader,
        registry: DatasetRegistry,
        generator: CodeGenerator,
        executor: CodeExecutor,
        comparator: ResultComparator,
        reporter: ValidationReporter,
        max_refinements: int = 3,
    ) -> None:
        self.parser = parser
        self.extractor = extractor
        self.downloader = downloader
        self.registry = registry
        self.generator = generator
        self.executor = executor
        self.comparator = comparator
        self.reporter = reporter
        self.max_refinements = max_refinements

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def validate(self, paper_source: str | Path) -> ValidationReport:
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
        """
        # Step 1: parse the paper
        paper = self._parse_paper(paper_source)

        # Step 2: extract claims
        paper.claims = self.extractor.extract_claims(paper)

        # Step 3: extract dataset references
        paper.dataset_references = self.extractor.extract_dataset_references(paper)

        # Step 4: extract methodology summary
        paper.methodology_summary = self.extractor.extract_methodology(paper)

        # Step 5: resolve dataset reference
        ref = self._resolve_dataset(paper.dataset_references)

        # Step 6: download dataset
        dataset = self.downloader.download(ref)

        # Step 7: generate and execute code (with refinement)
        code, exec_result = self._run_with_refinement(paper, dataset)

        # Step 8: compare results
        claim_results = self.comparator.compare_all(paper.claims, exec_result.outputs)

        # Step 9: build report
        return self.reporter.build(paper, dataset, exec_result, claim_results)

    def validate_with_known_dataset(
        self,
        paper_source: str | Path,
        dataset_reference: DatasetReference,
    ) -> ValidationReport:
        """Like ``validate``, but skip dataset auto-detection and use the
        provided reference instead.

        Useful when the automatic extractor cannot find the dataset or
        when you want to test with a specific dataset version.
        """
        # Step 1: parse the paper
        paper = self._parse_paper(paper_source)

        # Step 2: extract claims
        paper.claims = self.extractor.extract_claims(paper)

        # Step 3: extract methodology summary (skip dataset ref extraction)
        paper.methodology_summary = self.extractor.extract_methodology(paper)

        # Step 4: download dataset using the provided reference directly
        dataset = self.downloader.download(dataset_reference)

        # Step 5: generate and execute code (with refinement)
        code, exec_result = self._run_with_refinement(paper, dataset)

        # Step 6: compare results
        claim_results = self.comparator.compare_all(paper.claims, exec_result.outputs)

        # Step 7: build report
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

        raise ValueError(
            f"Could not resolve dataset from references: {[r.name for r in references]}"
        )

    def _run_with_refinement(self, paper, dataset) -> tuple[str, ExecutionResult]:
        """Generate code and execute it, refining on failure.

        Returns ``(final_code, ExecutionResult)``.

        Algorithm:
          1. Call ``generator.generate(paper, dataset)`` to get initial code.
          2. Call ``executor.execute(code, dataset)``.
          3. If ``exit_code != 0`` or ``outputs`` is empty and refinements
             remain, call ``generator.refine(code, error, paper, dataset)``
             and repeat from step 2.
          4. Return the last (code, result) pair regardless of success.
        """
        code = self.generator.generate(paper, dataset)
        result = self.executor.execute(code, dataset)

        for _attempt in range(self.max_refinements):
            if result.exit_code == 0 and result.outputs:
                break
            error = result.stderr or "No RESULT: lines found in output"
            code = self.generator.refine(code, error, paper, dataset)
            result = self.executor.execute(code, dataset)

        # Update the result with the final generated code
        result.generated_code = code
        return code, result

    # ------------------------------------------------------------------
    # Factory
    # ------------------------------------------------------------------

    @classmethod
    def default(
        cls,
        anthropic_api_key: str | None = None,
        use_docker: bool = False,
        docker_image: str = "openra-sandbox:latest",
        docker_memory: str = "4g",
        docker_cpus: float = 1.0,
    ) -> "ValidationPipeline":
        """Create a pipeline with default components.

        Parameters
        ----------
        anthropic_api_key:
            API key for the Anthropic client.  If None, reads
            ``ANTHROPIC_API_KEY`` from the environment.
        use_docker:
            If True, use ``DockerExecutor`` for OS-level sandboxing with
            ``--network none``.  Requires the sandbox image to be built first
            (``make build-sandbox``).  Falls back to ``CodeExecutor`` with a
            warning if Docker is unavailable.
        docker_image:
            Docker image tag used by ``DockerExecutor``.
        docker_memory:
            Memory limit for the Docker container (e.g. ``"4g"``).
        docker_cpus:
            CPU limit for the Docker container.
        """
        import anthropic

        client = anthropic.Anthropic(api_key=anthropic_api_key)

        registry = DatasetRegistry()
        registry.load()

        if use_docker:
            docker_exec = DockerExecutor(
                image=docker_image,
                memory_limit=docker_memory,
                cpu_count=docker_cpus,
            )
            if docker_exec.is_available() and docker_exec.is_image_built():
                executor = docker_exec
            else:
                import warnings
                warnings.warn(
                    "Docker is not available or sandbox image not built; "
                    "falling back to CodeExecutor (subprocess mode). "
                    "Run 'make build-sandbox' to enable Docker isolation.",
                    RuntimeWarning,
                    stacklevel=2,
                )
                executor = CodeExecutor()
        else:
            executor = CodeExecutor()

        return cls(
            parser=PaperParser(),
            extractor=ClaimExtractor(client),
            downloader=DatasetDownloader(),
            registry=registry,
            generator=CodeGenerator(client),
            executor=executor,
            comparator=ResultComparator(),
            reporter=ValidationReporter(),
        )
