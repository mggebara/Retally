# Retally benchmark report

Catalog size: **16** papers, each run in 3 reproduction modes.  
Runs (paper × mode): **105**.  
Executed runs: **105**.  
Skipped runs: **0** (out_of_scope=0, language_unsupported=0, no_api_key=0).  

Reproduction modes:

- **seeded**: the authors' replication-package scripts were in the generation prompt — computational reproduction.
- **independent**: the authors' scripts were withheld; reproduced from the paper text — independent reproduction.
- **blind**: the authors' scripts and the claimed values were withheld, with no claim-targeted refinement — blind reproduction, free of target-guided search.

Reproducer: **claude-code**, **pipeline (claude-opus-4-7)**, **pipeline (claude-opus-5-5)**, **pipeline (desktop-opus)**.

## Verdicts — seeded · claude-code (among executed papers)

- Pipeline completed without crashing: **13 / 13**
- Agrees with the paper's stated values: **12 / 13**
- Agrees with the I4R replicator: **10 / 12** (of papers where I4R published a value to compare against)

## Verdicts — independent · claude-code (among executed papers)

- Pipeline completed without crashing: **13 / 13**
- Agrees with the paper's stated values: **10 / 13**
- Agrees with the I4R replicator: **9 / 12** (of papers where I4R published a value to compare against)

## Verdicts — blind · claude-code (among executed papers)

- Pipeline completed without crashing: **13 / 13**
- Agrees with the paper's stated values: **8 / 13**
- Agrees with the I4R replicator: **7 / 12** (of papers where I4R published a value to compare against)

## Verdicts — seeded · pipeline (claude-opus-4-7) (among executed papers)

- Pipeline completed without crashing: **10 / 10**
- Agrees with the paper's stated values: **5 / 10**
- Agrees with the I4R replicator: **4 / 10** (of papers where I4R published a value to compare against)

## Verdicts — independent · pipeline (claude-opus-4-7) (among executed papers)

- Pipeline completed without crashing: **10 / 10**
- Agrees with the paper's stated values: **1 / 10**
- Agrees with the I4R replicator: **1 / 10** (of papers where I4R published a value to compare against)

## Verdicts — blind · pipeline (claude-opus-4-7) (among executed papers)

- Pipeline completed without crashing: **7 / 7**
- Agrees with the paper's stated values: **1 / 7**
- Agrees with the I4R replicator: **2 / 7** (of papers where I4R published a value to compare against)

## Verdicts — seeded · pipeline (claude-opus-5-5) (among executed papers)

- Pipeline completed without crashing: **4 / 4**
- Agrees with the paper's stated values: **4 / 4**
- Agrees with the I4R replicator: **3 / 4** (of papers where I4R published a value to compare against)

## Verdicts — independent · pipeline (claude-opus-5-5) (among executed papers)

- Pipeline completed without crashing: **4 / 4**
- Agrees with the paper's stated values: **3 / 4**
- Agrees with the I4R replicator: **2 / 4** (of papers where I4R published a value to compare against)

## Verdicts — blind · pipeline (claude-opus-5-5) (among executed papers)

- Pipeline completed without crashing: **4 / 4**
- Agrees with the paper's stated values: **1 / 4**
- Agrees with the I4R replicator: **1 / 4** (of papers where I4R published a value to compare against)

## Verdicts — seeded · pipeline (desktop-opus) (among executed papers)

- Pipeline completed without crashing: **9 / 9**
- Agrees with the paper's stated values: **8 / 9**
- Agrees with the I4R replicator: **6 / 8** (of papers where I4R published a value to compare against)

## Verdicts — independent · pipeline (desktop-opus) (among executed papers)

- Pipeline completed without crashing: **9 / 9**
- Agrees with the paper's stated values: **5 / 9**
- Agrees with the I4R replicator: **5 / 8** (of papers where I4R published a value to compare against)

## Verdicts — blind · pipeline (desktop-opus) (among executed papers)

- Pipeline completed without crashing: **9 / 9**
- Agrees with the paper's stated values: **2 / 9**
- Agrees with the I4R replicator: **2 / 8** (of papers where I4R published a value to compare against)

## Seeded vs independent vs blind

Claims passing with the authors' scripts in the prompt (seeded) versus without them (independent), per paper executed in both modes.  *Lost* claims pass seeded but not independent — what the scripts were carrying.
*Blind* withholds the claim values too and runs no claim-targeted refinement: its pass counts are the only ones free of target-guided search.

- claude-code · Seeded: **153 / 154** claims passed (first scored 151 / 154)
- claude-code · Independent: **148 / 154** claims passed (first scored 146 / 154)
- claude-code · Blind: **135 / 154** claims passed (first scored 128 / 154)
- claude-code · Lost without the scripts: **5**; gained: **0**
- pipeline (claude-opus-4-7) · Seeded: **85 / 114** claims passed (first scored 75 / 114)
- pipeline (claude-opus-4-7) · Independent: **64 / 114** claims passed (first scored 44 / 114)
- pipeline (claude-opus-4-7) · Blind: **24 / 79** claims passed (on 7 of 10 papers) (first scored 24 / 79)
- pipeline (claude-opus-4-7) · Lost without the scripts: **28**; gained: **7**
- pipeline (claude-opus-5-5) · Seeded: **44 / 44** claims passed (first scored 43 / 44)
- pipeline (claude-opus-5-5) · Independent: **33 / 44** claims passed (first scored 21 / 44)
- pipeline (claude-opus-5-5) · Blind: **20 / 44** claims passed (first scored 20 / 44)
- pipeline (claude-opus-5-5) · Lost without the scripts: **11**; gained: **0**
- pipeline (desktop-opus) · Seeded: **105 / 110** claims passed (first scored 105 / 110)
- pipeline (desktop-opus) · Independent: **96 / 110** claims passed (first scored 68 / 110)
- pipeline (desktop-opus) · Blind: **72 / 110** claims passed (first scored 72 / 110)
- pipeline (desktop-opus) · Lost without the scripts: **14**; gained: **5**

