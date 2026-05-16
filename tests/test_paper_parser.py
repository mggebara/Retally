"""Tests for PaperParser.

These are integration-style stubs — fill them in as each parse method is
implemented.  Use small fixture files stored under tests/fixtures/.
"""

import pytest
from pathlib import Path

from paper_validator.paper.parser import PaperParser
from paper_validator.models import Paper

FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture
def parser():
    return PaperParser()


@pytest.mark.skip(reason="not implemented")
def test_parse_text_extracts_title(parser):
    text = "My Paper Title\nAuthor One, Author Two\n\nAbstract\nThis is the abstract.\n"
    paper = parser.parse_text(text)
    assert "My Paper Title" in paper.title


@pytest.mark.skip(reason="not implemented")
def test_parse_text_extracts_abstract(parser):
    text = "Title\n\nAbstract\nThis paper studies X.\n\n1 Introduction\nMore text."
    paper = parser.parse_text(text)
    assert "studies X" in paper.abstract


@pytest.mark.skip(reason="not implemented")
def test_parse_pdf_returns_paper(parser):
    pdf_path = FIXTURES / "sample_paper.pdf"
    paper = parser.parse_pdf(pdf_path)
    assert isinstance(paper, Paper)
    assert paper.full_text != ""


@pytest.mark.skip(reason="requires network")
def test_parse_arxiv(parser):
    paper = parser.parse_arxiv("1706.03762")  # Attention Is All You Need
    assert "Attention" in paper.title
