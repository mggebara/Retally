"""Data inventory: a cheap host-side profile of every data file in the mount (ROADMAP 3.8).

The dataset listing (``_describe_dataset_files`` in ``generator.py``)
names every file and shows columns for the best-ranked Stata and R data
files, but it gives no row count for a ``.csv``, no columns for most of
them, no Stata variable labels, and nothing at all for spreadsheets.  And
when a package ships several files with the same columns -- versions of
one dataset built with different windows, cut-offs or codings -- the
listing shows them as identical, so the generator picks one and uses it
for every model.  The inventory is the profile the generator would
otherwise have to guess: for each data file its row count, column count,
leading column names and (Stata) variable labels, and for every group of
files that share their columns, which columns actually differ between
them.

No model call and no sandbox: everything is read on the host, in
Python, from file headers where the format allows it.  Work is bounded
by file size, never by wall-clock time, so the inventory -- and with it
the generation prompt and its LLM-cache key -- is deterministic for a
given tree.  A file too large to profile within those bounds is listed
with ``rows unknown`` and the reason, never skipped.

Nothing here is specific to any paper: the thresholds are sizes and
counts, the text is generic.
"""

from __future__ import annotations

import csv
import re
import zipfile
from collections.abc import Callable
from dataclasses import dataclass, field
from pathlib import Path

from retally.codegen.rdata import R_DATA_SUFFIXES, read_r_objects

# Formats the inventory profiles.  Everything else in the mount is left
# to the plain listing.
_CSV_SUFFIXES = frozenset({".csv", ".tsv"})
_EXCEL_SUFFIXES = frozenset({".xlsx", ".xlsm", ".xls"})
_NO_READER_SUFFIXES = frozenset({".parquet", ".feather", ".arrow", ".sav", ".por", ".sas7bdat"})
DATA_SUFFIXES = _CSV_SUFFIXES | _EXCEL_SUFFIXES | _NO_READER_SUFFIXES | R_DATA_SUFFIXES | frozenset({".dta"})

# Size bounds (bytes on disk).  A CSV up to the first is parsed with the
# csv module (exact row count, quoted newlines handled); up to the second
# its newlines are counted (an approximate row count, marked ``~``);
# beyond that the row count is reported as unknown.
CSV_EXACT_MAX_BYTES = 50 * 1024 * 1024
CSV_COUNT_MAX_BYTES = 1024 * 1024 * 1024
# Files sharing their columns are loaded and compared only up to this size each.
SIBLING_COMPARE_MAX_BYTES = 25 * 1024 * 1024
# Prompt budget.
MAX_FILES = 30
MAX_CHARS = 16_000
COLUMNS_CHARS = 700
MAX_LABELLED_COLUMNS = 25
LABEL_CHARS = 60
MAX_DIFF_COLUMNS = 8
MAX_R_TABLES = 3

_CHUNK = 1 << 20

Prioritise = Callable[[list[str], dict[str, str]], tuple[list[str], int]]
"""``(column names, {name: label}) -> (names in prompt order, number of strong matches)``."""


@dataclass
class _TableProfile:
    name: str  # R object name; "" for single-table formats
    rows: int | None
    columns: list[str]
    labels: dict[str, str] = field(default_factory=dict)
    rows_approx: bool = False


@dataclass
class FileProfile:
    """What the inventory knows about one data file."""

    relative: str
    size: int
    kind: str  # "csv", "dta", "R", "excel", or the bare suffix for unread formats
    tables: list[_TableProfile] = field(default_factory=list)
    note: str = ""  # why rows (or everything) are unknown; "" when fully profiled
    n_strong: int = 0  # columns matching the paper text (ranking only)


