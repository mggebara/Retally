"""What the script-free copy withholds: scripts, transcripts and generated result tables.

In ``independent`` and ``blind`` mode the agent is handed a copy of the
replication package without the authors' analysis code or its results
(:func:`benchmark.reproducer.script_free_copy`).  This module decides, file
by file, what that copy leaves out.  Two layers:

1. **By name** (:func:`name_reason`): script suffixes (``.do``, ``.R``,
   ``.py``, ``.ipynb``, ``.log``, ``.smcl``, ...), ``.Rhistory`` and
   ``log_*.txt`` console sessions.  Cheap and unconditional.
2. **By content** (:func:`content_reason`), for every other text file
   under :data:`SIZE_CAP_BYTES`, whatever its extension — packages ship
   Stata logs as ``.txt``, do-files copied to ``.txt``, R sessions with no
   extension, and the tables ``esttab``/``outreg2``/``stargazer`` wrote:

   * Stata logs (``log:`` / ``log type:`` header, ``Stata/MP`` banner,
     ``. reg``-style command echoes, estimation output) and SMCL markup.
   * R transcripts (``> lm(`` prompts, ``Call:`` + ``Coefficients:``
     blocks, ``Signif. codes``) and Python console/statsmodels output.
   * Analysis code without a script suffix (a do-file, R or Python
     script saved as ``.txt``): most non-comment lines are commands.
   * Regression tables: ``.tex`` (esttab fragments, stargazer, any
     tabular with ``Observations``/``R-squared``/standard-error rows),
     ``.html``, plain-text ``esttab``/``outreg2`` output, regression-shaped
     ``.csv`` (only with ``Observations``/``R-squared`` rows) and
     ``.xlsx`` sheets whose strings carry the same markers.

   A file byte-identical to a file stripped by name is stripped too.

Evidence must be strong — several independent markers — or the file is
kept.  Binary files are never content-tested (``.xlsx`` aside, whose
shared strings are read), and known data formats (``.dta``, ``.RData``,
``.rds``, ``.sav``, ``.parquet``, shapefiles, ...) are never stripped.
Directory names (``output/``, ``tables/``) play no part: a figure's data
``.csv`` in ``Out/Figures_data`` is data, a regression table anywhere is
not.
"""

from __future__ import annotations

import csv
import hashlib
import io
import re
import zipfile
from dataclasses import dataclass
from pathlib import Path

# ---------------------------------------------------------------------------
# Layer 1: names
# ---------------------------------------------------------------------------

# The authors' analysis code, in every form a replication package ships it.
# Stata logs (.log / .smcl) and R output (.Rout) are included because they
# echo every command the script ran — a transcript of the script.
SCRIPT_SUFFIXES = frozenset(
    {".do", ".ado", ".r", ".rmd", ".py", ".ipynb", ".sas", ".sps", ".m", ".log", ".smcl", ".rout"}
)

# Transcripts that carry the code without a script suffix.  ``.Rhistory``
# has no suffix in pathlib's sense (it is a dotfile) and holds every R
# command typed; ``log_*.txt`` is a common name for a saved R console
# session (the Bisbee 2022 package ships several).
SCRIPT_NAMES = frozenset({".rhistory", ".rapp.history"})
SCRIPT_NAME_PATTERNS = (re.compile(r"^log[_-].*\.txt$", re.IGNORECASE),)

# Data formats: never stripped, never content-tested.
DATA_SUFFIXES = frozenset(
    {
        ".dta", ".rdata", ".rda", ".rds", ".sav", ".zsav", ".por", ".sas7bdat", ".sas7bcat", ".xpt",
        ".parquet", ".feather", ".arrow", ".h5", ".hdf5", ".nc", ".mat", ".pkl", ".pickle", ".npy",
        ".npz", ".db", ".sqlite", ".shp", ".shx", ".dbf", ".prj", ".cpg", ".sbn", ".sbx", ".qix",
        ".gpkg", ".geojson", ".kml", ".json", ".xml", ".tif", ".tiff",
    }
)  # fmt: skip

SIZE_CAP_BYTES = 50 * 1024 * 1024
"""Files larger than this are not content-tested (kept unless stripped by name)."""

SAMPLE_BYTES = 64 * 1024
"""How much of a file the log / code / table tests read."""

TABLE_SAMPLE_BYTES = 2 * 1024 * 1024
"""``.tex`` / ``.html`` are read further: a manuscript's tables sit past its preamble."""

