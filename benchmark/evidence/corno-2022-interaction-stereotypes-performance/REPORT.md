# Evidence report: corno-2022-interaction-stereotypes-performance

**Interaction, Stereotypes, and Performance: Evidence from South Africa** — Lucia Corno, Eliana La Ferrara, Justine Burns

- Paper: https://leap.unibocconi.eu/sites/default/files/media/attach/CornoLaFerraraBurns_manuscript_13jun2022.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/corno-2022-interaction-stereotypes-performance.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T44/174501-V1.zip`; AEA Data and Code Repository on openICPSR, project 174501, version V1 (doi:10.3886/E174501V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T44/174501-V1.zip (16,662,899 bytes, md5 a35ff5adaff7edee4da8a205b13b30bb; SOURCE.txt beside it).  V1 is the only version.  47 zip entries (32 files, 34,759,618 bytes uncompressed), no nested archives, all under ForJournals_a/: README_a.pdf (5 pp., November 2022; data provenance, Stata 17 and ssc packages, run time about 1 h plus 36 h for the FWER p-values, file-to-table map, no estimates); Data/Clean/ with eight Stata .dta files — uctdata_balanced.dta (0.6 MB, the two-round student panel used for Tables 1-6), uctdata_clean.dta, uctdata_dyadic.dta (28 MB, the dyadic file for Table 2 Panel C), ronstudent_sim.dta, new_accommodation_2012.dta, uctdata_tabA2.dta, tabA5.dta and nstudents_fwer.dta (the README also lists uctdata_inter.dta, which is not shipped, and the cleaning do-files it describes are not shipped either); Code/ with 17 Stata do-files (0_main.do, analysis/1_main_tables.do and 2_appendix_tables.do, 4_, 5_, 6_ for appendix tables, 3_fwer_master.do and nine FWER/*.do resampling programs, additional/fdr_sharpened_qvalues.do); programs/ado/ with dyreg.ado, ngreg.ado, qap.ado and ngreg.hlp; Questionnaires/ with the baseline (February 2012) and follow-up (September 2012) survey PDFs (14 pp. each); empty output/ folders (Main, Appendix, FWER, Figures). No log, table or results file ships.  The script-free copy (independent / blind) withholds 20 files (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09): the 17 .do and 3 .ado files by suffix.  Kept: the eight .dta files, the README and questionnaire PDFs and ngreg.hlp, none of which prints a pinned value or SE.  Project page: https://www.openicpsr.org/openicpsr/project/174501/version/V1/view)

