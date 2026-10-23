"""The LLM oracle: the pipeline's Claude calls answered out of band, never by the API."""

from __future__ import annotations

import json

import pytest

from retally.llm import response_text
from retally.llm_cache import CachingLLMClient, _request_key
from retally.llm_oracle import OracleAnswerPending, OracleLLMClient, request_kind, write_answer
from retally.usage import UsageTrackingClient
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
reproducer_mod = load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
report = load_module_from_path("benchmark.report", REPO_ROOT / "benchmark" / "report.py")
oracle = load_module_from_path("benchmark.oracle", REPO_ROOT / "benchmark" / "oracle.py")

LABEL = "desktop-opus"
PROMPT = "Extract the claims.\n\n  Trailing spaces and unicode: é — ok  \n"


@pytest.fixture(autouse=True)
def _restore_oracle_env(monkeypatch):
    """``runner.main(["--llm-oracle", ...])`` writes os.environ directly; setenv first so it is undone."""
    for name in (runner.LLM_ORACLE_ENV, runner.PIPELINE_MODEL_ENV):
        monkeypatch.setenv(name, "")
        monkeypatch.delenv(name)


def _kwargs(prompt: str = PROMPT, **overrides):
    base = {
        "model": "claude-opus-5-5",
        "max_tokens": 16384,
        "messages": [{"role": "user", "content": prompt}],
        "output_config": {"effort": "medium"},
    }
    base.update(overrides)
    return base


def _miss(client, kwargs) -> OracleAnswerPending:
    with pytest.raises(OracleAnswerPending) as info:
        client.messages.create(**kwargs)
    return info.value


def _entry():
    return bschema.BenchmarkEntry(
        id="test",
        i4r_report_url="https://example.org/r",
        language=bschema.Language.PYTHON,
        outcome_label=bschema.OutcomeLabel.REPRODUCIBLE,
        paper=bschema.PaperRef(source="raw paper text"),
        original_claims=[bschema.OriginalClaim(description="beta", value=0.5, claim_type="coefficient")],
    )


# ── The client ──────────────────────────────────────────────────────────


def test_miss_writes_the_pending_files_and_raises(tmp_path):
    client = OracleLLMClient(tmp_path, LABEL)
    kwargs = _kwargs()
    key = _request_key(kwargs)

    exc = _miss(client, kwargs)

    pending = tmp_path / "pending" / key
    assert exc.key == key
    assert exc.prompt_path == pending / "prompt.md"
    assert str(pending / "prompt.md") in str(exc)
    assert "benchmark.oracle" in str(exc)
    assert isinstance(exc, RuntimeError)
    assert (pending / "prompt.md").read_bytes() == PROMPT.encode("utf-8")
    assert json.loads((pending / "request.json").read_text(encoding="utf-8")) == kwargs
    meta = json.loads((pending / "meta.json").read_text(encoding="utf-8"))
    assert meta["key"] == key
    assert meta["label"] == LABEL
    assert meta["model"] == "claude-opus-5-5"
    assert meta["max_tokens"] == 16384
    assert meta["output_config"] == {"effort": "medium"}
    assert meta["prompt_chars"] == len(PROMPT)
    assert meta["kind"] == "extraction"
    assert meta["created_at"]


def test_a_repeated_miss_is_idempotent(tmp_path):
    client = OracleLLMClient(tmp_path, LABEL)
    kwargs = _kwargs()
    first = _miss(client, kwargs)
    second = _miss(client, kwargs)
    assert first.prompt_path == second.prompt_path
    assert [p.name for p in (tmp_path / "pending").iterdir()] == [first.key]
    assert sorted(p.name for p in first.prompt_path.parent.iterdir()) == [
        "meta.json",
        "prompt.md",
        "request.json",
    ]
    assert first.prompt_path.read_bytes() == PROMPT.encode("utf-8")


def test_kind_heuristic():
    assert request_kind(_kwargs()) == "extraction"
    assert request_kind(_kwargs(output_config={"effort": "high"})) == "generation"
    assert request_kind(_kwargs(max_tokens=8192)) == "generation"
    assert request_kind({"max_tokens": 16384}) == "generation"


def test_unsupported_request_shapes_are_refused(tmp_path):
    client = OracleLLMClient(tmp_path, LABEL)
    two_turns = [{"role": "user", "content": "a"}, {"role": "assistant", "content": "b"}]
    blocks = [{"role": "user", "content": [{"type": "text", "text": "a"}]}]
    for messages in (two_turns, blocks, []):
        with pytest.raises(ValueError):
            client.messages.create(**_kwargs(messages=messages))
    with pytest.raises(ValueError):
        client.messages.create(**_kwargs(system="be terse"))
    assert not (tmp_path / "pending").exists()