*First scored* is what each mode's first script that printed results passed: after any crash repairs, before the refinement loop showed the model which claims were off target.

| Entry | Split | Reproducer | Seeded | Independent | Blind | First scored (seeded / independent / blind) | Lost without scripts |
|---|---|---|---|---|---|---|---|
| `acemoglu-2022-war-socialism-fascism` | holdout | claude-code | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 10/12 | — |
| `acemoglu-2022-war-socialism-fascism` | holdout | pipeline (desktop-opus) | 12/12 | 11/12 | 4/12 | 12/12 / 4/12 / 4/12 | `first_stage_fstat_table1_col6` |
| `adams-2023-women-mps-affective-polarization` | holdout | claude-code | 11/11 | 11/11 | 8/11 | 11/11 / 11/11 / 8/11 | — |
| `adams-2023-women-mps-affective-polarization` | holdout | pipeline (claude-opus-4-7) | 11/11 | 7/11 | 1/11 | 11/11 / 0/11 / 1/11 | `n_directed_dyads`, `n_obs_men_partisans`, `n_obs_women_partisans`, `women_mps_coef_men_partisans` |
| `adams-2023-women-mps-affective-polarization` | holdout | pipeline (desktop-opus) | 11/11 | 10/11 | 7/11 | 11/11 / 6/11 / 7/11 | `women_mps_coef_men_partisans` |
| `alesina-2022-immigration-redistribution` | dev | pipeline (claude-opus-4-7) | 7/11 | 7/11 | — | 7/11 / 1/11 / —/— | `order_effect_social_budget`, `sample_size_table4` |
| `altmann-2022-cognitive-spillovers` | holdout | claude-code | 13/13 | 13/13 | 13/13 | 13/13 / 13/13 / 13/13 | — |
| `altmann-2022-cognitive-spillovers` | holdout | pipeline (desktop-opus) | 13/13 | 13/13 | 4/13 | 13/13 / 4/13 / 4/13 | — |
| `arias-2022-changing-tides-climate-migration` | holdout | claude-code | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 12/12 | — |
| `arias-2022-changing-tides-climate-migration` | holdout | pipeline (claude-opus-4-7) | 4/12 | 0/12 | 1/12 | 4/12 / 0/12 / 1/12 | `choice_tasks_germany`, `choice_tasks_us`, `respondents_germany`, `respondents_us` |
| `arias-2022-changing-tides-climate-migration` | holdout | pipeline (desktop-opus) | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 12/12 | — |
| `bisbee-2022-flight-to-safety` | dev | pipeline (claude-opus-4-7) | 10/11 | 5/11 | — | 9/11 / 5/11 / —/— | `exposure_coefficient_march_basic`, `exposure_coefficient_march_cbps`, `sample_size_full`, `sample_size_march`, `tea_party_x_cases_interaction` |
| `dertwinkel-kalt-2022-concentration-bias` | holdout | claude-code | 13/13 | 13/13 | 13/13 | 13/13 / 12/13 / 13/13 | — |
| `dertwinkel-kalt-2022-concentration-bias` | holdout | pipeline (desktop-opus) | 13/13 | 13/13 | 12/13 | 13/13 / 13/13 / 12/13 | — |
| `dincecco-2022-india-warfare` | dev | pipeline (claude-opus-4-7) | 13/13 | 11/13 | — | 13/13 / 11/13 / —/— | `warfare_iv_se_full_controls`, `warfare_se_full_controls` |
| `gagliarducci-2022-gender-cooperation-congress` | holdout | claude-code | 13/13 | 13/13 | 7/13 | 11/13 / 13/13 / 7/13 | — |
| `gagliarducci-2022-gender-cooperation-congress` | holdout | pipeline (desktop-opus) | 8/13 | 13/13 | 12/13 | 8/13 / 7/13 / 12/13 | — |
| `grier-2023-sugar-roll-call-voting` | holdout | claude-code | 10/11 | 10/11 | 10/11 | 10/11 / 10/11 / 10/11 | — |
| `grier-2023-sugar-roll-call-voting` | holdout | pipeline (claude-opus-4-7) | 0/11 | 0/11 | 0/11 | 0/11 / 0/11 / 0/11 | — |
| `grier-2023-sugar-roll-call-voting` | holdout | pipeline (claude-opus-5-5) | 11/11 | 0/11 | 0/11 | 10/11 / 0/11 / 0/11 | `acu_ideology_district_fe`, `observations_district_fe`, `observations_incumbent_fe`, `sugar_contributions_12_months_district_fe`, `sugar_contributions_12_months_incumbent_fe`, `sugar_contributions_calendar_year_district_fe`, `sugar_contributions_calendar_year_incumbent_fe`, `sugar_contributions_district_fe`, `sugar_contributions_incumbent_fe`, `tenure_district_fe`, `tenure_incumbent_fe` |
| `hanlon-2022-aircraft-ip-spillovers` | holdout | claude-code | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 8/12 | — |
| `hanlon-2022-aircraft-ip-spillovers` | holdout | pipeline (claude-opus-4-7) | 12/12 | 10/12 | 12/12 | 12/12 / 10/12 / 12/12 | `airframe_maxspeed_trend_after_1926_us`, `airframe_maxspeed_trend_before_1926_us` |
| `hanlon-2022-aircraft-ip-spillovers` | holdout | pipeline (desktop-opus) | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 12/12 | — |
| `holman-2022-theresa-may-rally` | holdout | claude-code | 11/11 | 10/11 | 6/11 | 11/11 / 10/11 / 6/11 | `n_obs_table4` |
| `holman-2022-theresa-may-rally` | holdout | pipeline (desktop-opus) | 11/11 | 3/11 | 0/11 | 11/11 / 1/11 / 0/11 | `did_attack_like_may_table2`, `did_attack_x_time_like_may_table2`, `did_time_like_may_table2`, `did_time_may_best_pm_table2`, `intl_attack_table4`, `intl_attack_x_woman_exec_table4`, `n_obs_did_like_may_table2`, `n_obs_did_may_best_pm_table2` |
| `leeson-2022-hobo-economicus` | holdout | claude-code | 11/11 | 11/11 | 11/11 | 11/11 / 10/11 / 10/11 | — |
| `leeson-2022-hobo-economicus` | holdout | pipeline (claude-opus-4-7) | 11/11 | 9/11 | 4/11 | 11/11 / 9/11 / 4/11 | `friendliness_full_sample`, `station_visits_five_station_subsample` |
| `leeson-2022-hobo-economicus` | holdout | pipeline (claude-opus-5-5) | 11/11 | 11/11 | 8/11 | 11/11 / 8/11 / 8/11 | — |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | holdout | claude-code | 13/13 | 9/13 | 9/13 | 13/13 / 9/13 / 9/13 | `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`, `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3` |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | holdout | pipeline (desktop-opus) | 13/13 | 9/13 | 9/13 | 13/13 / 9/13 / 9/13 | `itt_gender_index_akbayan_tableC4`, `itt_gender_index_umalabka_tableC4`, `itt_poverty_index_akbayan_tableC3`, `itt_poverty_index_umalabka_tableC3` |
| `manekin-2022-effective-for-whom` | holdout | claude-code | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 12/12 | — |
| `manekin-2022-effective-for-whom` | holdout | pipeline (claude-opus-4-7) | 7/12 | 12/12 | 6/12 | 8/12 / 6/12 / 6/12 | — |
| `manekin-2022-effective-for-whom` | holdout | pipeline (claude-opus-5-5) | 12/12 | 12/12 | 12/12 | 12/12 / 12/12 / 12/12 | — |
| `montero-2022-cooperative-property-rights` | holdout | claude-code | 10/10 | 10/10 | 10/10 | 10/10 / 10/10 / 10/10 | — |
| `montero-2022-cooperative-property-rights` | holdout | pipeline (claude-opus-4-7) | 10/10 | 3/10 | 0/10 | 0/10 / 2/10 / 0/10 | `earnings_iqr_above500_bw150`, `earnings_iqr_above500_bw300`, `earnings_level_above500_bw150`, `n_clusters_bw150`, `n_clusters_bw300`, `n_obs_earnings_iqr_bw150`, `n_obs_earnings_iqr_bw300` |
| `montero-2022-cooperative-property-rights` | holdout | pipeline (claude-opus-5-5) | 10/10 | 10/10 | 0/10 | 10/10 / 1/10 / 0/10 | — |

