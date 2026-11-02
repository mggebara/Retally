# Corpus shortlist: 6 verified candidates (2026-11-02)

This is the third shortlist pass over the I4R First Meta Database
(`i4r_first_meta_database.csv.gz`). It follows
[`candidates-2026-10-21.md`](candidates-2026-10-21.md) and
[`candidates-2026-11-01.md`](candidates-2026-11-01.md). Machine-readable
details are in `candidates-2026-11-02.json`, which has the same shape as the
2026-11-01 file. It adds `widening_rules`, `text_match` and `supplement_pdf_url`
per paper, plus `rechecks_2026_11_01_curation_failures`, `failed`,
`not_rechecked` and `total_checked`.

**Six papers passed, below the 8–15 target.** The net was widened every way
the brief allows, and the pool of uncatalogued reports with at least 8 paired
rows is 64. Of those, 62 were checked today; the other two failed for reasons
unchanged since earlier passes. Most of the pool fails one of two checks:

- **Package (41 reports).** For 33 AER / AEJ / AER: Insights papers, the
  original package is on openICPSR only, which needs a login and a terms
  click-through. Harvard Dataverse (title and article-DOI searches), Zenodo
  (title and author searches) and GitHub turned up one author mirror
  (Douenne), which is included. Eight JPE/EJ papers have no original package
  anywhere.
- **Open text that matches the published tables.** For many political-science
  papers the article is closed, or the only open copy is a working paper whose
  numbers differ from the published ones.

## What changed in how each requirement was checked

The five hard requirements and how they are checked are as on 2026-11-01. One
check is now stronger:

- **4. Paper text is open and matches the published values.** The full PDF was
  fetched, not just a ranged GET. Its text was extracted with PyMuPDF. Every
  paired `o_coeff_dbl`, and its `o_std_err_dbl`, was searched for at the DB's
  precision (with and without a leading zero, with unicode minus normalised).
  Ambiguous hits were read in context, especially 2-decimal values, which
  match by chance. A working paper counts only if its main tables carry the
  published values; Ono below failed on exactly this.

Every request used `User-Agent: Retally-curation/0.1
(+https://github.com/mggebara/Retally)` with at least 1.1 s between requests
to the same host. A 403 or 429 was retried once, after 5 s.

The widening rules (named in the table as R1–R6) are:

- **R1.** Package size up to 1 GB; any single file over 500 MB is noted.
- **R2.** Archives must be `.zip`, `.tar.gz`, `.tgz` or `.tar` (no `.7z`/`.rar`).
- **R3.** No I4R DP is needed if the DB has at least 8 paired rows.
- **R4.** Open text may come from author homepages, university repositories
  or working-paper series, with the tables spot-checked.
- **R5.** Any journal in the meta-database, 2021–2024.
- **R6.** Python originals are acceptable when the data are plain files.

## Ranked shortlist

