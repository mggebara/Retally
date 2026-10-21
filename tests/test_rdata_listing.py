"""R data files in the dataset listing (Phase 1.9).

Bisbee & Honig's package is nine ``.RData`` files and the listing used
to give only their names, so every first script guessed variable names
and crashed.  The listing now shows each file's objects and every data
frame's rows and columns, ranked and budgeted like ``.dta`` columns.
"""

from __future__ import annotations

import gzip
import struct
from pathlib import Path

import pandas as pd
import pyreadr
import pytest

from retally.codegen import rdata
from retally.codegen.generator import _describe_dataset_files, _Hints, _prioritised_columns
from retally.codegen.rdata import read_r_objects

# ── a minimal R serializer for objects pyreadr cannot write ──────────


def _i(n: int) -> bytes:
    return struct.pack(">i", n)


def _flags(sexp_type: int, *, attr: bool = False, tag: bool = False, obj: bool = False) -> bytes:
    return _i(sexp_type | (0x100 if obj else 0) | (0x200 if attr else 0) | (0x400 if tag else 0))


def _charsxp(text: str) -> bytes:
    raw = text.encode()
    return _flags(9) + _i(len(raw)) + raw


def _symbol(name: str) -> bytes:
    return _flags(1) + _charsxp(name)


def _strsxp(values: list[str]) -> bytes:
    return _flags(16) + _i(len(values)) + b"".join(_charsxp(v) for v in values)


def _intsxp(values: list[int]) -> bytes:
    return _flags(13) + _i(len(values)) + b"".join(_i(v) for v in values)


def _realsxp(values: list[float]) -> bytes:
    return _flags(14) + _i(len(values)) + b"".join(struct.pack(">d", v) for v in values)


def _attributes(pairs: list[tuple[str, bytes]]) -> bytes:
    out = b"".join(_flags(2, tag=True) + _symbol(tag) + value for tag, value in pairs)
    return out + _i(254)


def _data_frame(columns: dict[str, list[float]]) -> bytes:
    n_rows = len(next(iter(columns.values())))
    body = _flags(19, attr=True, obj=True) + _i(len(columns))
    body += b"".join(_realsxp(v) for v in columns.values())
    return body + _attributes(
        [
            ("names", _strsxp(list(columns))),
            ("class", _strsxp(["data.frame"])),
            ("row.names", _intsxp([-(2**31), -n_rows])),
        ]
    )


def _list(items: list[bytes]) -> bytes:
    return _flags(19) + _i(len(items)) + b"".join(items)


def _write_rdata(path: Path, objects: dict[str, bytes]) -> None:
    stream = b"RDX3\nX\n" + _i(3) + _i(0x040300) + _i(0x030500) + _i(5) + b"UTF-8"
    for name, value in objects.items():
        stream += _flags(2, tag=True) + _symbol(name) + value
    path.write_bytes(gzip.compress(stream + _i(254)))


def _frame(columns: list[str], n_rows: int = 3) -> pd.DataFrame:
    return pd.DataFrame({c: [float(i) for i in range(n_rows)] for c in columns})


# ── reader ────────────────────────────────────────────────────────────


@pytest.mark.parametrize("compress", [None, "gzip"])
def test_rdata_written_by_pyreadr_lists_object_rows_and_columns(tmp_path, compress):
    path = tmp_path / "replication_data.RData"
    frame = _frame(["county", "stab", "pcttw_sanders"], 4)
    pyreadr.write_rdata(str(path), frame, df_name="finalDat", compress=compress)
    [obj] = read_r_objects(path).objects
    assert (obj.name, obj.is_data_frame, obj.rows) == ("finalDat", True, 4)
    assert obj.columns == ("county", "stab", "pcttw_sanders")


def test_rds_written_by_pyreadr_is_one_unnamed_object(tmp_path):
    path = tmp_path / "panel.rds"
    pyreadr.write_rds(str(path), _frame(["a", "b"], 7), compress="gzip")
    contents = read_r_objects(path)
    assert contents.note == ""
    [obj] = contents.objects
    assert (obj.name, obj.r_class, obj.rows, obj.columns) == ("", "data.frame", 7, ("a", "b"))


