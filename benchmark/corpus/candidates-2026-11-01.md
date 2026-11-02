# Corpus shortlist: 8 verified candidates (2026-11-01)

This is the second shortlist pass over the I4R First Meta Database
(`i4r_first_meta_database.csv.gz`). It follows the first pass,
[`candidates-2026-10-21.md`](candidates-2026-10-21.md). Machine-readable
details for each paper are in `candidates-2026-11-01.json`, which has the same
shape as the earlier file plus a `tag`, a `db_row_index` and a
`reserves_2026_10_21` block.

**What changed in reachability since 2026-10-21.**

Several open repositories that blocked us last time now serve PDFs:

- **HAL** (`hal.science`, `cnrs.hal.science`, `sciencespo.hal.science`) now
  returns `%PDF` for `/document` and `/file/` links. Last time it served an
  HTML challenge page.
- **MIT DSpace** now answers 200. Last time it returned 429 / a bot challenge.
  The base handle's bitstream redirects to a 4Science CDN and serves the PDF.
  The versioned handles (`.2`, `.4`) return 500 from the bitstream REST
  endpoint.
- **Elsevier Pure portals** (Aarhus, SDU, KU, Tilburg, Princeton) now return
  200 for landing pages. Last time they returned 403. File access is uneven:
  - The portal `/files/<id>/…` links still return 403 everywhere.
  - The legacy `/ws/files/<id>/…` path serves the PDF on Aarhus and SDU, but
    returns 404 on KU and Tilburg.
- **Penn's DSpace REST API** serves bitstreams.

Publisher and preprint hosts still refuse non-browser clients:

- Still 403: OUP (`academic.oup.com`), Wiley (`onlinelibrary.wiley.com`,
  including `pdfdirect`), SSRN (every abstract and `Delivery.cfm` link),
  `journals.uchicago.edu` (JPE articles and supplements), Taylor & Francis,
  CEPR, PubMed Central (`pmc.ncbi.nlm.nih.gov`), bepress/UKnowledge
  `viewcontent.cgi`, DOAJ and `brocku.ca`.
- Answering as before: NBER, EconStor, ECB, WRAP (Warwick), FRBSF, IREA (UB),
  Illinois, Harris, Cambridge Core and Zenodo/Dataverse.
- Four hosts could not be resolved from this environment's DNS, so they are
  **unverified, not refused**: `rieti.go.jp`, `thepearsoninstitute.org`,
  `repositorio-az.uc.cl` and `socialsciencereproduction.org`.

**How each requirement was checked** (the same five checks as 2026-10-21)

Every request used `User-Agent: Retally-curation/0.1
(+https://github.com/mggebara/Retally)`. Requests were spaced at least 1.1 s
apart per host. A 403 or 429 was retried at most once, after 5 s.

1. **Not already catalogued.** None of the 8 is one of the 18 entries in
   `benchmark/papers/`. Those 18 are the 6 original entries plus the 12
   picks from 2026-10-21.
2. **Package is public.** The repository metadata API returned HTTP 200:
   - Zenodo: `https://zenodo.org/api/records/<id>`.
   - Dataverse: `/api/datasets/:persistentId`.

   In addition, a 1-byte ranged GET of a package file returned 206 with no
   login, guestbook or terms page (Dataverse `/api/access/datafile/<id>`, or
   the Zenodo file link). No Dataverse file in the picks is restricted.
3. **Software and data formats.** These come from the Dataverse file list or
   the Zenodo zip preview (`/records/<id>/preview/<file>`). "Unverified" means
   the archive could not be listed without downloading it.
4. **Paper PDF is open.** A ranged GET (following redirects) returned a PDF
   content type, and the bytes begin with `%PDF`. One URL was also opened in
   full, because a "PDF" on a summary page can be a one-page brief: the BFI
   copy of Martínez (see Excluded).
