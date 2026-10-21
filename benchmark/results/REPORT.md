# Retally benchmark report

Catalog size: **1** papers, each run in 2 reproduction modes.  
Runs (paper × mode): **2**.  
Executed runs: **2**.  
Skipped runs: **0** (out_of_scope=0, language_unsupported=0, no_api_key=0).

Reproduction modes:

- **seeded**: the authors' replication-package scripts were in the generation prompt — computational reproduction.
- **independent**: the authors' scripts were withheld; reproduced from the paper text — independent reproduction.

Reproducer: **pipeline**.

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
- Independent: **12 / 13** claims passed
- Lost without the scripts: **1**; gained: **0**

| Entry | Split | Reproducer | Seeded | Independent | Lost without scripts |
|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | dev | pipeline | 13/13 | 12/13 | `warfare_iv_se_full_controls` |

## Closeness (per split and mode)

- **dev · seeded**: 1 entries, 13 claims, matched 100%, passed 13/13, median rel err 0.0%, within tol/2x/5x: 100%/100%/100%
- **dev · independent**: 1 entries, 13 claims, matched 100%, passed 12/13, median rel err 0.6%, within tol/2x/5x: 92%/100%/100%

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

| ID | Mode | Reproducer | Status | Ran | Agrees w/ paper | Agrees w/ I4R | Claims (paper / I4R) | Cached |
|---|---|---|---|---|---|---|---|---|
| `dincecco-2022-india-warfare` | seeded | pipeline | ran | ✓ | ✓ | ✓ | 13 / 13 of 13 |  |
| `dincecco-2022-india-warfare` | independent | pipeline | ran | ✓ | ✗ | ✗ | 12 / 12 of 13 |  |
