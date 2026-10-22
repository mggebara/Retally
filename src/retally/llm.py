"""Claude model defaults and the response-shape helper shared by every call.

The pipeline makes three kinds of Claude call (claim extraction, code
generation, refinement) through ``client.messages.create``.  This module
is the one place that knows which model and effort they run on and how
to read the text out of a response.

Model
-----
``DEFAULT_MODEL`` is Claude Opus 5.5.  On this model thinking is always
on (it cannot be disabled; ``output_config.effort`` is the only depth
control, default ``medium``), the thinking tokens are billed as output
and count against ``max_tokens``, and the response's content list opens
with a thinking block before the text block.  Reading
``response.content[0].text`` therefore no longer works — use
``response_text``.

Effort
------
Generation and refinement run at ``high``: that is where the model
decides how to map a paper's specification onto a replication package,
and the extra thinking is cheap next to the Docker run that follows.
Claim extraction runs at ``medium``, the model default: it is a
structured read of the paper text and its output is already capped by
a large ``max_tokens``.
"""

from __future__ import annotations

from typing import Any

DEFAULT_MODEL = "claude-opus-5-5"
"""Model for extraction, generation and refinement unless overridden."""

DEFAULT_GENERATION_EFFORT = "high"
"""``output_config.effort`` for code generation and refinement."""

DEFAULT_EXTRACTION_EFFORT = "medium"
"""``output_config.effort`` for claim extraction."""

LEGACY_MODEL = "claude-opus-4-7"
"""The default before 2026-10-22 (ROADMAP 3.2–3.4 pipeline rows).  Kept
for ``benchmark.pricing`` and for re-running the model-confound
comparison with ``RETALLY_PIPELINE_MODEL=claude-opus-4-7``."""


def request_options(effort: str | None) -> dict[str, Any]:
    """Keyword arguments that select the thinking depth of a call.

    Returns ``{"output_config": {"effort": effort}}`` when an effort is
    set and ``{}`` otherwise, so callers can splat it into
    ``messages.create`` and a ``None`` effort leaves the request exactly
    as it was before effort existed (the model's own default applies).
    """
    if effort is None:
        return {}
    return {"output_config": {"effort": effort}}


def response_text(response: Any) -> str:
    """Return the text of a Messages API response.

    Picks the first ``text`` content block, skipping the thinking block
    that models with thinking on put first.  For duck-typed stand-ins
    (the LLM cache's replay object, test mocks) that carry no ``type``,
    the first block whose ``text`` is a string is used instead.

    Raises ``ValueError`` when the response has no text block — an empty
    ``content`` list (a ``refusal`` stop reason, or a response cut off
    inside its thinking by ``max_tokens``) or a tool-use-only reply.
    """
    blocks = getattr(response, "content", None) or []
    for block in blocks:
        if getattr(block, "type", None) == "text" and isinstance(getattr(block, "text", None), str):
            return block.text
    for block in blocks:
        text = getattr(block, "text", None)
        if isinstance(text, str) and not isinstance(getattr(block, "type", None), str):
            return text
    stop = getattr(response, "stop_reason", None)
    raise ValueError(
        f"Claude response has no text block (stop_reason={stop!r}, {len(blocks)} content block(s))"
    )
