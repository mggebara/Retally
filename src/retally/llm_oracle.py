"""An LLM client whose answers are supplied out of band, one prompt at a time.

Why this exists
---------------
The pipeline makes its Claude calls through ``client.messages.create``
and already replays them from disk (``retally.llm_cache``) when the
request is byte-identical.  ``OracleLLMClient`` uses the same idea to run
the pipeline *without* the Messages API: every request is keyed exactly
as the real cache keys it (``retally.llm_cache._request_key``), and

* on a **hit** — ``<cache_dir>/answers/<key>.json`` exists — the stored
  text is returned as a response, as if the API had answered;
* on a **miss** the request is written to ``<cache_dir>/pending/<key>/``
  (``request.json``, ``prompt.md``, ``meta.json``) and
  :class:`OracleAnswerPending` is raised, which stops the run.

Someone (in practice a Claude Code subagent on plan usage, told to use
no tools and read nothing but ``prompt.md``) writes an answer, the
``python -m benchmark.oracle`` driver installs it under ``answers/``, and
the next run replays that call and proceeds to the next miss.  Nothing
here calls any API or CLI; the answering happens entirely outside.

Isolation from the real LLM cache
---------------------------------
Oracle answers are not API responses and must never be served to a real
run.  They live under their own ``cache_dir`` (the runner uses
``benchmark/.cache/llm-oracle/<label>/``, never ``benchmark/.cache/llm/``),
this client reads and writes nowhere else, and the pipeline does not wrap
an injected client in ``CachingLLMClient``.  A hit's response carries
``model = label`` and no ``from_llm_cache`` marker, so
``retally.usage`` records it as one call under the label with zero tokens
— which is what makes the benchmark report label the row
``pipeline (<label>)`` and price it at $0 (the label is not in the price
table).
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from retally.llm_cache import _request_key

ANSWERS_DIRNAME = "answers"
"""Subdirectory of the oracle root holding one ``<key>.json`` per answered request."""

PENDING_DIRNAME = "pending"
"""Subdirectory of the oracle root holding one ``<key>/`` directory per unanswered request."""

ANSWER_FILENAME = "answer.md"
"""Where an answering agent writes its reply, next to ``prompt.md``, for ``benchmark.oracle install``."""

_EXTRACTION_MAX_TOKENS = 16384
_EXTRACTION_EFFORT = "medium"


class OracleAnswerPending(RuntimeError):
    """A request has no installed answer yet; its prompt was written to ``prompt_path``.

    The benchmark runner records this as an ``llm_answer_pending`` skip
    (never cached), so re-running after the answer is installed picks the
    cell up again.
    """

    def __init__(self, key: str, prompt_path: Path) -> None:
        self.key = key
        self.prompt_path = Path(prompt_path)
        super().__init__(
            f"LLM oracle: no answer for request {key}; prompt written to {self.prompt_path}.  "
            f"Answer it, then install with `uv run python -m benchmark.oracle answer {key} FILE` "
            f"(or write {ANSWER_FILENAME} next to the prompt and run "
            "`uv run python -m benchmark.oracle install`), and re-run."
        )


class _OracleTextBlock:
    """Minimal stand-in for an anthropic text content block."""

    type = "text"

    def __init__(self, text: str) -> None:
        self.text = text


class _OracleResponse:
    """Minimal stand-in for an anthropic Message carrying an oracle answer.

    Deliberately has no ``from_llm_cache`` attribute: ``retally.usage``
    must record it as a call under ``model`` (the oracle label), not as a
    free replay of a real API response.
    """

    stop_reason = "end_turn"
    usage = None

    def __init__(self, text: str, label: str) -> None:
        self.content = [_OracleTextBlock(text)]
        self.model = label


def request_kind(kwargs: dict[str, Any]) -> str:
    """``"extraction"`` or ``"generation"`` — a heuristic, for the human answering the prompt only.

    The client cannot see which component sent a request (the generator's
    ``prompt_log`` is not visible here), so it classifies by the request
    shape the components currently send: claim extraction asks for
    ``max_tokens=16384`` at ``output_config.effort="medium"``; generation
    and refinement use ``"high"``.  Nothing reads this value back; it only
    labels ``meta.json`` and the ``benchmark.oracle pending`` listing.
    """
    output_config = kwargs.get("output_config") or {}
    effort = output_config.get("effort") if isinstance(output_config, dict) else None
    if kwargs.get("max_tokens") == _EXTRACTION_MAX_TOKENS and effort == _EXTRACTION_EFFORT:
        return "extraction"
    return "generation"


def single_user_prompt(kwargs: dict[str, Any]) -> str:
    """The text of the request's one user message; ``ValueError`` for any other shape.

    The pipeline sends exactly one user message whose content is a plain
    string.  Anything else (a system prompt, several turns, content
    blocks) would not survive being handed to the answering agent as one
    ``prompt.md``, so it is refused rather than flattened.
    """
    messages = kwargs.get("messages")
    if not isinstance(messages, list) or len(messages) != 1:
        raise ValueError("LLM oracle expects exactly one message per request")
    [message] = messages
    if not isinstance(message, dict) or message.get("role") != "user":
        raise ValueError("LLM oracle expects the single message to be a user message")
    content = message.get("content")
    if not isinstance(content, str):
        raise ValueError("LLM oracle expects the user message content to be plain text")
    if "system" in kwargs:
        raise ValueError("LLM oracle does not support a system prompt")
    return content


def write_answer(root: Path, key: str, text: str, label: str, answered_by: str) -> Path:
    """Write ``answers/<key>.json`` under ``root`` and return its path (the driver's install step)."""
    path = Path(root) / ANSWERS_DIRNAME / f"{key}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "model": label,
        "text": text,
        "answered_at": _now(),
        "answered_by": answered_by,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


class _OracleMessages:
    """The ``.messages`` attribute of :class:`OracleLLMClient` — hosts ``create``."""

    def __init__(self, cache_dir: Path, label: str) -> None:
        self._cache_dir = cache_dir
        self._label = label

    def create(self, **kwargs: Any) -> Any:
        key = _request_key(kwargs)
        text = self._read_answer(key)
        if text is not None:
            return _OracleResponse(text, self._label)
        prompt = single_user_prompt(kwargs)
        prompt_path = self._write_pending(key, kwargs, prompt)
        raise OracleAnswerPending(key, prompt_path)

    def _read_answer(self, key: str) -> str | None:
        path = self._cache_dir / ANSWERS_DIRNAME / f"{key}.json"
        if not path.exists():
            return None
        raw = json.loads(path.read_text(encoding="utf-8"))
        return str(raw["text"])

    def _write_pending(self, key: str, kwargs: dict[str, Any], prompt: str) -> Path:
        pending = self._cache_dir / PENDING_DIRNAME / key
        pending.mkdir(parents=True, exist_ok=True)
        (pending / "request.json").write_text(
            json.dumps(kwargs, default=str, indent=2) + "\n", encoding="utf-8"
        )
        prompt_path = pending / "prompt.md"
        # Bytes, not text mode: the prompt must reach the answering agent verbatim.
        prompt_path.write_bytes(prompt.encode("utf-8"))
        meta: dict[str, Any] = {
            "key": key,
            "label": self._label,
            "model": kwargs.get("model"),
            "max_tokens": kwargs.get("max_tokens"),
        }
        if kwargs.get("output_config") is not None:
            meta["output_config"] = kwargs["output_config"]
        meta.update(
            {
                "created_at": _now(),
                "prompt_chars": len(prompt),
                "kind": request_kind(kwargs),
            }
        )
        (pending / "meta.json").write_text(json.dumps(meta, default=str, indent=2) + "\n", encoding="utf-8")
        return prompt_path


class OracleLLMClient:
    """Drop-in for the anthropic client as the pipeline uses it, answered from ``cache_dir``.

    Parameters
    ----------
    cache_dir:
        Root of this oracle's store: ``answers/<key>.json`` (installed
        answers) and ``pending/<key>/`` (prompts waiting for one).  Must
        not be the real LLM cache directory.
    label:
        Names whoever answers (e.g. ``"desktop-opus"``).  Returned as the
        response's ``model``, so usage and reports attribute the calls to
        it rather than to a Claude model id.
    """

    def __init__(self, cache_dir: Path, label: str) -> None:
        if not label:
            raise ValueError("OracleLLMClient needs a non-empty label")
        self.cache_dir = Path(cache_dir)
        self.label = label
        self.messages = _OracleMessages(self.cache_dir, label)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")
