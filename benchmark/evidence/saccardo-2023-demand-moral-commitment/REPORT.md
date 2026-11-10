# Evidence report: saccardo-2023-demand-moral-commitment

**Enabling or Limiting Cognitive Flexibility? Evidence of Demand for Moral Commitment** — Silvia Saccardo, Marta Serra-Garcia

- Paper: https://par.nsf.gov/servlets/purl/10473378
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/saccardo-2023-demand-moral-commitment.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T26/180741-V1.zip`; AEA Data and Code Repository on openICPSR, project 180741, version V1 (doi:10.3886/E180741V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T26/180741-V1.zip (6,216,179 bytes, md5 b7e550192ed257e5e00e214ce8ef31cb; SOURCE.txt beside it).  V1 is the only version.  72 zip entries (63 files and 9 directories, 32,030,520 bytes uncompressed), no nested archives.  Contents: README.pdf (7 pp., created 2022-12-06; data provenance, a dataset list, run time about 2 minutes, and an "In-text Numbers" map from quoted in-text statistics to analysis.do line numbers, which quotes the paper's own sentences, e.g. the Table 3 column 1 gap in percentage points; no table cells); Code/ with four Stata do-files (main.do, config.do, datacleaning.do, analysis.do); Data/Clean Data/ with 23 Stata .dta files, among them choice_experiments.dta (7.4 MB, the advisor-level analysis file for Tables 2-4: treatment, wave, sample and design indicators, the standardized moral-cost measure and its interactions, preference, assignment, conflict and recommendation variables), nochoice.dta, professionals.dta, stakes.dta, the information-architect, prediction and client files; Data/Raw Data/ with 21 de-identified Qualtrics .csv exports (Choice waves 1-3, professionals from Prolific and CloudResearch, NoChoice, Stakes, clients, ...) and 4 .xlsx raw files (open-ended explanations, professionals' job titles, predictions and coded prediction explanations; raw responses, no estimates); Qualtrics/ with 10 .qsf survey exports; Results/Main Text/ and Results/Appendix/ empty.  The script-free copy (independent / blind) withholds 4 files (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09): the four .do files by suffix.  Kept: README.pdf, the data, the .xlsx and the .qsf files; none prints a table cell (README text and xlsx strings read, 2026-11-09).  Project page: https://www.openicpsr.org/openicpsr/project/180741/version/V1/view)

> Headline findings.  Table 2: relative to the AMT Choice Free baseline, making it costly to see the incentive first lowers the preference to see it first by -0.139 (0.018) and making it costly to assess quality first raises it by 0.152 (0.029); professionals prefer it less, -0.095 (0.026); N 5,908.  Among AMT advisors (N 5,196) Selfishness raises the preference, 0.028 (0.007) in column 2 and 0.039 (0.009) in column 3, with interactions -0.022 (0.016) (incentive-first costly) and -0.021 (0.018) (quality-first costly).  Table 3: advisors assigned their preferred order who prefer the incentive first recommend the incentivized product 0.195 (0.016) more often (N 4,448); among those not assigned their preference the gap is 0.003 (0.029); pooled, the Prefer x Not Assigned interaction is -0.140 (0.026).
> Paper text and how it was verified.  The catalog source is the published article (NSF PAR copy of the AER typeset PDF).  Its Table 2 holds every cell the I4R meta-database records, in the same row and column (column positions read from the PDF's word coordinates): See Incentive First Costly -0.139 / -0.140 / -0.140 (0.018 each), Assess Quality First Costly 0.152 (0.029) in all three columns, Choice Free—Professionals -0.095 (0.026) in column 1 only, Selfishness 0.028 (0.007) col 2 and 0.039 (0.009) col 3, and the column 3 interactions -0.022 (0.016) and -0.021 (0.018).  The 76 original values group into exactly those 8 distinct value/SE pairs (24 rows 0.152, 16 rows -0.140, 8 rows -0.139, 8 rows -0.095, 5 rows each for the other four); no typo was found.  Table 3 has no meta-database rows; its pinned cells are read from the same published article.
> Package cross-check (2026-11-09, numpy HC3 OLS on Data/Clean Data/choice_experiments.dta, not committed).  analysis.do "TABLE 2": use choice_experiments.dta, drop if study!=1 & alphavaluefinal==. (the preregistered exclusion of MTurk advisors with an inconsistent MPL; study 1 is the professionals, who have no MPL); reg choicebefore $covariates2 [stdalpha] [selfishseeincentivecostly selfishseequalitycostly] if Highx10==0 & Highx100==0 [& professionals==0 in column 2], vce(hc3), with $covariates2 = professionalsfree seeincentivecostly seequalitycostly wave2 wave3 professionalscloudresearch incentiveshigh incentiveleft incentiveshigh_incentiveleft age female.  Column 3 has no professionals==0 condition; stdalpha is missing for them, so the sample is the same 5,196.  "TABLE 3": reg recommendincentive choicebefore choicebeforenoconflict noconflict incentiveB $covariates2 if Highx10==0 & Highx100==0 & getyourchoice==1 (col 1) / ==0 (col 2); col 3 adds notgetyourchoice choicebeforenotgetyourchoice notgetyourchoicenoconflict on the full sample.  Note professionalscloudresearch (an indicator for professionals recruited via CloudResearch rather than Prolific) is a regressor the paper's table notes do not list.  Re-running these in numpy reproduces every pinned value, SE and N exactly (and the constants, Female and Age rows).
> Selfishness coding.  The I4R team reports the Selfishness variable as "incorrectly coded" while still reproducing the paper; its corrected coding roughly doubles the Selfishness coefficients (0.056 vs 0.028, 0.075 vs 0.039) and the incentive-first interaction (-0.049 vs -0.022). The catalog pins the published numbers, which the shipped stdalpha reproduces; a reproduction that recodes Selfishness from the raw MPL answers could legitimately land on the team's values instead.
> Curation pass (2026-11-09).  13 claims.  Left out: the Table 2 controls and constants, the See Incentive First Costly / Assess Quality First Costly coefficients of columns 2-3 (near-duplicates of column 1), the Table 3 conflict and treatment rows, Table 4 (belief updating, logit beliefs on log likelihood ratios, a different data shape), Table 1 (sample sizes by treatment), Figure 4's adjusted shares, and all appendix tables.
> Package-only facts (never in contexts).  Variables: choicebefore (prefer to see incentive first), recommendincentive, getyourchoice (assigned preference), noconflict, incentiveB, stdalpha (standardized alphavaluefinal, the MPL count), Highx10 / Highx100 (high-stakes variants), professionals, study.  README: Stata, about 2 minutes for main.do; estout, grc1leg, dataout and cdfplot from SSC.
> Blind-mode exposure (step 6, 2026-11-09, oracle label curate-t26, both modes reached llm_answer_pending at the generation prompt).  The blind generation prompt states no pinned value or SE, at printed precision or rounded, no N, and no script text (the hits for choicebefore, recommendincentive, getyourchoice and similar are data column names in the dataset listing); no .do file is listed.  The paper text the pipeline's summariser receives is cut at about 60,000 characters (it ends on p. 413, before Tables 2 and 3), and the parser takes the journal line as the title.  The full paper text does state three pinned values in words: the costly-treatment shifts as a "14 percentage point drop" and a "15 percentage point increase" (Section V) and the Table 3 column 1 gap as "19.5 percentage points" (Section VI); README.pdf, which stays in the mount, quotes the same sentences in its "In-text Numbers" map.  Neither adds a value the paper does not print.
> What was read.  The published article pp. 396-422 (Sections I-VI and Tables 1-4); the 77 meta-database rows; the package README.pdf, the Table 1-3 blocks of analysis.do and the Selfishness construction in datacleaning.do; the strip-rule classification of the extracted package; the strings of the four .xlsx files.
> What could not be verified.  The CESifo working paper and its exact month (the ifo.de PDF answers a bot check).  What exactly the I4R team corrected in the Selfishness coding (no discussion paper; only the meta-database's row labels).  The authors' Stata code was not run (no Stata here); the cross-check above is an independent numpy OLS with HC3.
> Original analysis in Stata (estout); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `see_incentive_first_costly_table2_col1` | -0.139 | 0.018 | Table 2, column (1), See Incentive First Costly | -0.139 | matches |
| 1 | `assess_quality_first_costly_table2_col1` | 0.152 | 0.029 | Table 2, column (1), Assess Quality First Costly | 0.152 | matches |
| 2 | `choice_free_professionals_table2_col1` | -0.095 | 0.026 | Table 2, column (1), Choice Free—Professionals | -0.095 | matches |
| 3 | `selfishness_table2_col2` | 0.028 | 0.007 | Table 2, column (2), Selfishness | 0.028 | matches |
| 4 | `selfishness_table2_col3` | 0.039 | 0.009 | Table 2, column (3), Selfishness | 0.039 | matches |
| 5 | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022 | 0.016 | Table 2, column (3), See Incentive First Costly × Selfishness | -0.022 | matches |
| 6 | `see_quality_first_costly_x_selfishness_table2_col3` | -0.021 | 0.018 | Table 2, column (3), See Quality First Costly × Selfishness | -0.021 | matches |
| 7 | `n_obs_table2_col1` | 5908 | — | Table 2, Observations, column (1) | — | — |
| 8 | `n_obs_table2_cols2_3` | 5196 | — | Table 2, Observations, columns (2) and (3) | — | — |
| 9 | `prefer_see_incentive_first_assigned_table3_col1` | 0.195 | 0.016 | Table 3, column (1) Assigned pref., Prefer to See Incentive First | — | — |
| 10 | `prefer_see_incentive_first_not_assigned_table3_col2` | 0.003 | 0.029 | Table 3, column (2) Not assigned pref., Prefer to See Incentive First | — | — |
| 11 | `prefer_see_incentive_first_x_not_assigned_table3_col3` | -0.14 | 0.026 | Table 3, column (3) Both, Prefer to See Incentive First × Not Assigned Preference | — | — |
| 12 | `n_obs_table3_col1` | 4448 | — | Table 3, Observations, column (1) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [13/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [12/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[12/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T143922Z/CELL.md) (20261110T143922Z) | [12/13](independent/pipeline-desktop-opus/20261110T145111Z/CELL.md) (20261110T145111Z) | [4/13](blind/pipeline-desktop-opus/20261110T143922Z/CELL.md) (20261110T143922Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) (20261110T145131Z) | [13/13](independent/pipeline-desktop-opus-run2/20261110T163544Z/CELL.md) (20261110T163544Z) | [4/13](blind/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) (20261110T145131Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T162852Z/CELL.md) (20261110T162852Z) | [8/13](independent/pipeline-desktop-opus-run3/20261110T163558Z/CELL.md) (20261110T163558Z) | [4/13](blind/pipeline-desktop-opus-run3/20261110T162210Z/CELL.md) (20261110T162210Z) |
| `pipeline-desktop-opus-run4` | — | [12/13](independent/pipeline-desktop-opus-run4/20261110T164051Z/CELL.md) (20261110T164051Z) | [5/13](blind/pipeline-desktop-opus-run4/20261110T144548Z/CELL.md) (20261110T144548Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-run2/20261110T145131Z](blind/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) | `see_quality_first_costly_x_selfishness_table2_col3` | -0.04218 | -0.021 | ±0.018 (se_band) | 1.177 | FAIL |
| [blind/pipeline-desktop-opus-run3/20261110T162210Z](blind/pipeline-desktop-opus-run3/20261110T162210Z/CELL.md) | `see_quality_first_costly_x_selfishness_table2_col3` | -0.04218 | -0.021 | ±0.018 (se_band) | 1.177 | FAIL |
| [blind/pipeline-desktop-opus/20261110T143922Z](blind/pipeline-desktop-opus/20261110T143922Z/CELL.md) | `see_quality_first_costly_x_selfishness_table2_col3` | -0.04239 | -0.021 | ±0.018 (se_band) | 1.188 | FAIL |
| [blind/pipeline-desktop-opus-run4/20261110T144548Z](blind/pipeline-desktop-opus-run4/20261110T144548Z/CELL.md) | `see_quality_first_costly_x_selfishness_table2_col3` | -0.042427 | -0.021 | ±0.018 (se_band) | 1.190 | FAIL |
| [seeded/pipeline-desktop-opus-run2/20261110T145131Z](seeded/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.0223933 | -0.022 | ±0.0005 (printed_precision) | 0.787 | PASS |
| [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022393 | -0.022 | ±0.0005 (printed_precision) | 0.786 | PASS |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022393 | -0.022 | ±0.0005 (printed_precision) | 0.786 | PASS |
| [seeded/pipeline-desktop-opus/20261110T143922Z](seeded/pipeline-desktop-opus/20261110T143922Z/CELL.md) | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022393 | -0.022 | ±0.0005 (printed_precision) | 0.786 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261110T162852Z](seeded/pipeline-desktop-opus-run3/20261110T162852Z/CELL.md) | `see_incentive_first_costly_x_selfishness_table2_col3` | -0.022393 | -0.022 | ±0.0005 (printed_precision) | 0.786 | PASS |
| [independent/pipeline-desktop-opus/20261110T145111Z](independent/pipeline-desktop-opus/20261110T145111Z/CELL.md) | `choice_free_professionals_table2_col1` | -0.074719 | -0.095 | ±0.026 (se_band) | 0.780 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Probabilistic-incentive control entered as incentiveshigh (probabilistic incentives randomized within AMT wave 2) rather than probabilistic_incentive (which also equals 1 for every professional). Using probabilistic_incentive makes the Choice Free--Professionals indicator nearly collinear with it (prof coef -0.022, SE 0.048); the chosen coding gives -0.084 (SE 0.023), closer to the paper's -0.095 (0.026). Other coefficients are identical under both codings.
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Probabilistic-incentive control is the dataset's incentiveshigh (randomized $15-to-1-in-100 payment within AMT wave 2) and its interaction with incentiveleft, not probabilistic_incentive (which also equals 1 for every professional); the paper's 'whether incentives were probabilistic' is ambiguous on this point. Chosen after the attempt-3 claim comparison.
  - Selfishness is the dataset's prebuilt stdalpha (standardized MPL count, standardized over all advisors with a consistent MPL, including high-stakes variants), not re-standardized within the regression sample.
  - Wave controls entered as a factor of the wave variable (AMT-1, AMT-2, AMT-3, Prolific/CloudResearch); the Prolific/CloudResearch level is collinear with the Professionals indicator and is dropped.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Choice Free-Professionals coefficient in Table 2 col 1 is -0.084 vs claimed -0.095; the exact coding of the probabilistic-incentive / product-position controls for professionals is not documented in the paper. Final script uses the dataset's wave-2 design indicators (incentiveshigh, incentiveleft, incentiveshigh_incentiveleft), which are zero for professionals.
  - Table 3 Choice Free-Professionals coefficients (not claimed) do not match the paper's column values (e.g. col 1: 0.004 vs -0.026), consistent with the same control-coding uncertainty.
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (13/13)
  - Probabilistic-incentive and product-position controls are coded as the AMT wave-2 randomized design variation (incentiveshigh, incentiveleft, incentiveshigh_incentiveleft); the professionals' always-probabilistic scheme is absorbed by their treatment indicator. The first scored run (attempt-4) used probabilistic_incentive (which is 1 for all professionals) and gave a Choice Free-Professionals coefficient of -0.022; the change was made after comparing with the claimed -0.095.
  - Selfishness uses the dataset's stdalpha (standardized MPL count) as provided; HC3 SEs via sandwich::vcovHC on lm.
- [independent/pipeline-desktop-opus/20261110T145111Z](independent/pipeline-desktop-opus/20261110T145111Z/CELL.md) (12/13; failed: `assess_quality_first_costly_table2_col1`)
  - Multiple switchers identified as non-professional advisors with a missing selfishness (MPL) measure; High Stakes arms dropped via highx10/highx100 flags
- [independent/pipeline-desktop-opus-run2/20261110T163544Z](independent/pipeline-desktop-opus-run2/20261110T163544Z/CELL.md) (13/13)
  - Table 2 col 1 includes wave/sample fixed effects ( wave ) so costly arms are compared with Choice Free advisors from the same wave; not stated in the excerpt
  - Selfishness measured as standardized continuous MPL value (alphavaluefinal), sign-oriented to agree with the binary selfish indicator, instead of the standardized 0/1 selfish dummy
- [independent/pipeline-desktop-opus-run3/20261110T163558Z](independent/pipeline-desktop-opus-run3/20261110T163558Z/CELL.md) (8/13; failed: `assess_quality_first_costly_table2_col1`, `selfishness_table2_col2`, `selfishness_table2_col3`, `see_incentive_first_costly_x_selfishness_table2_col3`, `see_quality_first_costly_x_selfishness_table2_col3`)
  - Excluded robustness arms (high-stakes x10/x100, replication, deterministic) from the main sample via Highx10/Highx100 dummies and treatment labels
  - Identified multiple switchers (excluded per preregistration) as non-professional advisors with missing MPL selfishness measure
- [independent/pipeline-desktop-opus-run4/20261110T164051Z](independent/pipeline-desktop-opus-run4/20261110T164051Z/CELL.md) (12/13; failed: `assess_quality_first_costly_table2_col1`)
  - Advisors with missing attention flag (Professionals sample) treated as attentive so that professionals are retained
  - Multiple switchers identified as non-professional advisors with missing selfishness (MPL) measure
  - Controls restricted to design-variation controls (probabilistic payment, left position, their interaction) per fn. 14
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `choice_free_professionals_table2_col1`)
  - Wave controls coded as AMT wave 2 and AMT wave 3 dummies (AMT wave 1 as base); professionals form their own wave/indicator, so the Choice Free-Professionals coefficient is relative to AMT Choice Free advisors net of these wave dummies. The paper does not state which wave is the reference category.
  - 'Whether incentives were probabilistic' coded with probabilistic_incentive (1 for professionals and the probabilistic AMT wave-2 subsample); 'position of products' coded with incentiveleft; interaction = probabilistic_incentive x incentiveleft (equal to incentiveshigh_incentiveleft in the data).
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (12/13; failed: `choice_free_professionals_table2_col1`)
  - Selfishness uses the dataset's prebuilt stdalpha (alphavaluefinal standardized over all advisors with a consistent MPL, incl. High Stakes rows) rather than re-standardizing within the estimation sample; the two mean/sd differ only in the 3rd decimal.
  - 'Whether incentives were probabilistic' is coded with probabilistic_incentive (1 for professionals and the AMT wave-2 probabilistic subsample); 'position of products' with incentiveleft; their interaction as the product. The professionals wave dummy is collinear with the Professionals indicator and is dropped by lm.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `assess_quality_first_costly_table2_col1` — pipeline 0/4, agent 4/4
- blind: `n_obs_table2_col1` — pipeline 0/4, agent 4/4
- blind: `n_obs_table2_cols2_3` — pipeline 0/4, agent 4/4
- blind: `n_obs_table3_col1` — pipeline 0/4, agent 4/4
- blind: `see_incentive_first_costly_x_selfishness_table2_col3` — pipeline 0/4, agent 4/4
- blind: `see_quality_first_costly_x_selfishness_table2_col3` — pipeline 0/4, agent 4/4
- blind: `selfishness_table2_col2` — pipeline 0/4, agent 4/4
- blind: `selfishness_table2_col3` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- independent: `assess_quality_first_costly_table2_col1` — pipeline 1/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T07:05:00Z; from `claude-code-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T07:05:00Z; from `claude-code-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T143922Z

[`seeded/pipeline-desktop-opus/20261110T143922Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T143922Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T14:39:22Z; from `pipeline-oracle-desktop-opus-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T145131Z

[`seeded/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T14:51:31Z; from `pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T162852Z

[`seeded/pipeline-desktop-opus-run3/20261110T162852Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T162852Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T16:28:52Z; from `pipeline-oracle-desktop-opus-run3-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 6; 2026-11-10T11:22:30Z; from `claude-code-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 5; 2026-11-10T11:28:30Z; from `claude-code-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 4; 2026-11-10T11:40:00Z; from `claude-code-run3-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 5; 2026-11-10T11:28:00Z; from `claude-code-run4-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T145111Z

[`independent/pipeline-desktop-opus/20261110T145111Z/CELL.md`](independent/pipeline-desktop-opus/20261110T145111Z/CELL.md) — final 12/13, re-scored 12/13; first scored 4/13; executions 4; 2026-11-10T14:51:11Z; from `pipeline-oracle-desktop-opus-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T163544Z