MANIFEST_SUFFIX = ".retally-stripped.json"
"""The manifest sits next to the copy as ``<copy name>.retally-stripped.json``."""


@dataclass(frozen=True)
class StrippedFile:
    """One file the script-free copy leaves out, and why."""

    path: str
    """POSIX path relative to the package root."""

    reason: str
    """``script-suffix``, ``transcript-name``, ``stata-log``, ``smcl``,
    ``r-transcript``, ``python-output``, ``script-content:stata|r|python``,
    ``regression-table`` or ``duplicate-of-script``."""


def name_reason(path: Path) -> str | None:
    """The by-name strip reason for ``path``, or None."""
    name = path.name.lower()
    if path.suffix.lower() in SCRIPT_SUFFIXES:
        return "script-suffix"
    if name in SCRIPT_NAMES or any(pat.match(name) for pat in SCRIPT_NAME_PATTERNS):
        return "transcript-name"
    return None


# ---------------------------------------------------------------------------
# Layer 2: content
# ---------------------------------------------------------------------------

_STATA_CMDS = (
    "use|u|reg|regress|xtreg|areg|reghdfe|ivreg2|ivregress|ivreghdfe|xtivreg2?|ppmlhdfe|poisson|nbreg|"
    "probit|logit|oprobit|ologit|tobit|qreg|rdrobust|didregress|gen|generate|egen|replace|sum|summarize|"
    "tab|tabulate|tabstat|merge|joinby|append|keep|drop|eststo|esttab|estout|estpost|outreg2?|"
    "clear|set|cd|global|local|foreach|forvalues|while|collapse|label|lab|insheet|infile|import|export|"
    "save|saveold|estimates|est|xtset|tsset|bysort|bys|sort|gsort|log|ssc|net|rename|ren|recode|reshape|"
    "destring|tostring|encode|decode|format|order|graph|twoway|tw|scatter|histogram|kdensity|binscatter|"
    "coefplot|robvar|ttest|ranksum|display|di|matrix|mat|mata|program|preserve|restore|duplicates|"
    "count|assert|xi|winsor2?|margins|marginsplot|test|testparm|lincom|nlcom|predict|spmap|shp2dta|"
    "capture|cap|quietly|qui|noisily|noi|do|run|include|version|macro|scalar|putexcel|lab(?:el)?|"
    "if|else|isid|levelsof|ds|describe|des|codebook|xtile|pctile|mvencode|fillin|expand|cross|"
    "tempfile|tempvar|tempname|sysuse|webuse|svyset|svy|bootstrap|boottest|wyoung|ritest"
)
_STATA_CMD_RE = re.compile(rf"^(?:{_STATA_CMDS})(?=[\s,:(]|$)")
_STATA_PROMPT_RE = re.compile(rf"^\.\s+(?:{_STATA_CMDS})(?=[\s,:(]|$)")
_STATA_MACRO_RE = re.compile(r"`[A-Za-z_][\w]*'")

_R_CALL_RE = re.compile(
    r"\b(?:lm|glm|feols|feglm|fepois|felm|lm_robust|iv_robust|ivreg|plm|lmer|glmer|summary|coeftest|"
    r"etable|modelsummary|stargazer|texreg|library|require|read\.csv|read_csv|read_dta|read\.dta|"
    r"readRDS|load|haven::read_dta|fixest::feols)\s*\("
)
_R_CODE_RE = re.compile(
    r"(?:^\s*[\w.$\[\]\"'@]+\s*(?:<-|<<-)\s*\S)|(?:\b(?:library|require|source|setwd|function)\s*\()"
    r"|(?:%>%|\|>)|(?:\b(?:read\.csv|read_csv|read_dta|readRDS|saveRDS|write\.csv|ggplot|mutate|filter|"
    r"select|group_by|summarise|summarize|lm|glm|feols|felm|stargazer|data\.frame|c)\s*\()"
)
_PY_CODE_RE = re.compile(
    r"^(?:import\s+\w|from\s+[\w.]+\s+import\s|def\s+\w+\s*\(|class\s+\w+[(:]|print\(|"
    r"\w+\s*=\s*(?:pd|np|sm|smf|plt|df)\.|(?:df|data)\[|if __name__)"
)
_COMMENT_RE = re.compile(r"^(?:\*|//|/\*|\*/|#)")


