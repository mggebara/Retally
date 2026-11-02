# Evidence report: bokobza-2022-morning-after-coup-purges

**The Morning After: Cabinet Instability and the Purging of Ministers after Failed Coup Attempts in Autocracies** — Laure Bokobza, Suthan Krishnarajan, Jacob Nyrup, Casper Sakstrup, Lasse Aaskoven

- Paper: https://pure.au.dk/ws/files/365105209/The_Morning_After_Cabinet_Instability_and_the_Purging_of_Ministers_after_Failed_Coup_Attempts_in_Autocracies_Accepted_.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/bokobza-2022-morning-after-coup-purges.yaml`

> Headline findings: failed coup attempts raise the year-to-year cabinet replacement rate in autocracies by 8-11 percentage points (Figure 2; Tables A1-A2: 0.10 and 0.11 with country fixed effects, 0.08 and 0.09 with leader fixed effects, SE 0.03 throughout), while alternative instability events (civil war, nonviolent campaigns, military disputes, interstate war, strikes; Table A3) do not once leader fixed effects are included.  At the minister level, purges after failed coups target newcomers (0.14 for under two years' experience; interaction -0.10 for over six years), ministers from parties other than the leader's (0.17; -0.13 for the leader's party), defence ministers (0.20; natural resources -0.18 relative to defence) and non-leader prime ministers / presidents (0.37).
> Curation pass (2026-11-01).  Pinned 11 claims: four A1/A2 failed-coup coefficients (Base and Main, country and leader fixed effects), four K1 coefficients (failed coup and the over-6-years and leader's-party interactions) and three K2 coefficients (failed coup in the responsibility and importance models, natural-resources interaction), each with its SE.  The A1 Base N (3,715) and the K1 experience-model N (90,020) were pinned in a first draft and dropped after the step-6 leak check: the main text states both ("up to 3,715 country-year observations"; Figure 3 note "Up to 90,020 minister-years"), so a blind run would read them in the paper.  sample_size: A1 Base 3,715, Main 3,676; A2 Base 3,332, Main 3,307; K1 experience 90,020, affiliation 86,057; K2 responsibility 76,530, importance 90,014.  All coefficients and SEs are printed to two decimals; the printed-precision floor (+-0.005) binds.  Full-precision values (Stata log; I4R o_coeff for K): A1 0.0985 (0.0327), 0.1055 (0.0323); A2 0.0839 (0.0317), 0.0853 (0.0318); K1 0.142112 (0.041926), interaction over 6 years -0.103 (0.052), 0.174175 (0.056053), leader's party -0.126 (0.061); K2 0.202499 (0.065968), natural resources -0.183 (0.083), 0.370185 (0.09339).  Note that A1 Main 0.1055 and A2 Main 0.0853 sit just inside their printed bands. Left out: the other A1/A2 columns (electoral, economic, instability, purges moving averages, all controls), the A3 placebos, K1 2-3 and 4-6 year interactions, K2 foreign/finance/other and importance-tier interactions, Table K3 (Figure 5), control coefficients, within R2s, the Figure 1 medians (17.4% / 38.1%) and all robustness appendices.
> Cross-check against the meta-database.  Every pinned coefficient and SE equals its o_coeff / o_std_err rounded to two decimals: A1 rows record 0.10 / 0.11 (0.03), A2 rows 0.08 / 0.09 (0.03), K1 0.142112 (0.041926) and 0.174175 (0.056053), K2 0.202499 (0.065968) and 0.370185 (0.09339); the interactions match the figure-row o_coeff (-0.103, -0.126, -0.183) and the differences of the recorded marginal effects.  The I4R "table k3" label covers both the K2 importance column and Table K3.  Row 5691 records 0.85329 for what is 0.085329 (the "Other type of minister" marginal effect; typo in the database).
> What was read.  The accepted manuscript PDF (all 72 pp.: text, Figures 1-5 notes, appendices A-R); the meta-database's 137 team-95 rows; Dataverse API metadata (version list, file list, licence); Crossref metadata; the package: readme.txt, the coefficient lines and sample sizes in the Stata .smcl log for Tables A1-A2, the R Markdown log's structure and console output, and figure4.jpg.  The R script, do-file and .tex tables were not read in full.
> Package-only facts (never in contexts).  Country level: xtreg replacement_rateadj_minister coupattempt_whogov L.gdp_cap_pwt_ln L.pop_pwt_ln [L.military_c L.monarchy_c L.party_c] i.YEAR_DATA if democracy1==0 & independent==1, fe cluster(COUNTRY_ID); the leader fixed-effects tables re-xtset the panel on the leader identifier (leader_cab_id) and run the same xtreg, fe.  The .dta has 7,878 rows. Individual level: read_rds(...) filtered to democracy_lag == 0 & leader == 0 & non-missing purged_y1, gdp_cap_pwt_ln and pop_pwt_ln (98,719 rows; 95,751 with a non-missing coupattempt_presentyear, 2,039 of them coup years), then lfe::felm models with country and year fixed effects and country clusters, written with texreg to output/appendix_k*.tex; the R script loads packages with pacman and uses windowsFonts.  The K1 experience sample (junior ministers excluded) has 90,020 rows with a non-missing coup indicator, per the R log's N computation for Figure 3.
> Strip rule (independent / blind mount).  The name and content rules already withheld .Rhistory, the .R script, the .smcl log, the do-file saved as .txt (script-content:stata) and appendix_k1-3.tex (regression-table).  They kept morning_after_logfile_individuallevel.html, a pandoc-rendered R Markdown log holding the whole R script and its console output (filter counts including the K1 N).  benchmark/ strip_rule.py now strips an HTML page with five or more language-tagged code chunks (132 <pre class="r"> chunks here) as script-content:r.  The 14 .jpg coefficient plots stay (binary, no printed numbers; they are the paper's own figures).
> Blind-mode caveat (oracle render check 2026-11-01).  The blind pipeline's first prompt (the methodology summary, which receives the paper text) contains no package script text and none of the 11 pinned values as results; the pinned-value forms it does contain are "p < 0.05" and "p < 0.1" (footnotes 21 and 20) and the illustrative "If the estimate is 0.10" (results section).  The prose does state rounded effects: "10 percentage points" for the A1 Base model, an "8-11 percentage-point" range across Figure 2, and "20 percentage points" for ministers of defense (with foreign affairs 16, finance 10, other 7), so a blind run sees claims 0 and 8 to the printed precision in words.  Also: the pipeline's paper parser titles this PDF "General Rights", from the Aarhus University cover sheet on page 1.
> Original analysis in Stata (country level) and R (individual level, lfe); language is r, the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `failed_coup_base_country_fe` | 0.1 | 0.03 | Table A1 (Tables for Figure 2), column Base Model, Failed coup attempt | 0.1 | matches |
| 1 | `failed_coup_main_country_fe` | 0.11 | 0.03 | Table A1, column Main Model, Failed coup attempt | 0.11 | matches |
| 2 | `failed_coup_base_leader_fe` | 0.08 | 0.03 | Table A2 (Tables for Figure 2), column Base Model, Failed coup attempt | 0.08 | matches |
| 3 | `failed_coup_main_leader_fe` | 0.09 | 0.03 | Table A2, column Main Model, Failed coup attempt | 0.09 | matches |
| 4 | `failed_coup_experience_model` | 0.14 | 0.04 | Table K1 (Table for Figure 3), column H2a: Experience, Failed coup attempt | 0.142112 | matches |
| 5 | `failed_coup_x_over_6_years_experience` | -0.1 | 0.05 | Table K1, column H2a: Experience, FCA*Over 6 years of experience (Ref: <2 y) | -0.102939 | matches |
| 6 | `failed_coup_affiliation_model` | 0.17 | 0.06 | Table K1, column H2b: Affiliation, Failed coup attempt | 0.174175 | matches |
| 7 | `failed_coup_x_leaders_party` | -0.13 | 0.06 | Table K1, column H2b: Affiliation, FCA*From the leader's party (Ref: Other party) | -0.125831 | matches |
| 8 | `failed_coup_responsibility_model` | 0.2 | 0.07 | Table K2 (Table for Figure 4), column H3a: Responsibility, Failed coup attempt | 0.202499 | matches |
| 9 | `failed_coup_x_natural_resources` | -0.18 | 0.08 | Table K2, column H3a: Responsibility, FCA*Minister of Natural Resources (Ref: D) | -0.183205 | matches |
| 10 | `failed_coup_importance_model` | 0.37 | 0.09 | Table K2, column H3b: Importance, Failed coup attempt | 0.370185 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [11/11](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) | [11/11](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) | [11/11](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a) |
| `pipeline-desktop-opus` | [9/11](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) | [11/11](independent/pipeline-desktop-opus/20261102T062442Z/CELL.md) (20261102T062442Z) | [4/11](blind/pipeline-desktop-opus/20261102T060946Z/CELL.md) (20261102T060946Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `failed_coup_main_leader_fe` | 0.085272 | 0.09 | ±0.005 (printed_precision) | 0.946 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `failed_coup_main_country_fe` | 0.105549 | 0.11 | ±0.005 (printed_precision) | 0.890 | PASS |
| [seeded/pipeline-desktop-opus/20261102T062442Z](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `failed_coup_main_country_fe` | 0.105549 | 0.11 | ±0.005 (printed_precision) | 0.890 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `failed_coup_affiliation_model` | 0.174175 | 0.17 | ±0.005 (printed_precision) | 0.835 | PASS |
| [seeded/pipeline-desktop-opus/20261102T062442Z](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `failed_coup_affiliation_model` | 0.174175 | 0.17 | ±0.005 (printed_precision) | 0.835 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `failed_coup_x_leaders_party` | -0.125832 | -0.13 | ±0.005 (printed_precision) | 0.834 | PASS |
| [seeded/pipeline-desktop-opus/20261102T062442Z](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `failed_coup_x_leaders_party` | -0.125832 | -0.13 | ±0.005 (printed_precision) | 0.834 | PASS |
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `failed_coup_base_leader_fe` | 0.083868 | 0.08 | ±0.005 (printed_precision) | 0.774 | PASS |
| [blind/pipeline-desktop-opus/20261102T060946Z](blind/pipeline-desktop-opus/20261102T060946Z/CELL.md) | `failed_coup_main_leader_fe` | 0.0669028 | 0.09 | ±0.03 (se_band) | 0.770 | PASS |
| [independent/pipeline-desktop-opus/20261102T062442Z](independent/pipeline-desktop-opus/20261102T062442Z/CELL.md) | `failed_coup_main_leader_fe` | 0.066903 | 0.09 | ±0.03 (se_band) | 0.770 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (11/11)
  - Country-level Stata xtreg, fe with i.YEAR_DATA translated to fixest::feols with panel and year fixed effects; Stata L. lags built by matching YEAR_DATA-1 within the xtset panel (COUNTRY_ID for Table A1, leader_cab_id for Table A2) on the full dataset before applying the democracy1==0 & independent==1 filter. fixest drops fixed-effect singletons (no effect on coefficients) and uses its own small-sample clustered SE correction, which differs slightly from Stata's xtreg.
  - Individual-level lfe::felm models translated to fixest::feols; the failed coup factor coupattempt_presentyear is coded as a 0/1 indicator (1 = 'Coup attempt'), equivalent to the factor dummy felm creates.
- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (11/11)
  - Individual-level lagged log population built from the country-year panel because the supplied pop_pwt_ln_lag column is identical to gdp_cap_pwt_ln_lag; lagged log GDP/cap also rebuilt the same way (matches the supplied GDP lag in 99.99% of rows).
  - H2a experience model sample: non-leader minister-years with non-missing importance tier (junior ministers kept). The paper text says juniors are excluded, but its reported N (90,020, vs 90,014 for the importance model, a gap of exactly the 6 'tier 0' rows) indicates they were kept.
  - Country-level autocracy filter uses democracy1 == 0 as stored (it reproduces the paper's 3,715 obs / 115 countries / 95 coups); lagging it again gives 3,745 obs / 117 countries.
  - Leader-FE models (Table A2): controls lagged within leader spells (panel set by leader_cab_id), which reproduces the paper's N of 3,332 (3,282 plus 50 singletons) and the monarchy dummy dropping as collinear.
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (11/11)
  - Individual-level data: the shipped pop_pwt_ln_lag column is an exact copy of gdp_cap_pwt_ln_lag (so fixest dropped it as collinear in attempt-3); the final script rebuilds lagged logged population from pop_pwt_ln (previous calendar year, within country).
  - Leader-FE country-level models (Table A2): lagged controls are taken within the leader spell (as with Stata L. after xtset on the leader id), so each leader's first year has no lagged controls. Chosen because the paper/task state that lagged monarchy is collinear with leader FE, which holds only under within-leader lags (with within-country lags it varies in 5 leader spells right after a monarchy ended). Country-FE models use within-country lags.
  - Autocracy filter at country level: lag of BMR democracy1 built within country (consecutive years), sample 1967-2016; the failed-coup variable coupattempt_whogov is taken as already July-aligned. Individual level uses democracy_lag == 0 and coupattempt_presentyear.
  - Experience model (H2a): excludes the leader and importance tier 0.5 (junior minister or other low-ranking post); rows with missing importance are kept; no experience polynomials (paper footnote 15). Importance model drops the 6 rows with importance code 0 (Governor General) not in the paper's tier list.
  - individual-level pop_pwt_ln_lag equals gdp_cap_pwt_ln_lag in the data; rebuilt from pop_pwt_ln lagged one year within country

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- seeded: `failed_coup_base_leader_fe` — pipeline 0/1, agent 1/1
- seeded: `failed_coup_main_leader_fe` — pipeline 0/1, agent 1/1
- blind: `failed_coup_affiliation_model` — pipeline 0/1, agent 1/1
- blind: `failed_coup_experience_model` — pipeline 0/1, agent 1/1
- blind: `failed_coup_importance_model` — pipeline 0/1, agent 1/1
- blind: `failed_coup_responsibility_model` — pipeline 0/1, agent 1/1
- blind: `failed_coup_x_leaders_party` — pipeline 0/1, agent 1/1
- blind: `failed_coup_x_natural_resources` — pipeline 0/1, agent 1/1
- blind: `failed_coup_x_over_6_years_experience` — pipeline 0/1, agent 1/1

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 7/11; executions 3; 2026-11-02T06:10:00Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T062442Z

[`seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 2; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 5; 2026-11-02T05:59:40Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T062442Z

[`independent/pipeline-desktop-opus/20261102T062442Z/CELL.md`](independent/pipeline-desktop-opus/20261102T062442Z/CELL.md) — final 11/11, re-scored 11/11; first scored 6/11; executions 3; 2026-11-02T06:24:42Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 5; 2026-11-02T06:01:00Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T060946Z

[`blind/pipeline-desktop-opus/20261102T060946Z/CELL.md`](blind/pipeline-desktop-opus/20261102T060946Z/CELL.md) — final 4/11, re-scored 4/11; first scored 4/11; executions 2; 2026-11-02T06:09:46Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

