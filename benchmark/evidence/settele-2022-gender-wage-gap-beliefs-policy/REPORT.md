# Evidence report: settele-2022-gender-wage-gap-beliefs-policy

**How Do Beliefs About the Gender Wage Gap Affect the Demand for Public Policy?** — Sonja Settele

- Paper: https://www.econtribute.de/RePEc/ajk/ajkdps/ECONtribute_179_2022.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/267007/1/I4R-DP012.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/settele-2022-gender-wage-gap-beliefs-policy.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T37/134041-V1.zip`; AEA Data and Code Repository on openICPSR, project 134041, version V1 (doi:10.3886/E134041V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T37/134041-V1.zip (1,320,832,549 bytes, md5 00976b1cd8efa1e3d979370f5027daf3; SOURCE.txt beside it).  V1 is the only version.  55 zip entries (50 files), 6.13 GB uncompressed, all deflate, no nested archives.  Contents: "Read Me.pdf" (3 pp.; file list, data sources, run order, no estimates); All.log (2.3 MB, the full Stata log of the master run, every table); data/ with the four raw LimeSurvey exports as Stata .dta (SurveyStageI_WaveA_raw.dta 7.2 MB, SurveyStageI_WaveB_raw.dta 4.1 MB, SurveyStageII_WaveA_raw.dta and SurveyStageII_WaveB_raw.dta, 0.1-0.2 MB; answers stored as codes such as "A1"), four Stata codebook logs for them (Codebook_*_raw.log), usa_00025.dta (5.94 GB, IPUMS ACS extract) and cps_00004.dta (170 MB, IPUMS CPS extract) with acs_codebook.txt and cps_codebook.txt; dofiles/ with 11 Stata do-files (master, treatment values, four cleaning files, main / appendix figures and tables, in-text results); ado/ with 17 .ado files, wyoung.sthlp and scheme-lean2.scheme; output/Display_Output.pdf (35 pp., every main and appendix table and figure as compiled) and Display_Output.tex (the LaTeX wrapper that \input's the table files, which are not shipped; no estimates); surveys/ with the four LimeSurvey .lss survey definitions.  The ACS and CPS extracts serve only 02_Generate_Treatment_Values.do (the two information-treatment wage statistics); no pinned claim needs them.  The script-free copy (independent / blind) withholds 34 files (benchmark.strip_rule .classify_tree on the extracted package, 2026-11-09): 11 .do, 17 .ado, All.log and the four codebook .log files by suffix, and Display_Output.pdf by content (regression-table pages).  Kept: Read Me.pdf, the six .dta files, the two codebook .txt, the .lss surveys, Display_Output.tex, wyoung.sthlp and the .scheme file, none of which prints a pinned value.  Project page: https://www.openicpsr.org/openicpsr/project/134041/version/V1/view)