def _decode(sample: bytes) -> str | None:
    """Text of ``sample`` or None when it looks binary."""
    if b"\x00" in sample:
        return None
    try:
        return sample.decode("utf-8")
    except UnicodeDecodeError as exc:
        if exc.start >= len(sample) - 4:  # a multi-byte char cut by the sample boundary
            return sample[: exc.start].decode("utf-8", errors="replace")
        return sample.decode("latin-1")


def _lines(text: str) -> list[str]:
    return [ln.rstrip("\r") for ln in text.split("\n")]


def _stata_log_score(text: str, lines: list[str]) -> int:
    score = 0
    if re.search(r"^\s*log type:\s+(?:text|smcl)\b", text, re.M):
        score += 2
    if re.search(r"^\s*(?:log|name):\s+\S", text, re.M) and re.search(r"^\s*opened on:\s", text, re.M):
        score += 1
    if re.search(r"Stata/(?:MP|SE|IC|BE)\b|StataCorp", text):
        score += 2
    cmds = {m.group(0).split()[1] for ln in lines if (m := _STATA_PROMPT_RE.match(ln))}
    score += min(3, len(cmds))
    for pattern in (
        r"Number of obs\s*=",
        r"R-squared\s*=",
        r"(?:Coef\.|Coefficient)\s+Std\.\s*[Ee]rr\.",
        r"^-{5,}\+-{5,}",
        r"end of do-file",
        r"^r\(\d+\);",
    ):
        if re.search(pattern, text, re.M):
            score += 1
    return score


def _smcl_score(text: str) -> int:
    tags = {
        t for t in ("{smcl}", "{com}", "{txt}", "{res}", "{err}", "{hline", "{sf}", "{ul off}") if t in text
    }
    return len(tags)


def _r_transcript_score(text: str, lines: list[str]) -> int:
    score = 0
    calls = {
        m.group(0).split("(")[0].strip()
        for ln in lines
        if ln.startswith("> ") and (m := _R_CALL_RE.search(ln))
    }
    score += min(3, len(calls))
    if re.search(r"^Call:\s*$", text, re.M) and re.search(r"^Coefficients:", text, re.M):
        score += 2
    for pattern in (
        r"Residual standard error:",
        r"Multiple R-squared:",
        r"Signif\. codes:",
        r"Estimate\s+Std\. Error\s+[tz] value",
        r"OLS estimation, Dep\. Var\.:",
        r"^R version \d",
    ):
        if re.search(pattern, text, re.M):
            score += 1
    return score


def _python_output_score(text: str, lines: list[str]) -> int:
    score = min(3, sum(1 for ln in lines if ln.startswith(">>> ")))
    if "OLS Regression Results" in text:
        score += 2
    for pattern in (r"Dep\. Variable:", r"No\. Observations:", r"\[0\.025\s+0\.975\]", r"In \[\d+\]:"):
        if re.search(pattern, text):
            score += 1
    return score


def _code_reason(lines: list[str]) -> str | None:
    """``script-content:stata`` / ``:r`` / ``:python`` when most lines are commands."""
    body = [ln.strip() for ln in lines if ln.strip() and not _COMMENT_RE.match(ln.strip())]
    if len(body) < 5:
        return None
    stata_lines = [ln for ln in body if _STATA_CMD_RE.match(ln)]
    stata_cmds = {re.split(r"[\s,:(]", ln, maxsplit=1)[0] for ln in stata_lines}
    stata_extra = sum(1 for ln in body if ln.endswith("///") or _STATA_MACRO_RE.search(ln))
    if len(stata_lines) >= 5 and len(stata_cmds) >= 3 and (len(stata_lines) + stata_extra) >= 0.4 * len(body):
        return "script-content:stata"
    r_lines = [ln for ln in body if _R_CODE_RE.search(ln)]
    if len(r_lines) >= 5 and len(r_lines) >= 0.4 * len(body):
        return "script-content:r"
    py_lines = [ln for ln in body if _PY_CODE_RE.match(ln)]
    if len(py_lines) >= 5 and len(py_lines) >= 0.3 * len(body):
        return "script-content:python"
    return None


