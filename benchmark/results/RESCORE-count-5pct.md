# Rescore: COUNT claims at 5 % (`count-5pct`, 2026-11-03)

Sample-size claims (observations, clusters, respondents, districts, bills, ...) were relabelled from `other` (1 % band) to the new `count` claim type (5 % band) in the catalog: 62 claims across 25 papers.  `uv run python -m benchmark.rescore benchmark/results/*.json` then re-scored, offline, every stored claim detail whose catalog claim is now a `count`, with the comparator, on the stored `reproduced` value, in the row's mode (probe rows as blind).  No run was repeated and no API call was made.  `other` claims (F statistics, Brown-Forsythe W, ANOVA F, percentage points) keep 1 %.

Fields updated per count claim: `claim_type`, `tolerance`, `tolerance_source`, `rel_err`, `passed` (and `within_tolerance` on probe rows).  On rows with a flip, `n_claims_with_paper_match` and `agrees_with_paper` are recomputed; the I4R fields move by what the new band changes on the stored values.  **First-scored and first-attempt fields are left as recorded**: rows store only the final reproduced value, not the first scored one, so `passed_first_scored` / `n_claims_with_paper_match_first_scored` cannot be re-scored.  The band only widened, so a recorded first-scored pass is still a pass; a recorded first-scored miss on a count claim may now be an undercount.  Files in the `{usage, results}` shape gained a top-level `rescored` key; the 14 older bare-list files keep their list shape and carry no marker.  A second run changes nothing.

**56 claim verdicts flipped, all FAIL → PASS**, across 76 files (75 rewritten).

