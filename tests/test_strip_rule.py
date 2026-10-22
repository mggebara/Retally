"""The script-free strip rule: logs, script content and result tables by content, plus the manifest."""

from __future__ import annotations

import json
import zipfile
from pathlib import Path

import pytest

from benchmark import reproducer as reproducer_mod
from benchmark import strip_rule
from benchmark.strip_rule import classify_tree, content_reason, manifest_path, strip_reason
from retally.models import Dataset

STATA_LOG = """\
-------------------------------------------------------------------------------
      name:  table1
       log:  C:\\Projects\\replicate\\output\\table1.txt
  log type:  text
 opened on:  21 Nov 2021, 10:02:11

. use "data\\stationvisit.dta", clear

. reg panhandlers passersby friendly shuttle service, vce(cluster metroid)

Linear regression                               Number of obs     =        212
                                                R-squared         =     0.4120
------------------------------------------------------------------------------
 panhandlers |      Coef.   Std. Err.      t    P>|t|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
   passersby |   .0123456   .0045678     2.70   0.012     .0029876    .0217036

. xtreg y x, fe

. log close table1
"""

SMCL = """{smcl}
{com}{sf}{ul off}{txt}{.-}
      name:  {res}<unnamed>
{txt}       log:  {res}/tmp/run.smcl
{txt}  log type:  {res}smcl
{com}. reg y x
{txt}      Source {c |}       SS
{res}
"""

R_TRANSCRIPT = """\
R version 4.1.2 (2021-11-01) -- "Bird Hippie"

> library(fixest)
> d <- readRDS("panel.rds")
> m <- lm(y ~ x, data = d)
> summary(m)

Call:
lm(formula = y ~ x, data = d)

Coefficients:
            Estimate Std. Error t value Pr(>|t|)
(Intercept)  0.12345    0.05432   2.273   0.0234 *
x            0.54321    0.01234  44.020   <2e-16 ***
---
Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Residual standard error: 1.01 on 998 degrees of freedom
Multiple R-squared:  0.6602
"""

STATA_DO = """\
*********    REPLICATION SETUP   ***********
clear all
set more off
set linesize 225

*** MANUALLY EDIT PATH BELOW:
cd "C:\\Documents\\Projects\\replicate"

use "data\\stationvisit.dta",clear
gen lpass = log(passersby)
reg panhandlers passersby friendly shuttle service i.day,vce(cluster metroid)
esttab using "output\\table2.tex", replace
"""

R_SCRIPT = """\
library(haven)
library(fixest)
d <- read_dta("data/panel.dta")
d$ly <- log(d$y)
m1 <- feols(ly ~ x | state, data = d)
m2 <- feols(ly ~ x + z | state, data = d)
etable(m1, m2)
"""

ESTTAB_TEX = r"""                    &\multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         \\
Pre-colonial conflict exposure&       3.713\sym{***}&       1.601\sym{***}\\
                    &     (0.305)         &     (0.380)         \\
\(R^{2}\)           &       0.598         &       0.829         \\
Observations        &         660         &         660         \\
"""

STARGAZER_HTML = """<table style="text-align:center"><caption><strong>Results</strong></caption>
<tr><td colspan="3" style="border-bottom: 1px solid black"></td></tr>
<tr><td style="text-align:left"></td><td>(1)</td><td>(2)</td></tr>
<tr><td style="text-align:left">x</td><td>0.543<sup>***</sup></td><td>0.512<sup>***</sup></td></tr>
<tr><td style="text-align:left"></td><td>(0.012)</td><td>(0.013)</td></tr>
<tr><td style="text-align:left">Observations</td><td>1,000</td><td>1,000</td></tr>
<tr><td style="text-align:left">R<sup>2</sup></td><td>0.660</td><td>0.661</td></tr>
<tr><td style="text-align:left"><em>Note:</em></td><td colspan="2" style="text-align:right">
<sup>*</sup>p&lt;0.1; <sup>**</sup>p&lt;0.05; <sup>***</sup>p&lt;0.01</td></tr>
</table>
"""

REGRESSION_CSV = """\
,(1),(2),(3)
,ly,ly,ly
x,0.543***,0.512***,0.498***
,(0.012),(0.013),(0.015)
Observations,1000,1000,980
R-squared,0.660,0.661,0.702
"""

