"""The printed-precision tolerance floor: inference, comparator, re-score CLI."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from retally.models import Claim, ClaimType, ReproductionMode
from retally.validation.comparator import ResultComparator
from tests._loaders import REPO_ROOT, load_module_from_path

bschema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")
load_module_from_path("benchmark.pricing", REPO_ROOT / "benchmark" / "pricing.py")
load_module_from_path("benchmark.metrics", REPO_ROOT / "benchmark" / "metrics.py")
load_module_from_path("benchmark.reproducer", REPO_ROOT / "benchmark" / "reproducer.py")
runner = load_module_from_path("benchmark.runner", REPO_ROOT / "benchmark" / "runner.py")
rescore = load_module_from_path("benchmark.rescore", REPO_ROOT / "benchmark" / "rescore.py")

ALL_MODES = list(ReproductionMode)


# ── Inference from the YAML literal ─────────────────────────────────────


@pytest.mark.parametrize(
    ("literal", "decimals"),
    [
        ("-0.0006", 4),
        ("3.713", 3),
        ("3.710", 3),  # trailing zeros are printed digits
        ("-0.0280", 4),
        ("660", 0),
        ("19765", 0),
        ("1.5e-3", 4),  # 0.0015
        ("1.5E-3", 4),
        ("1.5e3", 0),  # 1500
        ("6.8e+3", 0),
        ("+0.5", 1),
        ("1_000.25", 2),
        (".inf", None),
        ("0x1F", None),
        ("abc", None),
        ("", None),
    ],
)
def test_infer_decimals(literal, decimals):
    assert bschema.infer_decimals(literal) == decimals


_YAML = """\
id: grier-like
i4r_report_url: https://example.org/r
language: r
outcome_label: reproducible
paper:
  source: raw paper text
original_claims:
  - description: tiny_coefficient
    value: -0.0006
    claim_type: coefficient
  - description: three_decimals_trailing_zero
    value: 0.370
  - description: count
    value: 660
  - description: scientific
    value: 1.5e-3
  - description: quoted
    value: "0.0050"
  - description: explicit_wins
    value: 0.5
    decimals: 3
  - description: rounded_count
    value: 1100
    decimals: -2
