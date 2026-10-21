# Retally benchmark report

Catalog size: **10** papers, each run in 3 reproduction modes.  
Runs (paper × mode): **27**.  
Executed runs: **27**.  
Skipped runs: **0** (out_of_scope=0, language_unsupported=0, no_api_key=0).  

Reproduction modes:

- **seeded**: the authors' replication-package scripts were in the generation prompt — computational reproduction.
- **independent**: the authors' scripts were withheld; reproduced from the paper text — independent reproduction.
- **blind**: the authors' scripts and the claimed values were withheld, with no claim-targeted refinement — blind reproduction, free of target-guided search.

Reproducer: **pipeline**.

## Verdicts — seeded (among executed papers)

- Pipeline completed without crashing: **10 / 10**
- Agrees with the paper's stated values: **5 / 10**
- Agrees with the I4R replicator: **4 / 10** (of papers where I4R published a value to compare against)

## Verdicts — independent (among executed papers)

- Pipeline completed without crashing: **10 / 10**
- Agrees with the paper's stated values: **1 / 10**
- Agrees with the I4R replicator: **1 / 10** (of papers where I4R published a value to compare against)

## Verdicts — blind (among executed papers)

- Pipeline completed without crashing: **7 / 7**
- Agrees with the paper's stated values: **1 / 7**
- Agrees with the I4R replicator: **2 / 7** (of papers where I4R published a value to compare against)

## Seeded vs independent vs blind

Claims passing with the authors' scripts in the prompt (seeded) versus without them (independent), per paper executed in both modes.  *Lost* claims pass seeded but not independent — what the scripts were carrying.
*Blind* withholds the claim values too and runs no claim-targeted refinement: its pass counts are the only ones free of target-guided search.

- Seeded: **85 / 114** claims passed (first scored 75 / 114)
- Independent: **64 / 114** claims passed (first scored 44 / 114)
- Blind: **24 / 79** claims passed (on 7 of 10 papers) (first scored 24 / 79)
- Lost without the scripts: **28**; gained: **7**

*First scored* is what each mode's first script that printed results passed: after any crash repairs, before the refinement loop showed the model which claims were off target.

| Entry | Split | Reproducer | Seeded | Independent | Blind | First scored (seeded / independent / blind) | Lost without scripts |
|---|---|---|---|---|---|---|---|
| `adams-2023-women-mps-affective-polarization` | holdout | pipeline | 11/11 | 7/11 | 1/11 | 11/11 / 0/11 / 1/11 | `n_directed_dyads`, `n_obs_men_partisans`, `n_obs_women_partisans`, `women_mps_coef_men_partisans` |
| `alesina-2022-immigration-redistribution` | dev | pipeline | 7/11 | 7/11 | — | 7/11 / 1/11 / —/— | `order_effect_social_budget`, `sample_size_table4` |
| `arias-2022-changing-tides-climate-migration` | holdout | pipeline | 4/12 | 0/12 | 1/12 | 4/12 / 0/12 / 1/12 | `choice_tasks_germany`, `choice_tasks_us`, `respondents_germany`, `respondents_us` |
| `bisbee-2022-flight-to-safety` | dev | pipeline | 10/11 | 5/11 | — | 9/11 / 5/11 / —/— | `exposure_coefficient_march_basic`, `exposure_coefficient_march_cbps`, `sample_size_full`, `sample_size_march`, `tea_party_x_cases_interaction` |
| `dincecco-2022-india-warfare` | dev | pipeline | 13/13 | 11/13 | — | 13/13 / 11/13 / —/— | `warfare_iv_se_full_controls`, `warfare_se_full_controls` |
| `grier-2023-sugar-roll-call-voting` | holdout | pipeline | 0/11 | 0/11 | 0/11 | 0/11 / 0/11 / 0/11 | — |
| `hanlon-2022-aircraft-ip-spillovers` | holdout | pipeline | 12/12 | 10/12 | 12/12 | 12/12 / 10/12 / 12/12 | `airframe_maxspeed_trend_after_1926_us`, `airframe_maxspeed_trend_before_1926_us` |
| `leeson-2022-hobo-economicus` | holdout | pipeline | 11/11 | 9/11 | 4/11 | 11/11 / 9/11 / 4/11 | `friendliness_full_sample`, `station_visits_five_station_subsample` |
| `manekin-2022-effective-for-whom` | holdout | pipeline | 7/12 | 12/12 | 6/12 | 8/12 / 6/12 / 6/12 | — |
| `montero-2022-cooperative-property-rights` | holdout | pipeline | 10/10 | 3/10 | 0/10 | 0/10 / 2/10 / 0/10 | `earnings_iqr_above500_bw150`, `earnings_iqr_above500_bw300`, `earnings_level_above500_bw150`, `n_clusters_bw150`, `n_clusters_bw300`, `n_obs_earnings_iqr_bw150`, `n_obs_earnings_iqr_bw300` |