def test_rdata_lists_non_data_frame_objects_by_class(tmp_path):
    """pyreadr drops lists, models and vectors; the listing names them."""
    path = tmp_path / "mixed.RData"
    _write_rdata(
        path,
        {
            "dat": _data_frame({"x": [1.0, 2.0], "y": [3.0, 4.0]}),
            "maps": _list([_strsxp(["a", "b"]), _realsxp([1.0])]),
            "fit": _flags(19, attr=True, obj=True)
            + _i(1)
            + _realsxp([0.5])
            + _attributes([("class", _strsxp(["lm"]))]),
            "ids": _intsxp([1, 2, 3]),
        },
    )
    objs = {o.name: o for o in read_r_objects(path).objects}
    assert list(objs) == ["dat", "maps", "fit", "ids"]
    assert (objs["dat"].rows, objs["dat"].columns) == (2, ("x", "y"))
    assert [(o.r_class, o.is_data_frame) for o in list(objs.values())[1:]] == [
        ("list", False),
        ("lm", False),
        ("integer", False),
    ]


def test_unreadable_r_file_degrades_to_a_note(tmp_path):
    path = tmp_path / "broken.RData"
    path.write_bytes(b"not an R file at all")
    contents = read_r_objects(path)
    assert contents.objects == () and contents.note.startswith("unreadable: ")
    [line] = _describe_dataset_files(tmp_path)
    assert line.startswith("- broken.RData (") and "(unreadable: " in line


