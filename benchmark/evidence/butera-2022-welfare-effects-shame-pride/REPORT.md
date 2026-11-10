# Evidence report: butera-2022-welfare-effects-shame-pride

**Measuring the Welfare Effects of Shame and Pride** — Luigi Butera, Robert Metcalfe, William Morrison, Dmitry Taubinsky

- Paper: http://www.nber.org/papers/w25637.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/276252/1/I4R-DP064.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/butera-2022-welfare-effects-shame-pride.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T53/145141-V1.zip`; AEA Data and Code Repository on openICPSR, project 145141, version V1 (doi:10.3886/E145141V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T53/145141-V1.zip (8,033,487 bytes, md5 e4a630521216084283fab7fd3b471cef; SOURCE.txt beside it).  V1 is the only version.  42 zip entries (33 files, 9 directories), 31,154,441 bytes uncompressed, all under Packet/, no nested archives.  Contents: README.pdf (5 pp., dated 2021-12-24) and README.docx (its Word source; data provenance, run order, a table-to-program map, no estimates); "data dictionary.xlsx" (variable lists of the raw files, no numbers); Raw Data/ with eight .csv files: the four charity real-effort Qualtrics exports (prolific_survey_data.csv 1,017 participants, berkeley_survey_data.csv 407, bu_qm222_survey_data.csv 121 (the BU sample), bu_qm221_survey_data.csv 57 (a BU class not used in the main tables)), the YMCA survey, treatment assignment and membership files, and ymca_scans.csv (21 MB, 733,556 check-ins); Build/ with 7 Stata do-files and Analysis/Code/ with 8 (plus master_file.do); "QSF files and scripts/" with five Qualtrics .qsf survey definitions and "Experiment details appendix.pdf" (31 pp., LaTeX, 2021-07-13: survey questions and instructions, no results); empty Analysis/Output/, "Prepped Data/" and temp/ directories.  No log, table or figure output ships.  The script-free copy (independent / blind) withholds the 16 .do files by suffix (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09) and nothing else: neither PDF, the docx nor the xlsx prints a pinned value (grepped at printed precision and rounded).  Project page: https://www.openicpsr.org/openicpsr/project/145141/version/V1/view)

