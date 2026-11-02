"""The memorisation probe driver: recall prompts that never state a pinned value, scored like blind mode."""

from __future__ import annotations

import json

import pytest

from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
metrics = load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
probe = load_module_from_path("benchmark.probe", REPO_ROOT / "benchmark" / "probe.py")

PAPERS = REPO_ROOT / "benchmark" / "papers"
LABEL = "test-label"

FAKE_YAML = """\
# Original paper: Doe, J., & Roe, R. (2021). "A Tiny Paper: Evidence from
#   Nowhere." Journal of Made-Up Economics, 12(3), 45-67.
#   doi:10.0000/fake
#
# Not a real entry.

id: doe-2021-tiny
i4r_report_url: https://example.org/report
language: r
outcome_label: reproducible
split: holdout
paper:
  source: https://example.org/paper.pdf
  title: "A Tiny Paper: Evidence from Nowhere"
  authors:
    - Jane Doe
    - Richard Roe
original_claims:
  - description: effect_main
    value: 0.0280
    claim_type: coefficient
    standard_error: 0.0110
    context: >
      Table 2, column 1: the effect of the treatment on the outcome, with
      region fixed effects and standard errors clustered by village.
  - description: effect_placebo
    value: -1.25
    claim_type: coefficient
    context: >
      Table 2, column 3: the placebo coefficient in the same regression.
  - description: n_obs
    value: 4328
    claim_type: other
    context: >
      Number of observations in the Table 2 regressions.
"""


def _fake_catalog(tmp_path):
    papers = tmp_path / "papers"
    papers.mkdir()
    (papers / "doe-2021-tiny.yaml").write_text(FAKE_YAML, encoding="utf-8")
    return papers


@pytest.fixture
def store(tmp_path, monkeypatch):
    monkeypatch.setattr(probe, "PROBE_DIR", tmp_path / "probe")
    monkeypatch.setattr(probe, "RESULTS_DIR", tmp_path / "results")
    papers = _fake_catalog(tmp_path)
    return tmp_path / "probe" / LABEL, papers


def _main(papers, *argv):
    return probe.main([*argv, "--label", LABEL, "--papers-dir", str(papers)])


# ── Rendering ───────────────────────────────────────────────────────────


def test_citation_parsing():
    citation = probe.header_citation(FAKE_YAML)
    assert citation.startswith("Doe, J., & Roe, R. (2021).")
    assert "doi:10.0000/fake" in citation and "Not a real entry" not in citation
    assert probe.journal_and_year(citation) == ("Journal of Made-Up Economics", "2021")
    assert probe.journal_and_year(None) == (None, None)
    assert probe.journal_and_year("no citation here") == (None, None)


def test_render_writes_a_prompt_with_no_pinned_value(store, capsys):
    root, papers = store
    assert _main(papers, "render", "--split", "holdout") == 0
    d = root / "doe-2021-tiny"
    prompt = (d / "prompt.md").read_text(encoding="utf-8")

    assert "A Tiny Paper: Evidence from Nowhere" in prompt
    assert "Jane Doe, Richard Roe" in prompt
    assert "Journal of Made-Up Economics, 2021" in prompt
    assert "`effect_main` (coefficient): Table 2, column 1: the effect" in prompt
    assert "`n_obs` (other)" in prompt
    assert probe.INSTRUCTION in prompt
    for printed in (
        "0.0280",
        "0.028",
        "0.03",
        "0.0110",
        "0.011",
        "1.25",
        "1.3",
        "4328",
        "4,328",
        "4330",
        "4300",
    ):
        assert printed not in prompt
    entry = bschema.load_entry(papers / "doe-2021-tiny.yaml")
    assert probe.leaked_values(prompt, entry) == []

    meta = json.loads((d / "meta.json").read_text(encoding="utf-8"))
    assert meta["entry"] == "doe-2021-tiny" and meta["label"] == LABEL and meta["n_claims"] == 3
    assert meta["created_at"]

    # The dev split holds nothing here.
    capsys.readouterr()
    assert _main(papers, "render", "--split", "dev") == 0
    assert "0 prompt(s) rendered" in capsys.readouterr().out


def test_render_refuses_a_context_that_states_a_value(store):
    root, papers = store
    path = papers / "doe-2021-tiny.yaml"
    path.write_text(
        FAKE_YAML.replace("Number of observations in", "About 4,300 observations in"), encoding="utf-8"
    )
    with pytest.raises(ValueError, match=r"n_obs\.value as '4,300'"):
        _main(papers, "render")


