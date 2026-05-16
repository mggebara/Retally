"""Tests for PaperParser."""

from pathlib import Path

import pytest

from openra.models import Paper
from openra.paper.parser import PaperParser

FIXTURES = Path(__file__).parent / "fixtures"


@pytest.fixture
def parser():
    return PaperParser()


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


@pytest.mark.skip(reason="requires fixtures/sample_paper.pdf")
def test_parse_pdf_returns_paper(parser):
    pdf_path = FIXTURES / "sample_paper.pdf"
    paper = parser.parse_pdf(pdf_path)
    assert isinstance(paper, Paper)
    assert paper.full_text != ""


@pytest.mark.skip(reason="requires network")
def test_parse_arxiv(parser):
    paper = parser.parse_arxiv("1706.03762")  # Attention Is All You Need
    assert "Attention" in paper.title
