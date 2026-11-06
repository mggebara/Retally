# Evidence report: carrera-2022-who-chooses-commitment

**Who Chooses Commitment? Evidence and Welfare Implications** — Mariana Carrera, Heather Royer, Mark Stehr, Justin Sydnor, Dmitry Taubinsky

- Paper: https://www.nber.org/system/files/working_papers/w26161/w26161.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/carrera-2022-who-chooses-commitment.yaml`
- Data access: public

> Headline finding: in a gym-attendance field experiment, an enhanced information treatment that made participants more aware of their present focus raised the behavior change premium (Table 3 col 1: +1.36, SE 0.57, from an information-control mean of 0.66) but LOWERED take-up of "more visits" commitment contracts (Table 4 col 1: -0.080, SE 0.031); take-up is only weakly related to the behavior change premium (0.027 per SD) and rises with over-optimism (actual minus expected attendance, -0.043 per SD).
> Curation pass (2026-11-01).  Pinned 11 claims: Table 3 col 1 basic and enhanced information effects, col 2 goal-expected gap, col 3 actual-expected gap (each with its robust SE); Table 4 col 1 basic and enhanced effects, col 2 behavior change premium, col 3 goal-expected gap, col 4 actual-expected gap (each with its subject-clustered SE); the Table 3 N (1,126 participants; also the Table 4 cluster count, not pinned separately) and the Table 4 N (2,824 participant x threshold choices).  Left out: the information-treatment coefficients in Table 3 cols 2-3 (0.45 (0.57), 1.41 (0.58); 0.28 (0.56), 1.25 (0.59)) and Table 4 cols 2-4 (-0.023/-0.086, -0.013/-0.079, -0.019/-0.072), the dependent-variable means (1.17 (0.22) and 0.66 (0.24) in Table 3; 0.49 (0.01) and 0.52 (0.01) in Table 4), Table 2 summary statistics (N = 1,248 participants after the 44 endogenous-assignment exclusions), Table 5 take-up rates (no I4R row to check the open text against), Table 6 (wave 3 beliefs), the in-text averages ($2.01 / $1.20 behavior change premium) and everything structural (Tables 7-9, MATLAB).  The Table 3 sample excludes the 122 wave 3 participants assigned a commitment contract (1,248 - 122 = 1,126); the contexts state neither count.
> Cross-check.  Every pinned value and SE equals the I4R o_coeff_dbl / o_std_err_dbl (published tables), the NBER August 2021 text, and the package's own estout output (regs_avg_delta_ex1_all.tex, regs_commit_pooled_all.tex).  The numbers.tex macros also carry 1.36, 0.71, 0.45 (the Table 3 in-text coefficients) and 8.0 / 3 / 3.8 (Table 4 coefficients x 100).
> Package specification (package-only facts; never in contexts). Tables.do lines 225-423: gap_goal_exp = goal - days_0; gap_actual_exp = visits - days_exp; delta_k = (wtp_k - wtp_{k-1})/(k - (k-1)) - (days_k + days_{k-1})/2 for the adjacent incentive pairs 1-2, 2-3, 3-5, 5-7, 7-12, avg_delta_ex1 their mean; sample `!missing(incentive)`; the three variables are z-scored over that sample.  Table 3: `reg avg_delta_ex1 wave2 wave3 first_info new_info [z_gap_goal_exp | z_gap_actual_exp] if !missing(incentive), r`.  Table 4: `reshape long commit, i(id) j(t)` then `reg commit i.t wave2 wave3 [z_avg_delta_ex1 | z_gap_goal_exp | z_gap_actual_exp] first_info new_info if !missing(incentive), vce(cluster id)`.  first_info / new_info are the basic (wave 1) and enhanced (waves 2-3) information indicators.
> What could not be verified.  The published REStud PDF was not read (OUP refuses non-browser clients); the NBER revision's Tables 3-4 match every I4R published-value row, and the package output matches both.  The do-files were not run and no independent re-estimate was done; the I4R team's perfect-reproduction verdict is the evidence.
> Original analysis in Stata 14 (reduced form) and MATLAB R2019a (structural simulations, out of scope); language is r, the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `bcp_basic_info_treatment_col1` | 0.3 | 0.56 | Table 3, column (1), Basic info. treatment | 0.3 | matches |
| 1 | `bcp_enhanced_info_treatment_col1` | 1.36 | 0.57 | Table 3, column (1), Enhanced info. treatment | 1.36 | matches |
| 2 | `bcp_goal_minus_expected_attendance_col2` | 0.71 | 0.29 | Table 3, column (2), Goal - exp. attend. (z-score) | 0.71 | matches |
| 3 | `bcp_actual_minus_expected_attendance_col3` | 0.45 | 0.22 | Table 3, column (3), Actual - exp. attend. (z-score) | 0.45 | matches |
| 4 | `bcp_regression_observations` | 1126 | — | Table 3, N | 1126 | matches |
| 5 | `takeup_more_basic_info_treatment_col1` | -0.022 | 0.041 | Table 4, column (1), Basic info. treatment | -0.022 | matches |
| 6 | `takeup_more_enhanced_info_treatment_col1` | -0.08 | 0.031 | Table 4, column (1), Enhanced info. treatment | -0.08 | matches |
| 7 | `takeup_more_behavior_change_premium_col2` | 0.027 | 0.011 | Table 4, column (2), Behavior change premium (z-score) | 0.027 | matches |
| 8 | `takeup_more_goal_minus_expected_attendance_col3` | 0.038 | 0.013 | Table 4, column (3), Goal - exp. attend. (z-score) | 0.038 | matches |
| 9 | `takeup_more_actual_minus_expected_attendance_col4` | -0.043 | 0.013 | Table 4, column (4), Actual - exp. attend. (z-score) | -0.043 | matches |
| 10 | `takeup_more_regression_observations` | 2824 | — | Table 4, N | 2824 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [11/11](seeded/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[11/11](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [11/11](independent/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[11/11](independent/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[11/11](independent/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) | [11/11](blind/claude-code/2026-11-02-a/CELL.md) (2026-11-02-a)<br>[11/11](blind/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b)<br>[11/11](blind/claude-code/2026-11-02-c/CELL.md) (2026-11-02-c) |
| `pipeline-desktop-opus` | [11/11](seeded/pipeline-desktop-opus/20261102T060946Z/CELL.md) (20261102T060946Z) | [7/11](independent/pipeline-desktop-opus/20261102T065825Z/CELL.md) (20261102T065825Z) | [0/11](blind/pipeline-desktop-opus/20261102T055735Z/CELL.md) (20261102T055735Z) |
| `pipeline-desktop-opus-postfix` | — | [9/11](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) (20261103T104514Z) | [8/11](blind/pipeline-desktop-opus-postfix/20261103T071642Z/CELL.md) (20261103T071642Z) |
| `pipeline-desktop-opus-postfix2` | — | [0/11](independent/pipeline-desktop-opus-postfix2/20261105T212407Z/CELL.md) (20261105T212407Z) | [9/11](blind/pipeline-desktop-opus-postfix2/20261103T114859Z/CELL.md) (20261103T114859Z) |
| `pipeline-desktop-opus-run2` | [11/11](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) (20261102T091036Z) | [0/11](independent/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md) (20261102T092119Z) | [7/11](blind/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) (20261102T091036Z) |
| `pipeline-desktop-opus-run3` | [11/11](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) | [8/11](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (20261103T052626Z) | [4/11](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) (20261103T010557Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/claude-code/2026-11-02-a](seeded/claude-code/2026-11-02-a/CELL.md) | `takeup_more_basic_info_treatment_col1` | -0.021511 | -0.022 | ±0.0005 (printed_precision) | 0.978 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `takeup_more_basic_info_treatment_col1` | -0.021511 | -0.022 | ±0.0005 (printed_precision) | 0.978 | PASS |
| [seeded/pipeline-desktop-opus/20261102T060946Z](seeded/pipeline-desktop-opus/20261102T060946Z/CELL.md) | `takeup_more_basic_info_treatment_col1` | -0.021511 | -0.022 | ±0.0005 (printed_precision) | 0.978 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261102T091036Z](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) | `takeup_more_basic_info_treatment_col1` | -0.021511 | -0.022 | ±0.0005 (printed_precision) | 0.978 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261103T010557Z](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) | `takeup_more_basic_info_treatment_col1` | -0.021511 | -0.022 | ±0.0005 (printed_precision) | 0.978 | PASS |
| [independent/pipeline-desktop-opus/20261102T065825Z](independent/pipeline-desktop-opus/20261102T065825Z/CELL.md) | `bcp_basic_info_treatment_col1` | -0.273601 | 0.3 | ±0.56 (se_band) | 1.024 | FAIL |
| [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) | `bcp_basic_info_treatment_col1` | -0.273601 | 0.3 | ±0.56 (se_band) | 1.024 | FAIL |
| [independent/pipeline-desktop-opus/20261102T065825Z](independent/pipeline-desktop-opus/20261102T065825Z/CELL.md) | `takeup_more_regression_observations` | 2946 | 2824 | ±141.2 (relative) | 0.864 | PASS |
| [blind/pipeline-desktop-opus-run3/20261103T010557Z](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) | `takeup_more_behavior_change_premium_col2` | 0.018246 | 0.027 | ±0.011 (se_band) | 0.796 | PASS |
| [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) | `takeup_more_actual_minus_expected_attendance_col4` | -0.032806 | -0.043 | ±0.013 (se_band) | 0.784 | PASS |

### Declared deviations

- [independent/pipeline-desktop-opus-postfix/20261103T104514Z](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) (9/11; failed: `takeup_more_basic_info_treatment_col1`, `takeup_more_regression_observations`)
  - no wave-3 commitment-assignment rule gives exactly 1126; using rule 'inc_not07'
- [independent/pipeline-desktop-opus-run2/20261102T092119Z](independent/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md) (0/11; failed: `bcp_basic_info_treatment_col1`, `bcp_enhanced_info_treatment_col1`, `bcp_goal_minus_expected_attendance_col2`, `bcp_actual_minus_expected_attendance_col3`, `bcp_regression_observations`, `takeup_more_basic_info_treatment_col1`, `takeup_more_enhanced_info_treatment_col1`, `takeup_more_behavior_change_premium_col2`, `takeup_more_goal_minus_expected_attendance_col3`, `takeup_more_actual_minus_expected_attendance_col4`, `takeup_more_regression_observations`)
  - wave coded by group size (smallest=1, largest=2, middle=3) because wave values are not numeric
- [independent/pipeline-desktop-opus-run3/20261103T052626Z](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) (8/11; failed: `bcp_basic_info_treatment_col1`, `bcp_enhanced_info_treatment_col1`, `takeup_more_enhanced_info_treatment_col1`)
  - Sample additionally excludes potentially endogenous assignments via rule rule1_flag_low_wtp chosen to match paper N=1126
  - Unlabelled columns q169/q170 used as the >=8 and >=16 'more' contract choices
- [blind/claude-code/2026-11-02-a](blind/claude-code/2026-11-02-a/CELL.md) (11/11)
  - Subject identifier for clustering in Table 4 is the participant row in cleaned_commitment_study_data.dta (one row per participant; no id column in that file).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `takeup_more_regression_observations` — pipeline 0/5, agent 3/3

Pass rates at least 50 points apart (not unanimous):

- independent: `bcp_basic_info_treatment_col1` — pipeline 1/5, agent 3/3
- independent: `bcp_enhanced_info_treatment_col1` — pipeline 1/5, agent 3/3
- independent: `bcp_regression_observations` — pipeline 2/5, agent 3/3
- independent: `takeup_more_basic_info_treatment_col1` — pipeline 2/5, agent 3/3
- independent: `takeup_more_enhanced_info_treatment_col1` — pipeline 1/5, agent 3/3
- independent: `takeup_more_regression_observations` — pipeline 2/5, agent 3/3
- blind: `bcp_goal_minus_expected_attendance_col2` — pipeline 2/5, agent 3/3
- blind: `bcp_regression_observations` — pipeline 2/5, agent 3/3
- blind: `takeup_more_basic_info_treatment_col1` — pipeline 1/5, agent 3/3
- blind: `takeup_more_goal_minus_expected_attendance_col3` — pipeline 2/5, agent 3/3

## Cells

### seeded · claude-code · 2026-11-02-a

[`seeded/claude-code/2026-11-02-a/CELL.md`](seeded/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 2; 2026-11-02T05:52:30Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-11-02T19:34:00Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261102T060946Z

[`seeded/pipeline-desktop-opus/20261102T060946Z/CELL.md`](seeded/pipeline-desktop-opus/20261102T060946Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-11-02T06:09:46Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261102T091036Z

[`seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-11-02T09:10:36Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261103T010557Z

[`seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 1; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### independent · claude-code · 2026-11-02-a

[`independent/claude-code/2026-11-02-a/CELL.md`](independent/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 2; 2026-11-02T05:52:13Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-b

[`independent/claude-code/2026-11-02-b/CELL.md`](independent/claude-code/2026-11-02-b/CELL.md) — final 11/11, re-scored 11/11; first scored 7/11; executions 3; 2026-11-02T07:04:30Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · claude-code · 2026-11-02-c

[`independent/claude-code/2026-11-02-c/CELL.md`](independent/claude-code/2026-11-02-c/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 2; 2026-11-02T20:10:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261102T065825Z

[`independent/pipeline-desktop-opus/20261102T065825Z/CELL.md`](independent/pipeline-desktop-opus/20261102T065825Z/CELL.md) — final 7/11, re-scored 7/11; first scored 4/11; executions 5; 2026-11-02T06:58:25Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix · 20261103T104514Z

[`independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md`](independent/pipeline-desktop-opus-postfix/20261103T104514Z/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 5; 2026-11-03T10:45:14Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### independent · pipeline-desktop-opus-postfix2 · 20261105T212407Z

[`independent/pipeline-desktop-opus-postfix2/20261105T212407Z/CELL.md`](independent/pipeline-desktop-opus-postfix2/20261105T212407Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 4; 2026-11-05T21:24:07Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261102T092119Z

[`independent/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261102T092119Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 2; 2026-11-02T09:21:19Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261103T052626Z

[`independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261103T052626Z/CELL.md) — final 8/11, re-scored 8/11; first scored 0/11; executions 4; 2026-11-03T05:26:26Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

### blind · claude-code · 2026-11-02-a

[`blind/claude-code/2026-11-02-a/CELL.md`](blind/claude-code/2026-11-02-a/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 2; 2026-11-02T05:52:30Z; from `claude-code-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-b

[`blind/claude-code/2026-11-02-b/CELL.md`](blind/claude-code/2026-11-02-b/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 3; 2026-11-02T07:20:00Z; from `claude-code-run2-4papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · claude-code · 2026-11-02-c

[`blind/claude-code/2026-11-02-c/CELL.md`](blind/claude-code/2026-11-02-c/CELL.md) — final 11/11, re-scored 11/11; first scored 11/11; executions 3; 2026-11-02T20:15:00Z; from `claude-code-run3-23papers-indep-blind-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261102T055735Z

[`blind/pipeline-desktop-opus/20261102T055735Z/CELL.md`](blind/pipeline-desktop-opus/20261102T055735Z/CELL.md) — final 0/11, re-scored 0/11; first scored 0/11; executions 1; 2026-11-02T05:57:35Z; from `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix · 20261103T071642Z

[`blind/pipeline-desktop-opus-postfix/20261103T071642Z/CELL.md`](blind/pipeline-desktop-opus-postfix/20261103T071642Z/CELL.md) — final 8/11, re-scored 8/11; first scored 8/11; executions 4; 2026-11-03T07:16:42Z; from `pipeline-oracle-desktop-opus-postfix-23papers-indep-blind-2026-11-03.json`; evidence complete.

### blind · pipeline-desktop-opus-postfix2 · 20261103T114859Z

[`blind/pipeline-desktop-opus-postfix2/20261103T114859Z/CELL.md`](blind/pipeline-desktop-opus-postfix2/20261103T114859Z/CELL.md) — final 9/11, re-scored 9/11; first scored 9/11; executions 2; 2026-11-03T11:48:59Z; from `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261102T091036Z

[`blind/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261102T091036Z/CELL.md) — final 7/11, re-scored 7/11; first scored 6/11; executions 2; 2026-11-02T09:10:36Z; from `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261103T010557Z

[`blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261103T010557Z/CELL.md) — final 4/11, re-scored 4/11; first scored 4/11; executions 2; 2026-11-03T01:05:57Z; from `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json`; evidence complete.

