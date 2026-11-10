# Evidence report: balan-2022-local-elites-state-capacity

**Local Elites as State Capacity: How City Chiefs Use Local Information to Increase Tax Compliance in the Democratic Republic of the Congo** — Pablo Balán, Augustin Bergeron, Gabriel Tourek, Jonathan L. Weigel

- Paper: https://jonathanweigel.com/s/balan-et-al_chieftaxation_aer_2022.pdf
- I4R report: https://github.com/I4Replication/I4R-First-Meta-Paper
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/balan-2022-local-elites-state-capacity.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T48/147561-V3.zip`; AEA Data and Code Repository on openICPSR, project 147561, version V3 (doi:10.3886/E147561V3); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T48/147561-V3.zip (46,038,471 bytes, md5 4a061afd880035d6f914a1bbeaec8cb5; SOURCE.txt beside it).  Versions: V1 (registered 2022-02-24, the one I4R team 48 used in 2023), V2 (2024-11-14) and V3 (2025-10-29).  The package's CHANGES.txt: "V2: Removed extraneous variables, leaves our results and correspondence with the paper unchanged" and "V3: Removed additional variables containing potential PII that were mistakenly included. Results and correspondence with paper remain unchanged."  V3 is the only version on disk; V1 and V2 were not compared, so the authors' statement that no result changed is unverified here.  Top folder "Replication Materials - Updated October 2025"; 116 zip entries (105 files), 532 MB uncompressed, no nested archives.  Contents: README.pdf (14 pp., October 21, 2021; data list, software, run order, exhibit-to-program map with line numbers, no estimates); CHANGES.txt; output.tex (the LaTeX wrapper that \input's the generated tables, which are not shipped; it carries the main and appendix table captions and notes, no estimates, but its appendix-table notes state the Local-versus- Central cluster count, which is why that count is not pinned); Documents/ with three PNG illustrations (tax flier, neighborhood polygons, strata map), property_registration_path.pdf (an ArcMap map) and the paper's bibliography (.bbl); Data/01_base/admin_data/ with Stata .dta (registration_noPII 85 MB, taxroll_noPII, tax_payments_noPII, tax_payment_timing_noPII, fliers_campaign 40 MB, randomization_assignment, randomization_schedule, stratum, hh_distances, chief/collector rosters and others), three fliers_pilot_set*.xlsx mail-merge sheets and three .csv (property_values_MLestimates 24 MB, adjacent_neighborhoods, concessions_chefferies); Data/01_base/survey_data/ with the household baseline, midline (193 MB), endline round 1 and 2 and 2016-campaign endline surveys, chief and collector surveys as .dta and resident_info_quiz.csv; Data/02_intermediate and Data/03_clean_combined are EMPTY (the analysis files are built by the cleaning do-file); Dofiles/ with 0_Master.do, 1_Package_Setup.do, 2_Data_Construction.do (45 KB), 3_Main / 4_Appendix drivers, 53 per-exhibit do-files and a Stata swap file (~0_Master.do.stswp).  The script-free copy (independent / blind) withholds 58 files (benchmark.strip_rule .classify_tree on the extracted package, 2026-11-09): the 57 .do by suffix and the .stswp by content (Stata code).  Kept: README.pdf, CHANGES.txt, output.tex, the Documents/ files and all data, none of which prints a pinned value or SE.  Project page: https://www.openicpsr.org/openicpsr/project/147561/version/V3/view)

> Headline findings: chief collection (Local) raised property tax compliance relative to state collectors (Central) by 0.023 (0.008) without time fixed effects (Table 4 col 1, N 28,872, 221 clusters) and 0.032 (0.007) in the preferred specification with campaign-period fixed effects (col 2, N 27,764, 213 clusters, Central mean 0.063); 0.033 (0.007) with house fixed effects (col 4) and 0.040 (0.008) excluding exempt properties (col 5, N 23,803).  Revenues: 79.640 (22.856) CF per property (col 2, Central mean 182.236, the abstract's 44 percent) and 68.855 (20.560) with house fixed effects (col 4).  Chiefs collected more bribes at endline, 0.018 (0.009) (Table 5 Panel B, N 1,169, Central mean 0.014), made no more tax visits, -0.009 (0.026) (Table 6 col 1, N 18,162, 209 clusters).  State collectors informed by chiefs (CLI) raised compliance by 0.024 (0.009) and revenue by 46.566 (21.200) CF (Table 7 cols 1-2, N 20,636, 165 clusters).  In CLI, a one-point higher chief ease-of-payment rating goes with 0.056 (0.007) higher compliance (Table 8 Panel A col 2, N 8,135, 80 clusters).
> Paper text and how it was verified.  The source is the AEA-typeset article (page proofs, pp. 1-36) on Weigel's website.  Its Tables 4-8 were read cell by cell and each of the 129 non-empty meta-database rows was matched to the same table, row and column: every o_coeff_dbl / o_std_err_dbl equals the printed cell (Table 4 Panel B values rounded to two decimals in the database, e.g. 57.63 (25.69) for 57.627 (25.688), 81.83 (38.59) for 81.830 (38.595)), apart from these database slips: Table 5 "Assigned high band" coded 0.300 (paper 0.030, SE 0.021 agrees); Table 5 "Responsiveness of government" coded -0.490 (paper -0.049, SE 0.045 agrees); Table 7 col 2 coded 46.556 on one row (paper 46.566, the other two rows agree); Table 7 col 3 coded with SE -0.026 on two rows (paper -0.016 (0.028); -0.026 is the column 4 coefficient); and several Table 8 SEs carried at more digits on robustness rows (0.0211, 0.0125, 0.0158, 0.00929; printed 0.021, 0.012, 0.016, 0.009).  The candidates file's PDF link is a different paper (see header).  An EGAP working paper copy (December 3, 2020, 121 pp. with appendix) was also read for online Appendix A2.5 (time fixed effects); its tables were not used.
> Curation pass (2026-11-09).  13 claims (2 counts).  Left out: Table 4 column 3 (neighborhood-level collapse) and the other Panel B columns, the Table 4 cluster counts (the column 2 count is printed in output.tex's appendix-table notes, which the script-free copy keeps), Table 5's other rows (property assessments, midline bribes, government and tax views), Table 6 cols 2-4, Table 7 cols 3-6, Table 8's other cells (willingness to pay, predicted propensities in Local and Central), Table 3 balance, Table 9 (incidence) and the online appendix.
> Package-only facts (never in contexts).  2_Data_Construction.do builds Data/03_clean_combined/analysis_data.dta from the registration roll, the tax payment receipts (taxes_paid = 1 for a matched receipt at least the assigned rate), the flier mail-merge, the midline survey and the randomization assignment; taxes_paid_amt = taxes_paid * rate; tmt 1 Central, 2 Local, 3 CLI; a7 is the neighborhood (cluster) id; today_alt is the neighborhood's first tax-payment date, or its last registration date when no payment was recorded.  Table4.do: keep tmt 1-3; egen time_FE_tdm_2mo_CvL = cut(today_alt), at(21355 21415 21475 21532) (Stata dates 2018-06-20, 08-19, 10-18, 12-14); reg taxes_paid t_l i.stratum [i.house] [i.time_FE_tdm_2mo_CvL] if inlist(tmt,1,2) [& exempt!=1], cl(a7).  Table 5 endline bribe: endline_round1_noPII (tot_complete==1), bribe filled from bribe2a / bribe2b / bribe3, merged to neighborhood treatment, reg bribe_endline t_l i.stratum, cluster(a7). Table 6 uses the cut points 21355 21415 21475 21529 and visit_post_carto (0 if not visited or zero visits after registration).  Table 7: time_FE_tdm_2mo_CvCLI = cut(today_alt), at(21365.5 21425.5 21485.5 21519); reg taxes_paid / taxes_paid_amt t_cli i.house i.stratum i.time_FE_tdm_2mo_CvCLI if inlist(tmt,1,3), cl(a7).  Table 8 col 2: reg taxes_paid pay_ease i.house i.stratum if t_cli==1, cluster(a7), pay_ease from chief_consultations.dta.  The do-files use lowercase "data/" paths while the folder is "Data/" (matters on a case-sensitive file system), and 0_Master.do's stem names "Updated October 2024".
> Blind-mode exposure (step 6, 2026-11-09).  Both modes reached llm_answer_pending at the generation prompt (the methodology-summary and hyperparameter extraction prompts were answered by hand with a results-free summary and an empty list).  The blind generation prompt states no pinned value or SE at printed precision or rounded to 1-3 significant figures (the only hits are file sizes in the dataset listing, "23.1 KB", "21.0 KB") and carries no do-file text; the dataset listing names the .dta columns.  The abstract excerpt is the title and author line only.  The paper parser takes the page-1 running head ("American Economic Review 2022, 112(3): 1-36") as the title. Every context fits the generator's 600-character limit.
> What could not be verified.  The authors' Stata code was not run (no Stata here) and no independent R cross-check was made.  V1 (the version I4R used) was not compared with V3; the authors' CHANGES.txt says results are unchanged.  The CEPR first version's exact date was not read (403).
> Original analysis in Stata 14.2; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `compliance_local_table4_panelA_col1` | 0.023 | 0.008 | Table 4, Panel A (Compliance), Local, column (1) | 0.0226 | matches |
| 1 | `compliance_local_table4_panelA_col2` | 0.032 | 0.007 | Table 4, Panel A (Compliance), Local, column (2) | 0.0322 | matches |
| 2 | `compliance_local_house_fe_table4_panelA_col4` | 0.033 | 0.007 | Table 4, Panel A (Compliance), Local, column (4) | 0.0331 | matches |
| 3 | `compliance_local_exempt_excluded_table4_panelA_col5` | 0.04 | 0.008 | Table 4, Panel A (Compliance), Local, column (5) | 0.0396 | matches |
| 4 | `revenue_local_table4_panelB_col2` | 79.64 | 22.856 | Table 4, Panel B (Revenues), Local, column (2) | 79.64 | matches |
| 5 | `revenue_local_house_fe_table4_panelB_col4` | 68.855 | 20.56 | Table 4, Panel B (Revenues), Local, column (4) | 68.86 | matches |
| 6 | `n_obs_table4_col1` | 28872 | — | Table 4, Observations, column (1) (both panels) | — | — |
| 7 | `n_obs_table4_col2` | 27764 | — | Table 4, Observations, column (2) (both panels; column 4 has the same count) | — | — |
| 8 | `paid_bribe_endline_local_table5_panelB` | 0.018 | 0.009 | Table 5, Panel B (Bribes), Paid bribe (endline), beta-hat and SE | 0.018 | matches |
| 9 | `visited_by_collector_local_table6_col1` | -0.009 | 0.026 | Table 6, Local, column (1) Visited by collector | -0.00901 | matches |
| 10 | `compliance_cli_table7_col1` | 0.024 | 0.009 | Table 7, CLI, column (1) Compliance | 0.0242 | matches |
| 11 | `revenue_cli_table7_col2` | 46.566 | 21.2 | Table 7, CLI, column (2) Revenues | 46.57 | matches |
| 12 | `compliance_ease_of_payment_cli_table8_panelA_col2` | 0.056 | 0.007 | Table 8, Panel A (Ease of payment), Ease of payment, column (2) Compliance | 0.0561 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [12/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [11/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[12/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[12/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [8/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[7/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[9/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[12/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [4/13](seeded/pipeline-desktop-opus/20261110T223450Z/CELL.md) (20261110T223450Z) | [13/13](independent/pipeline-desktop-opus/20261110T222850Z/CELL.md) (20261110T222850Z) | [2/13](blind/pipeline-desktop-opus/20261110T220455Z/CELL.md) (20261110T220455Z) |
| `pipeline-desktop-opus-run2` | [3/13](seeded/pipeline-desktop-opus-run2/20261110T231000Z/CELL.md) (20261110T231000Z) | [7/13](independent/pipeline-desktop-opus-run2/20261110T225449Z/CELL.md) (20261110T225449Z) | [4/13](blind/pipeline-desktop-opus-run2/20261110T223603Z/CELL.md) (20261110T223603Z) |
| `pipeline-desktop-opus-run3` | [6/13](seeded/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) (20261110T230259Z) | [11/13](independent/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) (20261110T230259Z) | [5/13](blind/pipeline-desktop-opus-run3/20261110T223642Z/CELL.md) (20261110T223642Z) |
| `pipeline-desktop-opus-run4` | — | [6/13](independent/pipeline-desktop-opus-run4/20261110T230532Z/CELL.md) (20261110T230532Z) | [5/13](blind/pipeline-desktop-opus-run4/20261110T223728Z/CELL.md) (20261110T223728Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `compliance_local_table4_panelA_col2` | 0.038996 | 0.032 | ±0.007 (se_band) | 0.999 | PASS |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `compliance_local_table4_panelA_col2` | 0.038989 | 0.032 | ±0.007 (se_band) | 0.998 | PASS |
| [independent/pipeline-desktop-opus-run2/20261110T225449Z](independent/pipeline-desktop-opus-run2/20261110T225449Z/CELL.md) | `revenue_local_house_fe_table4_panelB_col4` | 48.3959 | 68.855 | ±20.56 (se_band) | 0.995 | PASS |
| [blind/pipeline-desktop-opus-run2/20261110T223603Z](blind/pipeline-desktop-opus-run2/20261110T223603Z/CELL.md) | `visited_by_collector_local_table6_col1` | -0.0345844 | -0.009 | ±0.026 (se_band) | 0.984 | PASS |
| [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) | `revenue_local_table4_panelB_col2` | 103 | 79.64 | ±22.856 (se_band) | 1.022 | FAIL |
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `compliance_local_exempt_excluded_table4_panelA_col5` | 0.047614 | 0.04 | ±0.008 (se_band) | 0.952 | PASS |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `compliance_local_exempt_excluded_table4_panelA_col5` | 0.047605 | 0.04 | ±0.008 (se_band) | 0.951 | PASS |
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `compliance_local_house_fe_table4_panelA_col4` | 0.03956 | 0.033 | ±0.007 (se_band) | 0.937 | PASS |
| [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) | `compliance_local_house_fe_table4_panelA_col4` | 0.039555 | 0.033 | ±0.007 (se_band) | 0.936 | PASS |
| [blind/pipeline-desktop-opus/20261110T220455Z](blind/pipeline-desktop-opus/20261110T220455Z/CELL.md) | `revenue_cli_table7_col2` | 23.9837 | 46.566 | ±21.2 (se_band) | 1.065 | FAIL |

### Declared deviations

- [seeded/claude-code/2026-11-10-a](seeded/claude-code/2026-11-10-a/CELL.md) (12/13; failed: `paid_bribe_endline_local_table5_panelB`)
  - analysis_data.dta is not shipped; it was rebuilt in R from the 01_base files following 2_Data_Construction.do, keeping only the variables the targeted tables use (fliers, stratum, randomization schedule incl. the a7 654 fix, registration, tax roll, midline, TDM payments; Stata merge semantics with master values winning on overlapping variables; carto-date imputations and today_alt as in the do-file). The pilot flier xlsx sets, chefferies and 2016 assignment merges were skipped because they only touch pilot polygons (dropped) or variables not used.
  - Coefficients only are reported; fixest clustered SEs (by a7) use fixest's small-sample defaults, which can differ marginally from Stata reg, cl().
- [seeded/pipeline-desktop-opus/20261110T223450Z](seeded/pipeline-desktop-opus/20261110T223450Z/CELL.md) (4/13; failed: `compliance_local_table4_panelA_col1`, `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_table4_panelB_col2`, `revenue_local_house_fe_table4_panelB_col4`, `visited_by_collector_local_table6_col1`, `revenue_cli_table7_col2`, `compliance_ease_of_payment_cli_table8_panelA_col2`)
  - Missing or non-2018 registration dates replaced by the neighborhood median registration date when building wave FE (today_alt)
  - Revenue per property uses one payment per property (max over duplicate receipt records) rather than summing duplicate records
- [seeded/pipeline-desktop-opus-run2/20261110T231000Z](seeded/pipeline-desktop-opus-run2/20261110T231000Z/CELL.md) (3/13; failed: `compliance_local_table4_panelA_col1`, `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_table4_panelB_col2`, `revenue_local_house_fe_table4_panelB_col4`, `n_obs_table4_col2`, `visited_by_collector_local_table6_col1`, `compliance_cli_table7_col1`, `revenue_cli_table7_col2`)
  - Dropped duplicate receipts and late-collection payments and counted one payment (max amount) per property, since summed amounts double-counted revenue
  - Campaign-wave FE built from property-level registration date (alternate date fields, then neighborhood median, where missing)
  - Campaign-wave bins made open-ended at the first and last wave so early/late registration dates are not dropped
- [seeded/pipeline-desktop-opus-run3/20261110T230259Z](seeded/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) (6/13; failed: `compliance_local_table4_panelA_col1`, `revenue_local_table4_panelB_col2`, `revenue_local_house_fe_table4_panelB_col4`, `visited_by_collector_local_table6_col1`, `compliance_cli_table7_col1`, `revenue_cli_table7_col2`, `compliance_ease_of_payment_cli_table8_panelA_col2`)
  - Payment amounts above the highest statutory rate (13,200 CF) are capped at 13,200 CF (implausible receipt amounts, max 1,662,800 CF, treated as entry errors)
  - Revenue per property uses one payment record per property (duplicate receipts dropped, max amount per compound) instead of summing all payment rows
  - For the Local vs Central comparison, registration dates a few days outside the outer time-window cut points are assigned to the nearest campaign-wave window rather than dropped (registration date used in place of the cleaned today_alt)
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (11/13; failed: `visited_by_collector_local_table6_col1`, `revenue_cli_table7_col2`)
  - The package ships only raw (01_base) data, so the analysis file was rebuilt: properties = non-pilot registration records with house type low/high (villas excluded) that carry a numeric tax liability on the tax roll (drops 'Voir le tract', 'Paye', blank and villa rows), deduplicated by compound code. This gives 28,921 Local+Central properties vs 28,872 in the paper.
  - De facto assignment: the paper says one CXL neighborhood was run by the chief alone; registration records show chief-only teams in CXL neighborhoods 654 and 639. Neighborhood 654 was recoded to Local (a guess).
  - Time fixed effects: property-level registration date; two-month (61-day) bins starting at floor of the midpoint between the two arms' first registration days, ending at the midpoint between their last days; properties outside dropped. Local-Central gives 213 clusters (as in the paper) but 27,507 obs (paper 27,764); CLI-Central gives 155 clusters (paper 165).
  - Revenue = receipt amount (amountCF) matched by compound code, 0 for non-payers; two receipts with amounts above 1.4 million CF (max liability 13,200 CF) were set to the property's liability.
  - Exempt (Table 4 col 5) = collector designated exempt in the registration record. House FE = registration house type (low/high band).
  - Table 6 outcome: midline (tot_complete==1, first record per compound) visits >= 2 (registration visit counted in 'visits'), 0 if household reported no visit; 99999 codes set missing.
  - Table 5 endline bribe: endline round 1 'bribe' (paid the collector's transport), asked only of households visited with someone present; set to 0 for households reporting no visit or a visit with nobody home (N = 1,222 vs paper 1,169).
  - Table 8: chief consultation pay_ease (0-2; 'don't know' set missing), CLI properties, house and stratum FE, N = 8,159 (paper 8,135).
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (12/13; failed: `visited_by_collector_local_table6_col1`)
  - Property sample built from registration_noPII: rows in the 356 study neighborhoods (drops logistics pilot), villas (house==3) dropped, deduplicated on tax ID (compound1) keeping the earliest record. This gives 29,396 Local+Central properties vs 28,872 in the paper; the authors' further exclusions could not be identified from the paper text.
  - De facto treatment: a7 654 (assigned CXL) recoded to Local (footnote 40); identified because all its endline respondents carry treatment==Local and its registration was done by the chief only.
  - Compliance = tax ID appears in tax_payments_noPII; revenue = sum of amountCF per tax ID. 8 payment records with missing or implausible amounts (two >1.4 million CF, one 50 CF) were set to the property's official liability (3,000 CF low band, 13,200 CF high band).
  - Time FE: property-level registration date (form start time, since `today` is missing for one form version). Window from the midpoint of the two arms' first registration days to the midpoint of their last days; two-month periods from the window start; properties outside the window dropped. Reproduces the 221 -> 213 cluster drop for Local vs Central, but leaves 157 clusters for CLI vs Central (paper 165).
  - Table 6 visited: midline survey (pilot==0, tot_complete==1), visited after registration = reported visits >= 2 (visits include the registration visit), 0 if household reported no visit; merged to the register by tax ID for house type and period; Local vs Central window sample.
  - Table 5 endline bribe: endline_round1 `bribe` (paid 'transport' to collectors), coded 0 for respondents not visited by collectors (visited==0 or 'yes but nobody home'), since the question was only asked of visited households; N=1,222 vs 1,169 in the paper.
  - Table 8: chief_consultations pay_ease (0-2, 'don't know' dropped) merged to CLI properties by tax ID; N=8,624 vs 8,135.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (12/13; failed: `visited_by_collector_local_table6_col1`)
  - Property universe taken from admin_data/hh_distances.dta (45,177 properties) with registration attributes merged by compound code; its arm counts match Table 2 except Central (+12) and CLI (+3), so the Local+Central base is 28,884 rather than 28,872.
  - De facto treatment: neighborhood a7=654 (assigned CXL; registration done by the chief alone; 93 properties) recoded to Local, which makes the Local and CXL counts equal Table 2 exactly.
  - Compliance = tax ID appears in tax_payments_noPII.dta, excluding receipts flagged error_code==1 (tax-ID/neighborhood mismatch); with this the Central mean (0.068) and revenue mean (193.7 vs 192.9) match Table 4 column 1.
  - Revenue: 8 receipt amounts that are not an official liability (e.g. 1,662,800 and 1,421,700 CF, 50 CF, missing) were replaced by the official liability implied by the receipt's USD rate (rateUSD*1900 snapped to the nearest official amount).
  - Time fixed effects: property-level registration date; two-month (61-day) periods from floor(midpoint of the two arms' first registration days) to floor(midpoint of their last registration days); properties outside dropped. The exact rule of online Appendix A2.5 is not in the provided text; this gives 27,446 obs / 213 clusters for Local-Central (paper 27,764 / 213) and 19,567 / 155 for CLI-Central (paper 20,636 / 165). Extensive searches over alternative date definitions did not reproduce both paper sample sizes.
  - House FE: registration house type 2 (high-value band) vs 1; exempt (Table 4 col 5) = collector-designated exempt in registration (missing treated as not exempt).
  - Endline bribe (Table 5): endline_round1 'bribe' (paid the collector's transport); the question is only asked if the household reported a visit with someone home, so households reporting no visit / no one home are coded 0; one record per respondent code; Local+Central; stratum FE only. N=1,217 (paper 1,169), Central mean 0.013 (paper 0.014).
  - Table 6 col 1: midline, first complete survey per compound; visited after registration = reported total visits >= 2 (the visit count includes the registration visit), 0 if no visit reported; merged to the windowed Local-Central property sample for house/period FE. N=16,323 (paper 18,162).
  - Table 8 Panel A col 2: chief_consultations pay_ease (0-2; 8888 'don't know' set to missing), CLI properties, house and stratum FE (N=8,136 vs paper 8,135).
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (12/13; failed: `visited_by_collector_local_table6_col1`)
  - Time-period fixed effects: two-month periods from the floor of the midpoint between the two arms' first registration dates to the ceiling of the midpoint between their last registration dates, assigned by each property's registration date; the paper's exact construction (online Appendix A2.5) is not in the package. Local/Central column 2 keeps 213 clusters like the paper but 27,453 rather than 27,764 properties; CLI/Central keeps 157 rather than 165 clusters.
  - Property universe = hh_distances (registered properties) merged with the registration survey; neighborhood 654 recoded from CXL to Local (paper fn 40). Gives 14,501 Central vs the paper's 14,489 (12 extra), and Local, CLI and CXL counts matching Table 2 to within 3.
  - Compliance and revenue come from tax_payments records with error_code==0. Two impossible amounts (1.42m and 1.66m CF) are capped at 13,200 CF.
  - Endline bribe (Table 5): endline_round1 'bribe' (paid transport to the collector), set to 0 for households reporting no visit; N=1,217 vs the paper's 1,169.
  - Table 6: post-registration visit = midline 'visits' >= 2 (the count includes the registration visit), 0 if no visit. Midline is linked to the register by compound code; N=16,332 vs the paper's 18,162.
  - time periods use each property's registration date; the paper's exact period construction (online Appendix A2.5) is not available, so the trimmed samples differ from the paper's (Local/Central col 2 has the paper's 213 clusters but fewer properties; CLI/Central keeps 157 rather than 165 clusters). The universe has 12 more Central properties than the paper's Table 2 (14,501 vs 14,489).
  - Table 6 midline outcome = household reports 2+ collector visits including registration (0 if no visit); midline records linked to the register by compound code, so fewer observations than the paper.
  - payment records flagged error_code==1 are not counted; two payment amounts above 13,200 CF (1.42m and 1.66m CF) are capped at 13,200 CF.
  - endline bribe outcome set to 0 for households reporting no collector visit (question asked only of visited households).
- [independent/pipeline-desktop-opus/20261110T222850Z](independent/pipeline-desktop-opus/20261110T222850Z/CELL.md) (13/13)
  - Payment amounts above the maximum statutory rate (13,200 CF) treated as data-entry errors and capped at 13,200 CF
  - Revenue counts one payment per property (max amount across duplicate receipts) instead of summing all receipt rows
  - Time fixed effects for Table 4 (cols 2,4,5) are the calendar month of each property's registration visit; properties without a dated registration record are dropped from these columns
  - Time fixed effects built as two-month calendar periods of each neighborhood's median 2018 registration date, keeping only periods in which both compared arms operated (exact wave definition not given in the summary)
- [independent/pipeline-desktop-opus-run2/20261110T225449Z](independent/pipeline-desktop-opus-run2/20261110T225449Z/CELL.md) (7/13; failed: `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_table4_panelB_col2`, `compliance_cli_table7_col1`, `revenue_cli_table7_col2`)
  - Per-property payment amounts winsorized at the 99th percentile of payers (13200 CF; 2 properties) to remove implausible receipt amounts that inflated revenue far above the statutory rates
  - 88 Local/Central neighborhoods with no recoverable campaign start date kept with their own campaign-wave FE level instead of being dropped
  - 77 CLI/Central neighborhoods with no recoverable campaign start date kept with their own campaign-wave FE level instead of being dropped
  - Endline file survey_data/endline_round2_noPII.dta dropped from the bribe outcome: its only bribe items (bribe_freq,bribe_amt1) give an implausible bribe-payment rate of 0.69, so they do not measure whether a bribe was paid
- [independent/pipeline-desktop-opus-run3/20261110T230259Z](independent/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) (11/13; failed: `compliance_cli_table7_col1`, `revenue_cli_table7_col2`)
  - Campaign start per neighborhood taken from earliest 2018 registration dates in the property register (program_start in the neighborhood file is 2016-dated and missing for many neighborhoods)
  - 7 payer amounts that were missing, non-positive or above 15x the median payment were replaced by the median payment for that house type
  - Time FE built as two-month campaign periods with neighborhoods starting outside the Local/Central overlap window pooled into the edge periods instead of being dropped (paper does not detail period construction)
- [independent/pipeline-desktop-opus-run4/20261110T230532Z](independent/pipeline-desktop-opus-run4/20261110T230532Z/CELL.md) (6/13; failed: `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_table4_panelB_col2`, `revenue_local_house_fe_table4_panelB_col4`, `compliance_cli_table7_col1`, `revenue_cli_table7_col2`)
  - Duplicate receipts dropped and receipt amounts (and per-property totals) capped at the top statutory rate of 13,200 CF to remove data-entry outliers
  - Compliance and revenue rebuilt from 2018 receipt-printer records (tax_payments) matched by tax ID to the register
  - Campaign-wave time FE built as two-month (or monthly) bins of each property's registration date with common support across arms
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (8/13; failed: `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_house_fe_table4_panelB_col4`, `visited_by_collector_local_table6_col1`)
  - Property sample built from taxroll_noPII.dta (one row per registered compound) merged to registration_noPII.dta for house band and collector exemption; villas (house type 3) dropped. Compliance = compound appears in tax_payments_noPII.dta (receipt data); revenue = amountCF, 0 for non-payers.
  - Revenue: 7 payers with missing or implausible receipt amounts (>13,200 CF, two records of >1.4m CF) were assigned the median amount paid in their house band.
  - De facto treatment: neighborhood 654 (CXL in the schedule) coded Local, identified as the misassigned neighborhood (chief-only registration, coded Local in the endline survey).
  - Randomization strata: the 'stratum' variable of randomization_assignment.dta (32 strata).
  - Time fixed effects: each neighborhood's campaign date is the median registration date in it; window from the midpoint of the two arms' earliest neighborhood dates to the midpoint of their latest; consecutive two-calendar-month bins from the window start; neighborhoods outside the window dropped. This drops 19 Central neighborhoods in Local vs Central and 35 in CLI vs Central.
  - Table 6 col 1: midline surveys with tot_complete==1, deduplicated by compound, merged to the register for house band; outcome = 1 if reported visits (which include the registration visit) >= 2, 0 if not visited or visits <= 1.
  - Table 5 endline bribe: endline_round1 respondents with a non-missing 'visited' answer, deduplicated by respondent code; outcome = 1 if paid the collector's transport, 0 if answered no or if not visited / nobody home; Local vs Central by survey neighborhood a7.
  - Table 8 panel A col 2: CLI-arm properties matched to chief_consultations.dta pay_ease (0-2 scale), house and stratum FE.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (7/13; failed: `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `revenue_local_table4_panelB_col2`, `revenue_local_house_fe_table4_panelB_col4`, `visited_by_collector_local_table6_col1`)
  - Register built from registration_noPII.dta: randomized neighborhoods (pilot dropped), tot_complete==1, unique compound codes, villas (house type 3) excluded. This gives 29,384 Local+Central properties, more than the paper's Table 2 counts. The authors' further cleaning of the register is not documented in the paper and could not be reconstructed.
  - De facto treatment: neighborhood 654 (CXL in the schedule) recoded to Local. It was identified from chief-only collectors in the registration data and Local coding in the endline survey.
  - Randomization stratum taken from randomization_assignment.dta (group of geographic stratum, 2016 campaign status and chief collection experience; 32 strata).
  - Compliance = the property's tax ID appears in tax_payments_noPII.dta. Revenue = amount paid (CF), 0 for non-payers. Eight payment records with missing or implausible amounts (<1500 or >13200 CF, all flagged error_rate) were set to the property's tax-roll liability.
  - Time fixed effects (online App. A2.5 not available): each neighborhood is dated by its first registration day. Start and end are the midpoints of the two arms' first and last registration days; two-month periods run from start; neighborhoods starting outside [start, end] are dropped.
  - Exempt (col 5) = collector-designated exempt in registration or an exemption reason in the tax roll.
  - Endline bribe outcome = 'paid the transport of the collector' (bribe), 0/1, among complete endline_round1 interviews where it was asked; Local vs Central, stratum FE.
  - Visited by collector (midline) = reported visits >= 2 (the visits count includes the registration visit), 0 if not visited. House type is merged from the register by compound code, so midline households whose compound code does not match the register drop out.
  - Table 8 ease of payment = chief_consultations pay_ease (0-2, 'don't know' dropped), merged to the CLI register by compound code.
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (9/13; failed: `compliance_local_table4_panelA_col2`, `compliance_local_house_fe_table4_panelA_col4`, `compliance_local_exempt_excluded_table4_panelA_col5`, `visited_by_collector_local_table6_col1`)
  - Package ships only raw (01_base) data, so the analysis sample was rebuilt: property register = registration_noPII rows in the 356 randomized neighborhoods with pilot==0, tot_complete==1, house in {low, high band} (285 villas dropped), unique compound code. This gives 46,506 non-villa properties (paper reports 45,162), so observation counts differ from the paper's construction.
  - De facto treatment taken from campaign_collector_info Tmt (neighborhood 654, randomized CXL, coded Local), giving 111 Local / 110 Central as in the paper.
  - Time fixed effects: online Appendix A2.5 is not available. Implemented as 61-day (two-month) periods starting at the midpoint between the earliest property registration dates of the two arms compared and ending at the midpoint between their latest registration dates. Each property is dated by its own registration date, and properties outside the window are dropped. The paper describes neighborhood-level assignment; the exact date variable used for it is unknown.
  - Compliance = registered compound appears in tax_payments_noPII receipt data with a positive amount (all receipts kept, including error_code==1). Revenue = sum of amountCF, 0 for non-payers. Two keyed amounts above 1 million CF were recoded to the band liability (3,000 or 13,200).
  - Column 5 drops properties with registration exempt==1 (collector designated exempt); missing exemption answers are kept.
  - Endline bribe: endline_round1 (tot_complete==1, non-pilot, one record per respondent code). Bribe is asked only of households reporting a collector visit with someone present, so households reporting no visit or nobody home are coded 0; 8888/9999 are set to missing. Treatment comes from the endline a7.
  - Table 6 visited: midline (tot_complete==1, non-pilot, first record per compound) matched to the register. 'Visited after registration' = 1 if the reported total visits (which include the registration visit) are >= 2, and 0 if no visit was reported. House type and registration date come from the register.
  - Table 8: chief_consultations pay_ease coded 0/1/2 (8888 don't know set to missing), merged to registered CLI properties by compound code; stratum = randomization_assignment stratum (32 groups) throughout.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (12/13; failed: `visited_by_collector_local_table6_col1`)
  - Analysis data rebuilt from raw base files (authors' cleaning code withheld). Register = registration_noPII rows in the 356 randomised neighbourhoods, pilot==0, tot_complete==1, house band 1/2 (villas excluded), deduplicated on compound1 (tax ID). This yields 29,384 Local+Central properties; the authors' exact register cleaning rules are unknown.
  - Compliance = tax ID appears in tax_payments_noPII (after dropping duplicate receipt copies, dup_receipt>=1). Revenue = sum of amountCF for the tax ID; 7 payers with missing amounts or amounts above the top statutory liability (13,200 CF; e.g. 1,421,700 and 1,662,800 CF entry errors) are set to their statutory liability (3,000 or 13,200 CF).
  - Time fixed effects: property-level registration dates (registration start timestamp). Arm first/last days = min/max registration date of each arm; window from floor of the midpoint of the two first days to the midpoint of the two last days; two-month calendar periods counted from the window start; properties outside the window dropped. The paper's note to Table 4 col 3 (time periods vary within neighbourhood) motivated property-level dating.
  - De facto treatment: neighbourhood a7 654 (assigned CXL) coded Local, identified from chief-only registration teams and the endline file's treatment code.
  - Table 6 col 1: midline complete non-pilot surveys excluding flagged duplicates/unknown compounds, one row per compound; visited after registration = total reported visits >= 2 (the visits question includes the registration visit), 0 if visited==No or visits<=1; merged to the register by tax ID for house type and time period.
  - Table 5 endline bribe: endline_round1 complete surveys; outcome 1 if paid collector 'transport' (bribe==1), 0 if bribe==0 or the household reported no visit / no one home (question skipped); don't know/refuse dropped.
  - Table 8: CLI register properties merged to chief_consultations by compound1, pay_ease in {0,1,2} (don't know dropped); 0-2 coding (slope identical to a 1-3 coding).

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- seeded: `compliance_local_table4_panelA_col1` — pipeline 0/3, agent 2/2
- seeded: `revenue_cli_table7_col2` — pipeline 0/3, agent 2/2
- seeded: `revenue_local_house_fe_table4_panelB_col4` — pipeline 0/3, agent 2/2
- seeded: `revenue_local_table4_panelB_col2` — pipeline 0/3, agent 2/2
- seeded: `visited_by_collector_local_table6_col1` — pipeline 0/3, agent 2/2
- independent: `visited_by_collector_local_table6_col1` — pipeline 4/4, agent 0/4
- blind: `n_obs_table4_col2` — pipeline 0/4, agent 4/4
- blind: `revenue_cli_table7_col2` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- seeded: `compliance_cli_table7_col1` — pipeline 1/3, agent 2/2
- seeded: `compliance_ease_of_payment_cli_table8_panelA_col2` — pipeline 1/3, agent 2/2
- seeded: `compliance_local_exempt_excluded_table4_panelA_col5` — pipeline 1/3, agent 2/2
- seeded: `compliance_local_house_fe_table4_panelA_col4` — pipeline 1/3, agent 2/2
- seeded: `compliance_local_table4_panelA_col2` — pipeline 1/3, agent 2/2
- seeded: `paid_bribe_endline_local_table5_panelB` — pipeline 3/3, agent 1/2
- independent: `compliance_cli_table7_col1` — pipeline 1/4, agent 4/4
- independent: `compliance_local_exempt_excluded_table4_panelA_col5` — pipeline 2/4, agent 4/4
- independent: `compliance_local_house_fe_table4_panelA_col4` — pipeline 2/4, agent 4/4
- independent: `compliance_local_table4_panelA_col2` — pipeline 2/4, agent 4/4
- independent: `revenue_cli_table7_col2` — pipeline 1/4, agent 3/4
- independent: `revenue_local_table4_panelB_col2` — pipeline 2/4, agent 4/4
- blind: `compliance_cli_table7_col1` — pipeline 1/4, agent 4/4
- blind: `revenue_local_house_fe_table4_panelB_col4` — pipeline 0/4, agent 2/4
- blind: `revenue_local_table4_panelB_col2` — pipeline 0/4, agent 3/4
- blind: `visited_by_collector_local_table6_col1` — pipeline 3/4, agent 0/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 2; 2026-11-10T17:09:22Z; from `claude-code-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 12/13; executions 3; 2026-11-10T17:11:30Z; from `claude-code-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T223450Z

[`seeded/pipeline-desktop-opus/20261110T223450Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T223450Z/CELL.md) — final 4/13, re-scored 4/13; first scored 0/13; executions 4; 2026-11-10T22:34:50Z; from `pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T231000Z

[`seeded/pipeline-desktop-opus-run2/20261110T231000Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T231000Z/CELL.md) — final 3/13, re-scored 3/13; first scored 0/13; executions 4; 2026-11-10T23:10:00Z; from `pipeline-oracle-desktop-opus-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T230259Z

[`seeded/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) — final 6/13, re-scored 6/13; first scored 0/13; executions 4; 2026-11-10T23:02:59Z; from `pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 11/13, re-scored 11/13; first scored 11/13; executions 10; 2026-11-10T17:17:31Z; from `claude-code-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 11; 2026-11-10T17:17:00Z; from `claude-code-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 13; 2026-11-10T17:23:00Z; from `claude-code-run3-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 20; 2026-11-10T17:24:00Z; from `claude-code-run4-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T222850Z

[`independent/pipeline-desktop-opus/20261110T222850Z/CELL.md`](independent/pipeline-desktop-opus/20261110T222850Z/CELL.md) — final 13/13, re-scored 13/13; first scored 2/13; executions 4; 2026-11-10T22:28:50Z; from `pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T225449Z

[`independent/pipeline-desktop-opus-run2/20261110T225449Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T225449Z/CELL.md) — final 7/13, re-scored 7/13; first scored 5/13; executions 4; 2026-11-10T22:54:49Z; from `pipeline-oracle-desktop-opus-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T230259Z

[`independent/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T230259Z/CELL.md) — final 11/13, re-scored 11/13; first scored 5/13; executions 5; 2026-11-10T23:02:59Z; from `pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T230532Z

[`independent/pipeline-desktop-opus-run4/20261110T230532Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T230532Z/CELL.md) — final 6/13, re-scored 6/13; first scored 6/13; executions 5; 2026-11-10T23:05:32Z; from `pipeline-oracle-desktop-opus-run4-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 5; 2026-11-10T17:12:30Z; from `claude-code-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 8; 2026-11-10T17:12:00Z; from `claude-code-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 9; 2026-11-10T17:15:00Z; from `claude-code-run3-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 12/13, re-scored 12/13; first scored 12/13; executions 8; 2026-11-10T17:15:00Z; from `claude-code-run4-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T220455Z

[`blind/pipeline-desktop-opus/20261110T220455Z/CELL.md`](blind/pipeline-desktop-opus/20261110T220455Z/CELL.md) — final 2/13, re-scored 2/13; first scored 2/13; executions 1; 2026-11-10T22:04:55Z; from `pipeline-oracle-desktop-opus-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T223603Z

[`blind/pipeline-desktop-opus-run2/20261110T223603Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T223603Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-11-10T22:36:03Z; from `pipeline-oracle-desktop-opus-run2-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T223642Z

[`blind/pipeline-desktop-opus-run3/20261110T223642Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T223642Z/CELL.md) — final 5/13, re-scored 5/13; first scored 5/13; executions 1; 2026-11-10T22:36:42Z; from `pipeline-oracle-desktop-opus-run3-1paper-balan-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T223728Z

[`blind/pipeline-desktop-opus-run4/20261110T223728Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T223728Z/CELL.md) — final 5/13, re-scored 5/13; first scored 5/13; executions 2; 2026-11-10T22:37:28Z; from `pipeline-oracle-desktop-opus-run4-1paper-balan-indep-blind-2026-11-10.json`; evidence complete.