def test_hit_returns_the_answer_and_counts_as_a_zero_token_call_under_the_label(tmp_path):
    kwargs = _kwargs()
    write_answer(tmp_path, _request_key(kwargs), "the answer", LABEL, "tester")
    client = UsageTrackingClient(OracleLLMClient(tmp_path, LABEL))

    response = client.messages.create(**kwargs)

    assert response_text(response) == "the answer"
    assert response.model == LABEL
    assert response.stop_reason == "end_turn"
    assert response.usage is None
    assert response.content[0].type == "text"
    assert not hasattr(response, "from_llm_cache")
    usage = client.tracker.since()
    assert usage["api_calls"] == 1
    assert usage["llm_cache_hits"] == 0
    assert usage["by_model"] == {
        LABEL: {
            "input_tokens": 0,
            "output_tokens": 0,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0,
            "api_calls": 1,
        }
    }
    assert client.tracker.by_model[LABEL].api_calls == 1


def test_keys_are_the_real_caches_request_key(tmp_path):
    client = OracleLLMClient(tmp_path, LABEL)
    base = _kwargs()
    variants = [
        base,
        _kwargs(output_config={"effort": "high"}),
        _kwargs(model="claude-opus-4-7"),
        _kwargs(prompt=PROMPT + "x"),
    ]
    keys = [_miss(client, kw).key for kw in variants]
    assert keys == [_request_key(kw) for kw in variants]
    assert len(set(keys)) == len(keys)


def test_nothing_is_ever_written_to_the_real_llm_cache(tmp_path):
    real_cache = tmp_path / "llm"
    real_cache.mkdir()
    oracle_dir = tmp_path / "llm-oracle" / LABEL
    client = UsageTrackingClient(OracleLLMClient(oracle_dir, LABEL))
    kwargs = _kwargs()

    exc = _miss(client, kwargs)
    (exc.prompt_path.parent / "answer.md").write_text("installed", encoding="utf-8")
    assert oracle.cmd_install(oracle_dir, _args(label=LABEL)) == 0
    assert response_text(client.messages.create(**kwargs)) == "installed"

    assert list(real_cache.iterdir()) == []
    assert sorted(p.name for p in tmp_path.iterdir()) == ["llm", "llm-oracle"]


# ── ValidationPipeline.default(client=...) ──────────────────────────────


def test_default_pipeline_uses_an_injected_client_without_the_llm_cache(tmp_path):
    from retally.pipeline import ValidationPipeline

    fake = OracleLLMClient(tmp_path / "oracle", LABEL)
    pipeline = ValidationPipeline.default(use_docker=False, client=fake, llm_cache_dir=tmp_path / "llm")

    client = pipeline.extractor._client
    assert isinstance(client, UsageTrackingClient)
    assert client._inner is fake
    assert not isinstance(client._inner, CachingLLMClient)
    assert pipeline.generator._client is client
    assert client.tracker is pipeline.usage_tracker
    assert not (tmp_path / "llm").exists()


# ── Runner wiring ───────────────────────────────────────────────────────


def test_pipeline_model_is_the_oracle_label(monkeypatch):
    assert runner.oracle_label() is None
    real_key = runner._cache_key(_entry(), "seeded")

    monkeypatch.setenv(runner.LLM_ORACLE_ENV, LABEL)
    assert runner.oracle_label() == LABEL
    assert runner.pipeline_model() == LABEL
    for mode in runner.MODES:
        monkeypatch.setenv(runner.LLM_ORACLE_ENV, LABEL)
        oracle_key = runner._cache_key(_entry(), mode)
        monkeypatch.delenv(runner.LLM_ORACLE_ENV)
        assert oracle_key != runner._cache_key(_entry(), mode)
    assert runner._cache_key(_entry(), "seeded") == real_key


def test_empty_oracle_env_is_off(monkeypatch):
    monkeypatch.setenv(runner.LLM_ORACLE_ENV, "")
    monkeypatch.delenv(runner.PIPELINE_MODEL_ENV, raising=False)
    assert runner.oracle_label() is None
    assert runner.pipeline_model() == "claude-opus-5-5"


def test_model_with_the_oracle_is_a_usage_error(monkeypatch, capsys):
    monkeypatch.setattr(runner, "run_benchmark", lambda *a, **k: pytest.fail("must not run"))
    assert runner.main(["--llm-oracle", LABEL, "--model", "claude-opus-4-7"]) == 2
    assert "--model" in capsys.readouterr().err
    monkeypatch.setenv(runner.LLM_ORACLE_ENV, LABEL)
    assert runner.main(["--model", "claude-opus-4-7"]) == 2


