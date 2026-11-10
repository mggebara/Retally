# Retally reproduction task: greenstone-2022-china-pollution-monitoring-automation (independent, run 2026-11-10-c)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `greenstone-2022-china-pollution-monitoring-automation`, mode `independent`, run `2026-11-10-c`
- Paper: Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation` as data, and `<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/paper.txt` as
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

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Independent Reproduction
This is an INDEPENDENT reproduction: reconstruct the analysis from the paper's description alone.  The authors' own analysis code is deliberately withheld.  Do NOT open, read, source, or execute any script files that may appear in the dataset directory listing (.do, .ado, .R, .Rmd, .py, .sas, .sps, .m, and similar) — load data files only.  Derive the estimating equation, sample restrictions, fixed effects, and standard-error clustering from the paper information and claims above.


## Claims to Reproduce
1. rd_pm_daily_no_controls_table1_panelA_col1: 34.7 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (1)
   Context: Table 1 ("Automating Air Quality Monitoring System and PM₁₀ Concentrations"), Panel A, column (1). Non-parametric local linear regression discontinuity estimate of the jump in reported daily PM₁₀ concentrations at the date a city's air quality monitoring was automated; the running variable is days from the automation date, with separate slopes before and after. Triangle kernel, bandwidth chosen by the Calonico, Cattaneo and Titiunik (2014) optimal bandwidth method. No fixed effects or covariates. Sample: all monitoring stations in the Wave 1 and Wave 2 cities with pollution data before and aft…
2. rd_pm_daily_controls_table1_panelA_col2: 34.9 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (2)
   Context: Table 1, Panel A, column (2), the paper's headline estimate: the column (1) local linear RD in reported daily PM₁₀ at the automation date with station fixed effects, month fixed effects and weather controls (temperature, relative humidity, precipitation, wind speed), entered by first residualizing PM₁₀ on them and running the RD on the residuals. Triangle kernel, optimal bandwidth (Calonico et al. 2014), all Wave 1 and Wave 2 stations; standard errors clustered by city.
3. rd_pm_daily_wave1_table1_panelA_col3: 27.5 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (3) Wave 1
   Context: Table 1, Panel A, column (3): the column (2) residualized RD (station FE, month FE, weather controls; triangle kernel, optimal bandwidth) restricted to stations in Wave 1 cities (required to automate by January 1, 2013). Standard errors clustered by city.
4. rd_pm_daily_wave2_table1_panelA_col4: 64.7 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (4) Wave 2
   Context: Table 1, Panel A, column (4): the column (2) residualized RD restricted to stations in Wave 2 cities (required to automate by January 1, 2014). Standard errors clustered by city.
5. rd_pm_daily_deadline_table1_panelA_col5: 57.1 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in PM₁₀ (Daily), column (5) Deadline
   Context: Table 1, Panel A, column (5): the column (2) residualized RD restricted to stations in cities that automated exactly on their wave's deadline (from both waves), where the automation date was not chosen strategically. Standard errors clustered by city.
6. rd_aod_monthly_controls_table1_panelA_col2: -0.005 (aerosol optical depth (unitless)) [type: coefficient]
   Location: Table 1, Panel A (RD Estimates), RD in AOD, column (2)
   Context: Table 1, Panel A, column (2), second row: the same residualized RD (station FE, month FE, weather controls) fitted to satellite aerosol optical depth (MODIS, Terra and Aqua) at the station by month, with months from automation as the running variable, as a check that true air quality did not change at automation; the paper calls it precisely zero. Triangle kernel, optimal bandwidth, all stations; standard errors clustered by city.
7. event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1: 60.3 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (1)
   Context: Table 1, Panel B, column (1). Event-study regression of reported daily PM₁₀ on treated-city indicators for 7-12, 5-6 and 3-4 months before and 1-2, 3-4, 5-6 and 7-12 months after automation (1-2 months before is the reference period), with station fixed effects, month fixed effects and weather controls (temperature, relative humidity, precipitation, wind speed). Sample: stations in cities that automated at their deadline, January 2012 to December 2013; treated stations are in Wave 1 cities (automated January 1, 2013), controls in Wave 2 cities (not automated during the period). The entry is th…
8. event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2: 31.4 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (2)
   Context: Table 1, Panel B, column (2): the column (1) deadline-sample event study with year-by-month fixed effects in place of month fixed effects (station FE and weather controls kept). The entry is the 1-2 months after coefficient; standard errors clustered by city.
9. event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3: 66.5 (micrograms per cubic meter of PM₁₀) [type: coefficient]
   Location: Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (3) +Matching
   Context: Table 1, Panel B, column (3): the column (1) event study (station FE, month FE, weather controls) on a matched sample in which each Wave 1 deadline station is paired with its geographically nearest Wave 2 deadline station, with replacement. The entry is the 1-2 months after coefficient; standard errors clustered by city.
10. event_study_log_pm_1_2_months_after_matched_table1_panelB_col5: 0.24 (log points of PM₁₀) [type: coefficient]
   Location: Table 1, Panel B (Event-Study Estimates), 1-2 Months after, column (5) Log(PM₁₀)
   Context: Table 1, Panel B, column (5): the matched-sample event study with the natural logarithm of reported daily PM₁₀ as the outcome, station fixed effects, year-by-month fixed effects and weather controls (the paper reads the coefficients as approximate percentage changes). The entry is the 1-2 months after coefficient; standard errors clustered by city.
11. n_obs_table1_panelB_deadline_cols1_2: 176426.0 (station-day observations) [type: count]
   Location: Table 1, Panel B, Obs., columns (1)-(2)
   Context: Number of observations in Table 1, Panel B, columns (1) and (2): the station-day observations of Wave 1 and Wave 2 deadline-city stations in 2012-2013 used in the unmatched event-study regressions.
12. rd_face_mask_searches_controls_table2_panelA_col2: 11.03 (Baidu search index points (monthly average)) [type: coefficient]
   Location: Table 2 (NBER WP Table 3), Panel A (RD Estimates), RD in Face Mask Searches, column (2)
   Context: Table 2 ("Automating Air Quality Monitoring System and Avoidance Behaviors"), Panel A, column (2). Local linear RD estimate of the jump at automation in a city's monthly Baidu search index for "anti-haze face masks" (PC searches), with months from automation as the running variable, after residualizing the outcome on city fixed effects, month fixed effects and weather controls. Triangle kernel, optimal bandwidth; all sample cities; standard errors clustered by city.
13. rd_air_filter_searches_controls_table2_panelA_col2: 8.73 (Baidu search index points (monthly average)) [type: coefficient]
   Location: Table 2 (NBER WP Table 3), Panel A (RD Estimates), RD in Air Filter Searches, column (2)
   Context: Table 2, Panel A, column (2): the same residualized RD (city FE, month FE, weather controls; triangle kernel, optimal bandwidth, all cities) for the city's monthly Baidu search index for "air filters". Standard errors clustered by city.

## Dataset Information
Name: greenstone_2022_china_pollution_monitoring_automation
Local path: <repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation
File format: csv
Files in the dataset directory (paths relative to the local path above):
- China_Pollution_Monitoring/Data/search_sale.dta (41.4 KB) — 467 rows, 15 columns: year, month, wind_speed, mask, filter, l_mask, l_filter, rh, code_city, taobao_mask, taobao_filter, l_taobao_mask, l_taobao_filter, rain, temp
- China_Pollution_Monitoring/Data/station_list.dta (15.1 KB) — 654 rows, 6 columns: auto_date, phase, pm10_n, code_city, station_lon, station_lat
- China_Pollution_Monitoring/Data/weather_1116.dta (27.4 MB) — 1433568 rows, 6 columns: date, wind_speed, rh, station_n, rain, temp
- China_Pollution_Monitoring/Data/mask_filter_search.dta (6.8 MB) — 712088 rows, 4 columns: date, filter, pmmask, code_city
- China_Pollution_Monitoring/Data/pollution_1116.dta (38.3 MB) — 1433568 rows, 6 columns: date, station_n, code_city, pm10, no2, so2
- China_Pollution_Monitoring/Data/pm10_corrected_reference.dta (188.4 KB) — 8856 rows, 5 columns: year, month, code_city, pm10, pm10_corrected
- China_Pollution_Monitoring/Data/aod_month.dta (421.6 KB) — 47088 rows, 4 columns: year, month, pm10_n, aod
- China_Pollution_Monitoring/Data/city_info.dta (12.2 KB) — 123 rows, 3 columns: phase, code_city, city_en
- China_Pollution_Monitoring/Data/pollution.csv (74.5 MB) — columns: station_n,code_city,date,pm10,no2,so2
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.dbf (412.5 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.prj (458 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.sbn (3.6 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.sbx (404 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.shp (25.5 MB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Cities_color.shx (2.9 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/FigureA1.mxd (574.5 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.dbf (187 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.prj (458 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.sbn (244 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.sbx (132 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.shp (79.8 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.shp.xml (5.4 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/Taiwan.shx (188 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.dbf (3.1 MB)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.prj (145 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.sbn (15.4 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.sbx (756 B)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.shp (70.9 KB)
- China_Pollution_Monitoring/Results/figures/FigureA1/wave1_wave2_station.shx (13.0 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.dbf (412.5 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.prj (458 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.sbn (3.6 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.sbx (404 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.shp (25.5 MB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Cities.shx (2.9 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/FigureB5.mxd (486.5 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.dbf (414.3 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.sbn (3.6 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.sbx (404 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.shp (25.5 MB)
- China_Pollution_Monitoring/Results/figures/FigureB5/RD_color.shx (2.9 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.cpg (5 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.dbf (187 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.prj (458 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.sbn (244 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.sbx (132 B)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.shp (79.8 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.shp.xml (5.4 KB)
- China_Pollution_Monitoring/Results/figures/FigureB5/Taiwan.shx (188 B)
- README.pdf (122.5 KB)
- metadata.json (241 B)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
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

    SCRIPT=<repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/script.R   # or <repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-greenstone-2022-china-pollution-monitoring-automation-independent-2026-11-10-c --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-greenstone-2022-china-pollution-monitoring-automation-independent-2026-11-10-c --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation:<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

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

The output directory `<repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/
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

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c`.
