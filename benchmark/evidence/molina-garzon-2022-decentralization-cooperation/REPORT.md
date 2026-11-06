# Evidence report: molina-garzon-2022-decentralization-cooperation

**Decentralization Can Increase Cooperation among Public Officials** — Adriana Molina-Garzón, Tara Grillos, Alan Zarychta, Krister P. Andersson

- Paper: https://par.nsf.gov/servlets/purl/10228422
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/molina-garzon-2022-decentralization-cooperation.yaml`
- Data access: public

> Headline findings: in the communication rounds of a public goods game, health officials in decentralized Honduran municipalities contribute more than those in centrally administered ones (Table 2 col 2 interaction 0.76 (0.38); col 1 Decentralized 0.83 (0.23); N 1,980 participant-rounds), and decentralization is associated with more cross-level ties, especially friendships (Table 3 Strong Ties Full Model 1.07 (0.31); N 231 base, 226 full).
> Curation pass (2026-11-06).  Pinned 12 claims: Table 2 Decentralized and Communication in both columns, the column 2 interaction and N; Table 3 Decentralized in all four columns with SEs, and the two Ns. Values exactly as printed in the Early View PDF (2 decimals). Cross-check against the meta-database: the seven paired rows' o_coeff / o_std_err round to the printed values (0.826 (0.226), 2.541 (0.214), 0.409 (0.302), 2.023 (0.317), 0.762 (0.380), 0.240 (0.144), 1.074 (0.314)).  Left out: Table 1 (weighted descriptive statistics), the Table 2 controls, R-squared and AIC, the Table 3 controls, constants and BIC, the text's raw communication-round means (7.9 vs 6.7 lempiras), Figure 3-4 predictions and every SI table.
> Paper vs package.  Table 2's note says "robust standard errors"; the do-file runs reg with [pweight = weights_games_full_scaled], vce(cluster publicid), i.e. SEs clustered by participant (220 clusters in the estimation sample).  Heteroskedasticity-robust SEs without clustering would differ; the contexts repeat the paper's wording.  Table 3's printed "0.22 = †" in the All Ties Base column is a typesetting artefact (the coefficient is 0.22, significant at 10 %).
> Package-only facts (never in contexts).  Table 2 (do-file): publicgoodgame_dataAug27.dta; contribution on decentralized i.p_type communication round lag_groupcontribution num_players knownpeople Q2_female Q1_Edad Q2_Educacion Q3_YrsSalud Q5_Trust1Base, column 2 with i.decentralized##i.communication; pweights weights_games_full_scaled; clustered by publicid.  p_type is numeric 1-4 with the mayor's office (A / M) as base.  The file has 2,257 rows (some contribution codes negative, dropped by the R script's Table 1 code; the regression's listwise deletion and the lag drop round 1). Table 3 (R): clanalysis_anondata_vNov16.csv; glm(family = poisson, weights = weights_games_full_scaled) of net_crosslevel_propnumknown / net_crosslevel_propnumfriends with offset(log(net_crosslevel_propdenom*)), full models adding Mujer, Q2_Educacion, Q1_Edad, Q3_YrsSalud, gen_trust, Participant_C, Participant_G, Participant_R; SEs from the script's clse.f (CR1 clustered by publicid_muni), passed to texreg. LEAK SURFACE: the game .dta also ships the authors' fitted values and CI bounds from the Table 2 models (outcome_ols_1, standarderror_ols, highconf_1, lowconf_1, outcome_ols_2, highconf_ols_2, lowconf_ols_2; documented in the codebook).  They are data columns, which the strip rule never touches; regressing outcome_ols_1 on the regressors would recover the column 1 coefficients but not the SEs or the column 2 interaction.  Recorded, not fixed.
> What was read.  The Early View PDF (all 16 pp.); the package README and codebook; the do-file in full; the R script's Table 1 and Table 3 sections; the Dataverse API metadata for both versions and for KDJD27; the meta-database's 8 team-17 rows.
> Independent cross-check (2026-11-06; not the package code: pandas / statsmodels on the downloaded files).  Table 2 col 1: Decentralized 0.826 (0.226), Communication 2.541 (0.214), N 1,980, R2 0.263; col 2: Decentralized 0.409 (0.302), Communication 2.023 (0.317), interaction 0.762 (0.380), R2 0.266 (WLS with participant-clustered SEs).  Table 3: All Ties base 0.218 (0.124), full 0.240 (0.144); Strong Ties base 0.607 (0.279), full 1.074 (0.314); N 231 / 226.  All round to the printed values.
> What could not be verified.  The authors' Stata and R code was not run.  Whether the issue PDF (pp. 554-569) differs from the Early View print in any number was not checked (the issue PDF is not open); the seven DB rows, entered from the published article, agree with it.
> Original analysis in Stata 15 (Table 2) and R 3.6.1 (Tables 1 and 3); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `decentralized_table2_col1` | 0.83 | 0.23 | Table 2, column (1), Decentralized | 0.83 | matches |
| 1 | `communication_table2_col1` | 2.54 | 0.21 | Table 2, column (1), Communication | 2.54 | matches |
| 2 | `decentralized_table2_col2` | 0.41 | 0.3 | Table 2, column (2), Decentralized | 0.41 | matches |
| 3 | `communication_table2_col2` | 2.02 | 0.32 | Table 2, column (2), Communication | 2.02 | matches |
| 4 | `decentralized_x_communication_table2_col2` | 0.76 | 0.38 | Table 2, column (2), Decentralized X Communication | 0.76 | matches |
| 5 | `n_obs_table2` | 1980 | — | Table 2, Observations | — | — |
| 6 | `decentralized_table3_allties_base` | 0.22 | 0.12 | Table 3, All Ties (Prop. Known), Base Model, Decentralized | — | — |
| 7 | `decentralized_table3_allties_full` | 0.24 | 0.14 | Table 3, All Ties (Prop. Known), Full Model, Decentralized | 0.24 | matches |
| 8 | `decentralized_table3_strongties_base` | 0.61 | 0.28 | Table 3, Strong Ties (Prop. Friends), Base Model, Decentralized | — | — |
| 9 | `decentralized_table3_strongties_full` | 1.07 | 0.31 | Table 3, Strong Ties (Prop. Friends), Full Model, Decentralized | 1.07 | matches |
| 10 | `n_obs_table3_base` | 231 | — | Table 3, N (Base Models) | — | — |
| 11 | `n_obs_table3_full` | 226 | — | Table 3, N (Full Models) | — | — |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/12](seeded/claude-code/2026-11-06-a/CELL.md) (2026-11-06-a)<br>[12/12](seeded/claude-code/2026-11-06-b/CELL.md) (2026-11-06-b) | [12/12](independent/claude-code/2026-11-06-a/CELL.md) (2026-11-06-a)<br>[12/12](independent/claude-code/2026-11-06-b/CELL.md) (2026-11-06-b)<br>[12/12](independent/claude-code/2026-11-06-c/CELL.md) (2026-11-06-c) | [12/12](blind/claude-code/2026-11-06-a/CELL.md) (2026-11-06-a)<br>[12/12](blind/claude-code/2026-11-06-b/CELL.md) (2026-11-06-b)<br>[12/12](blind/claude-code/2026-11-06-c/CELL.md) (2026-11-06-c) |
| `pipeline-desktop-opus` | [12/12](seeded/pipeline-desktop-opus/20261106T163831Z/CELL.md) (20261106T163831Z) | [12/12](independent/pipeline-desktop-opus/20261106T165825Z/CELL.md) (20261106T165825Z) | [6/12](blind/pipeline-desktop-opus/20261106T163912Z/CELL.md) (20261106T163912Z) |
| `pipeline-desktop-opus-run2` | [12/12](seeded/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) (20261106T174031Z) | [12/12](independent/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) (20261106T174031Z) | [6/12](blind/pipeline-desktop-opus-run2/20261106T173743Z/CELL.md) (20261106T173743Z) |
| `pipeline-desktop-opus-run3` | [12/12](seeded/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) (20261106T174057Z) | [6/12](independent/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) (20261106T174057Z) | [12/12](blind/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) (20261106T174057Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/pipeline-desktop-opus-run3/20261106T174057Z](blind/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) | `decentralized_table3_allties_full` | 0.173629 | 0.24 | ±0.14 (se_band) | 0.474 | PASS |
| [seeded/pipeline-desktop-opus/20261106T163831Z](seeded/pipeline-desktop-opus/20261106T163831Z/CELL.md) | `decentralized_table3_allties_base` | 0.217647 | 0.22 | ±0.005 (printed_precision) | 0.471 | PASS |
| [seeded/pipeline-desktop-opus-run3/20261106T174057Z](seeded/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) | `decentralized_table3_allties_base` | 0.217647 | 0.22 | ±0.005 (printed_precision) | 0.471 | PASS |
| [seeded/claude-code/2026-11-06-a](seeded/claude-code/2026-11-06-a/CELL.md) | `decentralized_table3_allties_base` | 0.217647 | 0.22 | ±0.005 (printed_precision) | 0.471 | PASS |
| [seeded/claude-code/2026-11-06-b](seeded/claude-code/2026-11-06-b/CELL.md) | `decentralized_table3_allties_base` | 0.217647 | 0.22 | ±0.005 (printed_precision) | 0.471 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261106T174031Z](seeded/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) | `decentralized_table3_allties_base` | 0.217647 | 0.22 | ±0.005 (printed_precision) | 0.471 | PASS |
| [seeded/claude-code/2026-11-06-a](seeded/claude-code/2026-11-06-a/CELL.md) | `decentralized_table2_col1` | 0.82582 | 0.83 | ±0.0166 (relative) | 0.252 | PASS |
| [seeded/claude-code/2026-11-06-b](seeded/claude-code/2026-11-06-b/CELL.md) | `decentralized_table2_col1` | 0.82582 | 0.83 | ±0.0166 (relative) | 0.252 | PASS |
| [seeded/pipeline-desktop-opus-run2/20261106T174031Z](seeded/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) | `decentralized_table2_col1` | 0.82582 | 0.83 | ±0.0166 (relative) | 0.252 | PASS |
| [seeded/pipeline-desktop-opus/20261106T163831Z](seeded/pipeline-desktop-opus/20261106T163831Z/CELL.md) | `decentralized_table2_col1` | 0.82582 | 0.83 | ±0.0166 (relative) | 0.252 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-06-b](independent/claude-code/2026-11-06-b/CELL.md) (12/12)
  - Table 2 standard errors use heteroskedasticity-robust (HC1) SEs per the table note; they do not match the printed SEs exactly (e.g. Decentralized 0.18 vs 0.23), so the authors probably clustered or used another variant. Point estimates are unaffected.
  - Table 3 Poisson is fit with glm(quasipoisson) and the matching weights (non-integer weights), with log(total possible cross-level ties) as the offset and HC1 municipality-clustered SEs; one participant missing the matching weight is dropped (232 -> 231).
- [independent/claude-code/2026-11-06-c](independent/claude-code/2026-11-06-c/CELL.md) (12/12)
  - Table 2 standard errors are clustered by municipality (fixest cluster=~publicid_muni); the paper's table note says 'robust standard errors', so reported SEs may differ slightly (e.g. 0.20 vs 0.23 on Decentralized, col. 1). Point estimates and N are unaffected.
- [blind/claude-code/2026-11-06-b](blind/claude-code/2026-11-06-b/CELL.md) (12/12)
  - Table 3: gen_trust enters as coded in the CSV (values 1/2, not 0/1 as the codebook states); this shifts only the intercept, not the Decentralized coefficient.
  - Table 3 Base N: the one participant with a missing matching weight is dropped (weighted models cannot use it).
- [blind/claude-code/2026-11-06-c](blind/claude-code/2026-11-06-c/CELL.md) (12/12)
  - Table 3: participants with a missing matching weight (1 row in the network CSV) are dropped; the paper does not state its N handling explicitly.
  - Table 3 clustered SEs use sandwich::vcovCL (HC0); only coefficients and Ns are scored.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

_None._

Pass rates at least 50 points apart (not unanimous):

- blind: `decentralized_table3_allties_base` — pipeline 1/3, agent 3/3
- blind: `decentralized_table3_allties_full` — pipeline 1/3, agent 3/3
- blind: `decentralized_table3_strongties_base` — pipeline 1/3, agent 3/3
- blind: `decentralized_table3_strongties_full` — pipeline 1/3, agent 3/3
- blind: `n_obs_table3_base` — pipeline 1/3, agent 3/3
- blind: `n_obs_table3_full` — pipeline 1/3, agent 3/3

## Cells

### seeded · claude-code · 2026-11-06-a

[`seeded/claude-code/2026-11-06-a/CELL.md`](seeded/claude-code/2026-11-06-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T16:32:00Z; from `claude-code-1paper-all-modes-2026-11-06.json`; evidence complete.

### seeded · claude-code · 2026-11-06-b

[`seeded/claude-code/2026-11-06-b/CELL.md`](seeded/claude-code/2026-11-06-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T17:40:40Z; from `claude-code-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261106T163831Z

