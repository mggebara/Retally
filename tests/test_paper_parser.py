"""Tests for PaperParser."""

import fitz
import pytest

from retally.models import Paper
from retally.paper.parser import PaperParser


@pytest.fixture
def parser():
    return PaperParser()


@pytest.fixture
def sample_pdf(tmp_path):
    """Build a one-page PDF programmatically with fitz.

    Keeps the test fully hermetic — no committed binary fixture, no
    network — while still exercising the PyMuPDF code path that the
    plain-text tests skip.
    """
    pdf_path = tmp_path / "sample.pdf"
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((72, 72), "Sample Paper Title")
    page.insert_text((72, 100), "Jane Doe, John Smith")
    page.insert_text((72, 140), "Abstract")
    page.insert_text((72, 160), "This is a one-sentence abstract for testing PDF parsing.")
    page.insert_text((72, 200), "1 Introduction")
    page.insert_text((72, 220), "Body content follows here.")
    doc.save(str(pdf_path))
    doc.close()
    return pdf_path


def test_parse_text_extracts_title(parser):
    text = "My Paper Title\nAuthor One, Author Two\n\nAbstract\nThis is the abstract.\n"
    paper = parser.parse_text(text)
    assert "My Paper Title" in paper.title


def test_parse_text_extracts_abstract(parser):
    text = "Title\n\nAbstract\nThis paper studies X.\n\n1 Introduction\nMore text."
    paper = parser.parse_text(text)
    assert "studies X" in paper.abstract


def test_parse_text_returns_paper(parser):
    text = "Some Paper\nJohn Smith\n\nAbstract\nWe study things.\n"
    paper = parser.parse_text(text)
    assert isinstance(paper, Paper)
    assert paper.full_text == text


def test_parse_text_with_source_path(parser, tmp_path):
    txt = tmp_path / "paper.txt"
    txt.write_text("Title\nAuthor\n\nAbstract\nSome content.\n")
    paper = parser.parse_text(txt.read_text(), source_path=txt)
    assert paper.source_path == txt


def test_parse_pdf_returns_paper(parser, sample_pdf):
    paper = parser.parse_pdf(sample_pdf)
    assert isinstance(paper, Paper)
    assert paper.full_text != ""
    assert "Sample Paper Title" in paper.full_text
    assert paper.source_path == sample_pdf


def test_parse_pdf_extracts_title_from_first_line(parser, sample_pdf):
    paper = parser.parse_pdf(sample_pdf)
    assert "Sample Paper Title" in paper.title


def test_parse_pdf_extracts_abstract(parser, sample_pdf):
    paper = parser.parse_pdf(sample_pdf)
    assert "one-sentence abstract" in paper.abstract


@pytest.mark.skip(reason="requires network")
def test_parse_arxiv(parser):
    paper = parser.parse_arxiv("1706.03762")  # Attention Is All You Need
    assert "Attention" in paper.title


class _FakeResponse:
    """Minimal stand-in for a streamed ``requests.Response``."""

    def __init__(self, body: bytes, content_type: str):
        self.headers = {"Content-Type": content_type}
        self.content = body
        self.text = body.decode("utf-8", errors="replace")

    def raise_for_status(self):
        return None


def test_parse_url_sniffs_pdf_served_as_octet_stream(parser, sample_pdf, monkeypatch):
    # CaltechAUTHORS serves PDFs as application/octet-stream; the %PDF
    # magic bytes, not the header, must route the body to parse_pdf.
    body = sample_pdf.read_bytes()
    monkeypatch.setattr(
        "retally.paper.parser.http_get",
        lambda url, **kw: _FakeResponse(body, "application/octet-stream"),
    )
    paper = parser.parse_url("https://example.org/record/files/paper.pdf/content")
    assert paper.title == "Sample Paper Title"
    assert "Body content follows here." in paper.full_text
    assert "%PDF" not in paper.full_text
    assert paper.source_url == "https://example.org/record/files/paper.pdf/content"


def test_parse_url_octet_stream_without_pdf_magic_is_text(parser, monkeypatch):
    html = b"<html><body><p>Hello paper</p></body></html>"
    monkeypatch.setattr(
        "retally.paper.parser.http_get",
        lambda url, **kw: _FakeResponse(html, "application/octet-stream"),
    )
    paper = parser.parse_url("https://example.org/page")
    assert paper.full_text == "Hello paper"
