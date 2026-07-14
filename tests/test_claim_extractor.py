"""Tests for ClaimExtractor.

These tests use a mock Anthropic client so they do not require API access.
"""

import json
from unittest.mock import MagicMock

import pytest

from openra.models import ClaimType, CodeReferenceSource, DatasetSource, Paper
from openra.paper.extractor import ClaimExtractor


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


def test_extract_claims_returns_list(paper_with_text):
    response = json.dumps(
        [
            {
                "description": "test accuracy",
                "value": 87.3,
                "unit": "%",
                "claim_type": "accuracy",
                "context": "Our method achieves a test accuracy of 87.3%",
                "table_ref": "Table 1",
                "figure_ref": None,
            }
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    claims = extractor.extract_claims(paper_with_text)
    assert len(claims) >= 1
    assert any(abs(c.value - 87.3) < 0.01 for c in claims)


def test_extract_claims_maps_claim_type(paper_with_text):
    response = json.dumps(
        [
            {
                "description": "AUC",
                "value": 0.91,
                "unit": None,
                "claim_type": "auc_roc",
                "context": "",
                "table_ref": None,
                "figure_ref": None,
            }
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    claims = extractor.extract_claims(paper_with_text)
    assert claims[0].claim_type == ClaimType.AUC_ROC


def test_extract_claims_unknown_type_falls_back_to_other(paper_with_text):
    response = json.dumps(
        [
            {
                "description": "something weird",
                "value": 42.0,
                "unit": None,
                "claim_type": "totally_unknown_metric",
                "context": "",
                "table_ref": None,
                "figure_ref": None,
            }
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    claims = extractor.extract_claims(paper_with_text)
    assert claims[0].claim_type == ClaimType.OTHER


def test_extract_dataset_references(paper_with_text):
    response = json.dumps(
        [
            {
                "name": "UCI Adult",
                "source": "uci",
                "url": None,
                "description": "UCI Adult Income dataset",
                "access_instructions": None,
            }
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    refs = extractor.extract_dataset_references(paper_with_text)
    assert len(refs) >= 1
    assert refs[0].source == DatasetSource.UCI


def test_parse_json_strips_markdown_fences():
    client = MagicMock()
    extractor = ClaimExtractor(client)
    raw = '```json\n[{"a": 1}]\n```'
    result = extractor._parse_json_response(raw)
    assert result == [{"a": 1}]


def test_parse_json_strips_plain_fences():
    client = MagicMock()
    extractor = ClaimExtractor(client)
    raw = '```\n[{"x": 2}]\n```'
    result = extractor._parse_json_response(raw)
    assert result == [{"x": 2}]


def test_parse_json_raises_on_invalid():
    client = MagicMock()
    extractor = ClaimExtractor(client)
    with pytest.raises(ValueError):
        extractor._parse_json_response("not json at all")


def test_parse_json_salvages_truncated_array():
    """A response truncated mid-array (e.g. at max_tokens) should still
    yield every complete object rather than raising."""
    client = MagicMock()
    extractor = ClaimExtractor(client)
    # Well-formed first two objects, third cut off mid-value.
    raw = (
        '[\n{"description": "c1", "value": 3.7},\n'
        '{"description": "c2", "value": 1.2},\n'
        '{"description": "c3", "val'
    )
    result = extractor._parse_json_response(raw)
    assert result == [
        {"description": "c1", "value": 3.7},
        {"description": "c2", "value": 1.2},
    ]


def test_parse_json_salvages_truncated_fenced_array():
    """Truncation inside a markdown-fenced array (no closing fence) still salvages."""
    client = MagicMock()
    extractor = ClaimExtractor(client)
    raw = '```json\n[{"a": 1}, {"b": 2}, {"c":'
    result = extractor._parse_json_response(raw)
    assert result == [{"a": 1}, {"b": 2}]


# ── extract_hyperparameters ─────────────────────────────────────────────


def test_extract_hyperparameters_returns_specs(paper_with_text):
    response = json.dumps(
        [
            {
                "name": "C",
                "value": 1.0,
                "context": "We use logistic regression with C=1.0.",
                "source_ref": "§3.2",
            },
            {
                "name": "test_size",
                "value": 0.2,
                "context": "80/20 stratified train/test split.",
                "source_ref": None,
            },
            {
                "name": "hidden_layer_sizes",
                "value": [32],
                "context": "One hidden layer of 32 units.",
                "source_ref": "Table 1",
            },
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    specs = extractor.extract_hyperparameters(paper_with_text)

    assert [s.name for s in specs] == ["C", "test_size", "hidden_layer_sizes"]
    assert specs[0].value == 1.0
    assert specs[1].value == 0.2
    assert specs[2].value == [32]
    assert specs[0].source_ref == "§3.2"
    assert specs[1].source_ref is None


def test_extract_hyperparameters_empty_list(paper_with_text):
    # Many papers genuinely don't state any hyperparameters; the
    # extractor must not crash and must return [].
    client = _make_mock_client("[]")
    extractor = ClaimExtractor(client)
    assert extractor.extract_hyperparameters(paper_with_text) == []


def test_extract_hyperparameters_skips_malformed_entries(paper_with_text):
    # An entry with no name is unusable downstream and must be dropped.
    response = json.dumps(
        [
            {"name": "", "value": 1.0, "context": ""},  # empty name → skip
            {"name": "C", "value": 1.0, "context": "C=1.0"},
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    specs = extractor.extract_hyperparameters(paper_with_text)
    assert [s.name for s in specs] == ["C"]


def test_extract_hyperparameters_handles_markdown_fenced_response(paper_with_text):
    raw = '```json\n[{"name": "C", "value": 1.0, "context": "C=1.0"}]\n```'
    client = _make_mock_client(raw)
    extractor = ClaimExtractor(client)
    specs = extractor.extract_hyperparameters(paper_with_text)
    assert len(specs) == 1
    assert specs[0].name == "C"


# ── extract_code_references ─────────────────────────────────────────────


def test_extract_code_references_returns_refs(paper_with_text):
    response = json.dumps(
        [
            {
                "url": "https://github.com/openai/baselines",
                "source": "github",
                "description": "Reference implementation at github.com/openai/baselines.",
            },
            {
                "url": "https://gitlab.com/research/repo",
                "source": "gitlab",
                "description": "Companion code at gitlab.com/research/repo.",
            },
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    refs = extractor.extract_code_references(paper_with_text)

    assert [r.url for r in refs] == [
        "https://github.com/openai/baselines",
        "https://gitlab.com/research/repo",
    ]
    assert refs[0].source is CodeReferenceSource.GITHUB
    assert refs[1].source is CodeReferenceSource.GITLAB


def test_extract_code_references_empty_list(paper_with_text):
    # Most older papers don't link code; the extractor must not crash
    # and must return [].
    client = _make_mock_client("[]")
    extractor = ClaimExtractor(client)
    assert extractor.extract_code_references(paper_with_text) == []


def test_extract_code_references_unknown_source_defaults_to_unknown(paper_with_text):
    # If the LLM emits a source value we don't recognise, fall back to
    # UNKNOWN rather than dropping the reference.  The downloader will
    # then skip it, but the reporter still surfaces it.
    response = json.dumps(
        [
            {
                "url": "https://example.com/code.zip",
                "source": "sourceforge",  # not in the enum
                "description": "Older paper hosted code on sourceforge.",
            }
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    refs = extractor.extract_code_references(paper_with_text)
    assert len(refs) == 1
    assert refs[0].source is CodeReferenceSource.UNKNOWN


def test_extract_code_references_skips_empty_url(paper_with_text):
    response = json.dumps(
        [
            {"url": "", "source": "github", "description": "empty"},
            {"url": "https://github.com/x/y", "source": "github", "description": "ok"},
        ]
    )
    client = _make_mock_client(response)
    extractor = ClaimExtractor(client)
    refs = extractor.extract_code_references(paper_with_text)
    assert [r.url for r in refs] == ["https://github.com/x/y"]


def test_extract_code_references_swallows_parse_errors(paper_with_text):
    # If Claude returns prose instead of JSON, the method must return []
    # rather than letting ValueError propagate — code ingestion is
    # opt-in convenience, not load-bearing.
    client = _make_mock_client("Sorry, I cannot answer that.")
    extractor = ClaimExtractor(client)
    assert extractor.extract_code_references(paper_with_text) == []