def test_leak_forms_cover_printed_and_rounded_values():
    forms = probe.value_forms(-0.1274, 4)
    assert {"-0.1274", "0.1274", "-0.127", "-0.13", "-0.1", "0.1"} <= forms
    assert {"4328", "4,328", "4330", "4,330", "4300", "4,300"} <= probe.value_forms(4328.0, 0)
    assert "4000" not in probe.value_forms(4328.0, 0)  # counts are not checked at one figure
    assert "3" not in probe.value_forms(3.112, 3)  # single-digit integers are references
    assert probe._stated("0.13", "a coefficient of 0.13 here")
    assert not probe._stated("0.13", "a coefficient of 0.134 here")
    assert not probe._stated("25", "75th minus 25th percentile")
    assert not probe._stated("12", "Table 12")


@pytest.mark.parametrize("entry", probe.probe_entries(PAPERS), ids=lambda e: e.id)
def test_real_catalog_prompts_state_no_pinned_value(entry):
    text = (PAPERS / f"{entry.id}.yaml").read_text(encoding="utf-8")
    journal, year = probe.journal_and_year(probe.header_citation(text))
    assert year is not None and journal
    prompt = probe.render_prompt(entry, journal, year)
    assert probe.leaked_values(prompt, entry) == []
    for oc in entry.original_claims:
        assert f"`{oc.description}` ({oc.claim_type})" in prompt


# ── Parsing ─────────────────────────────────────────────────────────────


def test_parse_answer_strips_fences_and_reads_confidence():
    text = (
        "Here is my answer.\n\n```json\n"
        '{"effect_main": 0.03, "effect_placebo": null, "n_obs": "4,300"}\n'
        "```\n\n"
        "CONFIDENCE: effect_main: recalled\n"
        "- CONFIDENCE: effect_placebo: none\n"
        "**CONFIDENCE:** n_obs — inferred\n"
    )
    values, conf = probe.parse_answer(text)
    assert values == {"effect_main": 0.03, "effect_placebo": None, "n_obs": "4,300"}
    assert conf == {"effect_main": "recalled", "effect_placebo": "none", "n_obs": "inferred"}
    assert probe._as_number(values["n_obs"]) == 4300.0

    block = '{"a": 1}\nCONFIDENCE:\na: recalled\nb: none\n'
    assert probe.parse_answer(block) == ({"a": 1}, {"a": "recalled", "b": "none"})
    with pytest.raises(ValueError):
        probe.parse_answer("I do not remember this paper.")


# ── Install / score round trip ──────────────────────────────────────────

ANSWER = """```json
{
  "effect_main": 0.035,
  "effect_placebo": null,
  "n_obs": 4000
}
```
CONFIDENCE: effect_main: recalled
CONFIDENCE: effect_placebo: none
CONFIDENCE: n_obs: inferred
"""


def test_install_and_score_round_trip(store, tmp_path, capsys):
    root, papers = store
    assert _main(papers, "render") == 0
    d = root / "doe-2021-tiny"

    capsys.readouterr()
    assert _main(papers, "pending") == 0
    assert "doe-2021-tiny  no answer.md" in capsys.readouterr().out
    assert _main(papers, "show", "doe-2021-tiny") == 0
    assert capsys.readouterr().out.split() == [
        str((d / "prompt.md").resolve()),
        str((d / "answer.md").resolve()),
    ]
    assert _main(papers, "show", "nope") == 2

    (d / "answer.md").write_text(ANSWER, encoding="utf-8")
    capsys.readouterr()
    assert _main(papers, "install") == 0
    assert "1 answer(s) installed; 0 prompt(s) still pending" in capsys.readouterr().out
    stored = json.loads((d / "answer.json").read_text(encoding="utf-8"))
    assert stored["text"] == ANSWER
    assert stored["answered_by"] == "desktop-opus-subagent" and stored["answered_at"]
    assert stored["label"] == LABEL
    assert _main(papers, "install") == 0  # unchanged answer: nothing re-installed
    assert "0 answer(s) installed" in capsys.readouterr().out
    assert _main(papers, "status") == 0
    assert "1 rendered, 1 answered, 0 pending" in capsys.readouterr().out

    out = tmp_path / "probe-result.json"
    assert _main(papers, "score", "--out", str(out)) == 0
    table = capsys.readouterr().out

    rows = metrics.result_rows(json.loads(out.read_text(encoding="utf-8")))
    assert len(rows) == 1
    row = rows[0]
    assert row["entry_id"] == "doe-2021-tiny"
    assert row["mode"] == "probe" and row["reproducer"] == "memory-probe"
    assert row["n_claims_in_catalog"] == 3 and row["n_answered"] == 2
    # effect_main: |0.035 - 0.028| = 0.007 <= 1 SE (0.011) -> pass.
    # effect_placebo: null -> not answered, fails.
    # n_obs: 4000 vs 4328, relative tolerance 1% -> fails (but within 5x? 7.6% > 5%: no).
    assert row["n_claims_with_paper_match"] == 1
    by_name = {cd["name"]: cd for cd in row["claim_details"]}
    assert by_name["effect_main"]["within_tolerance"] is True
    assert by_name["effect_main"]["tolerance_source"] == "se_band"
    assert by_name["effect_main"]["paper_value"] == pytest.approx(0.028)
    assert by_name["effect_main"]["answered"] == pytest.approx(0.035)
    assert by_name["effect_main"]["confidence"] == "recalled"
    assert by_name["effect_placebo"]["answered"] is None and by_name["effect_placebo"]["rel_err"] is None
    assert by_name["effect_placebo"]["confidence"] == "none"
    assert by_name["n_obs"]["within_tolerance"] is False
    assert by_name["n_obs"]["rel_err"] == pytest.approx(328 / 4328)

    m = metrics.closeness(rows)
    assert (m.n_claims, m.n_matched, m.n_passed) == (3, 2, 1)

    assert "| doe-2021-tiny | 3 | 2 | 1 |" in table
    assert "1 / 1 / 1 / 0" in table
    assert "**total**" in table


