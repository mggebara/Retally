# I4R meta-database — provenance

`i4r_first_meta_database.csv.gz` is the Institute for Replication (I4R)
"First Meta Database": the estimate-level record behind Brodeur, Mikola &
Cook, *"Mass Reproducibility and Replicability: A New Hope"* (I4R
Discussion Paper 107 / IZA DP 16912). It covers the reproduction and
robustness results of **110 replication reports over 109 original papers**
from leading economics and political-science journals, produced at I4R
Replication Games in 2022–2023.

This is the resource the `benchmark/README.md` prompt-tuning plan calls
the "Meta Database" — the per-paper robustness checks plus original-paper
info, and the computational-reproducibility outcomes.

## Where it came from

| | |
|---|---|
| Source repo | https://github.com/I4Replication/I4R-First-Meta-Paper |
| File | `Replication Package/data/Cleaned - First Meta Database - For I4R - 10 Jan 2025.dta` |
| Commit | `d34e5d7ada74f5fd6e28b86fa1670d14bf0f0eaf` (branch `main`) |
| License | MIT (repo `LICENSE`) — redistribution permitted with attribution |
| Retrieved | 2026-07-16 |
| Also mirrored | Zenodo [`10.5281/zenodo.17792605`](https://zenodo.org/records/17792605) (CC-BY-4.0) and OSF [`8wsqx`](https://osf.io/8wsqx/) — but the Zenodo/OSF `database_public.dta` is **anonymised** (paper titles replaced by integers, author names dropped). The GitHub copy is the un-anonymised one, so we use that. |

The published I4R "Database" page (`i4replication.org/database.html`) that
older notes pointed at now 404s; the site nav (About / Reports / Papers /
Projects / Tools) no longer exposes a data download, so the machine-readable
database lives only in the replication-package repos above.

## What we did to it

Converted the Stata `.dta` to CSV with **value labels applied**
(`pandas.read_stata(..., convert_categoricals=True)`), then gzipped it
(22 MB → 0.45 MB; `pandas.read_csv` reads `.gz` transparently). No rows or
columns were dropped — it is the full 6,693-row × 277-column database, just
in a diffable, label-decoded form. Regenerate with:

```python
import pandas as pd
pd.read_stata("Cleaned - First Meta Database - For I4R - 10 Jan 2025.dta",
              convert_categoricals=True
    ).to_csv("i4r_first_meta_database.csv.gz", index=False, compression="gzip")
```

## Grain and the columns the intake script uses

One row per **estimate** (an original coefficient the replicators checked or
re-ran). Report-level fields (title, journal, languages, reproduction
verdict, link) are constant within a `replicator_team`, so
`scripts/import_i4r_candidates.py` groups by `replicator_team` to get one
candidate per report.

| Column | Meaning | Used for |
|---|---|---|
| `replicator_team` | I4R internal replication-report ID (float, 1–110) | grouping key / candidate `id` suffix |
| `paper_title` | Original study title | `paper.title` |
| `o_a_name_1` … `o_a_name_6` | Original author names (`"No Author Number N"` = absent) | `paper.authors` |
| `journal`, `year_published` | Original publication venue / year | metadata, `notes` |
| `replication_link` | URL of the I4R report (blank for most) | `i4r_report_url` |
| `o_a_prog_lang_R` / `_Stata` / `_python` / … | Language the **original authors** coded in (`"R"`/`"Stata"`/… when selected, else `"Response not selected"`) | scope filter, `language` |
| `report_prog_lang_R` / `_stata` / … | Language the **I4R replicator** used | scope filter (R-verified case) |
| `perfect_reproduction` | `"Yes"`/`"No"` — did the report reproduce the paper exactly | `outcome_label` |
| `computational_reproduction` | 1/0 — did replicators reach a reproducibility verdict at all | `outcome_label` fallback |
| `best_describe_compreprod` | Prose describing the reproduction outcome | `notes` |
| `original_table` | Table/figure the estimate came from | (available for future claim seeding) |
| `o_coeff_dbl`, `o_std_err_dbl`, `o_p_dbl` | The **original paper's** number for each estimate | (available for `original_claims`) |
| `r_coeff_dbl`, `r_std_err_dbl`, `r_p_value` | The **I4R replicator's** reproduced number | (available for `i4r_replicator_findings` — the `agrees_with_i4r` ground truth) |

The coefficient columns are a latent goldmine — they are exactly the
I4R-aligned values `benchmark/README.md` describes for the `agrees_with_i4r`
verdict — but the intake script does **not** transcribe them yet (see the
script docstring for why claim seeding is left to human promotion).

## Data-quality caveats (these shaped the intake filter)

- **Report URLs are mostly missing.** Only **20 / 110** reports carry a
  `replication_link`; among the 59 Retally-runnable (R or R-verified) reports,
  only **9** do. `replicator_team` is an *internal* ID and does **not** equal
  the public I4R Discussion-Paper number (team 3 → DP47, team 5 → DP19, …),
  so a canonical report URL cannot be synthesised from it. Candidates without
  a link get a `TODO` placeholder `i4r_report_url` for a human to fill.
- **No dataset URLs.** The database records *whether* data/code were provided
  (`data_provided_*`, `code_provided_*`, `access_raw_data`) but never *where*
  to download them. Every candidate's `dataset.source` is left as a TODO.
- **No paper URLs.** Only titles + authors, so `paper.source` is a TODO too.
- **Language is self-reported** via the team survey and occasionally blank;
  the filter treats a missing R/Python flag as "not runnable" rather than
  guessing.

The gap between what's *catalogued* (110 reports) and what Retally can
actually *run end-to-end* (needs R/Python **and** open data **and** an
accessible paper) is itself a finding — the intake script reports the funnel.

## Related resource (not imported)

`https://github.com/I4Replication/AI-Games` (MIT) holds the data behind
Brodeur et al. (2026, PNAS) — an AI agent reproducing social-science
results, the same task Retally performs. Its `data/AI games.dta` is
attempt-level (137 rows) and keyed by anonymised paper IDs, so it is not
directly importable into the paper catalog, but it is the closest external
benchmark to Retally's own and worth revisiting.
