"""Tests for token accounting (retally.usage) and the price table (benchmark.pricing)."""

from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import MagicMock

import pytest

from retally.llm_cache import CachingLLMClient
from retally.usage import UsageTracker, UsageTrackingClient
from tests._loaders import REPO_ROOT, load_module_from_path

pricing = load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")


def _response(text="ok", model="claude-opus-4-7", inp=100, out=10, cw=0, cr=None):
    return SimpleNamespace(
        content=[SimpleNamespace(text=text)],
        model=model,
        usage=SimpleNamespace(
            input_tokens=inp,
            output_tokens=out,
            cache_creation_input_tokens=cw,
            cache_read_input_tokens=cr,  # the API may report None
        ),
    )


def _inner(*responses):
    client = MagicMock()
    client.messages.create.side_effect = list(responses)
    return client


def test_tracks_tokens_by_model_and_counts_calls():
    client = UsageTrackingClient(
        _inner(_response(inp=100, out=10, cw=5, cr=7), _response(model="claude-sonnet-4-6", inp=50, out=5))
    )
    client.messages.create(model="claude-opus-4-7", max_tokens=1, messages=[])
    client.messages.create(model="claude-sonnet-4-6", max_tokens=1, messages=[])
    usage = client.tracker.since()
    assert usage["api_calls"] == 2
    assert usage["llm_cache_served"] is False
    assert usage["by_model"]["claude-opus-4-7"] == {
        "input_tokens": 100,
        "output_tokens": 10,
        "cache_creation_input_tokens": 5,
        "cache_read_input_tokens": 7,
        "api_calls": 1,
    }
    assert usage["by_model"]["claude-sonnet-4-6"]["input_tokens"] == 50


def test_llm_cache_hits_are_counted_but_cost_nothing(tmp_path):
    inner = _inner(_response(inp=1000, out=100))
    client = UsageTrackingClient(CachingLLMClient(inner, tmp_path))
    kwargs = {"model": "claude-opus-4-7", "max_tokens": 1, "messages": [{"role": "user", "content": "hi"}]}
    client.messages.create(**kwargs)  # live
    client.messages.create(**kwargs)  # replayed from disk
    assert inner.messages.create.call_count == 1
    usage = client.tracker.since()
    assert usage["api_calls"] == 1
    assert usage["llm_cache_hits"] == 1
    assert usage["llm_cache_served"] is True
    assert usage["by_model"]["claude-opus-4-7"]["input_tokens"] == 1000


def test_since_reports_only_the_delta():
    client = UsageTrackingClient(_inner(_response(inp=100), _response(inp=40)))
    client.messages.create(model="m")
    before = client.tracker.snapshot()
    client.messages.create(model="m")
    delta = client.tracker.since(before)
    assert delta["api_calls"] == 1
    assert delta["by_model"]["claude-opus-4-7"]["input_tokens"] == 40
    assert UsageTracker().since() == {
        "api_calls": 0,
        "llm_cache_hits": 0,
        "llm_cache_served": False,
        "by_model": {},
    }


def test_falls_back_to_request_model_when_response_has_none():
    resp = _response()
    resp.model = None
    client = UsageTrackingClient(_inner(resp))
    client.messages.create(model="claude-haiku-4-5")
    assert "claude-haiku-4-5" in client.tracker.since()["by_model"]


def test_default_pipeline_wraps_its_client(tmp_path):
    from retally.pipeline import ValidationPipeline

    pipeline = ValidationPipeline.default(
        anthropic_api_key="sk-test-offline", use_docker=False, llm_cache_dir=tmp_path
    )
    assert isinstance(pipeline.usage_tracker, UsageTracker)
    client = pipeline.extractor._client
    assert isinstance(client, UsageTrackingClient)
    assert client.tracker is pipeline.usage_tracker
    assert isinstance(client._inner, CachingLLMClient)
    assert pipeline.generator._client is client


# ── Price table ─────────────────────────────────────────────────────────


def test_price_table_rates():
    opus47 = pricing.PRICES["claude-opus-4-7"]
    assert (opus47.input, opus47.output, opus47.cache_write, opus47.cache_read) == (5.0, 25.0, 6.25, 0.5)
    opus55 = pricing.PRICES["claude-opus-5-5"]
    assert (opus55.input, opus55.output, opus55.cache_write, opus55.cache_read) == (4.0, 20.0, 5.0, 0.2)


def test_cost_covers_all_four_token_kinds():
    tokens = {
        "input_tokens": 1_000_000,
        "output_tokens": 1_000_000,
        "cache_creation_input_tokens": 1_000_000,
        "cache_read_input_tokens": 1_000_000,
    }
    assert pricing.cost_of_model_usage("claude-opus-4-7", tokens) == pytest.approx(5 + 25 + 6.25 + 0.5)


def test_dated_snapshot_ids_and_unknown_models():
    assert pricing.price_for("claude-opus-4-7-20260101") is pricing.PRICES["claude-opus-4-7"]
    assert pricing.price_for("claude-opus-5-5") is pricing.PRICES["claude-opus-5-5"]
    usd, unpriced = pricing.estimate({"by_model": {"mystery-model": {"input_tokens": 10}}})
    assert usd == 0 and unpriced == ["mystery-model"]
    assert pricing.priced(None) is None
