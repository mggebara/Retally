# Corpus shortlist: 1 verified candidate (2026-11-06)

This is the fourth shortlist pass over the I4R First Meta Database
(`i4r_first_meta_database.csv.gz`). It follows
[`candidates-2026-11-02.md`](candidates-2026-11-02.md). Machine-readable
details are in `candidates-2026-11-06.json`, which has the same shape as the
2026-11-02 file, with `excluded_by_r7` in place of the re-check block.

**Why this pass exists.** Pass 3 used up the pool of uncatalogued reports
with at least 8 paired rows (rule R3). The only reports it left unchecked
were the ones with fewer than 8. This pass adds one rule:

- **R7.** A report qualifies with at least **6** paired rows (`o_coeff_dbl`
  and `r_coeff_dbl` both present, grouped by `replicator_team`), provided
  the paper itself prints at least 8 headline claims to pin. The I4R rows
  then cover only some of the claims; the rest are scored against the paper.

Under R7 the pool is exactly four reports:

- T17 Molina Garzón et al. (7 paired rows)
- T19 Allcott et al. (7)
- T35 Williams (6)
- T57 Laffitte & Toubal (6)

T51, T61 and T69 have 3, 3 and 1 paired rows. They fail R7 and are listed
as excluded below without further checks.

**One paper passed.** The three AEA papers fail on the package, as the 33
AEA papers did in pass 3. T19 is a partial case: its analysis data are on
Harvard Dataverse, but its code is not.

## How each requirement was checked

The requirements are those of 2026-11-02, with R1–R6 unchanged and R7
added. The checks were reproduced with small scripts (kept outside the
repository):

- **Package is public.** The Dataverse `/api/datasets/:persistentId`
  call returned 200, the versions endpoint was read, and the file lists of
  every version were compared by name, size and md5. A 1-byte ranged GET
  on `/api/access/datafile/<id>` (and on `?format=original`) returned 206
  with no login and no guestbook.
- **Only on openICPSR** (T19, T35, T57). Searches run for each paper:
  - Harvard Dataverse: title (exact phrase) and article DOI.
  - Zenodo: title, DOI, and author names (with title words for T19).
  - GitHub repository search: title, DOI, and author or keyword
    combinations.

  On Harvard Dataverse, a `doi:10.3886/E…` hit sits in the "ICPSR
  Harvested Dataverse". That is a harvested metadata record: its API
  answers 401 to guests and holds no files. `openicpsr.org` project pages
  answered 403 (a Cloudflare challenge) to the curation client.
