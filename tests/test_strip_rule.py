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


def _knitr_html(n_chunks: int, cls: str = "r") -> str:
    chunk = (
        f'<pre class="{cls}"><code>df &lt;- read_rds("data.rds") %&gt;% filter(x == 0)</code></pre>\n'
        "<pre><code>## filter: removed 3,784 rows (48%), 4,094 rows remaining</code></pre>\n"
    )
    return (
        '<html><head><meta name="generator" content="pandoc" /></head><body>'
        + chunk * n_chunks
        + "</body></html>"
    )


def test_rendered_r_markdown_html_is_stripped(tmp_path):
    # Bokobza 2022 ships its R script's knitted log as .html: code chunks plus their output.
    assert content_reason(_write(tmp_path, "log.html", _knitr_html(6))) == "script-content:r"
    assert content_reason(_write(tmp_path, "nb.html", _knitr_html(6, "highlight hl-ipython3"))) == (
        "script-content:python"
    )


def test_html_with_a_few_code_snippets_is_kept(tmp_path):
    # A codebook / README page showing how to load the data is documentation, not the script.
    assert content_reason(_write(tmp_path, "readme.html", _knitr_html(2))) is None
    assert (
        content_reason(_write(tmp_path, "codebook.html", "<html><body><p>id: identifier</p></body></html>"))
        is None
    )


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


# estout with an ``N`` row and stars in their own column: no "Observations",
# no R-squared, no table-tool signature (Carrera et al. 2022 ships its
# Tables 3-4 this way).
ESTOUT_N_TEX = r"""\begin{tabular}{l*{2}{r @{} l}}
\hline
                         &\multicolumn{2}{c}{(1)}&\multicolumn{2}{c}{(2)}\\
\hline
Treatment                &     --0.022&   &     --0.023&   \\
                         &     (0.041)&   &     (0.041)&   \\
Premium (z-score)        &            &   &       0.027&** \\
                         &            &   &     (0.011)&   \\
\hline Wave FEs          &         Yes&   &         Yes&   \\
N                        &       2,824&   &       2,824&   \\
Clusters                 &       1,126&   &       1,126&   \\
\hline\hline
\end{tabular}
"""

SUMMARY_N_TEX = r"""\begin{tabular}{lcccc}
\hline
 & Wave 1 & Wave 2 & Wave 3 & Overall \\
Female & 0.66 & 0.61 & 0.57 & 0.61 \\
 & (0.47) & (0.49) & (0.50) & (0.49) \\
Age & 30.93 & 34.55 & 34.38 & 33.51 \\
 & (12.61) & (15.29) & (15.70) & (14.82) \\
N & 340 & 509 & 399 & 1,248 \\
\hline
\end{tabular}
"""


def test_estout_table_with_an_n_row_is_stripped_but_a_summary_table_is_kept(tmp_path):
    assert content_reason(_write(tmp_path, "regs.tex", ESTOUT_N_TEX)) == "regression-table"
    # An N row and parenthesised SDs alone (no numbered columns) stay: summary statistics.
    assert content_reason(_write(tmp_path, "descriptive.tex", SUMMARY_N_TEX)) is None


# Hanlon (2022) ships esttab output split into row-only fragments
# (``3 replication files/tables/Table1_R.tex``, ``Table1_N.tex``): no tabular, no caption,
# no ``Observations`` label.  Verbatim from the package.
HANLON_TABLE1_R_TEX = r"""Before 1926 $\times$ year $\times$ US   &     0.013&    -0.001&          &     0.004&    -0.028&          &    -0.005&    -0.031\\
                                        &   (0.006)&   (0.006)&          &   (0.009)&   (0.009)&          &   (0.010)&   (0.009)\\
After 1926 $\times$ year $\times$ US    &     0.074&     0.067&          &     0.025&     0.031&          &     0.023&     0.024\\
                                        &   (0.006)&   (0.006)&          &   (0.010)&   (0.010)&          &   (0.010)&   (0.009)\\
"""  # noqa: E501
HANLON_TABLE1_N_TEX = (
    r"observations                            &       116&       174&          &       165&       233&"
    r"          &       140&       192\\" + "\n"
)
HANLON_TABLE1_F_TEX = (
    r"$ F $-statistic                         &      34.7&      37.6&          &       1.5&      11.4&"
    r"          &       2.5&      13.3\\" + "\n"
)
# Descriptive fragments in the same folder (``Table2_PRE.tex``, ``TableF1_match_boeing.tex``).
DESCRIPTIVE_FRAGMENT_TEX = r"""Before 1926                             &    0.5366&    0.4118&    0.2581&    0.7333\\
boeing              &    0.2917&    0.9375&          &    0.3750&    0.0312\\
"""  # noqa: E501
STARRED_FRAGMENT_TEX = r"""\hline
Treatment     &     0.074**&     0.067*  \\
Control mean  &     1.20   &     1.31    \\
Female        &    -0.012***&   -0.010$^{**}$\\
\hline
"""


