# Evidence report: montero-2022-cooperative-property-rights

**Cooperative Property Rights and Development: Evidence from Land Reform in El Salvador** — Eduardo Montero

- Paper: https://emontero23.github.io/emwebsite/montero_cooperatives_jpe.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/268943/1/I4R-DP020.pdf
- I4R outcome label: not_reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/montero-2022-cooperative-property-rights.yaml`
- Data access: public

> Headline finding (as published): an RD at El Salvador's 1980 500 ha land-reform threshold shows cooperatives grow fewer cash crops and more staple crops, are less productive in cash crops and more in staples (Tables 2-4), and that cooperative workers have higher earnings ($60 per month, Table 5 col 1) and a ~$43 lower within-property interquartile range of earnings (col 3).  The I4R comment (DP20 / JPE 2023) and the author's own note withdraw the Table 5 / Figure 6 earnings results; the productivity results stand (the meta-database's 20 "recoding in a different software" rows reproduce Tables 2-3 exactly, e.g. -.594 (.152), -.234 (.104), .439 (.194), 17.34 (7.236)).
> Original analysis in Stata (Montero's code and the comment's Replication_file.do); language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 10 claims, all from Table 5 — the only exhibit the package can produce: the four Above500 coefficients (each with its SE in standard_error) and six counts (observations per column; clusters per bandwidth).  Values exactly as printed in the published JPE version (author-site copy of the typeset article), and identical to the meta-database's o_coeff / o_std_err and DP20's reproductions.  Not pinned, and kept out of the claim contexts because they would state pinned counts or hint at them: the table's property counts (327 / 118 for the 300 / 150 ha samples; columns 3-4 have one observation per property, so these equal their N) and the mean dependent variables (73.59 / 74.81 / 38.63 / 37.52, columns 1-4).
> What was read.  The published JPE PDF (Tables 2, 3, 5, the data and empirical-strategy sections); the 12 January 2018 draft (for dates only); DP20 (all of it, EconStor, 16 pp.); Montero's 2023-03-01 note; the Dataverse API metadata; the whole package and the comment authors' own zip (andreaskotsadam.files.wordpress.com, same .dta, same .do up to paths), downloaded to a scratch directory (never committed); the meta-database's 204 rows (team 16).
> Independent cross-check (not the package code; Python/statsmodels on the package's .dta, mimicking the original specification): columns 1-2 reproduce exactly — 60.495 (31.03), N = 4,770, 98 clusters; 52.791 (40.64), N = 1,583, 36 clusters.  Columns 3-4 reproduce only with Stata's percentile definition (collapse (iqr)): -42.967 (17.84), N = 327 and -51.785 (24.92), N = 118; numpy's default linear interpolation gives -36.27 / -43.06 instead.  In the original data, 199 of the 327 (73 of 118) property-years have fewer than five workers and 94 (33) have exactly one — the five-member rule the paper states was not applied.  Of the 5,060 rows only 1,260 are unique on the comment's identifying variables (1,195 of 4,770 within 300 ha).
> How the printed numbers were produced (package-only; never in contexts).  From the comment's re-run of the original code: earnings levels are reg hh_inc_pc_real Above500 norm_dist c.norm_dist#Above500 i_year* sex age age2 if abs(norm_dist) < 300 (or 150), cluster(Expropretario_ISTA) — note the sex / age / age2 controls, which Table 5's note does not mention (the paper mentions them only for the Figure 6 quantile regressions).  The IQR columns collapse (iqr) hh_inc_pc_real by match_id Expropretario_ISTA i_year* and regress on the same RD terms with year dummies only.  The outcome is CPI-deflated (hh_inc_pc_real = hh_income_pc x a year-specific index / 100) although the paper says "dollars"; the index omits 2010, so all 798 rows from 2010 get real earnings 0 (DP20 fn. 5; their correction, hh_inc_pc_realC, barely moves the estimates).  The data also cover 2000-2001, not just the paper's 2002-2013 (survey years 2000, 2001, 2004-2013).  Key variables: Above500, norm_dist (own_amt, the former owner's cumulative landholdings, minus 500), norm_dist_Above, i_year1-i_year12, Expropretario_ISTA (former owner), match_id (property), hh_income_pc, sex, age, age2.  The do-file's corrected section (duplicates drop on dept munic canton year hh_income hh_income_pc Landholding_Type Total_Workers age norm_dist, then 43 hand-coded drop-if lines checked against the raw survey, then dropping 6 workers assigned to two properties) produces DP20 Tables 1-3.  It also runs net install gr0002_3 / ssc install grqreg (network) for Figure 6.
> Benchmark implications.  Seeded mode shows the model a script that computes BOTH the original and the corrected estimates; independent mode sees only the .dta and the paper, whose description (five-member rule, no demographic controls, nominal dollars, 2002-2013) does not match the code that produced the printed numbers.  A faithful independent reproduction is therefore expected to MISS the printed IQR values; reproducing them requires replicating the paper's mistakes. Retally agreeing with I4R requires removing the duplicates, which the paper gives no hint of.
> Left out.  Tables 2-4 (productivity; data not in this package), Table 6+ (credit, migration, canton outcomes), Figure 6 quantile estimates (figure only), and DP20's Table 2 alternative-threshold estimates (+182.20 / -28.35 / +157.08 / -3.53).
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 10 / 10 (first scored 0; 1 claim refinement); independent 3 / 10 (first scored 2; 2 error + 3 claim refinements); blind 0 / 10 (first scored 0).  agrees_with_i4r is false in all three modes; the 'agrees with I4R, not with the paper' cell did not occur.  The only public package is the I4R comment's (original data plus code that re-runs the original Table 5 and then the duplicate-corrected version); the I4R corrected values are pinned as reproduced_value.  Seeded: the first script produced NEITHER the paper's numbers nor the replicators' (79.19 / 71.31 / -51.37 / -61.81; N 3,982 / 1,513 / 275 / 99).  One claim-refinement round, told the gaps to the paper's printed values, then reproduced the paper's numbers exactly (60.49 / 52.79 / -42.97 / -51.79; N 4,770 / 1,583 / 327 / 118): target-guided search converged on numbers the human replicators showed to be wrong.  This is the first case of target-guided refinement reproducing a wrong published number, and the reason a seeded 10 / 10 here is a target match, not a reproduction. Independent 3 / 10: one coefficient inside the +-1 SE band (74.15 vs 60.49, SE 31.03) and two N (4,781 vs 4,770, 1,583).  Blind applied the paper's stated five-member rule (filter(n_workers >= 5)), which the original code never applied, and got 215.7 / 221.2 for the earnings levels and NA for the IQR columns, N 1,038 / 407 / 40 / 16: following the paper's text reproduces neither the paper nor the replicators, as the 'Benchmark implications' above predicted.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `earnings_level_above500_bw300` | 60.49 | 31.03 | Table 5, column 1 (Household Earnings per Capita, Levels, bandwidth 300) | 13.21 | does_not_match |
| 1 | `earnings_level_above500_bw150` | 52.79 | 40.61 | Table 5, column 2 (Household Earnings per Capita, Levels, bandwidth 150) | -24.24 | does_not_match |
| 2 | `earnings_iqr_above500_bw300` | -42.97 | 17.82 | Table 5, column 3 (Household Earnings per Capita, Interquartile Range, bandwidth 300) | -72.24 | does_not_match |
| 3 | `earnings_iqr_above500_bw150` | -51.79 | 24.79 | Table 5, column 4 (Household Earnings per Capita, Interquartile Range, bandwidth 150) | -79.78 | does_not_match |
| 4 | `n_obs_earnings_level_bw300` | 4770 | — | Table 5, Observations, column 1 | 1146 | does_not_match |
| 5 | `n_obs_earnings_level_bw150` | 1583 | — | Table 5, Observations, column 2 | 420 | does_not_match |
| 6 | `n_obs_earnings_iqr_bw300` | 327 | — | Table 5, Observations, column 3 | 324 | does_not_match |
| 7 | `n_obs_earnings_iqr_bw150` | 118 | — | Table 5, Observations, column 4 | 116 | does_not_match |
| 8 | `n_clusters_bw300` | 98 | — | Table 5, Clusters, columns 1 and 3 | 98 | matches |
| 9 | `n_clusters_bw150` | 36 | — | Table 5, Clusters, columns 2 and 4 | 36 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [10/10](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[10/10](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [10/10](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[10/10](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[10/10](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [10/10](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[7/10](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a)<br>[6/10](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-claude-opus-4-7` | [10/10](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [5/10](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [0/10](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-claude-opus-5-5` | [10/10](seeded/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) (20261022T044149Z) | [10/10](independent/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) (20261022T044149Z) | [0/10](blind/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) (20261022T044149Z) |
| `pipeline-desktop-opus-postfix` | — | [8/10](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) (20261103T104514Z) | [3/10](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) (20261103T064954Z) |
| `pipeline-desktop-opus-run2` | [10/10](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [8/10](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (20261023T153002Z) | [3/10](blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) |
| `pipeline-desktop-opus-run3` | [10/10](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [10/10](independent/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) (20261103T054754Z) | [0/10](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-postfix/20261103T064954Z](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) | `earnings_level_above500_bw150` | 94.6765 | 52.79 | ±40.61 (se_band) | 1.031 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261023T151837Z](blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `earnings_level_above500_bw150` | 94.6765 | 52.79 | ±40.61 (se_band) | 1.031 | FAIL |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `earnings_level_above500_bw150` | 95.7704 | 52.79 | ±40.61 (se_band) | 1.058 | FAIL |
| [blind/pipeline-desktop-opus-postfix/20261103T064954Z](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) | `earnings_iqr_above500_bw150` | -74.2325 | -51.79 | ±24.79 (se_band) | 0.905 | PASS |
| [blind/pipeline-desktop-opus-postfix/20261103T064954Z](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) | `n_clusters_bw150` | 34 | 36 | ±1.8 (relative) | 1.111 | FAIL |
| [blind/pipeline-desktop-opus-postfix/20261103T064954Z](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) | `n_obs_earnings_level_bw150` | 1513 | 1583 | ±79.15 (relative) | 0.884 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T151837Z](blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `n_obs_earnings_level_bw150` | 1513 | 1583 | ±79.15 (relative) | 0.884 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `n_obs_earnings_iqr_bw150` | 113 | 118 | ±5.9 (relative) | 0.847 | PASS |
| [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) | `earnings_iqr_above500_bw300` | -56.4231 | -42.97 | ±17.82 (se_band) | 0.755 | PASS |
| [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) | `earnings_iqr_above500_bw300` | -56.4231 | -42.97 | ±17.82 (se_band) | 0.755 | PASS |

### Declared deviations

- [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) (10/10)
  - IQR outcome computed per property x survey round over all surveyed workers (Stata-style percentiles, R quantile type 2); the paper's 'at least five members represented' restriction is not applied as a filter, since applying it (num_members>=5 or >=5 surveyed workers) does not give the reported 327/118 observations, while no filter reproduces them and the reported dependent-variable means (38.63, 37.52) exactly.
  - Bandwidth implemented as strict \|own_amt - 500\| < bw; the inclusive version gives 4781 observations instead of the reported 4770.
  - IQR computed over all surveyed workers per property-survey round (Stata-style percentiles, R type 2); the 'at least five members' restriction is not applied as a filter because applying it (num_members>=5 or >=5 surveyed workers) does not reproduce the reported 327/118 observations
  - bandwidth implemented as strict \|own_amt-500\| < bw (matches reported N of 4770 at 300 ha)
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (10/10)
  - IQR regressions (Table 5 cols 3-4) use all property-by-survey-round cells; the paper's at-least-five-members-in-survey filter is not applied, because the paper's observation counts (327/118) equal the total number of such cells in the bandwidth (only 128/45 cells have >=5 surveyed workers).
  - Bandwidth implemented as strict \|own_amt - 500\| < bw (this reproduces the paper's N=4770, 98 clusters, 327 properties at bw 300); uniform kernel.
  - IQR regressions use all property-by-survey-round cells (the paper's at-least-five-members filter is not applied) because the paper's observation counts (327/118) equal the total number of such cells.
- [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) (10/10)
  - The interquartile range is computed per property x survey round (match_id x year) over all such cells; the paper's 'at least five members represented' restriction is not applied, because the reported observation counts (327 and 118) equal the number of all property-round cells in the 300 and 150 ha samples (only 128 and 45 cells have five or more surveyed workers).
  - Percentiles use R quantile type 2 (Stata _pctile/egen pctile definition).
  - IQR computed per property x survey round (match_id x year) over all such cells; the 'at least five members' restriction is not applied because the reported observation counts (327/118) equal all property-round cells
- [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (5/10; failed: `earnings_level_above500_bw150`, `earnings_iqr_above500_bw300`, `earnings_iqr_above500_bw150`, `n_obs_earnings_iqr_bw300`, `n_clusters_bw300`)
  - IQR aggregated at canton-year level to approximate paper 327/118 obs counts; outcome hh_inc_pc_real; running variable own_amt-500.
- [independent/pipeline-claude-opus-5-5/20261022T044149Z](independent/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) (10/10)
  - Survey-round fixed effects included (Table 5 specification) although the baseline eq. (1) has none
  - IQR computed per property x survey year without a minimum-workers filter
- [independent/pipeline-desktop-opus-postfix/20261103T104514Z](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) (8/10; failed: `earnings_iqr_above500_bw150`, `n_obs_earnings_iqr_bw150`)
  - survey-year fixed effects added to pool EHPM rounds 2002-2013
  - IQR computed by cantonxprop x survey round to match the paper property count
  - IQR property-rounds require >= 2 members (instead of 5) to match the paper property count
- [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (8/10; failed: `earnings_iqr_above500_bw300`, `earnings_iqr_above500_bw150`)
  - Bandwidth window applied with strict inequality \|x\| < bw (owners exactly at the window edge excluded), matching the stated 98 owner clusters
  - IQR of earnings computed per property (key=CANTON, by survey year=TRUE, min 3 obs, household-dedup=TRUE, positive income only=FALSE, Stata-style percentiles); property definition chosen to match the stated property counts
- [independent/pipeline-desktop-opus-run3/20261103T054754Z](independent/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) (10/10)
  - IQR computed at the property x survey-wave x interview-year level, keeping all cells (Stata collapse-style percentiles, IQR=0 for single-worker cells) since the paper's IQR unit (327 properties at bw300) exceeds the number of distinct properties and of property x survey-year cells
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (10/10)
  - IQR (columns 3-4) sample: every property x survey-round cell inside the bandwidth, with the IQR computed within the cell (single-worker cells get IQR 0). The paper says the sample is limited to properties with at least five members in the surveys, but applying that literally per cell (45 cells at 150 ha) or via the num_members variable (101) contradicts the property counts the paper reports for these columns (118 at 150 ha, 327 at 300 ha), which match all cells under a strict bandwidth. I followed the reported property counts.
  - Bandwidth inclusion is strict (\|landholdings - 500\| < bw). This only matters at 300 ha, where one property (match_id 540732174011, 11 workers in 5 survey rounds) sits exactly 300 ha from the cutoff and is dropped; strict inclusion matches the 327 properties the paper reports for column 3.
  - Percentiles use R quantile type 2, which matches Stata's summarize/egen percentile definition (the data are Stata files).
  - All survey years in the file (2000-2013) are used, although the text says 2002-2013; the 150 ha worker count (1,583) and cluster count (36) given in the task match the full file.
  - IQR sample uses every property-survey-round cell inside the bandwidth (the paper's 'at least five members' filter, applied literally per cell, would leave far fewer units than the properties the paper reports); bandwidth inclusion is strict (\|dist\| < bw).
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (7/10; failed: `earnings_iqr_above500_bw150`, `n_obs_earnings_iqr_bw300`, `n_obs_earnings_iqr_bw150`)
  - Interquartile range computed per property pooling all survey rounds (Stata type-2 quantiles), properties with >=5 surveyed workers in the bandwidth sample; one observation per property. Because one observation per property cannot carry survey-round FE directly, columns 3-4 use FE for the property's modal survey round (fixest dropped 2 singletons at 150 ha, N=26 of 28 eligible properties).
  - All survey years in the provided file (2000-2013) kept, although the paper text says 2002-2013; the data file is the authors' constructed analysis sample.
  - IQR computed per property pooling all survey rounds (Stata-style type-2 quantiles); survey-round FE in columns 3-4 enter as the property's modal survey round
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (6/10; failed: `earnings_iqr_above500_bw300`, `earnings_iqr_above500_bw150`, `n_obs_earnings_iqr_bw300`, `n_obs_earnings_iqr_bw150`)
  - IQR regressions (one observation per property, IQR pooled across all of the property's surveyed workers): survey-round FE uses the survey year of each property's first row in the file, since the paper does not say how a round is assigned when a property's workers span several rounds.
  - All survey years in the data file (2000-2013) are kept, although the paper's text says 2002-2013; the file contains no 2002/2003 rounds, and no year restriction was applied.
  - Former-owner clusters are identified by Expropretario_ISTA; bandwidth samples are \|own_amt - 500\| <= bw (uniform kernel); percentiles use R quantile type 2 (Stata pctile convention).
  - survey-round FE in the one-observation-per-property IQR regressions use the survey year of each property's first row in the file (paper does not say how rounds are assigned when a property's workers span several rounds)
- [blind/pipeline-desktop-opus-run2/20261023T151837Z](blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (3/10; failed: `earnings_level_above500_bw300`, `earnings_level_above500_bw150`, `earnings_iqr_above500_bw300`, `earnings_iqr_above500_bw150`, `n_obs_earnings_level_bw300`, `n_obs_earnings_iqr_bw300`, `n_obs_earnings_iqr_bw150`)
  - IQR regressions use one observation per property; no survey-round FE (not identifiable with one obs per property)

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `earnings_level_above500_bw150` — pipeline 0/5, agent 3/3
- blind: `earnings_level_above500_bw300` — pipeline 0/5, agent 3/3
- blind: `n_obs_earnings_level_bw300` — pipeline 0/5, agent 3/3

Pass rates at least 50 points apart (not unanimous):

- independent: `earnings_iqr_above500_bw150` — pipeline 2/5, agent 3/3
- blind: `earnings_iqr_above500_bw300` — pipeline 0/5, agent 2/3
- blind: `n_clusters_bw150` — pipeline 1/5, agent 3/3
- blind: `n_clusters_bw300` — pipeline 2/5, agent 3/3
- blind: `n_obs_earnings_level_bw150` — pipeline 2/5, agent 3/3

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 2; 2026-10-22T02:03:08Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-11-02T19:36:47Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 10/10, re-scored 10/10; first scored 0/10; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-claude-opus-5-5 · 20261022T044149Z

[`seeded/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md`](seeded/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-10-22T04:41:49Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 4; 2026-10-22T02:09:00Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 5; 2026-11-02T04:30:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 4; 2026-11-02T20:06:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 5/10, re-scored 5/10; first scored 2/10; executions 6; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-claude-opus-5-5 · 20261022T044149Z

[`independent/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md`](independent/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) — final 10/10, re-scored 10/10; first scored 1/10; executions 4; 2026-10-22T04:41:49Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T104514Z

[`independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) — final 8/10, re-scored 8/10; first scored 1/10; executions 5; 2026-11-03T10:45:14Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T153002Z

[`independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) — final 8/10, re-scored 8/10; first scored 0/10; executions 4; 2026-10-23T15:30:02Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T054754Z

[`independent/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T054754Z/CELL.md) — final 10/10, re-scored 10/10; first scored 0/10; executions 5; 2026-11-03T05:47:54Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 5; 2026-10-22T02:13:09Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 7/10, re-scored 7/10; first scored 6/10; executions 3; 2026-11-02T04:21:30Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 6/10, re-scored 6/10; first scored 5/10; executions 4; 2026-11-02T20:21:32Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 0/10, re-scored 0/10; first scored 0/10; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-claude-opus-5-5 · 20261022T044149Z

[`blind/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md`](blind/pipeline-claude-opus-5-5/20261022T044149Z/CELL.md) — final 0/10, re-scored 0/10; first scored 0/10; executions 1; 2026-10-22T04:41:49Z; from `pipeline-opus55-4papers-all-modes-2026-10-22.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T064954Z

[`blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) — final 3/10, re-scored 3/10; first scored 3/10; executions 2; 2026-11-03T06:49:54Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T151837Z

[`blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 3/10, re-scored 3/10; first scored 1/10; executions 2; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T010557Z

[`blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 0/10, re-scored 0/10; first scored 0/10; executions 2; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

