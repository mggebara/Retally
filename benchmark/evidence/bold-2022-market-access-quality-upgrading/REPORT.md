# Evidence report: bold-2022-market-access-quality-upgrading

**Market Access and Quality Upgrading: Evidence from Four Field Experiments** — Tessa Bold, Selene Ghisolfi, Frances Nsonzi, Jakob Svensson

- Paper: https://www.jakobsvensson.com/uploads/9/9/1/0/99107788/aer.20210122.pdf
- I4R report: https://www.econstor.eu/bitstream/10419/277561/1/I4R-DP072.pdf
- I4R outcome label: reproducible; split: holdout
- Catalog entry (ground truth): `benchmark/papers/bold-2022-market-access-quality-upgrading.yaml`
- Data access: manual (package downloaded by hand and placed at `benchmark/manual-packages/T50/158401-V1.zip`; AEA Data and Code Repository on openICPSR, project 158401, version V1 (doi:10.3886/E158401V1); login and terms-of-use click-through required, so the zip was downloaded by hand (2026-11-09) and placed unchanged at benchmark/manual-packages/T50/158401-V1.zip (1,374,012 bytes, md5 98b64c984bae25b4e3659438174e7383; SOURCE.txt beside it).  V1 is the only version (the one DP72 reproduced, downloaded 2023-02-03).  64 zip entries (53 files), 6.5 MB uncompressed, no nested archives. Contents: README.pdf (3 pp.; data sources, Stata packages, run order and times, no estimates); data/raw/ with eight Stata .dta files (anonym_returns_data.dta, the returns-to-quality experiment with bag defects, lab tests and sales; panel_g1.dta, panel_g2.dta and panel_g0.dta, the market-access, extension-service and quasi-control household survey panels; maize_quality_gr0.dta and maize_quality_gr1.dta, lab tests; seller_data.dta, sales by trader; buy_data.dta, the trading company's records); empty data/end/ and output/ folders; dofiles/ with 38 Stata do-files (CONFIG, master, seven variable-creation files, a merge file, permutations, Tables 1-7, Figures 1-5, appendix tables and figures, in-text replication); other/"Results reported in the main text.pdf" (3 pp.; quotes the paper's in-text sentences that cite numbers not in tables and names the output table that replicates each; no regression table and none of the pinned values); survey_materials/ with five .xlsx survey instruments.  No log, no generated table.  The script-free copy (independent / blind) withholds the 38 .do files by suffix (benchmark.strip_rule.classify_tree on the extracted package and the runner's manifest, 2026-11-09); everything else is kept.  Project page: https://www.openicpsr.org/openicpsr/project/158401/version/V1/view)

> Headline findings: in the returns to quality experiment the service package cut visually verified defects by -2.16 (0.212) types per bag (Table 2 col 1, N 622 bags) and lab-measured defects by -0.20 (0.054) (col 2, N 82), yet price moved by 2.95 (9.870) UGX/kg (col 3), deductions by 0.18 (0.633) percent (col 4) and net price by 0.98 (10.621) (col 5; cols 3-5 N 116 sales, 94 households): the return to quality is zero.  In the market access experiment (Table 6 Panel A, ANCOVA, village-clustered p-values in parentheses, permutation p-values in brackets) access raised the price by 0.017 USD/kg (0.001) [0.004], yield by 108.9 kg/acre (0.041) [0.049], harvest value by 78.9 USD (0.078) [0.102], profit (monetary expenses) by 63.1 (0.061) [0.079] and profit incl. own hours by 97.6 (0.029) [0.031]; Ns 617 (price), 658 (harvest, yield, harvest value), 640 (cols 6-7), 464 (col 8).
> Paper text and how it was verified.  The catalog source is the published AER article itself (Atypon-produced typeset PDF on Jakob Svensson's site), so its cells are the published values by construction.  It was still checked cell by cell against the meta-database: all 129 numeric o_coeff_dbl / o_std_err_dbl / o_p_dbl values of the 64 rows (Table 2 cols 1, 2, 4; Table 4 col 3; Table 5 both panels, all 16 cells; Table 6 bracketed p-values; Table 7 all nine cells) equal the printed number in the same table cell (125 by script on the parsed table blocks, the four Table 7 Panel B bracketed p-values 0.680 / 0.052 by eye).  One meta-database coding quirk, not a typo: for Table 5 the DB records the parenthesised number as o_std_err_dbl, but the paper's notes say parentheses are clustered p-values (e.g. 2.37 (0.045) [0.049] is coded SE 0.045, p 0.049); Table 6 rows, coded with p only, read the bracket.  Other open texts: the J-PAL / Tessa Bold working papers (January / April 2021 "Three Field Experiments", August 2021 "Four Field Experiments", January 2022) were not used.
> Curation pass (2026-11-09).  13 claims.  Left out: Table 2 col 2 N (82) and the Households / R2 / Mean control rows; Table 6 Panel A cols 2 (acreage), 3 (harvest) and 6 (monetary expenses) and its other Ns; Table 6 Panel B (extension service, all null); Table 5 (investment; same ANCOVA, kept the entry at 13); Table 4 (quality, a difference in means with a quasi-control group and Horowitz-Manski / Lee bounds); Table 7 (trader market shares and prices); Tables 1 and 3 (descriptive / balance); every permutation p-value and the online appendix.
> Package-only facts (never in contexts).  Table 2 (dofiles/table2.do on data/end/quality_for_analysis.dta built by FINAL_create_vars_returns.do from data/raw/anonym_returns_data.dta, quasicontrol==0): col 1 reshapes defects_visual_tot_ long by bag and runs areg ... treatment, a(ea_code) cluster(hhh_id); col 2 areg defects_lab_share_r treatment, a(ea_code) robust; cols 3-5 reshape price_ / deduct_totalshare100_ / net_priceavg_ long by sale, drop missing price and sale 1 (the random bag bought by the research team), areg y treatment i.ea_code, cluster(hhh_id) a(week_sale_).  Table 6 (dofiles/table6.do on data/end/panel_g1g2_analysis.dta built by FINAL_create_vars_main_g1.do, _g2.do and merge_gr1_gr2.do from data/raw/panel_g1.dta / panel_g2.dta): group 1, treatment buy_treatment; the ANCOVA control is the outcome's household mean in the last baseline season (season_spring2018), else the mean over pre-treatment seasons (season_ante); reg y buy_treatment y_p3 i.survey_season if group==1 & season_post==1, cluster(ea_code). Price is revenue over kilograms sold; harvest value is revenue plus the unsold remainder at the village-season mean price (household 10249026 in season 3 valued at that mean); monetary values are converted from UGX at a season-specific rate (3575 ... 3685 UGX per USD); profit incl. own hours uses the household's own labor hours priced at 833 UGX/hour and exists only for seasons 5-7.  Randomization-inference p-values use 10,000 village-level permutations (permutations.do; about five hours in Stata per the README).
> Blind-mode exposure (step 6, 2026-11-09).  Both modes reached llm_answer_pending at zero cost (oracle label curate-t50, placeholder methodology summary and an empty hyperparameter list).  The blind generation prompt states no pinned value or SE at printed precision or rounded to 1-3 significant figures (its only hits are claim list numbers 10 and 11, "10,000 permutations", file sizes and row counts) and carries no do-file text; the independent prompt names no script. The abstract prints no numbers.  The methodology summariser and hyperparameter extractor get the full paper text, as for every entry, and the paper's prose states several targets ("Altogether 622 bags", "116 sales from 94 households", "US$79 ... per season"); the README's blind-mode caveat covers this.  The paper parser takes the AER running header ("American Economic Review 2022, 112(8): 2518-2552") as the title.
> What was read.  The published article (all 35 pp.; Tables 2 and 4-7 in detail, Sections IV-V); DP72 in full and the JCRE version's reproducibility section; the 64 meta-database rows; README.pdf and "Results reported in the main text.pdf"; FINAL_master.do, table2.do, table6.do, merge_gr1_gr2.do and the outcome-construction part of FINAL_create_vars_main_g1.do; the column lists of the eight .dta files; the strip-rule classification of the extracted package.
> What could not be verified.  The authors' Stata code was not run (no Stata here) and no independent R cross-check was made in this pass.
> Original analysis in Stata 16; language: r is the reproduction target.

## Pinned claims

| # | Claim | Paper value | SE | Location | I4R replicator | I4R outcome |
|---|---|---|---|---|---|---|
| 0 | `treatment_defects_visual_table2_col1` | -2.16 | 0.212 | Table 2, column (1) Defects (visually verifiable), Treatment | -2.16 | matches |
| 1 | `treatment_defects_lab_table2_col2` | -0.2 | 0.054 | Table 2, column (2) Defects (lab), Treatment | -0.2 | matches |
| 2 | `treatment_price_table2_col3` | 2.95 | 9.87 | Table 2, column (3) Price, Treatment | 2.95 | matches |
| 3 | `treatment_deductions_table2_col4` | 0.18 | 0.633 | Table 2, column (4) Deductions, Treatment | 0.18 | matches |
| 4 | `treatment_net_price_table2_col5` | 0.98 | 10.621 | Table 2, column (5) Net price, Treatment | 0.98 | matches |
| 5 | `n_obs_table2_col1_bags` | 622 | — | Table 2, Observations, column (1) | 622 | matches |
| 6 | `n_obs_table2_cols3_5_sales` | 116 | — | Table 2, Observations, columns (3)-(5) | 116 | matches |
| 7 | `market_access_price_table6_panelA_col1` | 0.017 | — | Table 6, Panel A (Market access experiment), column (1) Price, Access to a market for quality maize | 0.017 | matches |
| 8 | `market_access_yield_table6_panelA_col4` | 108.9 | — | Table 6, Panel A (Market access experiment), column (4) Yield, Access to a market for quality maize | 108.9 | matches |
| 9 | `market_access_harvest_value_table6_panelA_col5` | 78.9 | — | Table 6, Panel A (Market access experiment), column (5) Harvest value, Access to a market for quality maize | 78.9 | matches |
| 10 | `market_access_profit_monetary_table6_panelA_col7` | 63.1 | — | Table 6, Panel A (Market access experiment), column (7) Profit (monetary expenses), Access to a market for quality maize | 63.1 | matches |
| 11 | `market_access_profit_incl_own_hours_table6_panelA_col8` | 97.6 | — | Table 6, Panel A (Market access experiment), column (8) Profit (incl. own hours), Access to a market for quality maize | 97.6 | matches |
| 12 | `n_obs_table6_panelA_cols3_5` | 658 | — | Table 6, Panel A, Observations, columns (3)-(5) | 658 | matches |

## Pass counts: mode × reproducer × run

| Reproducer | seeded | independent | blind |
|---|---|---|---|
| `claude-code` | [13/13](seeded/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[13/13](seeded/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b) | [9/13](independent/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[11/13](independent/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[8/13](independent/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[8/13](independent/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) | [8/13](blind/claude-code/2026-11-10-a/CELL.md) (2026-11-10-a)<br>[7/13](blind/claude-code/2026-11-10-b/CELL.md) (2026-11-10-b)<br>[9/13](blind/claude-code/2026-11-10-c/CELL.md) (2026-11-10-c)<br>[8/13](blind/claude-code/2026-11-10-d/CELL.md) (2026-11-10-d) |
| `pipeline-desktop-opus` | [10/13](seeded/pipeline-desktop-opus/20261110T173855Z/CELL.md) (20261110T173855Z) | [8/13](independent/pipeline-desktop-opus/20261110T170624Z/CELL.md) (20261110T170624Z) | [3/13](blind/pipeline-desktop-opus/20261110T164122Z/CELL.md) (20261110T164122Z) |
| `pipeline-desktop-opus-run2` | [9/13](seeded/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) (20261110T215013Z) | [7/13](independent/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) (20261110T215013Z) | [4/13](blind/pipeline-desktop-opus-run2/20261110T172233Z/CELL.md) (20261110T172233Z) |
| `pipeline-desktop-opus-run3` | [9/13](seeded/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) (20261110T215031Z) | [6/13](independent/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) (20261110T215031Z) | [3/13](blind/pipeline-desktop-opus-run3/20261110T172243Z/CELL.md) (20261110T172243Z) |
| `pipeline-desktop-opus-run4` | — | [7/13](independent/pipeline-desktop-opus-run4/20261110T215048Z/CELL.md) (20261110T215048Z) | [3/13](blind/pipeline-desktop-opus-run4/20261110T171244Z/CELL.md) (20261110T171244Z) |

Final pass counts as recorded in the results row; * = partial evidence (see the cell).

## What to hand-check

### Narrowest margins

Ratio of the absolute error to the band closest to 1 (a pass at 0.98 or a fail at 1.03 is one rounding away from flipping).

| Cell | Claim | Reproduced | Paper | Band | Error / band | Verdict |
|---|---|---|---|---|---|---|
| [independent/pipeline-desktop-opus-run3/20261110T215031Z](independent/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) | `treatment_net_price_table2_col5` | -9.50059 | 0.98 | ±10.621 (se_band) | 0.987 | PASS |
| [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) | `market_access_price_table6_panelA_col1` | 0.017474 | 0.017 | ±0.0005 (printed_precision) | 0.948 | PASS |
| [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) | `market_access_price_table6_panelA_col1` | 0.016471 | 0.017 | ±0.0005 (printed_precision) | 1.058 | FAIL |
| [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) | `market_access_harvest_value_table6_panelA_col5` | 80.589 | 78.9 | ±1.578 (relative) | 1.070 | FAIL |
| [independent/pipeline-desktop-opus-run4/20261110T215048Z](independent/pipeline-desktop-opus-run4/20261110T215048Z/CELL.md) | `treatment_defects_visual_table2_col1` | -1.9687 | -2.16 | ±0.212 (se_band) | 0.902 | PASS |
| [blind/pipeline-desktop-opus/20261110T164122Z](blind/pipeline-desktop-opus/20261110T164122Z/CELL.md) | `treatment_price_table2_col3` | -7.9041 | 2.95 | ±9.87 (se_band) | 1.100 | FAIL |
| [blind/pipeline-desktop-opus-run3/20261110T172243Z](blind/pipeline-desktop-opus-run3/20261110T172243Z/CELL.md) | `treatment_price_table2_col3` | -7.9041 | 2.95 | ±9.87 (se_band) | 1.100 | FAIL |
| [blind/pipeline-desktop-opus-run4/20261110T171244Z](blind/pipeline-desktop-opus-run4/20261110T171244Z/CELL.md) | `treatment_price_table2_col3` | -7.9041 | 2.95 | ±9.87 (se_band) | 1.100 | FAIL |
| [seeded/pipeline-desktop-opus/20261110T173855Z](seeded/pipeline-desktop-opus/20261110T173855Z/CELL.md) | `treatment_defects_visual_table2_col1` | -2.19536 | -2.16 | ±0.0432 (relative) | 0.819 | PASS |
| [blind/pipeline-desktop-opus/20261110T164122Z](blind/pipeline-desktop-opus/20261110T164122Z/CELL.md) | `market_access_yield_table6_panelA_col4` | 111.485 | 108.9 | ±2.178 (relative) | 1.187 | FAIL |

### Declared deviations

- [seeded/pipeline-desktop-opus/20261110T173855Z](seeded/pipeline-desktop-opus/20261110T173855Z/CELL.md) (10/13; failed: `treatment_price_table2_col3`, `treatment_deductions_table2_col4`, `treatment_net_price_table2_col5`)
  - Dropped sale slot 2 records (treated as a re-recording of sale 1) so the sample matches the paper's 116 sales = 94 households + additional sales 3 and 4
- [seeded/pipeline-desktop-opus-run2/20261110T215013Z](seeded/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) (9/13; failed: `treatment_price_table2_col3`, `treatment_deductions_table2_col4`, `treatment_net_price_table2_col5`, `n_obs_table2_cols3_5_sales`)
  - Deductions built from bag weights (add5_ind_weight) and add5_ind_ded_weight; interpretation of ded_weight ( weight after deduction ) inferred from the data
- [seeded/pipeline-desktop-opus-run3/20261110T215031Z](seeded/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) (9/13; failed: `treatment_price_table2_col3`, `treatment_deductions_table2_col4`, `treatment_net_price_table2_col5`, `n_obs_table2_cols3_5_sales`)
  - No week-of-sale variable found in returns data; week-of-sale FE omitted (village FE only)
- [independent/claude-code/2026-11-10-a](independent/claude-code/2026-11-10-a/CELL.md) (9/13; failed: `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Table 6 ANCOVA pretreatment control is the outcome in the household's last observed baseline season (season 3 for nearly all households) rather than the mean over the three baseline seasons; switched after the attempt-7 claim comparison. The baseline-mean version (attempt-7) gave smaller treatment effects (yield 89.5, harvest value 56.2, profit 52.7).
  - Table 6 column 8 (profit incl. own hours): own/family hours are only recorded from season 5 on, so the pretreatment control is last-baseline monetary profit; family hours are valued at a constant US$26/118 per hour (the wage implied by the text: US$26 of hired labour = 118 hours).
  - UGX converted to USD at a constant 3700 UGX/USD (the paper does not state the rate; 3700 reproduces the Table 3 baseline mean price of about US$0.20/kg).
  - Harvest value = sales revenue (seller_data) + unsold harvest valued at the village-season median price per kg; expenses = inputs (seeds, fertilizer, booster, manure, chemicals) + equipment + hired labour (tot_lab_costs) + post-harvest labour/other/drying/storage costs + transport, defined when seed costs are reported (gives N=640). Season-2 harvest uses the sum of plot harvests because the season-2 harvest_kg total is inconsistent with the plot sums.
  - Table 2: sales are buyer slots 2-4 of the final-visit module (slot 1 is the single random bag bought by the research team); week of sale = Stata-style week of year of the sale date; deductions = 100*(y-z)/y with y = enumerator-measured weight of the bags sold and z = buyer weight after deductions; net price = price*z/y. Week fixed-effect singletons kept (fixef.rm='none'), so N=116.
  - Table 6 pretreatment control = outcome in the household's last observed baseline season (not the baseline mean); profit incl. own hours uses last-baseline monetary profit as its pretreatment control (own hours not measured at baseline); hourly wage fixed at US$26/118 (implied by the text); exchange rate 3700 UGX/USD (not stated in the paper).
- [independent/claude-code/2026-11-10-b](independent/claude-code/2026-11-10-b/CELL.md) (11/13; failed: `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`)
  - UGX to USD conversion uses a fixed 3700 UGX/USD; the paper does not state the rate (control means of price, harvest value and expenses match the paper's within about 1%).
  - Table 6 col 8: own/family hours were not collected at baseline, so the ANCOVA control for profit incl. own hours is the household's baseline monetary profit.
  - Family hours are valued at one market wage: the median daily hired-labour wage (5000 UGX) divided by the median hours per day (6), i.e. 833 UGX/hour, not a community-specific wage.
  - Table 2 cols 4-5: the enumerator-measured bag weights (y) are matched to sales by bag order after dropping the randomly selected lab bag; the authors' exact matching is unknown.
  - Post-harvest hired labour in seasons 5-7 is the sum of the activity items (decob/winnow/sort/bag), not the survey total labor_cost_ph. This drops one 12m UGX entry that appears only in the total. It was chosen because the expenses R2 (0.33) and the profit R2 (0.22) then match the paper.
- [independent/claude-code/2026-11-10-c](independent/claude-code/2026-11-10-c/CELL.md) (8/13; failed: `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - UGX/USD exchange rates are not stated in the paper; annual averages assumed (3611 for 2017, 3727 for 2018, 3704 for 2019, 3718 for 2020).
  - Hourly market wage for valuing family labor = median hired-labor day rate (5000 UGX) / median family hours per day (6).
  - Profit incl. own hours: no baseline family-hour data, so the lagged control is last-baseline monetary profit.
  - Lagged outcome in the ANCOVA = household's value in the last baseline survey round (missing set to 0 plus a missing indicator); chosen after exploratory runs on the unlisted harvest and acreage columns. The price regression therefore has 623 rather than 617 observations.
  - Community-specific price for harvest value = village-season mean of household average sale prices from seller_data.dta; monetary expenses aggregated from survey cost items (seeds, fertilizer, boosters, manure, chemicals, plot-level hired labor, equipment, harvest/decobbing, post-harvest labor and other costs, drying, storage, transport); defined only where the plot-level input module was administered (640 obs).
  - UGX/USD exchange rates assumed (annual averages 3611/3727/3704/3718 for 2017-2020); not stated in the paper
  - hourly wage = median hired day rate / median family hours per day; profit incl. own hours uses last-baseline monetary profit as the lagged control (no baseline family-hour data); lagged outcome = last baseline round value, missing set to 0 with indicator
  - community price = village-season mean of household average sale prices (seller_data); expenses aggregated from survey cost items as described
- [independent/claude-code/2026-11-10-d](independent/claude-code/2026-11-10-d/CELL.md) (8/13; failed: `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Monetary values converted at a constant 3,700 UGX per US dollar (rate not stated in the paper; chosen because it matches the paper's control/baseline means for price, harvest value and expenses).
  - Harvest value = sales revenue (seller data) + unsold harvest valued at the village-season mean sale price.
  - Monetary expenses = seeds, fertilizer, booster, chemicals, manure, equipment, hired labour (tot_lab_costs), post-harvest labour and other post-harvest costs, harvest and decobbing costs, drying labour, transport.
  - Family labour hours (seasons 5-7 only) valued at a single hourly wage = median hired daily wage (5,000 UGX) / median family hours per day (6) = 833 UGX/h.
  - ANCOVA pre-treatment control = household mean of the outcome over baseline seasons 1-3; for profit incl. own hours (no baseline family-hours data) the baseline monetary profit is used.
  - Season-2 harvest_kg is in a different unit (2-4x the plot sum), so harvest is the sum of plot-level harvests.
  - Table 6 inference by village clusters (fixest CR1); no randomization inference.
- [independent/pipeline-desktop-opus/20261110T170624Z](independent/pipeline-desktop-opus/20261110T170624Z/CELL.md) (8/13; failed: `n_obs_table2_cols3_5_sales`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Exchange rate set to 3,450 UGX/USD (rate not given in excerpt; previous 3,700 assumption)
  - Sales restricted to records with measured weights (needed for deductions and net price)
  - Records of the same household on the same sale date collapsed into one sale (weight-weighted price; sale definition not given in excerpt)
  - Harvest value uses household's own sale price (village-season median if no sale); valuation price not given in excerpt
  - Dropped component cost columns when a matching total column exists (avoid double counting)
  - Own hours valued at assumed wage of 10,000 UGX per 7-hour day (hired wage not recoverable)
- [independent/pipeline-desktop-opus-run2/20261110T215013Z](independent/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) (7/13; failed: `n_obs_table2_cols3_5_sales`, `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Sale records restricted to entries with positive price, recorded bag weight and a recorded sale date (add5_sold_when_e), used for the week-of-sale fixed effect
  - Maize price excludes labour-cost (lc_) and input price columns; chosen as the maize sale price construction with the widest post-treatment coverage
  - Missing household baseline means set to 0 with a missing-baseline indicator in the ANCOVA (estimating equation not in excerpt)
- [independent/pipeline-desktop-opus-run3/20261110T215031Z](independent/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) (6/13; failed: `treatment_price_table2_col3`, `n_obs_table2_cols3_5_sales`, `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Sale-level sample defined as 'hh_date' (raw sale records gave 211 rows vs the paper's 116 sales from 94 households)
  - Price per kg constructed as maize revenue / kg sold (told_tot/sold_kg), implausible values (<100 or >5000 UGX/kg) set to missing
  - Harvest value constructed as harvest_kg times household price (village-season, then season mean if unsold), USD
  - Monetary profit constructed as harvest value minus the sum of reported monetary cost items (UGX converted at 3700/USD)
- [independent/pipeline-desktop-opus-run4/20261110T215048Z](independent/pipeline-desktop-opus-run4/20261110T215048Z/CELL.md) (7/13; failed: `n_obs_table2_cols3_5_sales`, `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - Sale (transaction) definition not documented in the data; entries collapsed using the ' week ' definition ( 211 entries -> 179 sales), chosen among same-date, same-week, same-price and post-harvest-only definitions
  - Average price constructed as total revenue / kg sold per household-season ( combined/sold_kg_p , plausible range 100-5000 UGX/kg)
  - Harvest value constructed as harvest kg (yield x acres where harvest missing) x household price (village-season median if unsold)
  - Cost items de-duplicated: per-unit labour rates excluded, seasonal labour totals preferred over item-level labour costs, unsuffixed totals preferred over numbered items
  - Monetary profit constructed as harvest value minus summed monetary input/labour cost items (transport excluded)
  - Profit incl. own hours = monetary profit minus family labour hours valued at the average hired hourly wage ( 720.1 UGX/hour)
- [blind/claude-code/2026-11-10-a](blind/claude-code/2026-11-10-a/CELL.md) (8/13; failed: `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - UGX converted to US dollars at a constant 3700 UGX/USD; no exchange rate is given in the data or the paper.
  - Own/family labor valued at an hourly wage derived from the data: median positive daily hired-labor wage (5000 UGX) divided by the median reported hours per working day (6), i.e. 833 UGX/hour.
  - Family labor hours are only collected in seasons 5-7, so Table 6 col 8 uses seasons 5-7 and the household's pretreatment monetary profit as the lagged control (no pretreatment value of profit incl. own hours exists).
  - ANCOVA lagged outcome = household mean of the outcome over baseline seasons 1-3 (as available); missing pretreatment values set to 0 with a missing indicator (the indicator was collinear/dropped in all specs).
  - Harvest value = revenue from recorded sales (seller_data) + unsold harvest valued at the village-season median price; household price = quantity-weighted average sale price.
  - Monetary expenses = sum of seed, fertilizer, booster, manure, chemical, equipment, hired-labor (plot-level), harvest, decobbing, drying, storage, post-harvest labor and other post-harvest costs, plus transport costs.
  - UGX converted to USD at a constant 3700 UGX/USD (rate not provided in data or paper).
  - own labor valued at hourly wage = median daily hired-labor wage / median reported hours per day; own hours available seasons 5-7 only, so col 8 uses pretreatment monetary profit as the lagged control.
  - missing pretreatment values set to 0 with a missing-indicator in ANCOVA.
- [blind/claude-code/2026-11-10-b](blind/claude-code/2026-11-10-b/CELL.md) (7/13; failed: `n_obs_table2_cols3_5_sales`, `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - US dollar amounts (Table 6) use a constant exchange rate of 3700 UGX/USD; the paper does not state the rate.
  - Table 6 variables were constructed from the raw survey files (the authors' variable-creation code is withheld): price = household-season revenue / kg sold from seller_data (all buyers incl. the quality buyer); harvest = sum of plot harvests (fallback harvest_kg); acreage = sum of plot sizes; harvest value = sales revenue + unsold harvest valued at the village-season mean price of sales to buyers other than the quality buyer (code 555); monetary expenses = seeds, fertilizer, booster, manure, chemicals, equipment/other post-harvest, transport and hired labour (tot_lab_costs_*, labor_cost_ph).
  - Profit incl. own hours: family hours (pre-harvest tasks + decob/winnow/sort/bag) valued at a season median hourly hired wage (hired cost per day / median family hours per day, or cost per hour); only seasons 5-7 have the full hours module, and there is no pretreatment value, so that ANCOVA has no lagged outcome (missing-baseline indicator approach).
  - ANCOVA pretreatment value = household mean of the outcome over baseline seasons 1-3; missing baseline set to 0 with a missing indicator.
  - Table 2: visual defects = count over 10 types (dirty, cobs, stones, dust, insects live or dead, broken, immature, damaged, rotten, mould) with unrecorded items counted as absent; a bag counts as inspected if any defect item was recorded. Deductions use enumerator bag weights (add4_weight) of the bags in a sale as y and buyer weight after deduction (ind_ded_weight) as z; week FE = Stata-style week of year of the sale date.
  - fixest dropped one fixed-effect singleton sale in Table 2 cols 3-5 (210 sales with date -> 209 used); left as is.
  - US dollar values use a constant exchange rate of 3700 UGX/USD (rate not stated in the paper)
- [blind/claude-code/2026-11-10-c](blind/claude-code/2026-11-10-c/CELL.md) (9/13; failed: `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - UGX to USD conversion fixed at 10000/3 = 3333.33 UGX per USD, taken from the paper's stated approximation (UGX10,000 ~ US$3; UGX30,000 ~ US$9); the exact rate the authors used is not given.
  - Table 6 col 8 (profit incl. own hours): family labor hours were only collected from the follow-up seasons, so no pre-treatment value exists; the ANCOVA omits the lagged outcome for this column. Own hours = household pre-harvest/harvest hours (lh_*) plus post-harvest decob/winnow/sort/bag hours, valued at a market hourly wage = median hired day rate (lc_* unit 'days') / median family hours per day (6), by season.
  - Table 6 ANCOVA: pre-treatment value = household mean of the outcome over baseline seasons 1-3; households with no baseline value get 0 plus a missing indicator. Season fixed effects; follow-up seasons 4-7; SEs clustered by village (ea_code).
  - Table 6 variables constructed from raw data: harvest = harvest_kg (else sum of plot harvests); acreage = acres_tot (else sum of plot sizes); yield = harvest/acres; price = kg-weighted average sale price from seller_data (price>0, kg>0); harvest value = sales revenue + unsold harvest at the village-season kg-weighted market price; monetary expenses = seeds, fertilizer, booster, manure, chemicals, equipment, transport, hired labor (plot labor, post-harvest, drying, storage) and other post-harvest/drying/storage costs.
  - Table 2 cols 3-5: the add5 sale that consisted only of the household's randomly selected bag (bought by the research team for lab testing, 94 records) is excluded as not a market sale. Measured weight y = sum of enumerator-measured weights (add4_weight_b) of the bags in the sale; agreed weight z = sum of add5_ind_ded_weight; deduction = 100(y-z)/y; net price = price*z/y. Week-of-sale FE from the sale date (year-week). fixest drops 2 singleton observations, so N = 115 of 117 market sales.
  - Table 2 col 1: bags with at least one non-missing visual item (622 of 644 weighed bags); defects counted over dirty, cobs, stones, dust, insects (dead or live), broken, immature, damaged, rotten, mould (value 1 = yes). Col 2: lab defects = (foreign + inorganic + broken + pest-damaged + rotten + discoloured + immature grams)/total sample weight, as a share.
  - UGX->USD conversion fixed at 3,333.33 UGX/USD (paper's stated approximation UGX10,000 ~ US$3); the paper's exact rate is not given.
  - Profit incl. own hours has no pre-treatment value (family hours only collected from season 4/5 on); the ANCOVA for column 8 therefore omits the lagged outcome.
- [blind/claude-code/2026-11-10-d](blind/claude-code/2026-11-10-d/CELL.md) (8/13; failed: `market_access_price_table6_panelA_col1`, `market_access_yield_table6_panelA_col4`, `market_access_harvest_value_table6_panelA_col5`, `market_access_profit_monetary_table6_panelA_col7`, `market_access_profit_incl_own_hours_table6_panelA_col8`)
  - No exchange rate in the data: UGX converted to US dollars at a fixed 3700 UGX/USD (approximate 2017-2020 average), applied to all Table 6 monetary outcomes.
  - Pretreatment value in the ANCOVA = household mean of the outcome over baseline seasons 1-3 (seasons 2-3 for expenses/profit, since hired labour was not collected in season 1); missing pretreatment values set to 0 with a missing indicator. Own-hours profit has no baseline (family hours collected only from season 5), so column 8 is regressed on treatment and season dummies only.
  - Harvest value = sales revenue (seller_data) + unsold harvest valued at the village-season kg-weighted mean price of sales to buyers other than code 555 (taken to be the quality buyer); season mean where the village has no sale.
  - Monetary expenses = seeds, fertilizer, booster, manure, chemicals, equipment/harvest/decobbing costs, drying, storage, other post-harvest costs, hired labour (plot tot_lab_costs + labor_cost_ph) and transport (tot_transport_cost, else pre+post transport); defined only for in-person interviews with the plot module.
  - Own labour valued at a data-derived hourly wage: median hired daily wage (5000 UGX) / median family working day (6 h) = 833 UGX/h; own hours = plot-level family hours for all activities + post-harvest family hours (decob, winnow, sort, bag).
  - Table 2 sales: add5 sale 1 is the research team's purchase of the random lab bag (its bag matches add4_random_bag for 93 of 95), so sales 2-4 are the trader sales. Deduction uses the enumerator-measured bag weight (add4_weight) as y and the post-deduction agreed weight as z; week-of-sale = Stata-style week of year of the sale date. Singleton fixed-effect cells kept (fixef.rm='none') so N counts all 116 sales; the point estimates are the same either way.
  - Visual defects: 10 types (dirty, cobs, stones, dust, dead-or-live insects, broken, immature, insect/vermin damage, rotten, mould); a bag counts if the enumerator recorded its weight; unanswered items counted as no defect. Lab defects = (foreign + inorganic + broken + pest-damaged + rotten + discoloured + immature grams)/sample weight, as a share.

### Pipeline and agent disagree

Claims where, in the same mode, one reproducer family passed in every run and the other failed in every run (pass counts per family).

- seeded: `treatment_deductions_table2_col4` — pipeline 0/3, agent 2/2
- seeded: `treatment_net_price_table2_col5` — pipeline 0/3, agent 2/2
- seeded: `treatment_price_table2_col3` — pipeline 0/3, agent 2/2
- independent: `n_obs_table2_cols3_5_sales` — pipeline 0/4, agent 4/4
- blind: `treatment_deductions_table2_col4` — pipeline 0/4, agent 4/4
- blind: `treatment_defects_lab_table2_col2` — pipeline 0/4, agent 4/4
- blind: `treatment_net_price_table2_col5` — pipeline 0/4, agent 4/4

Pass rates at least 50 points apart (not unanimous):

- seeded: `n_obs_table2_cols3_5_sales` — pipeline 1/3, agent 2/2
- blind: `n_obs_table2_cols3_5_sales` — pipeline 0/4, agent 3/4
- blind: `treatment_price_table2_col3` — pipeline 1/4, agent 4/4

## Cells

### seeded · claude-code · 2026-11-10-a

[`seeded/claude-code/2026-11-10-a/CELL.md`](seeded/claude-code/2026-11-10-a/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T14:48:00Z; from `claude-code-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### seeded · claude-code · 2026-11-10-b

[`seeded/claude-code/2026-11-10-b/CELL.md`](seeded/claude-code/2026-11-10-b/CELL.md) — final 13/13, re-scored 13/13; first scored 13/13; executions 2; 2026-11-10T14:58:00Z; from `claude-code-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus · 20261110T173855Z

[`seeded/pipeline-desktop-opus/20261110T173855Z/CELL.md`](seeded/pipeline-desktop-opus/20261110T173855Z/CELL.md) — final 10/13, re-scored 10/13; first scored 8/13; executions 4; 2026-11-10T17:38:55Z; from `pipeline-oracle-desktop-opus-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run2 · 20261110T215013Z

[`seeded/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md`](seeded/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) — final 9/13, re-scored 9/13; first scored 8/13; executions 3; 2026-11-10T21:50:13Z; from `pipeline-oracle-desktop-opus-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### seeded · pipeline-desktop-opus-run3 · 20261110T215031Z

[`seeded/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md`](seeded/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) — final 9/13, re-scored 9/13; first scored 8/13; executions 3; 2026-11-10T21:50:31Z; from `pipeline-oracle-desktop-opus-run3-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-a

[`independent/claude-code/2026-11-10-a/CELL.md`](independent/claude-code/2026-11-10-a/CELL.md) — final 9/13, re-scored 9/13; first scored 8/13; executions 8; 2026-11-10T14:52:30Z; from `claude-code-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-b

[`independent/claude-code/2026-11-10-b/CELL.md`](independent/claude-code/2026-11-10-b/CELL.md) — final 11/13, re-scored 11/13; first scored 8/13; executions 8; 2026-11-10T16:23:00Z; from `claude-code-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-c

[`independent/claude-code/2026-11-10-c/CELL.md`](independent/claude-code/2026-11-10-c/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 10; 2026-11-10T16:22:30Z; from `claude-code-run3-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

### independent · claude-code · 2026-11-10-d

[`independent/claude-code/2026-11-10-d/CELL.md`](independent/claude-code/2026-11-10-d/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 9; 2026-11-10T16:24:00Z; from `claude-code-run4-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus · 20261110T170624Z

[`independent/pipeline-desktop-opus/20261110T170624Z/CELL.md`](independent/pipeline-desktop-opus/20261110T170624Z/CELL.md) — final 8/13, re-scored 8/13; first scored 3/13; executions 4; 2026-11-10T17:06:24Z; from `pipeline-oracle-desktop-opus-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run2 · 20261110T215013Z

[`independent/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md`](independent/pipeline-desktop-opus-run2/20261110T215013Z/CELL.md) — final 7/13, re-scored 7/13; first scored 2/13; executions 4; 2026-11-10T21:50:13Z; from `pipeline-oracle-desktop-opus-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run3 · 20261110T215031Z

[`independent/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md`](independent/pipeline-desktop-opus-run3/20261110T215031Z/CELL.md) — final 6/13, re-scored 6/13; first scored 2/13; executions 4; 2026-11-10T21:50:31Z; from `pipeline-oracle-desktop-opus-run3-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### independent · pipeline-desktop-opus-run4 · 20261110T215048Z

[`independent/pipeline-desktop-opus-run4/20261110T215048Z/CELL.md`](independent/pipeline-desktop-opus-run4/20261110T215048Z/CELL.md) — final 7/13, re-scored 7/13; first scored 2/13; executions 4; 2026-11-10T21:50:48Z; from `pipeline-oracle-desktop-opus-run4-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-a

[`blind/claude-code/2026-11-10-a/CELL.md`](blind/claude-code/2026-11-10-a/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 6; 2026-11-10T14:50:30Z; from `claude-code-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-b

[`blind/claude-code/2026-11-10-b/CELL.md`](blind/claude-code/2026-11-10-b/CELL.md) — final 7/13, re-scored 7/13; first scored 7/13; executions 4; 2026-11-10T14:50:30Z; from `claude-code-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-c

[`blind/claude-code/2026-11-10-c/CELL.md`](blind/claude-code/2026-11-10-c/CELL.md) — final 9/13, re-scored 9/13; first scored 9/13; executions 4; 2026-11-10T14:50:00Z; from `claude-code-run3-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

### blind · claude-code · 2026-11-10-d

[`blind/claude-code/2026-11-10-d/CELL.md`](blind/claude-code/2026-11-10-d/CELL.md) — final 8/13, re-scored 8/13; first scored 8/13; executions 6; 2026-11-10T14:50:30Z; from `claude-code-run4-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus · 20261110T164122Z

[`blind/pipeline-desktop-opus/20261110T164122Z/CELL.md`](blind/pipeline-desktop-opus/20261110T164122Z/CELL.md) — final 3/13, re-scored 3/13; first scored 3/13; executions 1; 2026-11-10T16:41:22Z; from `pipeline-oracle-desktop-opus-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run2 · 20261110T172233Z

[`blind/pipeline-desktop-opus-run2/20261110T172233Z/CELL.md`](blind/pipeline-desktop-opus-run2/20261110T172233Z/CELL.md) — final 4/13, re-scored 4/13; first scored 4/13; executions 1; 2026-11-10T17:22:33Z; from `pipeline-oracle-desktop-opus-run2-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run3 · 20261110T172243Z

[`blind/pipeline-desktop-opus-run3/20261110T172243Z/CELL.md`](blind/pipeline-desktop-opus-run3/20261110T172243Z/CELL.md) — final 3/13, re-scored 3/13; first scored 3/13; executions 1; 2026-11-10T17:22:43Z; from `pipeline-oracle-desktop-opus-run3-1paper-bold-all-modes-2026-11-10.json`; evidence complete.

### blind · pipeline-desktop-opus-run4 · 20261110T171244Z

[`blind/pipeline-desktop-opus-run4/20261110T171244Z/CELL.md`](blind/pipeline-desktop-opus-run4/20261110T171244Z/CELL.md) — final 3/13, re-scored 3/13; first scored 3/13; executions 1; 2026-11-10T17:12:44Z; from `pipeline-oracle-desktop-opus-run4-1paper-bold-indep-blind-2026-11-10.json`; evidence complete.