def test_row_only_table_fragments_are_stripped(tmp_path):
    assert content_reason(_write(tmp_path, "Table1_R.tex", HANLON_TABLE1_R_TEX)) == "table-fragment"
    assert content_reason(_write(tmp_path, "Table1_N.tex", HANLON_TABLE1_N_TEX)) == "table-fragment"
    assert content_reason(_write(tmp_path, "Table1_F.tex", HANLON_TABLE1_F_TEX)) == "table-fragment"
    assert content_reason(_write(tmp_path, "stars.tex", STARRED_FRAGMENT_TEX)) == "table-fragment"
    assert content_reason(_write(tmp_path, "Table1_R.txt", HANLON_TABLE1_R_TEX)) == "table-fragment"


def test_descriptive_fragments_and_prose_are_kept(tmp_path):
    # Shares with no SEs or stars: a descriptive fragment stays.
    assert content_reason(_write(tmp_path, "Table2_PRE.tex", DESCRIPTIVE_FRAGMENT_TEX)) is None
    # A single parenthesised number is not enough.
    one_se = DESCRIPTIVE_FRAGMENT_TEX + r"  &  (0.012) & \\" + "\n"
    assert content_reason(_write(tmp_path, "one_se.tex", one_se)) is None
    # Rows are a minority of the file: prose with a couple of rows stays.
    prose = "A paragraph of text about the estimates.\n" * 10
    assert content_reason(_write(tmp_path, "notes.tex", prose + HANLON_TABLE1_R_TEX)) is None
    # A whole summary tabular with SDs in parentheses stays (the fragment rule needs no environment).
    assert content_reason(_write(tmp_path, "descriptive.tex", SUMMARY_N_TEX)) is None
    # Other suffixes do not take the fragment path.
    assert content_reason(_write(tmp_path, "Table1_R.md", HANLON_TABLE1_R_TEX)) is None