> Headline findings: living with a roommate of a different race raises white students' Race IAT by 0.316 (0.140) (Table 3 col 1, N 117; about 0.63 SD, less prejudice against black people) and moves black students' by -0.094 (0.069) (col 2, N 332, not significant).  Black students in mixed rooms gain 0.257 (0.125) SD of GPA, pass 0.645 (0.245) more exams, are 0.152 (0.040) more likely to be eligible to continue, and score 0.443 (0.141) higher on the performance index (Table 4 Panel B); for white students the GPA effect is -0.028 (0.243) (Panel A); in the full sample (N 499; 498 for cols 3-4) 0.147 (0.102) GPA, 0.447 (0.204) exams and 0.289 (0.113) index (Panel C).
> Paper text and how it was verified.  The published article was not read (paywalled; no open copy found).  The source is the authors' June 2022 manuscript (post-referee; thanks the editor and three referees).  The meta-database records exactly two published cells, both checked against the same manuscript cells: Table 3 col 1 Mixed Room 0.316, SE 0.140 (the manuscript prints this SE without parentheses; in the rendered table it sits in the SE row under the coefficient) and Table 4 Panel B col 1 0.257 (0.125).  The body text repeats both (0.316 in Sec. 5.1; 0.257 in Sec. 5.2) and the white-student GPA cell (-0.028, SE 0.243).  No meta-database typo was found (o_p_value 0.047 / 0.041 vs the manuscript's Westfall-Young p-values 0.055 / 0.040 in square brackets: the meta-database p-values are the conventional ones, not printed in the table).  The other pinned cells are not covered by any I4R row; they are pinned from this late revision because its I4R-covered cells match.  The package's uctdata_balanced.dta has 499 follow-up rows, 117 white and 332 black, and 498 with continue / PCAperf non-missing, which equal the manuscript's Table 3 and Table 4 N rows.  The 2018 IFS WP and the 2015 drafts print different estimates and were not used.
> Curation pass (2026-11-09).  13 claims.  Left out: the Academic IAT columns of Table 3 (null, kept the Race IAT), the Westfall-Young adjusted p-values, the UCT admission score rows and the interaction row of Table 4, Panel A columns 2-4 (white students, all insignificant), Panel C column 3, the dependent-variable means and R-squared, Table 1 (descriptive), Table 2 (balance and the dyadic sorting regression), Tables 5-6 (friendships, attitudes, prosocial behaviour, residential choice; ordered logits and indices built by principal components), and all appendix tables.
> Package-only facts (never in contexts).  Code/analysis/1_main_tables.do, "TABLE 3": use Data/Clean/uctdata_balanced.dta; xtset individual round; xi: reg DscoreraceIAT mixracebas L.DscoreraceIAT `controls_subsample' `rocontrols' i.Res_base if round==2 & white==1 (black==1), robust cluster(roomnum_base).  controls_subsample = Female Falseuct2012 missfalse Foreign foreign_missing privateschool_nomiss privateschool_miss durpcabas_nomiss durpcabas_miss consbas_nomiss consbas_miss; rocontrols = roFalseuct2012 missrofalse roForeign_bas roforeign_missingbas roprivschool_nomiss roprivschool_miss rodurpcabas_nomiss rodurpcabas_miss roconsbas_nomiss roconsbas_miss. "TABLE 4": outcomes GPA examspassed continue PCAperf; subsamples add i.regprogram to the Table 3 regressors without the lag; the full sample uses `controls' (adds white coloured Else) and i.blackRes i.whiteRes i.Res_base i.regprogram.  The FWER p-values come from separate resampling do-files (seed 3005; about 36 h), not needed for any pinned claim.
> Blind-mode exposure (step 6, 2026-11-09).  Both modes reached the generation prompt and stopped as llm_answer_pending (oracle label, no API calls; the methodology-summary and hyperparameter prompts answered by the curator without results).  The blind generation prompt states no pinned value or SE at printed precision or rounded to 1-3 significant figures (the only hit, "117", is the file size "117.2 KB" of new_accommodation_2012.dta in the dataset listing) and carries no do-file text; the listing names the eight .dta files and their columns (mixracebas, roomnum_base, the ro* roommate controls and the missing-value dummies are data columns).  The abstract prints no numbers.  The paper text given to the methodology summariser carries the body-text statements of three pinned cells (0.316 in Sec. 5.1, 0.257 and -0.028 (0.243) in Sec. 5.2) and the working-sample size in the introduction and Sec. 3; the summariser is told to leave results out, and the README's blind-mode caveat covers this.  The parser takes "Interaction, Stereotypes and Performance." as the title.
> What was read.  The June 2022 manuscript pp. 1-20 and Tables 1-6; the 2018 IFS WP Table 4 (Race IAT) block; the 2015 CERGE-EI title page; the 41 meta-database rows; README_a.pdf; the Table 3-4 blocks of 1_main_tables.do and 0_main.do; the row counts of uctdata_balanced.dta; the strip-rule classification of the extracted package.
> What could not be verified.  The published article itself (its tables and notes) was not read; 11 of the 13 pinned values rest on the June 2022 manuscript alone.  The authors' Stata code was not run (no Stata here) and no R cross-check of the coefficients was made.
> Original analysis in Stata 17 (xi: reg, xml_tab, estout); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `race_iat_mixed_room_whites_table3_col1` | 0.316 | 0.14 | Table 3, Race IAT, Whites, column (1), Mixed Room | 0.316 | matches |
| 1 | `race_iat_mixed_room_blacks_table3_col2` | -0.094 | 0.069 | Table 3, Race IAT, Blacks, column (2), Mixed Room | — | — |
| 2 | `n_obs_table3_whites` | 117 | — | Table 3, No. Obs., columns (1) and (3) (Whites) | — | — |
| 3 | `n_obs_table3_blacks` | 332 | — | Table 3, No. Obs., columns (2) and (4) (Blacks) | — | — |
| 4 | `gpa_mixed_room_blacks_table4_panelB_col1` | 0.257 | 0.125 | Table 4, Panel B: Blacks, column (1) GPA, Mixed Room | 0.257 | matches |
| 5 | `exams_passed_mixed_room_blacks_table4_panelB_col2` | 0.645 | 0.245 | Table 4, Panel B: Blacks, column (2) Number of exams passed, Mixed Room | — | — |
| 6 | `eligible_mixed_room_blacks_table4_panelB_col3` | 0.152 | 0.04 | Table 4, Panel B: Blacks, column (3) Eligible to continue, Mixed Room | — | — |
| 7 | `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.443 | 0.141 | Table 4, Panel B: Blacks, column (4) Index of Academic Performance, Mixed Room | — | — |
| 8 | `gpa_mixed_room_whites_table4_panelA_col1` | -0.028 | 0.243 | Table 4, Panel A: Whites, column (1) GPA, Mixed Room | — | — |
| 9 | `gpa_mixed_room_full_table4_panelC_col1` | 0.147 | 0.102 | Table 4, Panel C: Full Sample, column (1) GPA, Mixed Room | — | — |
| 10 | `exams_passed_mixed_room_full_table4_panelC_col2` | 0.447 | 0.204 | Table 4, Panel C: Full Sample, column (2) Number of exams passed, Mixed Room | — | — |
| 11 | `performance_index_mixed_room_full_table4_panelC_col4` | 0.289 | 0.113 | Table 4, Panel C: Full Sample, column (4) Index of Academic Performance, Mixed Room | — | — |
| 12 | `n_obs_table4_panelC_cols1_2` | 499 | — | Table 4, Panel C: Full Sample, No. Obs., columns (1)-(2) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [13/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [13/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T165716Z/CELL.md) (20261110T165716Z) | [12/13](independent/pipeline-desktop-opus/20261110T164952Z/CELL.md) (20261110T164952Z) | [8/13](blind/pipeline-desktop-opus/20261110T164114Z/CELL.md) (20261110T164114Z) |
| `pipeline-desktop-opus-run2` | [7/13](seeded/pipeline-desktop-opus-run2/20261110T221318Z/CELL.md) (20261110T221318Z) | [13/13](independent/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) (20261110T172213Z) | [10/13](blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) (20261110T172213Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T212811Z/CELL.md) (20261110T212811Z) | [13/13](independent/pipeline-desktop-opus-run3/20261110T174309Z/CELL.md) (20261110T174309Z) | [10/13](blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md) (20261110T172220Z) |
| `pipeline-desktop-opus-run4` | — | [13/13](independent/pipeline-desktop-opus-run4/20261110T174317Z/CELL.md) (20261110T174317Z) | [13/13](blind/pipeline-desktop-opus-run4/20261110T171229Z/CELL.md) (20261110T171229Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-run2/20261110T172213Z](blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) | `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.30025 | 0.443 | ±0.141 (se_band) | 1.012 | FAIL |
| [blind/pipeline-desktop-opus-run3/20261110T172220Z](blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md) | `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.298085 | 0.443 | ±0.141 (se_band) | 1.028 | FAIL |
| [independent/pipeline-desktop-opus/20261110T164952Z](independent/pipeline-desktop-opus/20261110T164952Z/CELL.md) | `performance_index_mixed_room_full_table4_panelC_col4` | 0.188587 | 0.289 | ±0.113 (se_band) | 0.889 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261110T221318Z](seeded/pipeline-desktop-opus-run2/20261110T221318Z/CELL.md) | `gpa_mixed_room_full_table4_panelC_col1` | 0.149477 | 0.147 | ±0.00294 (relative) | 0.842 | PASS |
| [blind/pipeline-desktop-opus-run3/20261110T172220Z](blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md) | `exams_passed_mixed_room_full_table4_panelC_col2` | 0.277073 | 0.447 | ±0.204 (se_band) | 0.833 | PASS |
| [blind/pipeline-desktop-opus-run2/20261110T172213Z](blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) | `exams_passed_mixed_room_full_table4_panelC_col2` | 0.279613 | 0.447 | ±0.204 (se_band) | 0.821 | PASS |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `performance_index_mixed_room_blacks_table4_panelB_col4` | 0.557987 | 0.443 | ±0.141 (se_band) | 0.816 | PASS |
| [blind/pipeline-desktop-opus-run2/20261110T172213Z](blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) | `gpa_mixed_room_full_table4_panelC_col1` | 0.071044 | 0.147 | ±0.102 (se_band) | 0.745 | PASS |
| [blind/pipeline-desktop-opus-run3/20261110T172220Z](blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md) | `gpa_mixed_room_full_table4_panelC_col1` | 0.0745333 | 0.147 | ±0.102 (se_band) | 0.710 | PASS |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `performance_index_mixed_room_full_table4_panelC_col4` | 0.367585 | 0.289 | ±0.113 (se_band) | 0.695 | PASS |

### Declared deviations

- [seeded/pipeline-desktop-opus/20261110T165716Z](seeded/pipeline-desktop-opus/20261110T165716Z/CELL.md) (13/13)
  - roconsbas_miss (roommate consumption missing dummy) absent from data; reconstructed from roommate's consbas_miss / mean-imputed roconsbas_nomiss
- [seeded/pipeline-desktop-opus-run2/20261110T221318Z](seeded/pipeline-desktop-opus-run2/20261110T221318Z/CELL.md) (7/13; failed: `gpa_mixed_room_blacks_table4_panelB_col1`, `exams_passed_mixed_room_blacks_table4_panelB_col2`, `eligible_mixed_room_blacks_table4_panelB_col3`, `performance_index_mixed_room_blacks_table4_panelB_col4`, `gpa_mixed_room_whites_table4_panelA_col1`, `exams_passed_mixed_room_full_table4_panelC_col2`)
  - Table 4 regressions keep own private-school controls but drop roommate private-school controls (paper's control list is ambiguous; full and paper-stated sets bracket the reported values)
- [seeded/pipeline-desktop-opus-run3/20261110T212811Z](seeded/pipeline-desktop-opus-run3/20261110T212811Z/CELL.md) (13/13)
  - roconsbas_miss not found; used variable 'roconsbas_missing' as roommate consumption missing indicator
- [independent/pipeline-desktop-opus/20261110T164952Z](independent/pipeline-desktop-opus/20261110T164952Z/CELL.md) (12/13; failed: `eligible_mixed_room_blacks_table4_panelB_col3`)
  - Coded missing eligibility as 0 for students with exam records
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Academic performance index uses the dataset's provided PCAperf variable (labelled 'Performance index 2012, PCA'); a PCA I computed on standardized GPA, exams passed and eligible-to-continue in the working sample correlates 0.995 with it but is not identical (different scaling/sample), so the provided index was preferred as the authors' construction of the paper's definition.
  - GPA uses the dataset's provided standardized GPA (mean -0.01, SD 1.005 in the working sample) without re-standardizing.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Performance index: used the dataset's provided PCAperf variable (first principal component of GPA, exams passed, eligible to continue) rather than recomputing it; a PC1 recomputed on the 498-student working sample correlates 0.995 with PCAperf but has a different scale (sd ratio 1.18), so it was printed as an unscored robustness line only.
  - GPA: used the dataset's provided standardized GPA variable (standardized on a sample broader than the 499-student working sample; mean -0.01 in it).
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Academic performance index computed by us as the first principal component (correlation-matrix PCA, prcomp with scaling, sign set to correlate positively with GPA) of GPA, exams passed and eligible to continue over the 498 working-sample students with all three non-missing. The dataset's own PCAperf variable correlates 0.995 with it but has a smaller SD (1.15 vs 1.36), so it was apparently computed on a different sample or normalisation; we did not use it.
  - GPA used as provided (variable GPA, already standardized in the data file; SD 1.005 in the working sample); not re-standardized.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (13/13)
  - Academic performance index uses the dataset's provided PCAperf variable (first principal component of GPA, exams passed, eligible to continue) rather than recomputing the PCA.
  - GPA uses the dataset's provided standardized GPA variable as is.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `eligible_mixed_room_blacks_table4_panelB_col3` — pipeline 1/4, agent 4/4
- blind: `performance_index_mixed_room_blacks_table4_panelB_col4` — pipeline 1/4, agent 4/4
- blind: `performance_index_mixed_room_full_table4_panelC_col4` — pipeline 2/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T14:40:00Z; from `claude-code-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T14:35:30Z; from `claude-code-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T165716Z

[`seeded/pipeline-desktop-opus/20261110T165716Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T165716Z/CELL.md) — final 13/13, re-scored 13/13; first scored 6/13; executions 2; 2026-11-10T16:57:16Z; from `pipeline-oracle-desktop-opus-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T221318Z

[`seeded/pipeline-desktop-opus-run2/20261110T221318Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T221318Z/CELL.md) — final 7/13, re-scored 7/13; first scored 6/13; executions 3; 2026-11-10T22:13:18Z; from `pipeline-oracle-desktop-opus-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T212811Z

[`seeded/pipeline-desktop-opus-run3/20261110T212811Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T212811Z/CELL.md) — final 13/13, re-scored 13/13; first scored 6/13; executions 2; 2026-11-10T21:28:11Z; from `pipeline-oracle-desktop-opus-run3-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T14:36:30Z; from `claude-code-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T14:36:30Z; from `claude-code-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T14:36:30Z; from `claude-code-run3-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:37:30Z; from `claude-code-run4-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T164952Z

[`independent/pipeline-desktop-opus/20261110T164952Z/CELL.md`](independent/pipeline-desktop-opus/20261110T164952Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-10T16:49:52Z; from `pipeline-oracle-desktop-opus-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T172213Z

