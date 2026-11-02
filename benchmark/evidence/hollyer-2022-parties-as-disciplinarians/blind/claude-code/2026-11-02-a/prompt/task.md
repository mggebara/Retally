# Retally reproduction task: hollyer-2022-parties-as-disciplinarians (blind, run 2026-11-02-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `hollyer-2022-parties-as-disciplinarians`, mode `blind`, run `2026-11-02-a`
- Paper: Parties as Disciplinarians: Charisma and Commitment Problems in Programmatic Campaigning
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians` as data, and `<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/paper.txt` as
  the paper.
- Do not read anything else in this repository or on this machine: not the
  catalog YAMLs under `benchmark/papers/`, not `.cache/datasets/`, not
  `benchmark/results/`, not other reproductions under `benchmark/reproductions/`,
  not other task directories.  If you nevertheless read any other file, list
  it in `files_read_outside_mount` in `reproduction.json`, with why.

## Independent Reproduction
This is an INDEPENDENT reproduction: reconstruct the analysis from the paper's description alone.  The authors' own analysis code is deliberately withheld.  Do NOT open, read, source, or execute any script files that may appear in the dataset directory listing (.do, .ado, .R, .Rmd, .py, .sas, .sps, .m, and similar) — load data files only.  Derive the estimating equation, sample restrictions, fixed effects, and standard-error clustering from the paper information and claims above.

## Blind Reproduction
This reproduction is also BLIND: the paper's reported values for the quantities above are deliberately withheld, and you will not be told how close your numbers are.  Compute each quantity as the paper's method defines it; do not tune the specification toward any number you expect.  Do NOT read result tables, logs, or output files that may appear in the dataset directory (.tex, .log, .pdf, .html, and similar) to recover the paper's numbers — compute everything from the data files.  Print a RESULT: line for every quantity listed, using its name exactly.

- Never search the paper text for the quantities' reported values, and never
  adjust the specification toward any number in the paper.  Use the paper
  for its method, sample and variable definitions only.
- `kind: "claim"` attempts are forbidden: you are not told the claimed
  values and must not compare against them.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).
- To check that every quantity got a value (this prints names only, never a
  value or a target):

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a --stdout <a stdout.txt>

## Quantities to Compute
Compute each quantity below and print it under the given name.  The paper's reported values are deliberately not shown.
1. personalism_volatility_difference_overall [type: coefficient; unit: points on the 1-4 Personalism scale]
   Location: Table 1, Overall row, Personalism, Difference column
   Context: Table 1 ("Electoral Volatility, Group Attachments, and Electoral Strategies"), upper panel. Party-level OLS regression (Democratic Accountability and Linkages Project expert survey, 2009) of Personalism, the party's reliance on its leader's charismatic personality on a 1-4 scale, on electoral volatility (the country's average Pedersen index over up to four election pairs before 2009, rescaled to 0-1), with party-level covariates (party size, links to unions, business and religious organisations) and country-level covariates (plurality and proportional-representation indicators, closed- and ope…
2. programmaticness_volatility_difference_overall [type: coefficient; unit: points on the 1-4 Programmaticness scale]
   Location: Table 1, Overall row, Programmaticness, Difference column
   Context: Table 1, upper panel: the same regression and covariates with Programmaticness as the outcome (the average of two 1-4 expert items: how much the party mobilises support by emphasising its policy positions, and how much it appeals to voters' long-term partisan loyalty). High-volatility (75th percentile) minus low-volatility (25th percentile) predicted Programmaticness; country-clustered standard errors.
3. personalism_volatility_difference_nonethnic [type: coefficient; unit: points on the 1-4 Personalism scale]
   Location: Table 1, Ethnicity panel, Nonethnic party row, Personalism, Difference column
   Context: Table 1, middle (Ethnicity) panel. The Personalism regression of the upper panel with an ethnic-party indicator (parties most of whose expert coders report strong linkages to ethnic or linguistic organisations) and its interaction with volatility added; same covariates, country-clustered SEs. Predicted Personalism for a nonethnic party at high (75th percentile) minus low (25th percentile) volatility.
4. programmaticness_volatility_difference_nonethnic [type: coefficient; unit: points on the 1-4 Programmaticness scale]
   Location: Table 1, Ethnicity panel, Nonethnic party row, Programmaticness, Difference column
   Context: Table 1, Ethnicity panel: the Programmaticness regression with the ethnic-party indicator and its interaction with volatility; predicted Programmaticness for a nonethnic party at high minus low volatility.
5. personalism_ethnic_minus_nonethnic_low_volatility [type: coefficient; unit: points on the 1-4 Personalism scale]
   Location: Table 1, Ethnicity panel, Difference row, Personalism, Low volatility column
   Context: Table 1, Ethnicity panel, bottom (Difference) row: predicted Personalism of an ethnic party minus that of a nonethnic party at low volatility (25th percentile), from the ethnic-interaction Personalism regression. One of the four Hypothesis 3 comparisons.
6. programmaticness_ethnic_minus_nonethnic_high_volatility [type: coefficient; unit: points on the 1-4 Programmaticness scale]
   Location: Table 1, Ethnicity panel, Difference row, Programmaticness, High volatility column
   Context: Table 1, Ethnicity panel, Difference row: predicted Programmaticness of an ethnic party minus that of a nonethnic party at high volatility (75th percentile), from the ethnic-interaction Programmaticness regression. One of the four Hypothesis 3 comparisons.
7. personalism_volatility_difference_moderate [type: coefficient; unit: points on the 1-4 Personalism scale]
   Location: Table 1, Ideology panel, Moderate party row, Personalism, Difference column
   Context: Table 1, lower (Ideology) panel. The Personalism regression with ideological extremism (the absolute distance of the party's 1-10 left-right placement from the country's mean party placement, continuous, roughly 0-6) and its interaction with volatility added; same covariates, country-clustered SEs. A moderate party sits at the country's average placement (distance zero). Predicted Personalism for a moderate party at high (75th percentile) minus low (25th percentile) volatility.
8. programmaticness_volatility_difference_moderate [type: coefficient; unit: points on the 1-4 Programmaticness scale]
   Location: Table 1, Ideology panel, Moderate party row, Programmaticness, Difference column
   Context: Table 1, Ideology panel: the Programmaticness regression with ideological extremism and its interaction with volatility; predicted Programmaticness for a moderate party (distance zero) at high minus low volatility.
9. personalism_extremist_minus_moderate_low_volatility [type: coefficient; unit: points on the 1-4 Personalism scale]
   Location: Table 1, Ideology panel, Difference row, Personalism, Low volatility column
   Context: Table 1, Ideology panel, Difference row: predicted Personalism of an extremist party minus that of a moderate party at low volatility (25th percentile), from the extremism-interaction Personalism regression. The paper places the extremist party at an absolute distance of 3 from the country mean on the 0-6 scale ("approximately the 75th percentile"). One of the four Hypothesis 3 comparisons; not significant in the paper.
10. programmaticness_extremist_minus_moderate_high_volatility [type: coefficient; unit: points on the 1-4 Programmaticness scale]
   Location: Table 1, Ideology panel, Difference row, Programmaticness, High volatility column
   Context: Table 1, Ideology panel, Difference row: predicted Programmaticness of an extremist party (the paper: distance 3 from the country mean, "approximately the 75th percentile") minus that of a moderate party at high volatility (75th percentile), from the extremism-interaction Programmaticness regression. One of the four Hypothesis 3 comparisons.
11. n_obs_table1 [type: other; unit: observations (parties)]
   Location: Table 1, note
   Context: Number of party observations the Table 1 analyses are based on, as stated in the table note (parties in 75 countries with complete data on the outcomes, volatility and all covariates).
12. rd_effect_young [type: coefficient; unit: change in the probability (0-1) of nominating a young candidate]
   Location: Table 2, row Young, tau_RD
   Context: Table 2 ("RD Effect of Incumbent Party's Victory at t on Nomination of Charismatic Candidate at t + 1"). Brazilian mayoral elections 1996-2012, restricted to elections where the winning candidate is not term-limited in the next election (open-seat sample; the incumbent mayor does not run for a second term). Running variable: the incumbent party's margin of victory at t (its vote share minus that of its strongest opponent), cutoff zero. Outcome: the party's mayoral candidate at t + 1 is young (younger than 35 the first time they run for mayor). Conventional RD point estimate from local linear p…
13. rd_effect_young_outsider [type: coefficient; unit: change in the probability (0-1) of nominating a young outsider candidate]
   Location: Table 2, row Young and outsider, tau_RD
   Context: Table 2: the same RD design and estimator with the outcome that the party's candidate at t + 1 is both younger than 35 and an outsider the first time they run (neither an elected official nor a government employee of any kind). Conventional local linear RD point estimate, MSE-optimal main and bias bandwidths, rdrobust.

## Dataset Information
Name: hollyer_2022_parties_as_disciplinarians
Local path: <repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians
File format: csv
Files in the dataset directory (paths relative to the local path above):
- cross-national-data.dta (153.4 KB) — 506 rows, 25 columns: unions, business, religious, system, polity, gini, programmatic, ethnic, mdmh, partysize, cl, ev_total, pluralty, personal, programmatic2, extremist2, extremist2_2d, extremist2_3d, ccode, ctot, demsys, ethfrac, gdppc, pr, erule
- brazil-RD-data.dta (483.1 KB) — 27455 rows, 4 columns: mv_incparty, youngF_inc_for1, dlameduck_runs, outyg1F_inc_for1
- brazil-receipts-candidates-data.dta (264.4 KB) — 16591 rows, 3 columns: sg_ue, ratio_receipts, year
- brazil-validation-data.dta (651.5 KB) — 55385 rows, 3 columns: cand_youngF, err_mvparty, cand_outyg1F
- 00-README.txt (1.7 KB)
- codebook.pdf (40.2 KB)
- metadata.json (607 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
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

    SCRIPT=<repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/script.R   # or <repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/attempt-<n>/script.R
    docker run --rm --label retally.run=claude-code-hollyer-2022-parties-as-disciplinarians-blind-2026-11-02-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians:<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R > "$(dirname "$SCRIPT")/stdout.txt" 2> "$(dirname "$SCRIPT")/stderr.txt"; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  Wrap the
command in a timeout of that many seconds: prefix it with
`perl -e 'alarm shift; exec @ARGV' 300` (or `gtimeout 300` if installed;
macOS has no `timeout`).  If the timeout fires, stop the container with
`docker ps -q --filter label=retally.run=claude-code-hollyer-2022-parties-as-disciplinarians-blind-2026-11-02-a | xargs docker kill` and treat the
run as a crash (exit code 124).

## Output contract

The output directory `<repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a`.