## Closeness (per split and mode)

- **claude-code · holdout · seeded**: 13 entries, 154 claims, matched 100%, passed 153/154, median rel err 0.0%, within tol/2x/5x: 99%/100%/100%
- **claude-code · holdout · independent**: 13 entries, 154 claims, matched 100%, passed 148/154, median rel err 0.2%, within tol/2x/5x: 96%/97%/97%
- **claude-code · holdout · blind**: 13 entries, 154 claims, matched 100%, passed 135/154, median rel err 0.3%, within tol/2x/5x: 88%/91%/93%
- **pipeline (claude-opus-4-7) · dev · seeded**: 3 entries, 35 claims, matched 100%, passed 30/35, median rel err 0.2%, within tol/2x/5x: 86%/94%/97%
- **pipeline (claude-opus-4-7) · holdout · seeded**: 7 entries, 79 claims, matched 99%, passed 55/79, median rel err 0.3%, within tol/2x/5x: 71%/71%/74%
- **pipeline (claude-opus-4-7) · dev · independent**: 3 entries, 35 claims, matched 100%, passed 23/35, median rel err 6.0%, within tol/2x/5x: 66%/80%/86%
- **pipeline (claude-opus-4-7) · holdout · independent**: 7 entries, 79 claims, matched 85%, passed 41/79, median rel err 4.9%, within tol/2x/5x: 61%/70%/85%
- **pipeline (claude-opus-4-7) · holdout · blind**: 7 entries, 79 claims, matched 90%, passed 24/79, median rel err 22.3%, within tol/2x/5x: 34%/38%/51%
- **pipeline (claude-opus-5-5) · holdout · seeded**: 4 entries, 44 claims, matched 100%, passed 44/44, median rel err 0.0%, within tol/2x/5x: 100%/100%/100%
- **pipeline (claude-opus-5-5) · holdout · independent**: 4 entries, 44 claims, matched 100%, passed 33/44, median rel err 0.1%, within tol/2x/5x: 75%/75%/82%
- **pipeline (claude-opus-5-5) · holdout · blind**: 4 entries, 44 claims, matched 95%, passed 20/44, median rel err 5.7%, within tol/2x/5x: 48%/48%/55%
- **pipeline (desktop-opus) · holdout · seeded**: 9 entries, 110 claims, matched 100%, passed 105/110, median rel err 0.1%, within tol/2x/5x: 95%/96%/96%
- **pipeline (desktop-opus) · holdout · independent**: 9 entries, 110 claims, matched 100%, passed 96/110, median rel err 0.8%, within tol/2x/5x: 87%/90%/93%
- **pipeline (desktop-opus) · holdout · blind**: 9 entries, 110 claims, matched 95%, passed 72/110, median rel err 2.0%, within tol/2x/5x: 69%/78%/85%