**Added after the batch run:** `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (pipeline third sample, ROADMAP 3.7.4) was assembled after the batch rescore and was rescored when it was assembled, not by the `benchmark.rescore` batch run above; its top-level `rescored` key reads `{policy: count-5pct, date: 2026-11-03, flipped: 7}`.  Its rows below are marked *(rescored at assembly)*; the *before* figures are recomputed from its claim details (a passing `count` claim with a relative error above 1 % counted as a miss).  With it, 63 verdicts flipped across 77 files, all FAIL → PASS.

## Before / after per file and mode

Matched claims (claims passed) summed over the file's rows; *claims* is the number of claim details.

| File | Mode | Reproducer | Before | After | Claims |
|---|---|---|---:|---:|---:|
| `baseline-2026-10-19.json` | seeded | pipeline | 13 | 13 | 13 |
| `baseline-both-2026-10-19.json` | independent | pipeline | 0 | **1** | 13 |
| `baseline-both-2026-10-19.json` | seeded | pipeline | 13 | 13 | 13 |
| `baseline-both-2026-10-20.json` | independent | pipeline | 12 | 12 | 13 |
| `baseline-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `claude-code-4papers-all-modes-2026-11-02.json` | blind | claude-code | 45 | **46** | 47 |
| `claude-code-4papers-all-modes-2026-11-02.json` | independent | claude-code | 46 | 46 | 47 |
| `claude-code-4papers-all-modes-2026-11-02.json` | seeded | claude-code | 47 | 47 | 47 |
| `claude-code-6papers-all-modes-2026-10-22.json` | blind | claude-code | 60 | **61** | 75 |
| `claude-code-6papers-all-modes-2026-10-22.json` | independent | claude-code | 70 | **71** | 75 |
| `claude-code-6papers-all-modes-2026-10-22.json` | seeded | claude-code | 75 | 75 | 75 |
| `claude-code-6papers-all-modes-2026-11-02.json` | blind | claude-code | 70 | 70 | 77 |
| `claude-code-6papers-all-modes-2026-11-02.json` | independent | claude-code | 73 | 73 | 77 |
| `claude-code-6papers-all-modes-2026-11-02.json` | seeded | claude-code | 77 | 77 | 77 |
| `claude-code-7papers-all-modes-2026-10-21.json` | blind | claude-code | 75 | 75 | 79 |
| `claude-code-7papers-all-modes-2026-10-21.json` | independent | claude-code | 78 | 78 | 79 |
| `claude-code-7papers-all-modes-2026-10-21.json` | seeded | claude-code | 78 | 78 | 79 |
| `claude-code-blind-rerun-2026-10-22-b.json` | blind | claude-code | 14 | **15** | 24 |
| `claude-code-blind-rerun-2026-10-22.json` | blind | claude-code | 29 | 29 | 34 |
| `claude-code-run2-13papers-indep-blind-2026-11-01.json` | blind | claude-code | 132 | **134** | 154 |
| `claude-code-run2-13papers-indep-blind-2026-11-01.json` | independent | claude-code | 147 | **148** | 154 |
| `claude-code-run2-23papers-seeded-2026-11-02.json` | seeded | claude-code | 266 | 266 | 278 |
| `claude-code-run2-4papers-indep-blind-2026-11-02.json` | blind | claude-code | 45 | **46** | 47 |
| `claude-code-run2-4papers-indep-blind-2026-11-02.json` | independent | claude-code | 47 | 47 | 47 |
| `claude-code-run2-6papers-indep-blind-2026-11-02.json` | blind | claude-code | 71 | 71 | 77 |
| `claude-code-run2-6papers-indep-blind-2026-11-02.json` | independent | claude-code | 76 | 76 | 77 |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | blind | claude-code | 247 | **250** | 278 |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | independent | claude-code | 264 | **265** | 278 |
| `claude-code-run4-redaction-3papers-blind-2026-11-03.json` | blind | claude-code | 36 | 36 | 36 |
| `claude-code-test-cells-2026-10-21.json` | blind | claude-code | 20 | 20 | 21 |
| `claude-code-test-cells-2026-10-21.json` | independent | claude-code | 19 | 19 | 21 |
| `claude-code-test-cells-2026-10-21.json` | seeded | claude-code | 20 | 20 | 21 |
| `eval-7papers-all-modes-2026-10-21.json` | blind | pipeline | 24 | **29** | 79 |
| `eval-7papers-all-modes-2026-10-21.json` | independent | pipeline | 41 | **47** | 79 |
| `eval-7papers-all-modes-2026-10-21.json` | seeded | pipeline | 55 | 55 | 79 |
| `phase16-step3-both-2026-10-20.json` | independent | pipeline | 0 | 0 | 13 |
| `phase16-step3-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase16-step4-partial-both-2026-10-20.json` | independent | pipeline | 0 | 0 | 0 |
| `phase16-step4-partial-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase17-step4-both-2026-10-20.json` | independent | pipeline | 0 | 0 | 13 |
| `phase17-step4-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase17-step4-variance-independent-run1-2026-10-20.json` | independent | pipeline | 0 | 0 | 13 |
| `phase17-step4-variance-independent-run2-2026-10-20.json` | independent | pipeline | 0 | 0 | 13 |
| `phase17-step4-variance-independent-run3-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase17-step5-both-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase17-step5-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase17-step5-variance-independent-run1-2026-10-20.json` | independent | pipeline | 2 | 2 | 13 |
| `phase17-step5-variance-independent-run2-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase17-step5-variance-independent-run3-2026-10-20.json` | independent | pipeline | 2 | 2 | 13 |
| `phase17-step6-both-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase17-step6-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase17-step6-variance-independent-run1-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase17-step6-variance-independent-run2-2026-10-20.json` | independent | pipeline | 2 | 2 | 13 |
| `phase17-step6-variance-independent-run3-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase18-dincecco-both-2026-10-20.json` | independent | pipeline | 11 | 11 | 13 |
| `phase18-dincecco-both-2026-10-20.json` | seeded | pipeline | 13 | 13 | 13 |
| `phase18-dincecco-variance-independent-run1-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase18-dincecco-variance-independent-run2-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase18-dincecco-variance-independent-run3-2026-10-20.json` | independent | pipeline | 13 | 13 | 13 |
| `phase19-bisbee-independent-2026-10-20.json` | independent | pipeline | 5 | 5 | 11 |
| `phase19-bisbee-variance-independent-run1-2026-10-20.json` | independent | pipeline | 7 | 7 | 11 |
| `phase19-bisbee-variance-independent-run2-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase19-bisbee-variance-independent-run3-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase3-alesina-2022-immigration-redistribution-both-2026-10-20.json` | independent | pipeline | 9 | 9 | 11 |
| `phase3-alesina-2022-immigration-redistribution-both-2026-10-20.json` | seeded | pipeline | 6 | 6 | 11 |
| `phase3-alesina-both-2026-10-20.json` | independent | pipeline | 7 | 7 | 11 |
| `phase3-alesina-both-2026-10-20.json` | seeded | pipeline | 7 | 7 | 11 |
| `phase3-alesina-variance-independent-run1-2026-10-20.json` | independent | pipeline | 0 | 0 | 11 |
| `phase3-alesina-variance-independent-run2-2026-10-20.json` | independent | pipeline | 6 | **7** | 11 |
| `phase3-alesina-variance-independent-run3-2026-10-20.json` | independent | pipeline | 5 | 5 | 11 |
| `phase3-bisbee-2022-flight-to-safety-both-2026-10-20.json` | — | — | unchanged | | |
| `phase3-bisbee-both-2026-10-20.json` | independent | pipeline | 0 | 0 | 11 |
| `phase3-bisbee-both-2026-10-20.json` | seeded | pipeline | 7 | 7 | 11 |
| `phase3-bisbee-variance-independent-run1-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase3-bisbee-variance-independent-run2-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase3-bisbee-variance-independent-run3-2026-10-20.json` | independent | pipeline | 5 | 5 | 11 |
| `phase3b-bisbee-both-2026-10-20.json` | independent | pipeline | 0 | 0 | 0 |
| `phase3b-bisbee-both-2026-10-20.json` | seeded | pipeline | 10 | 10 | 11 |
| `phase3b-bisbee-independent-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase3b-bisbee-variance-independent-run1-2026-10-20.json` | independent | pipeline | 7 | 7 | 11 |
| `phase3b-bisbee-variance-independent-run2-2026-10-20.json` | independent | pipeline | 8 | 8 | 11 |
| `phase3b-bisbee-variance-independent-run3-2026-10-20.json` | independent | pipeline | 7 | 7 | 11 |
| `pipeline-10papers-all-modes-2026-10-21.json` | blind | pipeline | 24 | **29** | 79 |
| `pipeline-10papers-all-modes-2026-10-21.json` | independent | pipeline | 64 | **70** | 114 |
| `pipeline-10papers-all-modes-2026-10-21.json` | seeded | pipeline | 85 | 85 | 114 |
| `pipeline-opus55-4papers-all-modes-2026-10-22.json` | blind | pipeline | 20 | **21** | 44 |
| `pipeline-opus55-4papers-all-modes-2026-10-22.json` | independent | pipeline | 33 | 33 | 44 |
| `pipeline-opus55-4papers-all-modes-2026-10-22.json` | seeded | pipeline | 44 | 44 | 44 |
| `pipeline-opus55-grier-all-modes-2026-10-22.json` | blind | pipeline | 0 | 0 | 11 |
| `pipeline-opus55-grier-all-modes-2026-10-22.json` | independent | pipeline | 0 | 0 | 11 |
| `pipeline-opus55-grier-all-modes-2026-10-22.json` | seeded | pipeline | 11 | 11 | 11 |
| `pipeline-opus55-leeson-all-modes-2026-10-22.json` | blind | pipeline | 8 | **9** | 11 |
| `pipeline-opus55-leeson-all-modes-2026-10-22.json` | independent | pipeline | 11 | 11 | 11 |
| `pipeline-opus55-leeson-all-modes-2026-10-22.json` | seeded | pipeline | 11 | 11 | 11 |
| `pipeline-opus55-manekin-all-modes-2026-10-22.json` | blind | pipeline | 12 | 12 | 12 |
| `pipeline-opus55-manekin-all-modes-2026-10-22.json` | independent | pipeline | 12 | 12 | 12 |
| `pipeline-opus55-manekin-all-modes-2026-10-22.json` | seeded | pipeline | 12 | 12 | 12 |
| `pipeline-opus55-montero-all-modes-2026-10-22.json` | blind | pipeline | 0 | 0 | 10 |
| `pipeline-opus55-montero-all-modes-2026-10-22.json` | independent | pipeline | 10 | 10 | 10 |
| `pipeline-opus55-montero-all-modes-2026-10-22.json` | seeded | pipeline | 10 | 10 | 10 |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | blind | pipeline | 26 | 26 | 47 |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | independent | pipeline | 40 | **42** | 47 |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | seeded | pipeline | 45 | 45 | 47 |
| `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` | blind | pipeline | 52 | 52 | 77 |
| `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` | independent | pipeline | 66 | **67** | 77 |
| `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` | seeded | pipeline | 69 | 69 | 77 |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | blind | pipeline | 72 | **74** | 110 |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | independent | pipeline | 96 | **97** | 110 |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | seeded | pipeline | 105 | 105 | 110 |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | blind | pipeline | 82 | **85** | 154 |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | independent | pipeline | 128 | **130** | 154 |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | seeded | pipeline | 152 | 152 | 154 |
| `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` | blind | pipeline | 38 | **39** | 47 |
| `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` | independent | pipeline | 33 | **34** | 47 |
| `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` | seeded | pipeline | 43 | 43 | 47 |
| `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` | blind | pipeline | 52 | 52 | 77 |
| `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` | independent | pipeline | 62 | 62 | 77 |
| `pipeline-oracle-desktop-opus-run2-6papers-all-modes-2026-11-02.json` | seeded | pipeline | 70 | 70 | 77 |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | blind | pipeline | 177 | **181** | 278 |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | independent | pipeline | 224 | **227** | 278 |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | seeded | pipeline | 254 | 254 | 278 |
| `pre34-promptonly-both-run1-2026-10-19.json` | independent | pipeline | 0 | **1** | 13 |
| `pre34-promptonly-both-run1-2026-10-19.json` | seeded | pipeline | 13 | 13 | 13 |
| `pre34-promptonly-independent-run2-2026-10-19.json` | independent | pipeline | 0 | 0 | 13 |
| `pre34-promptonly-independent-run3-2026-10-19.json` | independent | pipeline | 1 | 1 | 13 |
| `probe-desktop-opus-2026-11-01.json` | probe | memory-probe | 26 | **27** | 154 |
| `probe-desktop-opus-2026-11-02.json` | probe | memory-probe | 41 | **44** | 278 |
| `variance-independent-postfix-run1-2026-10-20.json` | independent | pipeline | 4 | 4 | 13 |
| `variance-independent-postfix-run2-2026-10-20.json` | independent | pipeline | 10 | 10 | 13 |
| `variance-independent-postfix-run3-2026-10-20.json` | independent | pipeline | 1 | 1 | 13 |
| `variance-independent-scriptfree-run2-2026-10-19.json` | independent | pipeline | 0 | 0 | 13 |
| `variance-independent-scriptfree-run3-2026-10-19.json` | independent | pipeline | 0 | 0 | 13 |