def test_llm_oracle_flag_sets_the_env_and_prints_the_pending_notice(tmp_path, monkeypatch, capsys):
    seen = {}

    def fake_run_benchmark(catalog, **kwargs):
        seen["label"] = runner.oracle_label()
        return [
            runner.BenchmarkResult(
                entry_id="x",
                mode="seeded",
                skipped=True,
                skip_reason=runner.SkipReason.LLM_ANSWER_PENDING,
            )
        ]

    (tmp_path / "cache" / "llm-oracle" / LABEL / "pending" / "abc").mkdir(parents=True)
    monkeypatch.setattr(runner, "CATALOG_DIR", REPO_ROOT / "tests" / "fixtures" / "benchmark_placeholders")
    monkeypatch.setattr(runner, "RESULTS_DIR", tmp_path)
    monkeypatch.setattr(runner, "REPO_ROOT", tmp_path.parent)
    monkeypatch.setattr(runner, "CACHE_DIR", tmp_path / "cache")
    monkeypatch.setattr(runner, "run_benchmark", fake_run_benchmark)

    assert runner.main(["--llm-oracle", LABEL]) == 0

    assert seen["label"] == LABEL
    out = capsys.readouterr().out
    assert "1 cell(s) waiting on an answer; 1 prompt(s) pending" in out
    assert "benchmark.oracle pending" in out


def test_default_factory_in_oracle_mode_needs_no_api_key(tmp_path, monkeypatch):
    from retally.pipeline import ValidationPipeline

    seen = {}
    monkeypatch.setattr(ValidationPipeline, "default", classmethod(lambda cls, **kw: seen.update(kw) or "p"))
    monkeypatch.setattr(runner, "CACHE_DIR", tmp_path)
    monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
    monkeypatch.setenv(runner.LLM_ORACLE_ENV, LABEL)

    assert runner._default_pipeline_factory() == "p"

    client = seen["client"]
    assert isinstance(client, OracleLLMClient)
    assert client.cache_dir == tmp_path / "llm-oracle" / LABEL
    assert client.label == LABEL
    assert seen["llm_cache_dir"] is None
    assert seen["model"] == "claude-opus-5-5"


class _PendingReproducer:
    def reproduce(self, paper_source, *, language, dataset_reference, claims, reproduction_mode):
        raise OracleAnswerPending("abc123", REPO_ROOT / "nowhere" / "prompt.md")


def test_a_pending_answer_is_a_skip_that_is_never_cached(tmp_path, monkeypatch):
    monkeypatch.setenv(runner.LLM_ORACLE_ENV, LABEL)
    [row] = runner.run_benchmark([_entry()], reproducer_factory=_PendingReproducer, cache_dir=tmp_path)

    assert row.skipped is True
    assert row.skip_reason is runner.SkipReason.LLM_ANSWER_PENDING
    assert row.skip_reason.value == "llm_answer_pending"
    assert "abc123" in (row.error or "")
    assert list(tmp_path.iterdir()) == []

    [again] = runner.run_benchmark([_entry()], reproducer_factory=_PendingReproducer, cache_dir=tmp_path)
    assert again.cached is False
    assert runner._result_from_jsonable(runner._result_to_jsonable(row)).skip_reason is (
        runner.SkipReason.LLM_ANSWER_PENDING
    )


# ── Report ──────────────────────────────────────────────────────────────


def _row(**kw):
    base = {"entry_id": "a", "mode": "seeded", "reproducer": "pipeline", "skipped": False}
    base.update(kw)
    return base


def test_report_headline_counts_pending_answers():
    rows = [
        _row(entry_id="a", skipped=True, skip_reason="llm_answer_pending", error="pending"),
        _row(entry_id="b", skipped=True, skip_reason="llm_answer_pending", error="pending"),
        _row(entry_id="c", retally_ran=True),
    ]
    assert report._headline_counts(rows)["llm_answer_pending"] == 2
    assert "llm_answer_pending=2" in report.render_markdown(rows)
    assert "llm_answer_pending=2" in report.render_html(rows)
    assert "llm_answer_pending" not in report.render_markdown([_row(retally_ran=True)])


def test_an_oracle_row_prices_to_zero_with_the_label_unpriced():
    from benchmark import pricing

    usage = {
        "api_calls": 3,
        "llm_cache_hits": 0,
        "by_model": {LABEL: {"input_tokens": 0, "output_tokens": 0, "api_calls": 3}},
    }
    priced = pricing.priced(usage)
    assert priced["estimated_usd"] == 0.0
    assert priced["unpriced_models"] == [LABEL]
    assert LABEL not in pricing.PRICES
    md = report.render_markdown([_row(retally_ran=True, usage=priced)])
    assert f"Not priced (absent from the table): `{LABEL}`" in md
    assert "**$0.00**" in md


# ── Driver ──────────────────────────────────────────────────────────────


