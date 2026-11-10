# Evidence report: ambuehl-2022-deliberative-competence-financial-choice

**Evaluating Deliberative Competence: A Simple Method with an Application to Financial Choice** — Sandro Ambuehl, B. Douglas Bernheim, Annamaria Lusardi

- Paper: https://www.nber.org/system/files/working_papers/w20618/w20618.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/289580/1/I4R-DP110.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/ambuehl-2022-deliberative-competence-financial-choice.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T28/171681-V1.zip`; AEA Data and Code Repository on openICPSR, project 171681, version V1 (doi:10.3886/E171681V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T28/171681-V1.zip (1,127,520 bytes, md5 6d0692362cd22dc693edb160c538fee8; SOURCE.txt beside it).  V1 is the only version.  21 entries (16 files, 5 directories), 27.8 MB uncompressed, all deflate, no nested archives.  readMe.pdf (3 pp., titled "REPLICATION PACKAGE V2 ReadMe", dated 2022-08-17; data availability, Stata 16, the do-files, a dataset list and a table-to-line-number map; no estimates).  data/raw/: the raw Qualtrics exports, expAbatch1-8.csv (Experiment A, eight sessions, 668-669 columns) and expBbatch1-2.csv (Experiment B, two sessions, 779 columns, 21 MB together); no .dta ships (the README lists the CSVs under data/, they sit in data/raw/).  doFiles/: master.do, setup.do (ssc install outreg2, distplot), dataManagementExpA.do, dataManagementExpB.do and analysis.do.  graphs/ and tables/ are empty directories; no logs, tables or figures ship.  The script-free copy (independent / blind) withholds the 5 do-files by suffix (benchmark.strip_rule.classify_tree on the extracted package, 2026-11-09); the 10 CSVs and readMe.pdf stay, none printing a pinned value.  Project page: https://www.openicpsr.org/openicpsr/project/171681/version/V1/view)

