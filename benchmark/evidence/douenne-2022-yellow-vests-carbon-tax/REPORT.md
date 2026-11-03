# Evidence report: douenne-2022-yellow-vests-carbon-tax

**Yellow Vests, Pessimistic Beliefs, and Carbon Tax Aversion** — Thomas Douenne, Adrien Fabre

- Paper: https://pure.uva.nl/ws/files/131576690/pol.20200092.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/275821/1/I4R-DP058.pdf
- I4R outcome label: not_reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/douenne-2022-yellow-vests-carbon-tax.yaml`
- Data access: public

> Headline findings (as published): French respondents, surveyed after the Yellow Vests protests, largely reject a carbon tax with a uniform dividend, overestimate their losses, think it regressive and doubt its effectiveness.  The customized win/lose feedback moves beliefs only modestly (Table 4: a regression discontinuity at zero estimated net gain; the effect is larger for those who initially accepted the tax and smaller for Yellow Vests supporters), while believing one does not lose (Table 6) or that the tax is effective (Table 8) raises support substantially.  DP58 (Rivers, Woerman & Yassin) confirms the average feedback effect, finds 56 misclassified treatment indicators (column 1 falls to 0.216 when fixed) and argues the column 3 heterogeneity is misspecified; it does not examine Tables 5-8.
> Original analysis in R 4.0.3 (stargazer tables; ivreg / ivmodel for diagnostics), with a Python 2.7 microsimulation upstream; language: r is the reproduction target.
> Curation pass (2026-11-02).  Pinned 13 claims: all of Table 4 (the table I4R examined: nine coefficients with SEs and the column (1) N, 757; column (2) N 1,968, the R2s and column (1)'s acceptance row in other columns are not pinned) and the two IV estimates the abstract rounds to "more than 50 p.p." and "more than 40 p.p." (Table 6 col 1, 0.534; Table 8 col 1, 0.416).  Values exactly as printed in the published AEJ:EP PDF.  Every Table 4 column (1) and (3) value equals the meta-database's o_coeff / o_std_err (0.269/0.058, 0.246/0.064, 0.015/0.087, 0.019/0.058, 0.166/0.079, -0.151/0.069, 0.080/0.079) and the package's tables/effect_feedback.tex.
> What was read.  The published PDF (all 32 pp. of the UvA copy: abstract, Sections III-IV, Tables 3-8); DP58 (19 pp., all tables); the 66 meta-database rows; the package README, tables/effect_feedback.tex, papier.R sections 4.1.2, 5.1 and 5.2; the object lists of both RData workspaces (R in the retally-sandbox-r image); GitHub API commit list and repository metadata; openICPSR 128143's public landing page.
> Package-only facts (never in contexts).  The analysis loads after_preparation.RData (data frame s, 3,002 rows).  Table 4 (papier.R lines 202-243): lm(gagnant_feedback_categorie != 'Perdant' ~ simule_gagnant + tax_acceptance + (taxe_approbation == 'NSP') + prog_na + Simule_gain + Simule_gain2 + taxe_efficace + single + hausse_depenses_par_uc + variables_demo + piecewise income percentiles of respondent and spouse with kinks at 20 and 70), data = s, subset = variante_taxe_info == 'f' & abs(simule_gain) < 50 (column 2 drops the gain restriction), weights = s$weight (survey weights; the paper never mentions them in Table 4).  Column 3 adds (gagnant_categorie != 'Perdant') * simule_gagnant + simule_gagnant * gj + simule_gagnant * tax_acceptance; column 4's outcome is gagnant_feedback_categorie == 'Gagnant'.  simule_gagnant is the feedback actually shown; simule_gain the estimated net gain (DP58's misclassification is simule_gagnant != (simule_gain > 0) for 56 rows).  Table 6 col 1 (lines 264-282): a hand-rolled 2SLS — first stage lm(gagnant_cible_categorie != 'Perdant' ~ traite_cible * traite_cible_conjoint + cible + ...), second stage lm(taxe_cible_approbation != 'Non' ~ ... + non_perdant) on the fitted values, subset to respondent or spouse in income percentiles 10-60, weighted; the printed SE is the uncorrected second-stage OLS SE.  Table 8 col 1 (lines 365-375): first stage lm(taxe_efficace == 'Oui' ~ variables_reg_ee + apres_modifs + info_CC), second stage lm(taxe_approbation == 'Oui' ~ variables_reg_ee + taxe_efficace.hat), weighted, again with uncorrected SEs (the ivreg used for the effective F is unweighted).  variables_reg_ee uses Revenu / Revenu2 / spouse income quadratics and gagnant_categorie instead of the piecewise percentiles.
> Benchmark implications.  An independent run must recover the survey weights, the |estimated gain| < 50 window among feedback recipients and the long control list; the window and the feedback indicator are in the processed data, so the printed Table 4 values are reachable, and a run that rebuilds the indicator from the sign of the estimated net gain will land near DP58's corrected values instead.  A proper 2SLS for Tables 6 and 8 reproduces the coefficients but not the printed SEs, which are second-stage OLS SEs.
> Blind-mode caveat.  The paper's prose rounds several pinned values: "27 p.p." (Table 4 col 1), "15 p.p." (col 4), "from 27 p.p. to 41 p.p." and "less than 10 p.p." (col 3 combinations), "53 p.p." (Table 6 col 1) and "42 p.p." (Table 8 col 1).  The value-matching redactor may not catch percentage-point forms, so a blind run can see these to two digits.
> Mount caveat.  after_preparation.RData (kept: it is the processed data the analysis and DP58 use) carries the source of preparation.R's functions as srcrefs; the analysis script papier.R is not in it. after_papier.RData (withheld) held the formulas and stargazer tables.
> Left out.  Tables 1-3 and 5 (descriptive / first stages), Table 6 cols 2-4 and Table 8 cols 2-3 (robustness), the appendix tables, and DP58's rdrobust and placebo estimates.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `predicted_winner_believes_not_lose_table4_col1` | 0.269 | 0.058 | Table 4, column (1), Predicted winner | 0.216 | does_not_match |
| 1 | `initial_acceptance_believes_not_lose_table4_col1` | 0.306 | 0.066 | Table 4, column (1), Initial tax acceptance | — | — |
| 2 | `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.208 | 0.035 | Table 4, column (2), Predicted winner | — | — |
| 3 | `predicted_winner_heterogeneity_table4_col3` | 0.246 | 0.064 | Table 4, column (3), Predicted winner | 0.256 | matches |
| 4 | `initial_acceptance_heterogeneity_table4_col3` | 0.015 | 0.087 | Table 4, column (3), Initial tax acceptance | 0.061 | does_not_match |
| 5 | `yellow_vests_supporter_heterogeneity_table4_col3` | 0.019 | 0.058 | Table 4, column (3), Yellow Vests supporter | 0.013 | matches |
| 6 | `winner_x_initial_acceptance_table4_col3` | 0.166 | 0.079 | Table 4, column (3), Predicted winner x Initial tax acceptance | 0.15 | does_not_match |
| 7 | `winner_x_yellow_vests_supporter_table4_col3` | -0.151 | 0.069 | Table 4, column (3), Predicted winner x Yellow Vests supporter | -0.162 | does_not_match |
| 8 | `winner_x_initial_win_belief_table4_col3` | 0.08 | 0.079 | Table 4, column (3), Predicted winner x G | 0.084 | matches |
| 9 | `predicted_winner_believes_wins_table4_col4` | 0.153 | 0.045 | Table 4, column (4), Predicted winner | — | — |
| 10 | `n_obs_table4_col1` | 757 | — | Table 4, column (1), Observations | 757 | matches |
| 11 | `believes_not_lose_on_acceptance_iv_table6_col1` | 0.534 | 0.132 | Table 6, column (1), Believes does not lose | — | — |
| 12 | `believes_effective_on_approval_iv_table8_col1` | 0.416 | 0.168 | Table 8, column (1), Believes in effectiveness | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[13/13](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [12/13](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[12/13](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[13/13](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c)<br>[13/13](blind/claude-code/2026-11-03-a/CELL.md) (2026-11-03-a) |
| `pipeline-desktop-opus` | [5/13](seeded/pipeline-desktop-opus/20261102T144245Z/CELL.md) (20261102T144245Z) | [13/13](independent/pipeline-desktop-opus/20261102T143152Z/CELL.md) (20261102T143152Z) | [12/13](blind/pipeline-desktop-opus/20261102T142733Z/CELL.md) (20261102T142733Z) |
| `pipeline-desktop-opus-postfix` | — | [12/13](independent/pipeline-desktop-opus-postfix/20261103T104817Z/CELL.md) (20261103T104817Z) | [13/13](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) (20261103T064954Z) |
| `pipeline-desktop-opus-run2` | [6/13](seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md) (20261102T191457Z) | [13/13](independent/pipeline-desktop-opus-run2/20261102T153300Z/CELL.md) (20261102T153300Z) | [13/13](blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) (20261102T152052Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md) (20261103T050517Z) | [13/13](independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [13/13](blind/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md) (20261103T050517Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) | `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.2408 | 0.208 | ±0.035 (se_band) | 0.937 | PASS |
| [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) | `initial_acceptance_believes_not_lose_table4_col1` | 0.246483 | 0.306 | ±0.066 (se_band) | 0.902 | PASS |
| [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) | `winner_x_initial_win_belief_table4_col3` | 0.15118 | 0.08 | ±0.079 (se_band) | 0.901 | PASS |
| [seeded/pipeline-desktop-opus/20261102T144245Z](seeded/pipeline-desktop-opus/20261102T144245Z/CELL.md) | `predicted_winner_believes_wins_table4_col4` | 0.149585 | 0.153 | ±0.00306 (relative) | 1.116 | FAIL |
| [seeded/pipeline-desktop-opus-run2/20261102T191457Z](seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md) | `predicted_winner_believes_wins_table4_col4` | 0.149585 | 0.153 | ±0.00306 (relative) | 1.116 | FAIL |
| [blind/claude-code/2026-11-02-b](blind/claude-code/2026-11-02-b/CELL.md) | `initial_acceptance_believes_not_lose_table4_col1` | 0.231724 | 0.306 | ±0.066 (se_band) | 1.125 | FAIL |
| [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) | `winner_x_initial_win_belief_table4_col3` | 0.148682 | 0.08 | ±0.079 (se_band) | 0.869 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261102T191457Z](seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md) | `predicted_winner_heterogeneity_table4_col3` | 0.241792 | 0.246 | ±0.00492 (relative) | 0.855 | PASS |
| [blind/pipeline-desktop-opus-postfix/20261103T064954Z](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) | `predicted_winner_believes_not_lose_full_sample_table4_col2` | 0.237676 | 0.208 | ±0.035 (se_band) | 0.848 | PASS |
| [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) | `winner_x_initial_win_belief_table4_col3` | 0.146722 | 0.08 | ±0.079 (se_band) | 0.845 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Hmisc/memisc 'labelled'/'.item' column classes were stripped to plain vectors (memisc is not installed); numeric memisc items such as diplome4 and taille_agglo therefore enter as numeric regressors.
- [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) (13/13)
  - memisc is not installed in the sandbox, so memisc 'item' columns (e.g. taxe_approbation, taxe_efficace, gilets_jaunes, diplome4, taille_agglo) and Hmisc 'labelled' classes were stripped to their underlying values: character items enter lm as factors, double items as numeric, and no values are recoded as missing. With this, the Table 4 column 1 sample is 757, the same as the paper.
  - The control-variable vectors (variables_reg_effect_feedback, variables_reg_self_interest, variables_reg_ee) are taken from after_papier.RData, where papier.R stored them; the data frame s comes from after_preparation.RData, as papier.R loads it.
- [seeded/pipeline-desktop-opus-run2/20261102T191457Z](seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md) (6/13; failed: `initial_acceptance_heterogeneity_table4_col3`, `yellow_vests_supporter_heterogeneity_table4_col3`, `winner_x_initial_acceptance_table4_col3`, `winner_x_yellow_vests_supporter_table4_col3`, `winner_x_initial_win_belief_table4_col3`, `predicted_winner_believes_wins_table4_col4`, `believes_effective_on_approval_iv_table8_col1`)
  - Yellow Vests supporter dummy defined as "supports" or "is part of" the movement; exact definition not given in the provided text
- [independent/claude-code/2026-11-02-a](independent/claude-code/2026-11-02-a/CELL.md) (13/13)
  - Online-appendix control list unavailable; controls reconstructed from variable names: incomes = continuous piecewise-linear in both adults' income percentiles (kinks at 20 and 70); estimated gains = simule_gain and its square; sociodemographics = sex, age brackets, employment status, socio-professional category, region, education (4), town size, number of adults, household size, number aged 14+, smoker, main news source.
  - Other motives: Table 4 uses the progressivity belief (prog_na, with not-asked as a category); Table 6 uses effectiveness (Oui/Non/NSP) and progressivity beliefs; Table 8 uses the initial win/lose category (progressivity omitted because it was asked only of the apres_modifs half, collinear with the effectiveness-information instrument).
  - Effectiveness-information instrument Z_E identified as apres_modifs (second half of sample received the effectiveness info, per its variable label); Z_CC = info_CC.
  - Regressions unweighted, heteroskedasticity-robust SEs (fixest, hetero); the paper does not state regression weights.
  - Table 6 col 1 subsample: respondent or second-adult income percentile in [10, 60] (N = 1969, matches); Table 6 policy fixed effects from cible; Table 6 instruments traite_cible, traite_cible_conjoint and interaction.
- [independent/claude-code/2026-11-02-b](independent/claude-code/2026-11-02-b/CELL.md) (13/13)
  - The online-appendix list of controls is not available; controls were reconstructed: sociodemographics = sex, age bracket, education (4), town size (5), socio-professional category, region, household size, number aged 14+, number of adults; incomes = continuous piecewise-linear income percentiles of respondent and second adult (kinks at p20, p70; second-adult terms zeroed for singles) plus single dummy; estimated gains = simule_gain and its square; other motives = belief in environmental effectiveness (Tables 4 and 6) or initial win/lose category (Table 8). Progressivity beliefs were not used (asked only to the second half of the sample, collinear with the effectiveness-information instrument).
  - All regressions weighted by the survey weight; heteroskedasticity-robust SEs (coefficients only are scored).
  - Table 6 subsample [p10;p60]: respondent's own percentile in [10,60] or (non-single) second adult's percentile in [10,60]; N = 1961 vs 1969 in the paper.
  - Info on environmental effectiveness (Z_E) taken as apres_modifs (second-half sample that saw the effectiveness information); Z_CC = info_CC.
  - Table 4 R2 is lower than the paper's (0.267 vs 0.301 in col 1), suggesting the paper's control set is larger.
- [independent/claude-code/2026-11-02-c](independent/claude-code/2026-11-02-c/CELL.md) (13/13)
  - The paper's full control list is in the online appendix, which is not available; controls were reconstructed: incomes = respondent and second-adult income percentiles with kinks at the 20th and 70th percentiles (p, min(p-20,0), min(p-70,0)); estimated gains = simule_gain and its square; sociodemographics = sex, age bracket, socio-professional category, education (4), town size, region, consumption units, number aged 14+, smoker, main news source; other motives = belief the tax is effective (not 'No') in Tables 4 and 6, and the initial win/lose category in Table 8.
  - All regressions use the survey weights (weight) and heteroskedasticity-robust SEs.
  - Table 6 subsample built as respondent percentile in [10,60] or (more than one adult and second-adult percentile in [10,60]); this gives 1,961 observations versus 1,969 in the paper.
  - Effectiveness information treatment Z_E identified as the apres_modifs indicator (the random half-split whose first-stage effect on believing in effectiveness is about 6 p.p.).
- [independent/pipeline-desktop-opus/20261102T143152Z](independent/pipeline-desktop-opus/20261102T143152Z/CELL.md) (13/13)
  - Table 4 col. 1 drops effectiveness/progressivity belief controls (control list not given in provided text)
- [independent/pipeline-desktop-opus-postfix/20261103T104817Z](independent/pipeline-desktop-opus-postfix/20261103T104817Z/CELL.md) (12/13; failed: `believes_effective_on_approval_iv_table8_col1`)
  - winning_feedback_category has codes 1,2,3 without usable labels; mapping lowest->winner, middle->unaffected, highest->loser (factor levels Gagnant < Non affecte < Perdant)
  - winning_category has codes 1,2,3 without usable labels; mapping lowest->winner, middle->unaffected, highest->loser (factor levels Gagnant < Non affecte < Perdant)
  - using gagnant_cible_categorie instead of win_cible_category for targeted winner category
  - Table 8 endogenous belief coded as 'does not believe the tax is ineffective' (not No) and instrumented by the scientists-agree information and the climate-change information only
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (12/13; failed: `initial_acceptance_believes_not_lose_table4_col1`)
  - The online-appendix control lists are unavailable. Controls were rebuilt from the data. Sociodemographics: sex, age bracket, employment status, CSP, education (4 levels), agglomeration size, region, household size, number aged 14+, left-right placement, smoker, main news source. Other motives: belief in environmental effectiveness and in progressivity. Incomes: continuous piecewise-linear terms in both adults' income percentiles with kinks at p20 and p70. Estimated gains: quadratic in the estimated net gain per consumption unit.
  - Estimated net gain = simule_gain (EUR/yr per consumption unit). Predicted winner = simule_gagnant, the displayed feedback; it differs from 1{simule_gain>0} for 56 respondents, 52 of them inside the \|gain\|<50 band.
  - Table 8: the progressivity belief is left out of the other-motive controls. It was only elicited in the survey wave that also received the effectiveness information (apres_modifs), so it is collinear with the instrument. The other-motive control there is the initial win/lose category.
  - Yellow Vests supporter = Gilets_jaunes in {soutient, est_dedans}. The initial win/lose belief G = initial category not 'Loser'. Column 3 also controls for the 3-level initial category.
  - Table 6 col 1 subsample = at least one adult's income percentile in [10,60] (both percentile variables as provided; 1,969 respondents). Eligibility instruments are traite_cible, traite_cible_conjoint and their product. Controls add policy-threshold fixed effects, a single-adult indicator and initial acceptance.
  - Table 8 instruments: apres_modifs = info on the scientific consensus about effectiveness (identified by its effect on the effectiveness belief) and info_CC. Strict definitions: approval = 'Oui', effective = 'Oui'.
  - Heteroskedasticity-robust standard errors (coefficients do not depend on this).
  - control lists (online appendix) unavailable; sociodemo/other-motive/income controls reconstructed from variable names; heteroskedasticity-robust SEs.
  - Table 8 other-motive controls = initial win/lose category only (progressivity belief omitted: its missingness coincides with the E.E. information wave, collinear with the instrument).
- [blind/claude-code/2026-11-02-b](blind/claude-code/2026-11-02-b/CELL.md) (12/13; failed: `initial_acceptance_believes_not_lose_table4_col1`)
  - The paper's control lists are in the online Appendix, which is not available. Controls were constructed as: incomes = respondent and second-adult income percentiles with kinks at the 20th and 70th percentiles (min(I-20,0), min(I-70,0)); estimated gains = simule_gain and its square; sociodemo = sex, age group, employment status, socio-professional category, region, diploma (4 levels), agglomeration size, household size, number of members aged 14+; other motives = belief in environmental effectiveness (taxe_efficace, 3 levels) and progressivity belief (prog_na, including the not-asked category).
  - Table 8: the information on the scientific consensus about effectiveness (Z_E) has no dedicated variable; apres_modifs (listed among the dataset's random-treatment variables, the post-modification survey wave) was used as Z_E. Because the progressivity question exists only in that wave, progressivity was left out of the Table 8 controls (it would be collinear with Z_E); there other motives = initial win/lose category.
  - Predicted winner = simule_gagnant (the feedback actually shown); estimated net gain = simule_gain (EUR/year). Yellow Vests supporter = gilets_jaunes >= 1 (supports or is part of). Table 4 col. 3 adds the initial win/lose category as a factor plus winner interactions with initial acceptance, Yellow Vests support and initial not-lose belief.
  - Table 6 col. 1 sample: respondent or second-adult income percentile in [10, 60] (percentile_revenu_conjoint used as stored). Eligibility instruments = traite_cible, traite_cible_conjoint and their product; controls include policy-assigned (cible) fixed effects, single-adult dummy and initial acceptance.
  - All regressions unweighted OLS/2SLS (fixest), heteroskedasticity-robust SEs (SEs not scored).
- [blind/claude-code/2026-11-02-c](blind/claude-code/2026-11-02-c/CELL.md) (13/13)
  - The online-appendix control lists are not available; controls were constructed from the paper's description: socio-demographics (sex, age bracket, employment status, occupation, region, education, household size, number aged 14+, number of adults, smoker, news source, urban-area size, consumption units, following the dataset's variables_demo list minus income variables); incomes as a continuous piecewise-linear function of the respondent's and second adult's income percentiles with kinks at p20 and p70 (eq. 4); estimated gains as simule_gain and its square; other motives as belief in environmental effectiveness (Yes/No/PNR) and perceived progressivity (prog_not_no) in Tables 4 and 6, and initial win/lose category in Table 8.
  - Table 8: the progressivity control was dropped because that question was asked only in the second half of the sample (apres_modifs), the same indicator as the effectiveness-information instrument, so it is mechanically zero in the instrument's control group (bad control). This change was made after attempt-5, whose first stage on this instrument was nearly absent (F about 2.3); Tables 4 and 6 were left unchanged.
  - Yellow Vests supporter = gilets_jaunes > 0 (is part of or supports the movement). Predicted winner = simule_gagnant (the feedback actually shown); running variable = simule_gain (EUR/yr per c.u.). Initial win/lose belief G = initial category not 'Perdant'; column 3 also controls for the 3-level initial category.
  - Table 6 [p10;p60] subsample: respondent percentile in [10,60], or a second adult (nb_adultes > 1) whose percentile is in [10,60]. Unweighted OLS/2SLS (fixest), heteroskedasticity-robust SEs (point estimates do not depend on this).
  - memisc is not installed, so the labelled/memisc item columns were turned into plain vectors by stripping their attributes. No author functions stored in the RData were called.
- [blind/claude-code/2026-11-03-a](blind/claude-code/2026-11-03-a/CELL.md) (13/13)
  - The paper's full control lists are in the online Appendix, which is not available. Controls were constructed as: sociodemographics = sex, age bracket, socio-professional category, education (4 levels), town size, region (factors), household size, number of members aged 14+; incomes = continuous piecewise-linear in income percentiles of respondent and second adult with kinks at p20 and p70 (paper eq. 4); estimated gains = simule_gain and its square; other motives = belief the tax is effective (not 'No') and belief it is progressive (prog_not_no). For Table 8 the other motives are progressivity belief and initial belief of not losing (effectiveness is the endogenous variable).
  - All regressions use the survey weights (variable weight), since the paper states observations are weighted; heteroskedasticity-robust SEs.
  - Predicted winner = simule_gagnant (the feedback actually displayed); running variable = simule_gain (estimated net gain per consumption unit); feedback sample = variante_taxe_info == 'f' (1,968). simule_gagnant disagrees with sign(simule_gain) for 56 respondents; used as is.
  - Yellow Vests supporter = gilets_jaunes_soutien or gilets_jaunes_dedans. Table 4 col 3 controls for the 3-category initial win/lose belief (factor) and interacts the predicted-winner indicator with the binary initial not-lose belief.
  - Table 6 col 1 subsample: respondent's or second adult's income percentile in [10, 60] (1,969 obs); instruments traite_cible, traite_cible_conjoint and their product; fixed effects for the assigned target (cible); controls single, initial acceptance, incomes, estimated gains, sociodemo, other motives.
  - Table 8 col 1: info on effectiveness identified as apres_modifs (its label says the second half of the sample received the information on effectiveness against pollution); info on climate change = info_CC.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- seeded: `believes_effective_on_approval_iv_table8_col1` — pipeline 1/3, agent 2/2
- seeded: `initial_acceptance_heterogeneity_table4_col3` — pipeline 1/3, agent 2/2
- seeded: `predicted_winner_believes_wins_table4_col4` — pipeline 1/3, agent 2/2
- seeded: `winner_x_initial_acceptance_table4_col3` — pipeline 1/3, agent 2/2
- seeded: `winner_x_initial_win_belief_table4_col3` — pipeline 1/3, agent 2/2
- seeded: `winner_x_yellow_vests_supporter_table4_col3` — pipeline 1/3, agent 2/2
- seeded: `yellow_vests_supporter_heterogeneity_table4_col3` — pipeline 1/3, agent 2/2
- blind: `initial_acceptance_believes_not_lose_table4_col1` — pipeline 4/4, agent 2/4

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-02T10:08:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 5; 2026-11-02T19:52:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T144245Z

[`seeded/pipeline-desktop-opus/20261102T144245Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T144245Z/CELL.md) — final 5/13, re-scored 5/13; first scored 5/13; executions 5; 2026-11-02T14:42:45Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T191457Z

[`seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T191457Z/CELL.md) — final 6/13, re-scored 6/13; first scored 5/13; executions 5; 2026-11-02T19:14:57Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T050517Z

[`seeded/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-03T05:05:17Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 7; 2026-11-02T14:17:30Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 6; 2026-11-02T15:01:00Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 6; 2026-11-02T20:09:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T143152Z

[`independent/pipeline-desktop-opus/20261102T143152Z/CELL.md`](independent/pipeline-desktop-opus/20261102T143152Z/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 3; 2026-11-02T14:31:52Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T104817Z

[`independent/pipeline-desktop-opus-postfix/20261103T104817Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T104817Z/CELL.md) — final 12/13, re-scored 12/13; first scored 3/13; executions 7; 2026-11-03T10:48:17Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T153300Z

[`independent/pipeline-desktop-opus-run2/20261102T153300Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T153300Z/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 3; 2026-11-02T15:33:00Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T010557Z

[`independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 7; 2026-11-02T14:17:00Z; from `claude-code-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 10; 2026-11-02T15:09:30Z; from `claude-code-run2-6papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 6; 2026-11-02T20:26:30Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-03-a

[`blind/claude-code/2026-11-03-a/CELL.md`](blind/claude-code/2026-11-03-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 7; 2026-11-03T00:16:00Z; from `claude-code-run4-redaction-3papers-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T142733Z

[`blind/pipeline-desktop-opus/20261102T142733Z/CELL.md`](blind/pipeline-desktop-opus/20261102T142733Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-02T14:27:33Z; from `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T064954Z

[`blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T064954Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-03T06:49:54Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T152052Z

[`blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T152052Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T15:20:52Z; from `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T050517Z

[`blind/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T050517Z/CELL.md) — final 13/13, re-scored 13/13; first scored 4/13; executions 3; 2026-11-03T05:05:17Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

