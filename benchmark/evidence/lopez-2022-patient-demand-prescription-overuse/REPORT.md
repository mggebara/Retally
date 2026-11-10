# Evidence report: lopez-2022-patient-demand-prescription-overuse

**Does Patient Demand Contribute to the Overuse of Prescription Drugs?** — Carolina Lopez, Anja Sautmann, Simone Schaner

- Paper: https://documents1.worldbank.org/curated/en/780321606314613926/pdf/Does-Patient-Demand-Contribute-to-the-Overuse-of-Prescription-Drugs.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/lopez-2022-patient-demand-prescription-overuse.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T23/126722-V1.zip`; AEA Data and Code Repository on openICPSR, project 126722, version V1 (doi:10.3886/E126722V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T23/126722-V1.zip (24,908,445 bytes, md5 ad52d4e4b8fa1d6e28f305feca4989c5; SOURCE.txt beside it).  V1 is the only version.  71 entries (61 files, 72,933,936 bytes uncompressed, all deflate), no nested archives, all under Lopez_Sautmann_Schaner_2020/: 1_README.pdf (5 pp., January 2021; data sources, software (Stata 13.1+, pdslasso, rlasso, estout, coefplot, grc1leg), run time about 3 h 20 min, file-to-table map, no estimates); Data/ with three Stata .dta files — LSS_analysis_datasets_20201108.dta (56 MB, the patient-level analysis file for Tables 2-5 and the appendix regressions), LSS_CSComCensus.dta (clinic census) and LSS_DoctorEndlineInterview.dta (provider endline) — and an empty Data/_bootstrap/; Do_Files/ with 18 Stata do-files (LSS_master_data_analysis.do, "Stata admin files"/ with the table programs, package installer and bootstrap sampler, Tables/ and Figures/ subfolders); Tables/ with 22 generated .tex tables (every main and appendix table, esttab-style) and two LaTeX wrappers (LSS_Main_Replication.tex, LSS_Appendix_Replication.tex) that \input them, with no compiled PDF; Figures/ with 9 figure PDFs (two non-empirical diagrams and the lpoly / bar plots, axis labels only); "Survey Instruments"/ with 6 questionnaire PDFs (patient interview 176 pp., home follow-up 96 pp., doctor endline, clinic census in French, morning clinic ID, intervention notes).  Raw data are on the J-PAL Dataverse (doi:10.7910/DVN/CLGN7Z, guestbook; not needed).  The script-free copy (independent / blind) withholds 36 files (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09): the 18 .do files by suffix and 18 .tex tables by content as regression tables (Tables 2-5 and B3-B16, including Table 3). Kept: the README, the data, the figure and questionnaire PDFs, the two wrappers and four descriptive .tex tables (1_control_group, A1_theory_table, B1_clinic_census, B2_means_doctor), none of which prints a pinned value or SE (text of every kept PDF and .tex grepped, 2026-11-09).  Project page: https://www.openicpsr.org/openicpsr/project/126722/version/V1/view)

