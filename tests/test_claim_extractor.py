"""Tests for ClaimExtractor.

These tests use a mock Anthropic client so they do not require API access.
"""

import json
import pytest
from unittest.mock import MagicMock

from paper_validator.paper.extractor import ClaimExtractor
from paper_validator.models import Claim, ClaimType, DatasetSource, Paper


def _make_mock_client(response_text: str):
    """Build a minimal mock that mimics anthropic.Anthropic.messages.create."""
    msg = MagicMock()
    msg.content = [MagicMock(text=response_text)]
    client = MagicMock()
    client.messages.create.return_value = msg
    return client


@pytest.fixture
def paper_with_text():
    return Paper(
        title="A Classification Study",
        full_text=(
            "We evaluate our model on the UCI Adult dataset. "
            "Our method achieves a test accuracy of 87.3% and an F1 score of 0.842 "
            "as shown in Table 1."
        ),
    )


@pytest.mark.skip(reason="not implemented")
def test_extract_claims_returns_list(paper_with_text):
    response = json.dumps([
        {
            "description": "test accuracy",
            "value": 87.3,
            "unit": "%",
            "claim_type": "accuracy",
            "context": "Our method achieves a test accuracy of 87.3%",
            "table_ref": "Table 1",
            "figure_ref": None,
        }
    ])
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    claims = extractor.extract_claims(paper_with_text)
    assert len(claims) >= 1
    assert any(abs(c.value - 87.3) < 0.01 for c in claims)


@pytest.mark.skip(reason="not implemented")
def test_extract_dataset_references(paper_with_text):
    response = json.dumps([
        {
            "name": "UCI Adult",
            "source": "uci",
            "url": None,
            "description": "UCI Adult Income dataset",
            "access_instructions": None,
        }
    ])
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    refs = extractor.extract_dataset_references(paper_with_text)
    assert len(refs) >= 1
    assert refs[0].source == DatasetSource.UCI


@pytest.mark.skip(reason="not implemented")
def test_parse_json_strips_markdown_fences():
    client = MagicMock()
    extractor = ClaimExtractor(client)
    raw = "```json\n[{\"a\": 1}]\n```"
    result = extractor._parse_json_response(raw)
    assert result == [{"a": 1}]