> Headline findings: in the pure control group (trimmed priors, N 921) Democrats score 0.691 (0.066) SD and women 0.181 (0.057) SD higher on the perception index (Table 3 Panel A col 4), and a one-SD higher prior belief about females' relative wages goes with a -0.729 (0.065) SD lower index (Panel B); for the policy demand index Democrat 0.669 (0.051) (Table 4 Panel A col 7) and prior -0.302 (0.054) (Panel B).  The ACS ("74") versus CPS ("94") information moves posterior beliefs by -12.955 (0.594) dollars, -0.658 (0.030) SD (Table 5 Panel A cols 1-2), and the perception index by 0.417 (0.032) (col 6).  2SLS per SD of posterior belief: affirmative action -0.171 (0.053), equal pay legislation -0.177 (0.053), policy demand index -0.087 (0.038) (Panel C cols 2, 3, 7; N 3022).  Follow-up perception index 0.156 (0.045) (Table 6 Panel A col 7, N 1105).
> Paper text and how it was verified.  The published article was not read (paywalled).  The source is ECONtribute DP 179 (July 22, 2022). Its Tables 3-6 were parsed cell by cell (panel, row, column, coefficient, SE) and every one of the 116 non-empty meta-database rows was matched to a cell of the same table: 111 rows equal a cell exactly (coefficient and SE; Table 5 Panel C's seven 2SLS cells checked by hand because the label splits across lines).  The remaining five are meta-database transcription slips, each next to a paper cell that DP12's "(1)" (original) column prints exactly as the ECONtribute copy does: Table 5 Panel A col 2 coded -0.685 (paper and DP -0.658, SE 0.030 agrees); Table 3 Panel C col 4 Female SE coded 53.000 (paper and DP 0.053); Table 6 Panel B col 6 T74 coded 0.122 (paper and DP 0.123, SE 0.052); Table 6 Panel A col 4 T74 SE coded 0.058 (paper and DP 0.057); Table 3 Panel C col 3 Democrat SE coded 0.073 (paper and DP 0.071).  The first three are the candidates file's "3 of 116" unmatched tokens; the last two match as tokens elsewhere in the tables.  DP12's own "(1)" columns match the ECONtribute copy everywhere except one DP typo (Table 4 Panel A col 6 Democrat printed 0.625 in DP Table 5; the paper copy and the meta database both read 0.635).  Every pinned value and SE equals its meta-database row.
> Curation pass (2026-11-09).  13 claims.  Left out: the single-item columns of Tables 3-4 (kept the summary indices), Table 3/4 Panel C, Table 5 Panels A cols 3-5 and Panel B (reduced form) and the other 2SLS columns, the sharpened q-values, Table 6 other columns and Panel B, Table 2 (correlates of incentivized priors, reported at one decimal), Tables 7-10 and the appendix.  Left out for feasibility: the two information-treatment values themselves (the ACS-based $74 and the CPS-based $94 relative wage of 45-year-old full-time employees with a Bachelor's degree, and the in-text numbers built on them), which come from the 5.94 GB ACS extract (usa_00025.dta) and the 170 MB CPS extract; the R sandbox's 300 s limit and the host's bind-mount read speed (about 8 MB/s) rule out reading the ACS file in a run.  No pinned claim reads either extract.
> Package-only facts (never in contexts).  Cleaning: 03/04 code the raw wave A / wave B main-survey answers ("A1" ...), 05 appends them, sets pweight (1 in wave A; in wave B 1.4615 / 0.6298 for men / women in age group 1 and 1.0184 / 0.8691 in age group 5), z-scores large, problem, govmore and the six policy items (quotaanchor, AAanchor, legislationanchor, transparencyanchor, UKtool, childcare) on the rand==0 mean and SD, and builds z_mani_index (large, problem, govmore) and z_lmpolicy_index (quota, AA, legislation, transparency or UKtool, childcare) as inverse-correlation-matrix weighted averages over the full sample; 06 does the same for the follow-up (z_maniII_index2). Table 3/4 (08_MainTables.do): keep if rand==0, z-score prior within that group, keep if prior strictly between r(p5) and r(p95); reg y i.wave democrat indep otherpol gender [pweight=pweight], r (Panel A), reg y i.wave prior (Panel B).  Table 5: drop if rand==0; zscore posterior [aweight=pweight] in the treatment sample (the paper's notes say z-scored on the pure control group for the perception items, and call the column 2 outcome the "z-scored" posterior); reg y T1 $controls [pweight=pweight], vce(r); ivregress 2sls y $controls (zposterior = T1) [pweight=pweight], vce(r).  $controls = wave gender prior democrat indep otherpol midwest south west age1-age4 anychildren loghhinc associatemore fulltime parttime selfemp unemp student; loghhinc is the log of the midpoint of the income bracket (DP12 Fig. 1).  Table 6: SurveyStageIIAB_final.dta, drop if rand==0, same controls.  T1 is the ACS ("74") arm.
> Blind-mode exposure (step 6, 2026-11-09).  The blind generation prompt states no pinned value or SE at printed precision or rounded to 1-3 significant figures (the only hit, "13", is the list number of the thirteenth claim), and carries no do-file text; the dataset listing names the raw files' columns (the follow-up raw files already carry merged covariates such as pweight and loghhinc).  The abstract's first 500 characters print no numbers.  The paper parser takes the ECONtribute cover line ("Funding by the Deutsche Forschungsgemeinschaft ...") as the title.
> Mount cost (2026-11-09).  The runner extracts the zip once into .cache/datasets/<slug>/ (6.13 GB; a fresh blind run including extraction, strip and listing took about 12 s on this host, a cached run about 3 s); the script-free copy hard-links its files (link count 2, no extra bytes) and the sandbox bind-mounts it read-only, so a run copies nothing.  The dataset listing reads only the .dta headers.
> What was read.  ECONtribute DP 179 pp. 1-25 and Tables 1-6; DP12 in full; the 117 meta-database rows; Read Me.pdf; 01, 02, 05 and the Tables 3-6 part of 08_MainTables.do; the head of All.log; the Display_Output.tex wrapper and page texts of Display_Output.pdf; the strip-rule classification of the extracted package.
> What could not be verified.  The published article itself was not read.  The authors' Stata code was not run (no Stata here) and no independent R cross-check was made in this pass.
> Original analysis in Stata 14+; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `perception_index_democrat_table3_panelA_col4` | 0.691 | 0.066 | Table 3, Panel A, Democrat, column (4) Perception Index | 0.691 | matches |
| 1 | `perception_index_female_table3_panelA_col4` | 0.181 | 0.057 | Table 3, Panel A, Female, column (4) Perception Index | 0.181 | matches |
| 2 | `perception_index_prior_table3_panelB_col4` | -0.729 | 0.065 | Table 3, Panel B, Prior (z-scored), column (4) Perception Index | -0.729 | matches |
| 3 | `n_obs_table3` | 921 | — | Table 3, Observations (all columns) | 921 | matches |
| 4 | `policy_demand_index_democrat_table4_panelA_col7` | 0.669 | 0.051 | Table 4, Panel A, Democrat, column (7) Policy demand index | 0.669 | matches |
| 5 | `policy_demand_index_prior_table4_panelB_col7` | -0.302 | 0.054 | Table 4, Panel B, Prior (z-scored), column (7) Policy demand index | -0.302 | matches |
| 6 | `first_stage_posterior_raw_t74_table5_panelA_col1` | -12.955 | 0.594 | Table 5, Panel A: First Stage, T74, column (1) | -12.955 | matches |
| 7 | `first_stage_posterior_z_t74_table5_panelA_col2` | -0.658 | 0.03 | Table 5, Panel A: First Stage, T74, column (2) | -0.638 | matches |
| 8 | `perception_index_t74_table5_panelA_col6` | 0.417 | 0.032 | Table 5, Panel A: First Stage, T74, column (6) Perception Index | 0.417 | matches |
| 9 | `iv_affirmative_action_posterior_table5_panelC_col2` | -0.171 | 0.053 | Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (2) Statutory affirmative action | -0.177 | matches |
| 10 | `iv_equal_pay_legislation_posterior_table5_panelC_col3` | -0.177 | 0.053 | Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (3) Stricter equal pay legislation | -0.182 | matches |
| 11 | `iv_policy_demand_index_posterior_table5_panelC_col7` | -0.087 | 0.038 | Table 5, Panel C: 2SLS, Posterior belief about fem. rel. wage (z-scored), column (7) Policy demand index | -0.087 | matches |
| 12 | `followup_perception_index_t74_table6_panelA_col7` | 0.156 | 0.045 | Table 6, Panel A: Perceptions, T74, column (7) Perception Index | 0.156 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [13/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [7/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[7/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[6/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[7/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T064621Z/CELL.md) (20261110T064621Z) | [2/13](independent/pipeline-desktop-opus/20261110T142110Z/CELL.md) (20261110T142110Z) | [0/13](blind/pipeline-desktop-opus/20261110T064353Z/CELL.md) (20261110T064353Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T112930Z/CELL.md) (20261110T112930Z) | [12/13](independent/pipeline-desktop-opus-run2/20261110T143420Z/CELL.md) (20261110T143420Z) | [1/13](blind/pipeline-desktop-opus-run2/20261110T112539Z/CELL.md) (20261110T112539Z) |
| `pipeline-desktop-opus-run3` | [9/13](seeded/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md) (20261110T113315Z) | [1/13](independent/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md) (20261110T113315Z) | [0/13](blind/pipeline-desktop-opus-run3/20261110T070417Z/CELL.md) (20261110T070417Z) |
| `pipeline-desktop-opus-run4` | — | [1/13](independent/pipeline-desktop-opus-run4/20261110T113334Z/CELL.md) (20261110T113334Z) | [1/13](blind/pipeline-desktop-opus-run4/20261110T112304Z/CELL.md) (20261110T112304Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `perception_index_prior_table3_panelB_col4` | -0.792905 | -0.729 | ±0.065 (se_band) | 0.983 | PASS |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `perception_index_prior_table3_panelB_col4` | -0.792905 | -0.729 | ±0.065 (se_band) | 0.983 | PASS |
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `perception_index_democrat_table3_panelA_col4` | 0.75941 | 0.691 | ±0.066 (se_band) | 1.037 | FAIL |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `perception_index_democrat_table3_panelA_col4` | 0.75941 | 0.691 | ±0.066 (se_band) | 1.037 | FAIL |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `perception_index_democrat_table3_panelA_col4` | 0.761115 | 0.691 | ±0.066 (se_band) | 1.062 | FAIL |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `perception_index_democrat_table3_panelA_col4` | 0.761115 | 0.691 | ±0.066 (se_band) | 1.062 | FAIL |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `followup_perception_index_t74_table6_panelA_col7` | 0.194246 | 0.156 | ±0.045 (se_band) | 0.850 | PASS |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `followup_perception_index_t74_table6_panelA_col7` | 0.194246 | 0.156 | ±0.045 (se_band) | 0.850 | PASS |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `followup_perception_index_t74_table6_panelA_col7` | 0.194246 | 0.156 | ±0.045 (se_band) | 0.850 | PASS |
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `followup_perception_index_t74_table6_panelA_col7` | 0.194218 | 0.156 | ±0.045 (se_band) | 0.849 | PASS |

### Declared deviations

- [seeded/pipeline-desktop-opus-run3/20261110T113315Z](seeded/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md) (9/13; failed: `first_stage_posterior_raw_t74_table5_panelA_col1`, `iv_affirmative_action_posterior_table5_panelC_col2`, `iv_equal_pay_legislation_posterior_table5_panelC_col3`, `iv_policy_demand_index_posterior_table5_panelC_col7`)
  - Posterior belief filled from whichever of the five posterior questions (extrayoung/extraHS/extraoccu/extrachild/extrasame) the respondent answered when the RAND4-based mapping left it missing
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (13/13)
  - The wave-A wage-transparency item and the wave-B reporting-website item share one survey variable (transparencyanchor); each is z-scored on its own wave's pure control group and the two enter the Anderson policy-demand index as a single component (5 components per respondent).
  - Anderson (2008) index weights are the row sums of the inverse covariance matrix of the standardized components, computed in the pure control group (Tables 3-5) or the full follow-up sample (Table 6); the index is the weighted mean of the available components and is not re-standardized.
  - Posterior belief z-scored with the pooled mean/sd of the treatment-arm sample (the paper does not state the reference group); chosen after a claim comparison showed control-group scaling gave -0.587 vs the claimed -0.658.
  - Probability weights rebuilt from Appendix G.1 (wave B only: age 18-24 female 0.6298 / male 1.4615; age 55-65 female 0.8691 / male 1.0184; all others 1); they match the pweight column of the follow-up files for every matched respondent.
  - Trim for Tables 3-4: pure control group with prior strictly between the unweighted 5th and 95th percentiles (50 and 113) of the control-group prior distribution (n=921).
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (13/13)
  - The z-scored posterior belief (Table 5 Panel A col 2 and the 2SLS regressor in Panel C) is standardized with the mean and SD of the treatment-arm sample, pooled across the five posterior-statistic versions. The paper does not say which reference sample it uses for this variable; this choice was made after two claim comparisons (pure-control pooled SD, then pure-control SD by statistic version, both gave about -0.59 instead of -0.658).
  - In the policy demand index, wage transparency (wave A) and the reporting website (wave B) enter as one item, each z-scored on its own wave's pure control group, because no respondent answered both.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - Posterior belief (Table 5 col 2 and the 2SLS endogenous regressor) is z-scored on the treatment-arm sample (pooled over the five posterior statistics) rather than on the pure control group; chosen after the attempt-3 claim check (control-group z-scoring gave -0.587 vs claimed -0.658).
  - Policy demand index: wage transparency within companies (wave A) and the reporting website (wave B), each z-scored on its own wave's control group, share one slot in a 5-input Anderson index, since the two items are never jointly observed.
  - Anderson (2008) indices: weights are row sums of the inverse covariance matrix of the standardised inputs (computed on the full main-survey sample, or on the full follow-up sample for Table 6); the weighted mean is not re-standardised.
  - Log household income in the main survey is mapped from the income bracket using the per-bracket values found in the package's follow-up files (loghhinc), which are constant within bracket.
  - Probability weights for the main survey are rebuilt from Appendix G.1 (wave B, age 18-24: women 0.6298, men 1.4615; age 55-65: women 0.8691, men 1.0184; else 1); they match the follow-up files' pweight for all 1,105 follow-up respondents.
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (13/13)
  - Policy demand index: the wave-A item (wage transparency within firms) and the wave-B item (gender pay-gap reporting website) share one raw variable (transparencyanchor); each is z-scored on its own wave's pure control group and they enter the Anderson index as one combined input (5 inputs, no missing), since the two items are never observed for the same respondent and a 6x6 covariance matrix cannot be estimated.
  - Anderson (2008) index: inputs z-scored on the pure control group (unweighted), weights = row sums of the inverse covariance matrix of the standardized inputs over the full sample (follow-up index: full follow-up sample); the index is the weighted mean and is not re-standardized (attempt-6 re-standardized it; changed after claim comparison).
  - Table 3/4 trimming uses the 5th/95th percentiles of the pure control group's prior distribution (50 and 113), strictly between, as in the claim description; Appendix G of the paper quotes cutoffs 50 and 116, which are the full-sample percentiles (used in attempt-6, gave N=925).
  - Posterior belief z-scored within the treatment-arm sample (Table 5 estimation sample); attempt-6 used the pure control group and attempt-7 the full sample. Chosen after claim comparison.
  - Posterior belief pooled across the five randomized statistics without dummies for the statistic (Table 5 notes list none). Log household income uses bracket midpoints (the values carried in the cleaned follow-up covariates, which map one-to-one onto the bracket answers). Robust (HC1) SEs; probability weights per Appendix G.
- [independent/pipeline-desktop-opus-run2/20261110T143420Z](independent/pipeline-desktop-opus-run2/20261110T143420Z/CELL.md) (12/13; failed: `first_stage_posterior_z_t74_table5_panelA_col2`)
  - Survey probability weights not present in raw files; regressions are unweighted
  - Raw main-survey demographic answer codes (gender, party, education, children, income bracket) carry no value labels; they were decoded by matching respondents to the follow-up files' coded dummies (female, democrat/indep/otherpol, associatemore, anychildren, loghhinc)
  - Main-survey summary indices (perception, policy demand) are the Anderson (2008) inverse-covariance weighted mean of control-standardized outcomes, not re-standardized to unit control-group SD (paper's exact index normalization not stated in the summary)
  - Posterior beliefs expressed in SD units using the pure-control-group SD of beliefs (prior belief SD), since posteriors refer to different randomly assigned wage statistics
- [independent/pipeline-desktop-opus-run4/20261110T113334Z](independent/pipeline-desktop-opus-run4/20261110T113334Z/CELL.md) (1/13; failed: `perception_index_democrat_table3_panelA_col4`, `perception_index_female_table3_panelA_col4`, `perception_index_prior_table3_panelB_col4`, `n_obs_table3`, `policy_demand_index_democrat_table4_panelA_col7`, `policy_demand_index_prior_table4_panelB_col7`, `first_stage_posterior_raw_t74_table5_panelA_col1`, `first_stage_posterior_z_t74_table5_panelA_col2`, `perception_index_t74_table5_panelA_col6`, `iv_affirmative_action_posterior_table5_panelC_col2`, `iv_equal_pay_legislation_posterior_table5_panelC_col3`, `iv_policy_demand_index_posterior_table5_panelC_col7`)
  - Stage I raw files lack constructed controls/weights; party, region, age, children, log income, education, employment dummies and pweight were mapped onto Stage I respondents by learning the raw-code -> constructed-variable mapping from the follow-up files (merged on panelID)
  - Treatment arms identified from which information screen (ACS=T74, CPS=T94, control note) was displayed; posterior pooled over related-statistic questions, inverting men-per-$100-women items to the women-per-$100-men scale when needed
  - Item direction for unlabeled Likert items fixed so that items correlate negatively with the prior belief (larger perceived gap -> higher concern/support)
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (7/13; failed: `perception_index_democrat_table3_panelA_col4`, `policy_demand_index_democrat_table4_panelA_col7`, `policy_demand_index_prior_table4_panelB_col7`, `first_stage_posterior_z_t74_table5_panelA_col2`, `perception_index_t74_table5_panelA_col6`, `iv_policy_demand_index_posterior_table5_panelC_col7`)
  - Table 3/4 sample trimmed at the 5th/95th percentiles of the full main-survey prior distribution (50 and 116, strict inequalities), which are the cutoffs stated in the paper's Appendix G; the task context describes the control group's own percentiles (which would be 50 and 113).
  - Policy demand index: wage transparency (wave A only) and the reporting website (wave B only) are never observed for the same respondent, so their covariance is unidentified; they enter the Anderson index through one wave-specific slot (each z-scored on its own wave's pure control group), giving a 5-slot inverse-covariance weighted index.
  - Anderson (2008) indices: items z-scored on the pure control group (follow-up: full follow-up sample), weights = row sums of the inverse covariance matrix estimated on the whole main (resp. follow-up) sample, weighted mean over non-missing items, then re-standardised on the pure control group (resp. full follow-up sample). Z-scoring and covariance are unweighted.
  - Prior and posterior z-scored with the mean/sd of the full (untrimmed) pure control group; the posterior pools the five randomized statistic versions without version dummies (Table 5 notes list none).
  - Table 5/6 controls: female, census region dummies, four age-group dummies (55-65 omitted), any children, log household income (bracket values taken from the cleaned follow-up files), 2-year college degree+, full-time, part-time, self-employed, unemployed, student, raw prior, wave B, Democrat, Independent, other political orientation. Probability weights as in Appendix G (wave B age 18-24 and 55-65 by gender); HC1 robust SEs; 2SLS via fixest.
  - Table 3/4 trimming uses the 5th/95th percentiles of the full main-survey prior distribution (the cutoffs the paper's appendix states), not the control group's own percentiles.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (7/13; failed: `perception_index_democrat_table3_panelA_col4`, `policy_demand_index_democrat_table4_panelA_col7`, `policy_demand_index_prior_table4_panelB_col7`, `first_stage_posterior_z_t74_table5_panelA_col2`, `perception_index_t74_table5_panelA_col6`, `iv_policy_demand_index_posterior_table5_panelC_col7`)
  - Policy demand index: wage transparency within firms (wave A) and the reporting website (wave B) were never elicited jointly, so their covariance is not identified; each is z-scored on its own wave's pure control group and they share one slot in the Anderson (2008) index, which therefore has 5 inverse-covariance-weighted inputs instead of 6 separate ones.
  - Anderson index implementation (paper gives no formula): items z-scored on the pure control group (unweighted); weights are row sums of the inverse covariance matrix of the standardized items over the full main-survey sample (all 4,065, unweighted); index is the weighted mean of the non-missing items, re-standardized on the pure control group. The follow-up index uses the full follow-up sample for z-scoring, covariance and re-standardization.
  - Trimming for Tables 3-4: 5th/95th percentiles of the prior computed on the full main-survey sample (type-2 quantiles, giving 50 and 116, the cut-offs the paper reports in Appendix G); the task text says the control group's distribution, whose percentiles would be 50 and 113. Kept control respondents with 50 < prior < 116 (strict).
  - Prior (Table 3/4 Panel B) and posterior (Table 5 col 2 and the 2SLS) z-scored with the pure control group's mean and SD (both waves pooled, unweighted). Posterior regressions have no dummies for the posterior-statistic version (Table 5 notes list none).
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (6/13; failed: `perception_index_democrat_table3_panelA_col4`, `perception_index_prior_table3_panelB_col4`, `policy_demand_index_democrat_table4_panelA_col7`, `policy_demand_index_prior_table4_panelB_col7`, `first_stage_posterior_z_t74_table5_panelA_col2`, `perception_index_t74_table5_panelA_col6`, `iv_policy_demand_index_posterior_table5_panelC_col7`)
  - Anderson (2008) summary indices: components z-scored on the pure control group (follow-up: full follow-up sample), weights = row sums of the inverse covariance matrix of the standardized components computed on the full sample the index is built on (all 4,065 main-survey respondents; 1,105 follow-up respondents), weighted mean over non-missing components, then re-standardized on the pure control group (follow-up: full follow-up sample). The paper does not state which sample the covariance matrix uses or whether the index is re-standardized.
  - Policy demand index: wage transparency (wave A) and the reporting website (wave B) are the same survey slot (transparencyanchor); each is z-scored on its own wave's control group and they enter the index as one component (5 components), because the two items are never observed jointly and no covariance between them exists.
  - Prior belief z-scored with the unweighted mean and SD of the full (untrimmed) pure control group; trimming uses Stata-style (type 2) unweighted 5th/95th percentiles of the control group's prior (50 and 113), keeping priors strictly inside.
  - Posterior belief (Table 5 col 2 and the 2SLS regressor) z-scored with the pure control group's mean and SD of the pooled posterior statistic.
  - Standardizations are unweighted; probability weights are used in all regressions; robust (HC1) standard errors via fixest.
  - Main-survey covariates were rebuilt from raw LimeSurvey codes (answer codes taken from the .lss survey definitions); log household income uses the bracket values found in the authors' follow-up files.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (7/13; failed: `perception_index_democrat_table3_panelA_col4`, `perception_index_prior_table3_panelB_col4`, `policy_demand_index_democrat_table4_panelA_col7`, `policy_demand_index_prior_table4_panelB_col7`, `first_stage_posterior_z_t74_table5_panelA_col2`, `perception_index_t74_table5_panelA_col6`)
  - Analysis data rebuilt from the raw LimeSurvey exports (Stage I waves A and B, 4,065 respondents). Answer codes were mapped using the survey instruments (.lss) in the package. Covariate construction (party, region, age, children, education, employment, log household income from bracket, prior) and the Wave B probability weights (gender x age-bracket cells) were checked against the constructed variables in the follow-up files; all matched on the 1,105 linked respondents (prior matched for 1,104).
  - T74 = RAND==1 (the ACS $74 screen is shown for RAND0 1-4); pure control = RAND==0.
  - z-scores use the unweighted mean/SD of the full pure control group (both waves, untrimmed); the prior is z-scored the same way. The posterior belief (pooled over the five versions) is z-scored on the pure control group's posterior. No dummies for the posterior-statistic version, because Table 5's notes do not list them.
  - Anderson (2008) indices: z-scored items weighted by the row sums of the inverse covariance matrix (pairwise-complete covariance over the whole main sample, or the whole follow-up sample for Table 6). Missing items are skipped in the weighted mean, and the index is re-standardized on the pure control group (on the full follow-up sample for Table 6). Wage transparency (Wave A) and the reporting website (Wave B) are never observed together, so their covariance is set to 0.
  - Trimming for Tables 3-4: prior strictly between the 5th and 95th percentiles of the pooled pure-control prior distribution, unweighted, Stata-style percentiles (R quantile type 2).
  - All regressions: weighted least squares with pweights and HC1 robust SEs (fixest). The 2SLS instruments the z-scored posterior with T74 and uses the full Table 5 control set.
  - Follow-up Wave B: the item order was randomized (randorder2). In the second ordering (wageproblem2) sub-items 3 and 4 are low-/high-skilled, so they were swapped back before pooling. Table 6 controls come from the follow-up files.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `first_stage_posterior_z_t74_table5_panelA_col2` — pipeline 0/4, agent 4/4
- blind: `first_stage_posterior_raw_t74_table5_panelA_col1` — pipeline 0/4, agent 4/4
- blind: `iv_affirmative_action_posterior_table5_panelC_col2` — pipeline 0/4, agent 4/4
- blind: `iv_equal_pay_legislation_posterior_table5_panelC_col3` — pipeline 0/4, agent 4/4
- blind: `perception_index_female_table3_panelA_col4` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- independent: `first_stage_posterior_raw_t74_table5_panelA_col1` — pipeline 1/4, agent 4/4
- independent: `iv_affirmative_action_posterior_table5_panelC_col2` — pipeline 1/4, agent 4/4
- independent: `iv_equal_pay_legislation_posterior_table5_panelC_col3` — pipeline 1/4, agent 4/4
- independent: `iv_policy_demand_index_posterior_table5_panelC_col7` — pipeline 1/4, agent 4/4
- independent: `n_obs_table3` — pipeline 2/4, agent 4/4
- independent: `perception_index_democrat_table3_panelA_col4` — pipeline 1/4, agent 4/4
- independent: `perception_index_female_table3_panelA_col4` — pipeline 1/4, agent 4/4
- independent: `perception_index_prior_table3_panelB_col4` — pipeline 1/4, agent 4/4
- independent: `perception_index_t74_table5_panelA_col6` — pipeline 1/4, agent 4/4
- independent: `policy_demand_index_democrat_table4_panelA_col7` — pipeline 1/4, agent 4/4
- independent: `policy_demand_index_prior_table4_panelB_col7` — pipeline 1/4, agent 4/4
- blind: `followup_perception_index_t74_table6_panelA_col7` — pipeline 1/4, agent 4/4
- blind: `n_obs_table3` — pipeline 1/4, agent 4/4
- blind: `perception_index_prior_table3_panelB_col4` — pipeline 0/4, agent 2/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T06:24:30Z; from `claude-code-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T06:35:00Z; from `claude-code-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T064621Z

[`seeded/pipeline-desktop-opus/20261110T064621Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T064621Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T06:46:21Z; from `pipeline-oracle-desktop-opus-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T112930Z

[`seeded/pipeline-desktop-opus-run2/20261110T112930Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T112930Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T11:29:30Z; from `pipeline-oracle-desktop-opus-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T113315Z

[`seeded/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 2; 2026-11-10T11:33:15Z; from `pipeline-oracle-desktop-opus-run3-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 6/13; executions 5; 2026-11-10T06:28:00Z; from `claude-code-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 6; 2026-11-10T06:28:00Z; from `claude-code-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 5; 2026-11-10T06:41:00Z; from `claude-code-run3-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 7/13; executions 8; 2026-11-10T06:41:00Z; from `claude-code-run4-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T142110Z

[`independent/pipeline-desktop-opus/20261110T142110Z/CELL.md`](independent/pipeline-desktop-opus/20261110T142110Z/CELL.md) — final 2/13, re-scored 2/13; first scored 0/13; executions 5; 2026-11-10T14:21:10Z; from `pipeline-oracle-desktop-opus-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T143420Z

[`independent/pipeline-desktop-opus-run2/20261110T143420Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T143420Z/CELL.md) — final 12/13, re-scored 12/13; first scored 0/13; executions 4; 2026-11-10T14:34:20Z; from `pipeline-oracle-desktop-opus-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T113315Z

[`independent/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T113315Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 2; 2026-11-10T11:33:15Z; from `pipeline-oracle-desktop-opus-run3-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T113334Z

[`independent/pipeline-desktop-opus-run4/20261110T113334Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T113334Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 2; 2026-11-10T11:33:34Z; from `pipeline-oracle-desktop-opus-run4-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 7/13, re-scored 7/13; first scored 8/13; executions 5; 2026-11-10T06:27:30Z; from `claude-code-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 3; 2026-11-10T06:30:00Z; from `claude-code-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 6/13, re-scored 6/13; first scored 6/13; executions 4; 2026-11-10T06:38:30Z; from `claude-code-run3-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 3; 2026-11-10T06:37:30Z; from `claude-code-run4-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T064353Z

[`blind/pipeline-desktop-opus/20261110T064353Z/CELL.md`](blind/pipeline-desktop-opus/20261110T064353Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 2; 2026-11-10T06:43:53Z; from `pipeline-oracle-desktop-opus-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T112539Z

[`blind/pipeline-desktop-opus-run2/20261110T112539Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T112539Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 2; 2026-11-10T11:25:39Z; from `pipeline-oracle-desktop-opus-run2-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T070417Z

[`blind/pipeline-desktop-opus-run3/20261110T070417Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T070417Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 1; 2026-11-10T07:04:17Z; from `pipeline-oracle-desktop-opus-run3-1paper-settele-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T112304Z

[`blind/pipeline-desktop-opus-run4/20261110T112304Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T112304Z/CELL.md) — final 1/13, re-scored 1/13; first scored 1/13; executions 2; 2026-11-10T11:23:04Z; from `pipeline-oracle-desktop-opus-run4-1paper-settele-indep-blind-2026-11-10.json`; evidence complete.

