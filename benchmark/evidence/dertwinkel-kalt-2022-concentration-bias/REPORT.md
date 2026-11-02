# Evidence report: dertwinkel-kalt-2022-concentration-bias

**Concentration Bias in Intertemporal Choice** — Markus Dertwinkel-Kalt, Holger Gerhardt, Gerhard Riener, Frederik Schwerter, Louis Strang

- Paper: https://www.econtribute.de/RePEc/ajk/ajkdps/ECONtribute_076_2021.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/272844/1/I4R-DP042.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/dertwinkel-kalt-2022-concentration-bias.yaml`

> Headline finding: in a lab experiment where subjects trade extra real-effort tasks on eight future workdays against a larger restaurant voucher, the indifference point in an unbalanced trade-off (extra tasks on all eight days for the summed voucher raise) exceeds what the eight balanced trade-offs imply: concentration bias raises the per-workday willingness to work by 22.4% (Table 2).  Table 3 shows the effect is smaller when the voucher raise is framed as a sum of parts (Mechanism-Treatment), present with donations, and absent in the Control conditions that repeat a balanced trade-off.
> Original analysis in Stata (do-files last run in Stata 17); R is used in the package only for the Section 4 / Appendix C calibration exercise (Calibration Exercise.R), which produces no pinned number. language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 13 claims: Table 2 columns 2 and 4 of the absolute measure, all three columns of the relative measure, Table 3's three Treatment-vs-Control / Main-vs-Mechanism differences plus the Mechanism-Treatment and Donation-Treatment levels, and the two observation counts (Table 2: 100 in every column; Table 3: 200 in every column).  Each coefficient carries its robust SE as standard_error. Left out to stay within 13: Table 2 columns 1 and 3 of the absolute measure (31.640 (2.685), 43.580 (4.683); both reproduced exactly by I4R, rows 629 / 643) and the two Control-condition levels in Table 3 (Main-Control -0.023 (0.008), Mechanism-Control -0.014 (0.010)).
> Paper version and published-vs-DP check.  The PDF is ECONtribute DP 076 (1 April 2021); the REStud typeset version could not be obtained.  The DP's Table 2 and Table 3 carry the same table numbers as the published article (the I4R database labels them "table 2" / "table 3"; DP42 cites "Table 2/3 of DGRSS") and every pinned value equals the database's o_coeff / o_std_err in magnitude.  Signs: the database (and DP42's transcription of the published Table 3, Panel A) records the Donation difference as -0.158, Main-Control as +0.023 and the Main difference as -0.247, where the DP prints 0.158, -0.023 and 0.247.  The package (the published version's REStud replication package, July 2021) settles it: its log gives control = -0.1576 with the comment "the difference Donation-Treatment - Donation-Control that is reported in the manuscript (0.158) is positive", and treatment = +0.2467 with constant -0.0226 for Main; the DP's signs are internally consistent (Main-Control + difference = Main-Treatment mean 0.224), the database's are not.  The paper's signs are pinned.  Appendix numbering differs: in the DP the money experiment is Appendix C (Table C.1 reports 0.063 (0.011), N = 277, 185 subjects) while the published version and the package README put the calibration in Appendix C and the money experiment in Appendix D (Tables D1-D4; the database's "appendix table d.1" rows are 0.057 / 0.068 / 0.081 / 0.066 / 0.026 / 0.065 / 0.036, which the DP does not print in that form) — the money appendix was revised between the DP and publication; none of it is pinned.
> What was read.  The DP 076 PDF (Sections 2-4, Tables 1-3, appendix headings); DP42 in full (EconStor, 17 pp.; its IDEAS listing zbw/i4rdps/42); the Zenodo API metadata for both package versions; the package README.md, the consumption do-file in full and its log for Tables 2-3, the money do-file header, the .csv headers; the 32 I4R database rows for the paper (team 15; 31 with values, one empty).
> How the printed numbers are produced (package-only; never in contexts).  Consumption_Experiment tables and values.do, lines 70-114 (README: log lines 122-394), produces Tables 2 and 3; the money do-file produces only Section 5 / Appendix D numbers, the figures do-file only figures.  It reads Consumption_Experiment.csv with import delimited.  The csv is long: nine rows per subject (decision_number 1-8 balanced, 9 the final trade-off) and the subject-level outcomes (id_stage2, avg_id_stage2, id_stage2_upper, qe_ard, qe_ard_lower, qe_ard_upper, qe_rad*) are non-missing only on the decision_number == 9 row (769 subjects), so the regressions run on one row per subject without an explicit filter.  Main sample: pap_sample == 1.  Table 2: reg id_stage2 / avg_id_stage2 / id_stage2_upper and qe_ard_lower / qe_ard / qe_ard_upper on a constant, if pap_sample == 1 & dispersed == 0 & treatment == 1, r (HC1); col 4 is tobit id_stage2, ll(-63) ul(63) with conventional (non-robust) SEs (log: 73 uncensored, 27 right-censored).  Table 3: reg qe_ard main if pap_sample == 1 & treatment == 1, r (col 1); reg qe_ard control if pap_sample == 1 & pizza == 0, r (col 2; coefficient -0.158, sign flipped in print); reg qe_ard treatment if pap_sample == 1 & pizza == 1 & dispersed == 0 (col 3) / dispersed == 1 (col 4), r.  dispersed is missing for the Donation conditions.  Condition sizes before exclusion (subjects): Main-Treatment 135, Main-Control 135, Mechanism-Treatment 123, Mechanism-Control 125, Donation-Treatment 122, Donation-Control 128; 100 of each in pap_sample.  The relative measure is pre-computed in the csv; recomputing it from indifference_point and the mandatory-task vector (paper fn. 3) reproduces it only up to the third decimal (DP42 Figure 1: differences for negative d~rel, rounding / corner handling).
> Benchmark implications.  Seeded mode is close to a transcription of eight one-line regressions.  Independent/blind mode needs the model to find the right csv among ~370 files (oTree/z-Tree noise; the task's file listing truncates after ~80 entries, mostly oTree files, though the consumption csv and its columns are listed before the cut), map the paper's conditions to main / dispersed / pizza / treatment / control and the exclusion to pap_sample, and pick the pre-computed outcome columns (or recompute d~rel and land within the printed rounding).  A sign trap: column 2's difference needs Treatment minus Control. Blind caveat (curation render 2026-10-21, 153 paper redactions, 53 files stripped — every .do/.R/.log and the oTree .py sources): the redacted paper.txt still states three pinned values as percentages — "22.4%" (claim 3, abstract, intro, Section 2.4, Result 1), "7.5%" (claim 6) and "13.5%" (claim 8) — because the blind redactor matches decimal forms only (0.224, not 22.4).  Blind passes on claims 3, 6 and 8 are therefore not target-free for this entry.
> Left out.  Table 1 (design), the Section 3 / 4 tests reported only in the text, Appendix A (full sample, heterogeneity, alternative relative measure), the money experiment (Section 5 / Appendix D; revised since the DP, and its csv lacks the raw choices per DP42), and the calibration exercise (Appendix C, R, 1-8 h runtime).

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `abs_concentration_bias_midpoint_table2_col2` | 37.61 | 3.575 | Table 2, column 2 (OLS, Midpoint), row 'd~ in Main-Treatment' | 37.61 | matches |
| 1 | `abs_concentration_bias_tobit_table2_col4` | 37.094 | 3.658 | Table 2, column 4 (Tobit), row 'd~ in Main-Treatment' | 37.094 | matches |
| 2 | `rel_concentration_bias_lower_table2_col1` | 0.19 | 0.016 | Table 2, column 1 (OLS, Lower bound), row 'd~rel in Main-Treatment' | 0.19 | matches |
| 3 | `rel_concentration_bias_midpoint_table2_col2` | 0.224 | 0.021 | Table 2, column 2 (OLS, Midpoint), row 'd~rel in Main-Treatment' | 0.224 | matches |
| 4 | `rel_concentration_bias_upper_table2_col3` | 0.259 | 0.027 | Table 2, column 3 (OLS, Upper bound), row 'd~rel in Main-Treatment' | 0.259 | matches |
| 5 | `n_obs_table2` | 100 | — | Table 2, Observations (all four columns) | — | — |
| 6 | `rel_cb_mechanism_treatment_table3_col1` | 0.075 | 0.019 | Table 3, column 1, row 'd~rel in Mechanism-Treatment' | 0.075 | matches |
| 7 | `diff_main_minus_mechanism_table3_col1` | 0.149 | 0.028 | Table 3, column 1, row 'Difference: Main-Treatment - Mechanism-Treatment' | 0.149 | matches |
| 8 | `rel_cb_donation_treatment_table3_col2` | 0.135 | 0.021 | Table 3, column 2, row 'd~rel in Donation-Treatment' | 0.135 | matches |
| 9 | `diff_donation_treatment_minus_control_table3_col2` | 0.158 | 0.022 | Table 3, column 2, row 'Difference: Donation-Treatment - Donation-Control' | 0.158 | matches |
| 10 | `diff_main_treatment_minus_control_table3_col3` | 0.247 | 0.023 | Table 3, column 3, row 'Difference: Main-Treatment - Main-Control' | 0.247 | matches |
| 11 | `diff_mechanism_treatment_minus_control_table3_col4` | 0.09 | 0.021 | Table 3, column 4, row 'Difference: Mechanism-Treatment - Mechanism-Control' | 0.09 | matches |
| 12 | `n_obs_table3` | 200 | — | Table 3, Observations (all four columns) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a) | [13/13](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [13/13](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [13/13](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) | [12/13](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [13/13](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [13/13](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus/20261023T062931Z](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `n_obs_table3` | 202 | 200 | ±2 (relative) | 1.000 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `n_obs_table3` | 202 | 200 | ±2 (relative) | 1.000 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `n_obs_table3` | 202 | 200 | ±2 (relative) | 1.000 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `n_obs_table3` | 202 | 200 | ±2 (relative) | 1.000 | PASS |
| [seeded/pipeline-desktop-opus/20261023T063725Z](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) | `rel_cb_mechanism_treatment_table3_col1` | 0.0754251 | 0.075 | ±0.0015 (relative) | 0.283 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261023T151837Z](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `rel_cb_mechanism_treatment_table3_col1` | 0.0754251 | 0.075 | ±0.0015 (relative) | 0.283 | PASS |
| [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) | `rel_cb_mechanism_treatment_table3_col1` | 0.075425 | 0.075 | ±0.0015 (relative) | 0.283 | PASS |
| [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) | `diff_donation_treatment_minus_control_table3_col2` | 0.1625 | 0.158 | ±0.022 (se_band) | 0.205 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `diff_donation_treatment_minus_control_table3_col2` | 0.162486 | 0.158 | ±0.022 (se_band) | 0.204 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `diff_donation_treatment_minus_control_table3_col2` | 0.162486 | 0.158 | ±0.022 (se_band) | 0.204 | PASS |

### Declared deviations

- [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) (13/13)
  - Main sample: the corner-choice exclusion built from the raw balanced decisions keeps 607 subjects; 7 of them (tn 523, 526, 527, 541, 542, 544, 1239) are not flagged by the dataset's pap_sample indicator. The final run uses pap_sample==1 (a strict subset of the corner exclusion), which yields exactly 100 subjects per condition as in the paper. This change followed the claim comparison of attempt-2 (n_obs_table3 203 vs 200). — names `n_obs_table3`
  - Ends of the unbalanced elicitation range are coded -63/+63 in the data (the paper text says the upper end is 62); the lower-bound measure and the Tobit censoring points use the data's -63/+63 coding.
- [independent/claude-code/2026-11-01-a](independent/claude-code/2026-11-01-a/CELL.md) (13/13)
  - Upper-corner subjects' lower bound taken as the recorded id_stage2 value (63) rather than 62 as stated in the paper text; Tobit right-censoring point set to 63 accordingly.
  - Main sample taken from the data's preregistered-sample flag pap_sample (100 per condition); a pure 'no corner in any balanced trade-off' filter leaves 100-103 per condition (the extra subjects are presumably dropped by the stratified pairing in fn. 14).
  - Control conditions: d~rel computed with the same eq. (12) formula (average over all 8 workdays) as treatment conditions; the paper does not spell out the control-condition denominator.
  - upper-corner lower bound taken as recorded id_stage2 (=63) rather than 62 as in paper text; Tobit right-censoring at 63
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (13/13)
  - Upper-corner choices in the unbalanced trade-off use a lower bound of 63, the value the dataset assigns to upper corners (interior values run to 61; stated indifference points start at 63), instead of the 62 given in the paper text. With 62, the Main-Treatment midpoint mean of d would be 37.475 instead of 37.61. This sensitivity is printed as a DEVIATION line.
  - Tobit (Table 2 col 4) uses censoring points -63 (lower corner) and 63 (upper corner, matching the coding above), via AER::tobit.
  - Control conditions: the relative measure is d/(e_j + x_j) for the repeated workday j only, not the eight-day average of eq. 12, because in Control the deviation applies only to workday j. Rebuilt from the raw data, this matches the dataset's precomputed qe_ard.
  - upper-corner lower bound taken as 63 (dataset coding of upper corners) rather than 62 (paper text); with 62 the Main-Treatment mean midpoint d would be 37.4750
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (13/13)
  - n_obs_table3 reports the column-1 N (Main-Treatment + Mechanism-Treatment); all four columns have N = 200 in this reproduction. — names `n_obs_table3`
  - Control conditions: the relative measure is d / (e_j + x_j) on the repeated workday j (the paper's eq. 12 is defined for the Treatment conditions, where the deviation applies to all eight workdays).
  - Main sample = subjects with no corner choice in any balanced trade-off AND pap_sample == 1 (the dataset's preregistered-sample flag). This drops 7 more corner-free subjects, all from late sessions 18-19 plus one Donation-Control subject, and leaves exactly 100 subjects per condition. None of the 7 is in Main-Treatment.
  - n_obs_table3 reports column 1's N; the per-column Ns are printed above. — names `n_obs_table3`

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `rel_concentration_bias_lower_table2_col1` — pipeline 1/2, agent 2/2

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-22T03:04:00Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 3; 2026-10-22T03:11:30Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T04:30:30Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T062931Z

[`independent/pipeline-desktop-opus/20261023T062931Z/CELL.md`](independent/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T151837Z

[`independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-10-22T03:21:00Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-02T04:45:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