# Whole regression tables with no ``N`` row and a single ``(1)`` column, so neither the
# observations marker nor the numbered-columns marker fires: stars plus SEs decide.  And two
# balance tables (means, SDs in parentheses, no stars) that must stay.  Verbatim from the
# packages (Brouwer 2022 ``Results/TableA14.tex``, Carrera 2022 ``Output/DailyAttIncr.tex``,
# Brouwer 2022 ``Results/TableA3.tex``, Altmann 2022 ``out/tableO_1.tex``).
BROUWER_TABLEA14_TEX = r"""{
\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
\begin{tabular}{l*{1}{r}}
\toprule
                    &\multicolumn{1}{c}{(1)}   \\
\midrule
Social image        &       -1.43***\\
                    &      (0.20)   \\
Norm enforcement    &        0.21   \\
                    &      (0.18)   \\
Other reasons       &       -2.68***\\
                    &      (0.38)   \\
\midrule
Teaching            &        0.39   \\
Social image        &        0.09   \\
Norm enforcement    &        0.49   \\
Other reasons       &        0.03   \\
\bottomrule
\end{tabular}
}
"""  # noqa: E501
CARRERA_DAILYATTINCR_TEX = r"""\begin{tabular}{l*{1}{r @{} l}}
\hline
            &\multicolumn{2}{c}{\shortstack{Attendance \\ likelihood}}\\
            &\multicolumn{2}{c}{(1)}\\
\hline
Day         &     --0.005&***\\
            &     (0.001)&   \\
12+ visits contract&       0.051&   \\
            &     (0.045)&   \\
Day $\times$ 12+ visits contract&       0.005&** \\
            &     (0.002)&   \\
\hline
Wave FEs    &         Yes&   \\
N           &       7,336&   \\
Clusters    &         262&   \\
\hline\hline
\end{tabular}
"""  # noqa: E501
BROUWER_TABLEA3_TEX = r"""{
\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
\begin{tabular}{l*{4}{rrrrr}}
\toprule
                    &\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}         \\
                    &         All&       Alone&       Child&       Diff.         \\
\midrule
Own Child           &        0.88&        0.91&        0.85&        0.06         \\
                    &      (0.33)&      (0.29)&      (0.36)&      (0.05)         \\
Son                 &        0.61&        0.62&        0.61&        0.01         \\
                    &      (0.49)&      (0.49)&      (0.49)&      (0.07)         \\
Daughter            &        0.64&        0.63&        0.64&       -0.01         \\
                    &      (0.48)&      (0.49)&      (0.48)&      (0.07)         \\
No. of Children     &        1.46&        1.40&        1.52&       -0.12         \\
                    &      (0.64)&      (0.59)&      (0.67)&      (0.09)         \\
Child Age = 3       &        0.06&        0.06&        0.06&       -0.00         \\
                    &      (0.25)&      (0.24)&      (0.25)&      (0.03)         \\
Child Age = 4       &        0.16&        0.16&        0.17&       -0.01         \\
                    &      (0.37)&      (0.37)&      (0.38)&      (0.05)         \\
Child Age = 5       &        0.26&        0.25&        0.27&       -0.02         \\
                    &      (0.44)&      (0.44)&      (0.45)&      (0.06)         \\
Child Age = 6       &        0.18&        0.17&        0.19&       -0.03         \\
                    &      (0.39)&      (0.38)&      (0.40)&      (0.05)         \\
Child Age = 7       &        0.23&        0.19&        0.26&       -0.07         \\
                    &      (0.42)&      (0.39)&      (0.44)&      (0.06)         \\
Child Age = 8       &        0.21&        0.23&        0.20&        0.03         \\
                    &      (0.41)&      (0.42)&      (0.40)&      (0.06)         \\
Child Age = 9       &        0.19&        0.15&        0.22&       -0.07         \\
                    &      (0.39)&      (0.36)&      (0.41)&      (0.05)         \\
Child Age = 10      &        0.08&        0.11&        0.06&        0.05         \\
                    &      (0.27)&      (0.31)&      (0.23)&      (0.04)         \\
Child Age = 11      &        0.03&        0.03&        0.03&       -0.00         \\
                    &      (0.18)&      (0.18)&      (0.18)&      (0.02)         \\
\bottomrule
\end{tabular}
}
"""  # noqa: E501
ALTMANN_TABLEO_1_TEX = r"""   \begin{tabular}{l*{13}{c}}
\toprule
                &\multicolumn{4}{c}{\textsc{Baseline}}  &\multicolumn{4}{c}{\textsc{Directed Attention}}&\multicolumn{4}{c}{\textsc{Forced Choice}}&\multicolumn{1}{c}{Kruskal-Wallis}\\\cmidrule(lr){2-5}\cmidrule(lr){6-9}\cmidrule(lr){10-13}\cmidrule(lr){14-14}
                &       10&       20&       40&    Ample&       10&       20&       40&    Ample&       10&       20&       40&    Ample&  p-value\\
\midrule
Ability Background Task (std.)&    -0.08&     0.11&     0.08&     0.16&     0.01&    -0.10&     0.28&    -0.11&    -0.01&     0.28&    -0.17&    -0.09&     0.48\\
                &   (1.05)&   (0.90)&   (1.19)&   (0.87)&   (1.03)&   (0.80)&   (0.91)&   (0.97)&   (0.98)&   (0.83)&   (1.23)&   (1.14)&         \\
\addlinespace
Ability Decision Task (std.)&    -0.03&     0.07&     0.21&     0.08&    -0.10&     0.09&     0.21&     0.12&    -0.01&     0.23&    -0.47&    -0.13&     0.35\\
                &   (1.13)&   (1.02)&   (0.70)&   (1.02)&   (0.93)&   (0.96)&   (0.71)&   (0.92)&   (1.01)&   (0.74)&   (1.27)&   (1.05)&         \\
\addlinespace
Age             &    23.76&    23.74&    22.78&    23.13&    24.39&    23.14&    25.63&    23.33&    23.70&    23.62&    22.80&    24.74&     0.37\\
                &   (5.53)&   (4.44)&   (3.62)&   (4.30)&   (5.08)&   (3.76)&  (10.93)&   (3.54)&   (4.37)&   (4.66)&   (3.14)&   (6.09)&         \\
\addlinespace
Female          &     0.58&     0.51&     0.61&     0.59&     0.54&     0.60&     0.37&     0.62&     0.51&     0.65&     0.65&     0.55&     0.66\\
                &   (0.50)&   (0.51)&   (0.50)&   (0.50)&   (0.50)&   (0.50)&   (0.50)&   (0.49)&   (0.50)&   (0.48)&   (0.49)&   (0.50)&         \\
\addlinespace
\% Economists   &     0.13&     0.12&     0.17&     0.18&     0.16&     0.14&     0.11&     0.13&     0.17&     0.10&     0.10&     0.16&     0.96\\
                &   (0.33)&   (0.32)&   (0.38)&   (0.39)&   (0.37)&   (0.35)&   (0.32)&   (0.34)&   (0.38)&   (0.30)&   (0.31)&   (0.36)&         \\
\addlinespace
Perceived multitasking, relative&    54.97&    50.44&    51.94&    58.60&    51.30&    52.64&    62.79&    61.64&    53.43&    56.42&    59.35&    57.51&     0.00\\
                &  (18.97)&  (19.22)&  (20.40)&  (18.39)&  (20.69)&  (18.76)&  (20.64)&  (18.29)&  (19.04)&  (21.20)&  (13.65)&  (18.37)&         \\
\addlinespace
Perceived multitasking, Likert&     3.07&     3.28&     3.50&     2.78&     3.23&     3.14&     2.79&     2.66&     3.18&     3.08&     3.35&     2.64&     0.00\\
                &   (0.78)&   (0.77)&   (1.04)&   (0.76)&   (0.84)&   (0.75)&   (0.98)&   (0.82)&   (0.74)&   (0.80)&   (0.67)&   (0.65)&         \\
\addlinespace
Raven Score     &     6.12&     5.98&     6.72&     6.09&     6.17&     6.21&     6.84&     6.20&     5.93&     6.47&     6.30&     6.06&     0.34\\
                &   (1.48)&   (1.39)&   (1.49)&   (1.87)&   (1.58)&   (1.88)&   (1.64)&   (1.63)&   (1.53)&   (1.52)&   (1.84)&   (1.97)&         \\
\midrule
Participant in First wave&      .66&        0&        0&        1&      .66&        0&        0&        1&      .64&        0&        0&        1\\
                &         &         &         &         &         &         &         &         &         &         &         &         \\
\midrule
N               &      143&       43&       18&       94&      145&       42&       19&       94&      138&       40&       20&       96\\
                &         &         &         &         &         &         &         &         &         &         &         &         \\
\bottomrule
\end{tabular}
"""  # noqa: E501