- **Paper text is open and matches the published values.** The full PDF
  was fetched, checked for the `%PDF` magic, and its text extracted with
  PyMuPDF. Every paired `o_coeff_dbl` and `o_std_err_dbl` was searched at
  the DB's precision, as in pass 3. Because this paper prints 2 decimals,
  each DB value was also searched rounded to the printed places, and every
  hit was read in context. The values were then re-estimated from the
  package data (statsmodels, not the authors' code), which recovers the
  DB's 3-decimal values.
- **Headline claims printed** (R7). The main-text tables were counted.

Every request used `User-Agent: Retally-curation/0.1
(+https://github.com/mggebara/Retally)` with at least 1.1 s between requests
to the same host. A 403 or 429 was retried once, after 5 s.

## Ranked shortlist

| # | Proposed id | Tag / DB rows | Journal | Method | Software (data) | Package | Size | I4R verdict | Rows (total / paired / distinct o) | I4R report | Open text (route) | Rules |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `molina-garzon-2022-decentralization-cooperation` | T17 / 855–862 | AJPS 2022 | lab-in-the-field public goods game; matched quasi-experiment; weighted OLS and Poisson | Stata (Table 2) + R (Tables 1, 3) (.dta, .csv) | [Dataverse ZLHYSZ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/ZLHYSZ) | 0.6 MB | reproducible (blank DB fields; survey answer "code produces the same output") | 8 / 7 / 7 (Tables 2–3) | none | published Early View print (NSF PAR 10228422) | R4, R7 |

**Package.** Seven files, none restricted:

- `publicgoodgame_dataAug27` (Stata 14), the game panel for Table 2.
- `clanalysis_anondata_vNov16` (CSV), the network survey for Tables 1
  and 3.
- `healthperception_Aug2020` (Stata 14), used only by an appendix table.
- One R script and one do-file.
- A README and a codebook (PDF).

Version 1.0 (2021-01-08) and version 1.1 (2022-11-22) have identical file
lists, sizes and md5. An earlier deposit by the authors, KDJD27
(2020-09-10, "Forthcoming" in its title), holds the August 2020 versions
of the files. Its two `.dta` files are byte-identical. Its network CSV has
the same size but a different md5, and its scripts differ. The article
cites ZLHYSZ as its verification deposit.

**Text.** The PDF at `https://par.nsf.gov/servlets/purl/10228422` is the
Wiley typeset Early View article, printed from the Wiley e-reader by
co-author Andersson on 2021-05-05 (the page footer says so). It is 16 pp.,
numbered 1–16 rather than the issue's 554–569. OpenAlex lists the article
as closed, Wiley refuses scripts, and the NSF PAR record 10226517 that a
web search names now returns "Not Found".

All 7 paired rows match at the printed 2 decimals:

| Table, column | Variable | Printed | DB `o_coeff_dbl` (`o_std_err_dbl`) |
|---|---|---|---|
| Table 2 col (1) | Decentralized | 0.83 (0.23) | 0.826 (0.226) |
| Table 2 col (1) | Communication | 2.54 (0.21) | 2.541 (0.214) |
| Table 2 col (2) | Decentralized | 0.41 (0.30) | 0.409 (0.302) |
| Table 2 col (2) | Communication | 2.02 (0.32) | 2.023 (0.317) |
| Table 2 col (2) | Interaction | 0.76 (0.38) | 0.762 (0.380) |
| Table 3 col (2), All Ties full | Decentralized | 0.24 (0.14) | 0.240 (0.144) |
| Table 3 col (4), Strong Ties full | Decentralized | 1.07 (0.31) | 1.074 (0.314) |

At the DB's 3 decimals only 1 of 7 matches, and that one by chance.

**R7.** The main text prints 13 headline numbers that can be pinned:

- Table 2: Decentralized and Communication in both columns, the
  interaction, and N.
- Table 3: Decentralized in all four columns, and the two Ns.

**I4R rows.** All 7 paired rows are robustness variants, not
reproductions:

- Table 2: controls dropped, which enlarges the sample.
- Table 3: OLS on the proportion instead of the Poisson count.

So the I4R findings carry the team's blanket verdict, as for Dancygier.

## Risks to resolve at promotion time

- **Printed precision.** Every estimate is printed at 2 decimals. Pin
  the values as printed.
- **Data-format leak surface.** The game dataset ships the fitted values
  and CI bounds of the main Table 2 model (`outcome_ols_*`,
  `standarderror_ols`, `highconf_*`, `lowconf_*`). The strip rule never
  touches data formats.
- **Paper versus code.** Table 2's note says "robust standard errors",
  but the do-file clusters by individual (220 participants).
- **Version.** Pin Dataverse 1.0; 1.1 changes no file.

## Excluded: papers checked today and why they failed

| Paper (tag) | Journal | Package | Failing requirement |
|---|---|---|---|
| Allcott, Gentzkow & Song, *Digital Addiction* (T19) | AER 2022 | code: openICPSR 163822 only; data: openICPSR 167841 and Harvard Dataverse GN636M | **Package (code).** Dataverse GN636M ("Data for: Digital Addiction"; v1.0 2023-03-20, v2.0 2024-01-12; 30.4 MB) holds `final_data_sample.dta`, `final_data_sample_updated.dta` (some app-usage values revised), a codebook and a README, and no code. The `10.3886/E163822*` / `E167841*` Dataverse hits are harvested openICPSR records (API 401). Zenodo (title, DOI, author + title) and GitHub (title, DOI, author keywords) found nothing. |
| Williams, *Historical Lynchings and the Contemporary Voting Behavior of Blacks* (T35) | AEJ: Applied 2022 | openICPSR 136741 only | **Package (login and terms).** The Dataverse title and DOI hits are all harvested openICPSR records. Zenodo and GitHub found no original; the GitHub hits for "historical lynchings" are unrelated lynching-data projects. I4R DP 32 exists; the verdict is reproducible. |
| Laffitte & Toubal, *Multinationals' Sales and Profit Shifting in Tax Havens* (T57) | AEJ: Economic Policy 2022 | openICPSR 148301 only | **Package (login and terms).** The Dataverse title and DOI hits are all harvested openICPSR records. Zenodo (title, DOI, both authors) and GitHub (title, DOI, authors) found nothing. |

Excluded by R7 (fewer than 6 paired rows; not checked further):

| Paper (tag) | Journal | Paired rows |
|---|---|---|
| Bauer, Lakdawala & Mueller, *Market-Based Monetary Policy Uncertainty* (T51) | EJ 2022 | 3 |
| Donno, Morrison & Savun, *Not All Elections Are Created Equal* (T61) | JOP 2022 | 3 |
| Rogowski et al., *Public Infrastructure and Economic Development: Evidence from Postal Systems* (T69) | AJPS 2022 | 1 |

These were not re-checked, for reasons unchanged:

- T64 Bosquet (`.7z`, R2).
- T43 Grosjean (the package has no data).
- Reports with 0 paired rows.
- Everything checked on 2026-11-02.

**Total checked today: 4 papers.** That is 1 pick and 3 exclusions, out of
a pool of 4 uncatalogued reports with 6 or 7 paired rows. With this pass,
every uncatalogued I4R report with at least 6 paired rows has been checked.
The ones still out are blocked by the openICPSR login, by closed text, or
by structural problems recorded in earlier passes.
