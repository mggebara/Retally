# Retally benchmark report

Catalog size: **1** papers, each run in 2 reproduction modes.  
Runs (paper × mode): **2**.  
Executed runs: **2**.  
Skipped runs: **0** (out_of_scope=0, language_unsupported=0, no_api_key=0).

Reproduction modes:

- **seeded**: the authors' replication-package scripts were in the generation prompt — computational reproduction.
- **independent**: the authors' scripts were withheld; reproduced from the paper text — independent reproduction.

## Verdicts — seeded (among executed papers)

- Pipeline completed without crashing: **1 / 1**
- Agrees with the paper's stated values: **1 / 1**
- Agrees with the I4R replicator: **1 / 1** (of papers where I4R published a value to compare against)

## Verdicts — independent (among executed papers)

- Pipeline completed without crashing: **1 / 1**
- Agrees with the paper's stated values: **0 / 1**
- Agrees with the I4R replicator: **0 / 1** (of papers where I4R published a value to compare against)

## Seeded vs independent

Claims passing with the authors' scripts in the prompt (seeded) versus without them (independent), per paper executed in both modes.  *Lost* claims pass seeded but not independent — what the scripts were carrying.

- Seeded: **13 / 13** claims passed
- Independent: **0 / 13** claims passed
- Lost without the scripts: **13**; gained: **0**

| Entry | Split | Seeded | Independent | Lost without scripts |
|---|---|---|---|---|
| `dincecco-2022-india-warfare` | dev | 13/13 | 0/13 | `sample_size_districts`, `warfare_coefficient_bivariate`, `warfare_coefficient_full_controls`, `warfare_coefficient_state_fe`, `warfare_iv_coefficient_bivariate`, `warfare_iv_coefficient_full_controls`, `warfare_iv_coefficient_state_fe`, `warfare_iv_se_bivariate`, `warfare_iv_se_full_controls`, `warfare_iv_se_state_fe`, `warfare_se_bivariate`, `warfare_se_full_controls`, `warfare_se_state_fe` |

## Closeness (per split and mode)

- **dev · seeded**: 1 entries, 13 claims, matched 100%, passed 13/13, median rel err 0.0%, within tol/2x/5x: 100%/100%/100%
- **dev · independent**: 1 entries, 13 claims, matched 77%, passed 0/13, median rel err 103.8%, within tol/2x/5x: 0%/0%/50%

## Per-component success — seeded (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 1 | 1 | 100% |
| claims_extracted | 1 | 1 | 100% |
| dataset_extracted | 0 | 1 | 0% |
| dataset_downloaded | 1 | 1 | 100% |
| code_generated | 1 | 1 | 100% |
| code_executed | 1 | 1 | 100% |

## Per-component success — independent (executed papers only)

| Component | Succeeded | Total | Rate |
|---|---:|---:|---:|
| parsed | 1 | 1 | 100% |
| claims_extracted | 1 | 1 | 100% |
| dataset_extracted | 0 | 1 | 0% |
| dataset_downloaded | 1 | 1 | 100% |
| code_generated | 1 | 1 | 100% |
| code_executed | 1 | 1 | 100% |

## Per-paper results

| ID | Mode | Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |
|---|---|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | seeded | ran | ✓ | ✓ | ✓ | 13 / 13 of 13 |  |
| `dincecco-2022-india-warfare` | independent | ran | ✓ | ✗ | ✗ | 0 / 0 of 13 | ✓ |
