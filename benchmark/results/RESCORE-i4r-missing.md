# Rescore: I4R-valued claims with no Retally value (`i4r-missing`, 2026-11-06)

`agrees_with_i4r` used to skip a claim the I4R replicator valued when Retally printed no value for it (`benchmark/runner.py::_score_against_i4r` counted only claims with a reproduced value as attempted).  So a cell that printed NA for some replicator-valued claims could still read `agrees_with_i4r: true`, and the report's verdict table showed it as "paper ✗, I4R ✓", the combination meant to say the replicators found a different number.  `agrees_with_paper` already counted a missing value as a miss.  From 2026-11-06 a replicator-valued claim with no Retally value is attempted and not matching, so the flag is False; `n_claims_with_i4r_match` is unchanged, and the flag is still `null` when no I4R finding carries a value.

`uv run python -m benchmark.rescore --policy i4r-missing benchmark/results/*.json` applied the rule offline to every stored results file.  No run was repeated and no API call was made.  The new rule only tightens the old one, so the policy works on the stored rows directly: a row recorded `true` whose claim details hold a null `reproduced` for a claim the catalog's I4R findings value becomes `false`.  Nothing else in any row changes.  A rewritten file in the `{usage, results}` shape gains a second top-level key, `"rescored_i4r_missing": {"policy": "i4r-missing", "date": "2026-11-06", "flipped": N}`, beside the count policy's `rescored` key, which is left as written.  A bare-list file keeps its shape and carries no marker.  Files with no flip are untouched.  A second run changes nothing.

**8 rows flipped, all `true` → `false`, in 8 of 85 files.**  The other 77 files are unchanged.

| File | Entry | Mode | Paper matches | I4R matches (unchanged) | I4R-valued claims missing | `agrees_with_i4r` |
|---|---|---|---:|---:|---:|---|
| `eval-7papers-all-modes-2026-10-21.json` | `manekin-2022-effective-for-whom` | blind | 6/12 | 6 | 6 of 12 | ✓ → **✗** |
| `pipeline-10papers-all-modes-2026-10-21.json` | `manekin-2022-effective-for-whom` | blind | 6/12 | 6 | 6 of 12 | ✓ → **✗** |
| `pipeline-oracle-desktop-opus-4papers-all-modes-2026-11-02.json` | `bokobza-2022-morning-after-coup-purges` | blind | 4/11 | 4 | 7 of 11 | ✓ → **✗** |
| `pipeline-oracle-desktop-opus-postfix2-23papers-indep-blind-2026-11-05.json` | `bokobza-2022-morning-after-coup-purges` | blind | 4/11 | 4 | 7 of 11 | ✓ → **✗** |
| `pipeline-oracle-desktop-opus-1paper-all-modes-2026-11-06.json` | `molina-garzon-2022-decentralization-cooperation` | blind | 6/12 | 5 | 2 of 7 | ✓ → **✗** |
| `pipeline-oracle-desktop-opus-run2-1paper-all-modes-2026-11-06.json` | `molina-garzon-2022-decentralization-cooperation` | blind | 6/12 | 5 | 2 of 7 | ✓ → **✗** |
| `pipeline-oracle-desktop-opus-run3-1paper-all-modes-2026-11-06.json` | `molina-garzon-2022-decentralization-cooperation` | independent | 6/12 | 5 | 2 of 7 | ✓ → **✗** |
| `pre34-promptonly-both-run1-2026-10-19.json` | `dincecco-2022-india-warfare` | independent | 1/13 | 1 | 12 of 13 | ✓ → **✗** |

All eight are pipeline rows.  `pipeline-10papers-all-modes-2026-10-21.json` holds the same `claude-opus-4-7` Manekin blind cell as `eval-7papers-all-modes-2026-10-21.json` (it is the file `docs/report/tables.py` reads for that pipeline, `PIPELINE_47_FILE`), and `pre34-promptonly-both-run1-2026-10-19.json` is a prompt-only Dincecco run from before ROADMAP 3.4, which the report does not read.

**Effect on the report.**  In the verdict-combination table (`docs/report/tables/three_way.md`), the Manekin blind row on `claude-opus-4-7` (7 papers), the oracle pipeline's Bokobza blind row (17- and 24-paper sets) and its Molina-Garzón blind row (24) move from "paper ✗ I4R ✓" to "paper ✗ I4R ✗".  The column now holds only the agent's rows: three Grier rows, where the missed claim has no I4R value, and one independent Forsythe row, where all 13 claims match I4R and the miss against the paper is a real value.  `benchmark/results/REPORT.md` was re-rendered from the same first-sample files.  Only the three flags changed, and with them the I4R agreement summaries: 2 → 1 of 7 for `claude-opus-4-7` and 6 → 4 of 19 for desktop Opus.  The evidence bundles under `benchmark/evidence/` for the three affected papers were not rebuilt here.