# Regression-table markers, each counted once.
_TABLE_STAT_MARKERS = (
    re.compile(r"\bObservations\b|\bNum\. obs\.|\bNo\. of obs|\bN\. of obs", re.I),
    re.compile(
        r"R-squared|R-sq\b|Adj(?:usted)?\.? R2|\bR\^?\{?2\}?|R\$\^\{?2\}?\$|R<sup>2</sup>"
        r"|\\\(R\^\{2\}\\\)|\bR2\b"
    ),
    re.compile(
        r"[Ss]tandard errors?\b.{0,60}\bin parenthes|\bStd\.? ?[Ee]rr|[Rr]obust (?:standard )?errors", re.S
    ),
    re.compile(r"p\s*(?:<|\$<\$|&lt;|\\textless)\s*0?\.(?:1|05|01)\b"),
)
_TABLE_SIGNATURES = re.compile(
    r"\\sym\{\*|Table created by stargazer|\bstargazer\b|\besttab\b|\bestout\b|\boutreg2?\b|\btexreg\b"
    r"|\bmodelsummary\b|\betable\b|\bfixest\b"
)
_NUMBERED_COLUMNS = re.compile(r"\(1\)[^\n]{0,200}\(2\)")
_SE_ROW = re.compile(r"\(\s*-?\d*\.\d+\s*\)")


def _table_evidence(text: str) -> tuple[int, bool]:
    """(distinct stat markers + structure markers, has a table-tool signature)."""
    n = sum(1 for pat in _TABLE_STAT_MARKERS if pat.search(text))
    if _NUMBERED_COLUMNS.search(text):
        n += 1
    if len(_SE_ROW.findall(text)) >= 3:
        n += 1
    return n, bool(_TABLE_SIGNATURES.search(text))


def _is_regression_table(text: str, *, signature_suffices: bool = False) -> bool:
    """Several regression-table markers, or a table tool's signature plus one (alone in .tex/.html)."""
    n, signature = _table_evidence(text)
    return (signature and (signature_suffices or n >= 1)) or n >= 3


def _tex_reason(text: str) -> str | None:
    if "\\documentclass" in text:
        # A manuscript: strip only when one of its own tabulars is a regression table.
        blocks = re.findall(r"\\begin\{(tabular\*?|longtable)\}(.*?)\\end\{\1\}", text, re.S)
        return "regression-table" if any(_is_regression_table(body) for _, body in blocks) else None
    is_table = (
        "\\begin{tabular" in text or "\\begin{longtable" in text or (text.count("&") >= 4 and "\\\\" in text)
    )
    return "regression-table" if is_table and _is_regression_table(text, signature_suffices=True) else None


def _html_reason(text: str) -> str | None:
    if "<table" not in text.lower():
        return None
    return "regression-table" if _is_regression_table(text, signature_suffices=True) else None


_CSV_STAT_ROW = re.compile(
    r"^\W*(?:observations|n\. ?obs\.?|no\. obs\.?|r-squared|r2|adj(?:usted)?\.? r-?squared|r\^2)\W*$", re.I
)


def _csv_reason(text: str) -> str | None:
    """Regression table only: ``Observations``/``R-squared`` row labels plus coefficient columns."""
    if text.count("\n") > 500:
        return None
    try:
        dialect = csv.Sniffer().sniff(text[:4096], delimiters=",;\t|")
        rows = list(csv.reader(io.StringIO(text), dialect))
    except csv.Error:
        rows = list(csv.reader(io.StringIO(text)))
    rows = [[c.strip().strip('="') for c in r] for r in rows if any(c.strip() for c in r)]
    if len(rows) < 3:
        return None
    first_col = [r[0] for r in rows if r]
    stat_rows = sum(1 for c in first_col if _CSV_STAT_ROW.match(c))
    cells = [c for r in rows[:5] for c in r]
    numbered = sum(1 for c in cells if re.fullmatch(r"\(\d{1,2}\)", c))
    header = " ".join(rows[0]).lower()
    coef_header = bool(re.search(r"\b(?:coef|estimate|b)\b", header)) and bool(
        re.search(r"\b(?:se|std\.? ?err(?:or)?|std\.error|t|pval|p\.value|p>\|t\|)\b", header)
    )
    se_cells = sum(1 for r in rows for c in r if re.fullmatch(r"\(\s*-?\d*\.\d+\s*\)\**", c))
    if stat_rows >= 1 and (numbered >= 2 or coef_header or se_cells >= 3):
        return "regression-table"
    return None