"""


def _load(tmp_path: Path, text: str = _YAML):
    p = tmp_path / "entry.yaml"
    p.write_text(text, encoding="utf-8")
    return bschema.load_entry(p)


def test_loader_infers_decimals_from_how_the_value_is_written(tmp_path):
    claims = _load(tmp_path).original_claims
    assert [c.decimals for c in claims] == [4, 3, 0, 4, 4, 3, -2]
    # The float alone could not say this: 0.370 == 0.37.
    assert claims[1].value == 0.37
    assert claims[0].half_unit == pytest.approx(0.00005)
    assert claims[2].half_unit == 0.5
    assert claims[6].half_unit == pytest.approx(50.0)


def test_explicit_decimals_must_be_an_integer(tmp_path):
    bad = _YAML.replace("decimals: 3", "decimals: 2.5")
    with pytest.raises(bschema.SchemaError, match="decimals must be an integer"):
        _load(tmp_path, bad)


def test_claim_built_in_code_has_no_floor():
    oc = bschema.OriginalClaim(description="x", value=0.5)
    assert oc.decimals is None and oc.half_unit is None


def test_every_catalog_claim_gets_a_precision():
    for entry in bschema.load_catalog(REPO_ROOT / "benchmark" / "papers"):
        for c in entry.original_claims:
            assert c.decimals is not None, (entry.id, c.description)


def test_decimals_reaches_the_pipeline_claim(tmp_path):
    claims = runner._claims_override_for(_load(tmp_path))
    assert [c.decimals for c in claims] == [4, 3, 0, 4, 4, 3, -2]


# ── Comparator ──────────────────────────────────────────────────────────


def _coef(value, decimals, se=None):
    return Claim(
        description="b", value=value, claim_type=ClaimType.COEFFICIENT, decimals=decimals, standard_error=se
    )


@pytest.mark.parametrize("mode", ALL_MODES)
@pytest.mark.parametrize("reproduced", [-0.00055, -0.0006, -0.000649, -0.00065, -0.00058213])
def test_a_reproduction_that_rounds_to_the_printed_value_passes_in_every_mode(mode, reproduced):
    result = ResultComparator().compare(_coef(-0.0006, 4), reproduced, mode=mode)
    assert result.passed
    assert result.tolerance_source == "printed_precision"
    assert result.tolerance == pytest.approx(0.00005 / 0.0006)


@pytest.mark.parametrize("mode", ALL_MODES)
@pytest.mark.parametrize("reproduced", [-0.000549, -0.000651, -0.0007])
def test_a_reproduction_that_rounds_elsewhere_fails(mode, reproduced):
    assert not ResultComparator().compare(_coef(-0.0006, 4), reproduced, mode=mode).passed


def test_without_decimals_the_old_rule_holds():
    result = ResultComparator().compare(_coef(-0.0006, None), -0.00058)
    assert not result.passed
    assert result.tolerance == 0.02 and result.tolerance_source == "relative"


@pytest.mark.parametrize("mode", ALL_MODES)
def test_the_floor_never_narrows_the_relative_band(mode):
    """3.713 at 2 % is ±0.074, far wider than the half unit 0.0005."""
    comparator = ResultComparator()
    with_floor = comparator.compare(_coef(3.713, 3), 3.78, mode=mode)
    without = comparator.compare(_coef(3.713, None), 3.78, mode=mode)
    assert with_floor.passed is without.passed is True
    assert with_floor.tolerance == without.tolerance == 0.02
    assert with_floor.tolerance_source == "relative"


def test_the_floor_never_narrows_the_se_band():
    claim = _coef(-0.0006, 4, se=0.0003)  # ±1·SE = ±0.0003, wider than the half unit
    result = ResultComparator().compare(claim, -0.0008, mode=ReproductionMode.INDEPENDENT)
    assert result.passed
    assert result.tolerance_source == "se_band"
    assert result.tolerance == pytest.approx(0.5)
    # Seeded ignores the SE; the floor is what is left.
    seeded = ResultComparator().compare(claim, -0.0008, mode=ReproductionMode.SEEDED)
    assert not seeded.passed and seeded.tolerance_source == "printed_precision"


def test_the_floor_widens_an_se_band_narrower_than_the_rounding():
    claim = _coef(-0.0006, 4, se=0.00001)
    result = ResultComparator().compare(claim, -0.00064, mode=ReproductionMode.INDEPENDENT)
    assert result.passed and result.tolerance_source == "printed_precision"


def test_the_floor_applies_on_top_of_an_explicit_tolerance():
    result = ResultComparator().compare(_coef(-0.0006, 4), -0.00062, tolerance=0.001)
    assert result.passed and result.tolerance_source == "printed_precision"


def test_integer_claims_are_exact():
    claim = Claim(description="n", value=660, decimals=0)  # OTHER: 1 % -> ±6.6, wider than ±0.5
    comparator = ResultComparator()
    assert comparator.compare(claim, 660).tolerance_source == "relative"
    small = Claim(description="n", value=12, decimals=0)  # 1 % -> ±0.12, the half unit binds
    assert comparator.compare(small, 12).passed
    assert comparator.compare(small, 12.4).passed
    assert not comparator.compare(small, 13).passed
    assert comparator.compare(small, 13).tolerance_source == "printed_precision"


def test_negative_decimals_mean_rounded_to_tens_or_hundreds():
    claim = Claim(description="n", value=1100, decimals=-2)  # printed to the nearest hundred
    comparator = ResultComparator()
    for reproduced in (1050, 1100, 1149):
        result = comparator.compare(claim, reproduced)
        assert result.passed, reproduced
        assert result.tolerance_source == "printed_precision"
    assert not comparator.compare(claim, 1151).passed
    assert not comparator.compare(claim, 1049).passed


def test_a_zero_claim_records_the_absolute_band():
    claim = Claim(description="z", value=0.0, decimals=3)
    result = ResultComparator().compare(claim, 0.0004)
    assert result.passed
    assert result.tolerance_source == "printed_precision"
    assert result.tolerance == pytest.approx(0.0005)
    assert not ResultComparator().compare(claim, 0.0006).passed


def test_failure_note_names_the_printed_precision_band():
    result = ResultComparator().compare(_coef(-0.0006, 4), -0.0008)
    assert "printed place (4 decimals" in result.notes


def test_claim_detail_records_the_binding_source():
    entry_claims = [_coef(-0.0006, 4), _coef(3.713, 3), _coef(-0.5, 3, se=0.1)]
    results = ResultComparator().compare_all(entry_claims, {"b": -0.0006}, mode=ReproductionMode.INDEPENDENT)
    details = [runner._claim_detail(cr) for cr in results]
    assert [d.tolerance_source for d in details] == ["printed_precision", "relative", "se_band"]


# ── Re-score CLI ────────────────────────────────────────────────────────


_CATALOG = """\
id: paper1
i4r_report_url: https://example.org/r
language: r
outcome_label: reproducible
paper:
  source: raw paper text
