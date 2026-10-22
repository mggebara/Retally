"""Tests for ``retally.llm``: model defaults, effort options, response text."""

from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest

from retally import llm
from retally.codegen.generator import CodeGenerator
from retally.llm import request_options, response_text
from retally.llm_cache import CachingLLMClient
from retally.paper.extractor import ClaimExtractor


def _thinking_first(text: str, *, stop_reason: str = "end_turn") -> SimpleNamespace:
    """A live Opus 5.5-shaped response: thinking block, then the text block."""
    return SimpleNamespace(
        content=[
            SimpleNamespace(type="thinking", thinking="", signature="sig"),
            SimpleNamespace(type="text", text=text),
        ],
        stop_reason=stop_reason,
        model="claude-opus-5-5",
    )


# ── defaults ─────────────────────────────────────────────────────────────


def test_defaults():
    assert llm.DEFAULT_MODEL == "claude-opus-5-5"
    assert llm.DEFAULT_GENERATION_EFFORT == "high"
    assert llm.DEFAULT_EXTRACTION_EFFORT == "medium"
    assert llm.LEGACY_MODEL == "claude-opus-4-7"


def test_request_options():
    assert request_options(None) == {}
    assert request_options("high") == {"output_config": {"effort": "high"}}


# ── response_text ─────────────────────────────────────────────────────────


def test_response_text_skips_the_thinking_block():
    assert response_text(_thinking_first("answer")) == "answer"


def test_response_text_accepts_duck_typed_blocks_without_a_type():
    """The LLM cache's replay object and MagicMock-based test doubles."""
    assert response_text(SimpleNamespace(content=[SimpleNamespace(text="replay")])) == "replay"
    assert response_text(SimpleNamespace(content=[MagicMock(text="mocked")])) == "mocked"


def test_response_text_never_returns_a_thinking_blocks_text():
    thinking_only = SimpleNamespace(
        content=[SimpleNamespace(type="thinking", thinking="…", text="not the answer")],
        stop_reason="max_tokens",
    )
    with pytest.raises(ValueError, match="no text block"):
        response_text(thinking_only)


def test_response_text_raises_on_empty_content():
    with pytest.raises(ValueError, match="refusal"):
        response_text(SimpleNamespace(content=[], stop_reason="refusal"))
    with pytest.raises(ValueError):
        response_text(SimpleNamespace(content=None))


# ── components send effort and read past the thinking block ───────────────


def _client(response):
    client = MagicMock()
    client.messages.create.return_value = response
    return client


def test_generator_sends_model_effort_and_reads_the_text_block():
    client = _client(_thinking_first("```r\ncat('RESULT:x=1\\n')\n```"))
    gen = CodeGenerator(client)
    assert gen._call_claude("prompt") == "```r\ncat('RESULT:x=1\\n')\n```"
    kwargs = client.messages.create.call_args.kwargs
    assert kwargs["model"] == "claude-opus-5-5"
    assert kwargs["output_config"] == {"effort": "high"}
    assert kwargs["max_tokens"] == 16384
    assert "thinking" not in kwargs  # Opus 5.5: omit → adaptive; "disabled" would 400


def test_generator_effort_none_sends_no_output_config():
    client = _client(_thinking_first("x"))
    CodeGenerator(client, model="claude-opus-4-7", effort=None)._call_claude("p")
    kwargs = client.messages.create.call_args.kwargs
    assert kwargs["model"] == "claude-opus-4-7"
    assert "output_config" not in kwargs


def test_extractor_sends_model_effort_and_reads_the_text_block():
    client = _client(_thinking_first("[]"))
    ext = ClaimExtractor(client)
    assert ext._call_claude("prompt") == "[]"
    kwargs = client.messages.create.call_args.kwargs
    assert kwargs["model"] == "claude-opus-5-5"
    assert kwargs["output_config"] == {"effort": "medium"}
    assert kwargs["max_tokens"] == 16384


def test_llm_cache_persists_the_text_of_a_thinking_first_response(tmp_path):
    inner = _client(_thinking_first("cached answer"))
    client = CachingLLMClient(inner, tmp_path)
    kwargs = {
        "model": "claude-opus-5-5",
        "max_tokens": 100,
        "messages": [{"role": "user", "content": "hi"}],
        "output_config": {"effort": "high"},
    }
    first = client.messages.create(**kwargs)
    assert response_text(first) == "cached answer"
    replay = client.messages.create(**kwargs)
    assert replay.from_llm_cache is True
    assert replay.content[0].type == "text"
    assert response_text(replay) == "cached answer"
    assert inner.messages.create.call_count == 1


def test_llm_cache_keys_on_effort(tmp_path):
    inner = _client(_thinking_first("answer"))
    client = CachingLLMClient(inner, tmp_path)
    base = {"model": "claude-opus-5-5", "max_tokens": 10, "messages": [{"role": "user", "content": "q"}]}
    client.messages.create(**base, output_config={"effort": "low"})
    client.messages.create(**base, output_config={"effort": "high"})
    assert inner.messages.create.call_count == 2


def test_default_pipeline_passes_the_model_to_both_components(tmp_path):
    from retally.pipeline import ValidationPipeline

    pipeline = ValidationPipeline.default(
        anthropic_api_key="sk-test-offline", use_docker=False, model="claude-opus-4-7"
    )
    assert pipeline.extractor._model == "claude-opus-4-7"
    assert pipeline.generator._model == "claude-opus-4-7"
    default = ValidationPipeline.default(anthropic_api_key="sk-test-offline", use_docker=False)
    assert default.generator._model == llm.DEFAULT_MODEL