def test_single_column_regression_tables_with_stars_and_ses_are_stripped(tmp_path):
    assert content_reason(_write(tmp_path, "TableA14.tex", BROUWER_TABLEA14_TEX)) == "regression-table"
    assert (
        content_reason(_write(tmp_path, "DailyAttIncr.tex", CARRERA_DAILYATTINCR_TEX)) == "regression-table"
    )


def test_balance_tables_without_stars_are_kept(tmp_path):
    assert content_reason(_write(tmp_path, "TableA3.tex", BROUWER_TABLEA3_TEX)) is None
    assert content_reason(_write(tmp_path, "tableO_1.tex", ALTMANN_TABLEO_1_TEX)) is None
    # One starred row is not enough, nor are stars without standard errors.
    one_star = BROUWER_TABLEA14_TEX.replace("-2.68***", "-2.68   ")
    assert content_reason(_write(tmp_path, "one_star.tex", one_star)) is None
    no_se = "\n".join(ln for ln in BROUWER_TABLEA14_TEX.splitlines() if "(0." not in ln)
    assert content_reason(_write(tmp_path, "no_se.tex", no_se)) is None


RESULT_MACROS_TEX = r"""\newcommand{\lowwtpobs}{32}
\newcommand{\committwelveobs}{1{,}248}
\newcommand{\actexpmean}{-4.17}
\newcommand{\enhinfobcpcoeff}{1.36}
\newcommand{\lambdaallCI}{(0.06, 0.07)}
\newcommand{\pctfemale}{61}  % share female
\def\attcoeffse{0.028}
"""