[`seeded/pipeline-desktop-opus/20261106T163831Z/CELL.md`](seeded/pipeline-desktop-opus/20261106T163831Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T16:38:31Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261106T174031Z

[`seeded/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T17:40:31Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261106T174057Z

[`seeded/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T17:40:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json`; evidence complete.

### independent · claude-code · 2026-11-06-a

[`independent/claude-code/2026-11-06-a/CELL.md`](independent/claude-code/2026-11-06-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-06T16:34:30Z; from `claude-code-1paper-all-modes-2026-11-06.json`; evidence complete.

### independent · claude-code · 2026-11-06-b

[`independent/claude-code/2026-11-06-b/CELL.md`](independent/claude-code/2026-11-06-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T17:40:50Z; from `claude-code-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### independent · claude-code · 2026-11-06-c

[`independent/claude-code/2026-11-06-c/CELL.md`](independent/claude-code/2026-11-06-c/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-06T17:56:00Z; from `claude-code-run3-1paper-indep-blind-2026-11-06.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261106T165825Z

[`independent/pipeline-desktop-opus/20261106T165825Z/CELL.md`](independent/pipeline-desktop-opus/20261106T165825Z/CELL.md) — final 12/12, re-scored 12/12; first scored 6/12; executions 2; 2026-11-06T16:58:25Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261106T174031Z

[`independent/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261106T174031Z/CELL.md) — final 12/12, re-scored 12/12; first scored 6/12; executions 2; 2026-11-06T17:40:31Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261106T174057Z

[`independent/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) — final 6/12, re-scored 6/12; first scored 6/12; executions 2; 2026-11-06T17:40:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json`; evidence complete.

### blind · claude-code · 2026-11-06-a

[`blind/claude-code/2026-11-06-a/CELL.md`](blind/claude-code/2026-11-06-a/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-06T16:30:00Z; from `claude-code-1paper-all-modes-2026-11-06.json`; evidence complete.

### blind · claude-code · 2026-11-06-b

[`blind/claude-code/2026-11-06-b/CELL.md`](blind/claude-code/2026-11-06-b/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 3; 2026-11-06T17:48:30Z; from `claude-code-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### blind · claude-code · 2026-11-06-c

[`blind/claude-code/2026-11-06-c/CELL.md`](blind/claude-code/2026-11-06-c/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 2; 2026-11-06T17:50:40Z; from `claude-code-run3-1paper-indep-blind-2026-11-06.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261106T163912Z

[`blind/pipeline-desktop-opus/20261106T163912Z/CELL.md`](blind/pipeline-desktop-opus/20261106T163912Z/CELL.md) — final 6/12, re-scored 6/12; first scored 6/12; executions 1; 2026-11-06T16:39:12Z; from `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261106T173743Z

[`blind/pipeline-desktop-opus-run2/20261106T173743Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261106T173743Z/CELL.md) — final 6/12, re-scored 6/12; first scored 6/12; executions 1; 2026-11-06T17:37:43Z; from `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-06.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261106T174057Z

[`blind/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261106T174057Z/CELL.md) — final 12/12, re-scored 12/12; first scored 12/12; executions 1; 2026-11-06T17:40:57Z; from `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json`; evidence complete.

