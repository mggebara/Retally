# Evidence report: adams-2023-women-mps-affective-polarization

**Can't We All Just Get Along? How Women MPs Can Ameliorate Affective Polarization in Western Publics** — James Adams, David Bracken, Noam Gidron, Will Horne, Diana Z. O'Brien, Kaitlin Senk

- Paper: https://www.cambridge.org/core/services/aop-cambridge-core/content/view/D9F115F8EA9677F6AFC9E6D76392B8D5/S0003055422000491a.pdf/div-class-title-can-t-we-all-just-get-along-how-women-mps-can-ameliorate-affective-polarization-in-western-publics-div.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/adams-2023-women-mps-affective-polarization.yaml`

> Headline finding: partisans rate out-parties with more women MPs more warmly.  Moving an out-party's parliamentary delegation from no women to all women raises its mean 0-10 thermometer rating among other parties' partisans by 1.73 units (Table 1 col 2, p < 0.01; 1,842 directed party dyads, 125 parties, 20 Western democracies, 81 CSES surveys 1996-2017), and both women (2.10) and men (1.13) partisans show the bonus.
> Original analysis in R (replication_code.R); language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 11 claims: the women-MPs coefficient in all four Table 1 columns, the three column-2 controls (each with its SE in standard_error; SEs are not separate claims, as in arias-2022), the three Observations counts (1,842 serves columns 1 and 2), and the 81 election studies.  Coefficients and SEs are printed to two decimals.
> What was read.  The published APSR PDF (all 7 pages; the supplementary appendix was not read); the Dataverse API metadata; the whole package, downloaded to a scratch directory (never committed): readme.rtf and replication_code.R; the meta-database's 6 rows.
> Independent cross-check (not the package code).  Table 1 was re-estimated in Python (statsmodels OLS, election fixed effects as dummies) on the package's data, following the script's sample steps: N = 1,842 dyads in 81 elections and 20 countries (columns 1-2), 1,836 (women) and 1,833 (men).  Every point estimate reproduces the printed value to the second decimal (1.887, 1.726, 2.097, 1.131; -0.596 / 0.943 / 0.371 in column 2; adj. R2 0.154 / 0.308).  SEs: with clustering by COUNTRY (20 clusters) the women-MPs SEs are 0.431 / 0.514 / 0.527 / 0.487 (CR1), i.e. the printed 0.43 / 0.52 / 0.53 / 0.50 up to the small-sample correction (the script uses estimatr::starprep, default CR2).  With clustering by ELECTION (country-year, 81 clusters), which is what the paper's text and table note say, they are 0.365 / 0.428 / 0.432 / 0.401, and the column-2 controls 0.073 / 0.175 / 0.129.  So the printed SEs are country-clustered and the paper misdescribes the clustering: a reproducer following the paper's words gets the point estimates but SEs ~15-20% smaller.  Contexts keep the paper's wording ("clustered by election"); do not "fix" them.
> Package structure (package-only facts; never in contexts).  One script, replication_code.R (libraries tidyverse, stargazer, haven, estimatr, dplyr, fixest, modelsummary; no setwd, relative paths).  Table 1 columns 1-2 (lines ~40-70): load("dyadic_data_1-4-22.Rdata") creates object updated_data (2,266 rows, 85 columns); cntryyr = paste(country, year); keep to_prior_seats >= 4; keep rile_distance_s, prior_coalition, prior_opposition, econ_distance_s, society_distance_s, year, country, party_dislike, party_like, cntryyr, to_pfeml, to_prior_seats, to_mp_number and na.omit (listwise, over columns the model does not use); lm(party_like ~ to_pfeml [+ rile_distance_s + prior_coalition + prior_opposition] + as.factor(cntryyr)), SEs from starprep(clusters = dta$country) into stargazer (labelled "Country-Level Clustered SEs?").  Columns 3-4 (lines ~73-117): readRDS("gender_disagregated_8-8-21.rds"), like = 10 - dislike, gender == 2 (women) / 1 (men), same model on countryyear.  The one path bug I4R fixed is at line ~671, load("Data/multilevel_1-5-22.Rdata") (a Data/ subfolder the package does not have) — supplementary Tables S11-S12 only.  Figure 1 needs only the dyadic file.  The independent- mode script-free copy carries no answers (no .tex/.log/.RData output).
> Left out.  Table 1 control coefficients in columns 3-4 (-0.62 / 0.94 / 0.36 and -0.66 / 0.96 / 0.35, same pattern as column 2), adjusted R2 (0.15 / 0.31 / 0.31 / 0.30), the 0.55-unit +/-1 SD effect and the 0.29 / 0.16 mean / SD of the women-MPs share (derived from Table 1 and Figure 1), the 125-party count, and all supplementary-appendix models (S2-S12).
> First run 2026-10-21 (Phase 3.2 evaluation pass; main 0492c17, after the content-aware strip rule and the printed-precision floor; Opus 4.7, 47-package image, LLM cache on, --mode all, one run per mode; eval-7papers-all-modes-2026-10-21.json).  Seeded 11 / 11 (first scored 11, exact on the first script); independent 7 / 11 (first scored 0; 1 error + 3 claim refinements); blind 1 / 11 (first scored 1; 1 error repair).  Independent's first script crashed and the passes came after claim refinement; the three N claims failed (1,535 / 1,535 / 1,529 vs 1,842 / 1,836 / 1,833) and the men-partisans coefficient (1.87 vs 1.13).  Blind's first script also crashed; after the repair only n_election_studies (81) matched: all seven coefficients came out with the opposite sign at similar magnitudes (e.g. -1.95 vs 1.89) and N was 2,019 vs 1,842.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `women_mps_coef_bivariate` | 1.89 | 0.43 | Table 1, column 1 (Bivariate model), [out-party j's proportion of women MPs (t - 1)] | 1.89 | matches |
| 1 | `women_mps_coef_full` | 1.73 | 0.52 | Table 1, column 2 (Full model), [out-party j's proportion of women MPs (t - 1)] | 1.73 | matches |
| 2 | `women_mps_coef_women_partisans` | 2.1 | 0.53 | Table 1, column 3 (Women partisans), [out-party j's proportion of women MPs (t - 1)] | 2.1 | matches |
| 3 | `women_mps_coef_men_partisans` | 1.13 | 0.5 | Table 1, column 4 (Men partisans), [out-party j's proportion of women MPs (t - 1)] | 1.13 | matches |
| 4 | `right_left_distance_coef_full` | -0.6 | 0.09 | Table 1, column 2 (Full model), [elite right-left distance i, j (t)] | -0.6 | matches |
| 5 | `coalition_partners_coef_full` | 0.94 | 0.25 | Table 1, column 2 (Full model), [i, j are coalition partners (t)] | 0.94 | matches |
| 6 | `opposition_partners_coef_full` | 0.37 | 0.11 | Table 1, column 2 (Full model), [i, j are opposition partners (t)] | 0.37 | matches |
| 7 | `n_directed_dyads` | 1842 | — | Table 1, Observations, columns 1-2; Results (text) | 1842 | matches |
| 8 | `n_obs_women_partisans` | 1836 | — | Table 1, Observations, column 3 | 1836 | matches |
| 9 | `n_obs_men_partisans` | 1833 | — | Table 1, Observations, column 4 | 1833 | matches |
| 10 | `n_election_studies` | 81 | — | Data and Analysis; Results (text) | 81 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [11/11](seeded/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[11/11](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [11/11](independent/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[11/11](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [8/11](blind/claude-code/2026-10-21-b/CELL.md) (2026-10-21-b)<br>[8/11](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[7/11](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-claude-opus-4-7` | [11/11](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [7/11](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) | [1/11](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (20261021T142909Z) |
| `pipeline-desktop-opus` | [11/11](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [10/11](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (20261023T064839Z) | [7/11](blind/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) |
| `pipeline-desktop-opus-run2` | [11/11](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [8/11](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [2/11](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) | `women_mps_coef_men_partisans` | 1.69763 | 1.13 | ±0.5 (se_band) | 1.135 | FAIL |
| [blind/pipeline-desktop-opus/20261023T063725Z](blind/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `women_mps_coef_women_partisans` | 1.45509 | 2.1 | ±0.53 (se_band) | 1.217 | FAIL |
| [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) | `women_mps_coef_women_partisans` | 1.69263 | 2.1 | ±0.53 (se_band) | 0.769 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `women_mps_coef_women_partisans` | 1.71259 | 2.1 | ±0.53 (se_band) | 0.731 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `women_mps_coef_women_partisans` | 1.71259 | 2.1 | ±0.53 (se_band) | 0.731 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `women_mps_coef_bivariate` | 1.60382 | 1.89 | ±0.43 (se_band) | 0.666 | PASS |
| [blind/pipeline-desktop-opus/20261023T063725Z](blind/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `women_mps_coef_bivariate` | 1.60382 | 1.89 | ±0.43 (se_band) | 0.666 | PASS |
| [blind/pipeline-desktop-opus/20261023T063725Z](blind/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `women_mps_coef_men_partisans` | 1.45694 | 1.13 | ±0.5 (se_band) | 0.654 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `coalition_partners_coef_full` | 1.07692 | 0.94 | ±0.25 (se_band) | 0.548 | PASS |
| [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) | `women_mps_coef_men_partisans` | 1.8661 | 1.13 | ±0.5 (se_band) | 1.472 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-10-21-b](seeded/claude-code/2026-10-21-b/CELL.md) (11/11)
  - Standard errors clustered by country as in the authors' replication_code.R (paper text says clustered by election); no claimed quantity depends on the standard errors. lm with as.factor(cntryyr) translated to fixest::feols with cntryyr absorbed (identical point estimates).
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (11/11)
  - lm(... + as.factor(cntryyr)) translated to fixest::feols with cntryyr absorbed as a fixed effect (identical point estimates). SEs clustered by country as in replication_code.R's starprep(clusters = country); the paper text says election-clustered, so the election-clustered summary is also printed (coefficients unaffected).
- [independent/claude-code/2026-10-21-b](independent/claude-code/2026-10-21-b/CELL.md) (11/11)
  - The paper restricts to dyads where both parties have at least four MPs in the year before the survey. In the data, filtering on the evaluated (to) party's prior seats (to_prior_seats >= 4) reproduces the reported N of 1,842 exactly, while filtering on both parties gives 1,535. I used the to-party filter. Dyads where to_pfeml is missing are dropped listwise.
  - Elite right-left distance is the dataset's pre-standardized rile_distance_s (standardized over the full 2,266-row dyadic file; its raw mean of 22.4 and SD of 17.6 match the paper's footnote 3), not re-standardized within the estimation sample.
  - Coalition and opposition partner dummies are govern_together and opposition_together (status at the time of the survey), not prior_coalition and prior_opposition.
  - The gender-specific DV is 10 - dislike from gender_disagregated_8-8-21.rds (gender 2 = women, 1 = men), with the same to_prior_seats >= 4 filter.
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (11/11)
  - Sample restriction implemented as out-party (to-party) prior lower-house seats >= 4 (to_prior_seats), which yields exactly the paper's 1,842 dyads; applying the >=4 filter to both parties gives 1,535. US rows coded 999 seats are kept (major parties).
  - Coalition/opposition-partner dummies use prior_coalition / prior_opposition (codebook lists these as used in the analysis), not govern_together / opposition_together.
  - Left-right distance (CMP rile_distance) standardized over the estimation sample (mean 22.5, SD 17.5 vs paper's 22.4 / 17.6).
  - Gender-specific DV computed as 10 - dislike from gender_disagregated_8-8-21.rds (gender 2 = women, 1 = men).
- [independent/pipeline-claude-opus-4-7/20261021T142909Z](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) (7/11; failed: `women_mps_coef_men_partisans`, `n_directed_dyads`, `n_obs_women_partisans`, `n_obs_men_partisans`)
  - Treated prior_seats==999 as missing and substituted mp_number to recover ~1842 dyad sample; paper does not clearly specify the handling of this sentinel value.
- [independent/pipeline-desktop-opus/20261023T064839Z](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) (10/11; failed: `women_mps_coef_men_partisans`)
  - to_/from_mp_number are CMP party codes, not seat counts; the >=4 MPs restriction is applied to to_/from_prior_seats (seats in year before survey)
  - Party-size filter variant 'to4_drop' (handling of missing/999 seat codes, or which side is filtered) chosen as the one giving N closest to the paper's 1,842
- [blind/claude-code/2026-10-21-b](blind/claude-code/2026-10-21-b/CELL.md) (8/11; failed: `n_directed_dyads`, `n_obs_women_partisans`, `n_obs_men_partisans`)
  - Sample restriction applied literally as the paper states it: both parties i and j had >= 4 prior lower-chamber seats (from_prior_seats >= 4 & to_prior_seats >= 4), then listwise deletion on to_pfeml (44 rows), giving 1,535 dyads. Exploration (attempt-2) showed that filtering on the evaluated (to) party's seats only, with non-missing to_pfeml, yields 1,842 rows -- the dyad count quoted in the task context -- which suggests the authors' code may have applied the >=4-MP filter only to the out-party. This alternative was NOT adopted, because switching to it would be adjusting the specification toward a number given in the task.
  - Coalition/opposition-partner dummies use prior_coalition / prior_opposition (government status in the period before/at the time of the post-election survey), which the dataset codebook lists as the variables used in the analysis; govern_together / opposition_together are listed by the codebook as not used.
  - Elite left-right distance uses the dataset's pre-standardized rile_distance_s (standardized over the full 2,266-row dyadic file, mean 22.44, SD 17.61, matching footnote 3), not re-standardized on the estimation sample.
  - Gender-disaggregated DV computed as 10 - dislike (dislike is the reversed 0-10 thermometer); gender 2 = women, 1 = men per the codebook. Same >=4-seat rule for both parties.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (7/11; failed: `n_directed_dyads`, `n_obs_women_partisans`, `n_obs_men_partisans`, `n_election_studies`)
  - Coalition/opposition dummies use prior_coalition / prior_opposition (governing status in the period up to the survey), which the dataset codebook flags as the analysis variables; govern_together / opposition_together (flagged 'not used') were not used.
  - Women/men partisan DV built as 10 - dislike from the gender-disaggregated file (it stores only the reversed 0=like scale), so coefficients are on the 0-10 liking scale like columns 1-2.
  - Seat counts of 999 treated as missing; the four-MP restriction requires to_prior_seats >= 4 and from_prior_seats >= 4.
  - Country-year fixed effects and clustering both on cntryyr (no country-year in the estimation sample holds two election dates). The table's 'Country and year fixed effects' label was read as country-year FE, following the text.
  - Left-right distance uses the dataset's precomputed standardized rile_distance_s (raw rile_distance mean 22.44 over the full file).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- independent: `n_directed_dyads` — pipeline 1/3, agent 2/2
- independent: `n_obs_men_partisans` — pipeline 1/3, agent 2/2
- independent: `n_obs_women_partisans` — pipeline 1/3, agent 2/2
- independent: `women_mps_coef_men_partisans` — pipeline 1/3, agent 2/2
- blind: `coalition_partners_coef_full` — pipeline 1/3, agent 3/3
- blind: `opposition_partners_coef_full` — pipeline 1/3, agent 3/3
- blind: `right_left_distance_coef_full` — pipeline 1/3, agent 3/3
- blind: `women_mps_coef_bivariate` — pipeline 1/3, agent 3/3
- blind: `women_mps_coef_full` — pipeline 1/3, agent 3/3
- blind: `women_mps_coef_women_partisans` — pipeline 1/3, agent 3/3

## Cells

### seeded · claude-code · 2026-10-21-b

[`seeded/claude-code/2026-10-21-b/CELL.md`](seeded/claude-code/2026-10-21-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-22T02:02:37Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-11-02T19:36:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-claude-opus-4-7 · 20261021T142909Z

[`seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](seeded/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-21-b

[`independent/claude-code/2026-10-21-b/CELL.md`](independent/claude-code/2026-10-21-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 4; 2026-10-22T02:08:30Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 4; 2026-11-02T04:29:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-claude-opus-4-7 · 20261021T142909Z

[`independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](independent/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 7/11, re-scored 7/11; first scored 0/11; executions 5; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064839Z

[`independent/pipeline-desktop-opus/20261023T064839Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064839Z/CELL.md) — final 10/11, re-scored 10/11; first scored 6/11; executions 4; 2026-10-23T06:48:39Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T151837Z

[`independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 8/11, re-scored 8/11; first scored 8/11; executions 2; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-21-b

[`blind/claude-code/2026-10-21-b/CELL.md`](blind/claude-code/2026-10-21-b/CELL.md) — final 8/11, re-scored 8/11; first scored 8/11; executions 3; 2026-10-22T02:12:33Z; from `claude-code-7papers-all-modes-2026-10-21.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 8/11, re-scored 8/11; first scored 8/11; executions 3; 2026-10-22T02:45:01Z; from `claude-code-blind-rerun-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 7/11, re-scored 7/11; first scored 7/11; executions 2; 2026-11-02T04:24:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-claude-opus-4-7 · 20261021T142909Z

[`blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md`](blind/pipeline-claude-opus-4-7/20261021T142909Z/CELL.md) — final 1/11, re-scored 1/11; first scored 1/11; executions 2; 2026-10-21T14:29:09Z; from `pipeline-10papers-all-modes-2026-10-21.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T063725Z

[`blind/pipeline-desktop-opus/20261023T063725Z/CELL.md`](blind/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 7/11, re-scored 7/11; first scored 7/11; executions 2; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 2/11, re-scored 2/11; first scored 2/11; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