def test_numeric_newcommand_file_is_stripped_as_result_macros(tmp_path):
    assert content_reason(_write(tmp_path, "numbers.tex", RESULT_MACROS_TEX)) == "result-macros"
    # Text macros are not results.
    words = "".join(rf"\newcommand{{\m{c}}}{{\textsf{{word}}}}" + "\n" for c in "abcdefg")
    assert content_reason(_write(tmp_path, "macros.tex", words)) is None
    # A few numeric macros inside a longer non-manuscript .tex stay.
    prose = "Some sentence of text.\n" * 20
    assert content_reason(_write(tmp_path, "section.tex", RESULT_MACROS_TEX + prose)) is None
    # A manuscript that defines its numbers in the preamble takes the manuscript path.
    doc = r"\documentclass{article}" + "\n" + RESULT_MACROS_TEX + r"\begin{document}x\end{document}"
    assert content_reason(_write(tmp_path, "paper.tex", doc)) is None


def _pdf(path: Path, pages: list[str]) -> Path:
    import fitz

    path.parent.mkdir(parents=True, exist_ok=True)
    doc = fitz.open()
    for text in pages:
        doc.new_page().insert_text((50, 60), text, fontsize=9)
    doc.save(path)
    doc.close()
    return path


# A manuscript page as pymupdf extracts it: one cell per line.
PDF_TABLE_PAGE = "\n".join(
    [
        "Table 2: Determinants of Punishment Rate",
        "(1)", "(2)", "Child", "0.31**", "0.27**", "(0.09)", "(0.08)",
        "VH", "-0.05", "-0.06", "(0.02)", "(0.03)",
        "Observations", "512", "511", "R2", "0.05", "0.09",
        "Notes: Standard errors in parentheses are clustered at the school level.",
        "* p < 0.10 ** p < 0.05 *** p < 0.01.",
    ]
)  # fmt: skip

PDF_README_PAGE = "\n".join(
    [
        "ReadMe: replication package",
        "Data/master.dta holds one row per observation (601 observations).",
        "Run Do/analysis.do in Stata 16; tables are written with esttab.",
        "Variables: child (0/1), punish (0/1), help (0/1), school (1-30).",
    ]
)


def test_manuscript_pdf_with_a_regression_table_is_stripped_but_readme_pdf_is_kept(tmp_path):
    manuscript = _pdf(tmp_path / "1 paper" / "MS_accepted.pdf", ["Introduction text.", PDF_TABLE_PAGE])
    readme = _pdf(tmp_path / "ReadMe.pdf", [PDF_README_PAGE])
    assert content_reason(manuscript) == "regression-table"
    assert content_reason(readme) is None
    stripped = {s.path: s.reason for s in classify_tree(tmp_path)}
    assert stripped == {"1 paper/MS_accepted.pdf": "regression-table"}


def test_pdf_markers_must_sit_on_one_page_and_unreadable_pdfs_are_kept(tmp_path):
    lines = PDF_TABLE_PAGE.splitlines()
    # Two markers on the first page (SE rows, Observations), one on each later page.
    pages = [lines[:16], lines[16:19], lines[19:20], lines[20:]]
    split = _pdf(tmp_path / "split.pdf", ["\n".join(p) for p in pages])
    assert content_reason(split) is None
    broken = _write(tmp_path, "broken.pdf", b"%PDF-1.4\n" + PDF_TABLE_PAGE.encode())
    assert content_reason(broken) is None


# A manuscript page whose table is an image: only the caption and the note
# reach the text layer, and the note writes the significance legend out
# (EJ style; Mokyr et al. 2022 ships its accepted manuscript this way).
PDF_IMAGE_TABLE_PAGE = "\n".join(
    [
        "Table 2: The no. of wrights and Domesday Book watermills - OLS estimates",
        "Notes: All observations are clustered at the historical county level.",
        "Heteroskedasticity robust standard error estimates are reported in parentheses;",
        "*** denotes statistical significance at the 1% level, ** at the 5% level,",
        "and * at the 10% level. All regressions include a constant.",
    ]
)


