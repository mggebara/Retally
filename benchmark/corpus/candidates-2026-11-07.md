# Corpus shortlist, pass 5: data-only deposits (rule R8 proposal, 2026-11-07)

This is the fifth shortlist pass over the I4R First Meta Database
(`i4r_first_meta_database.csv.gz`). It follows
[`candidates-2026-11-06.md`](candidates-2026-11-06.md). Machine-readable
details are in `candidates-2026-11-07.json`.

**Why this pass exists.** Passes 3 and 4 excluded 36 AEA-journal reports
because their replication package is on openICPSR only (login and terms,
which the benchmark does not bypass). The benchmark's independent and blind
modes mount the package with the scripts removed anyway
(`benchmark/strip_rule.py`), so a deposit of the analysis *data* outside
openICPSR would support those two modes; only seeded mode needs the
authors' scripts. Pass 4 found one such deposit (T19). This pass checks
all 36 for the same thing and PROPOSES a rule; the rule is not adopted and
no catalog entry is created here.

- **R8 (proposal).** A report qualifies for independent and blind mode
  when (a) its published text is open (publisher, author copy, NSF PAR,
  or a working paper whose main-table numbers equal the published values
  recorded in the I4R rows) and (b) its analysis data is openly deposited
  outside openICPSR (Harvard Dataverse, Zenodo, OSF, GitHub, an author
  site), fetchable, under 1 GB, even without code. Seeded mode is then not
  applicable unless the deposit also carries the scripts.

## How each requirement was checked

- **Data deposits.** For each report: Crossref and OpenAlex (DOI, OA
  locations), the Harvard Dataverse search API (exact title, author
  keywords, article DOI), Zenodo and OSF search (title, authors), GitHub
  repository search, and the AEA article page for the replication-package
  DOI. Dataverse records were read through `/api/datasets/:persistentId`
  (version, licence, file list, restricted flags). A `doi:10.3886/E…` hit on
  Dataverse is a harvested openICPSR record (API 401, no files). Third-party
  GitHub re-uploads of openICPSR packages are excluded, as in pass 3.
- **Open text.** Candidate URLs from OpenAlex, NSF PAR, author sites and
  working-paper series were fetched; the `%PDF` magic was checked and the
  text extracted with PyMuPDF; every paired `o_coeff_dbl` and
  `o_std_err_dbl` was searched at the database precision. "N of M exact"
  below counts distinct paired values found verbatim. The check reached 24
  of 36 reports; the rest are marked not checked (403/404, non-PDF, or no
  candidate URL).
- Every request used `User-Agent: Retally-curation/0.1
  (+https://github.com/mggebara/Retally)` with at least 1.1 s between
  requests to the same host. The scripts and raw results were kept outside
  the repository.

## Result: one R8 candidate

