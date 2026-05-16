"""
PaperParser — converts raw paper sources into a Paper dataclass.

Supported input formats:
  - PDF (via PyMuPDF / fitz)
  - Plain text
  - HTML (arXiv abstract pages, publisher pages)
  - arXiv ID (fetches PDF automatically)
  - DOI (resolves to publisher page or PDF)
"""

from __future__ import annotations

import logging
import re
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import fitz  # PyMuPDF
import requests

from openra.models import Paper

logger = logging.getLogger(__name__)


class PaperParser:
    """Converts a raw paper source into a structured Paper object.

    Responsible only for extracting text and coarse structure
    (title, authors, abstract, full body).  Semantic extraction of claims and
    dataset references is handled by ClaimExtractor.
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
        ``source_path`` populated.
        """
        doc = fitz.open(str(path))
        pages = []
        for page in doc:
            pages.append(page.get_text("text"))
        doc.close()
        full_text = "\n\n".join(pages)

        title, authors, abstract = self._extract_metadata_heuristic(full_text)

        return Paper(
            title=title,
            authors=authors,
            abstract=abstract,
            full_text=full_text,
            source_path=path,
        )

    def parse_text(self, text: str, source_path: Path | None = None) -> Paper:
        """Parse a plain-text representation of a paper.

        Parameters
        ----------
        text:
            Full text content of the paper.
        source_path:
            Optional path to record in ``Paper.source_path``.
        """
        title, authors, abstract = self._extract_metadata_heuristic(text)

        return Paper(
            title=title,
            authors=authors,
            abstract=abstract,
            full_text=text,
            source_path=source_path,
        )

    def parse_arxiv(self, arxiv_id: str) -> Paper:
        """Fetch and parse a paper from arXiv by its ID (e.g. '2301.00001').

        Steps:
          1. Fetch metadata from arXiv Atom API.
          2. Download the PDF.
          3. Parse the PDF.
          4. Overwrite title/authors/abstract with API metadata values.
        """
        # Fetch metadata from arXiv Atom API
        api_url = f"https://export.arxiv.org/api/query?id_list={arxiv_id}"
        response = requests.get(api_url, timeout=30)
        response.raise_for_status()

        atom_ns = "http://www.w3.org/2005/Atom"
        root = ET.fromstring(response.text)

        entry = root.find(f"{{{atom_ns}}}entry")
        if entry is None:
            raise ValueError(f"No entry found for arXiv ID: {arxiv_id}")

        title_el = entry.find(f"{{{atom_ns}}}title")
        title = title_el.text.strip() if title_el is not None and title_el.text else ""

        summary_el = entry.find(f"{{{atom_ns}}}summary")
        abstract = summary_el.text.strip() if summary_el is not None and summary_el.text else ""

        authors = []
        for author_el in entry.findall(f"{{{atom_ns}}}author"):
            name_el = author_el.find(f"{{{atom_ns}}}name")
            if name_el is not None and name_el.text:
                authors.append(name_el.text.strip())

        # Download PDF
        pdf_url = f"https://arxiv.org/pdf/{arxiv_id}"
        pdf_response = requests.get(pdf_url, stream=True, timeout=60)
        pdf_response.raise_for_status()

        with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
            for chunk in pdf_response.iter_content(chunk_size=8192):
                tmp.write(chunk)
            tmp_path = Path(tmp.name)

        try:
            paper = self.parse_pdf(tmp_path)
        finally:
            tmp_path.unlink(missing_ok=True)

        # Overwrite with API metadata (more reliable than PDF extraction)
        paper.title = title
        paper.authors = authors
        paper.abstract = abstract
        paper.source_url = f"https://arxiv.org/abs/{arxiv_id}"

        return paper

    def parse_doi(self, doi: str) -> Paper:
        """Resolve a DOI and parse the linked paper.

        Use the Content Negotiation API to get metadata, then attempt to find
        a PDF link.  Fall back to the abstract if no PDF is available.
        """
        doi_url = f"https://doi.org/{doi}"
        headers = {"Accept": "application/vnd.citationstyles.csl+json"}
        response = requests.get(doi_url, headers=headers, timeout=30)
        response.raise_for_status()

        data = response.json()

        # Extract title
        title = data.get("title", "")
        if isinstance(title, list):
            title = title[0] if title else ""

        # Extract authors
        authors = []
        for author in data.get("author", []):
            given = author.get("given", "")
            family = author.get("family", "")
            parts = [p for p in [given, family] if p]
            if parts:
                authors.append(" ".join(parts))

        # Extract abstract if present
        abstract = data.get("abstract", "")

        # Try to find a PDF link in the response
        pdf_url = None
        for link in data.get("link", []):
            content_type = link.get("content-type", "")
            if "pdf" in content_type.lower():
                pdf_url = link.get("URL")
                break

        if pdf_url:
            tmp_path: Path | None = None
            try:
                pdf_response = requests.get(pdf_url, stream=True, timeout=60)
                pdf_response.raise_for_status()
                with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
                    for chunk in pdf_response.iter_content(chunk_size=8192):
                        tmp.write(chunk)
                    tmp_path = Path(tmp.name)
                paper = self.parse_pdf(tmp_path)
                paper.title = title or paper.title
                paper.authors = authors or paper.authors
                paper.abstract = abstract or paper.abstract
                paper.source_url = doi_url
                return paper
            except (requests.RequestException, OSError, ValueError) as exc:
                # PDF fetch / parse failed; log and fall through to the
                # metadata-only paper.  Downstream callers can still see the
                # abstract.
                logger.warning(
                    "DOI %s: failed to fetch or parse linked PDF (%s); returning metadata-only paper.",
                    doi,
                    exc,
                )
            finally:
                if tmp_path is not None:
                    tmp_path.unlink(missing_ok=True)

        # No PDF available — return what we have, using abstract as full_text
        return Paper(
            title=title,
            authors=authors,
            abstract=abstract,
            full_text=abstract,
            source_url=doi_url,
        )

    def parse_url(self, url: str) -> Paper:
        """Fetch a paper from an arbitrary URL and parse it.

        Detect the content type from the response headers:
          - ``application/pdf`` → save to a temp file and call parse_pdf.
          - ``text/html``       → extract visible text, then call parse_text.
        """
        response = requests.get(url, stream=True, timeout=60)
        response.raise_for_status()

        content_type = response.headers.get("Content-Type", "").lower()

        if "application/pdf" in content_type:
            with tempfile.NamedTemporaryFile(suffix=".pdf", delete=False) as tmp:
                for chunk in response.iter_content(chunk_size=8192):
                    tmp.write(chunk)
                tmp_path = Path(tmp.name)
            try:
                paper = self.parse_pdf(tmp_path)
            finally:
                tmp_path.unlink(missing_ok=True)
            paper.source_url = url
            return paper

        else:
            # Treat as HTML — download full content and strip tags
            html = response.text
            # Strip HTML tags
            text = re.sub(r"<[^>]+>", " ", html)
            # Normalize whitespace
            text = re.sub(r"\s+", " ", text).strip()
            paper = self.parse_text(text)
            paper.source_url = url
            return paper

    def _extract_metadata_heuristic(self, text: str) -> tuple[str, list[str], str]:
        """Extract title, authors, and abstract from raw text using heuristics.

        Returns
        -------
        (title, authors, abstract_text)
        """
        lines = [line.strip() for line in text.splitlines() if line.strip()]

        # Title: first non-empty line, truncated to 200 chars
        title = lines[0][:200] if lines else ""

        # Authors: look in lines 1–5 for author-like patterns
        authors: list[str] = []
        author_pattern = re.compile(
            r"(?:[A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)"  # Capitalized words
        )
        for line in lines[1:6]:
            has_email = "@" in line
            # Check for comma-separated capitalized names
            has_capitalized_names = len(author_pattern.findall(line)) >= 2 or (
                "," in line and author_pattern.search(line)
            )
            if has_email or has_capitalized_names:
                # Split on commas and "and"
                raw_authors = re.split(r",|\band\b", line)
                # Strip email addresses and whitespace
                cleaned = []
                for a in raw_authors:
                    a = re.sub(r"\S+@\S+", "", a).strip()
                    if a:
                        cleaned.append(a)
                if cleaned:
                    authors = cleaned
                    break

        # Abstract: find "Abstract" / "ABSTRACT" heading and extract text until
        # the next section heading
        abstract = ""
        abstract_match = re.search(r"(?i)\babstract\b", text)
        if abstract_match:
            after_abstract = text[abstract_match.end() :]
            # Strip leading colon / dash / whitespace
            after_abstract = re.sub(r"^[\s:\-—]+", "", after_abstract)
            # Find the next section heading
            next_section = re.search(
                r"\n\s*(?:1[\.\s]|Introduction\b|I\.\s)",
                after_abstract,
                re.IGNORECASE,
            )
            if next_section:
                abstract = after_abstract[: next_section.start()].strip()
            else:
                # Take up to 1500 chars if no section heading found
                abstract = after_abstract[:1500].strip()
        else:
            # Fallback: join lines 3–8 (index 2–7)
            abstract = " ".join(lines[2:8])

        return title, authors, abstract
