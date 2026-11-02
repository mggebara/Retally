# Retally reproduction task: bokobza-2022-morning-after-coup-purges (independent, run 2026-11-02-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `bokobza-2022-morning-after-coup-purges`, mode `independent`, run `2026-11-02-a`
- Paper: The Morning After: Cabinet Instability and the Purging of Ministers after Failed Coup Attempts in Autocracies
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges` as data, and `<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Independent Reproduction
This is an INDEPENDENT reproduction: reconstruct the analysis from the paper's description alone.  The authors' own analysis code is deliberately withheld.  Do NOT open, read, source, or execute any script files that may appear in the dataset directory listing (.do, .ado, .R, .Rmd, .py, .sas, .sps, .m, and similar) — load data files only.  Derive the estimating equation, sample restrictions, fixed effects, and standard-error clustering from the paper information and claims above.


## Claims to Reproduce
1. failed_coup_base_country_fe: 0.1 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A1 (Tables for Figure 2), column Base Model, Failed coup attempt
   Context: Table A1 ("Failed coup attempts. Country fixed effects: Country-level results"), Base Model column; plotted in the left panel of Figure 2. Time-series cross-sectional OLS of the year-to-year cabinet replacement rate (one minus the cabinet-size-adjusted retention rate of ministers, from WhoGov, July to July) on a failed coup attempt indicator (Powell and Thyne data; a failed coup before 1 July counts in that year, one after 1 July in the following year), with logged GDP per capita and logged population (Penn World Table 9.0) lagged one year, country fixed effects and year fixed effects. Sample:…
2. failed_coup_main_country_fe: 0.11 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A1, column Main Model, Failed coup attempt
   Context: Table A1, Main Model column (Figure 2, left panel). Same specification as failed_coup_base_country_fe plus lagged dummies for monarchy, military regime and party regime (Anckar and Fredriksson 2019); country and year fixed effects, country-clustered standard errors.
3. failed_coup_base_leader_fe: 0.08 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A2 (Tables for Figure 2), column Base Model, Failed coup attempt
   Context: Table A2 ("Failed coup attempts. Leader fixed effects: Country-level results"), Base Model column (Figure 2, left panel, leader fixed effects). Same regressors as failed_coup_base_country_fe (failed coup attempt, lagged logged GDP per capita and population, year fixed effects) with leader fixed effects instead of country fixed effects, so identification is within each autocrat's tenure. Standard errors clustered by country.
4. failed_coup_main_leader_fe: 0.09 (change in the cabinet replacement rate (share of ministers, 0-1)) [type: coefficient]
   Location: Table A2, column Main Model, Failed coup attempt
   Context: Table A2, Main Model column: the Main Model controls (lagged GDP per capita, population, monarchy, military and party regime dummies) with leader and year fixed effects; the monarchy dummy drops out as collinear with the leader fixed effects. Country-clustered standard errors.
5. failed_coup_experience_model: 0.14 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K1 (Table for Figure 3), column H2a: Experience, Failed coup attempt
   Context: Table K1, column H2a: Experience; Figure 3 left panel. Linear probability model of whether a cabinet member is purged (absent from the cabinet the following year; reshuffles within the cabinet are not purges) on a failed coup attempt indicator, experience-group dummies (2-3, 4-6, over 6 years in cabinet; reference under 2 years), their interactions with the failed coup indicator, lagged logged GDP per capita and population, country and year fixed effects. Minister-years in autocracies 1967-2016, excluding the leader and junior ministers or other low-ranking posts; standard errors clustered by …
6. failed_coup_x_over_6_years_experience: -0.1 (difference in the change in purge probability) [type: coefficient]
   Location: Table K1, column H2a: Experience, FCA*Over 6 years of experience (Ref: <2 y)
   Context: Table K1, column H2a: Experience: the interaction of the failed coup attempt indicator with having over six years of cabinet experience (reference: under two years), in the same linear probability model as failed_coup_experience_model.
7. failed_coup_affiliation_model: 0.17 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K1, column H2b: Affiliation, Failed coup attempt
   Context: Table K1, column H2b: Affiliation; Figure 3 right panel. Linear probability model of being purged next year on the failed coup attempt indicator, party affiliation dummies (no party affiliation; from the leader's party; reference: from another party than the leader's), their interactions with the failed coup indicator, cubic polynomials in the minister's years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for ministers from another party than the leader's.