## Per-component success — seeded · claude-code (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 13 | 13 | 100% |
| claims_extracted | 0 | 13 | 0% |
| dataset_extracted | 0 | 13 | 0% |
| dataset_downloaded | 13 | 13 | 100% |
| code_generated | 13 | 13 | 100% |
| code_executed | 13 | 13 | 100% |

## Per-component success — independent · claude-code (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 13 | 13 | 100% |
| claims_extracted | 0 | 13 | 0% |
| dataset_extracted | 0 | 13 | 0% |
| dataset_downloaded | 13 | 13 | 100% |
| code_generated | 13 | 13 | 100% |
| code_executed | 13 | 13 | 100% |

## Per-component success — blind · claude-code (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 13 | 13 | 100% |
| claims_extracted | 0 | 13 | 0% |
| dataset_extracted | 0 | 13 | 0% |
| dataset_downloaded | 13 | 13 | 100% |
| code_generated | 13 | 13 | 100% |
| code_executed | 13 | 13 | 100% |

## Per-component success — seeded · pipeline (claude-opus-4-7) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 10 | 10 | 100% |
| claims_extracted | 10 | 10 | 100% |
| dataset_extracted | 0 | 10 | 0% |
| dataset_downloaded | 10 | 10 | 100% |
| code_generated | 10 | 10 | 100% |
| code_executed | 10 | 10 | 100% |

## Per-component success — independent · pipeline (claude-opus-4-7) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 10 | 10 | 100% |
| claims_extracted | 10 | 10 | 100% |
| dataset_extracted | 0 | 10 | 0% |
| dataset_downloaded | 10 | 10 | 100% |
| code_generated | 10 | 10 | 100% |
| code_executed | 9 | 10 | 90% |

## Per-component success — blind · pipeline (claude-opus-4-7) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 7 | 7 | 100% |
| claims_extracted | 7 | 7 | 100% |
| dataset_extracted | 0 | 7 | 0% |
| dataset_downloaded | 7 | 7 | 100% |
| code_generated | 7 | 7 | 100% |
| code_executed | 7 | 7 | 100% |

## Per-component success — seeded · pipeline (claude-opus-5-5) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 4 | 4 | 100% |
| claims_extracted | 4 | 4 | 100% |
| dataset_extracted | 0 | 4 | 0% |
| dataset_downloaded | 4 | 4 | 100% |
| code_generated | 4 | 4 | 100% |
| code_executed | 4 | 4 | 100% |

## Per-component success — independent · pipeline (claude-opus-5-5) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 4 | 4 | 100% |
| claims_extracted | 4 | 4 | 100% |
| dataset_extracted | 0 | 4 | 0% |
| dataset_downloaded | 4 | 4 | 100% |
| code_generated | 4 | 4 | 100% |
| code_executed | 4 | 4 | 100% |

## Per-component success — blind · pipeline (claude-opus-5-5) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 4 | 4 | 100% |
| claims_extracted | 4 | 4 | 100% |
| dataset_extracted | 0 | 4 | 0% |
| dataset_downloaded | 4 | 4 | 100% |
| code_generated | 4 | 4 | 100% |
| code_executed | 4 | 4 | 100% |

## Per-component success — seeded · pipeline (desktop-opus) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 9 | 9 | 100% |
| claims_extracted | 9 | 9 | 100% |
| dataset_extracted | 0 | 9 | 0% |
| dataset_downloaded | 9 | 9 | 100% |
| code_generated | 9 | 9 | 100% |
| code_executed | 9 | 9 | 100% |

## Per-component success — independent · pipeline (desktop-opus) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 9 | 9 | 100% |
| claims_extracted | 9 | 9 | 100% |
| dataset_extracted | 0 | 9 | 0% |
| dataset_downloaded | 9 | 9 | 100% |
| code_generated | 9 | 9 | 100% |
| code_executed | 9 | 9 | 100% |

## Per-component success — blind · pipeline (desktop-opus) (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 9 | 9 | 100% |
| claims_extracted | 9 | 9 | 100% |
| dataset_extracted | 0 | 9 | 0% |
| dataset_downloaded | 9 | 9 | 100% |
| code_generated | 9 | 9 | 100% |
| code_executed | 9 | 9 | 100% |