def _args(**kw):
    import argparse

    base = {"label": LABEL, "by": "desktop-opus-subagent"}
    base.update(kw)
    return argparse.Namespace(**base)


def test_driver_pending_answer_hit_round_trip(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(oracle, "ORACLE_DIR", tmp_path)
    root = tmp_path / LABEL
    client = OracleLLMClient(root, LABEL)
    kwargs = _kwargs()
    key = _miss(client, kwargs).key

    assert oracle.main(["pending"]) == 0
    line = capsys.readouterr().out.strip()
    assert line.startswith(key)
    assert "extraction" in line and f"{len(PROMPT)} chars" in line and "no answer.md" in line

    assert oracle.main(["show", key]) == 0
    assert capsys.readouterr().out.split() == [
        str((root / "pending" / key / "prompt.md").resolve()),
        str((root / "pending" / key / "request.json").resolve()),
    ]

    answer_file = tmp_path / "reply.md"
    answer_file.write_text("```json\n[]\n```\n", encoding="utf-8")
    assert oracle.main(["answer", key, str(answer_file), "--by", "me"]) == 0
    assert not (root / "pending" / key).exists()
    stored = json.loads((root / "answers" / f"{key}.json").read_text(encoding="utf-8"))
    assert stored["model"] == LABEL
    assert stored["text"] == "```json\n[]\n```\n"
    assert stored["answered_by"] == "me"
    assert stored["answered_at"]

    assert response_text(client.messages.create(**kwargs)) == "```json\n[]\n```\n"

    capsys.readouterr()
    assert oracle.main(["status"]) == 0
    assert "1 answered (15 chars), 0 pending" in capsys.readouterr().out
    assert oracle.main(["pending"]) == 0


def test_driver_install_picks_up_answer_md(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(oracle, "ORACLE_DIR", tmp_path)
    root = tmp_path / LABEL
    client = OracleLLMClient(root, LABEL)
    answered = _miss(client, _kwargs())
    waiting = _miss(client, _kwargs(output_config={"effort": "high"}))
    (answered.prompt_path.parent / "answer.md").write_text("print(1)\n", encoding="utf-8")

    assert oracle.main(["pending"]) == 0
    out = capsys.readouterr().out
    assert "answer.md present" in out and "generation" in out

    assert oracle.main(["install"]) == 0
    out = capsys.readouterr().out
    assert f"Installed {answered.key}" in out
    assert "1 answer(s) installed; 1 prompt(s) still pending" in out
    assert (root / "answers" / f"{answered.key}.json").exists()
    assert not answered.prompt_path.parent.exists()
    assert waiting.prompt_path.exists()
    stored = json.loads((root / "answers" / f"{answered.key}.json").read_text(encoding="utf-8"))
    assert stored["answered_by"] == "desktop-opus-subagent"


def test_driver_refuses_empty_answers_and_unknown_keys(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(oracle, "ORACLE_DIR", tmp_path)
    root = tmp_path / LABEL
    key = _miss(OracleLLMClient(root, LABEL), _kwargs()).key
    blank = tmp_path / "blank.md"
    blank.write_text("  \n\t\n", encoding="utf-8")

    assert oracle.main(["answer", key, str(blank)]) == 2
    assert oracle.main(["answer", "not-a-key", str(blank)]) == 2
    assert oracle.main(["show", "not-a-key"]) == 2
    assert (root / "pending" / key).is_dir()
    assert not (root / "answers").exists()

    (root / "pending" / key / "answer.md").write_text("\n", encoding="utf-8")
    assert oracle.main(["install"]) == 0
    assert (root / "pending" / key).is_dir()


def test_driver_label_defaults_to_the_env(tmp_path, monkeypatch, capsys):
    monkeypatch.setattr(oracle, "ORACLE_DIR", tmp_path)
    monkeypatch.setenv(oracle.LLM_ORACLE_ENV, "other-label")
    assert oracle.main(["status"]) == 0
    assert "LLM oracle 'other-label'" in capsys.readouterr().out
    monkeypatch.delenv(oracle.LLM_ORACLE_ENV)
    assert oracle.main(["status"]) == 0
    assert f"LLM oracle '{LABEL}'" in capsys.readouterr().out
    assert oracle.LLM_ORACLE_ENV == runner.LLM_ORACLE_ENV


def test_oracle_rows_are_labelled_apart_from_api_pipeline_rows():
    from benchmark import metrics

    oracle_row = _row(entry_id="a", usage={"by_model": {LABEL: {"api_calls": 2}}})
    api_row = _row(entry_id="a", usage={"by_model": {"claude-opus-5-5": {"api_calls": 2}}})
    labelled = metrics.disambiguate_reproducers([oracle_row, api_row])
    assert [r["reproducer"] for r in labelled] == [f"pipeline ({LABEL})", "pipeline (claude-opus-5-5)"]