8. failed_coup_x_leaders_party: -0.13 (difference in the change in purge probability) [type: coefficient]
   Location: Table K1, column H2b: Affiliation, FCA*From the leader's party (Ref: Other party)
   Context: Table K1, column H2b: the interaction of the failed coup attempt indicator with being from the leader's party (reference: another party), in the same model as failed_coup_affiliation_model.
9. failed_coup_responsibility_model: 0.2 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K2 (Table for Figure 4), column H3a: Responsibility, Failed coup attempt
   Context: Table K2, column H3a: Responsibility; Figure 4 left panel. Linear probability model of being purged next year on the failed coup attempt indicator, portfolio dummies (Minister of Foreign Affairs, of Finance, of Natural Resources, other type of minister; reference: Minister of Defense), their interactions with the failed coup indicator, cubic polynomials in years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for ministers of defense.
10. failed_coup_x_natural_resources: -0.18 (difference in the change in purge probability) [type: coefficient]
   Location: Table K2, column H3a: Responsibility, FCA*Minister of Natural Resources (Ref: D)
   Context: Table K2, column H3a: the interaction of the failed coup attempt indicator with being minister of natural resources (reference: minister of defense), in the same model as failed_coup_responsibility_model.
11. failed_coup_importance_model: 0.37 (change in the probability of being purged next year) [type: coefficient]
   Location: Table K2, column H3b: Importance, Failed coup attempt
   Context: Table K2, column H3b: Importance; Figure 4 right panel. Linear probability model of being purged next year on the failed coup attempt indicator, rank-tier dummies (vice-president / deputy prime minister / top minister; medium-ranking; low-ranking; junior minister; reference: prime minister or president who is not the leader), their interactions with the failed coup indicator, cubic polynomials in years in office, lagged logged GDP per capita and population, country and year fixed effects, country-clustered standard errors. The failed coup coefficient is the effect for a prime minister or presi…

## Dataset Information
Name: bokobza_2022_morning_after_coup_purges
Local path: <repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges
File format: csv
Files in the dataset directory (paths relative to the local path above):
- morning_after_dataset_individuallevel.rds (91.8 MB) — data.frame, 205524 rows, 45 columns: year, party, leader, leader_party, party_group, experience, Group, experience_group, country_isocode, country_name, position, name, title, gender, birthyear, party_english, classification, portfolio_1, prestige_1, prestige_numeric, importance_numeric, purged_y1, purged_y2, coupattempt_presentyear, coup_presentyear, coup_lastyear, coupattempt_presentyear_br, coup_presentyear_br, coup_lastyear_br, coupattempt_whogov_type_br, leaderexperience_continuous, democracy_lag_br, n_part…
- morning_after_dataset_countrylevel.dta (1.7 MB) — 7878 rows, 37 columns: independent, democracy1, military_c, monarchy_c, party_c, YEAR_DATA, leader_cab_id, leaderexperience_continuous, COUNTRY_DATA, COUNTRY_ID, democracy_br, ldemocracy_br, replacement_rateadj_minister, replacement_rateadj_minister_300, replacement_rateadj_minister_200, replacement_rateadj_minister_100, coupattempt_whogov, coupattempt_month_whogov, coupattempt_whogov_br, coupattempt_whogov_type_br, ccode, gdp_cap_pwt_ln, pop_pwt_ln, elec_all, t1_e_a, oil_valuepop_2014_ln, growth_p…
- appendix_l1.jpg (101.1 KB)
- appendix_l2.jpg (48.8 KB)
- appendix_m1.jpg (121.1 KB)
- appendix_m2.jpg (63.2 KB)
- appendix_n1.jpg (101.9 KB)
- appendix_n2.jpg (53.8 KB)
- appendix_o1.jpg (60.6 KB)
- appendix_p1.jpg (114.9 KB)
- appendix_p2.jpg (52.4 KB)
- appendix_r1.jpg (99.1 KB)
- figure1.jpg (1.4 MB)
- figure3.jpg (50.9 KB)
- figure4.jpg (73.9 KB)
- figure5.jpg (44.6 KB)
- metadata.json (966 B)
- readme.txt (2.1 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
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

    SCRIPT=<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/script.R   # or <repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-bokobza-2022-morning-after-coup-purges-independent-2026-11-02-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges:<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-bokobza-2022-morning-after-coup-purges-independent-2026-11-02-a | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/
  script.R  stdout.txt  stderr.txt      # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  feedback.txt   # feedback.txt when kind is not ""
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a`.