[`independent/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T17:22:13Z; from `pipeline-oracle-desktop-opus-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T174309Z

[`independent/pipeline-desktop-opus-run3/20261110T174309Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T174309Z/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 2; 2026-11-10T17:43:09Z; from `pipeline-oracle-desktop-opus-run3-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T174317Z

[`independent/pipeline-desktop-opus-run4/20261110T174317Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T174317Z/CELL.md) — final 13/13, re-scored 13/13; first scored 10/13; executions 2; 2026-11-10T17:43:17Z; from `pipeline-oracle-desktop-opus-run4-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:37:00Z; from `claude-code-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T14:37:00Z; from `claude-code-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:37:30Z; from `claude-code-run3-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T14:36:40Z; from `claude-code-run4-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T164114Z

[`blind/pipeline-desktop-opus/20261110T164114Z/CELL.md`](blind/pipeline-desktop-opus/20261110T164114Z/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 1; 2026-11-10T16:41:14Z; from `pipeline-oracle-desktop-opus-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T172213Z

[`blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T172213Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-10T17:22:13Z; from `pipeline-oracle-desktop-opus-run2-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T172220Z

[`blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T172220Z/CELL.md) — final 10/13, re-scored 10/13; first scored 10/13; executions 1; 2026-11-10T17:22:20Z; from `pipeline-oracle-desktop-opus-run3-1paper-corno-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T171229Z

[`blind/pipeline-desktop-opus-run4/20261110T171229Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T171229Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T17:12:29Z; from `pipeline-oracle-desktop-opus-run4-1paper-corno-indep-blind-2026-11-10.json`; evidence complete.