def build_inventory(
    root: Path, prioritise: Prioritise | None = None, *, show_values: bool = True
) -> list[str]:
    """Prompt lines profiling every data file under ``root``; ``[]`` when there are none.

    ``prioritise`` orders each table's columns for the prompt and counts
    its matches against the paper text (the generator passes the
    listing's ``_prioritised_columns`` bound to the paper's hints); files
    are ranked by those matches, then by size.  Without it columns keep
    file order and files are ranked by size.  Deterministic.

    ``show_values=False`` (blind mode) names the columns that differ
    between files sharing their columns but prints no statistic of them:
    a package's result tables can share columns too, and their means
    could carry the withheld numbers.
    """
    if not root.is_dir():
        return []
    paths = sorted(
        p
        for p in root.rglob("*")
        if p.is_file()
        and p.suffix.lower() in DATA_SUFFIXES
        and not any(part.startswith(".") for part in p.relative_to(root).parts)
    )
    if not paths:
        return []
    profiles = [_profile(p, root) for p in paths]
    for prof in profiles:
        for table in prof.tables:
            if prioritise is not None and table.columns and prof.kind != "excel":
                ordered, n_strong = prioritise(list(table.columns), table.labels)
                table.columns = ordered
                prof.n_strong += n_strong
    by_rel = {prof.relative: (prof, path) for prof, path in zip(profiles, paths, strict=True)}
    profiles.sort(key=lambda f: (-f.n_strong, -f.size, f.relative))

    groups = _sibling_groups(profiles)
    lines: list[str] = []
    used = 0
    shown: list[FileProfile] = []
    for prof in profiles[:MAX_FILES]:
        line = _format_profile(prof)
        if used + len(line) > MAX_CHARS and shown:
            break
        lines.append(line)
        used += len(line)
        shown.append(prof)
    shown_set = {p.relative for p in shown}
    for group in groups:
        if not any(rel in shown_set for rel in group):
            continue
        line = _format_group(group, [by_rel[rel][1] for rel in group], by_rel, show_values)
        if used + len(line) > MAX_CHARS + 2_000:  # group notes may run slightly past the file budget
            break
        lines.append(line)
        used += len(line)
    hidden = len(profiles) - len(shown)
    if hidden > 0:
        lines.append(f"- … and {hidden} more data files not profiled here (inventory capped)")
    return lines


# ── profiling ────────────────────────────────────────────────────────────


def _profile(path: Path, root: Path) -> FileProfile:
    rel = str(path.relative_to(root))
    size = path.stat().st_size
    suffix = path.suffix.lower()
    try:
        if suffix in _CSV_SUFFIXES:
            return _profile_csv(path, rel, size, delimiter="\t" if suffix == ".tsv" else ",")
        if suffix == ".dta":
            return _profile_dta(path, rel, size)
        if suffix in R_DATA_SUFFIXES:
            return _profile_r(path, rel, size)
        if suffix in (".xlsx", ".xlsm"):
            return _profile_xlsx(path, rel, size)
    except Exception as exc:  # a profile must never break generation
        return FileProfile(rel, size, suffix.lstrip("."), note=f"not profiled: {_short(exc)}")
    return FileProfile(
        rel, size, suffix.lstrip("."), note=f"not profiled: no reader for {suffix} files on the host"
    )


def _profile_csv(path: Path, rel: str, size: int, delimiter: str) -> FileProfile:
    with path.open("r", encoding="utf-8", errors="replace", newline="") as f:
        header = next(csv.reader(f, delimiter=delimiter), [])
    columns = [c.strip() for c in header]
    if size <= CSV_EXACT_MAX_BYTES:
        with path.open("r", encoding="utf-8", errors="replace", newline="") as f:
            rows = sum(1 for _ in csv.reader(f, delimiter=delimiter)) - 1
        return FileProfile(rel, size, "csv", [_TableProfile("", max(rows, 0), columns)])
    if size <= CSV_COUNT_MAX_BYTES:
        newlines = 0
        last = b""
        with path.open("rb") as f:
            while chunk := f.read(_CHUNK):
                newlines += chunk.count(b"\n")
                last = chunk[-1:]
        lines = newlines + (1 if last and last != b"\n" else 0)
        return FileProfile(
            rel, size, "csv", [_TableProfile("", max(lines - 1, 0), columns, rows_approx=True)]
        )
    return FileProfile(
        rel,
        size,
        "csv",
        [_TableProfile("", None, columns)],
        note="rows unknown: file too large to count quickly",
    )