def test_written_out_significance_legend_counts_as_a_marker(tmp_path):
    legend = strip_rule._TABLE_STAT_MARKERS[3]
    assert legend.search("*** denotes statistical significance at the 1% level")
    assert legend.search("∗∗∗denotes statistical significance at the 1% level")
    assert legend.search("** significant at 5 per cent")
    assert not legend.search("We find a 10% increase. ** footnote")
    manuscript = _pdf(tmp_path / "1 paper" / "MS_accepted.pdf", ["Introduction text.", PDF_IMAGE_TABLE_PAGE])
    assert content_reason(manuscript) == "regression-table"


def _docx(path: Path, paragraphs: list[str]) -> Path:
    """A minimal Word file: one ``w:p`` per paragraph, in ``word/document.xml``."""
    from xml.sax.saxutils import escape

    body = "".join(f'<w:p><w:r><w:t xml:space="preserve">{escape(p)}</w:t></w:r></w:p>' for p in paragraphs)
    xml = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        f"<w:body>{body}</w:body></w:document>"
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr("[Content_Types].xml", "<Types/>")
        zf.writestr("word/document.xml", xml)
    return path


DOCX_README = [
    "README: replication files",
    "replication_data.dta holds one row per district (325 observations).",
    "Tables.do creates all the tables in the main text; results are exported to Tables/.",
    "Variables: wrights (sum) no. of apprentices to wrights in the district in 1710-50.",
]


def test_manuscript_docx_is_stripped_but_readme_docx_is_kept(tmp_path):
    tables = _docx(tmp_path / "1 paper" / "MS_tables_ocr.docx", PDF_TABLE_PAGE.splitlines())
    notes = _docx(tmp_path / "1 paper" / "MS_tables_image.docx", PDF_IMAGE_TABLE_PAGE.splitlines())
    readme = _docx(tmp_path / "README.docx", DOCX_README)
    captions = ["Figure 1. Partial correlation", "Source: see text."]
    figures = _docx(tmp_path / "1 paper" / "MS_figures.docx", captions)
    assert content_reason(tables) == "regression-table"
    assert content_reason(notes) == "regression-table"
    assert content_reason(readme) is None
    assert content_reason(figures) is None
    stripped = {s.path: s.reason for s in classify_tree(tmp_path)}
    assert stripped == {
        "1 paper/MS_tables_image.docx": "regression-table",
        "1 paper/MS_tables_ocr.docx": "regression-table",
    }


def test_docx_markers_must_sit_within_one_window_and_broken_docx_is_kept(tmp_path):
    filler = "Prose paragraph without any table marker. " * 80  # longer than one window on its own
    lines = PDF_IMAGE_TABLE_PAGE.splitlines()
    spread = _docx(tmp_path / "spread.docx", [lines[1], filler, lines[2], filler, lines[3]])
    assert content_reason(spread) is None
    broken = _write(tmp_path, "broken.docx", b"PK\x03\x04 not really a zip")
    assert content_reason(broken) is None


# A README's "numbers cited in the text" provenance table, as pymupdf extracts
# it (Henry, Zhuravskaya and Guriev 2022, README.pdf p. 4): each in-text number
# is derived from a quoted coefficient and the table cell it sits in.
README_RESULT_CITATIONS = "\n".join(
    [
        "Table B. Replicating numbers cited in the text:",
        "10.2% ",
        "=14.7%-0.045 (for 0.045, see ",
        "Table 2 Panel A Column 1, ",
        "coefficient on “Imposed Fact-",
        "Check”) ",
        "10.8% ",
        "=14.7%-0.038 (for 0.038, see ",
        "Table 2 Panel A Column 1, ",
        "coefficient on “Voluntary Fact-",
        "Check”) ",
        "11.5% ",
        "=0.143-0.028 (for 0.028, see ",
        "Table 2 Panel B Column 1, ",
        "coefficient on “Voluntary Fact-",
    ]
)

# A README that maps tables to scripts and cites cells without quoting a value.
README_TABLE_MAP = "\n".join(
    [
        "Table A. The lines of the code for replicating tables and figures:",
        "Table 2, Column 1: coefficient on treatment, 2.analysis.do lines 763-1070",
        "Table 2, Column 2: coefficient on treatment, 2.analysis.do lines 763-1070",
        "Table A3, Column 1: coefficient on treatment, 2.analysis.do lines 765-848",
        "Run time: 0.5 hours.",
    ]
)


