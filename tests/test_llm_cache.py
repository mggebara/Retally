"""Tests for the on-disk LLM call cache."""

from __future__ import annotations

from unittest.mock import MagicMock

from openra.llm_cache import CachingLLMClient


def _mock_inner(text: str = "live response"):
    """A stand-in anthropic client whose messages.create returns ``text``."""
    msg = MagicMock()
    msg.content = [MagicMock(text=text)]
    inner = MagicMock()
    inner.messages.create.return_value = msg
    return inner


def _create_kwargs(prompt: str = "hello", model: str = "claude-opus-4-7"):
    return {
        "model": model,
        "max_tokens": 100,
        "messages": [{"role": "user", "content": prompt}],
    }


def test_miss_hits_live_client_and_persists(tmp_path):
    inner = _mock_inner("first answer")
    client = CachingLLMClient(inner, tmp_path)

    response = client.messages.create(**_create_kwargs())
    assert response.content[0].text == "first answer"
    assert inner.messages.create.call_count == 1
    assert client.stats == {"hits": 0, "misses": 1}
    assert list(tmp_path.glob("*.json")), "cache entry not written"


def test_identical_call_replays_without_live_call(tmp_path):
    inner = _mock_inner("cached answer")
    client = CachingLLMClient(inner, tmp_path)

    client.messages.create(**_create_kwargs())
    response = client.messages.create(**_create_kwargs())

    assert response.content[0].text == "cached answer"
    assert inner.messages.create.call_count == 1  # second call served from disk
    assert client.stats == {"hits": 1, "misses": 1}


def test_cache_survives_client_restart(tmp_path):
    """A fresh wrapper over the same dir sees the previous session's entries —
    that's the whole point: re-running the benchmark replays for free."""
    CachingLLMClient(_mock_inner("persisted"), tmp_path).messages.create(**_create_kwargs())

    fresh_inner = _mock_inner("should not be called")
    fresh = CachingLLMClient(fresh_inner, tmp_path)
    response = fresh.messages.create(**_create_kwargs())

    assert response.content[0].text == "persisted"
    fresh_inner.messages.create.assert_not_called()


def test_different_prompt_is_a_different_key(tmp_path):
    inner = _mock_inner()
    client = CachingLLMClient(inner, tmp_path)
    client.messages.create(**_create_kwargs(prompt="extract claims"))
    client.messages.create(**_create_kwargs(prompt="extract methodology"))
    assert inner.messages.create.call_count == 2
    assert client.stats["misses"] == 2


def test_different_model_is_a_different_key(tmp_path):
    """Same prompt on a different model must not replay the other model's
    answer — model choice changes the response."""
    inner = _mock_inner()
    client = CachingLLMClient(inner, tmp_path)
    client.messages.create(**_create_kwargs(model="claude-opus-4-7"))
    client.messages.create(**_create_kwargs(model="claude-sonnet-4-6"))
    assert inner.messages.create.call_count == 2


def test_corrupt_cache_entry_falls_back_to_live(tmp_path):
    inner = _mock_inner("regenerated")
    client = CachingLLMClient(inner, tmp_path)
    client.messages.create(**_create_kwargs())

    [entry] = tmp_path.glob("*.json")
    entry.write_text("{not json", encoding="utf-8")

    response = client.messages.create(**_create_kwargs())
    assert response.content[0].text == "regenerated"
    assert inner.messages.create.call_count == 2  # corrupt entry treated as miss


def test_unexpected_response_shape_passes_through_uncached(tmp_path):
    """A response without .content[0].text (future API shape, tool use, …)
    must be returned as-is and NOT persisted as a broken entry."""
    weird = MagicMock()
    weird.content = []  # no blocks
    inner = MagicMock()
    inner.messages.create.return_value = weird
    client = CachingLLMClient(inner, tmp_path)

    response = client.messages.create(**_create_kwargs())
    assert response is weird
    assert not list(tmp_path.glob("*.json"))
