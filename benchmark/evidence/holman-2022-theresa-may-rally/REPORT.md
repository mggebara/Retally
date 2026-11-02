# Evidence report: holman-2022-theresa-may-rally

**The Curious Case of Theresa May and the Public That Did Not Rally: Gendered Reactions to Terrorist Attacks Can Cause Slumps Not Bumps** — Mirya R. Holman, Jennifer L. Merolla, Elizabeth J. Zechmeister

- Paper: https://www.cambridge.org/core/services/aop-cambridge-core/content/view/CCB0F99CE10065BAECA662C140F966EC/S0003055421000861a.pdf/div-class-title-the-curious-case-of-theresa-may-and-the-public-that-did-not-rally-gendered-reactions-to-terrorist-attacks-can-cause-slumps-not-bumps-div.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/272842/1/I4R-DP041.pdf
- I4R outcome label: not_reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/holman-2022-theresa-may-rally.yaml`

> Headline findings (as published): after the 22 May 2017 Manchester Arena bombing, British Election Study respondents liked Theresa May less and were less likely to prefer her as prime minister (Table 1, wave 12 before/after; Table 2, panel difference-in-differences), and in a global country-quarter panel major international terrorist attacks raise approval of men executives (3.1 points) but lower it for women (interaction -4.3; Table 4).  DP41 (Jetter & Stockley) finds the May results robust to its corrections but the global Table 4 result not: correcting the election-quarter coding, dropping the May-Manchester quarter or clustering by country each removes 5% significance.  The authors' reply (DP44) disputes the conclusion but accepts the errors; their 2024 APSR corrigendum replaces Tables 2 and 4.
> Original analysis in Stata (one do-file, xtreg and xtpcse); language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 11 claims: Table 4's two attack coefficients and N (the table I4R examined; its constant and R2 are not pinned — the constant depends on Stata's base-country dummy and R2 on xtpcse's definition), and Table 2's six difference-in-differences coefficients and two Ns.  Every coefficient carries its SE.  Values exactly as printed in the published APSR PDF; the Table 4 values equal the meta-database's o_coeff / o_std_err (-4.333 / 1.859) and DP41's reproduction; Table 2 equals DP41 Table B1 cols 1-2.  Table 1 and 3 (wave-12 cross-sections) are producible from BES_data.dta but were left out to keep the entry on the two tables the replicators corrected.
> What was read.  The published APSR PDF (all 16 pp.: design, Tables 1-4, the global-analysis section and footnotes 15-19); DP41 (28 pp., EconStor, incl. Table 1, Table 2, Table B1 and the election-coding appendix A.1); the authors' reply DP44 (July 19 update, opening sections); the 2024 corrigendum (2 pp., Cambridge Core); the Dataverse API metadata for versions 1.0 and 2.0; the version-1.0 package (replication_files.do in the Table 2 and Table 4 sections; columns and sample counts of did_data.dta and global_approval.dta); the meta-database's 18 team-86 rows.
> Package-only facts (never in contexts).  The do-file runs every analysis from one script and expects the working directory to hold the .dta files; it sets global demographics = white gender labour party_other income ideology2 at the top (line 36), which the Table 2 code reuses, so the Table 2 section does not run on its own.  It needs estout, lean2, lincomest, coefplot, grc1leg (ssc; commented-out installs) and writes .rtf tables.  Table 2: use did_data.dta; xtset id wave; xtreg likeMayW i.treatment1##i.time i.wave $demographics and the same for bestPMW — xtreg WITHOUT fe, i.e. Stata's default random-effects GLS with wave dummies, although the paper calls the table "with fixed effects" and the best-PM column a logit.  Complete cases give exactly 143,499 (likeMayW; waves 9-16) and 97,155 (bestPMW; waves 7, 8, 10, 11, 12 — waves 7 and 8 contribute 17,965 + 17,095 = 35,060, DP41's Cameron-era count).  Table 4: use global_approval.dta; xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth l(0/1).log_inflation l(0/4).election_qtr i.execrlc i.country_code, cor(psar1) i — panel-specific AR(1) Prais-Winsten with independent panel-corrected SEs, lagged growth and inflation and FIVE election indicators (current and four lags), which the table note summarises as "election in that year".  kill_16 is the >15-deaths attack dummy; lag_approval is the dependent variable (next-quarter approval, per the paper and DP41's equation 1).  The do-file never xtsets global_approval.dta: xtpcse and the l()/f() operators rely on the panel and time settings saved in the .dta's characteristics (_TSpanel / _TStvar), which an R port has to rebuild from country / qtr.  global_approval.dta has 5,469 rows and 45 country codes; the estimation sample is 44 countries (DP41 fn. 1: the paper's "66 countries" is wrong); kill_16 x female_pres = 1 in nine rows (Macapagal Arroyo x3, Thatcher x5, May 2017q2).  Variables used: country, qtr, country_code, lag_approval, kill_16, female_pres, growth, log_inflation, election_qtr, execrlc.
> Benchmark implications.  Reproducing the printed Table 4 needs Stata's xtpcse with psar1 (R: panelAR or pcse on a Prais-Winsten transform; an exact match is not guaranteed) and the five lagged election dummies the paper never spells out.  Reproducing Table 2 needs Stata's xtreg random-effects GLS (R: plm model = "random" or lme4), not the fixed effects the title says and not the logit the note says.  An independent run that follows the paper's text (fixed effects, logit) is expected to MISS the printed Table 2 best-PM values.  No run can be expected to land on the I4R Table 4 corrections: those need DP41's hand-recoded election calendar, which is not in this package (it is in the replicators' own package on the UWA repository / Borealis).  Table 2's correction (drop the Cameron waves) is derivable from the data.
> Blind-mode caveat (render check 2026-10-21).  The blind paper text redacts every pinned literal (20 redactions; none of the 11 values, SEs or Ns survives in task.md or paper.txt), but the results section's prose keeps the rounded Table 4 effects, "(3.1 points)" and "(4.3 points)", which the value-matching redactor does not catch.  A blind run therefore sees the Table 4 coefficients to one decimal; the Table 2 values do not appear in the prose.
> Left out.  Table 1 and Table 3 (wave-12 cross-sections with day- clustered SEs; reproducible but not examined by I4R), Figures 1-4, the constituency analysis (Figure 4), the appendix tables, and DP41's 32-specification figures.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `intl_attack_table4` | 3.112 | 0.875 | Table 4, International terrorist attack (All countries, attacks with more than 15 deaths) | — | — |
| 1 | `intl_attack_x_woman_exec_table4` | -4.333 | 1.859 | Table 4, International terrorist attack x Woman executive | -3.452 | does_not_match |
| 2 | `n_obs_table4` | 4328 | — | Table 4, Observations | 4429 | does_not_match |
| 3 | `did_attack_x_time_like_may_table2` | -0.1274 | 0.0187 | Table 2, column May likeability, Manchester attack * time | -0.1274 | matches |
| 4 | `did_attack_like_may_table2` | 0.0178 | 0.0278 | Table 2, column May likeability, Manchester attack | 0.0178 | matches |
| 5 | `did_time_like_may_table2` | -0.5007 | 0.0229 | Table 2, column May likeability, Time | -0.5007 | matches |
| 6 | `did_attack_x_time_may_best_pm_table2` | -0.0501 | 0.0044 | Table 2, column May best PM, Manchester attack * time | -0.0502 | matches |
| 7 | `did_attack_may_best_pm_table2` | -0.0002 | 0.004 | Table 2, column May best PM, Manchester attack | 0.0024 | does_not_match |
| 8 | `did_time_may_best_pm_table2` | 0.2098 | 0.0036 | Table 2, column May best PM, Time | 0.0287 | does_not_match |
| 9 | `n_obs_did_like_may_table2` | 143499 | — | Table 2, Observations, column May likeability | 143499 | matches |
| 10 | `n_obs_did_may_best_pm_table2` | 97155 | — | Table 2, Observations, column May best PM | 62095 | does_not_match |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [11/11](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[0/11](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [10/11](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[10/11](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [6/11](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[5/11](blind/claude-code/2026-10-22-b/CELL.md) (2026-10-22-b)<br>[6/11](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-desktop-opus` | [11/11](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [3/11](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) (20261023T064318Z) | [0/11](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [11/11](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [8/11](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (20261023T153002Z) | [0/11](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `did_time_like_may_table2` | -0.478198 | -0.5007 | ±0.0229 (se_band) | 0.983 | PASS |
| [blind/claude-code/2026-10-22-b](blind/claude-code/2026-10-22-b/CELL.md) | `intl_attack_table4` | 2.21565 | 3.112 | ±0.875 (se_band) | 1.024 | FAIL |
| [independent/pipeline-desktop-opus/20261023T064318Z](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) | `n_obs_table4` | 4369 | 4328 | ±43.28 (relative) | 0.947 | PASS |
| [independent/pipeline-desktop-opus/20261023T064318Z](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) | `n_obs_did_like_may_table2` | 145012 | 143499 | ±1434.99 (relative) | 1.054 | FAIL |
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `did_time_may_best_pm_table2` | 0.205917 | 0.2098 | ±0.004196 (relative) | 0.925 | PASS |
| [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) | `intl_attack_table4` | 2.32209 | 3.112 | ±0.875 (se_band) | 0.903 | PASS |
| [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) | `intl_attack_table4` | 2.32209 | 3.112 | ±0.875 (se_band) | 0.903 | PASS |
| [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) | `intl_attack_table4` | 2.32209 | 3.112 | ±0.875 (se_band) | 0.903 | PASS |
| [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) | `intl_attack_table4` | 2.32209 | 3.112 | ±0.875 (se_band) | 0.903 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) | `intl_attack_x_woman_exec_table4` | -2.14364 | -4.333 | ±1.859 (se_band) | 1.178 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) (11/11)
  - Table 4 xtpcse corr(psar1) implemented by hand: OLS residuals -> panel-specific rho (rhotype regress, consecutive-quarter pairs using tsset-style lags) -> Prais-Winsten transform (a time gap starts a new segment) -> OLS. One panel's rho (1.070) was bounded to 1. Only point estimates and N are reported; panel-corrected SEs were not computed.
  - Table 2 xtreg (Stata default random-effects GLS, Swamy-Arora with harmonic-mean T for unbalanced panels) implemented by hand. The paper's note calls the best-PM column logistic, but the authors' script runs linear xtreg RE, which is what is reproduced.
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (0/11; failed: `intl_attack_table4`, `intl_attack_x_woman_exec_table4`, `n_obs_table4`, `did_attack_x_time_like_may_table2`, `did_attack_like_may_table2`, `did_time_like_may_table2`, `did_attack_x_time_may_best_pm_table2`, `did_attack_may_best_pm_table2`, `did_time_may_best_pm_table2`, `n_obs_did_like_may_table2`, `n_obs_did_may_best_pm_table2`)
  - Table 4 (xtpcse, cor(psar1), independent) implemented by hand: OLS residuals, panel-specific rho from regressing e_t on e_{t-1} over consecutive quarters, truncated to [-1, 1]; Prais-Winsten transform with the sqrt(1 - rho^2) first-observation weight also applied to the first observation after an internal gap (195 such gaps in the estimation sample); panel-heteroskedastic PCSEs. Stata's exact handling of gaps and of rho > 1 (one panel, rho = 1.07) is not known; with rho truncated to 1 that country's dummy is aliased after the transform.
  - Table 2 (xtreg, default random effects) implemented by hand as Swamy-Arora GLS with the unbalanced-panel harmonic-mean T; wave dummies with the later collinear wave dummy omitted (Stata ordering), linear model also for the best-PM column as in the do-file.
- [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) (10/11; failed: `n_obs_table4`)
  - Table 4: estimation sample is every complete country-quarter in global_approval.dta (4,486 obs, 44 country_code panels) instead of the reported 4,328; no rule found in the paper or data that yields 4,328 (checked lagged regressors, lead DV, execrlc>0, AR(1) spell trimming).
  - Table 4: coefficients from OLS with country_code fixed effects (xtpcse without AR(1) gives the same point estimates); printed SEs are iid, not panel-corrected.
  - Table 4: dependent variable is lag_approval, which the series shows to be approval in the quarter after row t (US 9/11 row holds the 2001Q4 peak; UK Manchester row holds the post-election 2017Q3 slump), i.e. next-quarter approval as the paper describes; attack = kill_16 (16+ deaths, matches the paper's 60 attack quarters, 9 under women).
  - Table 2: estimated as random-effects GLS (Stata xtreg re, Swamy-Arora with harmonic-mean T) implemented by hand, with wave dummies (base = first wave; last post-attack wave omitted as collinear with time, as Stata does). The May best PM column is a linear probability model, not a logit, because the reported magnitudes and SEs are LPM-scale. Income missing values are dropped (not imputed); ideology2 (missing set to midpoint) is used.
  - Table 4 sample is all complete country-quarters in global_approval.dta ( 4486 ), not 4,328 as reported; SEs printed are iid, not panel-corrected (coefficients unaffected).
  - Table 2 estimated as random-effects GLS (xtreg re style) with wave dummies; the May best PM column is a linear probability model (reported magnitudes are LPM-scale), not logit.
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (10/11; failed: `n_obs_table4`)
  - Table 2 May best PM column estimated as a linear probability model (random-effects GLS), not the logit the table note describes; the published coefficients/SEs/constant are on the linear-probability scale.
  - Table 2 estimated as respondent random-effects GLS (Swamy-Arora, plm), i.e. Stata xtreg's default, with explicit wave dummies; time is collinear with the wave dummies, so the last wave dummy is dropped.
  - Table 4: DV is the dataset's only approval measure (lag_approval) regressed on the contemporaneous kill_16 (16+ deaths) indicator; execrlc entered linearly; country_code fixed effects via OLS. The sample is all complete cases (N=4486); the paper's N=4328 could not be reconstructed (growth-rate, lead/lag timing and AR(1)-trimming variants were counted in exploratory runs and none gives 4328). Point estimates are OLS-LSDV; Beck-Katz panel-corrected SEs (plm vcovBK) are printed but not scored, and no AR(1) correction was applied.
  - Table 2 May best PM column estimated as a linear probability model (random-effects GLS), not logit
  - Table 4 approval timing uses the dataset's lag_approval with the contemporaneous kill_16 indicator
- [independent/pipeline-desktop-opus/20261023T064318Z](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) (3/11; failed: `intl_attack_table4`, `intl_attack_x_woman_exec_table4`, `did_attack_x_time_like_may_table2`, `did_attack_like_may_table2`, `did_time_like_may_table2`, `did_time_may_best_pm_table2`, `n_obs_did_like_may_table2`, `n_obs_did_may_best_pm_table2`)
  - Table 2 likeability model restricted to BES waves 1-13 (window chosen to match the paper's reported N; paper does not list waves)
  - Table 2 best-PM model restricted to BES waves 9-12 (window chosen to match the paper's reported N; paper does not list waves)
- [independent/pipeline-desktop-opus-run2/20261023T153002Z](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) (8/11; failed: `intl_attack_table4`, `intl_attack_x_woman_exec_table4`, `n_obs_table4`)
  - Table 4 DV timing/attack timing/lagged-DV/consecutive-approval sample variant built from lag_approval chosen by sample size closest to 4328: dvlead0\|attlag0\|ldv\|req3
  - Like-May DiD treatment/ideology/weight variant chosen among N-matching candidates by closeness of reported regressor coefficients: like\|treatment2\|raw\|ideo3\|none
  - May-best-PM DiD estimated as a linear probability model (Table 2 magnitudes are on the probability scale)
  - Best-PM DiD variant chosen among N-matching candidates by closeness of reported regressor coefficients: bpw_1v0\|treatment1\|raw\|ideo3\|none
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (6/11; failed: `n_obs_table4`, `did_attack_x_time_like_may_table2`, `did_time_like_may_table2`, `did_attack_x_time_may_best_pm_table2`, `did_time_may_best_pm_table2`)
  - Table 4: coefficients are from OLS with country (country_code) dummies; panel-corrected SEs are computed by hand (Beck-Katz, casewise) since no PCSE package is installed. Coefficients do not depend on the SE method. No AR(1)/Prais-Winsten correction was applied because the paper does not mention one.
  - Table 4: DV is lag_approval (the only approval variable, labelled 'Lagged approval'); attack indicator is kill_16 (international attack with 16+ deaths, i.e. more than 15; exactly 60 country-quarters, 9 under women executives as the paper states); execrlc entered linearly; 'growth' is used as stored (it is a real-GDP level series). The estimation sample has 44 country-office units, not the 66 the paper mentions (country_code takes only 44 distinct values in the data).
  - Table 2: all waves with a non-missing outcome are used (like May: waves 9-16; best PM: waves 7, 8, 10, 11, 12); likeMayW code 9999 (don't know) set to missing; outcome for best PM is bestPMW (1 = May, 0 = Corbyn), logit; controls white, gender, labour, party_other, income, ideology2 (ideology with missing coded to the scale midpoint); no survey weights. time is perfectly collinear with the wave dummies, so time is entered before them and the last wave dummy (16 for like May, 12 for best PM) is dropped; the reported Time coefficient depends on this choice.
- [blind/claude-code/2026-10-22-b](blind/claude-code/2026-10-22-b/CELL.md) (5/11; failed: `intl_attack_table4`, `n_obs_table4`, `did_attack_x_time_like_may_table2`, `did_time_like_may_table2`, `did_attack_x_time_may_best_pm_table2`, `did_time_may_best_pm_table2`)
  - Table 4: global_approval.dta has 44 countries (paper says 66); used as provided. DV is `lag_approval`, which is missing in the last quarter of every panel and so is the next-quarter (lead) approval aligned to quarter t; regressed on contemporaneous kill_16 (16+ deaths = more than 15; 60 attack quarters, 9 under women in the full file, 50 / 9 in the estimation sample).
  - Table 4: 'GDP' control is the `growth` variable as provided (values look like GDP levels); election control is election_qtr (the only election variable); execrlc (DPI left/center/right, 0 = no information) entered as categories; OLS with country dummies. Panel-corrected SEs do not affect point estimates and were not needed (the informational PCSE block returned NULL and printed nothing).
  - Table 2: OLS (likeability) and logit (best PM, log-odds coefficients, as the table note says) with wave dummies entered after `time`; the collinear last wave dummy is dropped (wave 16 for likeability, wave 12 for best PM), so `time` is identified relative to that convention. Controls white, gender, labour, party_other, income, ideology2 (midpoint-recoded ideology); listwise deletion; no survey weights. Restricting to wave-12 participants gives identical samples and estimates.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (6/11; failed: `n_obs_table4`, `did_attack_x_time_like_may_table2`, `did_time_like_may_table2`, `did_attack_x_time_may_best_pm_table2`, `did_time_may_best_pm_table2`)
  - Table 4: the data file has no contemporaneous approval series, only `lag_approval` (labelled 'Lagged approval'); its timing (UK value drops at the Manchester quarter 2017q2) indicates it is the next-quarter approval aligned to the attack quarter, so it is used as the DV with the attack indicator in the same row.
  - Table 4: attack indicator = kill_16 (international attack, 16+ i.e. more than 15 deaths); woman executive = female_pres; execrlc (DPI left/center/right, 0-3) entered linearly; country FE on country_code (44 panels survive listwise deletion, not 66). Point estimates are OLS with country dummies (identical to xtpcse without AR terms); panel-corrected SEs not reproduced (clustered SEs printed for information only; SEs are not scored).
  - Table 2: did_data.dta; treatment = treatment1 (surveyed after attack in wave 12, constant within respondent), time = 1 for waves >= 12, interaction, wave dummies; time is collinear with the wave dummies, so (as Stata's left-to-right collinearity rule would) the last aliased wave dummy is dropped and time kept, which makes the time coefficient a contrast of the last wave with the base wave. Controls: white (ethnically British), female, labour, party_other, income, ideology2 (ideology with missing set to midpoint, per footnote 8); listwise deletion otherwise. Unweighted.
  - Table 2 May best PM: outcome = bestPMW (waves 7, 8, 10, 11, 12), logistic regression per the table note; coefficients reported in log-odds.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `intl_attack_table4` — pipeline 0/2, agent 2/2
- independent: `intl_attack_x_woman_exec_table4` — pipeline 0/2, agent 2/2
- blind: `did_attack_like_may_table2` — pipeline 0/2, agent 3/3
- blind: `did_attack_may_best_pm_table2` — pipeline 0/2, agent 3/3
- blind: `intl_attack_x_woman_exec_table4` — pipeline 0/2, agent 3/3
- blind: `n_obs_did_like_may_table2` — pipeline 0/2, agent 3/3
- blind: `n_obs_did_may_best_pm_table2` — pipeline 0/2, agent 3/3

Pass rates at least 50 points apart (not unanimous):

- seeded: `did_attack_like_may_table2` — pipeline 2/2, agent 1/2
- seeded: `did_attack_may_best_pm_table2` — pipeline 2/2, agent 1/2
- seeded: `did_attack_x_time_like_may_table2` — pipeline 2/2, agent 1/2
- seeded: `did_attack_x_time_may_best_pm_table2` — pipeline 2/2, agent 1/2
- seeded: `did_time_like_may_table2` — pipeline 2/2, agent 1/2
- seeded: `did_time_may_best_pm_table2` — pipeline 2/2, agent 1/2
- seeded: `intl_attack_table4` — pipeline 2/2, agent 1/2
- seeded: `intl_attack_x_woman_exec_table4` — pipeline 2/2, agent 1/2
- seeded: `n_obs_did_like_may_table2` — pipeline 2/2, agent 1/2
- seeded: `n_obs_did_may_best_pm_table2` — pipeline 2/2, agent 1/2
- seeded: `n_obs_table4` — pipeline 2/2, agent 1/2
- independent: `did_attack_like_may_table2` — pipeline 1/2, agent 2/2
- independent: `did_attack_x_time_like_may_table2` — pipeline 1/2, agent 2/2
- independent: `did_time_like_may_table2` — pipeline 1/2, agent 2/2
- independent: `did_time_may_best_pm_table2` — pipeline 1/2, agent 2/2
- independent: `n_obs_did_like_may_table2` — pipeline 1/2, agent 2/2
- independent: `n_obs_did_may_best_pm_table2` — pipeline 1/2, agent 2/2
- independent: `n_obs_table4` — pipeline 1/2, agent 0/2
- blind: `intl_attack_table4` — pipeline 0/2, agent 2/3

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 3; 2026-10-22T03:04:50Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 5; 2026-11-02T19:40:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 10/11, re-scored 10/11; first scored 10/11; executions 7; 2026-10-22T03:15:29Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 10/11, re-scored 10/11; first scored 6/11; executions 9; 2026-11-02T04:38:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064318Z

[`independent/pipeline-desktop-opus/20261023T064318Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) — final 3/11, re-scored 3/11; first scored 1/11; executions 3; 2026-10-23T06:43:18Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T153002Z

[`independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T153002Z/CELL.md) — final 8/11, re-scored 8/11; first scored 3/11; executions 4; 2026-10-23T15:30:02Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 6/11, re-scored 6/11; first scored 6/11; executions 4; 2026-10-22T03:21:35Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-10-22-b

[`blind/claude-code/2026-10-22-b/CELL.md`](blind/claude-code/2026-10-22-b/CELL.md) — final 5/11, re-scored 5/11; first scored 5/11; executions 3; 2026-10-22T03:30:01Z; from `claude-code-blind-rerun-2026-10-22-b.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 6/11, re-scored 6/11; first scored 6/11; executions 3; 2026-11-02T04:45:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

