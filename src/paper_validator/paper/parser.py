"""
PaperParser — converts raw paper sources into a Paper dataclass.

Supported input formats (to be implemented):
  - PDF (via PyMuPDF / fitz)
  - Plain text
  - HTML (arXiv abstract pages, publisher pages)
  - arXiv ID (fetches PDF automatically)
  - DOI (resolves to publisher page or PDF)
"""

from __future__ import annotations

from pathlib import Path

from paper_validator.models import Paper


class PaperParser:
    """Converts a raw paper source into a structured Paper object.

    This class is responsible only for extracting text and coarse structure
    (title, authors, abstract, full body).  Semantic extraction of claims and
    dataset references is handled by ClaimExtractor.

    Implementation notes
    --------------------
    - For PDF parsing, use ``import fitz`` (PyMuPDF).  Extract text with
      ``page.get_text("text")`` and attempt heuristic section detection
      (look for all-caps or bold headings) to separate abstract, intro, etc.
    - For arXiv IDs, hit the arXiv export API
      (``https://export.arxiv.org/abs/<id>``) and parse the HTML, then
      download the PDF from ``https://arxiv.org/pdf/<id>``.
    - For DOIs, resolve via ``https://doi.org/<doi>`` and handle redirects.
    """

    def parse_pdf(self, path: Path) -> Paper:
        """Parse a PDF file and return a Paper.

        Parameters
        ----------
        path:
            Local path to the PDF file.

        Returns
        -------
        Paper with ``full_text``, ``title``, ``authors``, ``abstract``, and
        ``source_path`` populated.  ``claims`` and ``dataset_references`` are
        left empty — run ClaimExtractor afterwards.
        """
        raise NotImplementedError

    def parse_text(self, text: str, source_path: Path | None = None) -> Paper:
        """Parse a plain-text representation of a paper.

        Useful for testing or when the PDF has already been converted.  Apply
        simple heuristics to identify the title (first non-empty line), authors,
        and abstract (text between "Abstract" and the first section heading).

        Parameters
        ----------
        text:
            Full text content of the paper.
        source_path:
            Optional path to record in ``Paper.source_path``.
        """
        raise NotImplementedError

    def parse_arxiv(self, arxiv_id: str) -> Paper:
        """Fetch and parse a paper from arXiv by its ID (e.g. '2301.00001').

        Steps:
          1. Download the abstract page from the arXiv export API to get
             metadata (title, authors, abstract).
          2. Download the PDF from ``https://arxiv.org/pdf/<arxiv_id>``.
          3. Call ``self.parse_pdf`` on the downloaded PDF.
          4. Overwrite title/authors/abstract with the metadata values, which
             are more reliable than PDF extraction.
        """
        raise NotImplementedError

    def parse_doi(self, doi: str) -> Paper:
        """Resolve a DOI and parse the linked paper.

        Use the Content Negotiation API (Accept: application/json) to get
        metadata, then attempt to find a PDF link.  Fall back to parse_text
        if only HTML is available.
        """
        raise NotImplementedError

    def parse_url(self, url: str) -> Paper:
        """Fetch a paper from an arbitrary URL and parse it.

        Detect the content type from the response headers:
          - ``application/pdf`` → save to a temp file and call parse_pdf.
          - ``text/html``       → extract visible text with BeautifulSoup,
                                  then call parse_text.
        """
        raise NotImplementedError
