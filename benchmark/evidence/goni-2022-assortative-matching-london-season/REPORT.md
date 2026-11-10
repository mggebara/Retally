# Evidence report: goni-2022-assortative-matching-london-season

**Assortative Matching at the Top of the Distribution: Evidence from the World's Most Exclusive Marriage Market** — Marc Goñi

- Paper: https://gwern.net/doc/sociology/2022-goni.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/273432/1/I4R-DP047.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/goni-2022-assortative-matching-london-season.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T3/140921-V1.zip`; AEA Data and Code Repository on openICPSR, project 140921, version V1 (doi:10.3886/E140921V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T3/140921-V1.zip (45,116,424 bytes, md5 97615f58f9bf26f4994a1b84aed7a18a; SOURCE.txt beside it).  V1 is the only version.  296 entries, 386 MB uncompressed, no nested archives. Contents: README.pdf (18 pp.; data provenance, file-to-table map, run times, no estimates); data/ with Stata .dta (final-data.dta, 231 MB, the analysis file for Tables 1-3; placebo-data.dta; final-data-sec4.dta), raw tab-delimited .txt sources (peers.txt Hollingsworth extract, bateman-master.txt, familyseats.txt, seasonattend.txt, landholings-baseline-sample.txt, sheppard.txt, countycntrls.txt), biographies.xls, constituencies.xlsx and data/shapefiles/ (ArcGIS shapefiles and a raster); programs/ with 00_setup.do, 01_dataprep/master-dataprep.do (plus an intermediate data file, dta-temp-files/final-data-men.dta), 02_analysis/ master-analysis.do and numbers-paper.do, 03_appendix/ master-appendix.do (plus "aux data appendix/" .txt/.xlsx inputs), 04_auxiliary/cgmreg.do, grc1leg.ado and grc1leg.hlp, and three ArcMap .mxd map documents; results/ with every main and appendix table as outreg2 .txt and .tex, Stata .log files (Table 2 small-cluster bootstrap, Table 4, appendix) and every figure as PDF. The script-free copy (independent / blind) withholds 120 files (the runner's manifest, 2026-11-09): the 7 .do/.ado scripts and 17 Stata .log files by suffix, and 96 regression-table .txt/.tex outputs by content (results/Table2_A/B, Table3_A/B, Table6_A/B, Table7_A/B and the appendix B/C regression tables).  Kept: README.pdf, the data, the .mxd files, grc1leg.hlp, figure PDFs, and descriptive or non-regression .tex tables (Table1.tex means, Table5.tex chi-squared tests, appendix contingency and descriptive tables), none of which prints a pinned value.  Project page: https://www.openicpsr.org/openicpsr/project/140921/version/V1/view)

