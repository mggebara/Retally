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

from pathlib import Path

from paper_validator.codegen.executor import CodeExecutor
from paper_validator.codegen.generator import CodeGenerator
from paper_validator.dataset.downloader import DatasetDownloader
from paper_validator.dataset.registry import DatasetRegistry
from paper_validator.models import DatasetReference, ValidationReport
from paper_validator.paper.extractor import ClaimExtractor
from paper_validator.paper.parser import PaperParser
from paper_validator.validation.comparator import ResultComparator
from paper_validator.validation.reporter import ValidationReporter


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
        raise NotImplementedError

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
        raise NotImplementedError

    # ------------------------------------------------------------------
    # Internal steps
    # ------------------------------------------------------------------

    def _parse_paper(self, source: str | Path):
        """Dispatch ``source`` to the appropriate PaperParser method.

        See ``validate`` for the dispatch logic.
        """
        raise NotImplementedError

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
        raise NotImplementedError

    def _run_with_refinement(self, paper, dataset) -> tuple[str, object]:
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
        raise NotImplementedError

    # ------------------------------------------------------------------
    # Factory
    # ------------------------------------------------------------------

    @classmethod
    def default(cls, anthropic_api_key: str | None = None) -> "ValidationPipeline":
        """Create a pipeline with default components.

        Parameters
        ----------
        anthropic_api_key:
            API key for the Anthropic client.  If None, the client will
            read ``ANTHROPIC_API_KEY`` from the environment.

        Steps:
          1. Instantiate ``anthropic.Anthropic(api_key=anthropic_api_key)``.
          2. Instantiate each component with its defaults.
          3. Call ``registry.load()`` to populate the dataset registry.
          4. Return a ValidationPipeline instance.
        """
        raise NotImplementedError
