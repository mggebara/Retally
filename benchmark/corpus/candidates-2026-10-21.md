# Corpus shortlist: 12 verified candidates (2026-10-21)

These are the next papers to curate into `benchmark/papers/`. Each came from the
I4R First Meta Database (`i4r_first_meta_database.csv.gz`). Each one was
checked against the five hard requirements on 2026-10-21. Machine-readable
details for each paper are in `candidates-2026-10-21.json`.

**How each requirement was checked**

1. **Not already catalogued.** None of the 12 is one of the six existing entries
   (alesina, arias, bisbee, dincecco, frederiksen, marcus).
2. **Package is public.** The repository metadata API returned HTTP 200:
   - Zenodo: `https://zenodo.org/api/records/<id>`.
   - Dataverse: `/api/datasets/:persistentId`, sent with `User-Agent: Retally-curation/0.1`.

   In addition, a 1-byte ranged GET of a package file returned 206 with no
   login, guestbook or terms click-through (Dataverse `/api/access/datafile/<id>`,
   or the Zenodo file link). No Dataverse file in the picks is restricted.
3. **Software and data formats.** These come from the Dataverse file list or the
   Zenodo zip preview. "Unverified" means the archive contents could not be
   listed without downloading the archive.
4. **Paper PDF is open.** A GET of the URL (following redirects) returned a PDF
   content type and the bytes begin with `%PDF`. Publisher pages that answer
   403 to non-browser clients (OUP, Wiley, Elsevier Pure portals) were counted
   as not reachable.
5. **I4R verdict exists.** The verdict comes from the database's
   `perfect_reproduction` and `computational_reproduction` fields:
   - Yes → **reproducible**.
   - No, with computational = 1 → **minor discrepancies**.
   - computational = 0 → **not reproducible**.

   "I4R rows" counts the estimate-level rows that have a replicator coefficient
   (`r_coeff_dbl`). Every one of these rows also has the original coefficient.
   DP numbers come from the I4R Discussion Paper series listing on IDEAS
   (`zbw/i4rdps`).

## Ranked shortlist