original_claims:
  - description: tiny
    value: -0.0006
    claim_type: coefficient
  - description: big
    value: 3.713
    claim_type: coefficient
i4r_replicator_findings:
  - claim_id: 0
    reproduced_value: -0.0006
    outcome: matches
"""


def _results_fixture(tmp_path: Path) -> tuple[Path, Path]:
    catalog = tmp_path / "papers"
    catalog.mkdir()
    (catalog / "paper1.yaml").write_text(_CATALOG, encoding="utf-8")
    rows = [
        {
            "entry_id": "paper1",
            "mode": "seeded",
            "agrees_with_paper": False,
            "n_claims_with_paper_match": 1,
            "claim_details": [
                # Failed the old 2 % band (3 % off) but rounds to -0.0006.
                {
                    "description": "tiny",
                    "claim_type": "coefficient",
                    "claimed": -0.0006,
                    "reproduced": -0.000618,
                    "tolerance": 0.02,
                    "rel_err": 0.03,
                    "passed": False,
                },
                {
                    "description": "big",
                    "claim_type": "coefficient",
                    "claimed": 3.713,
                    "reproduced": 3.7131,
                    "tolerance": 0.02,
                    "rel_err": 2.7e-05,
                    "passed": True,
                },
            ],
        },
        {"entry_id": "paper1", "mode": "independent", "skipped": True, "claim_details": []},
        {"entry_id": "ghost", "mode": "seeded", "claim_details": [{"description": "x", "passed": True}]},
    ]
    results = tmp_path / "results.json"
    results.write_text(json.dumps({"usage": {}, "results": rows}), encoding="utf-8")
    return results, catalog


def test_rescore_cli_reports_flips_without_touching_the_file(tmp_path, capsys):
    results, catalog = _results_fixture(tmp_path)
    before = results.read_bytes()
    assert rescore.main([str(results), "--catalog", str(catalog)]) == 0
    out = capsys.readouterr().out
    assert "paper1 [seeded, pipeline]: 1/2 -> 2/2 passed (1 flipped" in out
    assert "FAIL -> PASS  tiny: claimed -0.0006, reproduced -0.000618" in out
    assert "(printed_precision)" in out
    assert "paper1 [independent, pipeline]: not re-scored" in out
    assert "ghost [seeded, pipeline]: not re-scored (entry not in the catalog" in out
    assert "1 claim verdict(s) flipped across 3 row(s)." in out
    assert results.read_bytes() == before


def test_rescore_cli_write_updates_the_verdicts(tmp_path, capsys):
    results, catalog = _results_fixture(tmp_path)
    out_path = tmp_path / "rescored.json"
    assert rescore.main([str(results), "--catalog", str(catalog), "--write", str(out_path)]) == 0
    row = json.loads(out_path.read_text(encoding="utf-8"))["results"][0]
    assert row["agrees_with_paper"] is True
    assert row["n_claims_with_paper_match"] == 2
    assert row["agrees_with_i4r"] is True
    tiny, big = row["claim_details"]
    assert tiny["passed"] is True and tiny["tolerance_source"] == "printed_precision"
    assert big["tolerance_source"] == "relative" and big["tolerance"] == 0.02
    # The round trip still loads as BenchmarkResults.
    loaded = runner._result_from_jsonable(row)
    assert loaded.claim_details[0].tolerance_source == "printed_precision"


def test_rescore_cli_refuses_to_overwrite_its_input(tmp_path):
    results, catalog = _results_fixture(tmp_path)
    assert rescore.main([str(results), "--catalog", str(catalog), "--write", str(results)]) == 2