> Headline findings (Table 5): public recognition raises points scored by 105.01 (12.25) in the Prolific sample, 134.41 (22.56) at Berkeley and 103.61 (45.25) at BU; the financial incentive by 185.74 (12.56), 177.76 (22.04) and 118.33 (39.62); N 2904, 1152 and 354 participant-rounds (968, 384 and 118 participants).  Table 7 Berkeley, action-signaling model: gamma_1 0.30, rho 0.87, c 0.21; predicted financial incentive effect 2.33 hundred points against an actual 1.78.
> Paper text and how it was verified.  The published article was not read (paywalled).  The source is NBER WP 25637 revised July 2021.  Table 5: every one of the 13 meta-database "table 5" rows (o_coeff_dbl / o_std_err_dbl) equals the WP cell of the same row and column after rounding the WP's 2-decimal print to the DB's 4 significant digits (105.01 -> 105.0, 185.74 -> 185.7, 134.41 -> 134.4, 177.76 -> 177.8, 103.61 -> 103.6, 118.33 -> 118.3, 106.70 -> 106.7, 191.96 -> 192.0, -3.12 vs -3.117, -3.21 vs -3.213, -3.27 vs -3.270; 20.61 and -18.85 exact) and every SE is identical.  The DB transcribes DP64 Table 1's "Original" column (Stata default format); the package's own Table 5 code exports b(%8.2f) se(%8.2f), the WP's format.  Table 7: all 32 DB rows equal WP point estimates (the DB's SEs are the printed percentile CIs divided by 3.92, e.g. 0.34 [0.16, 1.47] -> 0.3342; c is printed in panels a and b, so each sample's c has two rows).  Table 6: the DB's three rows are the curvature-times-SD statistic, 0.245 (Prolific, equals the WP), 0.110 (Berkeley; WP 0.114) and -0.077 (BU; WP -0.085); DP64 Table 2's "Original" column agrees with the DB, so the WP's Table 6 is an earlier computation and nothing from Table 6 is pinned.  No DB value disagrees with DP64; no DB typo was found.
> Independent cross-check (2026-11-09, Python on the raw CSVs, not Stata): applying the package's build logic (attention check failed if attention_check is non-missing; coherent = preference switches 0 times, once from no to yes, or twice starting from no; drop participants with more than 3000 points in any round; the package's order coding) gives Table 5 columns (1)-(3) exactly: 105.01 (12.25), 185.74 (12.56), N 2904, 968 participants; 134.41 (22.56), 177.76 (22.04), 1152, 384; 103.61 (45.25), 118.33 (39.62), 354, 118.  The Table 7 point estimates for all three samples also come out as printed (Prolific 0.12, -0.004, 0.58, 0.08, prediction 2.41, actual 1.82; Berkeley 0.30, -0.004, 0.87, 0.21, 2.33, 1.78; BU 0.38, 0.002, 1.61, 0.34, 1.48, 1.18).
> Curation pass (2026-11-09).  13 claims.  Why Berkeley only in Table 7: the structural code (welfare_estimates.do) does NOT drop the more-than-3000-points participants that Table 5 drops, so its Prolific sample has 970 participants instead of the paper's 968 and its Prolific "actual" effect is 1.82 although Table 5 prints 185.74 points; a reproduction that follows the paper's stated final sample would miss the Prolific Table 7 values by about 2 percent.  BU's Table 7 values move with the order-dummy coding error (c 0.34 -> 0.30, prediction 1.48 -> 1.65).  Berkeley is affected by neither (no high-point participant; the corrected coding leaves its values unchanged but the prediction, 2.33 -> 2.34).  The order-dummy error moves the BU Table 5 estimates by about a third of an SE (DP64 Table 1), inside the SE-aware band.  Left out: Table 5 column (4) (group-size interactions), the order-dummy F-tests and control means, Tables 1-4 and 9 (YMCA; no I4R row, and the WP's Table 6 mismatch rules out pinning uncovered cells), Table 6 (WP differs from the package output), Table 8, panel (b) of Table 7 and the other Table 7 columns, the appendix.
> Package-only facts (never in contexts).  Raw columns (Stata lowercases them): attention_check, preference_0 ... preference_1700 (yes/no public), pref_anom_<j>_1 / pref_rec_<j>_1 (WTP sliders; WTP is minus the anonymous slider, else the recognition slider), condition (round order string such as AER), anompts / recogpts / earnpts, badgegroupsize. Label_Rounds.do assigns order 1-3 per round and condition (mis-coded for AER, EAR, RAE and REA, DP64 Appendix A); Table 5 regresses pts on SR ownpay o1 o2, clus(id); the Table 6 / 7 WTP regression uses interval midpoints (interval + 0.5, in hundreds of points) for intervals 0-16. Table 7: gamma2 = r2, gamma1 = sqrt(r1^2 - 4 r2 r0), rho = (gamma1 - r1) / (2 gamma2 abar_PR), c = (r1 + 2 r2 abar_PR) / tau, prediction = p / c with p = 0.5 (Berkeley, BU) or 0.2 (Prolific) dollars per hundred points, where abar_PR = anonymous-round mean + tau, all in hundreds of points; the printed value is the bootstrap's e(b), i.e. the full-sample estimate.  bu_qm221_survey_data.csv is a separate BU class not in the main tables.
> Blind-mode exposure (step 6, 2026-11-09).  Both modes reached llm_answer_pending at the methodology-summary prompt.  Neither prompt states a pinned value or SE at printed precision or rounded to 1-3 significant figures (the only hit, "2.3", is the section number "2.3 Structural Versus Reduced-Form"), and neither carries do-file text. The paper text in the prompt runs from the title page into Section 4 (YMCA), so none of Tables 5-7 is in it.  The paper parser takes the NBER cover line ("NBER WORKING PAPER SERIES") as the title.
> What was read.  NBER WP 25637 (July 2021) pp. 1-33 and Tables 1-9; DP64 in full; the 51 meta-database rows; README.pdf / README.docx; the Table 5 and Table 7 parts of charity_reduced_form_analysis.do and welfare_estimates.do, the build do-files; text of Experiment details appendix.pdf; the strip-rule classification of the extracted package.
> What could not be verified.  The published article itself was not read, so the published Table 5 / Table 7 print format is inferred from the package's export code and the WP; the authors' Stata code was not run (no Stata here); the cross-check above is Python, not R.
> Original analysis in Stata 15/16; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `public_recognition_points_prolific_table5_col1` | 105.01 | 12.25 | Table 5, Public recognition, column (1) Prolific | 105 | matches |
| 1 | `financial_incentives_points_prolific_table5_col1` | 185.74 | 12.56 | Table 5, Financial incentives, column (1) Prolific | 185.7 | matches |
| 2 | `public_recognition_points_berkeley_table5_col2` | 134.41 | 22.56 | Table 5, Public recognition, column (2) Berkeley | 134.4 | matches |
| 3 | `financial_incentives_points_berkeley_table5_col2` | 177.76 | 22.04 | Table 5, Financial incentives, column (2) Berkeley | 177.8 | matches |
| 4 | `public_recognition_points_bu_table5_col3` | 103.61 | 45.25 | Table 5, Public recognition, column (3) BU | 103.6 | matches |
| 5 | `financial_incentives_points_bu_table5_col3` | 118.33 | 39.62 | Table 5, Financial incentives, column (3) BU | 118.3 | matches |
| 6 | `n_obs_prolific_table5_col1` | 2904 | — | Table 5, Observations, column (1) Prolific | 2904 | matches |
| 7 | `n_obs_berkeley_table5_col2` | 1152 | — | Table 5, Observations, column (2) Berkeley | 1152 | matches |
| 8 | `n_obs_bu_table5_col3` | 354 | — | Table 5, Observations, column (3) BU | 354 | matches |
| 9 | `action_signaling_gamma1_berkeley_table7_panelA` | 0.3 | — | Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, gamma_1^a | 0.3 | matches |
| 10 | `action_signaling_rho_berkeley_table7_panelA` | 0.87 | — | Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, rho^a | 0.87 | matches |
| 11 | `cost_parameter_c_berkeley_table7_panelA` | 0.21 | — | Table 7, panel (a) Action-signaling model parameter estimates, Berkeley, c | 0.21 | matches |
| 12 | `predicted_financial_incentive_effect_berkeley_table7_panelC` | 2.33 | — | Table 7, panel (c) Predicted and actual effects of financial incentives, Berkeley, Model prediction | 2.33 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [13/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [11/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T164936Z/CELL.md) (20261110T164936Z) | [8/13](independent/pipeline-desktop-opus/20261110T171753Z/CELL.md) (20261110T171753Z) | [8/13](blind/pipeline-desktop-opus/20261110T164936Z/CELL.md) (20261110T164936Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) (20261110T174216Z) | [10/13](independent/pipeline-desktop-opus-run2/20261110T221231Z/CELL.md) (20261110T221231Z) | [7/13](blind/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) (20261110T174216Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md) (20261110T174232Z) | [9/13](independent/pipeline-desktop-opus-run3/20261110T221247Z/CELL.md) (20261110T221247Z) | [8/13](blind/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md) (20261110T174232Z) |
| `pipeline-desktop-opus-run4` | — | [9/13](independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md) (20261110T221303Z) | [8/13](blind/pipeline-desktop-opus-run4/20261110T174255Z/CELL.md) (20261110T174255Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus-run3/20261110T221247Z](independent/pipeline-desktop-opus-run3/20261110T221247Z/CELL.md) | `action_signaling_rho_berkeley_table7_panelA` | 0.851972 | 0.87 | ±0.0174 (relative) | 1.036 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261110T174216Z](blind/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) | `n_obs_berkeley_table5_col2` | 1212 | 1152 | ±57.6 (relative) | 1.042 | FAIL |
| [independent/pipeline-desktop-opus-run4/20261110T221303Z](independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md) | `action_signaling_rho_berkeley_table7_panelA` | 0.850862 | 0.87 | ±0.0174 (relative) | 1.100 | FAIL |
| [seeded/pipeline-desktop-opus/20261110T164936Z](seeded/pipeline-desktop-opus/20261110T164936Z/CELL.md) | `cost_parameter_c_berkeley_table7_panelA` | 0.21441 | 0.21 | ±0.005 (printed_precision) | 0.882 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261110T174232Z](seeded/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md) | `cost_parameter_c_berkeley_table7_panelA` | 0.21441 | 0.21 | ±0.005 (printed_precision) | 0.882 | PASS |
| [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) | `cost_parameter_c_berkeley_table7_panelA` | 0.21441 | 0.21 | ±0.005 (printed_precision) | 0.882 | PASS |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `cost_parameter_c_berkeley_table7_panelA` | 0.21441 | 0.21 | ±0.005 (printed_precision) | 0.882 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261110T174216Z](seeded/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) | `cost_parameter_c_berkeley_table7_panelA` | 0.21441 | 0.21 | ±0.005 (printed_precision) | 0.882 | PASS |
| [independent/pipeline-desktop-opus/20261110T171753Z](independent/pipeline-desktop-opus/20261110T171753Z/CELL.md) | `public_recognition_points_berkeley_table5_col2` | 154.054 | 134.41 | ±22.56 (se_band) | 0.871 | PASS |
| [independent/pipeline-desktop-opus-run4/20261110T221303Z](independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md) | `n_obs_prolific_table5_col1` | 3030 | 2904 | ±145.2 (relative) | 0.868 | PASS |