| # | Proposed id | Tag / DB rows | Journal | Method | Software (data) | Package | Size | I4R verdict | Rows (total / paired / distinct o) | I4R report | Open text (route) | Rules |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `hollyer-2022-parties-as-disciplinarians` | T62 / 2575–2750 | AJPS 2022 | RDD (Brazil) + cross-national regression | R + Stata (.dta) | [Dataverse AWSQTW](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/AWSQTW) | 1.7 MB | reproducible | 176 / 158 / 76 (Tables 1–2, app. D1) | DP 54 | published, plus supplementary appendix (co-author homepage) | R4 |
| 2 | `douenne-2022-yellow-vests-carbon-tax` | T110 / 6627–6692 | AEJ: Policy 2022 | survey; IV / discontinuity (DB: RDD) | Python + R (.csv, .RData) | [GitHub thomasdouenne/yellow_vests_aej_ep](https://github.com/thomasdouenne/yellow_vests_aej_ep) @ `0faf9e7` | 68.8 MB | **not reproducible** | 66 / 46 / 7 (Table 4) | DP 58 | published (UvA Pure `/ws/files/`) | R4, R5, R6 |
| 3 | `dancygier-2022-hate-crimes-gender-imbalances` | T34 / 1509–1546 | AJPS 2022 | online survey OLS + municipality panel | R (+1 Stata prep do-file) (.dta, .rdata) | [Dataverse QXJDJ5](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/QXJDJ5) | 95.1 MB | reproducible | 38 / 21 / 13 (Table 1, app. C1–C5) | none | published OA, plus online appendix (co-author homepage) | R4 |
| 4 | `mokyr-2022-wheels-of-change` | T100 / 5895–5911 | EJ 2022 | district cross-section OLS + IV | Stata (.dta, .csv) | [Zenodo 5731589](https://zenodo.org/records/5731589) | 7.8 MB | reproducible | 17 / 12 / 3 (Tables 2–3) | none | published (author's Northwestern site) | R4 |
| 5 | `labandeira-2022-electricity-pricing-reform` | T49 / 2226–2248 | EJ 2022 | DiD + IV (household budget survey) | Stata (.dta, .csv, raw .txt) | [Zenodo 5423782](https://zenodo.org/records/5423782) | 558.1 MB (one zip, over 500 MB) | minor discrepancies | 23 / 22 / 5 (Table 2) | none | accepted manuscript, 5 Aug 2021 (Diposit UB) | R1, R4 |
| 6 | `hanushek-2022-patience-risk-human-capital` | T63 / 2751–2845 | EJ 2022 | cross-country student-level regressions | Stata (zip, unverified) | [Dataverse 6HXBSD](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/6HXBSD) | 929.7 MB (one zip, over 500 MB) | minor discrepancies | 95 / 90 / 4 (Tables 1–2) | DP 48 | published (author's Stanford site) | R1, R4 |

"Distinct o" is the number of distinct `o_coeff_dbl` values among the paired
rows. Many I4R rows re-estimate one headline coefficient under robustness
variants. For Douenne, Mokyr, Labandeira and Hanushek the curator will pin
further claims from the printed tables. This is safe because the open text is
the published or accepted version.

**Ranking.** Small packages with an R or Stata original rank first, then
verdict and coverage gaps, then size.

- Hollyer ranks first: smallest package, published text, many paired rows.
- Douenne ranks second although its package is a GitHub repository. It is the
  only **not reproducible** verdict in the pass, and the first AEJ paper.
- Hanushek ranks last: the near-1 GB single zip could not be listed.

**Coverage:**

- **Verdicts:** 3 reproducible (Hollyer, Dancygier, Mokyr), 2 minor
  discrepancies (Labandeira, Hanushek), 1 not reproducible (Douenne). The
  2026-11-01 list had no not-reproducible pick.
- **Journals:** EJ ×3, AJPS ×2, and AEJ: Economic Policy, new to the corpus.
- **Software:**
  - Stata: Mokyr, Labandeira, Hanushek.
  - R: Dancygier (one Stata data-prep do-file).
  - R + Stata: Hollyer.
  - Python + R: Douenne (R6).
- **Size:** Hollyer, Mokyr and Douenne are under 70 MB. Two packages have a
  single file over 500 MB (Labandeira 558 MB, Hanushek 930 MB).
- **Labandeira was 2026-11-01 pick #7 and was not curated.** It is re-listed
  because its open text is now the accepted manuscript, not the 2018 working
  paper.

## Paper PDFs (each fetched in full, `%PDF`, tables spot-checked)

| # | id | URL that served `%PDF` | Version | Spot-check against `o_coeff_dbl` / `o_std_err_dbl` |
|---|---|---|---|---|
| 1 | hollyer | https://titiunik.github.io/files/publications/HollyerKlasnjaTitiunik2022-AJPS.pdf (appendix: https://titiunik.github.io/files/publications/HollyerKlasnjaTitiunik2022-AJPS-SA.pdf) | published (AJPS 66(1): 75–92); appendix dated 22 Feb 2021 | All Table 1 rows found in the article. The appendix has 134/158 coeff+SE, e.g. Table D1 0.38 (0.07), 0.47 (0.12), 1.42 (0.22). |
| 2 | douenne | https://pure.uva.nl/ws/files/131576690/pol.20200092.pdf | published: UvA-DARE cover "Final published version" plus AEJ:EP 14(1): 81–110. OpenAlex mislabels it submitted. | 46/46 coeff+SE (Table 4), e.g. 0.269 (0.058), 0.246 (0.064), −0.151 (0.069) |
| 3 | dancygier | https://naokiegami.com/paper/hatecrime.pdf (appendix: https://naokiegami.com/paper/hatecrime_SM.pdf) | published OA (AJPS 66(2): 501–515, CC BY-NC-ND) | Table 1 col (6) 0.155 (0.019) is in the article. In the appendix: 0.173, 0.192, 0.204, 0.027 (Figure 4 specification), and Tables C1–C5, e.g. 1.634 (0.902), 0.846 (0.319); 19/21 found. |
| 4 | mokyr | https://bpb-us-e1.wpmucdn.com/sites.northwestern.edu/dist/3/1222/files/2024/02/The-Wheels-of-Change-2022-2d19383637e6a5b4.pdf | published (EJ typeset, doi 10.1093/ej/ueab102) | Printed at 2 decimals, agreeing with I4R's 3 by rounding: Table 2 col (5) 0.12 (0.03) vs 0.120 (0.028); Table 3 col (5) 0.12 (0.03) vs 0.117 (0.028); col (6) 0.16 (0.04) vs 0.159 (0.037). |
| 5 | labandeira | https://diposit.ub.edu/bitstreams/6883bfcc-fd5d-466e-adb7-52565ba562bd/download (redirects to `/server/api/core/bitstreams/…/content`) | accepted manuscript, 5 Aug 2021 (Diposit UB 2445/185932) | 21/22 coeff+SE in Table 2, e.g. −0.154 (0.028), −0.123 (0.054), −0.098 (0.028). Col (8) prints −0.089 (0.053); the DB has −0.89, a dropped zero (the SE matches). |
| 6 | hanushek | https://hanushek.stanford.edu/sites/default/files/Hanushek%2BKinne%2BLergetporer%2BWoessmann%202022%20EJ%20132%28646%29.pdf | published (EJ 132(646): 2290–2307) | 90/90 coeff+SE, e.g. Table 1 col (3) 1.226 (0.132), −1.241 (0.184); Table 2 col (3) −0.294 (0.122) |

## The three 2026-11-01 curation failures, re-checked

| Paper (tag / DB rows) | Why curation failed | Status today | Routes tried today |
|---|---|---|---|
| Bautista et al., *Geography of Repression* (T90 / 5213–5251) | Open text was a 2018 Harris draft with a different specification; 0 matching values | **Still excluded**: no published or accepted text reachable | Pearson Institute WP with the final title (uploaded Feb 2021): connection error; the host's TLS certificate is reported expired, and its DNS failed on 2026-11-01. Repositorio UC: DNS failure. Rosario Pure: record has no file. SSRN 3249606: blocked. OpenAlex: closed. |
| De Haas & Popov, *Finance and Green Growth* (T30 / 1266–1321) | Open text was the 2019 ECB WP, a different analysis; the package stubs five proprietary data files | **Still excluded**: no newer open text, and the package problem stands regardless | KU Leuven Lirias 20.500.12942/721664: JS-only Limo page, no file visible. CEPR DP14012: 403. EBRD WP 217 (2018): no PDF found. OpenAlex: closed. |
| Guay & Johnston, *Ideological Asymmetries* (T40 / 1707–1850) | Headline results are figures only, with no printed values | **Still excluded**: structural, not a PDF problem | The MIT DSpace accepted manuscript exists. Its new bitstream link returned 429 twice today; the 2026-11-01 base-handle link served it. I4R DP 79 cites only the original's Figures 1–6, and every DB `original_table` is a figure panel. No open Supporting Information with tables was found. |

## Risks to resolve at promotion time

- **Douenne: the package is a GitHub repository.**
  - The official AEA deposit is openICPSR 128143 (2022-01-28, login).
  - Fetch the codeload zip pinned to commit
    `0faf9e7121ba1f67b1f5b327ed55efcc1665daec` through the downloader's
    direct-URL path. Codeload ignored the 1-byte Range request and answered
    200; the body was discarded.
  - The repo was last pushed on 2021-05-11, so it may differ from the deposit
    I4R ran. DP 58 says the cleaning code fails or differs.
  - The cleaning is Python, and the repo also carries 15 generated `.tex`
    tables and 41 figures.
- **Hanushek: 930 MB single zip, contents unverified.** Dataverse does not
  list zip members. Confirm the zip holds the analysis data and not only code
  for restricted PISA files.
- **Leak surfaces for the strip rule:**
  - Dancygier ships `table1.tex`, `table_C*.tex` and `number_in_texts.R`.
  - Mokyr ships `Nov-1-paper.zip` (the paper itself) and
    `Table_replication.log`.
  - Hollyer ships figure scripts and `Table-E2.do`.
- **Version pinning:** Hollyer (1.0 2021-05-05, 1.1 2022-04-27) and
  Dancygier (1.0 2020-12-09, 1.1 2022-11-22) each have two Dataverse
  versions. Pin the version current at the I4R games unless 1.1 is
  metadata-only.
- **Printed precision:** Mokyr prints 2 decimals. Pin as printed.
- **DB entry error:** Labandeira's Table 2 col (8) row has −0.89 for the
  printed −0.089.
- **Where the rows sit:** most of Hollyer's rows are in the supplementary
  appendix (Table D1). Dancygier's are in appendix Tables C1–C5.
- **Size:** Labandeira (558 MB) and Hanushek (930 MB) are single archives
  over 500 MB on a slow mount.

## Excluded: papers checked today and why they failed

| Paper (tag) | Journal | Package | Failing requirement |
|---|---|---|---|
| Ono & Zilis, *Ascriptive Characteristics…* (T2) | AJPS 2022 | Dataverse ZHOL6Y | **Text does not match the published tables.** RIETI DP 20-E-063 (2020) serves `%PDF` and its Table 2 matches, but Table 3 differs: WP −0.20 vs −0.19, −0.23 vs −0.24, −0.005 vs −0.004, and the published −0.44 (0.07) and −0.15 (0.06) are absent. UKnowledge `viewcontent.cgi` returned 403 twice. |
| Dhar, Jain & Jayachandran, *Reshaping Adolescents' Gender Attitudes* (T73) | AER 2022 | openICPSR E149882 only | **Package.** The text passes: the IPR WP-19-08 revision of Aug 2021 has 220/220 coeff+SE, and the AEA PDF returned 403. Dataverse 6DUTIC is a 2019 3ie deposit (one `Data.zip`, 27.5 MB), not the AER package; its file access returned 400. |
| Gsottbauer et al., *Social Class and (Un)Ethical Behaviour* (T76) | EJ 2022 | Zenodo 6226207 | **PDF.** The Tilburg Pure published file returned 403 twice at `/files/` and 404 at `/ws/files/`. The LMU epub 114927 record has no file. The Innsbruck WP 2020-10 matches only 11/24 coefficients. |
| Hariri & Wingender, *Jumping the Gun* (T46) | EJ 2022 | Zenodo 7077694 | **PDF.** The KU accepted manuscript returned 403 twice at `/files/` and 404 at `/ws/files/`. OUP refuses scripts. Dataverse 2YAHIA (2026) is a different paper (permitless carry laws). |
| Mangonnet, Kopas & Urpelainen, *Playing Politics with Environmental Protection* (T65) | JOP 2022 | Dataverse N6LIMH | **PDF and size.** The SAIS-ISEP Nov 2021 draft returned 403 twice, and JOP is closed. The package is 1,027.5 MB, just over 1 GB in decimal units, and is mostly one 966 MB CSV. |
| Kim, *Entertaining Beliefs in Economic Mobility* (T27) | AJPS 2022 | Dataverse FVRZYU | **PDF.** 2026-11-01 pick #8, now demoted: the only copies are on SSRN (blocked) and in the 2019 dissertation, which fails the stronger check. |
| Martínez, *Dictator's GDP Growth Estimates* (T39) | JPE 2022 | Dataverse 9M0S0M | **PDF.** SSRN only, plus the 2018 Ostrom draft (404 on 2026-11-01). |
| Zelizer, *Talking Shops* (T81) | AJPS 2022 | Dataverse S3M5AX | **PDF.** Closed. The only other copy is a 2019 Princeton CSDP draft with a different subtitle, which returned 403. |
| Hamel & Wilcox-Archuleta (T4); Chu & Recchia (T24); Córdova & Kras (T79); Gubler et al. (T11) | JOP 2022 | Dataverse FMOR6K, BNINNL, D2WL5I, FUCDTT | **PDF closed.** No author or repository copy found. |
| Herzog, Baron & Gibbons (T1) | JOP 2022 | Dataverse GLT4FX | **PDF.** The accepted version is on SSRN only (blocked). |
| Mayshar, Moav & Pascali (T96) | JPE 2022 | only the 2025 comment package (Dataverse 6KG67M) | **Package.** The other Dataverse title hits are unrelated datasets. |
| Borowiecki (T33), Christensen & Timmins (T77), Bianchi & Giorcelli (T87), Waldinger (T88), Carlson et al. (T89), Dickens (T101), Hoopes et al. (T108) | JPE / EJ 2022 | none original | **Package.** Today's Zenodo, Dataverse and GitHub searches found no original package. `peterchristensen/Sorting-or-Steering` is an empty repo, and `cwestheide/i4r_dp66_code` is the comment's code. |
| 32 AEA reports: T3, T8, T9, T13, T14, T20, T23, T26, T28, T37, T44, T48, T50, T53, T54, T55, T56, T67, T71, T72, T75, T80, T82, T84, T85, T91, T93, T98, T99, T102, T103, T106 | AER / AEJ / AER: Insights 2022–2023 | openICPSR only | **Package (login and terms).** No copy was found on Harvard Dataverse (title and article-DOI searches), Zenodo (title and author searches) or GitHub. The GitHub hits for T8, T13, T71 and T106 are third-party replication repos, not originals. |

These were not re-checked, for reasons unchanged:

- T64 Bosquet: `.7z` archive (R2).
- T43 Grosjean: the package has no data.
- Reports with fewer than 8 paired rows, which fail R3: T17, T19, T35, T57,
  T61, T69, and every report with 0 paired rows.

**Total checked today: 62 papers.** That is 6 picks, the 3 re-checks and
53 exclusions, out of a pool of 64 uncatalogued reports with at least 8
paired rows.

## Curation outcomes (2026-11-02)

All six picks were curated into catalog entries on 2026-11-02; none
failed at curation (against four of eight on the 2026-11-01 list).
Results for the six entries are in ROADMAP 3.7.  With them the catalog
has 28 entries, 26 in scope and 23 evaluation papers.

| Candidate | Outcome | Caveat |
|---|---|---|
| `hollyer-2022-parties-as-disciplinarians` (#1) | accepted, PR #100 | 13 claims.  Paper and code disagree on the "extremist" party (distance 3 in the text, the 90th percentile in the do-file), which is why DP 54 missed those rows; at the ±1 SE band the text-following value still passes.  Dataverse v1.1 has files identical to v1.0. |
| `douenne-2022-yellow-vests-carbon-tax` (#2) | accepted, PR #105 | 13 claims; `not_reproducible` (DP 58).  The package is the authors' GitHub repository at commit `0faf9e7` (43 MB zip), very likely the openICPSR snapshot but not compared file by file.  The strip rule learned to content-test `.RData` workspaces. |
| `dancygier-2022-hate-crimes-gender-imbalances` (#3) | accepted, PR #102 | 13 claims; no DP (every meta-database row is a robustness variant).  Pinned to Dataverse v1.0 (v1.1 has identical files).  The existing rule already withholds its 15 stargazer `.tex` tables. |
| `mokyr-2022-wheels-of-change` (#4) | accepted, PR #104 | 13 claims printed at two decimals and pinned as printed.  The manuscript ships as Word files with OCR'd tables; the strip rule learned `.docx` content tests and written-out significance legends. |
| `labandeira-2022-electricity-pricing-reform` (#5) | accepted, PR #103 | 12 claims from the accepted manuscript; the meta-database's −0.89 is a typo for the printed −0.089.  The IV columns omit the quarterly dummies the paper describes and the price is a real price the paper does not call one, which costs text-following runs claims. |
| `hanushek-2022-patience-risk-human-capital` (#6) | accepted, PR #101 | 13 claims.  The zip does hold the analysis data (930 MB, 5.5 GB unpacked), but the 2.47 GB Table 1 file is near the sandbox's 300 s I/O limit: column-selected reads clear it, naive reads do not. |