> Headline findings (Table 3): on Patient Voucher days voucher use was 0.35 (0.030) higher than on Control days, against 0.26 (0.024) on Doctor Voucher days (the abstract's "35 percent" is the 9-point gap relative to the Doctor Voucher level, not the coefficient); any malaria treatment prescribed 0.052 (0.025) PV vs 0.016 (0.025) DV, purchased 0.14 (0.027) vs 0.085 (0.025); severe malaria treatment prescribed -0.046 (0.018) vs -0.054 (0.021), purchased -0.022 (0.020) vs -0.050 (0.019).  N 2,055 in column 1, 2,053 in columns 2-5.
> Paper text and how it was verified.  No open copy of the published article was found; the catalog source is World Bank PRWP 9482 (November 2020).  Its Table 3 is identical to the published Table 3 in every cell the I4R meta-database records for "table 3": the 10 coefficient / SE pairs 0.35/0.030, 0.26/0.024, 0.052/0.025, 0.016/0.025, 0.14/0.027, 0.085/0.025, -0.046/0.018, -0.054/0.021, -0.022/0.020, -0.050/0.019 equal o_coeff_dbl / o_std_err_dbl, and the 5 "difference in means" rows without SE (0.090, 0.036, 0.055, 0.008, 0.028) equal beta_P - beta_D in each WP column.  The other 15 rows are "table b8" (online Appendix Table B8, no additional controls; 0.35/0.031, 0.27/0.025, 0.067/0.027, 0.023/0.026, 0.15/0.031, 0.092/0.027, -0.033/0.019, -0.058/0.023, -0.011/0.021, -0.051/0.020 and five differences); the WP carries no appendix, which is why 9 of the 30 paired values do not occur in it (the B8 values that do occur in the WP are tokens of other cells, not B8).  The published online appendix (https://aeaweb.org/content/file?id=15897, open, dated January 22, 2021, 30 pp.) prints B8 exactly as the meta-database, with the N row 2055 / 2053 and the control means of Table 3, so B8 is the published appendix and the published Table 3 sample is the WP's.  The package's generated Tables/3_mal_tmt_overall_new_lso.tex is cell-for-cell the WP's Table 3 (N row included), and its Tables 4 and 5 equal the WP's Tables 4 and 5; but no published value of Tables 4 or 5 is recorded anywhere open, so they are not pinned.  The N claims are not in the meta-database; they are pinned from the WP Table 3 / package table and the published appendix's identical N rows.  The NBER WP 25284 (2018) prints a different Table 3 (fixed controls instead of lasso) and was not used.
> Curation pass (2026-11-09).  12 claims.  Left out: the beta_P = beta_D p-values and mechanism rows, the control-group means (descriptive), Tables 1-2 (descriptive and balance), Table 4 (heterogeneity by predicted malaria risk, bootstrapped SEs with a generated regressor) and Table 5 (expected match), neither verifiable against a published value, and all appendix tables.
> Package-only facts (never in contexts).  LSS_master_data_analysis.do, "TABLE 3": use LSS_analysis_datasets_20201108.dta, drop if dropme==1; outcomes used_vouchers_admin, RXtreat_sev_simple_mal, treat_sev_simple_mal, RXtreat_severe_mal, treat_severe_mal; program docpat_theory_lso ("Stata admin files"/LSS_TablePrograms.do) runs pdslasso <y> patient_voucher doctor_voucher (DD1-DD35 CL1-CL59 CC*), clu(cscomnum) partial(DD1-DD35) — date dummies DD* partialled out (always kept), clinic dummies CL* and the prepared patient-control block CC* (levels, squares, interactions, missing dummies) eligible for selection; then test patient_voucher = doctor_voucher.  README: Stata/MP 14.0, about 3 h 20 min for the whole master file (most of it the bootstrap sets for Table 4 and B9/B11, which Table 3 does not need).
> Blind-mode exposure (step 6, 2026-11-09).  The blind generation prompt states no pinned value or SE at printed precision or rounded, and no script text (the one hit, "cscomnum", is a data column name in the listing).  Its "abstract" is the World Bank series boilerplate (the parser takes the cover line "Policy Research Working Paper" as the title), so the paper's own abstract ("increased discount use by 35 percent", a ratio of the voucher-use gap to the Doctor Voucher level) does not reach it.  The paper text given to the methodology summariser does carry that abstract, the interview count that is the column (1) N ("we completed 2,055 interviews"), and Section 4.2's percentage-point statements of three Table 3 estimates; the summariser is told to leave results out, and the README's blind-mode caveat covers this.  The R sandbox has no lasso package (no glmnet or hdm), so a reproduction must code the double-selection lasso by hand or approximate it.
> What was read.  WP 9482 pp. 1-29 and Tables 1-5 (pp. 46-53); NBER WP 25284 Tables 3-5; the published online appendix Tables B8 and B10; the 31 meta-database rows; the package README, the Table 3 block of the master do-file and the docpat_theory_lso program; the strip-rule classification of the extracted package and the text of every kept PDF and .tex.
> What could not be verified.  The published article itself (its Table 3 notes and wording) was not read.  The authors' Stata code was not run (no Stata here) and no R cross-check of the lasso specification was made; an R reproduction must approximate pdslasso (rlasso with cluster-robust penalty loadings) without a lasso package, so selected controls may differ.
> Original analysis in Stata 14 (pdslasso, rlasso, estout); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `voucher_used_patient_voucher_table3_col1` | 0.35 | 0.03 | Table 3, column (1) Used Voucher, beta_P: Patient Voucher | 0.35 | matches |
| 1 | `voucher_used_doctor_voucher_table3_col1` | 0.26 | 0.024 | Table 3, column (1) Used Voucher, beta_D: Doctor Voucher | 0.26 | matches |
| 2 | `any_malaria_treatment_prescribed_patient_voucher_table3_col2` | 0.052 | 0.025 | Table 3, column (2) Any Malaria Treatment, Prescribed, beta_P: Patient Voucher | 0.052 | matches |
| 3 | `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.016 | 0.025 | Table 3, column (2) Any Malaria Treatment, Prescribed, beta_D: Doctor Voucher | 0.016 | matches |
| 4 | `any_malaria_treatment_purchased_patient_voucher_table3_col3` | 0.14 | 0.027 | Table 3, column (3) Any Malaria Treatment, Purchased, beta_P: Patient Voucher | 0.14 | matches |
| 5 | `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.085 | 0.025 | Table 3, column (3) Any Malaria Treatment, Purchased, beta_D: Doctor Voucher | 0.085 | matches |
| 6 | `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.046 | 0.018 | Table 3, column (4) Severe Malaria Treatment, Prescribed, beta_P: Patient Voucher | -0.046 | matches |
| 7 | `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.054 | 0.021 | Table 3, column (4) Severe Malaria Treatment, Prescribed, beta_D: Doctor Voucher | -0.054 | matches |
| 8 | `severe_malaria_treatment_purchased_patient_voucher_table3_col5` | -0.022 | 0.02 | Table 3, column (5) Severe Malaria Treatment, Purchased, beta_P: Patient Voucher | -0.022 | matches |
| 9 | `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` | -0.05 | 0.019 | Table 3, column (5) Severe Malaria Treatment, Purchased, beta_D: Doctor Voucher | -0.05 | matches |
| 10 | `n_obs_table3_col1` | 2055 | — | Table 3, N, column (1) | — | — |
| 11 | `n_obs_table3_cols2_5` | 2053 | — | Table 3, N, columns (2)-(5) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[11/12](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [12/12](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/12](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[12/12](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/12](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [8/12](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[8/12](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[8/12](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/12](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261110T112214Z/CELL.md) (20261110T112214Z) | [12/12](independent/pipeline-desktop-opus/20261110T065707Z/CELL.md) (20261110T065707Z) | [0/12](blind/pipeline-desktop-opus/20261110T064634Z/CELL.md) (20261110T064634Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261110T142949Z/CELL.md) (20261110T142949Z) | [12/12](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) (20261110T142213Z) | [3/12](blind/pipeline-desktop-opus-run2/20261110T070059Z/CELL.md) (20261110T070059Z) |
| `pipeline-desktop-opus-run3` | [12/12](seeded/pipeline-desktop-opus-run3/20261110T113744Z/CELL.md) (20261110T113744Z) | [12/12](independent/pipeline-desktop-opus-run3/20261110T113422Z/CELL.md) (20261110T113422Z) | [3/12](blind/pipeline-desktop-opus-run3/20261110T070123Z/CELL.md) (20261110T070123Z) |
| `pipeline-desktop-opus-run4` | — | [4/12](independent/pipeline-desktop-opus-run4/20261110T112343Z/CELL.md) (20261110T112343Z) | [2/12](blind/pipeline-desktop-opus-run4/20261110T065844Z/CELL.md) (20261110T065844Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus-run2/20261110T142213Z](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) | `voucher_used_patient_voucher_table3_col1` | 0.322293 | 0.35 | ±0.03 (se_band) | 0.924 | PASS |
| [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) | `voucher_used_doctor_voucher_table3_col1` | 0.264222 | 0.26 | ±0.0052 (relative) | 0.812 | PASS |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `voucher_used_doctor_voucher_table3_col1` | 0.264222 | 0.26 | ±0.0052 (relative) | 0.812 | PASS |
| [seeded/pipeline-desktop-opus/20261110T112214Z](seeded/pipeline-desktop-opus/20261110T112214Z/CELL.md) | `voucher_used_doctor_voucher_table3_col1` | 0.264222 | 0.26 | ±0.0052 (relative) | 0.812 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261110T142949Z](seeded/pipeline-desktop-opus-run2/20261110T142949Z/CELL.md) | `voucher_used_doctor_voucher_table3_col1` | 0.264222 | 0.26 | ±0.0052 (relative) | 0.812 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261110T113744Z](seeded/pipeline-desktop-opus-run3/20261110T113744Z/CELL.md) | `voucher_used_doctor_voucher_table3_col1` | 0.264222 | 0.26 | ±0.0052 (relative) | 0.812 | PASS |
| [independent/pipeline-desktop-opus-run2/20261110T142213Z](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) | `any_malaria_treatment_purchased_doctor_voucher_table3_col3` | 0.105211 | 0.085 | ±0.025 (se_band) | 0.808 | PASS |
| [independent/pipeline-desktop-opus-run2/20261110T142213Z](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) | `any_malaria_treatment_prescribed_doctor_voucher_table3_col2` | 0.0358746 | 0.016 | ±0.025 (se_band) | 0.795 | PASS |
| [blind/pipeline-desktop-opus-run3/20261110T070123Z](blind/pipeline-desktop-opus-run3/20261110T070123Z/CELL.md) | `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` | -0.0276247 | -0.054 | ±0.021 (se_band) | 1.256 | FAIL |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` | -0.044843 | -0.046 | ±0.00092 (relative) | 1.258 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) (12/12)
  - Stata's pdslasso/rlasso (lassopack) is not available in R (glmnet not installed either), so the rigorous cluster-robust lasso was re-implemented by hand: lassopack defaults c=1.1, gamma=0.1/log(number of clusters), lambda=2c*sqrt(N)*invnormal(1-gamma/(2p)), cluster-robust penalty loadings, initial residuals from OLS on the 5 most correlated regressors, 2 loading iterations with post-lasso residuals, date dummies and constant partialled out before selection; final post-double-selection OLS via fixest with date dummies and clinic-clustered SEs.
  - The do-file clusters on `cscomnum`, which does not exist in the data; it is a Stata abbreviation that resolves to `cscomnum_OS` (the only variable with that prefix, 60 clinics), used here.
- [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) (11/12; failed: `severe_malaria_treatment_prescribed_patient_voucher_table3_col4`)
  - Stata's pdslasso/rlasso (lassopack) is not available in R; the post-double-selection lasso was re-implemented by hand: rlasso with cluster-robust (by clinic) penalty loadings, lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)) with gamma = 0.1/log(number of clusters), initial residuals from the 5 most correlated controls, up to 15 loading iterations using post-lasso residuals, coordinate-descent lasso. Date dummies DD1-DD35 and the constant are partialled out (unpenalised, always kept). Final OLS of the outcome on the voucher dummies, date dummies and the union of selected controls with clinic-clustered SEs (fixest). Small details of lassopack's defaults may differ from this implementation.
- [seeded/pipeline-desktop-opus/20261110T112214Z](seeded/pipeline-desktop-opus/20261110T112214Z/CELL.md) (12/12)
  - Clinic cluster id reconstructed from the CL* clinic dummies (cscomnum not found in data)
- [seeded/pipeline-desktop-opus-run2/20261110T142949Z](seeded/pipeline-desktop-opus-run2/20261110T142949Z/CELL.md) (12/12)
  - Penalty-loading iterations in rlasso capped at 2 (lassopack/pdslasso default) since the paper does not state the lasso tuning details
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (12/12)
  - Post-double-selection lasso implemented by hand in R (glmnet/hdm not available): rlasso-style rigorous plug-in penalty lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(#clusters), clinic-cluster-robust penalty loadings iterated with post-lasso residuals (initial residuals from OLS on the 5 most correlated candidates). The authors' Stata lasso implementation (pdslasso vs dsregress, exact penalty constants) is unknown, so the selected control set may differ slightly.
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (12/12)
  - Post-double-selection lasso implemented by hand in R (glmnet/hdm not installed): rigorous BCH penalty lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(#clusters), clinic-cluster-robust penalty loadings iterated on post-lasso residuals (up to 15 iterations, initial residuals from OLS on the 5 most correlated candidates), date fixed effects partialled out before selection. This approximates Stata pdslasso/rlasso with cluster(); exact Stata defaults (e.g. psi-iteration count) may differ.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (12/12)
  - glmnet/lassopack are not available, so the post-double-selection lasso is a hand-written rigorous (plug-in) lasso in the style of Stata's lassopack rlasso/pdslasso: coordinate descent, cluster-robust (clinic) penalty loadings iterated on post-lasso residuals (initialised from OLS on the 5 most correlated regressors), lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), gamma = 0.1/log(N_clusters). The exact Stata penalty settings used by the authors are not stated in the paper, so selected controls may differ slightly from theirs.
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (12/12)
  - Post-double-selection lasso implemented by hand in R (glmnet/hdm not installed): rigorous plug-in lasso with heteroskedastic penalty loadings, lambda = 2*1.1*sqrt(n)*qnorm(1-gamma/(2p)), gamma = 0.1/log(n), initial residuals from OLS on the 5 most correlated candidates, post-lasso residuals for loading updates (up to 15 iterations); date fixed effects and constant partialled out before selection. This mimics Stata pdslasso/rlasso defaults; exact selected sets may differ from the authors' software.
  - Candidate controls taken from the pre-built variables in the analysis file: CC* (individual controls with missing values set to the sample mean, plus missing dummies), CC*xCC* pairwise interactions, CL* clinic dummies.
- [independent/pipeline-desktop-opus/20261110T065707Z](independent/pipeline-desktop-opus/20261110T065707Z/CELL.md) (12/12)
  - Restricted to analysis sample via dropme ==0 (n=2055) to match the paper's 2,055 acutely ill patients; the exact sample flag is not named in the paper
- [independent/pipeline-desktop-opus-run2/20261110T142213Z](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) (12/12)
  - Any-antimalarial outcome constructed as simple-or-severe treatment because no single any-antimalarial variable was identified
  - Any-antimalarial-prescribed coded from RXisantimal* (0 if no prescribed drug is an antimalarial) where the simple/severe prescription flags were both missing but the prescription record was observed
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (8/12; failed: `voucher_used_patient_voucher_table3_col1`, `voucher_used_doctor_voucher_table3_col1`, `n_obs_table3_col1`, `n_obs_table3_cols2_5`)
  - Post-double-selection lasso implemented by hand in R (no glmnet/pdslasso available): rlasso-style plug-in lasso with cluster-robust (clinic) penalty loadings, c=1.1, gamma=0.1/log(60 clusters), lambda=2c*sqrt(n)*qnorm(1-gamma/(2p)), initial residuals from OLS on the 5 most-correlated candidates, loadings iterated on post-lasso residuals (max 15 iterations). Exact Stata pdslasso/rlasso defaults could not be verified, so the selected control set may differ from the authors'.
  - Date fixed effects (date_morning_survey) are partialled out of outcome, treatments and candidate controls before the lassos, and included in the final OLS; the final OLS uses the union of controls selected in the outcome, Patient Voucher and Doctor Voucher lassos (PDS OLS, not the CHS orthogonalized estimator).
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (8/12; failed: `voucher_used_patient_voucher_table3_col1`, `voucher_used_doctor_voucher_table3_col1`, `n_obs_table3_col1`, `n_obs_table3_cols2_5`)
  - Post-double-selection lasso implemented by hand in base R (coordinate descent) because glmnet/hdm/lassopack are not available; it follows Stata lassopack rlasso/pdslasso defaults as best known: date FE and constant partialled out, standardized controls, lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), cluster-robust (clinic) penalty loadings with gamma = 0.1/log(number of clinics), initial residuals from OLS on the 5 most correlated controls, 2 lasso-based loading updates with post-lasso residuals. The exact options the authors passed to pdslasso (heteroskedastic vs cluster loadings, gamma, iterations) are not stated in the paper, so selected controls may differ slightly.
  - Candidate controls taken from the dataset's pre-built control set: CC* main effects (23 patient/respondent controls, mean-imputed, with missing dummies), their 249 pairwise interactions CCixCCj, and 59 clinic dummies CL1-CL59 (331 candidates), matching the Table 3 notes.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (8/12; failed: `voucher_used_patient_voucher_table3_col1`, `voucher_used_doctor_voucher_table3_col1`, `n_obs_table3_col1`, `n_obs_table3_cols2_5`)
  - Post-double-selection lasso implemented by hand (glmnet/hdm/lassopack unavailable): rigorous plug-in lasso following lassopack rlasso defaults as I understand them -- cluster-robust penalty loadings by clinic (psi_j = sqrt((1/N) sum_g (sum_{i in g} x_ij e_i)^2)), lambda = 2*1.1*sqrt(N)*qnorm(1 - gamma/(2p)) with gamma = 0.1/log(number of clusters), initial residuals from OLS on the 5 most correlated regressors, 2 loading iterations using post-lasso residuals. The authors' exact lasso implementation (pdslasso vs Stata dsregress, heteroskedastic vs cluster loadings, gamma) is not stated in the paper, so selected controls may differ.
  - Candidate controls taken as the analysis file's prebuilt CC* variables (23 individual controls with missing values mean-recoded plus missing dummies, and their 249 pairwise interactions) and CL* clinic dummies (59); date dummies (DD*, plus constant) partialled out of all variables before the lassos and always included; final OLS with date fixed effects (date_morning_survey) and clinic-clustered SEs via fixest.
  - Treatment dummies are patient_voucher and doctor_voucher (scheduled assignment) as in the analysis file; PI (information) cross-cut not controlled, pooled across arms as the paper's equation (1) describes.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (12/12)
  - Post-double-selection lasso implemented by hand (no glmnet/hdm/lassopack in the sandbox): rigorous plug-in penalty lambda = 2*1.1*sqrt(N)*qnorm(1-gamma/(2p)), gamma = 0.1/log(number of clinics), cluster-robust (clinic) penalty loadings, initial residuals from OLS on the 5 most correlated regressors, loadings iterated with post-lasso residuals (up to 15 iterations). Exact Stata (pdslasso/rlasso) penalty conventions may differ, which can change the selected control set.
  - Date fixed effects partialled out (within-date demeaning) of outcome, treatments and candidates before the lasso steps; they enter the final OLS unpenalised.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `any_malaria_treatment_purchased_doctor_voucher_table3_col3` — pipeline 0/4, agent 4/4
- blind: `any_malaria_treatment_purchased_patient_voucher_table3_col3` — pipeline 0/4, agent 4/4
- blind: `severe_malaria_treatment_purchased_doctor_voucher_table3_col5` — pipeline 0/4, agent 4/4
- blind: `severe_malaria_treatment_purchased_patient_voucher_table3_col5` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- seeded: `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` — pipeline 3/3, agent 1/2
- blind: `any_malaria_treatment_prescribed_patient_voucher_table3_col2` — pipeline 2/4, agent 4/4
- blind: `severe_malaria_treatment_prescribed_doctor_voucher_table3_col4` — pipeline 2/4, agent 4/4
- blind: `severe_malaria_treatment_prescribed_patient_voucher_table3_col4` — pipeline 1/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-10T06:43:30Z; from `claude-code-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 11/12, re-scored 11/12; first scored 11/12; executions 3; 2026-11-10T06:44:00Z; from `claude-code-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T112214Z

[`seeded/pipeline-desktop-opus/20261110T112214Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T112214Z/CELL.md) — final 12/12, re-scored 12/12; first scored 3/12; executions 3; 2026-11-10T11:22:14Z; from `pipeline-oracle-desktop-opus-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T142949Z

[`seeded/pipeline-desktop-opus-run2/20261110T142949Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T142949Z/CELL.md) — final 12/12, re-scored 12/12; first scored 4/12; executions 4; 2026-11-10T14:29:49Z; from `pipeline-oracle-desktop-opus-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T113744Z

[`seeded/pipeline-desktop-opus-run3/20261110T113744Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T113744Z/CELL.md) — final 12/12, re-scored 12/12; first scored 4/12; executions 3; 2026-11-10T11:37:44Z; from `pipeline-oracle-desktop-opus-run3-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-10T06:43:30Z; from `claude-code-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-10T06:44:00Z; from `claude-code-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-10T06:48:19Z; from `claude-code-run3-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-10T06:48:00Z; from `claude-code-run4-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T065707Z

[`independent/pipeline-desktop-opus/20261110T065707Z/CELL.md`](independent/pipeline-desktop-opus/20261110T065707Z/CELL.md) — final 12/12, re-scored 12/12; first scored 7/12; executions 3; 2026-11-10T06:57:07Z; from `pipeline-oracle-desktop-opus-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T142213Z

[`independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T142213Z/CELL.md) — final 12/12, re-scored 12/12; first scored 2/12; executions 4; 2026-11-10T14:22:13Z; from `pipeline-oracle-desktop-opus-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T113422Z

[`independent/pipeline-desktop-opus-run3/20261110T113422Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T113422Z/CELL.md) — final 12/12, re-scored 12/12; first scored 2/12; executions 3; 2026-11-10T11:34:22Z; from `pipeline-oracle-desktop-opus-run3-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T112343Z

[`independent/pipeline-desktop-opus-run4/20261110T112343Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T112343Z/CELL.md) — final 4/12, re-scored 4/12; first scored 4/12; executions 2; 2026-11-10T11:23:43Z; from `pipeline-oracle-desktop-opus-run4-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 8/12, re-scored 8/12; first scored 8/12; executions 3; 2026-11-10T06:45:00Z; from `claude-code-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 8/12, re-scored 8/12; first scored 8/12; executions 4; 2026-11-10T06:49:30Z; from `claude-code-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 8/12, re-scored 8/12; first scored 8/12; executions 3; 2026-11-10T06:49:00Z; from `claude-code-run3-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-10T07:20:00Z; from `claude-code-run4-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T064634Z

[`blind/pipeline-desktop-opus/20261110T064634Z/CELL.md`](blind/pipeline-desktop-opus/20261110T064634Z/CELL.md) — final 0/12, re-scored 0/12; first scored 0/12; executions 2; 2026-11-10T06:46:34Z; from `pipeline-oracle-desktop-opus-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T070059Z

[`blind/pipeline-desktop-opus-run2/20261110T070059Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T070059Z/CELL.md) — final 3/12, re-scored 3/12; first scored 3/12; executions 1; 2026-11-10T07:00:59Z; from `pipeline-oracle-desktop-opus-run2-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T070123Z

[`blind/pipeline-desktop-opus-run3/20261110T070123Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T070123Z/CELL.md) — final 3/12, re-scored 3/12; first scored 3/12; executions 1; 2026-11-10T07:01:23Z; from `pipeline-oracle-desktop-opus-run3-1paper-lopez-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T065844Z

[`blind/pipeline-desktop-opus-run4/20261110T065844Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T065844Z/CELL.md) — final 2/12, re-scored 2/12; first scored 2/12; executions 1; 2026-11-10T06:58:44Z; from `pipeline-oracle-desktop-opus-run4-1paper-lopez-indep-blind-2026-11-10.json`; evidence complete.