def _profile_dta(path: Path, rel: str, size: int) -> FileProfile:
    import pandas as pd

    with pd.read_stata(path, iterator=True) as reader:
        labels = {str(k): str(v or "") for k, v in reader.variable_labels().items()}
        nobs = getattr(reader, "_nobs", None)
    rows = int(nobs) if isinstance(nobs, int) else None
    note = "" if rows is not None else "rows unknown: not in the file header"
    return FileProfile(rel, size, "dta", [_TableProfile("", rows, list(labels), labels)], note=note)


def _profile_r(path: Path, rel: str, size: int) -> FileProfile:
    contents = read_r_objects(path)
    if contents.note:
        return FileProfile(rel, size, "R", note=f"rows unknown: {contents.note}")
    tables = [
        _TableProfile(obj.name, obj.rows, list(obj.columns)) for obj in contents.objects if obj.is_data_frame
    ]
    others = [obj.name or obj.r_class for obj in contents.objects if not obj.is_data_frame]
    note = f"other objects: {', '.join(others[:10])}" if others else ""
    if not tables and not others:
        note = "no objects found"
    return FileProfile(rel, size, "R", tables, note=note)


_DIMENSION = re.compile(rb'<dimension ref="([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?"')
_SHEET = re.compile(rb'<sheet [^>]*name="([^"]*)"')


def _profile_xlsx(path: Path, rel: str, size: int) -> FileProfile:
    """Sheet names and their used range (rows include any header row) from the workbook XML."""
    with zipfile.ZipFile(path) as zf:
        names = [m.decode("utf-8", "replace") for m in _SHEET.findall(zf.read("xl/workbook.xml"))]
        sheet_files = sorted(
            (n for n in zf.namelist() if re.fullmatch(r"xl/worksheets/sheet\d+\.xml", n)),
            key=lambda n: int(re.findall(r"\d+", n)[-1]),
        )
        tables: list[_TableProfile] = []
        for index, sheet in enumerate(sheet_files):
            with zf.open(sheet) as f:
                head = f.read(4096)
            m = _DIMENSION.search(head)
            name = names[index] if index < len(names) else sheet
            if not m:
                tables.append(_TableProfile(name, None, []))
                continue
            if not m.group(3):  # a single-cell range ("A1"): an empty or one-cell sheet
                rows, n_cols = 1, 1
            else:
                rows = int(m.group(4)) - int(m.group(2)) + 1
                n_cols = _col_index(m.group(3).decode()) - _col_index(m.group(1).decode()) + 1
            tables.append(_TableProfile(name, rows, [f"<{n_cols} columns>"]))
    return FileProfile(rel, size, "excel", tables, note="spreadsheet: row counts include any header rows")


def _col_index(letters: str) -> int:
    n = 0
    for ch in letters:
        n = n * 26 + (ord(ch) - 64)
    return n


# ── files that share their columns ───────────────────────────────────────


def _sibling_groups(profiles: list[FileProfile]) -> list[list[str]]:
    """Groups (2+ files, same kind, one table each, same column set) in path order."""
    buckets: dict[tuple[str, tuple[str, ...]], list[str]] = {}
    for prof in profiles:
        if prof.kind not in ("csv", "dta") or len(prof.tables) != 1 or not prof.tables[0].columns:
            continue
        key = (prof.kind, tuple(sorted(prof.tables[0].columns)))
        buckets.setdefault(key, []).append(prof.relative)
    return sorted((sorted(g) for g in buckets.values() if len(g) > 1), key=lambda g: g[0])