> Headline findings: women whose age put them at risk of marrying during the 1861-1863 interruption of the London Season were more likely to marry a commoner (Table 2 Panel A col 1, 0.005 (0.002) per percentage point of synthetic probability) and less likely to marry an heir (-0.004 (0.002)), and sorted less by family landholdings (col 3, 0.524 (0.196) percentile ranks, which the text reads as a 31 percent reduction in sorting, the abstract's "30 percent"; col 4 -0.516 (0.225); col 5 married down 0.009 (0.003)).  The abstract's "40 percent" more peer-commoner intermarriage is not a Table 2 number. Never married, col 6, 0.002 (0.002), is insignificant.  Panel B (distance to London) 0.006 (0.002), -0.005 (0.002), 0.512 (0.213), -0.537 (0.221).  Ns: 644 baseline, 324 landholdings sample, 765 marital-rates sample (Panel B: 484 / 260 / 565, not pinned).
> Curation pass (2026-11-09).  Pinned 13 claims from Table 2, values exactly as printed.  Cross-check against the meta-database: every o_coeff_dbl / o_std_err_dbl in the 70 Table 2 rows equals a printed Table 2 value (0.005/0.002, -0.004/0.002, 0.524/0.196, -0.516/0.225, 0.009/0.003, 0.002/0.002, 0.006/0.002, -0.005/0.002, 0.512/0.213, -0.537/0.221).  Left out: Panel B columns 5-6 and the Panel B Ns (kept the entry at 13), the Distance coefficients, percent correct and dependent-variable means (summary statistics), the bootstrap-t p-values in brackets, Table 3's IV estimates (second-stage 0.39 / 0.54 / -0.33 / -0.45 ... with first-stage F; a separate estimator, kept for a later pass), Tables 1, 4, 5 (descriptive / contingency / chi-squared), Section IV and every appendix table.
> Printed precision.  The package's outreg2 output (results/Table2_A.txt, Table2_B.txt, withheld from independent / blind mounts) prints the probit marginal effects at four decimals: Panel A col 1 0.0045 (0.0021), col 2 -0.0036 (0.0017), col 5 0.0090 (0.0026), col 6 0.0021 (0.0017); Panel B col 1 0.0062 (0.0025), col 2 -0.0047 (0.0018).  The paper rounds them to three decimals; 0.0045 printed as 0.005 sits at the half-unit edge of the printed-precision floor (the four-decimal figure is itself rounded), and Panel B col 1's SE 0.0025 prints as (0.002) in the paper but (0.003) in DP47.  The OLS columns are printed at the same three decimals in both.
> Paper vs package.  The Table 2 notes call the estimates "estimates of equations (2) and (3)" without saying "marginal effects"; the do-file runs probit ... cluster(byear) followed by margins, dydx(*) predict(pr) post, i.e. average marginal effects, which is how the text interprets them (and how Figure 6's notes describe the probit estimates).  The contexts say "marginal effect".
> Package-only facts (never in contexts).  Table 2 (programs/02_analysis/ master-analysis.do, "TABLE 2"): use data/final-data.dta, keep if base_sample==1 (cols 1-5) or marital_rates_sample==1 (col 6); outcomes cOut (married a commoner), mheir, fmissmatch (|diff|), fmissmatch2 (husband - wife), fdown (married down: wife's family acres fATot > husband's sfATot), celibacy; treatment syntheticT; controls pr4 biorder hengpee; Panel B adds distlondon; probit / reg with cluster(byear) (21 birth-year clusters); probit columns report margins, dydx(*) predict(pr).  The bootstrap-t p-values come from programs/04_auxiliary/cgmreg.do (the hour-long small-cluster step). The analysis file carries the sample flags and the synthetic probability ready-made, so the dataprep chain (master-dataprep.do on the raw .txt sources) need not be re-run.
> What was read.  The published article (all 43 pp., Tables 1-5 in detail); DP47 in full; the 71 meta-database rows; README.pdf; the Table 2 section of master-analysis.do; the results/Table2 and Table3 outputs; the strip-rule classification of the extracted package.
> What could not be verified.  The authors' Stata code and the analysis were not run (no Stata here, no independent R cross-check in this pass).  The thesis version's numbers were not compared.
> Original analysis in Stata (with ArcMap for the maps); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `treatment_married_commoner_table2_panelA_col1` | 0.005 | 0.002 | Table 2, Panel A (Baseline), column (1) Married a commoner, Treatment | 0.005 | matches |
| 1 | `treatment_married_heir_table2_panelA_col2` | -0.004 | 0.002 | Table 2, Panel A (Baseline), column (2) Married an heir, Treatment | -0.004 | matches |
| 2 | `treatment_landholdings_diff_abs_table2_panelA_col3` | 0.524 | 0.196 | Table 2, Panel A (Baseline), column (3) Spouses' landholdings, Difference (absolute value), Treatment | 0.524 | matches |
| 3 | `treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4` | -0.516 | 0.225 | Table 2, Panel A (Baseline), column (4) Spouses' landholdings, Difference (husband - wife), Treatment | -0.516 | matches |
| 4 | `treatment_married_down_table2_panelA_col5` | 0.009 | 0.003 | Table 2, Panel A (Baseline), column (5) Married down, Treatment | 0.009 | matches |
| 5 | `treatment_never_married_table2_panelA_col6` | 0.002 | 0.002 | Table 2, Panel A (Baseline), column (6) Never married, Treatment | 0.002 | matches |
| 6 | `treatment_married_commoner_table2_panelB_col1` | 0.006 | 0.002 | Table 2, Panel B (Controlling for distance to London), column (1) Married a commoner, Treatment | 0.006 | matches |
| 7 | `treatment_married_heir_table2_panelB_col2` | -0.005 | 0.002 | Table 2, Panel B (Controlling for distance to London), column (2) Married an heir, Treatment | -0.005 | matches |
| 8 | `treatment_landholdings_diff_abs_table2_panelB_col3` | 0.512 | 0.213 | Table 2, Panel B (Controlling for distance to London), column (3) Difference (absolute value), Treatment | 0.512 | matches |
| 9 | `treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4` | -0.537 | 0.221 | Table 2, Panel B (Controlling for distance to London), column (4) Difference (husband - wife), Treatment | -0.537 | matches |
| 10 | `n_obs_table2_panelA_baseline` | 644 | — | Table 2, Panel A, Observations, columns (1)-(2) | 644 | matches |
| 11 | `n_obs_table2_panelA_landholdings` | 324 | — | Table 2, Panel A, Observations, columns (3)-(5) | 324 | matches |
| 12 | `n_obs_table2_panelA_never_married` | 765 | — | Table 2, Panel A, Observations, column (6) | 765 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [13/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [13/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T053231Z/CELL.md) (20261110T053231Z) | [13/13](independent/pipeline-desktop-opus/20261110T053231Z/CELL.md) (20261110T053231Z) | [13/13](blind/pipeline-desktop-opus/20261110T052937Z/CELL.md) (20261110T052937Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) (20261110T053855Z) | [13/13](independent/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) (20261110T053855Z) | [12/13](blind/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) (20261110T053855Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) (20261110T053957Z) | [12/13](independent/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) (20261110T053957Z) | [12/13](blind/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) (20261110T053957Z) |
| `pipeline-desktop-opus-run4` | — | [13/13](independent/pipeline-desktop-opus-run4/20261110T054433Z/CELL.md) (20261110T054433Z) | [12/13](blind/pipeline-desktop-opus-run4/20261110T053718Z/CELL.md) (20261110T053718Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) | `treatment_married_commoner_table2_panelA_col1` | 0.004534 | 0.005 | ±0.0005 (printed_precision) | 0.932 | PASS |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `treatment_married_commoner_table2_panelA_col1` | 0.004534 | 0.005 | ±0.0005 (printed_precision) | 0.932 | PASS |
| [seeded/pipeline-desktop-opus/20261110T053231Z](seeded/pipeline-desktop-opus/20261110T053231Z/CELL.md) | `treatment_married_commoner_table2_panelA_col1` | 0.004534 | 0.005 | ±0.0005 (printed_precision) | 0.932 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261110T053855Z](seeded/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) | `treatment_married_commoner_table2_panelA_col1` | 0.004534 | 0.005 | ±0.0005 (printed_precision) | 0.932 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261110T053957Z](seeded/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) | `treatment_married_commoner_table2_panelA_col1` | 0.004534 | 0.005 | ±0.0005 (printed_precision) | 0.932 | PASS |
| [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) | `treatment_married_heir_table2_panelA_col2` | -0.003631 | -0.004 | ±0.0005 (printed_precision) | 0.738 | PASS |
| [seeded/claude-code/2026-11-10-b](seeded/claude-code/2026-11-10-b/CELL.md) | `treatment_married_heir_table2_panelA_col2` | -0.003631 | -0.004 | ±0.0005 (printed_precision) | 0.738 | PASS |
| [seeded/pipeline-desktop-opus/20261110T053231Z](seeded/pipeline-desktop-opus/20261110T053231Z/CELL.md) | `treatment_married_heir_table2_panelA_col2` | -0.003631 | -0.004 | ±0.0005 (printed_precision) | 0.738 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261110T053855Z](seeded/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) | `treatment_married_heir_table2_panelA_col2` | -0.003631 | -0.004 | ±0.0005 (printed_precision) | 0.738 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261110T053957Z](seeded/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) | `treatment_married_heir_table2_panelA_col2` | -0.003631 | -0.004 | ±0.0005 (printed_precision) | 0.738 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Probit marginal effects are reported as average marginal effects (mean of phi(xb) times beta); the paper does not state whether margins are average or at the means.
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Probit marginal effects are average marginal effects (Stata margins default) computed by hand from glm probit; SEs (diagnostic only) via delta method with sandwich::vcovCL HC1 clustered by birth year. Bootstrap-t p-values were not reproduced.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Probit marginal effects are computed as average marginal effects (mean of phi(xb) times beta); the paper does not say whether its marginal effects are averaged or taken at the means.
- [independent/pipeline-desktop-opus/20261110T053231Z](independent/pipeline-desktop-opus/20261110T053231Z/CELL.md) (13/13)
  - Never-married sample constructed from base sample plus never-married women aged 15-35 in 1861 surviving to 35 (no ready-made sample flag); definition chosen as closest to the paper N among candidates
