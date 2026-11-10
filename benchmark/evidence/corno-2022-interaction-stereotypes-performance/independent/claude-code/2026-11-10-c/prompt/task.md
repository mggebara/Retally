# Retally reproduction task: corno-2022-interaction-stereotypes-performance (independent, run 2026-11-10-c)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `corno-2022-interaction-stereotypes-performance`, mode `independent`, run `2026-11-10-c`
- Paper: Interaction, Stereotypes, and Performance: Evidence from South Africa
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance` as data, and `<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/paper.txt` as
  the paper.
- Do not read anything else in this repository or on this machine: not the
  catalog YAMLs under `benchmark/papers/`, not `.cache/datasets/`, not
  `benchmark/results/`, not other reproductions under `benchmark/reproductions/`,
  not other task directories.  If you nevertheless read any other file, list
  it in `files_read_outside_mount` in `reproduction.json`, with why.
- You may compare your `RESULT:` values with the claimed values yourself.
  Every time you do that and then change the script, record the run you
  compared as an attempt with `kind: "claim"`, and write the comparison you
  made to that attempt's `feedback.txt`, one line per off-target claim in
  the form `<name>: reproduced <v>, claimed <c>`.  Produce it with:

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Independent Reproduction
This is an INDEPENDENT reproduction: reconstruct the analysis from the paper's description alone.  The authors' own analysis code is deliberately withheld.  Do NOT open, read, source, or execute any script files that may appear in the dataset directory listing (.do, .ado, .R, .Rmd, .py, .sas, .sps, .m, and similar) — load data files only.  Derive the estimating equation, sample restrictions, fixed effects, and standard-error clustering from the paper information and claims above.


## Claims to Reproduce
1. race_iat_mixed_room_whites_table3_col1: 0.316 (change in the Race IAT D-score (higher = less prejudice against black people)) [type: coefficient]
   Location: Table 3, Race IAT, Whites, column (1), Mixed Room
   Context: Table 3 ("Stereotypes and exposure to a roommate of different race"), column (1). OLS of the follow-up (end of first year) Race IAT score on Mixed Room, a dummy for having been assigned at baseline a roommate of a different race, controlling for the respondent's baseline Race IAT score, own baseline controls (female, UCT admission score, household wealth index, monthly consumption, foreign, private high school), the same controls for the roommate except female (rooms are single-sex), and residence fixed effects; missing values of controls other than the baseline IAT are replaced by means with …
2. race_iat_mixed_room_blacks_table3_col2: -0.094 (change in the Race IAT D-score (higher = less prejudice against black people)) [type: coefficient]
   Location: Table 3, Race IAT, Blacks, column (2), Mixed Room
   Context: Table 3, column (2): the column (1) regression (follow-up Race IAT on Mixed Room, baseline Race IAT, own and roommate baseline controls, residence fixed effects) for black students. Standard errors clustered at the room level.
3. n_obs_table3_whites: 117.0 (students) [type: count]
   Location: Table 3, No. Obs., columns (1) and (3) (Whites)
   Context: Number of observations in Table 3 for the white subsample: white students in the working sample (interviewed at baseline and follow-up with non-missing values for both IATs).
4. n_obs_table3_blacks: 332.0 (students) [type: count]
   Location: Table 3, No. Obs., columns (2) and (4) (Blacks)
   Context: Number of observations in Table 3 for the black subsample: black students in the working sample.
5. gpa_mixed_room_blacks_table4_panelB_col1: 0.257 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (1) GPA, Mixed Room
   Context: Table 4 ("Impact on academic performance"), Panel B, column (1). OLS of the student's first-year average GPA (standardized to mean 0 and SD 1 over the full sample) on Mixed Room, own baseline controls (female, UCT admission score, wealth index, consumption, foreign, private high school, with mean imputation and missing-value dummies), the roommate's baseline controls (all but female), residence fixed effects and academic program fixed effects. Sample: black students in the working sample. Standard errors clustered at the room level. The entry is the Mixed Room coefficient.
6. exams_passed_mixed_room_blacks_table4_panelB_col2: 0.645 (number of exams passed in the first year) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (2) Number of exams passed, Mixed Room
   Context: Table 4, Panel B, column (2): the same specification with the number of exams passed during the first year as the outcome; black students. Standard errors clustered at the room level.
7. eligible_mixed_room_blacks_table4_panelB_col3: 0.152 (change in the probability of being eligible to continue) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (3) Eligible to continue, Mixed Room
   Context: Table 4, Panel B, column (3): the same specification with a dummy for being in good standing and eligible to continue to the next academic year (Faculty Examination Committee assessment, possibly subject to make-up exams) as the outcome; black students. Standard errors clustered at the room level.
8. performance_index_mixed_room_blacks_table4_panelB_col4: 0.443 (units of the academic performance index (first principal component)) [type: coefficient]
   Location: Table 4, Panel B: Blacks, column (4) Index of Academic Performance, Mixed Room
   Context: Table 4, Panel B, column (4): the same specification with the index of academic performance, the first principal component of GPA, number of exams passed and eligible to continue, as the outcome; black students. Standard errors clustered at the room level.
9. gpa_mixed_room_whites_table4_panelA_col1: -0.028 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel A: Whites, column (1) GPA, Mixed Room
   Context: Table 4, Panel A, column (1): the Panel B column (1) specification (standardized first-year GPA on Mixed Room, own and roommate baseline controls, residence and academic program fixed effects) for white students. Standard errors clustered at the room level.
10. gpa_mixed_room_full_table4_panelC_col1: 0.147 (standard deviations of first-year GPA) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (1) GPA, Mixed Room
   Context: Table 4, Panel C, column (1): standardized first-year GPA on Mixed Room in the full working sample (all races), with own and roommate baseline controls, race dummies (White, Coloured, Indian/Other; Black omitted), race group x residence fixed effects (race groups: Black, White, and a residual group) and academic program fixed effects. Standard errors clustered at the room level.
11. exams_passed_mixed_room_full_table4_panelC_col2: 0.447 (number of exams passed in the first year) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (2) Number of exams passed, Mixed Room
   Context: Table 4, Panel C, column (2): the Panel C specification (race dummies, race group x residence and academic program fixed effects, own and roommate controls) with the number of exams passed in the first year as the outcome; full sample. Standard errors clustered at the room level.
12. performance_index_mixed_room_full_table4_panelC_col4: 0.289 (units of the academic performance index (first principal component)) [type: coefficient]
   Location: Table 4, Panel C: Full Sample, column (4) Index of Academic Performance, Mixed Room
   Context: Table 4, Panel C, column (4): the Panel C specification with the index of academic performance (first principal component of GPA, exams passed and eligible to continue) as the outcome; full sample with the index non-missing. Standard errors clustered at the room level.
13. n_obs_table4_panelC_cols1_2: 499.0 (students) [type: count]
   Location: Table 4, Panel C: Full Sample, No. Obs., columns (1)-(2)
   Context: Number of observations in Table 4 Panel C, columns (1) and (2): the full working sample of first-year students in double rooms interviewed at baseline and follow-up with both IAT scores.

## Dataset Information
Name: corno_2022_interaction_stereotypes_performance
Local path: <repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance
File format: csv
Files in the dataset directory (paths relative to the local path above):
- ForJournals_a/Data/Clean/uctdata_balanced.dta (552.4 KB) — 998 rows, 89 columns: continue, Female, Race, coloured, white, black, Foreign, foreign_missing, roFalseuct2012, Falseuct2012, roconsbas_nomiss, consbas_nomiss, roprivschool_nomiss, DscoreraceIATbas, DscoreacaIATbas, mixracebas, DscoreraceIAT, DscoreacaIAT, falseuct2012, examspassed, Same_ro_yr2, samefaculty, Res_base, rowhite, roblack, roElse, blackRes, whiteRes, Else, roommate_study, continue2013, examspassed2013, rocoloured, mixsamefaculty, nstudent, regprogram, roForeign_bas, roforeign_missingb…
- ForJournals_a/Data/Clean/uctdata_clean.dta (573.8 KB) — 1139 rows, 83 columns: Faculty, continue, Female, Race, coloured, white, black, Foreign, foreign_missing, roFalseuct2012, Falseuct2012, roconsbas_nomiss, consbas_nomiss, roprivschool_nomiss, roDscoreraceIAT, roDscoreacaIAT, mixracebas, DscoreraceIAT, whi_raceIAT, col_raceIAT, DscoreacaIAT, examspassed, else_raceIAT, Res_base, roFaculty, blackRes, whiteRes, Else, continue2013, examspassed2013, rocoloured, regprogram, roForeign_bas, roforeign_missingbas, privateschool_nomiss, privateschool_miss, roco…
- ForJournals_a/Data/Clean/nstudents_fwer.dta (336.6 KB) — 758 rows, 63 columns: Female, Race, Falseuct2012_fwer, consbas_nomiss_fwer, examspassed2013_fu_fwer, GPA2013_fu_fwer, DscoreraceIAT_fwer, DscoreraceIAT_fu_fwer, DscoreacaIAT_fwer, DscoreacaIAT_fu_fwer, continue_fu_fwer, foreign_missing_fwer, Res_base, blackRes_fwer, whiteRes_fwer, Faculty_fwer, coloured_fwer, white_fwer, black_fwer, Else_fwer, Foreign_fwer, examspassed_fu_fwer, continue2013_fu_fwer, nstudent_fwer, regprogram, privateschool_nomiss_fwer, privateschool_miss_fwer, roomnum_base, missfa…
- ForJournals_a/Data/Clean/uctdata_tabA2.dta (3.2 MB) — 31675 rows, 19 columns: Female, Race, Foreign, falseuct2012, foreign_comp, studentinsample, populationgroup, studentinres_double, all_students, studentinres, studentinourres, nstudent, round, gender, acadyear, english_home_comp, zulu_home_comp, xhosa_home_comp, af…
- ForJournals_a/Data/Clean/ronstudent_sim.dta (268.9 KB) — 3815 rows, 11 columns: roFalseuct2012_sim, roconsbas_nomiss_sim, roforeign_missing_sim, roForeign_sim, ronstudent, roprivateschool_nomiss_sim, roprivateschool_miss_sim, romissfalse_sim, roconsbas_miss_sim, rodurpcabas_nomiss_sim, rodurpcabas_miss_sim
- ForJournals_a/Data/Clean/tabA5.dta (92.4 KB) — 2292 rows, 9 columns: Race, female, sample, nstudent, round, odd, n_order, roomnum_base, buildings_name
- ForJournals_a/Data/Clean/uctdata_dyadic.dta (26.9 MB) — 370272 rows, 25 columns: sameresidence, nstudent, A_Foreign, S_Foreign, A_privateschool_nomiss, S_privateschool_nomiss, A_DscoreraceIAT, S_DscoreraceIAT, A_DscoreacaIAT, S_DscoreacaIAT, id_d, id, Res_base, sameroom, samesex, samerace, A_zFalseuct2012, S_zFalseuct20…
- ForJournals_a/Data/Clean/new_accommodation_2012.dta (117.2 KB) — 3787 rows, 2 columns: nstudent, buildings_name
- ForJournals_a/Questionnaires/Questionnaire_R1_final.pdf (262.9 KB)
- ForJournals_a/Questionnaires/Questionnaire_R2_final.pdf (263.8 KB)
- ForJournals_a/README_a.pdf (235.6 KB)
- ForJournals_a/programs/ado/ngreg.hlp (1.3 KB)
- metadata.json (241 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/script.R   # or <repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-corno-2022-interaction-stereotypes-performance-independent-2026-11-10-c --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-corno-2022-interaction-stereotypes-performance-independent-2026-11-10-c --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance:<repo>/benchmark/.cache/claude-code/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/mount/corno_2022_interaction_stereotypes_performance:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  The
command enforces it: `run_sandbox` runs the `docker run` after `--`, writes
its output to `stdout.txt` and `stderr.txt` next to the script, and writes
`timing.json` there too (wall-clock seconds, and whether the limit was
hit).  If the limit is hit it kills the container, appends a line saying
so to `stderr.txt` and exits with code 124: treat the run as a crash.  Do
not add your own timeout, do not redirect its output yourself, and do not
delete `timing.json`; keep it with the run's other files.

If a `docker run` produces no output for more than ten minutes (no
container output, no error, the command does not return), the Docker
daemon is probably wedged.  Stop: kill the command, and do not restart
Docker Desktop or the Docker daemon yourself.  The hung attempt is not
counted: do not save it as an `attempt-<n>` directory or as the final run,
and say in `notes` that it hung.  Report it in your final message (which
step hung, and for how long) instead of retrying.

## Output contract

The output directory `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c/
  script.R  stdout.txt  stderr.txt  timing.json   # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  timing.json  feedback.txt   # feedback.txt when kind is not ""
  reproduction.json                     # written LAST
