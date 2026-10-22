"""Estimated USD cost of the pipeline's Claude API usage — the one price table.

Every dollar figure in results JSON and REPORT.md comes from ``PRICES``
below.  Estimates only: they price the tokens the API reported in
``response.usage``; they do not see discounts, the Batch API, or a
change in list price after the run.  Calls the LLM cache answered never
reached the API and are priced at zero (they carry no tokens).

Source: the ``claude-api`` skill bundled with Claude Code (2.1.295),
"Current Models (cached: 2026-10-06)" table for input / output $/MTok,
``shared/models.md`` for the per-model cache-read rates it states
(Claude Fable 5.1 $0.25, Claude Fable 5 $1, Claude Opus 5.5 $0.20,
Claude Sonnet 5.5 $0.20), and ``shared/prompt-caching.md`` "Economics":
"Cache reads cost ~0.1x base input price ... Cache writes cost 1.25x for
5-minute TTL, 2x for 1-hour TTL".  Cache writes are priced at the
5-minute rate (1.25x input) — ``usage.cache_creation_input_tokens`` does
not split by TTL, and the pipeline does not request prompt caching today
(so the field is zero anyway).  Claude Haiku 5.5 is priced at its
<=100K-token-prompt tier.  Re-check against
https://platform.claude.com/docs/en/about-claude/pricing before quoting
a figure externally.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

_MTOK = 1_000_000


@dataclass(frozen=True)
class ModelPrice:
    """USD per million tokens."""

    input: float
    output: float
    cache_write: float
    """5-minute-TTL cache write (1.25x input)."""
    cache_read: float


def _std(input_: float, output: float, cache_read: float | None = None) -> ModelPrice:
    """Standard multipliers: cache write 1.25x input; cache read 0.1x input unless stated."""
    return ModelPrice(
        input=input_,
        output=output,
        cache_write=input_ * 1.25,
        cache_read=input_ * 0.1 if cache_read is None else cache_read,
    )


PRICES: dict[str, ModelPrice] = {
    "claude-fable-5-1": _std(10.00, 50.00, cache_read=0.25),
    "claude-fable-5": _std(10.00, 50.00, cache_read=1.00),
    "claude-opus-5-5": _std(4.00, 20.00, cache_read=0.20),  # the pipeline's default model since 2026-10-22
    "claude-opus-5": _std(5.00, 25.00),
    "claude-opus-4-8": _std(5.00, 25.00),
    "claude-opus-4-7": _std(5.00, 25.00),  # the pipeline's default until 2026-10-22 (ROADMAP 3.2-3.4 rows)
    "claude-opus-4-6": _std(5.00, 25.00),
    "claude-sonnet-5-5": _std(2.00, 10.00, cache_read=0.20),
    "claude-sonnet-5": _std(2.00, 10.00),
    "claude-sonnet-4-6": _std(3.00, 15.00),
    "claude-haiku-5-5": _std(0.10, 0.50),
    "claude-haiku-4-5": _std(1.00, 5.00),
}


def price_for(model: str) -> ModelPrice | None:
    """Price for ``model``: exact id, else the longest table id it starts with (dated snapshots)."""
    if model in PRICES:
        return PRICES[model]
    matches = [m for m in PRICES if model.startswith(m + "-")]
    return PRICES[max(matches, key=len)] if matches else None


def cost_of_model_usage(model: str, tokens: dict[str, Any]) -> float | None:
    """USD for one model's token counts, or None if the model is not in the table."""
    p = price_for(model)
    if p is None:
        return None
    return (
        int(tokens.get("input_tokens") or 0) * p.input
        + int(tokens.get("output_tokens") or 0) * p.output
        + int(tokens.get("cache_creation_input_tokens") or 0) * p.cache_write
        + int(tokens.get("cache_read_input_tokens") or 0) * p.cache_read
    ) / _MTOK


def estimate(usage: dict[str, Any] | None) -> tuple[float, list[str]]:
    """(estimated USD, unpriced model ids) for a usage dict; (0.0, []) for None."""
    total = 0.0
    unpriced: list[str] = []
    for model, tokens in ((usage or {}).get("by_model") or {}).items():
        cost = cost_of_model_usage(model, tokens or {})
        if cost is None:
            unpriced.append(model)
        else:
            total += cost
    return total, sorted(unpriced)


def priced(usage: dict[str, Any] | None) -> dict[str, Any] | None:
    """``usage`` with ``estimated_usd`` (and ``unpriced_models`` if any) added; None stays None."""
    if not usage:
        return None
    usd, unpriced = estimate(usage)
    out = dict(usage)
    out["estimated_usd"] = round(usd, 6)
    if unpriced:
        out["unpriced_models"] = unpriced
    return out


def aggregate(rows: list[dict[str, Any]]) -> dict[str, Any]:
    """Run-level spend across result rows (``results.json`` dicts).

    Rows served from the benchmark result cache (``cached: true``) made no
    calls in this run and are excluded from the spend; they are counted in
    ``rows_from_result_cache``.  Rows with no ``usage`` (skips, old files,
    reproducers that do not track usage) contribute nothing.
    """
    by_model: dict[str, dict[str, int]] = {}
    api_calls = 0
    cache_hits = 0
    from_result_cache = 0
    for r in rows:
        if r.get("cached"):
            from_result_cache += 1
            continue
        usage = r.get("usage") or {}
        api_calls += int(usage.get("api_calls") or 0)
        cache_hits += int(usage.get("llm_cache_hits") or 0)
        for model, tokens in (usage.get("by_model") or {}).items():
            acc = by_model.setdefault(model, {})
            for k, v in (tokens or {}).items():
                acc[k] = acc.get(k, 0) + int(v or 0)
    total = {
        "api_calls": api_calls,
        "llm_cache_hits": cache_hits,
        "llm_cache_served": cache_hits > 0,
        "by_model": by_model,
        "rows_from_result_cache": from_result_cache,
    }
    usd, unpriced = estimate(total)
    total["estimated_usd"] = round(usd, 6)
    if unpriced:
        total["unpriced_models"] = unpriced
    return total


def format_usd(usd: float) -> str:
    return f"${usd:,.2f}" if usd >= 0.01 or usd == 0 else f"${usd:.4f}"