def test_readme_quoting_estimates_by_table_cell_is_stripped(tmp_path):
    readme = _pdf(tmp_path / "README.pdf", [PDF_README_PAGE, README_RESULT_CITATIONS])
    assert content_reason(readme) == "result-citations"
    word = _docx(tmp_path / "README.docx", README_RESULT_CITATIONS.splitlines())
    assert content_reason(word) == "result-citations"
    # Two citations are not enough; a table-to-script map quotes no value.
    two = _pdf(tmp_path / "two" / "README.pdf", ["\n".join(README_RESULT_CITATIONS.splitlines()[:11])])
    assert content_reason(two) is None
    table_map = _pdf(tmp_path / "map" / "README.pdf", [README_TABLE_MAP])
    assert content_reason(table_map) is None
    assert content_reason(_pdf(tmp_path / "plain" / "README.pdf", [PDF_README_PAGE])) is None


# ---------------------------------------------------------------------------
# R workspaces: a save.image() snapshot taken after the analysis keeps the
# stargazer output (Douenne & Fabre 2022 ship after_papier.RData)
# ---------------------------------------------------------------------------

STARGAZER_ROWS = [
    r"\begin{table}[!htbp] \centering ",
    r"\begin{tabular}{@{\extracolsep{5pt}}lcccc} ",
    r"\\[-1.8ex] & (1) & (2) & (3) & (4)\\ ",
    r" Treated & 0.112 & 0.208 & 0.146 & 0.153 \\ ",
    r"  & (0.058) & (0.035) & (0.064) & (0.045) \\ ",
    r"  Baseline support & 0.406 & 0.331 & 0.025 & 0.310 \\ ",
    r"  & (0.066) & (0.038) & (0.087) & (0.051) \\ ",
    r"Observations & 812 & 2,104 & 812 & 812 \\ ",
    r"R$^{2}$ & 0.301 & 0.320 & 0.419 & 0.253 \\ ",
    r"\end{tabular} ",
]

DATA_STRINGS = [
    "names", "row.names", "data.frame", "Observations", "R2", "Bosnia & Herzegovina",
    "Trinidad & Tobago", "(0.5)", "(1.2)", "(2.0)", "Féminin", "Masculin", "Cadre", "Ouvrier",
]  # fmt: skip


def _rdata(path: Path, strings: list[str], *, compress: str = "gzip") -> Path:
    """A minimal XDR R serialization: header, then each string as a CHARSXP (flags, length, bytes)."""
    import bz2
    import gzip
    import lzma
    import struct

    body = b"RDX3\nX\n" + struct.pack(">iii", 3, 0x040003, 0x030500)
    for i, s in enumerate(strings):
        raw = s.encode("latin-1")
        body += struct.pack(">ii", 0x00040009, len(raw)) + raw + struct.pack(">d", i * 0.5)
    codecs = {"gzip": gzip.compress, "bz2": bz2.compress, "xz": lzma.compress, "none": lambda b: b}
    return _write(path.parent, path.name, codecs[compress](body))


@pytest.mark.parametrize("compress", ["gzip", "bz2", "xz", "none"])
def test_r_workspace_holding_a_stargazer_table_is_stripped(tmp_path, compress):
    strings = DATA_STRINGS + STARGAZER_ROWS + DATA_STRINGS
    path = _rdata(tmp_path / "after_analysis.RData", strings, compress=compress)
    assert content_reason(path) == "regression-table"
    assert {s.path: s.reason for s in classify_tree(tmp_path)} == {"after_analysis.RData": "regression-table"}


def test_r_data_workspaces_and_rds_files_are_kept(tmp_path):
    _rdata(tmp_path / "after_preparation.RData", DATA_STRINGS * 50)
    _rdata(tmp_path / "survey.rda", DATA_STRINGS, compress="xz")
    # A single serialized object (.rds) is data, not a session snapshot: not content-tested.
    _rdata(tmp_path / "table.rds", STARGAZER_ROWS)
    # Not an R serialization at all.
    _write(tmp_path, "odd.rda", b"\x00\x01" + "\n".join(STARGAZER_ROWS).encode())
    assert classify_tree(tmp_path) == []


