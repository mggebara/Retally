"""Token accounting for the pipeline's Claude API calls.

``UsageTrackingClient`` wraps the client every pipeline component calls
(``client.messages.create``) and accumulates, per model id, the four
token counters the Messages API reports in ``response.usage`` —
``input_tokens``, ``output_tokens``, ``cache_creation_input_tokens``,
``cache_read_input_tokens`` — plus the number of API calls.

It sits *outside* the on-disk LLM cache (``retally.llm_cache``), so it
sees every call the pipeline makes.  A call the LLM cache answered never
reached the API and cost nothing: it is counted in ``llm_cache_hits``
and contributes no tokens.  (The ``_CachedResponse`` replay carries
``from_llm_cache = True``.)

Dollar estimates are deliberately not computed here — the price table
lives with the benchmark tooling (``benchmark/pricing.py``), so the
library only reports what it measured.
"""

from __future__ import annotations

import copy
from dataclasses import asdict, dataclass, field
from typing import Any

TOKEN_FIELDS = (
    "input_tokens",
    "output_tokens",
    "cache_creation_input_tokens",
    "cache_read_input_tokens",
)


@dataclass
class ModelUsage:
    """Accumulated usage for one model id."""

    input_tokens: int = 0
    output_tokens: int = 0
    cache_creation_input_tokens: int = 0
    cache_read_input_tokens: int = 0
    api_calls: int = 0


@dataclass
class UsageTracker:
    """Running totals for one pipeline (live API calls by model, plus LLM-cache hits)."""

    by_model: dict[str, ModelUsage] = field(default_factory=dict)
    llm_cache_hits: int = 0

    def record(self, model: str, usage: Any) -> None:
        """Add one live API response's ``usage`` under ``model``."""
        mu = self.by_model.setdefault(str(model or "unknown"), ModelUsage())
        mu.api_calls += 1
        for name in TOKEN_FIELDS:
            setattr(mu, name, getattr(mu, name) + _as_int(getattr(usage, name, 0)))

    def record_cache_hit(self) -> None:
        self.llm_cache_hits += 1

    def snapshot(self) -> UsageTracker:
        """A frozen copy, for computing what a later stretch of work added (:meth:`since`)."""
        return copy.deepcopy(self)

    def since(self, before: UsageTracker | None = None) -> dict[str, Any]:
        """Usage accumulated since ``before`` (or in total), as a JSON-ready dict.

        Shape::

            {"api_calls": int, "llm_cache_hits": int, "llm_cache_served": bool,
             "by_model": {model_id: {input_tokens, output_tokens,
                                     cache_creation_input_tokens,
                                     cache_read_input_tokens, api_calls}}}
        """
        before = before or UsageTracker()
        by_model: dict[str, dict[str, int]] = {}
        for model, mu in self.by_model.items():
            prev = before.by_model.get(model, ModelUsage())
            delta = {k: v - getattr(prev, k) for k, v in asdict(mu).items()}
            if any(delta.values()):
                by_model[model] = delta
        hits = self.llm_cache_hits - before.llm_cache_hits
        return {
            "api_calls": sum(d["api_calls"] for d in by_model.values()),
            "llm_cache_hits": hits,
            "llm_cache_served": hits > 0,
            "by_model": by_model,
        }


class _TrackingMessages:
    def __init__(self, inner_client: Any, tracker: UsageTracker) -> None:
        self._inner = inner_client
        self._tracker = tracker

    def create(self, **kwargs: Any) -> Any:
        response = self._inner.messages.create(**kwargs)
        if getattr(response, "from_llm_cache", False) is True:
            self._tracker.record_cache_hit()
        else:
            # Prefer the model id the API reports; fall back to the request's.
            model = getattr(response, "model", None)
            if not isinstance(model, str) or not model:
                model = kwargs.get("model")
            self._tracker.record(model, getattr(response, "usage", None))
        return response


class UsageTrackingClient:
    """Wraps a client (real, cached, or mock) and records ``messages.create`` usage.

    Preserves the surface pipeline components use: ``client.messages.create``
    returning the inner response unchanged.
    """

    def __init__(self, inner_client: Any, tracker: UsageTracker | None = None) -> None:
        self._inner = inner_client
        self.tracker = tracker or UsageTracker()
        self.messages = _TrackingMessages(inner_client, self.tracker)


def _as_int(value: Any) -> int:
    """Usage counters can be None (e.g. no cache activity); treat that as 0."""
    try:
        return int(value or 0)
    except (TypeError, ValueError):
        return 0