| # | Proposed id | Journal | Method | Software (data) | Package source | Size | I4R verdict | I4R rows (total / with r_coeff) | I4R report |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `grier-2023-sugar-roll-call-voting` | APSR 2023 | DiD / panel | Stata (.dta) | [Dataverse 2IFZR9](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/2IFZR9) | 0.5 MB | reproducible | 8 / 6 (Table 1) | DP 57 |
| 2 | `leeson-2022-hobo-economicus` | EJ 2022 | DiD | Stata (nested zip, unverified) | [Zenodo 5719541](https://zenodo.org/records/5719541) | 0.4 MB | minor discrepancies | 16 / 12 (Table 2) | DP 55 |
| 3 | `hanlon-2022-aircraft-ip-spillovers` | EJ 2022 | DiD | Stata (.dta, .csv) | [Zenodo 5627298](https://zenodo.org/records/5627298) | 7.7 MB | reproducible | 23 / 12 (Table 1) | none in DP series |
| 4 | `manekin-2022-effective-for-whom` | APSR 2022 | survey experiment, OLS | R (.tgz, unverified) | [Dataverse SHHVCA](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/SHHVCA) | 2.7 MB | minor discrepancies | 43 / 42 (Tables 1-2) | DP 86 |
| 5 | `adams-2023-women-mps-affective-polarization` | APSR 2023 | cross-national TSCS regression | R (.Rdata, .rds) | [Dataverse AHQRVR](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/AHQRVR) | 10.8 MB | reproducible | 6 / 5 (Table 1) | none in DP series |
| 6 | `altmann-2022-cognitive-spillovers` | REStud 2022 | online experiment, OLS | Stata (.dta) | [Zenodo 5652808](https://zenodo.org/records/5652808) | 8.2 MB | minor discrepancies (0.001 rounding) | 75 / 71 (Tables 2-4) | DP 43 |
| 7 | `montero-2022-cooperative-property-rights` | JPE 2022 | RDD | Stata (.dta) | [Dataverse AMD3NO](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/AMD3NO) | 3.1 MB | not reproducible (coding error) | 204 / 203 (Tables 2-3) | DP 20 |
| 8 | `lopez-moctezuma-2022-policy-deliberation-philippines` | AJPS 2022 | field RCT | R (.RData, .csv) | [Dataverse S3HACJ](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/S3HACJ) | 24.2 MB | minor discrepancies (archived CRAN pkgs) | 10 / 8 (appendix) | none in DP series |
| 9 | `dertwinkel-kalt-2022-concentration-bias` | REStud 2022 | lab/field experiment | Stata + R calibration (.csv) | [Zenodo 5091975](https://zenodo.org/records/5091975) | 11.2 MB | reproducible | 32 / 31 (Tables 2-3) | DP 42 |
| 10 | `holman-2022-theresa-may-rally` | APSR 2022 | DiD / panel | Stata (.dta) | [Dataverse VHNPUO **v1.0**](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/VHNPUO&version=1.0) | 236 MB | not reproducible (coding errors) | 18 / 11 (Table 4) | DP 41 |
| 11 | `acemoglu-2022-war-socialism-fascism` | QJE 2022 | IV | Stata (.dta) | [Dataverse CLJTSC](https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/CLJTSC) | 411 MB | reproducible | 64 / 59 (Tables 1-3) | none in DP series |
| 12 | `gagliarducci-2022-gender-cooperation-congress` | EJ 2022 | RDD + matching | Stata (zip too large to list) | [Zenodo 5111360](https://zenodo.org/records/5111360) | 403 MB | reproducible | 123 / 120 (Table 5) | DP 75 |

**Coverage against the ranking preferences:**

- **Software:** 8 papers are Stata originals and 3 are R originals (Manekin, Adams,
  López-Moctezuma). Dertwinkel-Kalt is Stata with an R calibration script.
- **Verdicts:** 6 reproducible, 4 with minor discrepancies, 2 not reproducible.
- **Journals:** APSR ×4, EJ ×3, REStud ×2, AJPS, JPE, QJE.
- **Methods:**
  - DiD ×4 (Grier, Leeson, Hanlon, Holman)
  - RDD ×2 (Montero, Gagliarducci)
  - IV ×1 (Acemoglu)
  - experiments ×4 (Manekin, Altmann, López-Moctezuma, Dertwinkel-Kalt)
  - cross-national TSCS ×1 (Adams)
- **Years:** all published 2022–2023.
- **Size:** 9 of the 12 packages are under 25 MB. All 12 are under 500 MB.

## Paper PDFs (each verified to return a PDF)

| # | id | PDF URL | Version |
|---|---|---|---|
| 1 | grier | https://www.cambridge.org/core/services/aop-cambridge-core/content/view/DBB341572A3FC0A1D06705B5DDE5C497/S0003055422000466a.pdf/div-class-title-campaign-contributions-and-roll-call-voting-in-the-u-s-house-of-representatives-the-case-of-the-sugar-industry-div.pdf | published (OA) |
| 2 | leeson | https://www.peterleeson.com/Hobo_Economicus.pdf | author copy |
| 3 | hanlon | https://www.nber.org/system/files/working_papers/w26490/w26490.pdf | NBER WP 26490 |
| 4 | manekin | https://www.cambridge.org/core/services/aop-cambridge-core/content/view/D78EE1F9EE3B41D6F1500311F17B8EA6/S0003055421000940a.pdf/div-class-title-effective-for-whom-ethnic-identity-and-nonviolent-resistance-div.pdf | published (OA) |
| 5 | adams | https://www.cambridge.org/core/services/aop-cambridge-core/content/view/D9F115F8EA9677F6AFC9E6D76392B8D5/S0003055422000491a.pdf/div-class-title-can-t-we-all-just-get-along-how-women-mps-can-ameliorate-affective-polarization-in-western-publics-div.pdf | published (OA) |
| 6 | altmann | https://docs.iza.org/dp12337.pdf | IZA DP 12337 (earlier title "Passive Choices and Cognitive Spillovers") |
| 7 | montero | https://www.economics.utoronto.ca/index.php/index/research/downloadSeminarFile/15597 | Jan 2018 draft |
| 8 | lopez-moctezuma | https://authors.library.caltech.edu/api/records/qce9v-wvk72/files/American_J_Political_Sci_-_2020_-_L_pez_u2010Moctezuma_-_Policy_Deliberation_and_Voter_Persuasion_Experimental_Evidence_from_an.pdf/content | published (CaltechAUTHORS; served as octet-stream) |
| 9 | dertwinkel-kalt | https://www.econtribute.de/RePEc/ajk/ajkdps/ECONtribute_076_2021.pdf | ECONtribute DP 076 |
| 10 | holman | https://www.cambridge.org/core/services/aop-cambridge-core/content/view/CCB0F99CE10065BAECA662C140F966EC/S0003055421000861a.pdf/div-class-title-the-curious-case-of-theresa-may-and-the-public-that-did-not-rally-gendered-reactions-to-terrorist-attacks-can-cause-slumps-not-bumps-div.pdf | published (OA) |
| 11 | acemoglu | https://www.nber.org/system/files/working_papers/w27854/w27854.pdf | NBER WP 27854 |
| 12 | gagliarducci | https://www.nber.org/system/files/working_papers/w22488/w22488.pdf | NBER WP 22488 |

## Risks to resolve at promotion time

- **Montero (#7): the package may already be corrected.** The Dataverse record
  has one version only, released 2023-03-31. That is after the I4R comment that
  found duplicate observations. It may therefore be a corrected package, so
  confirm that it reproduces the *published* tables before seeding claims. The
  only open PDF is the 2018 draft, and its numbers may differ from the JPE
  article.
- **Holman (#10): use the original package version.** Pin Dataverse **version
  1.0** (2021-08-26). The latest version (2.0, 2024-08-06) is the
  post-corrigendum package and would not reproduce the published numbers. Check
  whether the downloader can take a version parameter.
- **Working-paper PDFs may not match the published tables.** This applies to
  Hanlon, Altmann, Dertwinkel-Kalt, Acemoglu, Gagliarducci and Montero. Table
  numbers and coefficients can differ, so seed claims from the I4R rows and
  check them against the PDF.
- **Archive contents could not be listed before download:**
  - Leeson: nested zip.
  - Manekin: `.tgz`.
  - Gagliarducci: 403 MB zip that Zenodo will not preview.
- **Packages with extra material** (file-selection noise):
  - Altmann and Dertwinkel-Kalt ship oTree/Python experiment code.
  - Hanlon ships LaTeX sources.
- **Thin I4R coverage:**
  - Adams has 5 rows and Grier has 6.
  - López-Moctezuma's rows come from appendix tables only.
  - Gagliarducci's rows all come from one table.

## Excluded: next papers checked and why they failed

| Paper (I4R team) | Journal | Package found | Failing requirement |
|---|---|---|---|
| Guay & Johnston, *Ideological Asymmetries…* (T40) | AJPS 2022 | Dataverse CGHTPZ, 3.1 MB, R | PDF: Wiley pdfdirect returns 403. The MIT DSpace author copy returns 429 / bot challenge. **First reserve** if DSpace becomes reachable (143 I4R rows). |
| Brouwer, Galeotti & Villeval, *Teaching Norms* (T83) | EJ 2022 | Zenodo 7045559, 4.6 MB, Stata | PDF: the OUP OA PDF returns 403. HAL (hal-03725575, hal-03793652) serves an HTML challenge page. **Second reserve** (284 I4R rows). |
| Zelizer, *Talking Shops* (T81) | AJPS 2022 | Dataverse S3M5AX, 0.5 MB, R | No open PDF found (Wiley only; Semantic Scholar/Unpaywall report no OA copy). |
| Herzog, Baron & Gibbons, *Antinormative Messaging…* (T1) | JOP 2022 | Dataverse GLT4FX, 1.1 MB, R | Only OA copy is on SSRN, which returns 403 on download. JOP is paywalled. |
| Hamel & Wilcox-Archuleta, *Black Workers in White Places* (T4) | JOP 2022 | Dataverse FMOR6K, 10 MB, R | PDF closed (Unpaywall/S2: CLOSED). |
| Hariri & Wingender, *Jumping the Gun* (T46) | EJ 2022 | Zenodo 7077694, 14.8 MB, Stata | PDF: OUP and the KU Pure accepted manuscript both return 403. |
| Gsottbauer et al., *Social Class and (Un)Ethical Behaviour* (T76) | EJ 2022 | Zenodo 6226207, 6.4 MB, Stata | PDF: the Tilburg Pure copy returns 403. OUP is paywalled. |
| Nyrup/Bokobza et al., *The Morning After* (T95) | JOP 2022 | Dataverse GCDJ25, 103 MB, Stata+R | PDF: the AU Pure accepted manuscript returns 403. The DUO record is JS-only. |
| Mokyr, Sarid & van der Beek, *Wheels of Change* (T100) | EJ 2022 | Zenodo 5731589, 7.8 MB, Stata | PDF closed (SSRN only). The paper PDF exists only inside a Zenodo zip. |
| Grosjean, Masera & Yousaf, *Inflammatory Political Campaigns…* (T43) | QJE 2023 | Dataverse A3B9HE | Package has `.do` files and a README only. No data is included. |
| Mangonnet, Kopas & Urpelainen, *Playing Politics with Environmental Protection* (T65) | JOP 2022 | Dataverse N6LIMH, R | 1,027 MB (shapefile zips), over the size limit. No open PDF found. |
| Gubler et al., *Changing Hearts and Minds?* (T11) | JOP 2022 | Dataverse FUCDTT (re-released 2024), R | JOP paywalled. The package was re-published after I4R. |
| Hanushek et al., *Patience, Risk-Taking…* (T63) | EJ 2022 | Dataverse 6HXBSD (930 MB) + openICPSR | Over the size limit. |
| Gethin, Martínez-Toledano & Piketty, *Brahmin Left…* (T5) | QJE 2022 | Dataverse XUSWG6 (1.3 GB) | Over the size limit, and 0 estimate-level I4R rows. |
| AER / AEJ / AER: Insights papers (e.g. Greenstone T9, Okeke T106, Settele T37, Bold T50) | AEA | openICPSR | Out of scope: openICPSR requires login. |
| Dancygier et al., *Hate Crimes and Gender Imbalances* (T34) | AJPS 2022 | Dataverse QXJDJ5, 95 MB | Wiley hybrid-OA PDF returns 403 to non-browser clients. No other copy found. |

These were also looked at and set aside:

- Cordova & Kras (JOP): paywalled.
- Christensen & Timmins (JPE): no Dataverse or Zenodo package found.
- De Haas & Popov (EJ 2023): no open PDF could be verified (CEPR DP 14012 or OUP, which returns 403).
- Chu & Recchia and Donno et al. (JOP): paywalled.