| Tag | Title | Journal | Paired rows | Open text | Data deposit outside openICPSR | Overall |
|---|---|---|---|---|---|---|
| T73 | Reshaping Adolescents' Gender Attitudes: Evidence from a School-Based Experiment in India | AER 2022 | 220 | open: working paper, 53 of 69 paired values exact ([link](https://www.nber.org/system/files/working_papers/w25331/w25331.pdf)) | 3ie Impact Evaluation Dataverse doi:10.7910/DVN/6DUTIC (27.5 MB): Data.zip: ready-for-analysis data, Stata do-files, codebooks and questionnaires of the 3ie final report (v1, 2019-07-25; authors Jayachandran, Jain, Dhar; no licence or terms fields); predates the AER version | **R8 candidate (data and code; verify the 3ie package reproduces the published tables at curation)** |
| T19 | Digital Addiction | AER 2022 | 7 | open: working paper, 2 of 7 paired values exact ([link](https://www.nber.org/system/files/working_papers/w28936/w28936.pdf)) | Harvard Dataverse doi:10.7910/DVN/GN636M (30.4 MB): data only (final_data_sample.dta, updated copy, codebook, README); no code; non-redistribution licence | **excluded: open text fails (NBER WP matches 2 of 7); data-only deposit exists** |
| T3 | Assortative Matching at the Top of the Distribution: Evidence from the World's Most Exclusive Marriage Market | AEJ: Applied Economics 2022 | 69 | unreadable (HTTP -1) ([link](https://nora.nb.no/handle/11250/3061780)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T8 | Can Information Reduce Ethnic Discrimination? Evidence from Airbnb | AEJ: Applied Economics 2022 | 24 | open: author/repository copy, 2 of 3 paired values exact ([link](https://wrap.warwick.ac.uk/146995/1/WRAP-Can-information-reduce-ethnic-discrimination-evidence-Airbnb-2020.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T9 | Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution | AER 2022 | 270 | open: working paper, 49 of 71 paired values exact ([link](https://www.nber.org/system/files/working_papers/w27502/w27502.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T13 | Checking and Sharing Alt-Facts | AEJ: Economic Policy 2022 | 48 | open: working paper, 7 of 11 paired values exact ([link](https://sciencespo.hal.science/hal-03389187/document)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T14 | Child Marriage Bans and Female Schooling and Labor Market Outcomes: Evidence from Natural Experiments in 17 Low- and Middle-Income Countries | AEJ: Economic Policy 2022 | 60 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T20 | Do Thank-You Calls Increase Charitable Giving? Expert Forecasts and Field Experimental Evidence | AEJ: Applied Economics 2023 | 15 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T23 | Does Patient Demand Contribute to the Overuse of Prescription Drugs? | AEJ: Applied Economics 2022 | 30 | open: working paper, 21 of 30 paired values exact ([link](http://documents.worldbank.org/curated/en/780321606314613926/pdf/Does-Patient-Demand-Contribute-to-the-Overuse-of-Prescription-Drugs.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T26 | Enabling or Limiting Cognitive Flexibility? Evidence of Demand for Moral Commitment | AER 2023 | 75 | unreadable (HTTP 403) ([link](https://escholarship.org/content/qt0874x1wz/qt0874x1wz.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T28 | Evaluating Deliberative Competence: A Simple Method with an Application to Financial Choice | AER 2022 | 49 | unreadable (HTTP 200) ([link](https://www.zora.uzh.ch/id/eprint/227304/1/aer.20210290.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T35 | Historical Lynchings and the Contemporary Voting Behavior of Blacks | AEJ: Applied Economics 2022 | 6 | open: author/repository copy, 0 of 2 paired values exact ([link](https://topcat.aeaweb.org/conference/2019/preliminary/paper/YBZ4TyNr)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T37 | How Do Beliefs about the Gender Wage Gap Affect the Demand for Public Policy? | AEJ: Economic Policy 2022 | 116 | open: author/repository copy, 113 of 116 paired values exact ([link](https://www.econtribute.de/RePEc/ajk/ajkdps/ECONtribute_179_2022.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T44 | Interaction, Stereotypes, and Performance: Evidence from South Africa | AER 2022 | 40 | unreadable (HTTP 404) ([link](https://www.ifs.org.uk/uploads/publications/wps/WP201903.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T48 | Local Elites as State Capacity: How City Chiefs Use Local Information to Increase Tax Compliance in the Democratic Republic of the Congo | AER 2022 | 129 | open: author/repository copy, 45 of 60 paired values exact ([link](https://jonathanweigel.com/s/weigel_et-al_collectors.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T50 | Market Access and Quality Upgrading: Evidence from Four Field Experiments | AER 2022 | 27 | unreadable (HTTP 200) ([link](https://www.povertyactionlab.org/media/10072)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T53 | Measuring the Welfare Effects of Pride and Shame | AER 2022 | 48 | open: working paper, 34 of 45 paired values exact ([link](http://www.nber.org/papers/w25637.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T54 | Mental Health Costs of Lockdowns: Evidence from Age-Specific Curfews in Turkey | AEJ: Applied Economics 2022 | 28 | open: working paper, 8 of 9 paired values exact ([link](https://docs.iza.org/dp14281.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T55 | Mortality, Temperature, and Public Health Provision: Evidence from Mexico | AEJ: Economic Policy 2022 | 42 | open: author/repository copy, 0 of 7 paired values exact ([link](https://researchonline.lse.ac.uk/id/eprint/115766/1/AEJPol_2018_0594_REV3_manuscript_POSTPRINT.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T56 | Motivated Beliefs and Anticipation of Uncertainty Resolution | AER: Insights 2022 | 12 | unreadable (HTTP -1) ([link](https://cms.mgt.tum.de/fileadmin/mgt.tum.de/faculty_and_research/mppe/07_Motivated_beliefs__and_anticipation_of_uncertainty_resolution.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T57 | Multinationals' Sales and Profit Shifting in Tax Havens | AEJ: Economic Policy 2022 | 6 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T67 | Political Turnover, Bureaucratic Turnover, and the Quality of Public Services | AER 2022 | 99 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T71 | Rebel on the Canal: Disrupted Trade Access and Social Conflict in China, 1650–1911 | AER 2022 | 34 | no open copy found / not checked | none original (GitHub brycewang-stanford/AER2022-Rebel-on-the-Canal is a third-party archive, excluded by the pass-3 policy) | **excluded: no data deposit outside openICPSR** |
| T72 | Recessions, Mortality, and Migration Bias: Evidence from the Lancashire Cotton Famine | AEJ: Applied Economics 2022 | 40 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T75 | School Spending and Student Outcomes: Evidence from Revenue Limit Elections in Wisconsin | AEJ: Economic Policy 2022 | 38 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T80 | Student Performance, Peer Effects, and Friend Networks: Evidence from a Randomized Peer Intervention | AEJ: Economic Policy 2023 | 44 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T82 | Targeting High Ability Entrepreneurs Using Community Information: Mechanism Design in the Field | AER 2022 | 89 | open: working paper, 12 of 48 paired values exact ([link](https://www.povertyactionlab.org/sites/default/files/research-paper/3674_Rigol_Targeting_Jan2020.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T84 | Technological Change and the Consequences of Job Loss | AER 2023 | 13 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T85 | The Common-Probability Auction Puzzle | AER 2023 | 21 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T91 | The Labor Market Impacts of Universal and Permanent Cash Transfers: Evidence from the Alaska Permanent Fund | AEJ: Economic Policy 2022 | 32 | open: working paper, 4 of 4 paired values exact ([link](https://www.nber.org/system/files/working_papers/w24312/w24312.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T93 | The Long-Term Effects of Measles Vaccination on Earnings and Employment | AEJ: Economic Policy 2022 | 216 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T98 | The Relative Efficiency of Skilled Labor across Countries: Measurement and Interpretation | AER 2022 | 30 | unreadable (HTTP -1) ([link](https://wrap.warwick.ac.uk/159013/1/WRAP-Relative-efficiency-skilled-labor-across-countries-measurement-interpretation-2021.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T99 | The Side Effects of Immunity: Malaria and African Slavery in the United States | AEJ: Applied Economics 2022 | 27 | unreadable (HTTP -1) ([link](https://iris.unito.it/bitstream/2318/1874479/1/esposito_aejapp_slavery_acceptedversion.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T102 | Vulnerability and Clientelism | AER 2022 | 78 | unreadable (HTTP 403) ([link](https://escholarship.org/content/qt4n28d9c1/qt4n28d9c1.pdf)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T103 | Wage Cyclicality and Labor Market Sorting | AER: Insights 2022 | 10 | no open copy found / not checked | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |
| T106 | When a Doctor Falls from the Sky: The Impact of Easing Doctor Supply Constraints on Mortality | AER 2023 | 76 | unreadable (HTTP 200) ([link](https://pmc.ncbi.nlm.nih.gov/articles/PMC13193249/pdf/)) | none (Dataverse hits are other papers or harvested openICPSR records; Zenodo/OSF/GitHub hits unrelated) | **excluded: no data deposit outside openICPSR** |

**T73 Dhar, Jain & Jayachandran, *Reshaping Adolescents' Gender Attitudes*
(AER 2022).** The 3ie Impact Evaluation Dataverse holds the authors' package
for the 3ie final report on the same experiment (deposited 2019-07-25,
27.5 MB, open, Stata do-files plus ready-for-analysis data). The NBER
working paper w25331 (2018) matches 53 of 69 distinct paired values at the
database precision. Both predate the AER version, so curation must verify,
table by table, that the 3ie data reproduce the published values the I4R
rows record (220 paired rows, so the check is well powered) and pin only
claims that do. If they do, this package also carries code, so the entry
would run in all three modes under the ordinary rules; R8 would not be
needed for it.

**T19 Allcott, Gentzkow & Song, *Digital Addiction* (AER 2022).** Data on
Harvard Dataverse GN636M (30.4 MB, no code, non-redistribution licence),
but the only open text is the NBER working paper w28936, which matches 2 of
7 paired values; the published text is closed. Excluded on text.

**Everything else.** No analysis-data deposit outside openICPSR was found
for the other 34 reports. Several have open working papers that match the
published values well (T37 113 of 116, T9 49 of 71, T48 45 of 60, T53 34 of
45, T23 21 of 30), which would matter if their data ever appear outside
openICPSR.

## What adopting R8 would take

- A per-entry way to mark seeded mode not applicable (a schema field, a
  `seeded_not_applicable` skip reason in the runner, `tables.py` rows for
  two-mode papers kept out of seeded totals).
- With one candidate, and that one possibly admissible under the existing
  rules, R8 is not worth building yet. Revisit if more data-only deposits
  turn up.

**Total checked today: 36 reports.** One R8 candidate (T73, 220 paired
rows), one data-only deposit that fails on text (T19), 34 with no deposit
outside openICPSR.