def test_truncated_r_file_degrades_to_a_note(tmp_path):
    good = tmp_path / "good.RData"
    _write_rdata(good, {"dat": _data_frame({"x": [1.0, 2.0]})})
    raw = gzip.decompress(good.read_bytes())
    (tmp_path / "cut.RData").write_bytes(gzip.compress(raw[: len(raw) // 2]))
    assert read_r_objects(tmp_path / "cut.RData").note.startswith("unreadable: ")


def test_large_r_file_is_not_inspected(tmp_path, monkeypatch):
    path = tmp_path / "huge.RData"
    pyreadr.write_rdata(str(path), _frame(["a"]), df_name="d")
    monkeypatch.setattr(rdata, "R_MAX_INSPECT_BYTES", 10)
    assert read_r_objects(path).note == "too large to inspect"
    [line] = _describe_dataset_files(tmp_path)
    assert line.endswith("(too large to inspect)")


def _break_walker(monkeypatch) -> None:
    def fail(self):
        raise rdata._Malformed("unsupported")

    monkeypatch.setattr(rdata._Walker, "objects", fail)


def test_walker_failure_falls_back_to_pyreadr_list_objects(tmp_path, monkeypatch):
    path = tmp_path / "d.RData"
    pyreadr.write_rdata(str(path), _frame(["alpha", "beta"]), df_name="d")
    _break_walker(monkeypatch)
    listed = [{"object_name": "d", "columns": ["alpha", "beta"]}]
    monkeypatch.setattr(pyreadr, "list_objects", lambda p: listed)
    [obj] = read_r_objects(path).objects
    assert (obj.name, obj.columns, obj.rows) == ("d", ("alpha", "beta"), None)
    [line] = _describe_dataset_files(tmp_path)
    assert "objects: d (data.frame, 2 columns: alpha, beta)" in line


def test_walker_failure_falls_back_to_pyreadr_read_r(tmp_path, monkeypatch):
    """pyreadr's list_objects raises on frames with row names; read_r reads them."""
    path = tmp_path / "d.RData"
    pyreadr.write_rdata(str(path), _frame(["alpha", "beta"], 6), df_name="d")
    _break_walker(monkeypatch)
    [obj] = read_r_objects(path).objects
    assert (obj.name, obj.columns, obj.rows) == ("d", ("alpha", "beta"), 6)


def test_reads_are_cached_per_path_and_mtime(tmp_path, monkeypatch):
    path = tmp_path / "d.rds"
    pyreadr.write_rds(str(path), _frame(["a"]))
    first = read_r_objects(path)
    monkeypatch.setattr(rdata, "_read_uncached", lambda *a: pytest.fail("re-read"))
    assert read_r_objects(path) is first


# ── listing ───────────────────────────────────────────────────────────


def test_rdata_line_shows_objects_with_paper_matched_columns_first(tmp_path):
    filler = [f"CTY_var_{i:03d}" for i in range(120)]
    _write_rdata(
        tmp_path / "replication_data.RData",
        {
            "finalDat": _data_frame({c: [1.0, 2.0] for c in [*filler, "sanders", "caucus_switch"]}),
            "stateMap": _list([_strsxp(["a"])]),
        },
    )
    [line] = _describe_dataset_files(tmp_path, ["Sanders vote share; caucus switch"])
    assert line.startswith("- replication_data.RData (")
    expected = "— objects: finalDat (data.frame, 2 rows, 122 columns: sanders, caucus_switch, CTY_var_000,"
    assert expected in line
    assert line.endswith("…), stateMap (list)")


def test_rds_line_shows_class_and_shape(tmp_path):
    pyreadr.write_rds(str(tmp_path / "panel.rds"), _frame(["id", "year"], 5))
    [line] = _describe_dataset_files(tmp_path)
    assert line.endswith("— data.frame, 5 rows, 2 columns: id, year")


def test_dta_and_r_data_files_share_one_ranking(tmp_path):
    """Most strong matches first, whatever the format."""
    _frame(["state", "exposure"]).to_stata(tmp_path / "a.dta", write_index=False)
    pyreadr.write_rdata(str(tmp_path / "b.RData"), _frame(["state", "exposure", "turnout"]), df_name="d")
    pyreadr.write_rds(str(tmp_path / "c.rds"), _frame(["x"] + [f"v{i}" for i in range(30)]))
    (tmp_path / "notes.txt").write_text("x")
    lines = _describe_dataset_files(tmp_path, ["exposure and turnout"])
    assert [line.split(" (")[0] for line in lines] == ["- b.RData", "- a.dta", "- c.rds", "- notes.txt"]
    # Without hints the widest file wins, again whatever the format.
    lines = _describe_dataset_files(tmp_path)
    assert lines[0].startswith("- c.rds (")


def test_top_rdata_file_shows_every_strong_match_past_the_budget(tmp_path):
    from retally.codegen.generator import _TREE_TOP_HEADER_CHARS

    strong = [f"distinctiveword{i:02d}" for i in range(35)]
    filler = [f"zzfiller_{i:03d}" for i in range(100)]
    pyreadr.write_rdata(str(tmp_path / "d.RData"), _frame(filler + strong), df_name="d")
    [line] = _describe_dataset_files(tmp_path, [" ".join(strong)])
    columns = line.split("columns: ", 1)[1]
    assert all(w in columns for w in strong)
    assert len(columns) > _TREE_TOP_HEADER_CHARS


def test_r_data_frames_put_leading_columns_after_strong_matches():
    """No labels: the author's column order is the fallback signal."""
    names = ["id", "outcome_pct", "fe_code", *[f"ctrl_{i}" for i in range(30)], "school"]
    ordered, n_strong = _prioritised_columns(names, {}, _Hints(["high school"]), lead=3)
    assert n_strong == 1
    assert ordered[:4] == ["school", "id", "outcome_pct", "fe_code"]
    ordered, _ = _prioritised_columns(names, {}, _Hints(["high school"]))
    assert ordered[:2] == ["school", "id"]  # lead=0: the rest in file order


def test_compound_names_of_hint_words_and_acronyms_are_strong():
    """``DMA_cases``: "DMA" (an acronym in the text) and "cases" are both hint words."""
    hints = _Hints(["the county's DMA had confirmed cases; caucus switch"])
    names = ["DMA_deaths", "zz", "DMA_cases", "caucus_switch", "turnout_20", "cases"]
    ordered, n_strong = _prioritised_columns(names, {}, hints)
    assert ordered[:n_strong] == ["DMA_cases", "caucus_switch", "cases"]
