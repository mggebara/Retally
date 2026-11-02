# Evidence report: dancygier-2022-hate-crimes-gender-imbalances

**Hate Crimes and Gender Imbalances: Fears over Mate Competition and Violence against Refugees** — Rafaela Dancygier, Naoki Egami, Amaney Jamal, Ramona Rischke

- Paper: https://naokiegami.com/paper/hatecrime.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/dancygier-2022-hate-crimes-gender-imbalances.yaml`

> Headline findings: German municipalities with more men than women aged 15-44 are more likely to see anti-refugee hate crime (Figure 1; SI Table C1 full models, Excess Males 1.406 (0.463) Sum and 1.537 (0.412) Annual, logit; in the text, moving from 1.0 to 1.2 raises the probability of at least one hate crime by 2.60 and 1.71 points), and survey respondents who agree that refugees make it harder for native men to find partners are more likely to support anti-refugee violence (Table 1: Mate Competition 0.437 (0.016) bivariate, 0.155 (0.019) with all controls; N 3,019 / 3,008).
> Curation pass (2026-11-02).  Pinned 13 claims: Table 1's Mate Competition coefficient in all six columns and Job Competition in column 2, each with its SE; the two Table 1 Ns; SI Table C1 columns 5-6 Excess Males with SEs and their Ns (9,282 municipalities; 27,846 municipality-years).  Values exactly as printed in the published PDF and SI and identical to the package's table1.tex / table_C1.tex. Cross-check against the meta-database: Table 1 col 6 0.155 (0.019) and Table C1 col 6 1.537 (0.412) equal the rows' o_coeff / o_std_err; the other pinned values have no row.  Table C1 columns 5-6 are pinned although they sit in the SI because they are the "full results and specification" of main-text Figure 1 (the paper's municipality-level headline), not a robustness check; ContextAnalysis_Main.R fits exactly these two models for Figure 1.  Left out: Table 1's Job Competition in columns 3-6 and Life Satisfaction, R2 / adjusted R2 (0.191-0.459), Table C1 columns 1-4 and its other covariates, the Figure 1 effects (2.60 [0.88, 4.19] and 1.71 [0.76, 2.55] points; marginal effects from a custom function), Figure 2-4 quantities, the list experiment, the YouGov replication, and SI Tables C2-C9 and D (robustness).
> Paper vs package.  The main text (fn. 24 area) says Figure 1 includes "county and year fixed effects"; the code and SI Table C1 use county fixed effects in columns 1-4 only and STATE fixed effects (plus year in the annual model) in the full columns 5-6 plotted in Figure 1, with SEs clustered by county.  The contexts follow SI Table C1.  The paper's Table 1 prints stars at p < 0.1 / 0.05 / 0.01 as dagger / * / **; the package's table1.tex uses the stargazer default *** for the same thresholds (values identical).
> Package-only facts (never in contexts).  master.R sources the four analysis scripts and number_in_texts.R; all read the .dta files from the working directory with readstata13 and use Help.R's bin.summary (glm logit with a cluster-robust vcov via sandwich) and star_out. Table 1 (SurveyAnalysis_Main.R): dat[dat$wave == 4, ]; lm1 hate_violence_means ~ MateComp.cont; lm2 adds JobComp.cont + LifeSatis.cont; lm3 adds factor(age_group, gender, state, citizenship, marital, religion, occupation, income, household_size, self_econ) + eduyrs; lm4 adds eight national refugee items factor(ref_integrating, ref_citizenship, ref_reduce, ref_moredone, ref_cultgiveup, ref_economy, ref_crime, ref_terror); lm5 adds eight local items factor(ref_loc_*); lm6 adds factor(distance_ref) + factor(settle_ref) + lrscale + afd + muslim_ind + afd_ind + contact_ind.  Classical lm SEs.  Table C1 (ContextAnalysis_Appendix.R): context.dta; the Sum outcome Hate_all_muni_1517_bin is built on the 2015 rows by summing Hate_all_muni over 2015-2017 (rows aligned by position across year subsets); Excess Males is pop_15_44_muni_gendergap_2015, trimmed to its 2.5-97.5 % quantiles computed on the 2015 rows; full models add log_unemp_all_muni_2015, d_pop1511_muni, vote_afd_2013_muni, log_ref_inflow_1514, log_pop_ref_2014, log_violence_percap_2015, pc_hidegree_all2011, d_manuf1115, pc_manufacturing_2015, unemp_gendergap_2015, as.factor(ags_state) (+ as.factor(year) for the annual Hate_all_muni_bin), clustered by ags_county. produce_context_data.do (Stata 16) and merge_context*.R only rebuild context.dta from source_data/ and are not needed for the pinned numbers.
> What was read.  The published AJPS PDF (all 15 pp.); the SI PDF (Appendix C.1-C.3 and D.5.1 in full, the rest skimmed); the Dataverse API metadata for versions 1.0 and 1.1; the package's 1-ReadMe.txt, master.R, ContextAnalysis_Main.R, ContextAnalysis_Appendix.R (Table C1 section), SurveyAnalysis_Main.R (Table 1 and Figure 4 sections), table1.tex and table_C1.tex; the meta-database's 38 team-34 rows.
> Independent cross-check (2026-11-02; not the package code: pandas / statsmodels on the downloaded .dta files).  Table 1 col 1 0.437 (0.016), N 3,019; col 2 Mate 0.263 (0.020), Job 0.250 (0.019), Life -0.015 (0.006), N 3,019; SI Table C1 col 5 logit with county-clustered SEs 1.406 (0.463), N 9,282; col 6 1.537 (0.413 vs the printed 0.412, a small-sample-correction difference between statsmodels and sandwich), N 27,846.  Benchmark implication: the Sum outcome sums the three annual hate-crime counts per municipality; the R code does it by row position across the 2015 / 2016 / 2017 subsets (the file is in a consistent municipality order within year), and a first attempt here that re-sorted by year with an unstable sort got 1.041 (0.365) at the same N — a reproduction must align years by municipality.
> What could not be verified.  The package's R code was not run (the cross-check above re-estimates four pinned coefficients and the Ns; Table 1 columns 3-6 were not re-estimated).  The date of team 34's replication (hence the exact Dataverse version it used) is not recorded; both versions are byte-identical.
> Original analysis in R 4.0.2 (readstata13, MASS, sandwich, lmtest, stargazer, list, pBrackets), with one Stata 16 data-construction do-file; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `mate_competition_table1_col1` | 0.437 | 0.016 | Table 1, column (1), Mate competition | 0.437 | matches |
| 1 | `mate_competition_table1_col2` | 0.263 | 0.02 | Table 1, column (2), Mate competition | 0.263 | matches |
| 2 | `mate_competition_table1_col3` | 0.236 | 0.021 | Table 1, column (3), Mate competition | 0.236 | matches |
| 3 | `mate_competition_table1_col4` | 0.206 | 0.019 | Table 1, column (4), Mate competition | 0.206 | matches |
| 4 | `mate_competition_table1_col5` | 0.185 | 0.019 | Table 1, column (5), Mate competition | 0.185 | matches |
| 5 | `mate_competition_table1_col6` | 0.155 | 0.019 | Table 1, column (6), Mate competition | 0.155 | matches |
| 6 | `job_competition_table1_col2` | 0.25 | 0.019 | Table 1, column (2), Job competition | 0.25 | matches |
| 7 | `n_obs_table1_col1` | 3019 | — | Table 1, columns (1)-(2), Observations | 3019 | matches |
| 8 | `n_obs_table1_col3` | 3008 | — | Table 1, columns (3)-(6), Observations | 3008 | matches |
| 9 | `excess_males_sum_tableC1_col5` | 1.406 | 0.463 | SI Table C1, column (5) Sum, Excess Males (Age 15 - 44) | 1.406 | matches |
| 10 | `excess_males_annual_tableC1_col6` | 1.537 | 0.412 | SI Table C1, column (6) Annual, Excess Males (Age 15 - 44) | 1.537 | matches |
| 11 | `n_obs_sum_tableC1_col5` | 9282 | — | SI Table C1, column (5), Observations | 9282 | matches |
| 12 | `n_obs_annual_tableC1_col6` | 27846 | — | SI Table C1, column (6), Observations | 27846 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) | [13/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) | [13/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col6` | 0.157354 | 0.155 | ±0.019 (se_band) | 0.124 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col6` | 0.157325 | 0.155 | ±0.019 (se_band) | 0.122 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col4` | 0.20644 | 0.206 | ±0.00412 (relative) | 0.107 | PASS |
| [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col5` | 0.186929 | 0.185 | ±0.019 (se_band) | 0.102 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col5` | 0.186639 | 0.185 | ±0.019 (se_band) | 0.086 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col2` | 0.263437 | 0.263 | ±0.00526 (relative) | 0.083 | PASS |
| [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col4` | 0.207114 | 0.206 | ±0.019 (se_band) | 0.059 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col5` | 0.184842 | 0.185 | ±0.0037 (relative) | 0.043 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col4` | 0.206705 | 0.206 | ±0.019 (se_band) | 0.037 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `mate_competition_table1_col3` | 0.23615 | 0.236 | ±0.00472 (relative) | 0.032 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Data read with haven::read_dta + zap_labels instead of readstata13::read.dta13; all labelled survey variables are fully labelled, so factor() on the numeric codes gives the same dummy sets as the authors' factors.
  - Help.R::bin.summary reimplemented as glm(binomial) on na.omit of the model variables plus the cluster id, with sandwich::vcovCL clustered by ags_county (same as the authors).
- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Sociodemographic controls coded from survey.dta as: age (linear), gender, years of education (eduyrs, linear), income (factor incl. 'No answer'), occupation (factor; used for both 'main economic activity' and 'employment status' since only one variable exists), German citizenship, household size (linear), self-assessed social status (linear), religion (factor), state (factor). Column (3) R2 is 0.276 vs 0.288 reported, so the authors' coding of some controls (likely factor vs linear) differs slightly.
  - Additional controls (col 6) coded as contact_ind, distance_ref (factor incl. don't know), settle_ref (factor), afd (0-100 closeness), afd_ind, lrscale, muslim_ind.
  - SI Table C1 controls taken from footnote 24 using the log versions in context.dta (log population, log density, log unemployment rate, log refugee stock 2014, log refugee inflow, log violent crime per capita) plus population change, male/female unemployment ratio, % highly educated, % manufacturing, change in manufacturing, AfD 2013 vote share; state FE (plus year FE in the annual model); trimming of Excess Males at the 2.5/97.5 percentiles of the 2015 municipality cross-section; fixest::feglm logit, SE clustered by county.
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Table 1 sociodemographics coded as: age (years, linear), female dummy, eduyrs (years; 11 missing -> N drops to 3008), income as factor with 'No answer' kept as a category, occupation as a factor (the data has a single item covering both main economic activity and employment status), citizenship dummy, household size (numeric), self-assessed social status (0-10, numeric), religion factor, state factor.
  - National battery = the 8 ref_* items (integrating, citizenship, reduce, moredone, cultgiveup, economy, crime, terror) entered linearly; local battery = the 8 ref_loc_* items entered linearly.
  - Additional controls = contact_ind, distance_ref (factor, incl. don't know), settle_ref (factor), afd_ind, afd (0-100 closeness), lrscale, muslim_ind.
  - SI Table C1: Excess Males trimmed at the 2.5th/97.5th percentiles of the municipality-level (2015 cross-section) distribution; controls = log population, log pop density, pop change 2011-15, log unemployment rate, male/female unemployment ratio, log refugee stock 2014, log refugee inflow 2014-15, % highly educated, % manufacturing, change in % manufacturing, AfD 2013 vote share, log violent crime per capita; state FE (plus year FE in the annual model); fixest::feglm logit, SEs clustered by county; complete cases.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T09:47:27Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T09:51:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T09:51:10Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