## Estimated API cost

Total estimated spend this run: **$15.51** across 253 API calls (48 further calls served free by the LLM cache).  Estimates from the price table in `benchmark/pricing.py`.  Not priced (absent from the table): `desktop-opus`.

| ID | Mode | Reproducer | API calls | LLM-cache hits | Input tok | Output tok | Cache write tok | Cache read tok | Est. cost |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| `dincecco-2022-india-warfare` | seeded | pipeline (claude-opus-4-7) | 1 | 3 | 36,013 | 1,813 | 0 | 0 | $0.23 |
| `dincecco-2022-india-warfare` | independent | pipeline (claude-opus-4-7) | 5 | 2 | 33,260 | 13,398 | 0 | 0 | $0.50 |
| `alesina-2022-immigration-redistribution` | seeded | pipeline (claude-opus-4-7) | 4 | 3 | 120,666 | 23,942 | 0 | 0 | $1.20 |
| `alesina-2022-immigration-redistribution` | independent | pipeline (claude-opus-4-7) | 4 | 2 | 35,777 | 19,890 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | seeded | pipeline (claude-opus-4-7) | 4 | 3 | 75,442 | 12,209 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | independent | pipeline (claude-opus-4-7) | 4 | 2 | 34,082 | 16,081 | 0 | 0 | $0.57 |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline (claude-opus-4-7) | 4 | 0 | 39,299 | 2,309 | 0 | 0 | $0.25 |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline (claude-opus-4-7) | 5 | 2 | 30,427 | 11,966 | 0 | 0 | $0.45 |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline (claude-opus-4-7) | 3 | 1 | 29,148 | 8,495 | 0 | 0 | $0.36 |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline (claude-opus-4-7) | 6 | 0 | 64,642 | 18,643 | 0 | 0 | $0.79 |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline (claude-opus-4-7) | 7 | 2 | 51,538 | 36,331 | 0 | 0 | $1.17 |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline (claude-opus-4-7) | 3 | 1 | 31,427 | 13,034 | 0 | 0 | $0.48 |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline (claude-opus-4-7) | 5 | 0 | 28,129 | 3,190 | 0 | 0 | $0.22 |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline (claude-opus-4-7) | 4 | 2 | 11,412 | 5,215 | 0 | 0 | $0.19 |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline (claude-opus-4-7) | 4 | 1 | 25,407 | 9,526 | 0 | 0 | $0.37 |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline (claude-opus-4-7) | 4 | 0 | 89,192 | 2,794 | 0 | 0 | $0.52 |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline (claude-opus-4-7) | 2 | 2 | 14,485 | 4,755 | 0 | 0 | $0.19 |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline (claude-opus-4-7) | 3 | 1 | 32,275 | 4,781 | 0 | 0 | $0.28 |
| `leeson-2022-hobo-economicus` | seeded | pipeline (claude-opus-4-7) | 4 | 0 | 33,208 | 3,235 | 0 | 0 | $0.25 |
| `leeson-2022-hobo-economicus` | independent | pipeline (claude-opus-4-7) | 2 | 2 | 12,118 | 6,275 | 0 | 0 | $0.22 |
| `leeson-2022-hobo-economicus` | blind | pipeline (claude-opus-4-7) | 2 | 1 | 21,415 | 3,784 | 0 | 0 | $0.20 |
| `manekin-2022-effective-for-whom` | seeded | pipeline (claude-opus-4-7) | 8 | 0 | 57,810 | 11,875 | 0 | 0 | $0.59 |
| `manekin-2022-effective-for-whom` | independent | pipeline (claude-opus-4-7) | 3 | 2 | 16,068 | 6,770 | 0 | 0 | $0.25 |
| `manekin-2022-effective-for-whom` | blind | pipeline (claude-opus-4-7) | 2 | 1 | 28,741 | 3,814 | 0 | 0 | $0.24 |
| `montero-2022-cooperative-property-rights` | seeded | pipeline (claude-opus-4-7) | 5 | 0 | 43,625 | 6,014 | 0 | 0 | $0.37 |
| `montero-2022-cooperative-property-rights` | independent | pipeline (claude-opus-4-7) | 6 | 2 | 31,941 | 13,631 | 0 | 0 | $0.50 |
| `montero-2022-cooperative-property-rights` | blind | pipeline (claude-opus-4-7) | 2 | 1 | 25,533 | 4,342 | 0 | 0 | $0.24 |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline (claude-opus-5-5) | 7 | 0 | 41,922 | 20,027 | 0 | 0 | $0.57 |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline (claude-opus-5-5) | 3 | 2 | 18,218 | 12,465 | 0 | 0 | $0.32 |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline (claude-opus-5-5) | 2 | 1 | 17,094 | 5,408 | 0 | 0 | $0.18 |
| `montero-2022-cooperative-property-rights` | seeded | pipeline (claude-opus-5-5) | 4 | 0 | 37,769 | 6,018 | 0 | 0 | $0.27 |
| `montero-2022-cooperative-property-rights` | independent | pipeline (claude-opus-5-5) | 4 | 2 | 23,415 | 16,976 | 0 | 0 | $0.43 |
| `montero-2022-cooperative-property-rights` | blind | pipeline (claude-opus-5-5) | 2 | 1 | 25,787 | 5,697 | 0 | 0 | $0.22 |
| `manekin-2022-effective-for-whom` | seeded | pipeline (claude-opus-5-5) | 4 | 0 | 58,085 | 4,763 | 0 | 0 | $0.33 |
| `manekin-2022-effective-for-whom` | independent | pipeline (claude-opus-5-5) | 1 | 2 | 7,278 | 4,096 | 0 | 0 | $0.11 |
| `manekin-2022-effective-for-whom` | blind | pipeline (claude-opus-5-5) | 2 | 1 | 29,172 | 5,580 | 0 | 0 | $0.23 |
| `leeson-2022-hobo-economicus` | seeded | pipeline (claude-opus-5-5) | 4 | 0 | 33,744 | 6,631 | 0 | 0 | $0.27 |
| `leeson-2022-hobo-economicus` | independent | pipeline (claude-opus-5-5) | 3 | 2 | 22,593 | 15,166 | 0 | 0 | $0.39 |
| `leeson-2022-hobo-economicus` | blind | pipeline (claude-opus-5-5) | 2 | 1 | 21,817 | 6,785 | 0 | 0 | $0.22 |
| `acemoglu-2022-war-socialism-fascism` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `acemoglu-2022-war-socialism-fascism` | independent | pipeline (desktop-opus) | 6 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `acemoglu-2022-war-socialism-fascism` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline (desktop-opus) | 6 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `altmann-2022-cognitive-spillovers` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `altmann-2022-cognitive-spillovers` | independent | pipeline (desktop-opus) | 5 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `altmann-2022-cognitive-spillovers` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `dertwinkel-kalt-2022-concentration-bias` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `dertwinkel-kalt-2022-concentration-bias` | independent | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `dertwinkel-kalt-2022-concentration-bias` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `gagliarducci-2022-gender-cooperation-congress` | seeded | pipeline (desktop-opus) | 6 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `gagliarducci-2022-gender-cooperation-congress` | independent | pipeline (desktop-opus) | 6 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `gagliarducci-2022-gender-cooperation-congress` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `holman-2022-theresa-may-rally` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `holman-2022-theresa-may-rally` | independent | pipeline (desktop-opus) | 5 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `holman-2022-theresa-may-rally` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | seeded | pipeline (desktop-opus) | 4 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | independent | pipeline (desktop-opus) | 6 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | blind | pipeline (desktop-opus) | 3 | 0 | 0 | 0 | 0 | 0 | $0.00 |
| `adams-2023-women-mps-affective-polarization` | seeded | claude-code | — | — | — | — | — | — | — |
| `adams-2023-women-mps-affective-polarization` | independent | claude-code | — | — | — | — | — | — | — |
| `adams-2023-women-mps-affective-polarization` | blind | claude-code | — | — | — | — | — | — | — |
| `arias-2022-changing-tides-climate-migration` | seeded | claude-code | — | — | — | — | — | — | — |
| `arias-2022-changing-tides-climate-migration` | independent | claude-code | — | — | — | — | — | — | — |
| `arias-2022-changing-tides-climate-migration` | blind | claude-code | — | — | — | — | — | — | — |
| `grier-2023-sugar-roll-call-voting` | seeded | claude-code | — | — | — | — | — | — | — |
| `grier-2023-sugar-roll-call-voting` | independent | claude-code | — | — | — | — | — | — | — |
| `grier-2023-sugar-roll-call-voting` | blind | claude-code | — | — | — | — | — | — | — |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | claude-code | — | — | — | — | — | — | — |
| `hanlon-2022-aircraft-ip-spillovers` | independent | claude-code | — | — | — | — | — | — | — |
| `hanlon-2022-aircraft-ip-spillovers` | blind | claude-code | — | — | — | — | — | — | — |
| `leeson-2022-hobo-economicus` | seeded | claude-code | — | — | — | — | — | — | — |
| `leeson-2022-hobo-economicus` | independent | claude-code | — | — | — | — | — | — | — |
| `leeson-2022-hobo-economicus` | blind | claude-code | — | — | — | — | — | — | — |
| `manekin-2022-effective-for-whom` | seeded | claude-code | — | — | — | — | — | — | — |
| `manekin-2022-effective-for-whom` | independent | claude-code | — | — | — | — | — | — | — |
| `manekin-2022-effective-for-whom` | blind | claude-code | — | — | — | — | — | — | — |
| `montero-2022-cooperative-property-rights` | seeded | claude-code | — | — | — | — | — | — | — |
| `montero-2022-cooperative-property-rights` | independent | claude-code | — | — | — | — | — | — | — |
| `montero-2022-cooperative-property-rights` | blind | claude-code | — | — | — | — | — | — | — |
| `acemoglu-2022-war-socialism-fascism` | seeded | claude-code | — | — | — | — | — | — | — |
| `acemoglu-2022-war-socialism-fascism` | independent | claude-code | — | — | — | — | — | — | — |
| `acemoglu-2022-war-socialism-fascism` | blind | claude-code | — | — | — | — | — | — | — |
| `altmann-2022-cognitive-spillovers` | seeded | claude-code | — | — | — | — | — | — | — |
| `altmann-2022-cognitive-spillovers` | independent | claude-code | — | — | — | — | — | — | — |
| `altmann-2022-cognitive-spillovers` | blind | claude-code | — | — | — | — | — | — | — |
| `dertwinkel-kalt-2022-concentration-bias` | seeded | claude-code | — | — | — | — | — | — | — |
| `dertwinkel-kalt-2022-concentration-bias` | independent | claude-code | — | — | — | — | — | — | — |
| `dertwinkel-kalt-2022-concentration-bias` | blind | claude-code | — | — | — | — | — | — | — |
| `gagliarducci-2022-gender-cooperation-congress` | seeded | claude-code | — | — | — | — | — | — | — |
| `gagliarducci-2022-gender-cooperation-congress` | independent | claude-code | — | — | — | — | — | — | — |
| `gagliarducci-2022-gender-cooperation-congress` | blind | claude-code | — | — | — | — | — | — | — |
| `holman-2022-theresa-may-rally` | seeded | claude-code | — | — | — | — | — | — | — |
| `holman-2022-theresa-may-rally` | independent | claude-code | — | — | — | — | — | — | — |
| `holman-2022-theresa-may-rally` | blind | claude-code | — | — | — | — | — | — | — |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | seeded | claude-code | — | — | — | — | — | — | — |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | independent | claude-code | — | — | — | — | — | — | — |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | blind | claude-code | — | — | — | — | — | — | — |