def _format_group(
    group: list[str],
    paths: list[Path],
    by_rel: dict[str, tuple[FileProfile, Path]],
    show_values: bool = True,
) -> str:
    head = f"- Same columns in {len(group)} files: {', '.join(group)}."
    if any(by_rel[rel][0].size > SIBLING_COMPARE_MAX_BYTES for rel in group):
        return head + " Too large to compare here: check which one each analysis needs."
    try:
        frames = [_load_frame(p) for p in paths]
    except Exception as exc:
        return head + f" Could not compare them ({_short(exc)})."
    columns = [c for c in frames[0].columns if all(c in f.columns for f in frames)]
    differing = [c for c in columns if not all(_same_values(frames[0][c], f[c]) for f in frames[1:])]
    shapes = [f"{len(f)} rows" for f in frames]
    if len(set(shapes)) > 1:
        head += " Rows: " + " | ".join(shapes) + "."
    if not differing:
        return head + " Their contents are identical."
    if show_values:
        parts = [f"{c} ({' | '.join(_summary(f[c]) for f in frames)})" for c in differing[:MAX_DIFF_COLUMNS]]
        intro = " -- values per file, in the order listed: "
    else:
        parts = [str(c) for c in differing[:MAX_DIFF_COLUMNS]]
        intro = ": "
    more = len(differing) - MAX_DIFF_COLUMNS
    tail = f", and {more} more columns" if more > 0 else ""
    same = len(columns) - len(differing)
    return (
        head
        + f" They differ in {len(differing)} column(s){intro}"
        + "; ".join(parts)
        + tail
        + f".  The other {same} columns are identical.  Decide from the paper which file each "
        "analysis uses; do not assume one file serves them all."
    )


def _load_frame(path: Path):
    import pandas as pd

    suffix = path.suffix.lower()
    if suffix == ".dta":
        return pd.read_stata(path, convert_categoricals=False)
    return pd.read_csv(path, sep="\t" if suffix == ".tsv" else ",", low_memory=False)


def _same_values(a, b) -> bool:
    if len(a) != len(b):
        return False
    try:
        return bool(a.reset_index(drop=True).equals(b.reset_index(drop=True)))
    except Exception:
        return False


def _summary(series) -> str:
    import pandas as pd

    non_missing = int(series.notna().sum())
    if pd.api.types.is_numeric_dtype(series) and non_missing:
        return f"mean {float(series.mean()):.6g}, {non_missing} non-missing"
    return f"{int(series.nunique(dropna=True))} distinct, {non_missing} non-missing"


# ── formatting ───────────────────────────────────────────────────────────


def _format_profile(prof: FileProfile) -> str:
    head = f"- {prof.relative} ({_human_size(prof.size)}, {prof.kind})"
    if not prof.tables:
        return f"{head}: {prof.note}" if prof.note else head
    parts = [_format_table(t, prof.kind) for t in prof.tables[:MAX_R_TABLES]]
    more = len(prof.tables) - MAX_R_TABLES
    if more > 0:
        parts.append(f"… and {more} more tables")
    text = f"{head}: " + "; ".join(parts)
    if prof.note:
        text += f" [{prof.note}]"
    return text


def _format_table(table: _TableProfile, kind: str) -> str:
    if table.rows is None:
        rows = "rows unknown"
    else:
        rows = f"{'~' if table.rows_approx else ''}{table.rows} rows"
    if kind == "excel":
        cols = table.columns[0].strip("<>") if table.columns else "columns unknown"
        return f"sheet {table.name!r}: {rows}, {cols}"
    shape = f"{rows}, {len(table.columns)} columns"
    if table.name:
        shape = f"{table.name} ({shape})"
    if not table.columns:
        return shape
    rendered: list[str] = []
    for index, col in enumerate(table.columns):
        label = " ".join((table.labels.get(col) or "").split())
        if label and index < MAX_LABELLED_COLUMNS and label != col:
            if len(label) > LABEL_CHARS:
                label = label[:LABEL_CHARS] + "…"
            rendered.append(f'{col} "{label}"')
        else:
            rendered.append(col)
    joined = ", ".join(rendered)
    if len(joined) > COLUMNS_CHARS:
        joined = joined[:COLUMNS_CHARS] + "…"
    return f"{shape}: {joined}"


def _human_size(n_bytes: int) -> str:
    size = float(n_bytes)
    for unit in ("B", "KB", "MB", "GB"):
        if size < 1024 or unit == "GB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} GB"  # pragma: no cover


def _short(exc: BaseException) -> str:
    text = " ".join(str(exc).split()) or type(exc).__name__
    return text if len(text) <= 80 else text[:80] + "…"


__all__ = ["DATA_SUFFIXES", "FileProfile", "build_inventory"]