- [independent/pipeline-desktop-opus-run2/20261110T053855Z](independent/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) (13/13)
  - Celibacy sample death-before-35 rule operationalised as 'v4_lenient_peerdau' (dage/dyear-based); exact rule not specified in data
- [independent/pipeline-desktop-opus-run4/20261110T054433Z](independent/pipeline-desktop-opus-run4/20261110T054433Z/CELL.md) (13/13)
  - Percentile ranks of family acres computed on the pooled wife+husband distribution within the landholdings sample
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (13/13)
  - Probit columns report the average marginal effect (dP/dT averaged over the estimation sample) of the synthetic probability; the paper does not say whether its marginal effects are averaged or evaluated at the means.
  - Samples and the treatment use the flags/variables shipped in data/final-data.dta (base_sample, marital_rates_sample, syntheticT, cOut, mheir, fmissmatch, fmissmatch2, fdown, celibacy, distlondon); the synthetic probability was not rebuilt from the 1815-1830 benchmark cohort. Sample sizes with a family seat (484, 260, 565) and SD of T (7.3) agree with figures stated in the paper text.
  - Standard errors (printed for information only, not scored) are clustered by birth year (byear), which has 22 distinct values in the data versus G = 21 stated in the paper; bootstrap-t p-values were not computed.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Probit marginal effects are average marginal effects of the treatment (Stata margins default); the paper does not say whether effects are evaluated at means or averaged.
  - Treatment uses the syntheticT variable shipped in data/final-data.dta (a deterministic function of age in 1861) rather than recomputing p(t) from the 1815-1830 benchmark cohort.
  - Samples use the shipped base_sample (644) and marital_rates_sample (765) flags; landholdings sample = base_sample with non-missing fmissmatch/fmissmatch2/fdown (324); Panel B additionally requires non-missing distlondon (484 / 260).
  - Clustering by byear gives 22 clusters in the data versus G=21 stated in the paper; this affects only standard errors, which are not reported quantities.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Probit columns report the average marginal effect of syntheticT (marginaleffects::avg_slopes); the paper says 'marginal effect' without stating average vs at-means. Marginal effects at means are printed as non-RESULT diagnostics in stdout.
  - Standard errors clustered by birth year (byear, 22 clusters in the baseline sample) as the text says; the paper mentions G = 21, which equals the number of ages in 1861. Bootstrap-t p-values not computed (no listed quantity depends on them).
  - Samples, outcomes and treatment taken from the prebuilt variables in data/final-data.dta: base_sample, marital_rates_sample, syntheticT, cOut, mheir, fmissmatch, fmissmatch2, fdown, celibacy, distlondon; controls pr4 (duke/marquess/earl daughter), hengpee (English peerage), biorder (birth order excluding heirs). Landholdings sample = base_sample with non-missing fmissmatch/fmissmatch2/fdown.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (13/13)
  - Probit marginal effects are average marginal effects (Stata margins dydx default); the paper does not say whether effects are averaged or evaluated at means.
  - Used the dataset's pre-built sample flags (base_sample, marital_rates_sample), treatment (syntheticT), outcomes (cOut, mheir, fmissmatch, fmissmatch2, fdown) and controls (pr4, hengpee, biorder, distlondon) from data/final-data.dta; never married = nthismarriage == 0 in the marital-rates sample. A diagnostic rebuild of the synthetic probability from the 1815-1830 benchmark cohort correlates 0.9998 with syntheticT (small level differences from the exact exclusion rule).
  - Standard errors (not scored) clustered by birth year (byear); probit AME SEs by delta method with CR0 cluster vcov. Bootstrap-t p-values not computed.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `n_obs_table2_panelA_never_married` — pipeline 1/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:35:00Z; from `claude-code-1paper-all-modes-2026-11-09.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:32:00Z; from `claude-code-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T053231Z