def _xlsx_reason(path: Path) -> str | None:
    """A spreadsheet whose strings read like an ``outreg2``/``esttab`` table (data sheets are kept)."""
    try:
        with zipfile.ZipFile(path) as zf:
            if "xl/sharedStrings.xml" not in zf.namelist():
                return None
            info = zf.getinfo("xl/sharedStrings.xml")
            if info.file_size > TABLE_SAMPLE_BYTES:
                return None
            raw = zf.read(info).decode("utf-8", errors="replace")
    except (zipfile.BadZipFile, OSError, KeyError):
        return None
    strings = [re.sub(r"<[^>]+>", "", s) for s in re.findall(r"<si>(.*?)</si>", raw, re.S)]
    text = "\n".join(strings)
    stat_labels = sum(1 for s in strings if _CSV_STAT_ROW.match(s.strip()))
    numbered = sum(1 for s in strings if re.fullmatch(r"\s*\(\d{1,2}\)\s*", s))
    n, signature = _table_evidence(text)
    if stat_labels >= 1 and (numbered >= 2 or signature) and n >= 2:
        return "regression-table"
    return None


def _read_sample(path: Path, limit: int) -> bytes:
    with path.open("rb") as fh:
        return fh.read(limit)


def content_reason(path: Path, *, size_cap: int = SIZE_CAP_BYTES) -> str | None:
    """The by-content strip reason for the file at ``path``, or None (keep)."""
    suffix = path.suffix.lower()
    if suffix in DATA_SUFFIXES:
        return None
    try:
        size = path.stat().st_size
        if size == 0 or size > size_cap:
            return None
        if suffix in {".xlsx", ".xlsm"}:
            return _xlsx_reason(path)
        limit = TABLE_SAMPLE_BYTES if suffix in {".tex", ".html", ".htm"} else SAMPLE_BYTES
        text = _decode(_read_sample(path, limit))
    except OSError:
        return None
    if text is None:
        return None
    if suffix == ".tex":
        return _tex_reason(text)
    if suffix in {".html", ".htm"}:
        return _html_reason(text)
    if suffix in {".csv", ".tsv", ".tab"}:
        return _csv_reason(text)
    lines = _lines(text)
    if _smcl_score(text) >= 3:
        return "smcl"
    if _stata_log_score(text, lines) >= 4:
        return "stata-log"
    if _r_transcript_score(text, lines) >= 4:
        return "r-transcript"
    if _python_output_score(text, lines) >= 4:
        return "python-output"
    code = _code_reason(lines)
    if code:
        return code
    if _is_regression_table(text) and _NUMBERED_COLUMNS.search(text):
        return "regression-table"
    return None


def strip_reason(path: Path, *, size_cap: int = SIZE_CAP_BYTES) -> str | None:
    """Why the script-free copy leaves out ``path`` (by name, then content), or None to keep it."""
    return name_reason(path) or content_reason(path, size_cap=size_cap)


def _digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def classify_tree(root: Path, *, size_cap: int = SIZE_CAP_BYTES) -> list[StrippedFile]:
    """Every file under ``root`` the script-free copy leaves out, sorted by path.

    Besides :func:`strip_reason`, a file byte-identical to one stripped by
    name (a do-file copied to ``.txt``) is stripped as ``duplicate-of-script``.
    Only same-sized files are hashed, so data files are rarely read.
    """
    root = Path(root)
    files = sorted(p for p in root.rglob("*") if p.is_file() and not p.is_symlink())
    stripped: dict[Path, str] = {}
    for p in files:
        reason = strip_reason(p, size_cap=size_cap)
        if reason:
            stripped[p] = reason
    by_size: dict[int, set[str]] = {}
    for p, reason in stripped.items():
        if reason == "script-suffix" or reason == "transcript-name":
            try:
                size = p.stat().st_size
                if 0 < size <= size_cap:
                    by_size.setdefault(size, set()).add(_digest(p))
            except OSError:
                continue
    for p in files:
        if p in stripped or p.suffix.lower() in DATA_SUFFIXES:
            continue
        try:
            size = p.stat().st_size
            if size in by_size and _digest(p) in by_size[size]:
                stripped[p] = "duplicate-of-script"
        except OSError:
            continue
    return [StrippedFile(p.relative_to(root).as_posix(), r) for p, r in sorted(stripped.items())]


def manifest_path(copy_dir: Path) -> Path:
    """Where ``script_free_copy`` writes the manifest: beside ``copy_dir``, never inside it."""
    copy_dir = Path(copy_dir)
    return copy_dir.parent / f"{copy_dir.name}{MANIFEST_SUFFIX}"
