"""Content-addressed on-disk cache for Claude API calls.

Why this exists
---------------
A single benchmark iteration against a real paper re-pays every LLM call
in the pipeline — five extraction calls (the claims call alone sends
~120k chars of paper text) plus generation and up to six refinement
rounds, all on the most capable model.  When the change under test only
touches code generation, the extraction spend is pure waste: same paper,
same prompts, same model, same answer.

``CachingLLMClient`` wraps an ``anthropic.Anthropic`` client and caches
each ``messages.create`` call on disk, keyed by a hash of the full
request (model, max_tokens, messages).  The key covers the entire prompt
text, so invalidation is automatic and exact: edit a prompt template and
only the calls built from that template re-run — everything else replays
from disk for free.

Deliberately NOT handled here:

* TTLs / eviction — the cache lives under ``benchmark/.cache/`` and is
  cleared with ``rm -rf`` when a truly fresh run is wanted.
* Sampling variance — a cached replay is deterministic where a live call
  is not.  For iteration that's a feature (stable yardstick); for
  measuring run-to-run variance, disable the cache.
* Streaming / multi-block responses — the pipeline only ever reads
  ``response.content[0].text``, so that's all we persist.
"""

from __future__ import annotations

import hashlib
import json
import logging
from pathlib import Path
from typing import Any

from retally.llm import response_text

logger = logging.getLogger(__name__)


class _CachedTextBlock:
    """Minimal stand-in for an anthropic text content block."""

    type = "text"

    def __init__(self, text: str) -> None:
        self.text = text


class _CachedResponse:
    """Minimal stand-in for an anthropic Message: one text content block.

    A replay carries only the text — the thinking block a live response
    may have opened with is not persisted — which is all
    ``retally.llm.response_text`` reads.
    """

    from_llm_cache = True
    """Marks a replay: no API call was made, so it carries no ``usage`` and
    costs nothing (``retally.usage`` counts it as a cache hit)."""

    def __init__(self, text: str) -> None:
        self.content = [_CachedTextBlock(text)]


class _CachingMessages:
    """The ``.messages`` attribute of the wrapper — hosts ``create``."""

    def __init__(self, inner_client: Any, cache_dir: Path, stats: dict[str, int]) -> None:
        self._inner = inner_client
        self._cache_dir = cache_dir
        self._stats = stats

    def create(self, **kwargs: Any) -> Any:
        key = _request_key(kwargs)
        path = self._cache_dir / f"{key}.json"

        cached_text = _read_cached_text(path)
        if cached_text is not None:
            self._stats["hits"] += 1
            logger.debug("llm-cache hit %s (model=%s)", key, kwargs.get("model"))
            return _CachedResponse(cached_text)

        self._stats["misses"] += 1
        response = self._inner.messages.create(**kwargs)

        try:
            text = response_text(response)
        except (AttributeError, ValueError):
            # Response shape we don't understand (no text block: a
            # refusal, a tool-use-only reply, …) — pass it through
            # uncached rather than persist something we can't replay.
            logger.warning("llm-cache: uncacheable response shape for %s; not caching", key)
            return response

        _write_cached_text(path, kwargs, text)
        return response


class CachingLLMClient:
    """Wraps an ``anthropic.Anthropic`` client with an on-disk call cache.

    Drop-in for the pipeline's usage of the client — components only
    call ``client.messages.create(...)`` and read the response's text
    block (``retally.llm.response_text``), and that surface is preserved
    exactly.

    Parameters
    ----------
    inner_client:
        The real (or mock) client to delegate cache misses to.
    cache_dir:
        Directory for cache entries (one JSON file per unique request).
        Created on first write.
    """

    def __init__(self, inner_client: Any, cache_dir: Path) -> None:
        self._inner = inner_client
        self.cache_dir = Path(cache_dir)
        self.stats: dict[str, int] = {"hits": 0, "misses": 0}
        self.messages = _CachingMessages(inner_client, self.cache_dir, self.stats)


def _request_key(kwargs: dict[str, Any]) -> str:
    """Stable hash of the full request: model, token cap, effort, and messages.

    Everything that could change the response text must be in here —
    the messages list carries the entire prompt, so editing any prompt
    template naturally produces a new key, and so does a model or
    ``output_config`` change.
    """
    payload = json.dumps(kwargs, sort_keys=True, default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:24]


def _read_cached_text(path: Path) -> str | None:
    """Return the cached response text, or None on miss / corrupt entry."""
    if not path.exists():
        return None
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
        return str(raw["text"])
    except (json.JSONDecodeError, OSError, KeyError, TypeError):
        logger.warning("llm-cache: unreadable entry %s; treating as miss", path.name)
        return None


def _write_cached_text(path: Path, kwargs: dict[str, Any], text: str) -> None:
    """Persist a response.  Best-effort — a failed write must not fail the call."""
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(
                {"model": kwargs.get("model"), "text": text},
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
    except OSError as exc:
        logger.warning("llm-cache: failed to write %s: %s", path.name, exc)