5. **I4R verdict exists.** The verdict comes from the database's
   `perfect_reproduction` and `computational_reproduction` fields, mapped the
   same way as on 2026-10-21:
   - Yes → **reproducible**.
   - No, with computational = 1 → **minor discrepancies**.
   - computational = 0 → **not reproducible**.

   "Rows" counts estimate-level rows with a replicator coefficient
   (`r_coeff_dbl`). All of them also have `o_coeff_dbl`. "DB rows" is the
   0-based row-index range in the CSV, and `T<n>` is `replicator_team`. DP
   numbers were matched by title against the IDEAS listing of the I4R
   Discussion Paper series (`zbw/i4rdps`, 336 entries).

## Ranked shortlist

| # | Proposed id | Tag / DB rows | Journal | Method | Software (data) | Package | Size | I4R verdict | I4R rows (total / r_coeff) | I4R report |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | `de-haas-2023-finance-green-growth` | T30 / 1266–1321 | EJ 2023 | macro country-industry panel: FE interactions, IV, GMM | Stata (.dta) | [Zenodo 7220094](https://zenodo.org/records/7220094) | 6.2 MB | minor discrepancies | 56 / 55 (Tables 2-3) | DP 95 |
| 2 | `carrera-2022-who-chooses-commitment` | T107 / 6300–6334 | REStud 2022 | field experiment (+ structural sims) | Stata (.dta); MATLAB for sims only | [Zenodo 5173081](https://zenodo.org/records/5173081) | 8.1 MB | reproducible | 35 / 30 (Tables 3-4) | none in DP series |
| 3 | `bokobza-2022-morning-after-coup-purges` | T95 / 5629–5765 | JOP 2022 | linear panel models + placebo tests | Stata (.dta) + R (.rds) | [Dataverse GCDJ25](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/GCDJ25) | 102.8 MB | reproducible | 137 / 135 (appendix A1-A3, K1-K2; Figs 3-5) | none in DP series |
| 4 | `bosquet-2022-peer-effects-academic-research` | T64 / 2846–2885 | EJ 2022 | IV | Stata + "other" (.7z, unverified) | [Zenodo 6457037](https://zenodo.org/records/6457037) | 78.9 MB | reproducible | 40 / 39 (Table 3) | none in DP series |
| 5 | `forsythe-2022-young-workers-recessions` | T109 / 6412–6626 | EJ 2022 | CPS panel, linear probability models | Stata (.csv) | [Zenodo 5710784](https://zenodo.org/records/5710784) | 347.3 MB | reproducible | 215 / 214 (Tables 1-6, 10, B.2) | DP 163 |
| 6 | `bautista-2023-geography-repression-autocracy` | T90 / 5213–5251 | AJPS 2023 | IV (distance to military bases) | Stata (.dta, .csv) | [Dataverse EYAWES](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/EYAWES) | 166.7 MB | reproducible | 39 / 35 (Tables 2-3) | none in DP series |
| 7 | `labandeira-2022-electricity-pricing-reform` | T49 / 2226–2248 | EJ 2022 | DiD + IV (energy demand) | Stata (.dta, .csv, raw .txt) | [Zenodo 5423782](https://zenodo.org/records/5423782) | 558.1 MB | minor discrepancies | 23 / 22 (Table 2) | none in DP series |
| 8 | `kim-2022-entertaining-beliefs-economic-mobility` | T27 / 1199–1213 | AJPS 2022 | lab / online experiments, survey | R (.RData) | [Dataverse FVRZYU](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/FVRZYU) | 55.1 MB | reproducible | 15 / 14 (Tables 1-2, F2) | none in DP series |

The list has eight picks, the bottom of the 8–12 range. Of the 34 papers
checked, these are all that passed the five checks today.

**Ranking.** Papers under 50 MB with an R or Stata original rank first, then
DP coverage and coverage gaps, then size. Kim ranks last because the only open
text is the dissertation, not the article.

**Coverage against the ranking preferences:**

- **Software:**
  - 6 Stata originals: De Haas, Carrera, Bosquet, Forsythe, Bautista,
    Labandeira.
  - 1 R original: Kim.
  - 1 mixed Stata + R: Bokobza.
  - Carrera uses MATLAB only for its structural simulations.
- **Verdicts:** 6 reproducible and 2 with minor discrepancies (De Haas,
  Labandeira). There is **no "not reproducible" pick**. Every not-reproducible
  report in the pool failed a check: Martínez on the PDF; Bianchi & Giorcelli
  and Christensen & Timmins on the package.
- **Journals:** EJ ×4, AJPS ×2, REStud, JOP. JOP is new to the corpus.
- **Methods new to the set:**
  - macro / industry panel with GMM (De Haas)
  - CPS labour-market panel (Forsythe)
  - IO / energy-demand DiD-IV (Labandeira)
  - economics-of-science IV (Bosquet)
  - political-economy-history IV (Bautista)
- **Years:** De Haas and Bautista are 2023; the rest are 2022.
- **Size:** 2 packages are at or under 50 MB, and Kim is just over at 55 MB.
  Labandeira is the only pick above 500 MB.

## Paper PDFs (each verified to return a PDF)

| # | id | PDF URL | Version |
|---|---|---|---|
| 1 | de-haas | https://www.ecb.europa.eu/pub/pdf/scpwps/ecb.wp2318~44719344e8.en.pdf | ECB WP 2318 (2019), earlier title *Finance and Carbon Emissions* |
| 2 | carrera | https://www.nber.org/system/files/working_papers/w26161/w26161.pdf | NBER WP 26161 |
| 3 | bokobza | https://pure.au.dk/ws/files/365105209/The_Morning_After_Cabinet_Instability_and_the_Purging_of_Ministers_after_Failed_Coup_Attempts_in_Autocracies_Accepted_.pdf | accepted manuscript (Aarhus Pure, `/ws/files/` path) |
| 4 | bosquet | https://sciencespo.hal.science/hal-03874070v1/file/2022_bosquet_combes_henry_mayer_peer_effects_in_academic_research_senders_and_receivers.pdf | 2022 version (Sciences Po HAL) |
| 5 | forsythe | https://publish.illinois.edu/elizaforsythe/files/2022/01/Forsythe_Youth_Hiring_prepub_version_2021.pdf | author pre-publication version (2021) |
| 6 | bautista | https://harris.uchicago.edu/files/repression_v2_prelim_6.pdf | Harris preliminary draft (2018), earlier title |
| 7 | labandeira | https://www.ub.edu/irea/working_papers/2018/201828.pdf | IREA WP 2018/28 |
| 8 | kim | https://repository.upenn.edu/server/api/core/bitstreams/c9a17945-bc43-4b7b-83cf-8c2383722b1d/content | Penn PhD dissertation (2019) of the same title, **not the article** |

## The two 2026-10-21 reserves, re-checked today

Both reserves are now reachable, so either can be promoted ahead of, or
alongside, the list above.

| Reserve | Tag / DB rows | Status | URL that worked | Routes that failed |
|---|---|---|---|---|
| Guay & Johnston, *Ideological Asymmetries…* (AJPS 2022), `guay-2022-ideological-asymmetries-motivated-reasoning` | T40 / 1707–1850; 144 / 143 rows; DP 79 | **reachable** | https://dspace.mit.edu/bitstream/handle/1721.1/140315/10.1111-ajps.12624.pdf (published version; redirects to `cf003.cdn.4science.cloud`, 206 `%PDF`) | Wiley `pdfdirect` returned 403 twice. DSpace versioned handles `1721.1/140315.2` and `.4`: landing 200, bitstream REST 500. |
| Brouwer, Galeotti & Villeval, *Teaching Norms* (EJ 2022), `brouwer-2022-teaching-norms` | T83 / 4164–4448; 285 / 284 rows; DP 106 | **reachable** | https://cnrs.hal.science/hal-03725575v1/file/Teaching_Children__HAL_17July22.pdf (submitted version, 17 July 2022; 206 `%PDF`). https://hal.science/hal-03793652v1/document also returns 206 `%PDF`. | OUP `article-pdf` returned 403 twice. |

Reserve notes:

- **Guay:** Dataverse CGHTPZ is now at **version 2.0** (2023-05-01). Earlier
  versions are 1.0 (2021-04-05) and 1.1 (2022-11-22). A major version means
  the files changed, so pin 1.x unless 2.0 is shown to be cosmetic.
- **Brouwer:** the Zenodo zip also contains `EJ MS20210782_accepted.pdf`,
  which is closer to the published tables than the HAL submitted version.

## Risks to resolve at promotion time

- **Working papers, drafts and the dissertation may not match the published
  tables.** Seed claims from the I4R rows and check each against the PDF:
  - De Haas (2019 ECB WP, different title)
  - Carrera (NBER 2019)
  - Bautista (2018 draft, different title)
  - Labandeira (2018 WP)
  - Kim (2019 dissertation)
- **De Haas: check the package against the 2025 correction.** The EJ
  published a correction in 2025 after a comment found two coding errors.
  Both Zenodo records (7185770 of 2022-10-11 and 7220094 of 2022-10-18)
  predate it and are 6.2 MB each. Confirm that the pinned record reproduces
  the *published* tables, and that it is the one I4R used.
- **Archives that could not be listed:** Bosquet ships a `.7z`, which Zenodo
  does not preview. Confirm it contains data and not only code for
  confidential French administrative records. The I4R DB also flags "other"
  software.
- **Size:**
  - Labandeira is 558 MB, mostly raw INE `.txt` files. A ready analysis
    `.dta` is included.
  - Forsythe is 347 MB, almost all one CPS `.csv`.
  - Bautista is 167 MB and Bokobza 103 MB, mostly figures and shapefiles.
- **Packaging quirks:**
  - Bokobza's Stata do-file is shipped as `.txt`.
  - Carrera's zip carries 222 simulation `.csv` and many generated `.tex`
    files.
  - Bautista bundles `.ado` files (`acreg`, `lassoShooting`).
- **Where the I4R rows sit:**
  - Bokobza's rows are all appendix tables and figures.
  - Bosquet's rows all come from Table 3, and Labandeira's from Table 2.
  - Forsythe has 214 rows, so curate a headline subset.
- **Author names misspelled in the I4R DB.** The DB has "Justin Syndor"
  (Carrera) and "Eliza Forsyth" (Forsythe). The JSON uses Sydnor and
  Forsythe.

## Excluded: papers checked today and why they failed

| Paper (tag) | Journal | Package found | Failing requirement |
|---|---|---|---|
| Martínez, *How Much Should We Trust the Dictator's GDP Growth Estimates?* (T39) | JPE 2022 | Dataverse 9M0S0M, 205.6 MB, Stata; **not reproducible** | PDF. SSRN 3093296 and 3882062 return 403. The Ostrom Workshop 2018 draft is now 404. The BFI PDF is a one-page "Economic Finding" summary, not the paper. JPE returns 403. |
| Ono & Zilis, *Ascriptive Characteristics…* (T2) | AJPS 2022 | Dataverse ZHOL6Y, 45.9 MB, Stata + R; reproducible; 32 rows | PDF. Wiley returns 403. The UKnowledge `viewcontent.cgi` submitted version returns 403. RIETI DP 20-E-063 could not be resolved by DNS from this environment (unverified). |
| Hollyer, Klašnja & Titiunik, *Parties as Disciplinarians* (T62) | AJPS 2022 | Dataverse AWSQTW, 1.7 MB, Stata + R; reproducible; 158 rows; DP 54 | PDF closed. OpenAlex and Semantic Scholar report no OA copy, and the Princeton Pure record has no file. |
| Molina-Garzón et al., *Decentralization Can Increase Cooperation…* (T17) | AJPS 2022 | Dataverse ZLHYSZ, 0.6 MB, R + Stata; reproducible | PDF closed (no OA location found). |
| Zelizer, *Talking Shops* (T81) | AJPS 2022 | Dataverse S3M5AX, 0.5 MB, R; DP 69 | PDF closed (unchanged from 2026-10-21). |
| Bauer, Lakdawala & Mueller, *Market-Based Monetary Policy Uncertainty* (T51, T52) | EJ 2022 | Zenodo 5566246, 4.9 MB, R + MATLAB; DP 76/77 | Software and coverage. The I4R rows (Table 4) come from MATLAB (`tab4.m`). There are only 3 paired rows, and team 52 has none. The PDF is open (WRAP accepted version; FRBSF WP 2019-12). |
| Borowiecki, *Good Reverberations?* (T33) | JPE 2022 | none on Dataverse or Zenodo; DP 27 | Package. The JPE supplement on `journals.uchicago.edu` returns 403. The PDF is open (SDU `/ws/files/`). |
| Bianchi & Giorcelli, *Dynamics and Spillovers of Management Interventions* (T87) | JPE 2022 | none found; **not reproducible** | Package (JPE site returns 403). The PDF is open (NBER w28833); PMC returns 403. |
| Christensen & Timmins, *Sorting or Steering* (T77) | JPE 2022 | none found; R; **not reproducible**; 252 rows | Package (unchanged). The PDF is open (NBER w24826). |
| Waldinger, *Economic Effects of Long-Term Climate Change* (T88) | JPE 2022 | none for the original; only a 2025 Economic Inquiry replication package on openICPSR (E234462) | Package. The only open PDF is a 2015 LSE Grantham WP. |
| Carlson, Correia & Luck, *Effects of Banking Competition…* (T89) | JPE 2022 | only the I4R comment's Dataverse BB864R (do-files, no data); DP 81 | Package. SSRN returns 403. |
| Mayshar, Moav & Pascali, *The Origin of the State* (T96) | JPE 2022 | only a 2025 comment package, Dataverse 6KG67M | Package. The PDF is open (WRAP). |
| Dickens, *Understanding Ethnolinguistic Differences* (T101) | EJ 2022 | none found on Zenodo | Package. The Brock RePEc PDF returns 403. |
| Hoopes et al., *Who Sells During a Crash?* (T108) | EJ 2022 | none (confidential IRS data) | Package. The PDF is closed. |
| Hariri & Wingender, *Jumping the Gun* (T46) | EJ 2022 | Zenodo 7077694, 14.8 MB, Stata; DP 50 | PDF. OUP returns 403. The KU Pure landing now returns 200, but `/files/…accepted.pdf` returns 403 and `/ws/files/` returns 404. |
| Gsottbauer et al., *Social Class and (Un)Ethical Behaviour* (T76) | EJ 2022 | Zenodo 6226207, 6.4 MB, Stata; DP 29 | PDF. The Tilburg Pure landing returns 200, but the file returns 403 and `/ws/files/` returns 404. OUP returns 403. |
| Mokyr, Sarid & van der Beek, *Wheels of Change* (T100) | EJ 2022 | Zenodo 5731589, 7.8 MB, Stata | PDF. The paper still exists only inside a Zenodo zip; OpenAlex reports it closed. |
| Dancygier et al., *Hate Crimes and Gender Imbalances* (T34) | AJPS 2022 | Dataverse QXJDJ5 (2026-10-21) | PDF. Wiley still returns 403, and the SSRP report DOIs did not resolve (DNS). |
| Herzog, Baron & Gibbons, *Antinormative Messaging…* (T1) | JOP 2022 | Dataverse GLT4FX (2026-10-21) | PDF. SSRN 3787157 still returns 403. |
| Hamel & Wilcox-Archuleta, *Black Workers in White Places* (T4) | JOP 2022 | Dataverse FMOR6K (2026-10-21) | PDF closed. The only OA hit is the I4R report itself (DP 61). |
| Gubler et al., *Changing Hearts and Minds?* (T11) | JOP 2022 | Dataverse FUCDTT (2026-10-21) | PDF closed. The OA hit is a 2024 MUNI working paper, not the article. |
| Chu & Recchia (T24), Donno et al. (T61), Cordova & Kras (T79) | JOP 2022 | Dataverse BNINNL, 8B31FG, D2WL5I | PDF closed. OpenAlex and Semantic Scholar report no OA location. |

These were not re-checked, for reasons unchanged since 2026-10-21:

- AER, AEJ and AER: Insights papers, because openICPSR requires a login.
- Reports with 0 estimate-level `r_coeff` rows: T5, T6, T18, T21, T29, T38,
  T42, T47, T58, T59, T60, T70, T74, T94, T97, T105.
- T63 Hanushek and T65 Mangonnet, which are over the size limit.
- T43 Grosjean, which has no data.

**Total checked today: 34 papers** (8 picks, 2 reserves and 24 exclusions).

## Curation outcomes (2026-11-02)

Eight candidates were attempted on 2026-11-01: six picks from the ranked
list and the two 2026-10-21 reserves.  Four became catalog entries and
four were excluded.  Labandeira (#7) and Kim (#8) were not attempted and
remain available.  Results for the four entries are in ROADMAP 3.6.

| Candidate | Outcome | Reason |
|---|---|---|
| `carrera-2022-who-chooses-commitment` (#2) | accepted, PR #91 | 11 claims from Tables 3–4.  The open text is the NBER WP 26161 revision (August 2021), and its values equal the I4R rows.  The strip rule learned `N` / `Clusters` rows and result-macro `.tex` files. |
| `bokobza-2022-morning-after-coup-purges` (#3) | accepted, PR #93 | 11 claims from appendix Tables A1, A2 and K1–K3, because the main text is figures only.  The open text is the accepted manuscript.  The strip rule learned rendered R Markdown pages.  The country-level do-file ships as `.txt`. |
| `forsythe-2022-young-workers-recessions` (#5) | accepted, PR #92 | 13 claims from Tables 1, 2 and 10.  The label is `robust`, not `reproducible`: I4R DP 163 rebuilt the CPS panel from IPUMS and never ran the package.  The main `.csv` is 2.17 GB uncompressed. |
| `brouwer-2022-teaching-norms` (2026-10-21 reserve) | accepted, PR #94 | 12 claims from Table 2.  The open HAL text is the accepted manuscript, text-identical to the package's accepted PDF.  The strip rule learned PDFs with regression-table pages. |
| `bautista-2023-geography-repression-autocracy` (#6) | excluded | The only open text is the 2018 Harris draft, which uses a different specification; 0 of its values match the published tables. |
| `de-haas-2023-finance-green-growth` (#1) | excluded | The open text is the 2019 ECB working paper, a different analysis from the published one.  The package also stubs five proprietary data files. |
| `guay-2022-ideological-asymmetries-motivated-reasoning` (2026-10-21 reserve) | excluded | Figures only: the paper prints no headline values to pin.  The open text is the accepted manuscript. |
| `bosquet-2022-peer-effects-academic-research` (#4) | excluded | The package is a `.7z` archive the downloader cannot read.  Inside are 3 GB of SAS and Stata files and 46 result tables. |

What the exclusions add to the five shortlist checks:

- The open PDF must print the published tables, not just exist.
  Bautista and De Haas passed check 4 with earlier versions that do not.
- The main text must state its headline numbers.  Guay has only figures;
  Bokobza passed only because its appendix tables print the plotted
  coefficients.
- The package must be complete and in a format the downloader can
  unpack.  De Haas stubs its proprietary inputs, and Bosquet's `.7z` is
  unreadable.

Screen for these at shortlist time on the next pass.