[`independent/pipeline-desktop-opus-run2/20261110T163544Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T163544Z/CELL.md) — final 13/13, re-scored 13/13; first scored 4/13; executions 4; 2026-11-10T16:35:44Z; from `pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T163558Z

[`independent/pipeline-desktop-opus-run3/20261110T163558Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T163558Z/CELL.md) — final 8/13, re-scored 8/13; first scored 4/13; executions 4; 2026-11-10T16:35:58Z; from `pipeline-oracle-desktop-opus-run3-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T164051Z

[`independent/pipeline-desktop-opus-run4/20261110T164051Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T164051Z/CELL.md) — final 12/13, re-scored 12/13; first scored 4/13; executions 5; 2026-11-10T16:40:51Z; from `pipeline-oracle-desktop-opus-run4-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 3; 2026-11-10T07:04:30Z; from `claude-code-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 3; 2026-11-10T11:27:30Z; from `claude-code-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 3; 2026-11-10T11:27:30Z; from `claude-code-run3-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 4; 2026-11-10T11:27:30Z; from `claude-code-run4-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T143922Z

[`blind/pipeline-desktop-opus/20261110T143922Z/CELL.md`](blind/pipeline-desktop-opus/20261110T143922Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 2; 2026-11-10T14:39:22Z; from `pipeline-oracle-desktop-opus-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T145131Z

[`blind/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T145131Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-11-10T14:51:31Z; from `pipeline-oracle-desktop-opus-run2-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T162210Z

[`blind/pipeline-desktop-opus-run3/20261110T162210Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T162210Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-11-10T16:22:10Z; from `pipeline-oracle-desktop-opus-run3-1paper-saccardo-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T144548Z

[`blind/pipeline-desktop-opus-run4/20261110T144548Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T144548Z/CELL.md) — final 5/13, re-scored 5/13; first scored 5/13; executions 1; 2026-11-10T14:45:48Z; from `pipeline-oracle-desktop-opus-run4-1paper-saccardo-indep-blind-2026-11-10.json`; evidence complete.