### Declared deviations

- [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Participant ids are row indices instead of the build's random runiformint ids (used only as cluster identifiers; no effect on point estimates or N).
  - Only the full-sample point estimates of Table 7 are computed; the 1000-rep cluster bootstrap for percentile CIs is not run, since the claims are full-sample point estimates.
- [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Table 7 parameters are reported as full-sample point estimates only; the 1000-rep cluster bootstrap used for the paper's percentile CIs was not run (no CI is claimed).
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (13/13)
  - The 'incoherent preferences' exclusion is not defined operationally in the paper text. I defined coherent as a 0/1 preference-for-recognition pattern over the 18 intervals that is weakly increasing (incl. constant) or single-peaked (0..1..0); decreasing, dipped, or multi-reversal patterns are incoherent. This reproduces the paper's incoherent counts exactly (40 Prolific, 11 Berkeley, 2 BU among attention-check passers) and the 1.0/1.8/1.7% non-monotonic shares among the coherent.
  - Prolific: after attention-check and incoherence exclusions 970 participants remain vs 968 in the paper; I additionally dropped the 2 participants with a missing public-recognition group assignment or missing practice-round record (both scored 0-1 points in the public round). This rule is my guess, not stated in the paper. Prolific anonymous-round mean is 809.7 vs paper 807.9 and Table 6 Prolific estimates are close but not identical, so the Prolific sample likely differs slightly from the authors'.
  - BU sample taken to be the BU QM222 file (121 completes, matching the paper); QM221 is not used.
  - Round-order dummies: position (1st/2nd/3rd) of each round taken from the Condition string (e.g. 'RAE'); dummies for 2nd and 3rd with 1st omitted.
  - Table 7 bootstrapped confidence intervals not computed (only point estimates are claimed).
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - The paper does not spell out the charitable-experiment 'incoherent preference' rule beyond 'analogous to the YMCA analysis' (coherent = monotonically increasing, monotonically decreasing, or single-peaked). Implemented: coherent if the binary preference for recognition is weakly increasing across the 18 intervals, or if the signed WTP profile (WTP for recognition if preferred, minus WTP to avoid it otherwise; budget-limited '_1' answers) is non-constant and weakly decreasing or weakly single-peaked. This yields exactly the paper's exclusion counts for Berkeley (11) and BU (2) but 44 instead of 40 for Prolific (final N 966 vs 968, 2898 vs 2904 observations), and the selected Berkeley/BU individuals evidently differ in part from the authors' (anonymous-round means 985.8 vs 989.8 Berkeley, 830.9 vs 815.9 BU).
  - BU sample = bu_qm222_survey_data.csv (121 completers, matching the paper's BU count); QM221 file not used.
  - Rho uses the average performance under public recognition (anonymous mean + Table 5 col 2 effect) as the reference average, per the claim description; c = (r1 + 2 r2 (a0 + tau)) / tau (Appendix eq. 27); prediction = $0.50 per 100 points / c. Bootstrap CIs not computed (not claimed).
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Prolific sample: after the attention-check and incoherence exclusions 970 participants remain; 2 more (one with missing recog_group_assign, one with missing PracticePts) are dropped to match the paper's stated N=968 and its group-size breakdown (17 groups of 13-15, 6 of 71-79, 1 of 278). The paper does not describe this step.
  - Incoherent preferences are defined on the binary yes/no public-recognition choices over all 18 intervals. Coherent means never switching, a single no->yes switch (monotone increasing), or no->yes->no (single-peaked); every other pattern, including yes->no (decreasing), is incoherent. This reproduces the paper's exclusion counts exactly (40 Prolific, 11 Berkeley, 2 BU) and its non-monotonic shares (1.0/1.8/1.7%).
  - BU sample = bu_qm222_survey_data.csv (121 completers, matching the paper); QM221 (Appendix Table A16) is not used.
  - Prolific sample additionally drops 2 participants with missing recog_group_assign or PracticePts (to reach the paper's N=968)
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (13/13)
  - The paper does not define 'incoherent' preferences for the charity experiments beyond 'analogous to the YMCA analysis'. Final rule, applied to the yes/no recognition choices over the 18 intervals: coherent = weakly increasing (0...01...1, incl. constant) or single-peaked with an interior peak (0..01..10..0); everything else (multiple switches, or recognition wanted only at low scores, 1..10..0) is incoherent. This reproduces the paper's incoherent counts (40 among attention-passers in Prolific, 11 Berkeley, 2 BU), the ~1.0/1.8/1.7% non-monotone shares, and the Table 5 control means (807.9, 989.8, 815.9).
  - Prolific: two participants with a round score above 3000 points (3493/3501 and 3202; every other score in all samples is at most 2521) are dropped as implausible. The paper does not mention this; it was inferred because it yields the paper's final N (968) and control mean (807.9) exactly.
  - Attention check: a participant passes when attention_check is missing (data dictionary).
  - Signed WTP = pref_rec_X_1 if preference_X == 1, else -pref_anom_X_1 (budget-capped answers; the hypothetical _10 columns are not used). Table 6 col (4): OLS of WTP on interval midpoint (hundreds of points) and its square, intervals 0-1699 only, clustered by participant.
  - Table 7 Berkeley: gamma1 = sqrt(r1^2 - 4 r0 r2); rho = (gamma1 - r1)/(2 r2 abar) with abar = anonymous-round mean + Table 5 PR effect (hundreds of points); c = (r1 + 2 r2 (a0 + tau))/tau; predicted financial-incentive effect = 0.50/c ($0.50 per 100 points). The bootstrap in the script (200 participant-block reps) is informational only; the paper uses 1000.
- [independent/pipeline-desktop-opus/20261110T171753Z](independent/pipeline-desktop-opus/20261110T171753Z/CELL.md) (8/13; failed: `financial_incentives_points_prolific_table5_col1`, `action_signaling_gamma1_berkeley_table7_panelA`, `action_signaling_rho_berkeley_table7_panelA`, `cost_parameter_c_berkeley_table7_panelA`, `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - Prolific sample restricted by data-derived screen 'all points > 0' (paper's exact exclusion rule not available in provided text)
  - Berkeley sample restricted by data-derived screen 'all points > 0' (paper's exact exclusion rule not available in provided text)
  - BU sample restricted by data-derived screen 'Sample==BU' (paper's exact exclusion rule not available in provided text)
  - Berkeley structural WTP profile restricted to intervals whose midpoint is within one SD of the change in performance (4.174 hundred points) of the participant's public-recognition score, the online analogue of the paper's within-4-visits restriction
  - Berkeley WTP profile estimated by Tobit with censoring bounds set to observed min/max WTP (-25, 25) since exact bounds are not stated in provided text
- [independent/pipeline-desktop-opus-run2/20261110T221231Z](independent/pipeline-desktop-opus-run2/20261110T221231Z/CELL.md) (10/13; failed: `action_signaling_gamma1_berkeley_table7_panelA`, `cost_parameter_c_berkeley_table7_panelA`, `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - BU sample restricted to the single statistics class file bu_qm222 (paper describes one BU statistics class; combined classes far exceed the reported N)
  - Incoherent participants defined as those whose binary recognition/anonymity choice switches more than twice across performance thresholds (exact rule not given in the provided text)
  - Tobit censoring limits for Berkeley WTP set at the observed minimum and maximum of the elicited WTP (exact limits not given in the provided text)
- [independent/pipeline-desktop-opus-run3/20261110T221247Z](independent/pipeline-desktop-opus-run3/20261110T221247Z/CELL.md) (9/13; failed: `action_signaling_gamma1_berkeley_table7_panelA`, `action_signaling_rho_berkeley_table7_panelA`, `cost_parameter_c_berkeley_table7_panelA`, `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - WTP rebuilt by combining pref_rec (positive) and pref_anom (negative) slider amounts across both slider scales; only participants with no WTP responses or >2 sign switches are treated as incoherent
  - Berkeley structural PRU (Table 7) uses a Tobit fit of WTP on midpoint and midpoint^2 (censored at the slider bounds) instead of OLS, following the paper's use of Tobit censoring assumptions in the structural analysis
  - Berkeley structural Tobit restricted to WTP points whose interval midpoint lies within one SD of the (public - anonymous) change in points of the participant's own public-recognition performance, the online analogue of the paper's within-4-visits restriction used in the structural analysis
  - BU sample is the QM222 statistics class file (one BU statistics class); participants with WTP profiles switching sign more than once are treated as incoherent in this sample
- [independent/pipeline-desktop-opus-run4/20261110T221303Z](independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md) (9/13; failed: `action_signaling_gamma1_berkeley_table7_panelA`, `action_signaling_rho_berkeley_table7_panelA`, `cost_parameter_c_berkeley_table7_panelA`, `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - BU sample uses only the QM222 class file (the paper describes a single BU statistics class); QM221 file not pooled
  - Online samples restricted to attention-check passers with a complete WTP profile; the ad-hoc sign-change incoherence filter (not specified for the online experiments) is no longer applied
  - Structural PRU for Berkeley estimated on WTP points within one SD of the individual public-minus-anonymous change of the participant's own public-round points (online analogue of the paper's within-4-visits restriction used in the structural analysis)
  - Structural PRU for Berkeley estimated by two-limit Tobit (censoring at the WTP bounds observed in the data), per the paper's use of Tobit parametric assumptions for censoring
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (11/13; failed: `cost_parameter_c_berkeley_table7_panelA`, `predicted_financial_incentive_effect_berkeley_table7_panelC`)
  - Prolific final sample is 972 participants under the stated exclusions (attention check + incoherent preferences); the paper reports 968. The 4 extra exclusions could not be identified from the paper's description, so none were applied (n_obs Prolific = 2916).
  - The 'incoherent' rule is not spelled out in the paper. Used: the signed WTP profile's strict preferences (non-zero WTP) must be weakly monotone increasing across the 18 intervals, i.e. a participant may never strictly prefer recognition at a lower interval and strictly prefer anonymity at a higher one; zero WTP is treated as indifference. This rule reproduces exactly the paper's stated incoherent counts (40 Prolific, 11 Berkeley, 2 BU), Berkeley N=384, BU N=118, QM221 N=52, and the stated 1.8% / 1.7% non-monotonic shares among the remaining Berkeley / BU participants.
  - For rho, abar is the average performance with public recognition (anonymous-round mean + Table 5 col 2 PR effect, in hundreds of points), as the quantity definition says; Appendix eq. (22) writes this term as abar0_pop.
  - Point estimates only; the bootstrapped confidence intervals in Table 7 were not computed.
  - Prolific final sample has 972 participants under the stated exclusions (paper reports 968); no further unexplained exclusions applied.
  - rho uses the average with-PR performance (anonymous mean + Table 5 col 2 PR effect) as abar, per the quantity definition.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Prolific final sample is 970 participants (2910 participant-rounds) under my exclusion rules (7 attention-check failures, 40 incoherent among passers); the paper's text states a final Prolific sample of 968. I could not identify a documented rule that drops 2 more participants, so I did not drop any.
  - Bootstrap CIs for Table 7 are computed (1000 participant-level resamples, seed 42) and printed for information only; scored quantities are full-sample point estimates.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Prolific final sample is 970 participants (2910 participant-rounds), not the 968 stated in Section 6.1: applying the attention-check exclusion (7 failures) and the incoherent-preference exclusion (40, matching the paper's notes) leaves 970; no documented rule identifies the 2 further exclusions, so none were made.
  - The 'incoherent' rule is not spelled out for the charity experiments; it was operationalised on the yes/no preference-for-recognition pattern across the 18 intervals: coherent = weakly increasing (incl. constant) or single-peaked; decreasing, U-shaped and multi-switch patterns excluded. This reproduces the stated exclusion counts (40/11/2) and the 1.0/1.8/1.7% non-monotone shares.
  - Table 7 rho uses as reference average the anonymous-round mean plus the Table 5 col (2) public recognition effect (as described in the task), in hundreds of points; bootstrap CIs were not computed (point estimates only).
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (13/13)
  - The paper does not define 'incoherent' preferences operationally. The final script defines it on the yes/no preference-for-recognition profile over the 18 intervals: coherent = constant, a single 0->1 switch (weakly increasing), or single-peaked (0..1..0); anything else (decreasing, U-shaped, multiple switches) is incoherent. With the attention-check exclusion (item left blank = pass) this gives 40/11/2 incoherent exclusions, matching the counts in the table notes, and 384 Berkeley participants, matching the text; Prolific gives 970 participants, 2 more than the 968 the text reports. No further exclusion rule is described in the paper, so none was added.
  - The BU experiment is taken to be the QM222 file only (121 completers, matching the paper's count); bu_qm221_survey_data.csv was not used.
  - WTP is the budgeted response (pref_rec_*_1 if the participant wanted recognition in that interval, minus pref_anom_*_1 otherwise); the hypothetical uncensored follow-ups (*_10) were not used.
  - For rho, the comparison-population average is the anonymous-round mean plus the Table 5 col (2) public-recognition effect (in hundreds of points), as the quantity definition specifies. c = (r1 + 2 r2 (a0 + tau)) / tau (Appendix eq. 27); gamma1 = sqrt(r1^2 - 4 r0 r2); predicted financial effect = 0.50 / c (5 cents per 10 points = $0.50 per hundred points).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `action_signaling_gamma1_berkeley_table7_panelA` — pipeline 0/4, agent 4/4
- independent: `cost_parameter_c_berkeley_table7_panelA` — pipeline 0/4, agent 4/4
- blind: `action_signaling_gamma1_berkeley_table7_panelA` — pipeline 0/4, agent 4/4
- blind: `action_signaling_rho_berkeley_table7_panelA` — pipeline 0/4, agent 4/4
- blind: `n_obs_bu_table5_col3` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- independent: `action_signaling_rho_berkeley_table7_panelA` — pipeline 1/4, agent 4/4
- independent: `predicted_financial_incentive_effect_berkeley_table7_panelC` — pipeline 0/4, agent 3/4
- blind: `cost_parameter_c_berkeley_table7_panelA` — pipeline 0/4, agent 3/4
- blind: `predicted_financial_incentive_effect_berkeley_table7_panelC` — pipeline 0/4, agent 3/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T14:29:00Z; from `claude-code-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T14:35:00Z; from `claude-code-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T164936Z

[`seeded/pipeline-desktop-opus/20261110T164936Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T164936Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T16:49:36Z; from `pipeline-oracle-desktop-opus-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T174216Z

[`seeded/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T17:42:16Z; from `pipeline-oracle-desktop-opus-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T174232Z

[`seeded/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T17:42:32Z; from `pipeline-oracle-desktop-opus-run3-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 7; 2026-11-10T14:31:30Z; from `claude-code-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 8; 2026-11-10T14:35:00Z; from `claude-code-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 9/13; executions 5; 2026-11-10T14:31:00Z; from `claude-code-run3-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 9; 2026-11-10T14:35:30Z; from `claude-code-run4-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T171753Z

[`independent/pipeline-desktop-opus/20261110T171753Z/CELL.md`](independent/pipeline-desktop-opus/20261110T171753Z/CELL.md) — final 8/13, re-scored 8/13; first scored 6/13; executions 5; 2026-11-10T17:17:53Z; from `pipeline-oracle-desktop-opus-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T221231Z

[`independent/pipeline-desktop-opus-run2/20261110T221231Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T221231Z/CELL.md) — final 10/13, re-scored 10/13; first scored 8/13; executions 5; 2026-11-10T22:12:31Z; from `pipeline-oracle-desktop-opus-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T221247Z

[`independent/pipeline-desktop-opus-run3/20261110T221247Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T221247Z/CELL.md) — final 9/13, re-scored 9/13; first scored 5/13; executions 5; 2026-11-10T22:12:47Z; from `pipeline-oracle-desktop-opus-run3-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T221303Z

[`independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T221303Z/CELL.md) — final 9/13, re-scored 9/13; first scored 7/13; executions 5; 2026-11-10T22:13:03Z; from `pipeline-oracle-desktop-opus-run4-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 7; 2026-11-10T14:35:00Z; from `claude-code-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:31:30Z; from `claude-code-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T14:30:30Z; from `claude-code-run3-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:30:30Z; from `claude-code-run4-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T164936Z

[`blind/pipeline-desktop-opus/20261110T164936Z/CELL.md`](blind/pipeline-desktop-opus/20261110T164936Z/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 2; 2026-11-10T16:49:36Z; from `pipeline-oracle-desktop-opus-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T174216Z

[`blind/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T174216Z/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 2; 2026-11-10T17:42:16Z; from `pipeline-oracle-desktop-opus-run2-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T174232Z

[`blind/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T174232Z/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 2; 2026-11-10T17:42:32Z; from `pipeline-oracle-desktop-opus-run3-1paper-butera-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T174255Z

[`blind/pipeline-desktop-opus-run4/20261110T174255Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T174255Z/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 3; 2026-11-10T17:42:55Z; from `pipeline-oracle-desktop-opus-run4-1paper-butera-indep-blind-2026-11-10.json`; evidence complete.

