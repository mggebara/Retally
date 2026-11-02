# Evidence report: manekin-2022-effective-for-whom

**Effective for Whom? Ethnic Identity and Nonviolent Resistance** — Devorah Manekin, Tamar Mitts

- Paper: https://www.cambridge.org/core/services/aop-cambridge-core/content/view/D78EE1F9EE3B41D6F1500311F17B8EA6/S0003055421000940a.pdf/div-class-title-effective-for-whom-ethnic-identity-and-nonviolent-resistance-div.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/279959/1/I4R-DP086.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/manekin-2022-effective-for-whom.yaml`

> Headline finding: nonviolent protest by ethnic minorities is perceived as more violent and as requiring more police action than identical protest by majorities (Study 1: U.S. Black protesters +0.235 / +0.268 on 0-10 scales; Israel Arab protesters +0.623 / +0.964, Ethiopian +0.425 / +0.181 n.s.), and Study 2 replicates it in June 2020 (U.S. Black protesters +0.347 / +0.429).
> Original analysis in R (base lm() with stargazer output); language: r is the reproduction target and matches the original.
> outcome_label.  The I4R verdict is "minor discrepancies"; the schema has no such label.  The discrepancy is confined to the observational Figure 1 / Table A5 (none pinned) and every pinned table reproduces exactly, so the entry is labelled reproducible (stratification only). DP86's robustness findings (weights, aggregation) would argue for not_robust on the observational claim, which is not pinned.
> Curation pass (2026-10-21).  Pinned 12 claims: the eight protester- identity coefficients for the two outcomes the abstract names (perceived violence, police action required) — Study 1 U.S. (Black), Study 1 Israel (Ethiopian, Arab) and Study 2 U.S. (Black) — each with its SE in standard_error, and the four survey sample sizes stated in the Research Design section and the tables' Observations rows.
> What was read.  The published PDF (abstract, design sections, Tables 1-2), the supplementary information PDF (static.cambridge.org, sample and weighting description), DP86 in full (EconStor), the Dataverse API metadata, the whole package (downloaded to a scratch directory, never committed): the master script and replicate_table_1.R / replicate_table_4.R, and the shipped Tables/*.tex; the meta-database's 43 rows.  No code was run.
> Weights (matters for independent mode).  The main text never mentions weights; the SI says Study 1 oversampled Black Americans and Arab Israelis and uses sample weights.  The package's Table 1 regressions are weighted lm() fits (weights = weight) and the Table 2 regressions are unweighted; the contexts state this from the SI.  A reproducer that ignores the weights gets the meta-database's "Remove weights" values for Study 1 (e.g. U.S. Black perceived violence 0.137 (0.118), police 0.171 (0.127); Israel Arab 0.584 / 0.890, Ethiopian 0.426 / 0.165), which would fail the U.S. claims.  DP86 also reports that the shipped Study 1 weights adjust for ethnicity only (Arabs vs Jews), not age, gender or education.  Standard errors are the default lm() (classical OLS) ones; the paper says only "OLS regressions".
> Package structure (package-only facts; never in contexts).  Replication/ Code/Manekin_Mitts_Effective_for_Whom_Replication.R is the master: it loads libraries (lemon, stargazer, xtable, fastDummies, tidyr, gridExtra, stm, quanteda, ggplot2, dotwhisker, ggeffects, estimatr, corrplot), setwd()s to an absolute Dropbox path, load()s ten Data/*.rdata files, then source()s one script per exhibit.  Table 1 is Code/replicate_table_1.R: lm(degree_violence / police_action_required / recall_violence2 ~ identity_protesters + tactic, data = us_survey_wave1 / isr_survey_wave1, weights = weight), written by stargazer to Tables/table_1_panel_A.tex / _B.tex.  The paper's Table 2 is produced by Code/replicate_table_4.R (misnamed, as DP86 notes): lm(... ~ black + group_goal + commitment, data = us_survey_wave2) and lm(... ~ identity_protesters + group_goal + commitment, data = isr_survey_wave2), unweighted, written to Tables/table_4_panel_A.tex / _B.tex.  Every pinned value and SE equals the shipped .tex.  Selecting files by name (table_2) will not find the Table 2 script.
> Left out.  Recall-violence columns (binary recall measure; the U.S. Study 2 Black effect is insignificant), tactic and goal/commitment coefficients, intercepts and R-squared, Study 2 Israel identity effects (Ethiopian 0.950 (0.139) / 0.732 (0.144), Arab 0.587 (0.139) / 0.802 (0.144); not named in the abstract, kept to the 12-claim target), the observational NAVCO/EPR estimates (Figure 1, appendix Tables A3 / A5, the abstract's first finding: not tabulated in the main text, and the part DP86 found discrepant and fragile), Figure 3-4 conditional effects and the structural topic models.
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 7 / 12 (first scored 8; 1 error + 3 claim refinements); independent 12 / 12 (first scored 6; 1 error + 1 claim refinement); blind 6 / 12 (first scored 6). Seeded's final is below its first scored: a claim refinement fixed the Ethiopian perceived-violence coefficient but dropped the Study 1 weights, losing both U.S. coefficients (0.137 / 0.171, the unweighted values above), and was kept because it fixed a different claim.  The independent and blind first-script 6 / 12 are the same six claims: the two Study 2 U.S. coefficients (0.347, 0.429) and the four sample sizes; every Study 1 coefficient fails first time (blind prints NA for all six).  Independent's 12 / 12 final passes the unweighted Study 1 values (0.137 vs 0.235 etc.) inside the +-1 SE band, the same numbers that fail seeded's 1% band: a tolerance effect, not a recovered weighting.  96 files stripped from the independent / blind mount (the shipped Tables/*.tex among them).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `study1_us_black_perceived_violence` | 0.235 | 0.117 | Table 1, Panel (A) US Sample, Black protesters, Perceived degree of violence | 0.235 | matches |
| 1 | `study1_us_black_police_action` | 0.268 | 0.127 | Table 1, Panel (A) US Sample, Black protesters, Police action required | 0.268 | matches |
| 2 | `study1_israel_ethiopian_perceived_violence` | 0.425 | 0.107 | Table 1, Panel (B) Israel Sample, Ethiopian protesters, Perceived degree of violence | 0.425 | matches |
| 3 | `study1_israel_ethiopian_police_action` | 0.181 | 0.118 | Table 1, Panel (B) Israel Sample, Ethiopian protesters, Police action required | 0.181 | matches |
| 4 | `study1_israel_arab_perceived_violence` | 0.623 | 0.108 | Table 1, Panel (B) Israel Sample, Arab protesters, Perceived degree of violence | 0.623 | matches |
| 5 | `study1_israel_arab_police_action` | 0.964 | 0.119 | Table 1, Panel (B) Israel Sample, Arab protesters, Police action required | 0.964 | matches |
| 6 | `study2_us_black_perceived_violence` | 0.347 | 0.115 | Table 2, Panel (A) US Sample, Black protesters, Perceived degree of violence | 0.347 | matches |
| 7 | `study2_us_black_police_action` | 0.429 | 0.114 | Table 2, Panel (A) US Sample, Black protesters, Police action required | 0.429 | matches |
| 8 | `respondents_study1_us` | 2269 | — | Research Design (text); Table 1, Panel (A), Observations | 2269 | matches |
| 9 | `respondents_study1_israel` | 3063 | — | Research Design (text); Table 1, Panel (B), Observations | 3063 | matches |
| 10 | `respondents_study2_us` | 3013 | — | Research Design (text); Table 2, Panel (A), Observations | 3013 | matches |
| 11 | `respondents_study2_israel` | 3465 | — | Research Design (text); Table 2, Panel (B), Observations | 3465 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b) | [12/12](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [12/12](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[12/12](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [7/12](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [12/12](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [6/12](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-claude-opus-5-5` | [12/12](seeded/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) (20261022T044632Z) | [12/12](independent/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) (20261022T044632Z) | [12/12](blind/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) (20261022T044632Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [12/12](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) | [9/12](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_us_black_perceived_violence` | 0.1374 | 0.235 | ±0.117 (se_band) | 0.834 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_us_black_police_action` | 0.1708 | 0.268 | ±0.127 (se_band) | 0.765 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_israel_arab_police_action` | 0.8895 | 0.964 | ±0.119 (se_band) | 0.626 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_israel_arab_perceived_violence` | 0.5836 | 0.623 | ±0.108 (se_band) | 0.365 | PASS |
| [seeded/pipeline-claude-opus-4-7/20261021T142909Z](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_israel_ethiopian_perceived_violence` | 0.4264 | 0.425 | ±0.0085 (relative) | 0.165 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `study1_israel_ethiopian_perceived_violence` | 0.407652 | 0.425 | ±0.107 (se_band) | 0.162 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `study1_israel_ethiopian_police_action` | 0.1653 | 0.181 | ±0.118 (se_band) | 0.133 | PASS |
| [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) | `study1_israel_ethiopian_police_action` | 0.180704 | 0.181 | ±0.00362 (relative) | 0.082 | PASS |
| [seeded/pipeline-claude-opus-5-5/20261022T044632Z](seeded/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) | `study1_israel_ethiopian_police_action` | 0.180704 | 0.181 | ±0.00362 (relative) | 0.082 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T151837Z](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `study1_israel_ethiopian_police_action` | 0.180704 | 0.181 | ±0.00362 (relative) | 0.082 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (12/12)
  - Study 2 U.S. regressions are unweighted: us_survey_wave2 has no weight variable.
  - Study 2 US regressions are unweighted (no weight variable in us_survey_wave2).
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (12/12)
  - Study 2 regressions (US and Israel) are unweighted: the Study 2 data files contain no weight variable. Study 1 regressions use the `weight` column, as the task context states.
  - The Israeli identity_protesters factor is unlabeled; codes taken as 0 = white Jews, 1 = Ethiopian Jews, 2 = Arabs, following the order the paper lists the conditions (in Study 2 code 0 has about half the cell count of the others, consistent with the two omitted white-protester conditions, which supports 0 = white; the 1 vs 2 assignment cannot be verified from the data).
  - Study 1 Israel uses the full file (Jewish and Arab respondents pooled, 3063 rows); no other sample restrictions applied anywhere.
  - Study 2 regressions are unweighted (no weight variable in the Study 2 files); Israeli identity codes assumed 0=white,1=Ethiopian,2=Arab.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (12/12)
  - Israeli protester identity codes assumed 0=white Jews, 1=Ethiopian Jews, 2=Arabs (paper's listing order; the data factor has no labels).
  - Study 2 regressions are unweighted because the Study 2 data files contain no weight variable; Study 1 regressions use the provided weight variable.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `study1_israel_arab_perceived_violence` — pipeline 1/3, agent 2/2
- blind: `study1_israel_arab_police_action` — pipeline 1/3, agent 2/2
- blind: `study1_israel_ethiopian_police_action` — pipeline 1/3, agent 2/2

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:10:00Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 7/12, re-scored 7/12; first scored 8/12; executions 5; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-5-5 · 20261022T044632Z

[`seeded/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md`](seeded/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-22T04:46:32Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-10-22T02:07:14Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T04:40:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 12/12, re-scored 12/12; first scored 6/12; executions 3; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-claude-opus-5-5 · 20261022T044632Z

[`independent/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md`](independent/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-22T04:46:32Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T150832Z

[`independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-10-22T02:25:00Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-02T04:20:30Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 6/12, re-scored 6/12; first scored 6/12; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-claude-opus-5-5 · 20261022T044632Z

[`blind/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md`](blind/pipeline-claude-opus-5-5/20261022T044632Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-10-22T04:46:32Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 9/12, re-scored 9/12; first scored 9/12; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

