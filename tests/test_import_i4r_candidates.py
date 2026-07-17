"""Tests for scripts/import_i4r_candidates.py.

The fixture ``tests/fixtures/i4r_candidates/mini_meta_database.csv`` mirrors
the real I4R First Meta Database columns the importer reads, with five
replication reports chosen to exercise every branch of the scope filter and
outcome mapping (see the row comments below).
"""

from __future__ import annotations

from tests._loaders import REPO_ROOT, load_module_from_path

imp = load_module_from_path("import_i4r_candidates", REPO_ROOT / "scripts" / "import_i4r_candidates.py")
schema = load_module_from_path("benchmark.schema", REPO_ROOT / "benchmark" / "schema.py")

FIXTURE = REPO_ROOT / "tests" / "fixtures" / "i4r_candidates" / "mini_meta_database.csv"


# ── Pure helpers ────────────────────────────────────────────────────────


def test_slugify_drops_stopwords_and_caps_length():
    assert imp.slugify("The Long-Run Effects of Sports Club Vouchers") == ("long-run-effects-sports-club")


def test_slugify_falls_back_when_all_stopwords():
    # Don't return an empty slug just because every word is a stopword.
    assert imp.slugify("Of The And") == "of-the-and"


def test_surname_takes_last_token():
    assert imp.surname("Alberto Alesina") == "alesina"
    assert imp.surname("Kristian Vrede Skaaning Frederiksen") == "frederiksen"


def test_collect_authors_drops_padding_and_blanks():
    row = {
        "o_a_name_1": "Alberto Alesina",
        "o_a_name_2": "Armando Miano",
        "o_a_name_3": "No Author Number 3",
        "o_a_name_4": "",
        "o_a_name_5": "No Author Number 5",
        "o_a_name_6": "No Author Number 6",
    }
    assert imp.collect_authors(row) == ["Alberto Alesina", "Armando Miano"]


def test_resolve_language_prefers_original_r():
    row = {"o_a_prog_lang_R": "R", "report_prog_lang_R": "Response not selected"}
    assert imp.resolve_language(row) == "r"


def test_resolve_language_python_original():
    row = {"o_a_prog_lang_python": "Python"}
    assert imp.resolve_language(row) == "python"


def test_resolve_language_r_verified_stata_original():
    # Original in Stata, but the I4R replicator wrote an R routine → target R.
    row = {"o_a_prog_lang_Stata": "Stata", "report_prog_lang_R": "R"}
    assert imp.resolve_language(row) == "r"


def test_resolve_language_none_when_out_of_scope():
    row = {"o_a_prog_lang_Stata": "Stata", "report_prog_lang_R": "Response not selected"}
    assert imp.resolve_language(row) is None


def test_original_language_label():
    assert imp.original_language({"o_a_prog_lang_R": "R"}) == "R"
    assert imp.original_language({"o_a_prog_lang_Stata": "Stata"}) == "Stata"
    assert imp.original_language({}) == "unknown"


def test_map_outcome():
    assert imp.map_outcome("Yes", "1.0") == "reproducible"
    assert imp.map_outcome("No", "1.0") == "inconclusive"
    assert imp.map_outcome("", "0.0") == "not_reproducible"
    assert imp.map_outcome("", "1.0") == "reproducible"
    assert imp.map_outcome("", "") == "inconclusive"


def test_first_nonempty_skips_blank_summary_rows():
    rows = [{"x": ""}, {"x": " "}, {"x": "found"}, {"x": "later"}]
    assert imp.first_nonempty(rows, "x") == "found"
    assert imp.first_nonempty(rows, "missing") == ""


# ── End-to-end over the fixture ─────────────────────────────────────────


def test_load_candidates_filters_and_maps():
    cands = imp.load_candidates(FIXTURE)
    by_title = {c.title: c for c in cands}

    # The Stata-only report (team 4, no R replication) is dropped.
    assert "A Structural Model of the Labor Market" not in by_title
    # Four in-scope reports survive (teams 1, 2, 3, 5).
    assert len(cands) == 4

    languages = {c.language for c in cands}
    assert languages == {"r", "python"}

    # Report-level fields spread across multiple rows are picked up
    # (team 2's perfect_reproduction sits on its second row).
    alt = by_title["Checking and Sharing Alt-Facts"]
    assert alt.language == "r"
    assert alt.replicator_wrote_r is True
    assert alt.outcome_label == "inconclusive"
    assert alt.has_report_url is False
    assert alt.i4r_report_url.startswith("TODO")

    digital = by_title["Digital Addiction"]
    assert digital.language == "python"
    assert digital.outcome_label == "not_reproducible"


def test_real_report_url_is_preserved():
    cands = imp.load_candidates(FIXTURE)
    alesina = next(c for c in cands if c.has_report_url)
    assert alesina.i4r_report_url.endswith("I4R-DP040.pdf")
    assert alesina.outcome_label == "reproducible"


def test_colliding_ids_get_team_suffix():
    # Teams 1 and 5 are the same paper/author/year → base id collides, so both
    # get an unambiguous -r<team> suffix.
    cands = imp.load_candidates(FIXTURE)
    ids = [c.id for c in cands if "immigration-redistribution" in c.id]
    assert sorted(ids) == [
        "alesina-2022-immigration-redistribution-r1",
        "alesina-2022-immigration-redistribution-r5",
    ]


# ── Rendered YAML round-trips through the catalog loader ─────────────────


def test_rendered_candidates_validate_against_schema(tmp_path):
    cands = imp.load_candidates(FIXTURE)
    paths = imp.write_candidates(cands, tmp_path)
    assert len(paths) == len(cands)

    catalog = schema.load_catalog(tmp_path)
    # Every rendered candidate loads as a valid BenchmarkEntry.
    assert len(catalog) == len(cands)
    for entry in catalog:
        assert entry.paper.source  # required field present (a TODO sentinel is fine)
        assert entry.i4r_report_url
        assert entry.split == "dev"
        assert entry.language.value in ("r", "python")


def test_gzip_corpus_is_read_transparently(tmp_path):
    import gzip

    gz = tmp_path / "mini.csv.gz"
    gz.write_bytes(gzip.compress(FIXTURE.read_bytes()))
    assert len(imp.load_candidates(gz)) == 4
