# Evidence report: altindag-2022-mental-health-costs-lockdowns

**Mental Health Costs of Lockdowns: Evidence from Age-Specific Curfews in Turkey** — Onur Altindag, Bilge Erten, Pinar Keskin

- Paper: https://epflicht.ulb.uni-bonn.de/download/pdf/661207
- I4R report: https://www.econstor.eu/bitstream/10419/268496/1/I4R-DP016.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/altindag-2022-mental-health-costs-lockdowns.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T54/ICPSR_183165-V1.1.zip`; openICPSR project 183165, version V1.1 (doi:10.3886/E183165V1 is the V1 registration; "Revised Reproduction Package for 'Mental Health Costs of Lockdowns ...' - Hennigan et al. (2022)", deposited by Cian Hennigan, William Spain and Ronan Hegarty of Trinity College Dublin); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T54/ICPSR_183165-V1.1.zip (260,813 bytes, md5 91cf314544261e3e3ad9cabfc39f737f; SOURCE.txt beside it).  This is NOT the authors' own AEA deposit (openICPSR 131981 V1, doi:10.3886/E131981V1, which I4R DP 16 used) but a student reproduction package that re-ships the authors' analysis file and revised copies of their code; its analysis file reproduces the published Table 3 column (3) and the Table 4 SRQ-20 sum exactly, with the same N (an independent least-squares check, 2026-11-09; see notes).  19 entries, 1,590,185 bytes uncompressed, all deflate, no nested archives, all under ICPSR_183165-V1.1/: konda_data_for_analysis.dta (1.2 MB, 2,175 respondents of the KONDA phone survey, 146 variables: SRQ-20 items, mobility, channels, covariates, the running variable, treatment dummy, birth month-year, and month and province dummies); "read me .pdf" (3 pp., written by the Trinity College team, December 2022: folder layout, run order, software, no estimates); the authors' code as revised by that team — 1 Tables.do (Tables 1-6, A2-A8), 2 Figures.do, 3 Adjustment q main.do, 4 Adjustment q appendix.do, fdr_sharpened_qvalues_v02.do (Anderson 2008), rd_an.do (Asher and Novosad 2020), rdprog_cols1_se2_connected.do (Meyersson 2014), and three R scripts for appendix Table A1 / Figures A1, A2, A4 (A1 needs the TurkStat Household Labour Force Survey, not shipped); and seven files named "Replication Analysis - ..." (.do: Table 4, Table 5, Tables 1-3 and 6, Figures, and three q-value adjustments, dated December 2021 to December 2022, outputs prefixed "REP"), which are the Trinity College team's own replication scripts, not the authors'.  The _gweightave2.ado index program the README names is not in the zip.  No log, table, manuscript or results file is shipped.  The script-free copy (independent / blind) withholds 17 files (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09), all by suffix: the 14 .do (the seven "Replication Analysis" files among them) and the 3 .R.  Kept: the .dta and the README PDF, which prints no pinned value.  Project page: https://www.openicpsr.org/openicpsr/project/183165/version/V1.1/view)