```

- `attempt-<n>` directories are every execution before the final one, in
  the order they ran; the final files at the top are the run whose
  `RESULT:` lines are scored.  If you go back to an earlier attempt, copy
  that attempt's files to the top level as the final run.
- `feedback.txt` holds what you acted on before the next attempt: the error
  you fixed (`kind: "error"`) or the `check_attempt` comparison
  (`kind: "claim"`).
- Exploratory runs (inspecting variables, counting rows, checking a filter;
  no estimate of a listed quantity) are attempts with `kind: ""` and need no
  `feedback.txt`.  They must NOT print any `RESULT:` line, not even a
  placeholder: the first run that prints one is scored as your first scored
  attempt.  Print `RESULT:` lines only from a script that estimates the
  listed quantities, and `kind: "error"` only for a run that crashed or
  that was meant to print them and did not.
- Write `reproduction.json` last, in this schema:

```
reproduction.json (schema 1), written last by the agent into its run directory
benchmark/reproductions/<entry_id>/<mode>/<run_id>/:

{
  "schema": 1,
  "entry_id": "montero-2022-cooperative-property-rights",
  "mode": "independent",
  "run_id": "2026-10-22-a",
  "reproducer": "claude-code",
  "language": "r",
  "final": {"script": "script.R", "stdout": "stdout.txt", "stderr": "stderr.txt", "exit_code": 0},
  "attempts": [
    {"dir": "attempt-1", "exit_code": 1, "kind": "error"},
    {"dir": "attempt-2", "exit_code": 0, "kind": "claim"}
  ],
  "deviations": [],
  "notes": "free text: what the agent did, what it could not do",
  "files_read_outside_mount": [],
  "started_at": "2026-10-22T10:00:00Z",
  "finished_at": "2026-10-22T10:40:00Z"
}

* entry_id, mode and run_id must match the directory the file sits in.
* final: the run that is scored -- script.R, stdout.txt, stderr.txt at the
  run-dir root, and its exit code.  If the agent reverts to an earlier
  attempt it copies that attempt's files there.
* attempts: every execution before the final one, oldest first.  Each
  attempt-<n>/ holds script.R, stdout.txt, stderr.txt, and feedback.txt
  when kind is not "".  kind is the refinement that followed it:
  "error" (it crashed or printed no RESULT: line; the agent repaired it),
  "claim" (the agent compared its RESULT: values with the claimed values
  and changed the script; never allowed in blind mode), or "" (neither).
* All paths are relative to the run directory; absolute paths and ".."
  are rejected.
* deviations: free-text methodology changes, in addition to any
  DEVIATION: lines in the final stdout.
* The numbers scored are the RESULT: lines of the files, never anything
  written in this JSON.
```

End your final message with the final run's `RESULT:` lines and a short
note.  Nothing needed for scoring may live only in the message: the files
are the record.

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/corno-2022-interaction-stereotypes-performance/independent/2026-11-10-c`.