DATA_CSV = "id,year,y,x,Observations\n1,2000,0.5,1.2,3\n2,2001,0.7,1.1,4\n3,2002,0.2,0.9,5\n"

MANUSCRIPT_TEX = r"""\documentclass{article}
\begin{document}
Our main estimate is 3.713 (Table~\ref{t1}); it is significant at p<0.01.
\begin{table}\begin{tabular}{lc}
\input{table1.tex}
\end{tabular}\end{table}
\end{document}
"""


def _write(root: Path, rel: str, content: str | bytes) -> Path:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, bytes):
        path.write_bytes(content)
    else:
        path.write_text(content, encoding="utf-8")
    return path


def _xlsx(path: Path, strings: list[str]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    sst = "".join(f"<si><t>{s}</t></si>" for s in strings)
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("[Content_Types].xml", "<Types/>")
        zf.writestr("xl/sharedStrings.xml", f'<?xml version="1.0"?><sst count="{len(strings)}">{sst}</sst>')
    return path


def _notebook() -> str:
    cell = {
        "cell_type": "code",
        "source": ["import statsmodels.formula.api as smf\n", "smf.ols('y ~ x', d).fit().summary()"],
        "outputs": [{"output_type": "execute_result", "data": {"text/plain": ["OLS Regression Results"]}}],
    }
    return json.dumps({"cells": [cell], "nbformat": 4})


@pytest.fixture
def package(tmp_path: Path) -> Path:
    """A package mixing every leak with every data format that must survive."""
    root = tmp_path / "pkg"
    leaks = {
        "code/0_setup.txt": STATA_LOG,
        "logs/run.smcl": SMCL,
        "logs/session": R_TRANSCRIPT,
        "code/1_dataprep.txt": STATA_DO,
        "notes/analysis.md": R_SCRIPT,
        "output/table1.tex": ESTTAB_TEX,
        "results/table2.html": STARGAZER_HTML,
        "tables/reg.csv": REGRESSION_CSV,
        "code/analysis.ipynb": _notebook(),
        "master.do": "use x\nreg y x\n",
    }
    for rel, content in leaks.items():
        _write(root, rel, content)
    _write(root, "code/master_copy.txt", "use x\nreg y x\n")  # byte copy of master.do
    _write(root, "data/panel.dta", b"\x72\x00\x01data" + b"use x\nreg y x\n" * 5)
    _write(root, "data/panel.csv", DATA_CSV)
    _write(root, "output/figures/fig2_data.csv", "x,y\n1,2\n2,3\n3,5\n")
    _write(root, "data/model.rds", b"X\n" + STATA_LOG.encode())
    _write(root, "paper/main.tex", MANUSCRIPT_TEX)
    _write(
        root, "README.txt", "Run master.do in Stata 17.\nData are in data/.\nThe codebook lists variables.\n"
    )
    _xlsx(root / "data/survey.xlsx", ["country", "year", "share_immigrants", "Observations"])
    _xls(root / "output/Table5_TopPanel_Cosponsors.xls", XLS_MATRIX)
    _xls(root / "data/districts.xls", XLS_DATA)
    return root


EXPECTED = {
    "code/0_setup.txt": "stata-log",
    "logs/run.smcl": "script-suffix",
    "logs/session": "r-transcript",
    "code/1_dataprep.txt": "script-content:stata",
    "notes/analysis.md": "script-content:r",
    "output/table1.tex": "regression-table",
    "results/table2.html": "regression-table",
    "tables/reg.csv": "regression-table",
    "code/analysis.ipynb": "script-suffix",
    "master.do": "script-suffix",
    "code/master_copy.txt": "duplicate-of-script",
    "output/Table5_TopPanel_Cosponsors.xls": "regression-table",
}

KEPT = {
    "data/panel.dta",
    "data/panel.csv",
    "output/figures/fig2_data.csv",
    "data/model.rds",
    "paper/main.tex",
    "README.txt",
    "data/survey.xlsx",
    "data/districts.xls",
}


def test_classify_tree_strips_every_leak_and_no_data(package):
    assert {s.path: s.reason for s in classify_tree(package)} == EXPECTED


def test_script_free_copy_keeps_data_and_writes_the_manifest_outside(package, tmp_path):
    dest = reproducer_mod.script_free_copy(package, tmp_path / "pkg.script-free")
    kept = {p.relative_to(dest).as_posix() for p in dest.rglob("*") if p.is_file()}
    assert kept == KEPT
    manifest_file = manifest_path(dest)
    assert manifest_file == tmp_path / "pkg.script-free.retally-stripped.json"
    assert not manifest_file.is_relative_to(dest)
    manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
    assert manifest["n_stripped"] == len(EXPECTED)
    assert {e["path"]: e["reason"] for e in manifest["stripped"]} == EXPECTED
    # Nothing in the mounted tree names the withheld files.
    assert not any(p.name.endswith(strip_rule.MANIFEST_SUFFIX) for p in dest.rglob("*"))


def test_script_free_dataset_reports_the_count(package):
    ds = Dataset(name="d", source_url="u", local_path=package)
    copy, stripped = reproducer_mod.script_free_dataset_with_manifest(ds)
    assert copy.local_path == package.parent / "pkg.script-free"
    assert len(stripped) == len(EXPECTED)
    assert manifest_path(copy.local_path).is_file()


def test_size_cap_skips_content_tests(tmp_path):
    log = _write(tmp_path, "out.txt", STATA_LOG)
    assert content_reason(log) == "stata-log"
    assert content_reason(log, size_cap=100) is None
    # Name-based stripping ignores the cap.
    do = _write(tmp_path, "big.do", "x" * 1000)
    assert strip_reason(do, size_cap=100) == "script-suffix"


@pytest.mark.parametrize(
    "rel",
    [".Rhistory", "code/.Rhistory", "code/run.Rout", "log_analysis.txt", "Log-session2.TXT", "a.py", "b.R"],
)
def test_name_based_cases_still_strip(tmp_path, rel):
    path = _write(tmp_path, rel, "x\n")
    assert strip_reason(path) in {"script-suffix", "transcript-name"}
    assert reproducer_mod.is_script(path)


@pytest.mark.parametrize(
    "content",
    [
        "Variable list\nid: identifier\nyear: survey year\nuse: land use category\n",
        "a b c\n1 2 3\n4 5 6\n",
        "We regress y on x.\n. This line starts with a dot\nThe sample has 660 observations.\n",
        "Table 1 reports the main estimate.\nStandard errors are clustered by state.\n",
    ],
)
def test_ordinary_text_is_kept(tmp_path, content):
    assert content_reason(_write(tmp_path, "notes.txt", content)) is None


def test_plain_data_csv_with_coef_columns_but_no_stat_rows_is_kept(tmp_path):
    # A meta-analysis dataset of estimates is data, not a results table.
    path = _write(
        tmp_path, "estimates.csv", "study,coef,se,pval\nA,0.5,0.1,0.01\nB,0.3,0.2,0.2\nC,0.1,0.1,0.4\n"
    )
    assert content_reason(path) is None


def test_outreg_style_xlsx_is_stripped_but_data_xlsx_is_kept(tmp_path):
    table = _xlsx(tmp_path / "table2.xlsx", ["", "(1)", "(2)", "x", "(0.012)", "Observations", "R-squared"])
    data = _xlsx(tmp_path / "data.xlsx", ["id", "year", "income", "Observations"])
    assert content_reason(table) == "regression-table"
    assert content_reason(data) is None


def _xls(path: Path, strings: list[str], *, compressed: list[str] = ()) -> Path:
    """A stand-in BIFF8 workbook: OLE2 header, then SST-style records, then binary noise.

    Each string is written the way BIFF8's shared-string table stores it:
    a 2-byte length, an option byte (1 = UTF-16LE, 0 = one byte per char),
    then the characters.  ``compressed`` strings use the one-byte form.
    """
    body = bytearray(strip_rule.OLE2_MAGIC + bytes(range(0x20)) * 4)
    for s, flag, enc in [(s, 1, "utf-16-le") for s in strings] + [(s, 0, "latin-1") for s in compressed]:
        body += len(s).to_bytes(2, "little") + bytes([flag]) + s.encode(enc)
        body += b"\x00\x01\x02\x03\xfd\x00\x0a\x00"  # a BIFF record header-ish separator
    body += bytes(range(256)) * 8
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(bytes(body))
    return path


XLS_TABLE = ["", "(1)", "(2)", "(3)", "lnwage", "female", "(0.012)", "Observations", "R-squared"]
XLS_DATA = ["state", "year", "district", "sponsor_id", "party", "Democrats", "Republicans"]
# Stata ``export excel`` of a coefficient matrix, as the Gagliarducci 2022 package ships it.
XLS_MATRIX = ["sampletype", "All", "Democrats", "OLS_all", "OLS_all_stars", "RD_bwidth", "RD_bwidth_stars"]
XLS_MATRIX += ["PS_match", "PS_match_stars", "***"]


def test_binary_xls_regression_table_is_stripped_and_data_xls_is_kept(tmp_path):
    table = _xls(tmp_path / "t.xls", XLS_TABLE)
    data = _xls(tmp_path / "d.xls", XLS_DATA)
    assert strip_rule._xls_strings(table.read_bytes())  # the strings are found
    assert content_reason(table) == "regression-table"
    assert content_reason(data) is None
    # One-byte ("compressed") BIFF strings are read too.
    assert content_reason(_xls(tmp_path / "c.xls", [], compressed=XLS_TABLE)) == "regression-table"


def test_stata_export_excel_matrix_is_stripped_as_xls_and_xlsx(tmp_path):
    assert content_reason(_xls(tmp_path / "m.xls", XLS_MATRIX)) == "regression-table"
    assert content_reason(_xlsx(tmp_path / "m.xlsx", XLS_MATRIX)) == "regression-table"
    # A placebo table: no stars anywhere, but three estimate / stars column pairs.
    placebo = [s for s in XLS_MATRIX if s != "***"]
    assert content_reason(_xls(tmp_path / "p.xls", placebo)) == "regression-table"
    # One pair, or a ``_stars`` column without its estimate column, is not enough.
    assert content_reason(_xls(tmp_path / "h.xls", ["hotel", "hotel_stars", "city", "***"])) is None
    assert content_reason(_xls(tmp_path / "r.xls", ["review_stars", "food_stars", "room_stars"])) is None


@pytest.mark.parametrize(
    "name", ["Table5_TopPanel_Cosponsors.xls", "Table5_BottomPanel_PctCosponsorsOpposite.xls", "data.xls"]
)
def test_xls_decision_is_by_content_not_name(tmp_path, name):
    assert content_reason(_xls(tmp_path / "table" / name, XLS_TABLE)) == "regression-table"
    assert content_reason(_xls(tmp_path / "data" / name, XLS_DATA)) is None


def test_xls_without_strings_or_over_the_cap_is_kept(tmp_path):
    empty = _write(tmp_path, "empty.xls", strip_rule.OLE2_MAGIC + b"\x00\x01" * 512)
    assert content_reason(empty) is None
    table = _xls(tmp_path / "t.xls", XLS_TABLE)
    assert content_reason(table, size_cap=100) is None


def test_text_xls_still_takes_the_text_path(tmp_path):
    # outreg2's ``.xls`` is tab-separated text, not BIFF.
    text = "\t(1)\t(2)\n\ty\ty\nx\t0.543***\t0.512***\n\t(0.012)\t(0.013)\n\t(0.1)\t(0.2)\n"
    text += "Observations\t1000\t1000\nR-squared\t0.660\t0.661\n"
    assert content_reason(_write(tmp_path, "table2.xls", text)) == "regression-table"


def test_manuscript_tex_with_an_inline_regression_table_is_stripped(tmp_path):
    inline = MANUSCRIPT_TEX.replace(r"\input{table1.tex}", ESTTAB_TEX)
    assert content_reason(_write(tmp_path, "main.tex", inline)) == "regression-table"
    assert content_reason(_write(tmp_path, "plain.tex", MANUSCRIPT_TEX)) is None


def test_binary_files_are_not_content_tested(tmp_path):
    path = _write(tmp_path, "blob.bin", b"\x00\x01" + STATA_LOG.encode())
    assert content_reason(path) is None
