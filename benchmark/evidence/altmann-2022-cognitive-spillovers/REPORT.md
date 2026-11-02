# Evidence report: altmann-2022-cognitive-spillovers

**Interventions and Cognitive Spillovers** — Steffen Altmann, Andreas Grunewald, Jonas Radbruch

- Paper: https://epflicht.ulb.uni-bonn.de/download/pdf/501850
- I4R report: https://www.econstor.eu/bitstream/10419/272845/1/I4R-DP043.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/altmann-2022-cognitive-spillovers.yaml`

> Headline finding (as published): policies that steer attention to a decision (Directed Attention) or force an active choice (Forced Choice) raise decision-task choice quality by about 11 percentage points and cut default adherence (Table 2), but lower performance in the simultaneous background task — a negative cognitive spillover, in the lab and in an online Memory-game experiment (Table 3) — so that overall payoffs do not change (Table 4).
> Original analysis in Stata 15 (README: "code was last run with version 15"); the experiment itself ran in oTree 3.3.11 / Python 3.7. language: r is the reproduction target.
> Curation pass (2026-10-21).  Pinned 13 claims from the published Tables 2-4: eleven coefficients, each with its SE (Table 2 cols 1, 2, 5, 6 and both col 7 environment coefficients; Table 3 cols 1, 2, 5 and 6; Table 4 col 1) and two counts — N = 12,160 subject-rounds and 608 subjects (= clusters) in every lab column.  The online columns' N = 5,472 was deliberately NOT pinned: it is the full row count of the online data file, which the task's dataset listing prints in every mode (blind included), so it would be a free claim.  Values exactly as printed (three decimals; 0.110 and -0.300 keep their trailing zeros).  Every pinned number appears identically in the meta-database (o_coeff / o_std_err), in DP43's reprint of the published tables, and in the package's out/table2.tex, table3.tex and table4.tex.
> Published vs working-paper version.  paper.source is the May 2019 IZA DP 12337 ("Passive Choices and Cognitive Spillovers"), the only open PDF reachable without a bot challenge.  It does not contain Tables 2-4 of the published article in any form: its Table 1 is the 3x2 treatment overview, its Table 2 ("Decision Quality and Payoffs") is a table of treatment means with between-subject SDs (e.g. 59.11 / 71.98 / 68.76 % correct in the decision task under scarcity), its appendix Tables C.1-C.2 are descriptives and attention.  The draft reports 564 lab subjects, calls the third environment "Active Choice" (published: "Forced Choice"), has one decision-task payoff (EUR 0.10) and no online experiment; the published version adds decision-task payoff schemes of 10 / 20 / 40 cents (the Baseline-10/20/40 treatments), a second lab wave, and the online (MTurk) Memory-game experiment.  Table numbering therefore does not carry over at all: published Table 2 (regressions, targeted domain) has no counterpart in the draft, and the draft's Table 2 is not a regression table.  Because paper.txt describes an earlier design, the claim contexts carry the published specification (taken from the published table notes as reprinted in DP43 Tables 4-6).  Blind / independent runs therefore depend on the contexts more than usual.
> What was read.  The IZA draft (all 47 pp., for design and numbering); DP43 (all 18 pp., EconStor); the meta-database's 75 team-45 rows; the Zenodo API record; the package README, master.do, all six do-files and out/table2-4.tex; the published-article metadata (OpenAlex, RePEc). The published PDF itself was not obtainable (OUP paywall; KU research portal accepted manuscript behind a Cloudflare challenge).
> Which script produces the pinned tables (package-only; never in contexts).  Per the README table: Table 2 <- dofiles/4_2_Interventions_targeted_domain.do (out/table2.tex); Table 3 <- dofiles/4_2_Cognitive_Spillover.do (out/table3.tex); Table 4 <- dofiles/4_3_Payoffs_And_Efficiency.do (out/table4.tex); master.do runs them in sequence after defining the control globals.  Tables 2 and 4 and Table 3 cols 1-4 use original_data/formatted_data_replication.dta restricted to Treatment_Incentives != 4 (4 = the Ample condition; 1-3 are the 10 / 20 / 40-cent payoff schemes): reg <y> i.Treatment_intervention [controls], robust cluster(subject_id), with y = summation_correct (decision-task choice quality), default_followed (default adherence), load_correct (background task), payoff_share (Table 4); the environment columns use i.Treatment_Environment (1 Baseline, 2 Directed Attention, 3 Forced Choice).  The controls are $Incentive_control (i.Treatment_Incentives) $Wave_control (i.original_lab) $Ability_control (c.(ability_task ability_load)##i.original_lab — ability interacted with the wave, which the table notes do not mention; DP43 flags the control declaration as insufficient) and $Controls (q_age i.q_gender i.perc_multitasking_1_easy perc_multitasking_2 i.subject_cat i.q_abitur_grade_cat i.q_math_grade_cat).  Table 3 cols 5-6 use original_data/formatted_data_long_mturk.dta: reg memory i.Treatment_intervention [window_height1 window_width1 age i.gender], cluster(subject_id).  The full lab file has 17,840 rows (892 subjects x 20 rounds, including the Ample condition); the restriction leaves 12,160 rows / 608 subjects.  The online file is 608 subjects x 9 rounds = 5,472 rows (the online No. Subjects of 608 is therefore genuine, not a copy of the lab count).
> Independent cross-check (Python/statsmodels on the package's .dta, OLS with subject-clustered SEs, no controls): decision-task Intervention 0.1069 (0.0178); default adherence -0.2168 (0.0222); Directed Attention -0.1370 (0.0256), Forced Choice -0.2999 (0.0211); background task -0.0282 (0.0171); payoff share 0.0058 (0.0132); online Memory -0.1143 (0.0188), N = 5,472, 608 subjects; lab N = 12,160, 608 subjects — all round to the printed values.  The with-controls columns were not re-estimated here (I4R reproduced them exactly in Stata and R).
> Package file-selection facts.  Seeded mode lists the two .dta files with their columns and shows master.do plus all six do-files under "Original Replication Scripts" (no oTree .py file was selected).  The script-free copy (independent / blind) withholds the do-files, the six .log files, the regression .tex tables, the bundled .ado files and the oTree .py sources; the README (which names the do-file behind each table) stays.  The oTree directory and the bundled ado library are noise a reproducer has to ignore.
> Left out.  Table 2 cols 3-4 and 8 (environment split of choice quality and with-controls default adherence) and Table 3 cols 3-4 (to stay within 13 claims; all reproduce exactly per I4R); the online N (see above); Table 4 col 2 (printed -0.000, a zero target the relative tolerance cannot score meaningfully) and cols 3-4; constants, R-squared and the Directed = Forced p-values; Table 5 (hypothetical payoffs, assembled by hand from a log); appendix Table B.1 (Baseline attention, a 203- / 298-subject subsample) and the supplementary O-tables; DP43's in-text Spearman correlations.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `choice_quality_intervention_t2_col1` | 0.107 | 0.018 | Table 2, Panel (a) Choice quality, column 1, Intervention | 0.107 | matches |
| 1 | `choice_quality_intervention_t2_col2` | 0.11 | 0.017 | Table 2, Panel (a) Choice quality, column 2, Intervention | 0.11 | matches |
| 2 | `default_adherence_intervention_t2_col5` | -0.217 | 0.022 | Table 2, Panel (b) Default adherence, column 5, Intervention | -0.217 | matches |
| 3 | `default_adherence_intervention_t2_col6` | -0.219 | 0.022 | Table 2, Panel (b) Default adherence, column 6, Intervention | -0.219 | matches |
| 4 | `default_adherence_directed_attention_t2_col7` | -0.137 | 0.026 | Table 2, Panel (b) Default adherence, column 7, Directed Attention | -0.137 | matches |
| 5 | `default_adherence_forced_choice_t2_col7` | -0.3 | 0.021 | Table 2, Panel (b) Default adherence, column 7, Forced Choice | -0.3 | matches |
| 6 | `background_quality_intervention_lab_t3_col1` | -0.028 | 0.017 | Table 3, Lab experiment, column 1, Intervention | -0.028 | matches |
| 7 | `background_quality_intervention_lab_t3_col2` | -0.038 | 0.014 | Table 3, Lab experiment, column 2, Intervention | -0.038 | matches |
| 8 | `memory_intervention_online_t3_col5` | -0.114 | 0.019 | Table 3, Online experiment, column 5, Intervention | -0.114 | matches |
| 9 | `payoff_share_intervention_t4_col1` | 0.006 | 0.013 | Table 4, Payoff share, column 1, Intervention | 0.006 | matches |
| 10 | `n_obs_lab_tables_2_to_4` | 12160 | — | Tables 2-4, N (every lab-experiment column) | — | — |
| 11 | `n_subjects_lab_tables_2_to_4` | 608 | — | Tables 2-4, No. Subjects (lab-experiment columns) | — | — |
| 12 | `memory_intervention_online_t3_col6` | -0.113 | 0.017 | Table 3, Online experiment, column 6, Intervention | -0.113 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](seeded/claude-code/2026-11-02-b/CELL.md) (2026-11-02-b) | [13/13](independent/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](independent/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) | [13/13](blind/claude-code/2026-10-22-a/CELL.md) (2026-10-22-a)<br>[13/13](blind/claude-code/2026-11-01-a/CELL.md) (2026-11-01-a) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) (20261023T063725Z) | [13/13](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) (20261023T064318Z) | [4/13](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) (20261023T062931Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [13/13](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (20261023T151837Z) | [4/13](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (20261023T150832Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `choice_quality_intervention_t2_col1` | 0.0829921 | 0.107 | ±0.018 (se_band) | 1.334 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `choice_quality_intervention_t2_col1` | 0.082992 | 0.107 | ±0.018 (se_band) | 1.334 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `background_quality_intervention_lab_t3_col2` | -0.01869 | -0.038 | ±0.014 (se_band) | 1.379 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `choice_quality_intervention_t2_col2` | 0.085884 | 0.11 | ±0.017 (se_band) | 1.419 | FAIL |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `background_quality_intervention_lab_t3_col1` | -0.0186727 | -0.028 | ±0.017 (se_band) | 0.549 | PASS |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `background_quality_intervention_lab_t3_col1` | -0.018673 | -0.028 | ±0.017 (se_band) | 0.549 | PASS |
| [blind/pipeline-desktop-opus/20261023T062931Z](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) | `default_adherence_directed_attention_t2_col7` | -0.098736 | -0.137 | ±0.026 (se_band) | 1.472 | FAIL |
| [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) | `default_adherence_directed_attention_t2_col7` | -0.098736 | -0.137 | ±0.026 (se_band) | 1.472 | FAIL |
| [seeded/claude-code/2026-10-22-a](seeded/claude-code/2026-10-22-a/CELL.md) | `background_quality_intervention_lab_t3_col1` | -0.028245 | -0.028 | ±0.00056 (relative) | 0.437 | PASS |
| [seeded/claude-code/2026-11-02-b](seeded/claude-code/2026-11-02-b/CELL.md) | `background_quality_intervention_lab_t3_col1` | -0.028245 | -0.028 | ±0.00056 (relative) | 0.437 | PASS |

### Declared deviations

- [independent/claude-code/2026-10-22-a](independent/claude-code/2026-10-22-a/CELL.md) (13/13)
  - Control set operationalised from variable labels: field of study = subject_cat factor; high-school GPA = q_abitur_grade_cat factor (quartiles, category 5 = missing, keeps all 12160 obs); last math grade = q_math_grade_cat factor (quartiles); perceived multitasking = perc_multitasking_1 (Likert) and perc_multitasking_2 (relative) entered linearly; payoff scheme = Treatment_Incentives factor; wave = original_lab.
  - Online screen size control entered as window_height1 and window_width1 linearly; gender as a factor (3 levels).
- [independent/pipeline-desktop-opus-run2/20261023T151837Z](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) (13/13)
  - Sample for Tables 2-4 identified by searching subject-level variables for the definition yielding 608 subjects ( Treatment_Incentives!=Ample )
- [blind/claude-code/2026-10-22-a](blind/claude-code/2026-10-22-a/CELL.md) (13/13)
  - Paper text supplied is the 2019 IZA working-paper version (no regression tables, no online experiment, 'Active Choice' instead of 'Forced Choice'); specifications were taken from the task descriptions of the published Tables 2-4 plus the data's variable labels.
  - Control set mapping (choice of codings is mine): age = q_age; gender = q_gender (female dummy); field of study = subject_cat factor (4 categories); high school GPA = q_abitur_grade_cat factor (quartiles plus a 5th category for missing GPA, so no observations are dropped); last math grade = q_math_grade_cat factor (quartiles); ability = ability_load and ability_task; perceived multitasking ability = perc_multitasking_1 (Likert); payoff-scheme indicators = Treatment_Incentives factor (10/20/40); wave = original_lab factor.
  - Online column 6 controls: age, gender as a factor (Female/Male/Other), and screen size entered as window_height1 and window_width1 linearly.
- [blind/claude-code/2026-11-01-a](blind/claude-code/2026-11-01-a/CELL.md) (13/13)
  - Paper text supplied is an earlier working-paper version without the regression tables or the online experiment; specifications follow the task's quantity descriptions.
  - Controls: age, female, field of study (subject_cat), A-level GPA quartile indicators with a missing-GPA category (q_abitur_grade_cat, keeps N constant), last math grade quartile indicators (q_math_grade_cat), background- and decision-task ability from the practice parts, perceived multitasking (5-point Likert item perc_multitasking_1), payoff-scheme (10/20/40) and wave (original_lab) indicators.
  - Online controls: age, gender (3-level factor), screen size as browser window height and width.
  - GPA and last math grade entered as quartile indicators (GPA with a missing-category), perceived multitasking as the 5-point Likert item; online screen size as window height and width.
- [blind/pipeline-desktop-opus-run2/20261023T150832Z](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) (4/13; failed: `choice_quality_intervention_t2_col1`, `choice_quality_intervention_t2_col2`, `default_adherence_intervention_t2_col5`, `default_adherence_intervention_t2_col6`, `default_adherence_directed_attention_t2_col7`, `default_adherence_forced_choice_t2_col7`, `background_quality_intervention_lab_t3_col2`, `n_obs_lab_tables_2_to_4`, `n_subjects_lab_tables_2_to_4`)
  - could not identify scarce indicator; using all observations

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- blind: `background_quality_intervention_lab_t3_col2` — pipeline 0/2, agent 2/2
- blind: `choice_quality_intervention_t2_col1` — pipeline 0/2, agent 2/2
- blind: `choice_quality_intervention_t2_col2` — pipeline 0/2, agent 2/2
- blind: `default_adherence_directed_attention_t2_col7` — pipeline 0/2, agent 2/2
- blind: `default_adherence_forced_choice_t2_col7` — pipeline 0/2, agent 2/2
- blind: `default_adherence_intervention_t2_col5` — pipeline 0/2, agent 2/2
- blind: `default_adherence_intervention_t2_col6` — pipeline 0/2, agent 2/2
- blind: `n_obs_lab_tables_2_to_4` — pipeline 0/2, agent 2/2
- blind: `n_subjects_lab_tables_2_to_4` — pipeline 0/2, agent 2/2

## Cells

### seeded · claude-code · 2026-10-22-a

[`seeded/claude-code/2026-10-22-a/CELL.md`](seeded/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-22T03:01:43Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### seeded · claude-code · 2026-11-02-b

[`seeded/claude-code/2026-11-02-b/CELL.md`](seeded/claude-code/2026-11-02-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-02T19:32:31Z; from `claude-code-run2-23papers-seeded-2026-11-02.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261023T063725Z

[`seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md`](seeded/pipeline-desktop-opus/20261023T063725Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T06:37:25Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261023T151837Z

[`seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### independent · claude-code · 2026-10-22-a

[`independent/claude-code/2026-10-22-a/CELL.md`](independent/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-10-22T03:10:05Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### independent · claude-code · 2026-11-01-a

[`independent/claude-code/2026-11-01-a/CELL.md`](independent/claude-code/2026-11-01-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-02T04:28:24Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261023T064318Z

[`independent/pipeline-desktop-opus/20261023T064318Z/CELL.md`](independent/pipeline-desktop-opus/20261023T064318Z/CELL.md) — final 13/13, re-scored 13/13; first scored 4/13; executions 3; 2026-10-23T06:43:18Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261023T151837Z

[`independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261023T151837Z/CELL.md) — final 13/13, re-scored 13/13; first scored 4/13; executions 2; 2026-10-23T15:18:37Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

### blind · claude-code · 2026-10-22-a

[`blind/claude-code/2026-10-22-a/CELL.md`](blind/claude-code/2026-10-22-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-10-22T03:19:07Z; from `claude-code-6papers-all-modes-2026-10-22.json`; evidence complete.

### blind · claude-code · 2026-11-01-a

[`blind/claude-code/2026-11-01-a/CELL.md`](blind/claude-code/2026-11-01-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-02T04:40:00Z; from `claude-code-run2-13papers-indep-blind-2026-11-01.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261023T062931Z

[`blind/pipeline-desktop-opus/20261023T062931Z/CELL.md`](blind/pipeline-desktop-opus/20261023T062931Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-10-23T06:29:31Z; from `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261023T150832Z

[`blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261023T150832Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-10-23T15:08:32Z; from `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json`; evidence complete.

