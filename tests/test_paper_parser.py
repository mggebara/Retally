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