## Closeness (per split and mode)

- **dev · seeded**: 3 entries, 35 claims, matched 100%, passed 30/35, median rel err 0.2%, within tol/2x/5x: 86%/94%/97%
- **holdout · seeded**: 7 entries, 79 claims, matched 99%, passed 55/79, median rel err 0.3%, within tol/2x/5x: 71%/71%/74%
- **dev · independent**: 3 entries, 35 claims, matched 100%, passed 23/35, median rel err 6.0%, within tol/2x/5x: 66%/80%/86%
- **holdout · independent**: 7 entries, 79 claims, matched 85%, passed 41/79, median rel err 4.9%, within tol/2x/5x: 61%/70%/85%
- **holdout · blind**: 7 entries, 79 claims, matched 90%, passed 24/79, median rel err 22.3%, within tol/2x/5x: 34%/38%/51%

## Per-component success — seeded (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 10 | 10 | 100% |
| claims_extracted | 10 | 10 | 100% |
| dataset_extracted | 0 | 10 | 0% |
| dataset_downloaded | 10 | 10 | 100% |
| code_generated | 10 | 10 | 100% |
| code_executed | 10 | 10 | 100% |

## Per-component success — independent (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 10 | 10 | 100% |
| claims_extracted | 10 | 10 | 100% |
| dataset_extracted | 0 | 10 | 0% |
| dataset_downloaded | 10 | 10 | 100% |
| code_generated | 10 | 10 | 100% |
| code_executed | 9 | 10 | 90% |

## Per-component success — blind (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 7 | 7 | 100% |
| claims_extracted | 7 | 7 | 100% |
| dataset_extracted | 0 | 7 | 0% |
| dataset_downloaded | 7 | 7 | 100% |
| code_generated | 7 | 7 | 100% |
| code_executed | 7 | 7 | 100% |

## Estimated API cost

Total estimated spend this run: **$11.97** across 106 API calls (36 further calls served free by the LLM cache).  Estimates from the price table in `benchmark/pricing.py`.