## Flipped claims

| File | Entry | Mode | Reproducer | Claim | Claimed | Reproduced | Rel. err | Verdict |
|---|---|---|---|---|---:|---:|---:|---|
| `baseline-both-2026-10-19.json` | `dincecco-2022-india-warfare` | independent | pipeline | `sample_size_districts` | 660 | 631 | 4.39 % | FAIL → PASS |
| `claude-code-4papers-all-modes-2026-11-02.json` | `forsythe-2022-young-workers-recessions` | blind | claude-code | `n_obs_full_sample` | 16,948,516 | 17,357,345 | 2.41 % | FAIL → PASS |
| `claude-code-6papers-all-modes-2026-10-22.json` | `holman-2022-theresa-may-rally` | independent | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-6papers-all-modes-2026-10-22.json` | `holman-2022-theresa-may-rally` | blind | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-blind-rerun-2026-10-22-b.json` | `holman-2022-theresa-may-rally` | blind | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-run2-13papers-indep-blind-2026-11-01.json` | `holman-2022-theresa-may-rally` | independent | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-run2-13papers-indep-blind-2026-11-01.json` | `holman-2022-theresa-may-rally` | blind | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-run2-13papers-indep-blind-2026-11-01.json` | `montero-2022-cooperative-property-rights` | blind | claude-code | `n_clusters_bw300` | 98 | 99 | 1.02 % | FAIL → PASS |
| `claude-code-run2-4papers-indep-blind-2026-11-02.json` | `forsythe-2022-young-workers-recessions` | blind | claude-code | `n_obs_full_sample` | 16,948,516 | 17,357,345 | 2.41 % | FAIL → PASS |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | `holman-2022-theresa-may-rally` | independent | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | `forsythe-2022-young-workers-recessions` | blind | claude-code | `n_obs_full_sample` | 16,948,516 | 17,357,345 | 2.41 % | FAIL → PASS |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | `holman-2022-theresa-may-rally` | blind | claude-code | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `claude-code-run3-23papers-indep-blind-2026-11-02.json` | `montero-2022-cooperative-property-rights` | blind | claude-code | `n_clusters_bw300` | 98 | 99 | 1.02 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `respondents_us` | 1,086 | 1,033 | 4.88 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `respondents_germany` | 1,074 | 1,029 | 4.19 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `choice_tasks_us` | 18,966 | 18,578 | 2.05 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `choice_tasks_germany` | 18,862 | 18,506 | 1.89 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `respondents_us` | 1,086 | 1,033 | 4.88 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `respondents_germany` | 1,074 | 1,029 | 4.19 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `choice_tasks_us` | 18,966 | 18,594 | 1.96 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `choice_tasks_germany` | 18,862 | 18,522 | 1.80 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_full_sample` | 242 | 239 | 1.24 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_obs_earnings_iqr_bw150` | 118 | 113 | 4.24 % | FAIL → PASS |
| `eval-7papers-all-modes-2026-10-21.json` | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_clusters_bw150` | 36 | 35 | 2.78 % | FAIL → PASS |
| `phase3-alesina-variance-independent-run2-2026-10-20.json` | `alesina-2022-immigration-redistribution` | independent | pipeline | `sample_size_table4` | 19,765 | 20,730 | 4.88 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `respondents_us` | 1,086 | 1,033 | 4.88 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `respondents_germany` | 1,074 | 1,029 | 4.19 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `choice_tasks_us` | 18,966 | 18,578 | 2.05 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | independent | pipeline | `choice_tasks_germany` | 18,862 | 18,506 | 1.89 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `respondents_us` | 1,086 | 1,033 | 4.88 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `respondents_germany` | 1,074 | 1,029 | 4.19 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `choice_tasks_us` | 18,966 | 18,594 | 1.96 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `choice_tasks_germany` | 18,862 | 18,522 | 1.80 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_full_sample` | 242 | 239 | 1.24 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_obs_earnings_iqr_bw150` | 118 | 113 | 4.24 % | FAIL → PASS |
| `pipeline-10papers-all-modes-2026-10-21.json` | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_clusters_bw150` | 36 | 35 | 2.78 % | FAIL → PASS |
| `pipeline-opus55-4papers-all-modes-2026-10-22.json` | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_five_station_subsample` | 102 | 98 | 3.92 % | FAIL → PASS |
| `pipeline-opus55-leeson-all-modes-2026-10-22.json` | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_five_station_subsample` | 102 | 98 | 3.92 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | `carrera-2022-who-chooses-commitment` | independent | pipeline | `takeup_more_regression_observations` | 2,824 | 2,946 | 4.32 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | `forsythe-2022-young-workers-recessions` | independent | pipeline | `n_obs_full_sample` | 16,948,516 | 17,282,600 | 1.97 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-6papers-all-modes-2026-11-02.json` | `labandeira-2022-electricity-pricing-reform` | independent | pipeline | `n_obs_table2` | 20,872 | 21,317 | 2.13 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | `acemoglu-2022-war-socialism-fascism` | blind | pipeline | `n_clusters_main_sample` | 181 | 178 | 1.66 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | `acemoglu-2022-war-socialism-fascism` | blind | pipeline | `n_clusters_fascist_vote1921` | 175 | 171 | 2.29 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-9papers-all-modes-2026-10-23.json` | `holman-2022-theresa-may-rally` | independent | pipeline | `n_obs_did_like_may_table2` | 143,499 | 145,012 | 1.05 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | `holman-2022-theresa-may-rally` | independent | pipeline | `n_obs_table4` | 4,328 | 4,380 | 1.20 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_five_station_subsample` | 102 | 98 | 3.92 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_obs_earnings_iqr_bw150` | 118 | 122 | 3.39 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | `montero-2022-cooperative-property-rights` | blind | pipeline | `n_obs_earnings_level_bw150` | 1,583 | 1,513 | 4.42 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-13papers-all-modes-2026-10-23.json` | `montero-2022-cooperative-property-rights` | blind | pipeline | `n_clusters_bw300` | 98 | 99 | 1.02 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` | `carrera-2022-who-chooses-commitment` | blind | pipeline | `bcp_regression_observations` | 1,126 | 1,152 | 2.31 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run2-4papers-all-modes-2026-11-02.json` | `forsythe-2022-young-workers-recessions` | independent | pipeline | `n_obs_full_sample` | 16,948,516 | 17,282,551 | 1.97 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `acemoglu-2022-war-socialism-fascism` | blind | pipeline | `n_clusters_main_sample` | 181 | 178 | 1.66 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `acemoglu-2022-war-socialism-fascism` | blind | pipeline | `n_clusters_fascist_vote1921` | 175 | 171 | 2.29 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `arias-2022-changing-tides-climate-migration` | blind | pipeline | `choice_tasks_germany` | 18,862 | 19,078 | 1.15 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `holman-2022-theresa-may-rally` | independent | pipeline | `n_obs_table4` | 4,328 | 4,486 | 3.65 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `leeson-2022-hobo-economicus` | blind | pipeline | `station_visits_five_station_subsample` | 102 | 98 | 3.92 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_obs_earnings_iqr_bw300` | 327 | 332 | 1.53 % | FAIL → PASS |
| `pipeline-oracle-desktop-opus-run3-23papers-all-modes-2026-11-03.json` (rescored at assembly) | `montero-2022-cooperative-property-rights` | independent | pipeline | `n_clusters_bw300` | 98 | 99 | 1.02 % | FAIL → PASS |
| `pre34-promptonly-both-run1-2026-10-19.json` | `dincecco-2022-india-warfare` | independent | pipeline | `sample_size_districts` | 660 | 640 | 3.03 % | FAIL → PASS |
| `probe-desktop-opus-2026-11-01.json` | `grier-2023-sugar-roll-call-voting` | probe | memory-probe | `observations_incumbent_fe` | 106 | 110 | 3.77 % | FAIL → PASS |
| `probe-desktop-opus-2026-11-02.json` | `grier-2023-sugar-roll-call-voting` | probe | memory-probe | `observations_incumbent_fe` | 106 | 110 | 3.77 % | FAIL → PASS |
| `probe-desktop-opus-2026-11-02.json` | `hanushek-2022-patience-risk-human-capital` | probe | memory-probe | `table1_col3_observations` | 1,992,276 | 1,900,000 | 4.63 % | FAIL → PASS |
| `probe-desktop-opus-2026-11-02.json` | `labandeira-2022-electricity-pricing-reform` | probe | memory-probe | `n_obs_table2` | 20,872 | 20,000 | 4.18 % | FAIL → PASS |