## Per-paper results

| ID | Mode | Reproducer | Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |
|---|---|---|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 13 / 13 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dincecco-2022-india-warfare` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 11 / 11 of 13 (first scored 11/13, 1 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 7/11, 0 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 1/11, 0 error + 3 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 10 / 10 of 11 (first scored 9/11, 1 error + 2 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 5 / 5 of 11 (first scored 5/11, 0 error + 3 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 0/11, 1 error + 3 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 1 / 1 of 11 (first scored 1/11, 1 error + 0 claim refinement) |  |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 4 / 4 of 12 (first scored 4/12, 1 error + 1 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 0 / 0 of 12 (first scored 0/12, 3 error + 3 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 1 / 1 of 12 (first scored 1/12, 1 error + 0 claim refinement) |  |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 0 error + 1 claim refinement) |  |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 3 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 2 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 10 / 10 of 12 (first scored 10/12, 0 error + 1 claim refinement) |  |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 1 error + 0 claim refinement) |  |
| `leeson-2022-hobo-economicus` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 9 / 9 of 11 (first scored 9/11, 0 error + 1 claim refinement) |  |
| `leeson-2022-hobo-economicus` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 4 / 4 of 11 (first scored 4/11, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 7 / 7 of 12 (first scored 8/12, 1 error + 3 claim refinements) |  |
| `manekin-2022-effective-for-whom` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 6/12, 1 error + 1 claim refinements) |  |
| `manekin-2022-effective-for-whom` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✓ | 6 / 6 of 12 (first scored 6/12, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | seeded | pipeline (claude-opus-4-7) | ran | ✓ | ✓ | ✗ | 10 / 3 of 10 (first scored 0/10, 0 error + 1 claim refinement) |  |
| `montero-2022-cooperative-property-rights` | independent | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 3 / 0 of 10 (first scored 2/10, 2 error + 3 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | blind | pipeline (claude-opus-4-7) | ran | ✓ | ✗ | ✗ | 0 / 0 of 10 (first scored 0/10, 0 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | seeded | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 11 / 7 of 11 (first scored 10/11, 0 error + 3 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | independent | pipeline (claude-opus-5-5) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 1 error + 1 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | blind | pipeline (claude-opus-5-5) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | seeded | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✗ | 10 / 3 of 10 (first scored 10/10, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | independent | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✗ | 10 / 4 of 10 (first scored 1/10, 2 error + 1 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | blind | pipeline (claude-opus-5-5) | ran | ✓ | ✗ | ✗ | 0 / 0 of 10 (first scored 0/10, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | seeded | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | independent | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | blind | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | seeded | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | independent | pipeline (claude-opus-5-5) | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 8/11, 0 error + 2 claim refinements) |  |
| `leeson-2022-hobo-economicus` | blind | pipeline (claude-opus-5-5) | ran | ✓ | ✗ | ✗ | 8 / 8 of 11 (first scored 8/11, 0 error + 0 claim refinements) |  |
| `acemoglu-2022-war-socialism-fascism` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | — | 12 / 0 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `acemoglu-2022-war-socialism-fascism` | independent | pipeline (desktop-opus) | ran | ✓ | ✗ | — | 11 / 0 of 12 (first scored 4/12, 0 error + 3 claim refinements) |  |
| `acemoglu-2022-war-socialism-fascism` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | — | 4 / 0 of 12 (first scored 4/12, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | independent | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 10 / 10 of 11 (first scored 6/11, 0 error + 3 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 7/11, 1 error + 0 claim refinement) |  |
| `altmann-2022-cognitive-spillovers` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `altmann-2022-cognitive-spillovers` | independent | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 4/13, 0 error + 2 claim refinements) |  |
| `altmann-2022-cognitive-spillovers` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 4 / 4 of 13 (first scored 4/13, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | independent | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | blind | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `dertwinkel-kalt-2022-concentration-bias` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dertwinkel-kalt-2022-concentration-bias` | independent | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dertwinkel-kalt-2022-concentration-bias` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 12 / 10 of 13 (first scored 12/13, 0 error + 0 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | seeded | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 8 / 4 of 13 (first scored 8/13, 0 error + 2 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | independent | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 9 of 13 (first scored 7/13, 0 error + 3 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 12 / 8 of 13 (first scored 12/13, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | independent | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | blind | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `holman-2022-theresa-may-rally` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✗ | 11 / 5 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `holman-2022-theresa-may-rally` | independent | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 3 / 2 of 11 (first scored 1/11, 0 error + 2 claim refinements) |  |
| `holman-2022-theresa-may-rally` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 0 / 0 of 11 (first scored 0/11, 0 error + 0 claim refinements) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | seeded | pipeline (desktop-opus) | ran | ✓ | ✓ | ✓ | 13 / 6 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | independent | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 9 / 2 of 13 (first scored 9/13, 0 error + 3 claim refinements) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | blind | pipeline (desktop-opus) | ran | ✓ | ✗ | ✗ | 9 / 2 of 13 (first scored 9/13, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | independent | claude-code | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `adams-2023-women-mps-affective-polarization` | blind | claude-code | ran | ✓ | ✗ | ✗ | 8 / 8 of 11 (first scored 8/11, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | independent | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `arias-2022-changing-tides-climate-migration` | blind | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | seeded | claude-code | ran | ✓ | ✗ | ✓ | 10 / 7 of 11 (first scored 10/11, 0 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | independent | claude-code | ran | ✓ | ✗ | ✓ | 10 / 7 of 11 (first scored 10/11, 0 error + 0 claim refinements) |  |
| `grier-2023-sugar-roll-call-voting` | blind | claude-code | ran | ✓ | ✗ | ✓ | 10 / 7 of 11 (first scored 10/11, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | independent | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `hanlon-2022-aircraft-ip-spillovers` | blind | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 8/12, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 11/11, 0 error + 0 claim refinements) |  |
| `leeson-2022-hobo-economicus` | independent | claude-code | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 10/11, 0 error + 1 claim refinement) |  |
| `leeson-2022-hobo-economicus` | blind | claude-code | ran | ✓ | ✓ | ✓ | 11 / 11 of 11 (first scored 10/11, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 1 error + 0 claim refinement) |  |
| `manekin-2022-effective-for-whom` | independent | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `manekin-2022-effective-for-whom` | blind | claude-code | ran | ✓ | ✓ | ✓ | 12 / 12 of 12 (first scored 12/12, 1 error + 0 claim refinement) |  |
| `montero-2022-cooperative-property-rights` | seeded | claude-code | ran | ✓ | ✓ | ✗ | 10 / 3 of 10 (first scored 10/10, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | independent | claude-code | ran | ✓ | ✓ | ✗ | 10 / 5 of 10 (first scored 10/10, 0 error + 0 claim refinements) |  |
| `montero-2022-cooperative-property-rights` | blind | claude-code | ran | ✓ | ✓ | ✗ | 10 / 5 of 10 (first scored 10/10, 0 error + 0 claim refinements) |  |
| `acemoglu-2022-war-socialism-fascism` | seeded | claude-code | ran | ✓ | ✓ | — | 12 / 0 of 12 (first scored 12/12, 0 error + 0 claim refinements) |  |
| `acemoglu-2022-war-socialism-fascism` | independent | claude-code | ran | ✓ | ✓ | — | 12 / 0 of 12 (first scored 12/12, 0 error + 1 claim refinement) |  |
| `acemoglu-2022-war-socialism-fascism` | blind | claude-code | ran | ✓ | ✓ | — | 12 / 0 of 12 (first scored 10/12, 0 error + 0 claim refinements) |  |
| `altmann-2022-cognitive-spillovers` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `altmann-2022-cognitive-spillovers` | independent | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `altmann-2022-cognitive-spillovers` | blind | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dertwinkel-kalt-2022-concentration-bias` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dertwinkel-kalt-2022-concentration-bias` | independent | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 12/13, 0 error + 1 claim refinement) |  |
| `dertwinkel-kalt-2022-concentration-bias` | blind | claude-code | ran | ✓ | ✓ | ✓ | 13 / 11 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 13 / 9 of 13 (first scored 11/13, 1 error + 1 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | independent | claude-code | ran | ✓ | ✓ | ✓ | 13 / 9 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `gagliarducci-2022-gender-cooperation-congress` | blind | claude-code | ran | ✓ | ✗ | ✗ | 7 / 5 of 13 (first scored 7/13, 0 error + 0 claim refinements) |  |
| `holman-2022-theresa-may-rally` | seeded | claude-code | ran | ✓ | ✓ | ✗ | 11 / 5 of 11 (first scored 11/11, 1 error + 0 claim refinement) |  |
| `holman-2022-theresa-may-rally` | independent | claude-code | ran | ✓ | ✗ | ✗ | 10 / 7 of 11 (first scored 10/11, 0 error + 1 claim refinement) |  |
| `holman-2022-theresa-may-rally` | blind | claude-code | ran | ✓ | ✗ | ✗ | 6 / 4 of 11 (first scored 6/11, 1 error + 0 claim refinement) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | seeded | claude-code | ran | ✓ | ✓ | ✓ | 13 / 6 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | independent | claude-code | ran | ✓ | ✗ | ✗ | 9 / 2 of 13 (first scored 9/13, 0 error + 2 claim refinements) |  |
| `lopez-moctezuma-2022-policy-deliberation-philippines` | blind | claude-code | ran | ✓ | ✗ | ✗ | 9 / 2 of 13 (first scored 9/13, 0 error + 0 claim refinements) |  |