> Headline findings: the Treatment raises compound-interest test scores by 1.442 (0.194) correct answers in Experiment A and 1.601 (0.143) in Experiment B (Table 4 cols 1-2), and lowers scores on the control module by -1.058 (0.146) and -0.374 (0.141) (cols 3-4); N 215 (A) and 348 (B).  Deliberative competence (Table 7, both delays): Experiment A Control -24.448 (1.633), Treatment -22.864 (1.741), Substance-Only -22.012 (1.433), Rhetoric-Only -19.797 (1.406), N 4,550; Experiment B Control -25.673 (1.357), Treatment -18.569 (1.177), i.e. a 7.1-point gain only with practice and feedback.
> Paper text and how it was verified.  The published AER article could not be read (paywalled; the ZORA open-access copy is behind an Anubis bot-protection challenge, CEPR DP15863 behind Cloudflare; neither was circumvented).  The catalog source is NBER WP 20618, revised March 2022. Its Table 4 equals the published Table 4 in every cell checked: the four Difference coefficients and SEs equal the meta-database's o_coeff_dbl / o_std_err_dbl for "table 4" (1.442/0.194, 1.601/0.143, -1.058/0.146, -0.374/0.141), and every Control / Treatment / Difference cell and both Observations cells equal DP110 Table 1's "Original" columns, which reproduce the published table.  Its Table 7 equals DP110 Table 4 ("precisely replicate the results as reported in the paper") in every level, SE, p-value, Observations and Subjects cell of all six columns, and the twelve meta-database "table 7" values (no SEs) are the Treatment / Substance-Only / Rhetoric-Only minus Control differences of those levels in columns 1-6 (1.584, 7.104, 2.436, 4.651, 1.117, 7.504, 2.819, 3.885, 2.051, 6.704, 2.053, 5.417), all exact.  The WP thanks the editor (Stefano DellaVigna) and referees; its table numbering matches the package README's map of published Tables 4-11.  The published abstract is reworded relative to the WP's.  Contexts use the WP's wording.  The WP prints Table 4's SEs only as "Standard errors in parentheses"; DP110 (fn. 1) notes the code clusters by subject, which with one observation per subject equals heteroskedasticity-robust SEs.
> Curation pass (2026-11-09).  13 claims.  Left out: Table 4's Control and Treatment level rows, Table 7 columns 3-6 (36- and 72-day delays separately) and its p-value rows, Table 5 (valuations in the complex frame; not covered by the meta-database or DP110, so unverified), Table 6 (rhetoric vs substance), Tables 9-11 (simple-frame valuations, corrected and quartile versions of Table 7) and all appendix tables.
> Package-only facts (never in contexts).  dataManagementExpA.do insheets the eight expAbatch CSVs (drop if id == 1 in each, drop if help_test missing), builds each price list's switch point, flags multi-switching (multi), and collapses to subject-by-task valuations; dataManagementExpB.do does the same for Experiment B. analysis.do builds discount_unframed = v_unframed/amount*100 and discount_framed = v_framed/amount_precise*100 (the complex-frame valuation over the exact compounded amount, "our analysis controls for these differences" in the paper), absDiff = |framed - unframed|, keeps multi == 0.  Table 4: reg score_compounding / score_indexing Full if tag == 1 & (Full|Control) & sample == "old" (A) or (fullNew|contNew) & sample == "new" (B), cl(id).  Table 7: negAbsDiff = -absDiff; reg negAbsDiff Control Full Rule72 Rhetoric if sample == "old", nocons cl(id) (Rule72 is the Substance-Only arm); reg negAbsDiff Control Full if sample == "new", nocons cl(id); cols 3-6 add delay == 72 / 36.  The package's sqDiff is still abs(framed^2 - unframed^2)/100, the coding error DP110 reports (appendix-only).  The README says Stata 16, under 10 minutes; master.do's cd points at the authors' Dropbox ("AER 2/Round 3/REPLICATION PACKAGE V2").
> Blind-mode exposure (step 6, 2026-11-09).  The blind generation prompt states no pinned value or SE, as printed or rounded to 3 significant figures; its 1-2 figure matches are column names (switch19, T20) and file sizes (1.4 MB, 200 KB).  It carries no script text.  The methodology summariser and hyperparameter extractor get the full paper text, as for every entry, and the paper prints Table 4 and Table 7 and rounded forms of some targets in prose ("-24.4%", "-25.7%", "-18.6%", "1.4 additional correct answers", "differences of 1.06 and 0.37 questions"); the README's blind-mode caveat covers this.  The paper parser takes the WP cover line "EVALUATING DELIBERATIVE COMPETENCE:" as the title.
> What was read.  NBER WP 20618 (March 2022 revision) Sections 1-2 and Tables 1-7 in full; DP110 in full; the 51 meta-database rows; readMe.pdf; master.do, setup.do, the Table 4 and Table 7 blocks of analysis.do and the multiple-switching parts of dataManagementExpA.do; the strip-rule classification of the extracted package.
> What could not be verified.  The published article itself (pages, table notes, final wording) was not read.  Table 4's Control / Treatment level rows and Table 7's SEs are checked against DP110's recomputation (which the DP states equals the published paper), not against the published page.  The authors' Stata code was not run (no Stata here) and no independent R cross-check was made in this pass.
> Original analysis in Stata 16 (outreg2, distplot); language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `test_score_compounding_treatment_minus_control_expA_table4_col1` | 1.442 | 0.194 | Table 4, column (1) Test score compounding, Experiment A, Difference | 1.442 | matches |
| 1 | `test_score_compounding_treatment_minus_control_expB_table4_col2` | 1.601 | 0.143 | Table 4, column (2) Test score compounding, Experiment B, Difference | 1.601 | matches |
| 2 | `test_score_control_module_treatment_minus_control_expA_table4_col3` | -1.058 | 0.146 | Table 4, column (3) Test score control module, Experiment A, Difference | -1.058 | matches |
| 3 | `test_score_control_module_treatment_minus_control_expB_table4_col4` | -0.374 | 0.141 | Table 4, column (4) Test score control module, Experiment B, Difference | -0.374 | matches |
| 4 | `n_obs_table4_expA_cols1_3` | 215 | — | Table 4, Observations, columns (1) and (3), Experiment A | 215 | matches |
| 5 | `n_obs_table4_expB_cols2_4` | 348 | — | Table 4, Observations, columns (2) and (4), Experiment B | 348 | matches |
| 6 | `deliberative_competence_control_expA_table7_col1` | -24.448 | 1.633 | Table 7, column (1) both delays, Experiment A, Levels, Control | -24.448 | matches |
| 7 | `deliberative_competence_treatment_expA_table7_col1` | -22.864 | 1.741 | Table 7, column (1) both delays, Experiment A, Levels, Treatment | -22.864 | matches |
| 8 | `deliberative_competence_substance_only_expA_table7_col1` | -22.012 | 1.433 | Table 7, column (1) both delays, Experiment A, Levels, Substance-Only | -22.012 | matches |
| 9 | `deliberative_competence_rhetoric_only_expA_table7_col1` | -19.797 | 1.406 | Table 7, column (1) both delays, Experiment A, Levels, Rhetoric-Only | -19.797 | matches |
| 10 | `deliberative_competence_control_expB_table7_col2` | -25.673 | 1.357 | Table 7, column (2) both delays, Experiment B, Levels, Control | -25.673 | matches |
| 11 | `deliberative_competence_treatment_expB_table7_col2` | -18.569 | 1.177 | Table 7, column (2) both delays, Experiment B, Levels, Treatment | -18.569 | matches |
| 12 | `n_obs_table7_expA_col1` | 4550 | — | Table 7, Observations, column (1) Experiment A | 4550 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [12/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[13/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[13/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [12/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[12/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [13/13](seeded/pipeline-desktop-opus/20261110T065041Z/CELL.md) (20261110T065041Z) | [0/13](independent/pipeline-desktop-opus/20261110T070354Z/CELL.md) (20261110T070354Z) | [0/13](blind/pipeline-desktop-opus/20261110T064710Z/CELL.md) (20261110T064710Z) |
| `pipeline-desktop-opus-run2` | [13/13](seeded/pipeline-desktop-opus-run2/20261110T112703Z/CELL.md) (20261110T112703Z) | [2/13](independent/pipeline-desktop-opus-run2/20261110T143511Z/CELL.md) (20261110T143511Z) | [0/13](blind/pipeline-desktop-opus-run2/20261110T070206Z/CELL.md) (20261110T070206Z) |
| `pipeline-desktop-opus-run3` | [13/13](seeded/pipeline-desktop-opus-run3/20261110T112717Z/CELL.md) (20261110T112717Z) | [0/13](independent/pipeline-desktop-opus-run3/20261110T142318Z/CELL.md) (20261110T142318Z) | [0/13](blind/pipeline-desktop-opus-run3/20261110T070218Z/CELL.md) (20261110T070218Z) |
| `pipeline-desktop-opus-run4` | — | [0/13](independent/pipeline-desktop-opus-run4/20261110T142335Z/CELL.md) (20261110T142335Z) | [0/13](blind/pipeline-desktop-opus-run4/20261110T065905Z/CELL.md) (20261110T065905Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.4505 | -18.569 | ±1.177 (se_band) | 0.950 | PASS |
| [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.3066 | -18.569 | ±1.177 (se_band) | 1.073 | FAIL |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.3066 | -18.569 | ±1.177 (se_band) | 1.073 | FAIL |
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.3066 | -18.569 | ±1.177 (se_band) | 1.073 | FAIL |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.303 | -18.569 | ±1.177 (se_band) | 1.076 | FAIL |
| [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.2848 | -18.569 | ±1.177 (se_band) | 1.091 | FAIL |
| [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.5337 | -18.569 | ±1.177 (se_band) | 0.880 | PASS |
| [independent/pipeline-desktop-opus-run2/20261110T143511Z](independent/pipeline-desktop-opus-run2/20261110T143511Z/CELL.md) | `test_score_compounding_treatment_minus_control_expB_table4_col2` | 1.72664 | 1.601 | ±0.143 (se_band) | 0.879 | PASS |
| [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) | `deliberative_competence_treatment_expB_table7_col2` | -17.6356 | -18.569 | ±1.177 (se_band) | 0.793 | PASS |
| [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) | `deliberative_competence_rhetoric_only_expA_table7_col1` | -18.7138 | -19.797 | ±1.406 (se_band) | 0.770 | PASS |

### Declared deviations

- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (12/13; failed: `deliberative_competence_treatment_expB_table7_col2`)
  - Analysis data rebuilt from the raw Qualtrics CSVs. Exp A conditions are identified from the batch (batches 1,2,4,5 = Treatment/Control; 3,6,7,8 = Substance-Only/Rhetoric-Only) and from which video-check question was answered. Substance-Only vs Rhetoric-Only was assigned using the compound-interest test results (only one arm covers the rule of 72).
  - Multiple switchers are defined as subjects with any non-monotone choice (future reward chosen at a higher immediate amount and immediate amount chosen at a lower one) in any of the 40 price lists. This excludes 53 of 504 in Exp A (paper: 49) and 54 of 401 in Exp B (paper: 53), so N = 214 / 347 / 4510, against 215 / 348 / 4550 in the paper.
  - Exp B: one Qualtrics survey-preview row (Status == 1, a test worker ID) was dropped, leaving 401 completers. A worker ID that appears twice in Exp B (one unfinished Control row at 97% progress and one finished Treatment row) was kept twice.
  - Valuation = midpoint of the $0.20 interval from the iterated price list (2*s - 0.2*n2 - 0.1). It is normalized by the Table 2 reward R (rule-of-72 amount) for both frames. Normalizing by the exact compounded amounts was tried in diagnostics but not adopted.
  - Test answer keys were inferred from the question texts (no answer keys in the data). Compound questions: test1=2, test2=4, test3=4, test4=7, test5=6. Exp A control-module questions: 3,4,2,3,3. Exp B control-module questions: 4,5,5,5,1.
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `deliberative_competence_treatment_expB_table7_col2`)
  - Multiple switching is operationalised as any non-monotone choice pattern (a later line returning to the immediate option) in either price list of any of the 20 tasks. This flags 53 of 504 (A) and 54 of 401 (B) completers versus the 49 and 53 the paper reports, so the samples are 451 (A; Control 108, Treatment 106, Substance-Only 126, Rhetoric-Only 111) and 347 (B; Control 179, Treatment 168) instead of 455 and 348. The literal reading (two or more choice changes within one list) flags only 28/29 subjects, so I used the reading closest to the reported counts.
  - Valuation = midpoint of the switching interval of the iterated price list: x + 0.2*(# future choices in list 2) - 0.1, where x = 2*(# future choices in list 1) - 2 (as in the Qualtrics piping). It is normalised by the nominal future reward R from Table 2, with no capping. Subjects who switch inconsistently across the two lists (list 2 all immediate) get x - 0.1.
  - Experiment A conditions are not coded in the data beyond a 0/1 'treatment' flag. Batches 1, 2, 4 and 5 are Treatment vs Control (attention-check words 'compounding' / 'funds'). Batches 3, 6, 7 and 8 are the dissected videos: treatment==1 is Substance-Only and treatment==0 is Rhetoric-Only, assigned from the attention-check wording and the test-score pattern described in Section 2.4.
  - Answer keys: Experiment A key (2,4,4,7,6 \| 3,4,2,3,3) reproduces Qualtrics' own score variable exactly. Experiment B compound-interest key is the same; the B control-module key (4,5,5,5,1) comes from the question content in Table C.2 (for the Coca-Cola/Pepsi item, 0.7 = option 5 was chosen).
  - multiple switching operationalised as any non-monotone choice pattern (a later line returning to the immediate option) within either list of any of the 20 tasks; this flags 53 of 504 (A) and 54 of 401 (B) subjects vs. 49 and 53 reported, so samples are 451 (A) and 347 (B) instead of 455 and 348.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (13/13)
  - The paper does not spell out its exact multiple-switching rule. We count as multiple switchers subjects with >=2 switches in any list or a wrong-way (future-to-immediate) switch. Single wrong-way switches confined to the top line of list 1 are not counted. In Experiment A, single wrong-way switches confined to the bottom ($0) line are not counted either. This rule reproduces the paper's reported counts (49 of 504 in A, 53 of 401 in B) and its sample sizes (455 and 215 subjects in A, 348 in B). The literal '>=2 switches' rule would exclude only 28 and 29 subjects.
  - The answer keys for the exam-style questions were derived from the question content: compound interest codes 2,4,4,7,6; Experiment A control codes 3,4,2,3,3; Experiment B control codes 4,5,5,5,1. They were not given in the data.
  - The Experiment A conditions were identified from the session and video code words. Sessions 1, 2, 4 and 5 ran Treatment vs Control. In sessions 3 and 6-8, treatment==1 is Substance-Only, identified by its high rule-of-72 Q1 score, and treatment==0 is Rhetoric-Only.
  - Valuations use the midpoint of the interval from the iterated price list: 2*switch - 2.1 + 0.2*(# future choices in list 2). They are normalized by the nominal future reward R from Table 2 and are not clipped at zero.
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (13/13)
  - Multiple-switching rule reconstructed from the paper: a subject is excluded if any first or second price list has a future-reward choice followed by an immediate-payment choice; second lists that follow an all-future first list (x = $20) are not checked. This rule reproduces the paper's analysis samples of 215 (Exp. A Treatment+Control) and 348 (Exp. B), but flags 51 rather than 49 Exp. A subjects, so Exp. A has 453 subjects (4,530 observations) in Table 7 instead of 455 (4,550). The 2 extra are in the Substance-Only/Rhetoric-Only sessions.
  - Exp. A conditions are not coded in the data (treatment is 0/1 only). Sessions 1, 2, 4 and 5 ran Treatment vs Control (Control video = index funds, as shown by the video-check answers). Sessions 3, 6, 7 and 8 ran the two compound-interest variants; the arm with the higher compounding test score is labeled Substance-Only, as the paper describes.
  - Answer keys were derived from the question content: compounding questions 7.2 years, 18%, 20 years, 36%, $250. Exp. A control module: Franklin = 'money makes money', 90%, Sinclair = 'salary' quote, 50-70%, index fund = market portfolio. Exp. B control module: GM & Microsoft, 0.7, stocks, stocks, +1. The Qualtrics score fields (SC0) do not match any 10-item key and were not used.
  - Valuation = midpoint of the $0.20 interval in the second list (2s - 2.1 + 0.2k, where s and k count future-reward choices in lists 1 and 2); s = 0 is coded as 0. The simple frame is normalized by the reward R. The complex frame is normalized by the exact daily-compounded payoff a(1+X)^t (the paper says the analysis 'controls for' the rule-of-72 approximation). Deliberative competence = -\|r_c - r_s\| in percentage points, one observation per subject x task pair.
  - Table 4 uses plain OLS of the score on a Treatment dummy, with one observation per subject. Table 7 uses OLS without a constant on condition dummies (fixest), with SEs clustered by subject.
- [independent/pipeline-desktop-opus-run2/20261110T143511Z](independent/pipeline-desktop-opus-run2/20261110T143511Z/CELL.md) (2/13; failed: `test_score_compounding_treatment_minus_control_expA_table4_col1`, `test_score_control_module_treatment_minus_control_expA_table4_col3`, `n_obs_table4_expA_cols1_3`, `n_obs_table4_expB_cols2_4`, `deliberative_competence_control_expA_table7_col1`, `deliberative_competence_treatment_expA_table7_col1`, `deliberative_competence_substance_only_expA_table7_col1`, `deliberative_competence_rhetoric_only_expA_table7_col1`, `deliberative_competence_control_expB_table7_col2`, `deliberative_competence_treatment_expB_table7_col2`, `n_obs_table7_expA_col1`)
  - Experiment A: subjects with a 'code treat' entry are the Substance-Only/Rhetoric-Only arms (split by code word interest/compounding); others are Control (treatment=0) / Treatment (treatment=1)
  - valuations reconstructed from raw iMPL choices: coarse list step = 10% of R, refining list step = 1% of R, interval midpoint (a constant offset that cancels in r^c - r^s)
- [independent/pipeline-desktop-opus-run3/20261110T142318Z](independent/pipeline-desktop-opus-run3/20261110T142318Z/CELL.md) (0/13; failed: `test_score_compounding_treatment_minus_control_expA_table4_col1`, `test_score_compounding_treatment_minus_control_expB_table4_col2`, `test_score_control_module_treatment_minus_control_expA_table4_col3`, `test_score_control_module_treatment_minus_control_expB_table4_col4`, `n_obs_table4_expA_cols1_3`, `n_obs_table4_expB_cols2_4`, `deliberative_competence_control_expA_table7_col1`, `deliberative_competence_treatment_expA_table7_col1`, `deliberative_competence_substance_only_expA_table7_col1`, `deliberative_competence_rhetoric_only_expA_table7_col1`, `deliberative_competence_control_expB_table7_col2`, `deliberative_competence_treatment_expB_table7_col2`, `n_obs_table7_expA_col1`)
  - Exp A multiple-switch flag inferred from switch columns (switch partial NA) since no explicit indicator found
  - Exp A multiple-switch flag inferred from switch columns (switch partial NA) since no explicit indicator found
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (12/13; failed: `deliberative_competence_treatment_expB_table7_col2`)
  - Exp A condition labels are not stored in the data (the 'treatment' field is 0/1 in every batch). Batches 1,2,4,5 were coded Treatment(1)/Control(0) and batches 3,6,7,8 SubstanceOnly(1)/RhetoricOnly(0), based on the video attention-check words, video durations and the rule-of-72 self-report (the Rhetoric-Only video omits the rule of 72; its viewers mostly report not knowing it).
  - Multiple switching: a subject is excluded if any first price list is non-monotone (more than one switch, or a right-to-left switch), or any second price list is non-monotone when the first list had an interior switch (second lists after an all-left or all-right first list have amounts outside $0-$20 and are disregarded for this check). This gives 53 of 401 in Exp B (paper: 53) and 51 of 504 in Exp A (paper: 49), so the Exp A Substance/Rhetoric arms hold 2 more excluded subjects than the paper's sample (Table 7 col 1 N = 4530, not 455 subjects x 10).
  - Valuation = midpoint of the $0.20 interval: (2*s - 2) + 0.2*(# future choices in list 2) - 0.1, where s = # future choices in list 1; applied mechanically also when s = 0 or 11 (giving values just below $0 or above $20).
  - Normalization uses the nominal future reward R of Table 2 (20/18/16/14/12) for both frames; complex tasks matched to their simple twin by (R, delay).
  - Exp B control-module answer key built from content (GM & Microsoft; 0.7; stocks; stocks; 1) because the Qualtrics score field in Exp B uses the Exp A control key; compounding and Exp A control keys match the Qualtrics score field. An unanswered question counts as wrong.
  - One worker appears twice in Exp B; only the first participation is kept (401 completed, as in the paper). The Exp A duplicate is a multiple switcher both times and is excluded.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (13/13)
  - Multiple-switching rule: the paper reports 49/504 (A) and 53/401 (B) multiple switchers but does not give the exact rule. Several rules were checked (per-list >=2 switches: 28/30; any non-monotone list: 53/55; iterated list 1 + list 2 merged into one price list ordered by amount with >=2 switches: 51/51). The merged-list rule was used. It keeps 453 (A) + 350 (B) = 803 subjects, which matches the paper's stated total of 803, but the per-experiment split differs from 455/348 by 2 subjects.
  - Experiment A conditions are not coded directly in the data (the treatment field is 0/1). Sessions 1, 2, 4 and 5 ran the full Treatment against Control; sessions 3, 6, 7 and 8 ran Substance-Only (treatment path) against Rhetoric-Only (other path). This was inferred from the minimum video page times (~665 s, ~620 s, ~265 s and ~505 s), the slide code words, and correctness on Q1 and Q2 by group.
  - Test answer keys: the compound-interest key and the Experiment A control-module key reproduce the Qualtrics Score field exactly (R^2 = 1). Experiment B's Qualtrics score uses Experiment A's control-module key, which does not fit B's diversification questions, so the B control-module answers were scored from Table C.2 content (options in display order: GM & Microsoft, 0.7, stocks, stocks, 1).
  - Experiment B: one worker ID appears twice. The earlier record, which is unfinished (Progress 97), was dropped, giving the 401 completers. 'Completed' means the subject answered the final test.
  - Valuation = midpoint of the $0.20 interval implied by the iterated MPL: 2*switch - 0.1 - 0.2*(number of immediate choices in list 2), with x = 2*switch - 2 as displayed. It is normalized by the rule-of-72 future reward R from Table 2 and is not clipped. Table 4 uses iid OLS standard errors; Table 7 clusters by subject.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (12/13; failed: `deliberative_competence_treatment_expB_table7_col2`)
  - Multiple switching defined as any price list (first or second list of the iterated MPL) with two or more switches or any switch from the future reward back to the immediate amount; this flags 53/504 subjects in Experiment A and 54/401 in Experiment B, versus 49 and 53 stated in the paper text, so the analysis samples are slightly smaller (A 451 vs 455 subjects; B 347 vs 348). No tested variant reproduced both stated counts; the strict definition from the experimental instructions was kept.
  - Valuation = midpoint of the iterated-MPL interval, computed as 2*(future choices in list 1) - 2 + 0.2*(future choices in list 2) - 0.1; lists where the subject took the future reward on every line (top-coded) get x+1.9 and lists with all-immediate choices in list 1 get -0.1, without further censoring adjustments.
  - Experiment A arm coding inferred from the raw files: batches 1,2,4,5 randomize Treatment (treatment=1) vs Control; batches 3,6,7 randomize Substance-Only (treatment=1; subjects overwhelmingly report knowing the rule of 72) vs Rhetoric-Only (treatment=0); batch 8 contains Rhetoric-Only only (same video slot).
  - Test answer key: compound questions 7.2 yrs, 18% (rule of 72), about 20 yrs, 36%, $250; Experiment A control key (Franklin 'money makes money', 90%, Sinclair quote, 50-70%, market portfolio) reproduces Qualtrics' own Score-sum for all 504 A subjects; Experiment B control key (GM & Microsoft, 0.7, stocks, stocks, 1) chosen from content, as B's Qualtrics score does not match a full key.
  - Table 4 SEs clustered by subject (one obs per subject, i.e. heteroskedasticity-robust).
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (12/13; failed: `deliberative_competence_treatment_expB_table7_col2`)
  - Multiple switching is defined as any monotonicity violation (a switch back from the future reward to the immediate payment) in either the first or the second list of any of the 20 iterated price lists. This flags 53 of 504 rows in A and 55 of 401 in B; the paper reports 49 and 53, so the retained samples (A 451, B 346) are slightly smaller than the paper's 455 and 348. No alternative definition I tried (counting switches, combined fine-grid list, ignoring line 1, and others) matched both counts.
  - Experiment A conditions are not coded in the data: treatment is 0/1 within batches. Batches 1, 2, 4 and 5 were taken as Treatment vs. Control (index-fund attention code 'funds'); batches 3, 6, 7 and 8 as Substance-Only (treatment==1, the shorter video, with high Q1 rule-of-72 accuracy) vs. Rhetoric-Only (treatment==0). This was inferred from attention-check answers, video timers and Q1 accuracy.
  - Exam answer key: the compound-interest key (test1-5 = 2,4,4,7,6) and the Exp A control key (test6-10 = 3,4,2,3,3) were inferred from Qualtrics' Score-sum (exact fit, R2=1). The Qualtrics score in Exp B applies the Exp A key to B's different control questions, so for B's diversification questions I used content-based answers in display order from Table C.2: GM & Microsoft, 0.7, stocks, stocks, 1 (codes 4,5,5,5,1).
  - Valuations are interval midpoints: 2*n1 - 0.1 - 0.2*m2, where n1 is the number of future choices in list 1 and m2 the number of immediate choices in list 2. They are normalized by the paired simple reward R (Table 2), and the edge cases (n1=0 or 11) are not truncated.
  - Exp B has one worker id among 402 completers twice; the first participation is kept (401 subjects). Completers are subjects with price-list data and at least 9 of the 10 test answers (A: 504 rows, including the paper's duplicate subject, whose two rows are both flagged as multiple switchers).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- independent: `deliberative_competence_control_expA_table7_col1` — pipeline 0/4, agent 4/4
- independent: `deliberative_competence_control_expB_table7_col2` — pipeline 0/4, agent 4/4
- independent: `deliberative_competence_rhetoric_only_expA_table7_col1` — pipeline 0/4, agent 4/4
- independent: `deliberative_competence_substance_only_expA_table7_col1` — pipeline 0/4, agent 4/4
- independent: `deliberative_competence_treatment_expA_table7_col1` — pipeline 0/4, agent 4/4
- independent: `n_obs_table4_expA_cols1_3` — pipeline 0/4, agent 4/4
- independent: `n_obs_table4_expB_cols2_4` — pipeline 0/4, agent 4/4
- independent: `n_obs_table7_expA_col1` — pipeline 0/4, agent 4/4
- independent: `test_score_compounding_treatment_minus_control_expA_table4_col1` — pipeline 0/4, agent 4/4
- independent: `test_score_control_module_treatment_minus_control_expA_table4_col3` — pipeline 0/4, agent 4/4
- blind: `deliberative_competence_control_expA_table7_col1` — pipeline 0/4, agent 4/4
- blind: `deliberative_competence_control_expB_table7_col2` — pipeline 0/4, agent 4/4
- blind: `deliberative_competence_rhetoric_only_expA_table7_col1` — pipeline 0/4, agent 4/4
- blind: `deliberative_competence_substance_only_expA_table7_col1` — pipeline 0/4, agent 4/4
- blind: `deliberative_competence_treatment_expA_table7_col1` — pipeline 0/4, agent 4/4
- blind: `n_obs_table4_expA_cols1_3` — pipeline 0/4, agent 4/4
- blind: `n_obs_table4_expB_cols2_4` — pipeline 0/4, agent 4/4
- blind: `n_obs_table7_expA_col1` — pipeline 0/4, agent 4/4
- blind: `test_score_compounding_treatment_minus_control_expA_table4_col1` — pipeline 0/4, agent 4/4
- blind: `test_score_compounding_treatment_minus_control_expB_table4_col2` — pipeline 0/4, agent 4/4
- blind: `test_score_control_module_treatment_minus_control_expA_table4_col3` — pipeline 0/4, agent 4/4
- blind: `test_score_control_module_treatment_minus_control_expB_table4_col4` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- independent: `deliberative_competence_treatment_expB_table7_col2` — pipeline 0/4, agent 2/4
- independent: `test_score_compounding_treatment_minus_control_expB_table4_col2` — pipeline 1/4, agent 4/4
- independent: `test_score_control_module_treatment_minus_control_expB_table4_col4` — pipeline 1/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 3; 2026-11-10T06:52:30Z; from `claude-code-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T06:53:00Z; from `claude-code-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T065041Z

[`seeded/pipeline-desktop-opus/20261110T065041Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T065041Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T06:50:41Z; from `pipeline-oracle-desktop-opus-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T112703Z

[`seeded/pipeline-desktop-opus-run2/20261110T112703Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T112703Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T11:27:03Z; from `pipeline-oracle-desktop-opus-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T112717Z

[`seeded/pipeline-desktop-opus-run3/20261110T112717Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T112717Z/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 1; 2026-11-10T11:27:17Z; from `pipeline-oracle-desktop-opus-run3-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 16; 2026-11-10T07:20:00Z; from `claude-code-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 11; 2026-11-10T07:05:00Z; from `claude-code-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 8; 2026-11-10T11:23:00Z; from `claude-code-run3-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 9; 2026-11-10T11:23:00Z; from `claude-code-run4-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T070354Z

[`independent/pipeline-desktop-opus/20261110T070354Z/CELL.md`](independent/pipeline-desktop-opus/20261110T070354Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 4; 2026-11-10T07:03:54Z; from `pipeline-oracle-desktop-opus-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T143511Z

[`independent/pipeline-desktop-opus-run2/20261110T143511Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T143511Z/CELL.md) — final 2/13, re-scored 2/13; first scored 1/13; executions 5; 2026-11-10T14:35:11Z; from `pipeline-oracle-desktop-opus-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T142318Z

[`independent/pipeline-desktop-opus-run3/20261110T142318Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T142318Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 4; 2026-11-10T14:23:18Z; from `pipeline-oracle-desktop-opus-run3-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T142335Z

[`independent/pipeline-desktop-opus-run4/20261110T142335Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T142335Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 4; 2026-11-10T14:23:35Z; from `pipeline-oracle-desktop-opus-run4-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 7; 2026-11-10T06:58:30Z; from `claude-code-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 7; 2026-11-10T11:23:30Z; from `claude-code-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 5; 2026-11-10T07:05:00Z; from `claude-code-run3-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 8; 2026-11-10T11:25:00Z; from `claude-code-run4-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T064710Z

[`blind/pipeline-desktop-opus/20261110T064710Z/CELL.md`](blind/pipeline-desktop-opus/20261110T064710Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 2; 2026-11-10T06:47:10Z; from `pipeline-oracle-desktop-opus-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T070206Z

[`blind/pipeline-desktop-opus-run2/20261110T070206Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T070206Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 1; 2026-11-10T07:02:06Z; from `pipeline-oracle-desktop-opus-run2-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T070218Z

[`blind/pipeline-desktop-opus-run3/20261110T070218Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T070218Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 1; 2026-11-10T07:02:18Z; from `pipeline-oracle-desktop-opus-run3-1paper-ambuehl-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T065905Z

[`blind/pipeline-desktop-opus-run4/20261110T065905Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T065905Z/CELL.md) — final 0/13, re-scored 0/13; first scored 0/13; executions 1; 2026-11-10T06:59:05Z; from `pipeline-oracle-desktop-opus-run4-1paper-ambuehl-indep-blind-2026-11-10.json`; evidence complete.

