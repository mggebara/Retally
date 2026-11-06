# Evidence report: brouwer-2022-teaching-norms

**Teaching Norms: Direct Evidence of Parental Transmission** — Thijs Brouwer, Fabio Galeotti, Marie Claire Villeval

- Paper: https://hal.science/hal-03793652v1/document
- I4R report: https://www.econstor.eu/bitstream/10419/286490/1/I4R-DP106.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/brouwer-2022-teaching-norms.yaml`
- Data access: public

> Headline finding: in a natural field experiment near 30 Lyon elementary schools (601 targeted parents, May-June 2019), parents walking with their child are more likely to confront a litterer directly (Table 2 col 2: Child 0.12, SE 0.04; raw rates 22 vs 11 percent, Figure 1a) and more likely to help a stranger who drops their belongings (col 4: Child 0.22, SE 0.06; 47 vs 26 percent).  They are not more likely to punish indirectly by withholding help (col 4: Child x VH -0.07, SE 0.08, not significant).  With a helping opportunity, direct punishment by parents with children falls (Child x VH -0.12, SE 0.04, col 2), which the authors read as greater fear of retaliation.
> Curation pass (2026-11-01).  Pinned 12 claims, all from Table 2: Child in columns 1-4, VH in columns 2 and 4, Child x VH in columns 1-4 (each with its school-clustered SE in standard_error, printed to two decimals, so the printed-precision floor is +/-0.005), and two observation counts.  Column 2 (punishment, controls) has 399 and column 3 (helping, no controls) has 401; columns 1 and 4 have 400, and all four have 30 school clusters.  Columns 1 and 3 have no controls and are saturated in Child x VH, so their coefficients are differences in the Figure 1 rates printed in the paper (0.11, 0.22, 0.07, 0.05 and 0.26, 0.47, 0.16, 0.31).  A model that reads Figure 1 can derive them; the controlled columns 2 and 4 are not derivable that way.  Left out: the VH rows of columns 1 and 3 (also pure rate differences), the control coefficients, constants, R2 (0.04 / 0.07 / 0.06 / 0.13) and F (7.74 / 5.17 / 7.36 / 6.45), Table 1 summary statistics, the in-text chi-squared tests (4.39, 9.82, 6.26, 12.37, 0.98), the witness confidence intervals, and everything in the appendix (logit marginal effects, Table A7 sample restrictions, A9/A10 heterogeneity, vignette and video studies).
> Paper version check (brief step 1).  Table 2 in the July 2022 submitted version (hal-03725575) and in the August 2022 accepted manuscript (hal-03793652, the paper.source) is identical.  Both equal the six distinct Table 2 o_coeff / o_std_err pairs of the I4R meta-database: 0.12 (0.04), 0.22 (0.06), -0.04 (0.03), -0.10 (0.04), -0.12 (0.04), -0.07 (0.08).  The OUP typeset version could not be fetched (403); the accepted manuscript is what the EJ typeset.
> Independent cross-check (not the package code: pandas / statsmodels OLS with school-clustered SEs on master.csv).  Reproduces every pinned value at the printed precision.  Col 1: Child 0.1100 (0.0481), VH -0.0400 (0.0312), Child x VH -0.1300 (0.0446), N 400.  Col 2: 0.1161 (0.0441), -0.0386 (0.0285), -0.1223 (0.0429), N 399.  Col 3: 0.2126 (0.0546), -0.0974 (0.0453), -0.0626 (0.0710), N 401.  Col 4: 0.2214 (0.0568), -0.1035 (0.0436), -0.0677 (0.0772), N 400.  30 clusters throughout; R2 0.043 / 0.068 / 0.060 / 0.131.
> Package structure (package-only facts; never in contexts).  master.csv / master.dta columns include School (30 school codes, e.g. "CB"), day, Child (0/1), scene and Condition (strings), Violation, ViolationHelp, Help (scene dummies), Punishment, Helping, HelpingParents, male (target is a father; one missing), hugo (male actor), Morning, witness, rich, Rain, Hot, inc_Q, povrate, response2, OwnChild, numkids and child-age dummies.  Table 2 in the do-file: `reg Punishment i.Child##i.ViolationHelp [$controls] if Help==0, cluster(School)` and `reg Helping i.Child##i.ViolationHelp [$controls] if Violation==0, cluster(School)`, with $controls = i.male i.hugo i.Morning i.witness i.rich i.Rain i.Hot, written by esttab to Results/Table2.tex.  The do-file sets a hard-coded global PATH with Windows backslash paths ("$PATH\Data") and needs esttab (ssc).
> Strip-rule change made with this entry.  benchmark/strip_rule.py now content-tests .pdf files with pymupdf, the pipeline's own PDF parser. A PDF is withheld as regression-table when one page carries three of the five regression-table markers the .tex test counts: Observations, an R2 row, a standard-errors note, a significance-star legend, and three or more parenthesised SEs.  There is no table-tool shortcut, and unreadable PDFs are kept.  Here it withholds the accepted manuscript PDF and the online appendix PDF.  Over the 97 PDFs in the 18 locally cached packages, every non-manuscript PDF (README, codebook, IRB, instructions, pre-registration) scores 0 or 1 and is kept.  The manuscript and appendix PDFs of dincecco-2022 (4) and hanlon-2022 (3) are newly withheld too; hanlon-2022's notes recorded that leak.
> What was read.  Both HAL PDFs (main text and Table 2; the July version's appendix skimmed); I4R DP 106 (EconStor PDF, sections 2-4 and Tables 3-5); the meta-database's 285 rows; Zenodo API metadata; the whole package listing, the ReadMe PDF, the do-file's Table 2 block, the master.csv header, and the kept Results/*.tex tables (to confirm none carries a Table 2 number).
> What could not be verified.  The OUP typeset PDF (403), though the accepted manuscript is text-identical to the package's accepted PDF. The do-file was not run.  DP 106 says the authors later sent I4R the variable-construction code and "incorporated it into the replication package".  Zenodo 7045559 has a single version (2022-09-03) without that code, so the update, if any, lives elsewhere (perhaps the EJ's own copy or I4R's Zenodo 8114738); it does not affect the analysis data.
> Curation check (2026-11-01, zero cost).  `benchmark.runner --llm-oracle curation-check --only brouwer-2022-teaching-norms`, run once in each of --mode blind and --mode independent.  Both cells stopped as llm_answer_pending on the first call, the methodology summary.  That prompt embeds the paper text, Table 2 included, by design; it carried no package script text, file names or claim tokens.  The project downloader fetched Zenodo 7045559, and the script-free copy withholds 18 files (16 plus two __MACOSX stubs); no Table 2 cell occurs in what it keeps.  The blind code-generation prompt for these claims is checked by tests/test_blind_prompt.py (passes).
> Original analysis in Stata (one do-file); language is r, the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `child_punishment_no_controls` | 0.11 | 0.05 | Table 2, column (1) Punishment, row Child | 0.11 | matches |
| 1 | `child_punishment_controls` | 0.12 | 0.04 | Table 2, column (2) Punishment, row Child | 0.12 | matches |
| 2 | `child_helping_no_controls` | 0.21 | 0.05 | Table 2, column (3) Helping, row Child | 0.21 | matches |
| 3 | `child_helping_controls` | 0.22 | 0.06 | Table 2, column (4) Helping, row Child | 0.22 | matches |
| 4 | `vh_punishment_controls` | -0.04 | 0.03 | Table 2, column (2) Punishment, row VH | -0.04 | matches |
| 5 | `vh_helping_controls` | -0.1 | 0.04 | Table 2, column (4) Helping, row VH | -0.1 | matches |
| 6 | `child_x_vh_punishment_no_controls` | -0.13 | 0.04 | Table 2, column (1) Punishment, row Child x VH | -0.13 | matches |
| 7 | `child_x_vh_punishment_controls` | -0.12 | 0.04 | Table 2, column (2) Punishment, row Child x VH | -0.12 | matches |
| 8 | `child_x_vh_helping_no_controls` | -0.06 | 0.07 | Table 2, column (3) Helping, row Child x VH | -0.06 | matches |
| 9 | `child_x_vh_helping_controls` | -0.07 | 0.08 | Table 2, column (4) Helping, row Child x VH | -0.07 | matches |
| 10 | `observations_punishment_controls` | 399 | — | Table 2, column (2), Observations | 399 | matches |
| 11 | `observations_helping_no_controls` | 401 | — | Table 2, column (3), Observations | 401 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[12/12](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [12/12](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[12/12](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[12/12](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [12/12](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[12/12](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[12/12](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261102T064502Z/CELL.md) (20261102T064502Z) | [12/12](independent/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) | [12/12](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) |
| `pipeline-desktop-opus-postfix` | — | [12/12](independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md) (20261103T062157Z) | [12/12](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) (20261103T062809Z) |
| `pipeline-desktop-opus-postfix2` | — | [12/12](independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md) (20261103T110326Z) | [12/12](blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md) (20261103T111134Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) (20261102T091036Z) | [12/12](independent/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md) (20261102T090216Z) | [12/12](blind/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md) (20261102T090216Z) |
| `pipeline-desktop-opus-run3` | [12/12](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [12/12](independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) | [12/12](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) (20261103T004800Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `child_punishment_controls` | 0.116104 | 0.12 | ±0.005 (printed_precision) | 0.779 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `child_punishment_controls` | 0.116104 | 0.12 | ±0.005 (printed_precision) | 0.779 | PASS |
| [seeded/pipeline-desktop-opus/20261102T064502Z](seeded/pipeline-desktop-opus/20261102T064502Z/CELL.md) | `child_punishment_controls` | 0.116104 | 0.12 | ±0.005 (printed_precision) | 0.779 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261102T091036Z](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) | `child_punishment_controls` | 0.116104 | 0.12 | ±0.005 (printed_precision) | 0.779 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261103T010557Z](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) | `child_punishment_controls` | 0.116104 | 0.12 | ±0.005 (printed_precision) | 0.779 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `vh_helping_controls` | -0.103548 | -0.1 | ±0.005 (printed_precision) | 0.710 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `vh_helping_controls` | -0.103548 | -0.1 | ±0.005 (printed_precision) | 0.710 | PASS |
| [seeded/pipeline-desktop-opus/20261102T064502Z](seeded/pipeline-desktop-opus/20261102T064502Z/CELL.md) | `vh_helping_controls` | -0.103548 | -0.1 | ±0.005 (printed_precision) | 0.710 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261102T091036Z](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) | `vh_helping_controls` | -0.103548 | -0.1 | ±0.005 (printed_precision) | 0.710 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261103T010557Z](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) | `vh_helping_controls` | -0.103548 | -0.1 | ±0.005 (printed_precision) | 0.710 | PASS |

### Declared deviations

_No cell declared a deviation._

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T05:55:30Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T19:33:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T064502Z

[`seeded/pipeline-desktop-opus/20261102T064502Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T064502Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T06:45:02Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T091036Z

[`seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T09:10:36Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T06:02:00Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T07:03:00Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T19:59:37Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T062442Z

[`independent/pipeline-desktop-opus/20261102T062442Z/CELL.md`](independent/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T062157Z

[`independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T062157Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T06:21:57Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix2 · 20261103T110326Z

[`independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md`](independent/pipeline-desktop-opus-postfix2/20261103T110326Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T11:03:26Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T090216Z

[`independent/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T09:02:16Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T004800Z

[`independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T06:05:00Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T07:02:38Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T20:13:14Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T062442Z

[`blind/pipeline-desktop-opus/20261102T062442Z/CELL.md`](blind/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T062809Z

[`blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T062809Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T06:28:09Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix2 · 20261103T111134Z

[`blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md`](blind/pipeline-desktop-opus-postfix2/20261103T111134Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T11:11:34Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T090216Z

[`blind/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T090216Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-02T09:02:16Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T004800Z

[`blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T004800Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-03T00:48:00Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