# Cohen & Dechezleprêtre (2022) ship every regression three ways the rule used to keep:
# Stata ``estimates save`` files (``.ster``, binary), ``esttab ... using "Table 5.rtf"``
# and plain-text ``esttab ... nonumbers`` (no ``(1) (2)`` header).  Shapes from the package,
# numbers shortened.
ESTTAB_RTF = (
    r"{\rtf1\ansi\deff0 {\fonttbl{\f0\fnil Times New Roman;}}" + "\n"
    r"{\info {\author .}{\company .}{\title .}{\creatim\yr2021\mo3\dy6\hr14\min00}}" + "\n"
    r"\deflang1033\plain\fs24" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {}\cell \pard\intbl\qc {y_a}\cell"
    r" \pard\intbl\qc {y_b}\cell\row}" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {treat_cold}\cell"
    r" \pard\intbl\qc {-0.00000031**}\cell \pard\intbl\qc {-0.00000032***}\cell\row}" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {}\cell"
    r" \pard\intbl\qc {(0.00000012)}\cell \pard\intbl\qc {(0.00000011)}\cell\row}" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {treat_mild}\cell"
    r" \pard\intbl\qc {-0.00000017}\cell \pard\intbl\qc {-0.00000017*}\cell\row}" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {}\cell"
    r" \pard\intbl\qc {(0.00000011)}\cell \pard\intbl\qc {(0.00000009)}\cell\row}" + "\n"
    r"{\trowd\trgaph108\cellx1908\cellx3924\cellx5940\pard\intbl\ql {Observations}\cell"
    r" \pard\intbl\qc {18156447450}\cell \pard\intbl\qc {18156447450}\cell\row}" + "\n"
    r"{\pard\ql Standard errors in parentheses\par}" + "\n"
    r"{\pard\ql * p < 0.1, ** p < 0.05, *** p < 0.01\par}" + "\n"
    "}\n"
)
ESTTAB_TXT_NONUMBERS = """\
------------------------------------------------------------
                  DR_A1_D0_P      DR_A2_D0_P      DR_A3_D0_P
------------------------------------------------------------
TREATMENT_scale_12  -0.00000002      0.00000007      0.00000003
                (0.00000004)    (0.00000008)    (0.00000003)
TREATMENT_scale_16  -0.00000004*    -0.00000008      0.00000002
                (0.00000002)    (0.00000005)    (0.00000002)
------------------------------------------------------------
Observations     18156447450     18156447450     18156447450
------------------------------------------------------------
Standard errors in parentheses
* p<0.1, ** p<0.05, *** p<0.01
"""
SUMMARY_RTF = (
    r"{\rtf1\ansi {\trowd\cellx1908\cellx3924\pard\intbl {Variable}\cell {Mean}\cell\row}"
    r"{\trowd\cellx1908\cellx3924\pard\intbl {Deaths}\cell {12.4}\cell\row}"
    r"{\trowd\cellx1908\cellx3924\pard\intbl {}\cell {(3.1)}\cell\row}"
    r"{\trowd\cellx1908\cellx3924\pard\intbl {Observations}\cell {828711}\cell\row}}" + "\n"
)


def test_stata_saved_estimates_are_stripped_by_name(tmp_path):
    ster = _write(tmp_path, "output/Table_5_col_1_A345.ster", b"\x00\x01stata estimates\x00")
    assert strip_reason(ster) == "saved-estimates"
    assert strip_reason(_write(tmp_path, "output/MODEL.STER", b"\x00")) == "saved-estimates"


def test_esttab_rtf_and_unnumbered_text_tables_are_stripped(tmp_path):
    assert content_reason(_write(tmp_path, "output/Table 5.rtf", ESTTAB_RTF)) == "regression-table"
    assert content_reason(_write(tmp_path, "output/Table D1.txt", ESTTAB_TXT_NONUMBERS)) == "regression-table"


def test_summary_rtf_and_unnumbered_summary_text_are_kept(tmp_path):
    # Means with SDs in parentheses and an N row, no legends: summary statistics stay.
    assert content_reason(_write(tmp_path, "Table 1.rtf", SUMMARY_RTF)) is None
    no_legends = ESTTAB_TXT_NONUMBERS.replace("Standard errors in parentheses\n", "").replace(
        "* p<0.1, ** p<0.05, *** p<0.01\n", ""
    )
    assert content_reason(_write(tmp_path, "summary.txt", no_legends)) is None
