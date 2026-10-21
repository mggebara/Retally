# Retally benchmark report

Catalog size: **3** papers, each run in 2 reproduction modes.  
Runs (paper × mode): **6**.  
Executed runs: **6**.  
Skipped runs: **0** (out_of_scope=0, language_unsupported=0, no_api_key=0).  

Reproduction modes:

- **seeded**: the authors' replication-package scripts were in the generation prompt — computational reproduction.
- **independent**: the authors' scripts were withheld; reproduced from the paper text — independent reproduction.

Reproducer: **pipeline**.

## Verdicts — seeded (among executed papers)

- Pipeline completed without crashing: **3 / 3**
- Agrees with the paper's stated values: **1 / 3**
- Agrees with the I4R replicator: **1 / 3** (of papers where I4R published a value to compare against)

## Verdicts — independent (among executed papers)

- Pipeline completed without crashing: **3 / 3**
- Agrees with the paper's stated values: **0 / 3**
- Agrees with the I4R replicator: **0 / 3** (of papers where I4R published a value to compare against)

## Seeded vs independent

Claims passing with the authors' scripts in the prompt (seeded) versus without them (independent), per paper executed in both modes.  *Lost* claims pass seeded but not independent — what the scripts were carrying.

- Seeded: **30 / 35** claims passed (first scored 29 / 35)
- Independent: **23 / 35** claims passed (first scored 17 / 35)
- Lost without the scripts: **9**; gained: **2**

*First scored* is what each mode's first script that printed results passed: after any crash repairs, before the refinement loop showed the model which claims were off target.

| Entry | Split | Reproducer | Seeded | Independent | First scored (seeded / independent) | Lost without scripts |
|---|---|---|---|---|---|---|
| `alesina-2022-immigration-redistribution` | dev | pipeline | 7/11 | 7/11 | 7/11 / 1/11 | `order_effect_social_budget`, `sample_size_table4` |
| `bisbee-2022-flight-to-safety` | dev | pipeline | 10/11 | 5/11 | 9/11 / 5/11 | `exposure_coefficient_march_basic`, `exposure_coefficient_march_cbps`, `sample_size_full`, `sample_size_march`, `tea_party_x_cases_interaction` |
| `dincecco-2022-india-warfare` | dev | pipeline | 13/13 | 11/13 | 13/13 / 11/13 | `warfare_iv_se_full_controls`, `warfare_se_full_controls` |

## Closeness (per split and mode)

- **dev · seeded**: 3 entries, 35 claims, matched 100%, passed 30/35, median rel err 0.2%, within tol/2x/5x: 86%/94%/97%
- **dev · independent**: 3 entries, 35 claims, matched 100%, passed 23/35, median rel err 6.0%, within tol/2x/5x: 66%/80%/86%

## Per-component success — seeded (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 3 | 3 | 100% |
| claims_extracted | 3 | 3 | 100% |
| dataset_extracted | 0 | 3 | 0% |
| dataset_downloaded | 3 | 3 | 100% |
| code_generated | 3 | 3 | 100% |
| code_executed | 3 | 3 | 100% |

## Per-component success — independent (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 3 | 3 | 100% |
| claims_extracted | 3 | 3 | 100% |
| dataset_extracted | 0 | 3 | 0% |
| dataset_downloaded | 3 | 3 | 100% |
| code_generated | 3 | 3 | 100% |
| code_executed | 3 | 3 | 100% |

## Estimated API cost

Total estimated spend this run: **$3.86** across 22 API calls (15 further calls served free by the LLM cache).  Estimates from the price table in `benchmark/pricing.py`.

| ID | Mode | Reproducer | API calls | LLM-cache hits | Input tok | Output tok | Cache write tok | Cache read tok | Est. cost |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|
| `dincecco-2022-india-warfare` | seeded | pipeline | 1 | 3 | 36,013 | 1,813 | 0 | 0 | $0.23 |
| `dincecco-2022-india-warfare` | independent | pipeline | 5 | 2 | 33,260 | 13,398 | 0 | 0 | $0.50 |
| `alesina-2022-immigration-redistribution` | seeded | pipeline | 4 | 3 | 120,666 | 23,942 | 0 | 0 | $1.20 |
| `alesina-2022-immigration-redistribution` | independent | pipeline | 4 | 2 | 35,777 | 19,890 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | seeded | pipeline | 4 | 3 | 75,442 | 12,209 | 0 | 0 | $0.68 |
| `bisbee-2022-flight-to-safety` | independent | pipeline | 4 | 2 | 34,082 | 16,081 | 0 | 0 | $0.57 |

## Per-paper results

| ID | Mode | Reproducer | Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |
|---|---|---|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 13 / 13 of 13 (first scored 13/13, 0 error + 0 claim refinements) |  |
| `dincecco-2022-india-warfare` | independent | pipeline | ran | ✓ | ✗ | ✗ | 11 / 11 of 13 (first scored 11/13, 1 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 7/11, 0 error + 3 claim refinements) |  |
| `alesina-2022-immigration-redistribution` | independent | pipeline | ran | ✓ | ✗ | ✗ | 7 / 7 of 11 (first scored 1/11, 0 error + 3 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | seeded | pipeline | ran | ✓ | ✗ | ✗ | 10 / 10 of 11 (first scored 9/11, 1 error + 2 claim refinements) |  |
| `bisbee-2022-flight-to-safety` | independent | pipeline | ran | ✓ | ✗ | ✗ | 5 / 5 of 11 (first scored 5/11, 0 error + 3 claim refinements) |  |