def test_score_default_out_and_compare(store, tmp_path, capsys):
    root, papers = store
    assert _main(papers, "render") == 0
    reply = tmp_path / "reply.md"
    reply.write_text(ANSWER, encoding="utf-8")
    assert _main(papers, "answer", "doe-2021-tiny", str(reply), "--by", "me") == 0

    blind = tmp_path / "blind.json"
    blind.write_text(
        json.dumps(
            {
                "usage": {},
                "results": [
                    {
                        "entry_id": "doe-2021-tiny",
                        "mode": "blind",
                        "n_claims_in_catalog": 3,
                        "n_claims_with_paper_match": 2,
                    },
                    {
                        "entry_id": "doe-2021-tiny",
                        "mode": "seeded",
                        "n_claims_in_catalog": 3,
                        "n_claims_with_paper_match": 3,
                    },
                ],
            }
        ),
        encoding="utf-8",
    )
    capsys.readouterr()
    assert _main(papers, "score", "--compare", str(blind)) == 0
    table = capsys.readouterr().out
    assert "blind: blind" in table and "| 2/3 |" in table
    written = list((tmp_path / "results").glob(f"probe-{LABEL}-*.json"))
    assert len(written) == 1
    assert metrics.result_rows(json.loads(written[0].read_text(encoding="utf-8")))[0]["answered_by"] == "me"


def test_score_records_an_unparsable_answer(store, capsys):
    root, papers = store
    assert _main(papers, "render") == 0
    (root / "doe-2021-tiny" / "answer.md").write_text("No recollection at all.\n", encoding="utf-8")
    assert _main(papers, "install") == 0
    entry = bschema.load_entry(papers / "doe-2021-tiny.yaml")
    answer = json.loads((root / "doe-2021-tiny" / "answer.json").read_text(encoding="utf-8"))
    row = probe.score_entry(entry, answer)
    assert row["error"] and row["n_answered"] == 0 and row["n_claims_with_paper_match"] == 0


# ── Same tolerance as blind mode ────────────────────────────────────────


def test_tolerance_matches_committed_blind_rows():
    """Re-score committed blind claims with the probe's comparator call: same verdict, band, source."""
    from benchmark.runner import _claims_override_for

    catalog = {e.id: e for e in bschema.load_catalog(PAPERS)}
    path = (
        REPO_ROOT
        / "benchmark"
        / "results"
        / "pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json"
    )
    rows = [
        r
        for r in metrics.result_rows(json.loads(path.read_text(encoding="utf-8")))
        if r.get("mode") == "blind"
    ]
    checked = 0
    for r in rows:
        entry = catalog.get(r["entry_id"])
        if entry is None:
            continue
        claims = {c.description: c for c in _claims_override_for(entry) or []}
        for cd in r.get("claim_details", []):
            claim = claims.get(cd["description"])
            if claim is None or cd["reproduced"] is None or claim.value != cd["claimed"]:
                continue
            cr = probe.blind_compare(claim, cd["reproduced"])
            assert cr.passed == cd["passed"], cd
            assert cr.tolerance == pytest.approx(cd["tolerance"]), cd
            assert cr.tolerance_source == cd["tolerance_source"], cd
            checked += 1
    assert checked >= 20


def test_tolerance_matches_a_blind_row_example():
    """Leeson's committed blind row: claimed 0.005, reproduced 0.004914, ±1·SE band of 0.2 (relative)."""
    from benchmark.runner import _claims_override_for

    entry = bschema.load_entry(PAPERS / "leeson-2022-hobo-economicus.yaml")
    claim = next(c for c in _claims_override_for(entry) if c.description == "passersby_full_sample")
    cr = probe.blind_compare(claim, 0.004914)
    assert cr.passed and cr.tolerance_source == "se_band"
    assert cr.tolerance == pytest.approx(0.2)
    assert not probe.blind_compare(claim, 0.0065).passed