[`seeded/pipeline-desktop-opus/20261110T053231Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T053231Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:32:31Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T053855Z

[`seeded/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:38:55Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T053957Z

[`seeded/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:39:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:29:00Z; from `claude-code-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:29:00Z; from `claude-code-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T05:33:30Z; from `claude-code-run3-1paper-indep-blind-2026-11-09.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T05:45:00Z; from `claude-code-run4-1paper-indep-blind-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T053231Z

[`independent/pipeline-desktop-opus/20261110T053231Z/CELL.md`](independent/pipeline-desktop-opus/20261110T053231Z/CELL.md) — final 13/13, re-scored 13/13; first scored 11/13; executions 2; 2026-11-10T05:32:31Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T053855Z

[`independent/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 2; 2026-11-10T05:38:55Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T053957Z

[`independent/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-10T05:39:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-09.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T054433Z

[`independent/pipeline-desktop-opus-run4/20261110T054433Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T054433Z/CELL.md) — final 13/13, re-scored 13/13; first scored 8/13; executions 3; 2026-11-10T05:44:33Z; from `pipeline-oracle-desktop-opus-run4-1paper-indep-blind-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:29:30Z; from `claude-code-1paper-all-modes-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 4; 2026-11-10T05:33:30Z; from `claude-code-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:32:30Z; from `claude-code-run3-1paper-indep-blind-2026-11-09.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T05:34:00Z; from `claude-code-run4-1paper-indep-blind-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T052937Z

[`blind/pipeline-desktop-opus/20261110T052937Z/CELL.md`](blind/pipeline-desktop-opus/20261110T052937Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T05:29:37Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T053855Z

[`blind/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T053855Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-10T05:38:55Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T053957Z

[`blind/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T053957Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-10T05:39:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-09.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T053718Z

[`blind/pipeline-desktop-opus-run4/20261110T053718Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T053718Z/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 1; 2026-11-10T05:37:18Z; from `pipeline-oracle-desktop-opus-run4-1paper-indep-blind-2026-11-09.json`; evidence complete.