> Headline findings (+/-45-month column (3), N 1214 / 1222 / 1203 in Table 3 and 1133 / 1203 / 1137 / 1133 in Table 4): crossing the age threshold cuts days outside last week by -1.090 (0.180), raises being under curfew by 0.708 (0.045) and never going out by 0.297 (0.036); the mental distress index rises 0.205 (0.094) SD, the somatic index 0.175 (0.085), the nonsomatic index 0.158 (0.092), and the SRQ-20 sum 0.734 (0.440) "yes" answers.
> Paper text and how it was verified.  The published article was not read: the AEA page labels it "Complimentary", but pubs.aeaweb.org answers scripts with a Cloudflare challenge, and docs.iza.org (the candidates file's link) answers 403; neither was bypassed.  The source is IZA DP 14281 (April 2021) from the Bonn legal-deposit server.  Its Table 3 and Table 4 were read cell by cell and compared with the 28 meta-database rows as the same table, row and column (3) (+/-45): every row's o_coeff_dbl / o_std_err_dbl names one of the seven column (3) cells, and all seven equal the WP cell: Table 3 days outside -1.09 (0.180), under curfew 0.708 (0.045), never goes out 0.297 (0.036); Table 4 mental distress index 0.205 (0.094), somatic 0.175 (0.085), nonsomatic 0.158 (0.092), SRQ-20 sum 0.734 (0.440).  The WP prints the days-outside estimate as "-1.09"; DP16 Tables 1-2 print -1.090, and the authors' table code formats coefficients to three decimals, so the value is pinned as -1.090 (numerically the same). Two DB variants are DP16 transcription slips, not different published values: rows coded -1.089 (0.179) and 0.708 (0.044) come from DP16 Table 3 column (1) (the rdrobust table), whereas DP16 Tables 1 and 2 column (1), described identically as "a reproduction of the results presented in Table 3, Column 3", print -1.090 (0.180) and 0.708 (0.045) as the WP does.  One more DB slip: the no-covariates row for the nonsomatic index codes r_std_err 0.100 where DP16 Table 5 prints 0.125 (r_coeff 0.100 is right). The three N claims have no I4R row.  They are pinned because the WP is a late revision of the published paper: the published online appendix is dated April 6, 2021 (web search result for the AEA materials page, not opened), the WP was created April 9, 2021; DP16 quotes the published pp. 334-335 mental-health paragraph and cites footnote 30 (p. 329) on the uniform kernel, and the WP's own paragraph and footnote 30 read the same; and the package data reproduce exactly the WP's N for all seven column (3) outcomes.
> Independent check of the data (2026-11-09, numpy least squares with Stata's CR1 cluster correction, no Stata here).  With survey non-respondents dropped and listwise deletion on the controls, the column (3) regressions give days outside -1.090 (0.180) N 1214, under curfew 0.708 (0.045) N 1222, never out 0.297 (0.036) N 1203, SRQ-20 sum 0.734 (0.440) N 1133, 91 birth-cohort clusters: the published values exactly.  The three indices came out at 0.214 (0.097), 0.173 (0.085) and 0.147 (0.093) with an inverse-covariance index computed on the control group and re-standardised (N 1133 / 1203 / 1137 exact); other weightings gave 0.08-0.16, so the index claims depend on matching the Anderson construction, which the package's missing _gweightave2.ado would have fixed.
> Curation pass (2026-11-09).  10 claims.  Left out: the +/-17, +/-30 and +/-60 columns (bandwidth robustness inside the main tables), the p-values and sharpened q-values, the control group means, Table 3/4 remaining N rows, Tables 1-2 (summary statistics), Table 5 (channels; the abstract calls labor market and conflict effects not robust) and Table 6 (policy support), and the appendix.
> Package-only facts (never in contexts).  1 Tables.do: keep if non_response==0; global contr "month_* province_n_* i.ethnicity i.education female i.survey_taker_id"; vce(cluster modate); xi: reg y before1955 di1* $contr if inrange(dif,-45,45) (di1, di1_i the linear running-variable terms on each side; dif the running variable in months); indices egen z_depression / z_somatic / z_nonsomatic = weightave2(list), normby(controldummy) with controldummy = before1955==0, then set missing if any component item is missing; sum_srq = rowtotal(list1), missing if any item missing.  Outcomes outside_week, under_curfew, never_out.  estout cells b(fmt(%9.3f)) se(par).
> Blind-mode exposure (step 6, 2026-11-09).  Both modes reach llm_answer_pending with the manual package mounted (17 files stripped).  The blind generation prompt (reached by answering the methodology and hyperparameter prompts with results-free text) states no pinned value or SE at printed precision or rounded to 2-3 significant figures and carries no script text; its only numeric near-hit is the abstract's "approximately 0.2 standard deviation". The dataset listing shows the .dta column names and Stata variable labels (e.g. the treatment dummy's label "born before December 1955"), no estimates.  The paper text given to the methodology summariser carries the WP's rounded in-text results (1-1.1 days, 71 and 30 percentage points, 0.21 / 0.18 / 0.16 SD, 0.7); the summariser is told to leave results out, and the README's blind-mode caveat covers this.  The parser takes the IZA cover line ("DISCUSSION PAPER SERIES") as the title.
> What was read.  IZA DP 14281 pp. 1-17, Tables 3-4 and Appendix B; DP16 in full; the 29 meta-database rows; the package README and the Tables 3-4 block of 1 Tables.do, the headers of every other script; the DataCite records of E131981V1 and E183165V1; the strip-rule classification of the extracted package.
> What could not be verified.  The published article and its online appendix were not read (Cloudflare challenge).  That the re-deposit's analysis file is byte-identical to the authors' own package (openICPSR 131981, login) was not checked; it reproduces the published numbers. The authors' Stata code was not run (no Stata here).
> Original analysis in Stata 17 (estout, fsum, _gweightave2.ado) with R for appendix figures; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `days_outside_last_week_table3_col3` | -1.09 | 0.18 | Table 3, Days outside last week, Born before 1955, column (3) +/-45 | -1.09 | matches |
| 1 | `under_curfew_table3_col3` | 0.708 | 0.045 | Table 3, Under curfew, Born before 1955, column (3) +/-45 | 0.708 | matches |
| 2 | `never_goes_out_table3_col3` | 0.297 | 0.036 | Table 3, Never goes out, Born before 1955, column (3) +/-45 | 0.297 | matches |
| 3 | `n_obs_days_outside_table3_col3` | 1214 | — | Table 3, Days outside last week, Observations, column (3) | — | — |
| 4 | `n_obs_under_curfew_table3_col3` | 1222 | — | Table 3, Under curfew, Observations, column (3) | — | — |
| 5 | `mental_distress_index_table4_col3` | 0.205 | 0.094 | Table 4, Mental distress index, Born before 1955, column (3) +/-45 | 0.205 | matches |
| 6 | `somatic_symptoms_index_table4_col3` | 0.175 | 0.085 | Table 4, Somatic symptoms of distress index, Born before 1955, column (3) +/-45 | 0.175 | matches |
| 7 | `nonsomatic_symptoms_index_table4_col3` | 0.158 | 0.092 | Table 4, Nonsomatic symptoms of distress index, Born before 1955, column (3) +/-45 | 0.158 | matches |
| 8 | `sum_srq20_yes_answers_table4_col3` | 0.734 | 0.44 | Table 4, Sum of "yes" answers in SRQ-20, Born before 1955, column (3) +/-45 | 0.734 | matches |
| 9 | `n_obs_mental_distress_index_table4_col3` | 1133 | — | Table 4, Mental distress index, Observations, column (3) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [8/10](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[10/10](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [10/10](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[10/10](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[10/10](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[10/10](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [9/10](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[9/10](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[9/10](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[9/10](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [8/10](seeded/pipeline-desktop-opus/20261110T162835Z/CELL.md) (20261110T162835Z) | [10/10](independent/pipeline-desktop-opus/20261110T144524Z/CELL.md) (20261110T144524Z) | [10/10](blind/pipeline-desktop-opus/20261110T143542Z/CELL.md) (20261110T143542Z) |
| `pipeline-desktop-opus-run2` | [7/10](seeded/pipeline-desktop-opus-run2/20261110T163624Z/CELL.md) (20261110T163624Z) | [10/10](independent/pipeline-desktop-opus-run2/20261110T163226Z/CELL.md) (20261110T163226Z) | [9/10](blind/pipeline-desktop-opus-run2/20261110T145151Z/CELL.md) (20261110T145151Z) |
| `pipeline-desktop-opus-run3` | [6/10](seeded/pipeline-desktop-opus-run3/20261110T163637Z/CELL.md) (20261110T163637Z) | [10/10](independent/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) (20261110T145201Z) | [9/10](blind/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) (20261110T145201Z) |
| `pipeline-desktop-opus-run4` | — | [10/10](independent/pipeline-desktop-opus-run4/20261110T163302Z/CELL.md) (20261110T163302Z) | [10/10](blind/pipeline-desktop-opus-run4/20261110T145215Z/CELL.md) (20261110T145215Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus/20261110T144524Z](independent/pipeline-desktop-opus/20261110T144524Z/CELL.md) | `n_obs_mental_distress_index_table4_col3` | 1187 | 1133 | ±56.65 (relative) | 0.953 | PASS |
| [blind/pipeline-desktop-opus-run3/20261110T145201Z](blind/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) | `n_obs_mental_distress_index_table4_col3` | 1073 | 1133 | ±56.65 (relative) | 1.059 | FAIL |
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.080142 | 0.175 | ±0.085 (se_band) | 1.116 | FAIL |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.080142 | 0.175 | ±0.085 (se_band) | 1.116 | FAIL |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.080142 | 0.175 | ±0.085 (se_band) | 1.116 | FAIL |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.080142 | 0.175 | ±0.085 (se_band) | 1.116 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261110T145151Z](blind/pipeline-desktop-opus-run2/20261110T145151Z/CELL.md) | `n_obs_days_outside_table3_col3` | 1165 | 1214 | ±60.7 (relative) | 0.807 | PASS |
| [independent/pipeline-desktop-opus-run3/20261110T145201Z](independent/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.106788 | 0.175 | ±0.085 (se_band) | 0.802 | PASS |
| [blind/pipeline-desktop-opus-run2/20261110T145151Z](blind/pipeline-desktop-opus-run2/20261110T145151Z/CELL.md) | `n_obs_under_curfew_table3_col3` | 1173 | 1222 | ±61.1 (relative) | 0.802 | PASS |
| [blind/pipeline-desktop-opus/20261110T143542Z](blind/pipeline-desktop-opus/20261110T143542Z/CELL.md) | `somatic_symptoms_index_table4_col3` | 0.108382 | 0.175 | ±0.085 (se_band) | 0.784 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) (8/10; failed: `mental_distress_index_table4_col3`, `nonsomatic_symptoms_index_table4_col3`)
  - The Anderson (2008) indices come from the authors' _gweightave2.ado (egen weightave2, normby(controldummy)), which is not in the replication package. It was reconstructed: items z-scored with control-group (born after Dec 1955) mean/SD; weights = row sums of the inverse covariance matrix of the z-scores estimated on complete cases in the control group; weighted average; index re-standardised to control-group mean 0, SD 1. The control-group covariance was chosen after claim comparisons (attempt-2 used full-sample covariance; attempt-4 scored a raw-item-covariance version and printed alternative constructions as '#' diagnostic lines, among which the control-group-covariance version fit the claimed coefficients and SEs best).
  - Stata's xi: dummy regression is translated to feols with the month_*/province_n_* dummies and factor() terms as regressors (collinear month_12 and province_n_66 dropped automatically), clustered by modate.
- [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) (10/10)
  - The authors' _gweightave2.ado (Asher & Novosad) is not in the package, so the Anderson (2008) index was re-implemented in R: items z-scored with the control-group (before1955==0) mean and SD over the non-response==0 sample, combined with weights equal to the row sums of the inverse correlation matrix of the z-scores (complete cases), then rescaled to mean 0 / SD 1 in the control group, and set to missing if any item is missing. The weighting and rescaling were chosen by comparing variants against the claimed Table 4 values (attempt-3 diagnostics); the chosen variant also matches the paper's standard errors.
- [seeded/pipeline-desktop-opus/20261110T162835Z](seeded/pipeline-desktop-opus/20261110T162835Z/CELL.md) (8/10; failed: `mental_distress_index_table4_col3`, `somatic_symptoms_index_table4_col3`)
  - Mental health indices built with Anderson (2008) inverse-covariance weighting of control-group-standardized items (control group = born 1956 or later, full analysis sample), index re-standardized to control-group mean 0 / SD 1, and defined only for respondents answering all 20 SRQ items; the paper cites Anderson (2008) but does not spell out weighting, reference group or missing-item rule
- [seeded/pipeline-desktop-opus-run2/20261110T163624Z](seeded/pipeline-desktop-opus-run2/20261110T163624Z/CELL.md) (7/10; failed: `mental_distress_index_table4_col3`, `somatic_symptoms_index_table4_col3`, `nonsomatic_symptoms_index_table4_col3`)
  - Indices built as equal-weighted averages of control-standardised item z-scores (per the paper's description), complete cases only; exact Anderson weighting/missing-item handling not stated
- [seeded/pipeline-desktop-opus-run3/20261110T163637Z](seeded/pipeline-desktop-opus-run3/20261110T163637Z/CELL.md) (6/10; failed: `mental_distress_index_table4_col3`, `somatic_symptoms_index_table4_col3`, `nonsomatic_symptoms_index_table4_col3`, `n_obs_mental_distress_index_table4_col3`)
  - Mental health indices built with Anderson (2008) inverse-covariance (GLS) weights, pairwise-complete covariance and weights renormalized over each respondent's answered items
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (10/10)
  - fixest's default removed 15-16 fixed-effect singleton observations per regression, so reported N (1199, 1207, 1117) is below the full estimation sample (1214, 1222, 1133 identified in exploratory attempt-2 with \|dif\|<=45 and complete controls); coefficients are unaffected by singleton removal. Not changed after comparison with claims.
  - Anderson (2008) indices built on the full respondent sample (non_response==0): items standardized by control-group (born Jan 1956 or later) mean/SD, weighted by row sums of the inverse covariance matrix of standardized items, index re-standardized to control mean 0/SD 1; index defined only where all component items are observed (matches the paper's sample sizes).
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (10/10)
  - Anderson (2008) indices: items standardized by the mean/sd of the control group (born Jan 1956 or later) in the full respondent sample; inverse-covariance weights from all complete-case respondents; index defined only for respondents answering every component item; final index re-standardized to control mean 0 / sd 1. Exact details of the authors' implementation are not given in the paper, and the index coefficients (0.157, 0.112, 0.152) are below the published ones (0.205, 0.175, 0.158).
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (10/10)
  - fixest removes fixed-effect singletons (15-16 obs per regression; does not change coefficients), so reported Ns (1199, 1207, 1117) are below the paper's (1214, 1222, 1133), which presumably keep singletons as Stata reg/areg would; adding those back matches the paper's Ns exactly.
  - Anderson (2008) indices built on the full respondent sample: items z-scored with control-group (born 1956 or later) mean/SD, weighted by row sums of the inverse covariance matrix of the z-scores, complete cases only, then re-standardized by control mean/SD. The paper's exact weighting routine (_gweightave2) was not available; index coefficients (0.157, 0.112, 0.152) are below the paper's (0.205, 0.175, 0.158) while the SRQ-20 sum matches (0.734).
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (10/10)
  - Anderson (2008) indices built as: items standardized by control-group (born 1956+) mean and SD, inverse-covariance (row-sum) weights from the covariance of the standardized items over complete cases, index re-standardized to control mean 0 / SD 1; computed once on the full respondent sample (not within the bandwidth). The authors' _gweightave2.ado was not available, so the exact weighting/normalization may differ.
- [independent/pipeline-desktop-opus/20261110T144524Z](independent/pipeline-desktop-opus/20261110T144524Z/CELL.md) (10/10)
  - Anderson indices average z-scores over answered SRQ items, restricted to respondents answering at least 75% of the items (paper does not state its missing-item rule)
- [independent/pipeline-desktop-opus-run2/20261110T163226Z](independent/pipeline-desktop-opus-run2/20261110T163226Z/CELL.md) (10/10)
  - Overall mental distress index set to missing for respondents with more than one missing SRQ-20 item (paper does not state its missing-item rule)
- [independent/pipeline-desktop-opus-run4/20261110T163302Z](independent/pipeline-desktop-opus-run4/20261110T163302Z/CELL.md) (10/10)
  - Overall SRQ-20 distress index and yes-count set to missing when more than 2 of the 20 items are unanswered (paper does not state its missing-item rule; complete-case gave too few obs, any-item too many)
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (9/10; failed: `somatic_symptoms_index_table4_col3`)
  - Bandwidth sample taken as \|dif\| <= 45 (dif = months older than December 1955; dif=0 is December 1955, treated). The paper's equation writes an open interval (c-h, c+h); the closed version was chosen because the text says 'born within 45 months'.
  - Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later, before1955==0) mean and SD over all respondents answering every SRQ-20 item (full sample, not just the bandwidth); weights are row sums of the inverse covariance matrix of the standardized items; the weighted index is re-standardized to mean 0, SD 1 in the control group.
  - Observation counts are complete cases (outcome, treatment, running variable, education, ethnicity, female, birth month, province, surveyor) in the bandwidth, i.e. without dropping fixed-effect singletons (fixest drops 15-16 singletons in estimation, which does not change the point estimates).
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (9/10; failed: `somatic_symptoms_index_table4_col3`)
  - Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later, full +/-72-month respondent sample) mean/SD, combined with inverse-covariance weights (row sums of inverse covariance of standardized items, computed on respondents answering all 20 SRQ-20 items), then the index is rescaled to control-group mean 0 / SD 1. Indices and SRQ-20 sum defined only for respondents answering all 20 items. The paper's main text describes a simple average of z-scores while Appendix B describes inverse-covariance weighting; Appendix B was followed.
  - Bandwidth +/-45 implemented as \|dif\| <= 45, where dif = months older than December 1955 (treated: dif >= 0).
  - Estimated with fixest::feols (month, province, surveyor FE absorbed; education and ethnicity category dummies and female as regressors; clustered by month-year of birth). fixest drops fixed-effect singletons (15-16 obs here), as reghdfe would; the reported N excludes them.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (9/10; failed: `somatic_symptoms_index_table4_col3`)
  - Bandwidth sample taken as \|dif\| <= 45 (inclusive), where dif = months between birth month-year and December 1955 (dif >= 0 is treated); the paper's equation writes an open interval, which was read as 'born within 45 months'.
  - Anderson (2008) indices built on respondents with all 20 SRQ-20 items answered: items standardized with the control-group (born Jan 1956 or later, full 72-month survey sample) mean and SD, weighted by row sums of the inverse covariance matrix of the standardized items (full sample), and the final index re-standardized to mean 0 / SD 1 in the control group.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (9/10; failed: `somatic_symptoms_index_table4_col3`)
  - Bandwidth +/-45 implemented as \|dif\| <= 45 (dif = months older than December 1955; treated side dif 0..45, control side -1..-45).
  - Anderson (2008) indices: items standardized by control-group (born Jan 1956 or later) mean/SD over all respondents answering all 20 SRQ-20 items (not bandwidth-restricted); weights are row sums of the inverse covariance matrix of the standardized items (computed on that full complete-case sample); the weighted index is re-standardized to control-group mean 0 / SD 1.
  - Fixed effects and indicators entered as factor dummies in feols (birth month, province, surveyor, education category, ethnicity category, female); observations with any missing outcome/control dropped; no singleton removal.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- seeded: `somatic_symptoms_index_table4_col3` — pipeline 0/3, agent 2/2
- blind: `somatic_symptoms_index_table4_col3` — pipeline 4/4, agent 0/4

Pass rates at least 50 points apart (not unanimous):

- seeded: `mental_distress_index_table4_col3` — pipeline 0/3, agent 1/2
- blind: `n_obs_mental_distress_index_table4_col3` — pipeline 2/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 8/10, re-scored 8/10; first scored 7/10; executions 5; 2026-11-10T11:34:00Z; from `claude-code-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 10/10, re-scored 10/10; first scored 7/10; executions 4; 2026-11-10T11:33:30Z; from `claude-code-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T162835Z

[`seeded/pipeline-desktop-opus/20261110T162835Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T162835Z/CELL.md) — final 8/10, re-scored 8/10; first scored 7/10; executions 4; 2026-11-10T16:28:35Z; from `pipeline-oracle-desktop-opus-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T163624Z

[`seeded/pipeline-desktop-opus-run2/20261110T163624Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T163624Z/CELL.md) — final 7/10, re-scored 7/10; first scored 7/10; executions 4; 2026-11-10T16:36:24Z; from `pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T163637Z

[`seeded/pipeline-desktop-opus-run3/20261110T163637Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T163637Z/CELL.md) — final 6/10, re-scored 6/10; first scored 7/10; executions 4; 2026-11-10T16:36:37Z; from `pipeline-oracle-desktop-opus-run3-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 3; 2026-11-10T11:31:30Z; from `claude-code-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 4; 2026-11-10T11:31:35Z; from `claude-code-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 2; 2026-11-10T11:35:00Z; from `claude-code-run3-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 4; 2026-11-10T11:32:00Z; from `claude-code-run4-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T144524Z

[`independent/pipeline-desktop-opus/20261110T144524Z/CELL.md`](independent/pipeline-desktop-opus/20261110T144524Z/CELL.md) — final 10/10, re-scored 10/10; first scored 9/10; executions 3; 2026-11-10T14:45:24Z; from `pipeline-oracle-desktop-opus-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T163226Z

[`independent/pipeline-desktop-opus-run2/20261110T163226Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T163226Z/CELL.md) — final 10/10, re-scored 10/10; first scored 8/10; executions 3; 2026-11-10T16:32:26Z; from `pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T145201Z

[`independent/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-11-10T14:52:01Z; from `pipeline-oracle-desktop-opus-run3-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T163302Z

[`independent/pipeline-desktop-opus-run4/20261110T163302Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T163302Z/CELL.md) — final 10/10, re-scored 10/10; first scored 9/10; executions 3; 2026-11-10T16:33:02Z; from `pipeline-oracle-desktop-opus-run4-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 2; 2026-11-10T11:31:00Z; from `claude-code-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 3; 2026-11-10T11:31:30Z; from `claude-code-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 3; 2026-11-10T11:34:30Z; from `claude-code-run3-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 3; 2026-11-10T11:34:00Z; from `claude-code-run4-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T143542Z

[`blind/pipeline-desktop-opus/20261110T143542Z/CELL.md`](blind/pipeline-desktop-opus/20261110T143542Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 1; 2026-11-10T14:35:42Z; from `pipeline-oracle-desktop-opus-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T145151Z

[`blind/pipeline-desktop-opus-run2/20261110T145151Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T145151Z/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 1; 2026-11-10T14:51:51Z; from `pipeline-oracle-desktop-opus-run2-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T145201Z

[`blind/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T145201Z/CELL.md) — final 9/10, re-scored 9/10; first scored 9/10; executions 1; 2026-11-10T14:52:01Z; from `pipeline-oracle-desktop-opus-run3-1paper-altindag-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T145215Z

[`blind/pipeline-desktop-opus-run4/20261110T145215Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T145215Z/CELL.md) — final 10/10, re-scored 10/10; first scored 10/10; executions 2; 2026-11-10T14:52:15Z; from `pipeline-oracle-desktop-opus-run4-1paper-altindag-indep-blind-2026-11-10.json`; evidence complete.