| ID | Mode | Reproducer | API calls | LLM-cache hits | Input tok | Output tok | Cache write tok | Cache read tok | Est. cost |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| `dincecco-2022-india-warfare` | seeded | pipeline | 1 | 3 | 36,013 | 1,813 | 0 | 0 | $0.23 |
| `dincecco-2022-india-warfare` | independent | pipeline | 5 | 2 | 33,260 | 13,398 | 0 | 0 | $0.50 |
| `alesina-2022-immigration-redistribution` | seeded | pipeline | 4 | 3 | 120,666 | 23,942 | 0 | 0 | $1.20 |
| `alesina-2022-immigration-redistribution` | independent | pipeline | 4 | 2 | 35,777 | 19,890 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | seeded | pipeline | 4 | 3 | 75,442 | 12,209 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | independent | pipeline | 4 | 2 | 34,082 | 16,081 | 0 | 0 | $0.57 |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline | 4 | 0 | 39,299 | 2,309 | 0 | 0 | $0.25 |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline | 5 | 2 | 30,427 | 11,966 | 0 | 0 | $0.45 |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline | 3 | 1 | 29,148 | 8,495 | 0 | 0 | $0.36 |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline | 6 | 0 | 64,642 | 18,643 | 0 | 0 | $0.79 |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline | 7 | 2 | 51,538 | 36,331 | 0 | 0 | $1.17 |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline | 3 | 1 | 31,427 | 13,034 | 0 | 0 | $0.48 |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline | 5 | 0 | 28,129 | 3,190 | 0 | 0 | $0.22 |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline | 4 | 2 | 11,412 | 5,215 | 0 | 0 | $0.19 |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline | 4 | 1 | 25,407 | 9,526 | 0 | 0 | $0.37 |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline | 4 | 0 | 89,192 | 2,794 | 0 | 0 | $0.52 |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline | 2 | 2 | 14,485 | 4,755 | 0 | 0 | $0.19 |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline | 3 | 1 | 32,275 | 4,781 | 0 | 0 | $0.28 |
| `leeson-2022-hobo-economicus` | seeded | pipeline | 4 | 0 | 33,208 | 3,235 | 0 | 0 | $0.25 |
| `leeson-2022-hobo-economicus` | independent | pipeline | 2 | 2 | 12,118 | 6,275 | 0 | 0 | $0.22 |
| `leeson-2022-hobo-economicus` | blind | pipeline | 2 | 1 | 21,415 | 3,784 | 0 | 0 | $0.20 |
| `manekin-2022-effective-for-whom` | seeded | pipeline | 8 | 0 | 57,810 | 11,875 | 0 | 0 | $0.59 |
| `manekin-2022-effective-for-whom` | independent | pipeline | 3 | 2 | 16,068 | 6,770 | 0 | 0 | $0.25 |
| `manekin-2022-effective-for-whom` | blind | pipeline | 2 | 1 | 28,741 | 3,814 | 0 | 0 | $0.24 |
| `montero-2022-cooperative-property-rights` | seeded | pipeline | 5 | 0 | 43,625 | 6,014 | 0 | 0 | $0.37 |
| `montero-2022-cooperative-property-rights` | independent | pipeline | 6 | 2 | 31,941 | 13,631 | 0 | 0 | $0.50 |
| `montero-2022-cooperative-property-rights` | blind | pipeline | 2 | 1 | 25,533 | 4,342 | 0 | 0 | $0.24 |

## Per-paper results

| ID | Mode | Reproducer | Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |
|---|---|---|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 13 / 13 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dincecco-2022-india-warfare` | independent | pipeline | ran | ✓ | ✗ | ✗ | 11 / 11 of 13 (first scored 11/13, 1 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 7/11, 0 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | independent | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 1/11, 0 error + 3 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 10 / 10 of 11 (first scored 9/11, 1 error + 2 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | independent | pipeline | ran | ✓ | ✗ | ✗ | 5 / 5 of 11 (first scored 5/11, 0 error + 3 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 0/11, 1 error + 3 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline | ran | ✓ | ✗ | ✗ | 1 / 1 of 11 (first scored 1/11, 1 error + 0 claim refinement) |  |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 4 / 4 of 12 (first scored 4/12, 1 error + 1 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline | ran | ✓ | ✗ | ✗ | 0 / 0 of 12 (first scored 0/12, 3 error + 3 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline | ran | ✓ | ✗ | ✗ | 1 / 1 of 12 (first scored 1/12, 1 error + 0 claim refinement) |  |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 0 error + 1 claim refinement) |  |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 3 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 2 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline | ran | ✓ | ✗ | ✗ | 10 / 10 of 12 (first scored 10/12, 0 error + 1 claim refinement) |  |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 1 error + 0 claim refinement) |  |
| `leeson-2022-hobo-economicus` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | independent | pipeline | ran | ✓ | ✗ | ✗ | 9 / 9 of 11 (first scored 9/11, 0 error + 1 claim refinement) |  |
| `leeson-2022-hobo-economicus` | blind | pipeline | ran | ✓ | ✗ | ✗ | 4 / 4 of 11 (first scored 4/11, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 12 (first scored 8/12, 1 error + 3 claim refinements) |  |
| `manekin-2022-effective-for-whom` | independent | pipeline | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 6/12, 1 error + 1 claim refinements) |  |
| `manekin-2022-effective-for-whom` | blind | pipeline | ran | ✓ | ✗ | ✓ | 6 / 6 of 12 (first scored 6/12, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | seeded | pipeline | ran | ✓ | ✓ | ✗ | 10 / 3 of 10 (first scored 0/10, 0 error + 1 claim refinement) |  |
| `montero-2022-cooperative-property-rights` | independent | pipeline | ran | ✓ | ✗ | ✗ | 3 / 0 of 10 (first scored 2/10, 2 error + 3 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | blind | pipeline | ran | ✓ | ✗ | ✗ | 0 / 0 of 10 (first scored 0/10, 0 error + 0 claim refinements) |  |
