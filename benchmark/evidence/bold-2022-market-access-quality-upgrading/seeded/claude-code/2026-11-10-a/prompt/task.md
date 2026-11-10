# Retally reproduction task: bold-2022-market-access-quality-upgrading (seeded, run 2026-11-10-a)

You are reproducing quantitative results from an econometrics paper for the
Retally benchmark.  You will write R code, run it in a network-less Docker
sandbox, and record what you did as files.  The files are what gets scored.

- Benchmark cell: entry `bold-2022-market-access-quality-upgrading`, mode `seeded`, run `2026-11-10-a`
- Paper: Market Access and Quality Upgrading: Evidence from Four Field Experiments
- Paper text (extracted from the PDF; tables may be garbled): `<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/paper.txt`
- Data (the ONLY data you get): `<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading`
- Output directory (the ONLY place you write): `<repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a`

## Mode rules

These apply in every mode:

- Write R only.  Run it only inside the sandbox, with the command under
  "How to run a script"; never run R on the host.
- No network: do not download anything, do not look the paper or its
  replication package up online.
- Use only the files under `<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading` as data, and `<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/paper.txt` as
  the paper.
- Do not read anything else in this repository or on this machine: not the
  catalog YAMLs under `benchmark/papers/`, not `.cache/datasets/`, not
  `benchmark/results/`, not other reproductions under `benchmark/reproductions/`,
  not other task directories.  If you nevertheless read any other file, list
  it in `files_read_outside_mount` in `reproduction.json`, with why.
- Seeded mode: the authors' own analysis scripts are on disk under the data
  directory and reproduced below under "Original Replication Scripts".  You
  may follow them:

  The replication package (the dataset directory) ships the authors' own analysis scripts,
  reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names,
  sample restrictions, fixed effects, and standard-error clustering — follow them over anything
  reconstructed from the methodology summary, and prefer them over the paper's text where the two
  disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the
  scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression,
  e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call
  in R).  Keep only the parts that produce the specific claims being reproduced; skip figure
  construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's
  internal layout — resolve them against the dataset directory listed under Dataset Information.
- You may compare your `RESULT:` values with the claimed values yourself.
  Every time you do that and then change the script, record the run you
  compared as an attempt with `kind: "claim"`, and write the comparison you
  made to that attempt's `feedback.txt`, one line per off-target claim in
  the form `<name>: reproduced <v>, claimed <c>`.  Produce it with:

      cd <repo> && uv run python -m benchmark.reproducers.check_attempt --run-dir <repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a --stdout <that attempt's stdout.txt>

  At most 3 `kind: "claim"` attempts.
- At most 3 `kind: "error"` repairs (a run that crashed or
  printed no `RESULT:` line, followed by a fix).

## Claims to Reproduce
1. treatment_defects_visual_table2_col1: -2.16 (number of visually verified defect types per bag (out of ten)) [type: coefficient]
   Location: Table 2, column (1) Defects (visually verifiable), Treatment
   Context: Table 2 ("Returns to Quality: Treatment Effects"), column (1). Returns to quality experiment: maize-farming households randomly assigned to a free harvest and postharvest service package (treatment) or not (control). OLS of the number of defect types (out of ten) that trained enumerators visually verified in a bag the household was about to sell, on the treatment indicator with village fixed effects. Unit of observation: a bag (all bags inspected). Standard errors clustered by household.
2. treatment_defects_lab_table2_col2: -0.2 (share of defective grain and waste in the lab sample) [type: coefficient]
   Location: Table 2, column (2) Defects (lab), Treatment
   Context: Table 2, column (2): OLS of laboratory-measured defects (defective grain and waste in the lab sample, which the table notes describe as grams of defects per 200 g of maize; the text reads the coefficient as a percentage-point difference in the share of the content) on the treatment indicator with village fixed effects. Unit of observation: one randomly selected bag bought from each household for lab testing. Robust (heteroskedasticity-consistent) standard errors.
3. treatment_price_table2_col3: 2.95 (Ugandan shillings per kilogram) [type: coefficient]
   Location: Table 2, column (3) Price, Treatment
   Context: Table 2, column (3): OLS of the price received (Ugandan shillings per kilogram) on the treatment indicator, with village and week-of-sale fixed effects. Unit of observation: a maize sale reported in the final household visit. Standard errors clustered by household. The paper reads it as essentially zero: no return to quality.
4. treatment_deductions_table2_col4: 0.18 (percent of the measured weight) [type: coefficient]
   Location: Table 2, column (4) Deductions, Treatment
   Context: Table 2, column (4): OLS of weight deductions, (y - z)/y in percent, where y is the weight of maize sold as measured by enumerators and z the agreed sales volume, on the treatment indicator with village and week-of-sale fixed effects. Unit of observation: a maize sale. Standard errors clustered by household.
5. treatment_net_price_table2_col5: 0.98 (Ugandan shillings per kilogram) [type: coefficient]
   Location: Table 2, column (5) Net price, Treatment
   Context: Table 2, column (5): OLS of the net price (price net of any weight deductions, Ugandan shillings per kilogram) on the treatment indicator with village and week-of-sale fixed effects. Unit of observation: a maize sale. Standard errors clustered by household.
6. n_obs_table2_col1_bags: 622.0 (bags) [type: count]
   Location: Table 2, Observations, column (1)
   Context: Number of observations in Table 2, column (1): the bags visually inspected by enumerators across all households in the returns to quality experiment.
7. n_obs_table2_cols3_5_sales: 116.0 (sales) [type: count]
   Location: Table 2, Observations, columns (3)-(5)
   Context: Number of observations in Table 2, columns (3) to (5): the maize sales recorded in the final visit to the returns to quality households.
8. market_access_price_table6_panelA_col1: 0.017 (US dollars per kilogram) [type: coefficient]
   Location: Table 6, Panel A (Market access experiment), column (1) Price, Access to a market for quality maize
   Context: Table 6 ("Impact on Productivity and Income"), Panel A, column (1). Market access experiment: villages randomly assigned to access to an agricultural trading company that buys maize of sufficient quality at a premium (with extension service), or to control; households surveyed over three baseline and four follow-up seasons. ANCOVA regression on follow-up seasons only: the outcome on the treatment indicator, season dummies and the household's pretreatment value of the outcome. Outcome: average price per kilogram of maize sold, in US dollars. Standard errors clustered by village (the table print…
9. market_access_yield_table6_panelA_col4: 108.9 (kilograms per acre) [type: coefficient]
   Location: Table 6, Panel A (Market access experiment), column (4) Yield, Access to a market for quality maize
   Context: Table 6, Panel A, column (4): the same ANCOVA (treatment, season dummies, pretreatment value of the outcome; follow-up seasons; village-clustered inference) with yield, the maize harvest in kilograms per acre of cultivated land, as the outcome.
10. market_access_harvest_value_table6_panelA_col5: 78.9 (US dollars per season) [type: coefficient]
   Location: Table 6, Panel A (Market access experiment), column (5) Harvest value, Access to a market for quality maize
   Context: Table 6, Panel A, column (5): the same ANCOVA with the harvest value in US dollars as the outcome; harvest value includes own-produced consumption, valued at the community-specific market price.
11. market_access_profit_monetary_table6_panelA_col7: 63.1 (US dollars per season) [type: coefficient]
   Location: Table 6, Panel A (Market access experiment), column (7) Profit (monetary expenses), Access to a market for quality maize
   Context: Table 6, Panel A, column (7): the same ANCOVA with profit (monetary expenses) as the outcome: harvest value minus expenses on inputs, equipment, transport and hired labor, in US dollars.
12. market_access_profit_incl_own_hours_table6_panelA_col8: 97.6 (US dollars per season) [type: coefficient]
   Location: Table 6, Panel A (Market access experiment), column (8) Profit (incl. own hours), Access to a market for quality maize
   Context: Table 6, Panel A, column (8): the same ANCOVA with profit including own hours as the outcome: harvest value minus monetary expenses and the cost of the household's own labor valued at market wages, in US dollars.
13. n_obs_table6_panelA_cols3_5: 658.0 (household-seasons) [type: count]
   Location: Table 6, Panel A, Observations, columns (3)-(5)
   Context: Number of observations in Table 6, Panel A, columns (3) to (5) (harvest, yield, harvest value): household-season observations in the follow-up seasons of the market access experiment.

## Dataset Information
Name: bold_2022_market_access_quality_upgrading
Local path: <repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading
File format: csv
Files in the dataset directory (paths relative to the local path above):
- data/raw/panel_g1.dta (2.4 MB) — 1221 rows, 405 columns: equipment_cost_1, equipment_cost_2, harvest_cost_1, harvest_cost_2, sale_transport_cost_1, sale_transport_cost_2, sale_transport_cost_5, sale_transport_cost_3, equipment_cost_3, equipment_cost_4, equipment_cost_5, harvest_cost_3, harvest_cost_4, harvest_cost_5, lh_prep_hours_unit1, lh_plant_hours_unit1, lh_weed_hours_unit1, lh_spray_hours_unit1, lh_harv_hours_unit1, lh_prep_hours_unit2, lh_plant_hours_unit2, lh_weed_hours_unit2, lh_spray_hours_unit2, lh_harv_hours_unit2, lh_prep_hours_unit3, lh_plant_hours_unit3, lh_weed_hours_unit3, lh_spray_hours_unit3, lh_harv_hours_unit3, lh_prep_hours_unit4, lh_plant_hours_unit4, lh_weed_hours_unit4, lh_spray_hours_unit4, lh_harv_hours_unit4, lh_prep_hours_unit5, lh_plant_hours_unit5, lh_weed_hours_unit5, lh_spray_hours_unit5, lh_harv_hours_unit5, lh_prep_hours_unit6…
- data/raw/panel_g2.dta (1.4 MB) — 953 rows, 307 columns: harvest_cost_1_1, harvest_cost_2_1, harvest_cost_4_1, harvest_cost_5_1, equipment_cost_1, equipment_cost_2, harvest_cost_1, harvest_cost_2, sale_transport_cost_1, sale_transport_cost_2, sale_transport_cost_5, sale_transport_cost_3, equipment_cost_3, equipment_cost_4, equipment_cost_5, harvest_cost_3, harvest_cost_4, harvest_cost_5, labor_cost_transport_1, labor_cost_transport_2, labor_cost_transport_3, survey_season, buy_treatment, survey_round, ext_treatment, lc_decob_price,…
- data/raw/anonym_returns_data.dta (647.5 KB) — 99 rows, 485 columns: treatment, add5_ppk_1, add5_ppk_2, add5_ppk_3, add5_ppk_4, add4_random_bag, add1_harvest_new_when_e_1, Total_weight_of_maize_g, add1_ap_maize_kg_1, Broken_grains_tot_g, Pest_damaged_grains_tot_g, Rotten_and_diseased_grain, Discoloured_grains_tot_g, add5_sold_when_e_1, add5_sold_when_e_2, add5_sold_when_e_3, add5_sold_when_e_4, add5_ind_weight1_1, add5_ind_weight2_1, add5_ind_weight3_1, add5_ind_weight4_1, add5_ind_weight5_1, add5_ind_weight6_1, add5_ind_weight7_1, add5_ind_we…
- data/raw/panel_g0.dta (337.6 KB) — 200 rows, 158 columns: sale_transport_cost_1, sale_transport_cost_2, sale_transport_cost_5, sale_transport_cost_3, survey_season, harvest_kg_tot, sold_kg_tot, tot_transport_cost, labor_cost_store, labor_cost_ph, seeds_cost_1, seeds_cost_2, fert_cost_1, fert_cost_…
- data/raw/maize_quality_gr1.dta (22.4 KB) — 175 rows, 17 columns: treatment, season, sales_no, totalweightofmaizeg, brokengrainstotg, pestdamagedgrainstotg, rottenanddiseasedgrainstotg, discolouredgrainstotg, immatureorshrivelledgrainstotg, ea_code, hhh, hhh_id, foreignmattertotg, inorganicmattertotg, liv…
- data/raw/maize_quality_gr0.dta (14.5 KB) — 60 rows, 16 columns: season, totalweightofmaizeg, brokengrainstotg, pestdamagedgrainstotg, rottenanddiseasedgrainstotg, discolouredgrainstotg, immatureorshrivelledgrainstotg, ea_code, hhh, hhh_id, group, foreignmattertotg, inorganicmattertotg, totalaflatoxins, …
- data/raw/seller_data.dta (61.2 KB) — 1389 rows, 8 columns: price, survey_season, buy_treatment, sold_kg_p_, sold_kg_tot, ea_code, hhh_id, name
- data/raw/buy_data.dta (273.7 KB) — 193 rows, 5 columns: buy_treatment, survey_season, ea_code, hhh_id, status
- README.pdf (100.9 KB)
- dofiles/CONFIG.do (401 B)
- dofiles/FINAL_create_vars_gr0.do (3.1 KB)
- dofiles/FINAL_create_vars_main_g1.do (23.7 KB)
- dofiles/FINAL_create_vars_main_g2.do (26.7 KB)
- dofiles/FINAL_create_vars_returns.do (9.6 KB)
- dofiles/FINAL_create_vars_sellers.do (1.8 KB)
- dofiles/FINAL_master.do (1.0 KB)
- dofiles/XAppendix_figure2.do (3.0 KB)
- dofiles/XAppendix_figure3.do (691 B)
- dofiles/XAppendix_table1.do (4.5 KB)
- dofiles/XAppendix_table10.do (3.4 KB)
- dofiles/XAppendix_table11.do (3.1 KB)
- dofiles/XAppendix_table12.do (7.6 KB)
- dofiles/XAppendix_table13.do (1.8 KB)
- dofiles/XAppendix_table14.do (2.2 KB)
- dofiles/XAppendix_table2.do (1.5 KB)
- dofiles/XAppendix_table3.do (2.2 KB)
- dofiles/XAppendix_table4.do (2.7 KB)
- dofiles/XAppendix_table5.do (6.2 KB)
- dofiles/XAppendix_table6.do (3.1 KB)
- dofiles/XAppendix_table7.do (3.7 KB)
- dofiles/XAppendix_table8.do (2.4 KB)
- dofiles/XAppendix_table9.do (3.4 KB)
- dofiles/figure1.do (1.8 KB)
- dofiles/figure2.do (2.1 KB)
- dofiles/figure3.do (2.5 KB)
- dofiles/figure4.do (5.9 KB)
- dofiles/figure5.do (2.8 KB)
- dofiles/intext_replication.do (13.5 KB)
- dofiles/merge_gr1_gr2.do (1003 B)
- dofiles/permutations.do (651 B)
- dofiles/table1.do (1.8 KB)
- dofiles/table2.do (3.2 KB)
- dofiles/table3.do (3.7 KB)
- dofiles/table4.do (3.4 KB)
- dofiles/table5.do (4.1 KB)
- dofiles/table6.do (3.8 KB)
- dofiles/table7.do (2.1 KB)
- metadata.json (240 B)
- other/Results reported in the main text.pdf (198.3 KB)
- survey_materials/main_survey/survey_instrument_main.xlsx (366.3 KB)
- survey_materials/return_survey/add1_enroll_gps.xlsx (52.1 KB)
- survey_materials/return_survey/add2_description.xlsx (58.7 KB)
- survey_materials/return_survey/add4_measuring_bags.xlsx (64.3 KB)
- survey_materials/return_survey/add5_bags_sales.xlsx (97.0 KB)

## Required Output Convention
Emit each reproduced metric on its own line to stdout using EXACTLY this format:
    RESULT:<metric_name>=<numeric_value>
For example:  cat('RESULT:beta=0.342\n')
Use snake_case metric names matching the claim descriptions.

## Code Requirements
Write a complete, self-contained R script that runs under Rscript.
The dataset is a directory tree at '<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading' — see the file listing under Dataset Information.  Load the actual data file(s) by the exact paths listed there (readr::read_csv() for .csv, haven::read_dta() for Stata .dta, load() for .RData/.rda, which creates the objects listed for the file under exactly those names: use them, do not guess others; readRDS() for .rds).
Installed packages (no network; nothing else can be installed): jsonlite, fixest, lfe, AER, ivreg, plm, estimatr, lme4, quantreg, car, sandwich, lmtest, clubSandwich, multiwayvcov, marginaleffects, MatchIt, optmatch, CBPS, WeightIt, cobalt, did, rdrobust, rddensity, Synth, modelsummary, stargazer, texreg, broom, tidyverse, dplyr, tidyr, readr, stringr, lubridate, data.table, haven, readxl, janitor, zoo, ggplot2, ggridges, ggrepel, gridExtra, cowplot, gtable, extrafont, sf, MASS, nnet, survival, splines, Matrix, boot, stats, utils.
Prefer fixest for fixed effects, IV and clustered SEs; use the other installed packages where the paper's method calls for them.
Set a deterministic seed with ``set.seed(42)`` for any randomness.
Do NOT access the internet; the container runs with --network none.
Do NOT shell out via system() / system2().
Emit RESULT:<name>=<value> lines to stdout at the end via cat().

## Original Replication Scripts
The replication package (the dataset directory) ships the authors' own analysis scripts, reproduced below.  These are the GROUND TRUTH for the exact estimating equation, variable names, sample restrictions, fixed effects, and standard-error clustering — follow them over anything reconstructed from the methodology summary, and prefer them over the paper's text where the two disagree.  Your job is to write R code that implements the SAME SPECIFICATION: translate what the scripts estimate, do not transliterate their syntax line by line (a Stata .do file's regression, e.g. `reghdfe y x controls, absorb(fe) cluster(cl)`, becomes the equivalent fixest::feols() call in R).  Keep only the parts that produce the specific claims being reproduced; skip figure construction and unrelated robustness checks.  The scripts' data-file paths refer to the package's internal layout — resolve them against the dataset directory listed under Dataset Information.

Stata-to-fixest sample matching: feols() drops fixed-effect singletons by default, but Stata's `reg y x i.fe` / `xi:` dummies keep them.  Pass `fixef.rm = "none"` to every feols() call that has fixed effects, otherwise the observation count and the robust SEs drift from the paper's.  Stata's `, r` / `vce(robust)` is `vcov = "hetero"`.

### `dofiles/FINAL_create_vars_main_g1.do`
```stata


use "$repfol\data\raw\panel_g1.dta", replace

*This dofiles generates all avriables for the analysis starting from the variables created by the survey survey_instruemnt_main

*******************************
*******MAIZE ACREAGE **********
*******************************

egen acreage=rowtotal(plot_size_? plot_size_??), missing
replace acreage=0 if acreage==. & maize_tot_plotn==0
replace acreage=acres_tot if survey_season==7 & form_used=="Phone_Market_Survey_spring2020"

*************************************************
*********EXPENSES UP TO AND INCLUDING HARVEST****
*************************************************

*****EQUIPMENT COSTS (ONLY AVAILABLE FOR SPRING 2018)
egen equipment_cost_tot=rowtotal(equipment_cost_?) if survey_season==3, missing

*****************************
****COSTS FOR CHEMICALS *****
*****************************

egen tot_chem_costs=rowtotal(tot_chem_costs_?), missing

****************************
*****INPUTS*****************
**************************** 

*** TYPES OF SEEDS

*dummy for type of seeds
foreach seedtype in own opv hybrid rechyb {
di "`seedtype'"
local numplot=0
foreach var of varlist seeds_types_? {
local numplot=`numplot'+1
}
foreach num of numlist 1/`numplot' {
cap gen `seedtype'_seeds_`num'_dummy=.
replace `seedtype'_seeds_`num'_dummy=strmatch(seeds_types_`num',"*`seedtype'*") if    seeds_types_`num'!="" & seeds_types_`num'!="dk"
}
}

***dummy for whether they use any modern seeds
local numplot=0
foreach var of varlist hybrid_seeds_?_dummy {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
gen modern_seeds_`num'_dummy=(opv_seeds_`num'_dummy==1 | hybrid_seeds_`num'_dummy==1 | rechyb_seeds_`num'_dummy==1) if (opv_seeds_`num'_dummy!=. | hybrid_seeds_`num'_dummy!=. | rechyb_seeds_`num'_dummy!=.) 
}

egen modern_seeds_any=rowmax(modern_seeds_?_dummy) 


***phone survey

replace modern_seeds_any=1 if (seeds_type=="hybrid" | seeds_type=="rechyb" | seeds_type=="opv") & survey_season==7 & form_used=="Phone_Market_Survey_spring2020"
replace modern_seeds_any=0 if (seeds_type=="own") & survey_season==7 & form_used=="Phone_Market_Survey_spring2020"


****cost of modern seeds per plot
local numplot=0 
foreach var of varlist seeds_cost_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
gen modern_seeds_`num'_cost=seeds_cost_`num'*modern_seeds_`num'_dummy 
}
****total cost of modern seeds

egen modern_seeds_cost_tot=rowtotal(modern_seeds_?_cost), missing

replace modern_seeds_cost_tot=seeds_cost if modern_seeds_any==1 & survey_season==7 & form_used=="Phone_Market_Survey_spring2020"
replace modern_seeds_cost_tot=0 if modern_seeds_any==0 & survey_season==7 & form_used=="Phone_Market_Survey_spring2020"


***total cost of seeds 
egen seeds_cost_tot=rowtotal(seeds_cost_?) if  survey_season>=2, missing
replace seeds_cost_tot=seeds_cost if  survey_season==7 & form_used=="Phone_Market_Survey_spring2020"

*** FERTILIZER
*fertilizer dummy per plot S17 &round 1 F17
local numplot=0
foreach var of varlist fert_spec_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
gen fert_`num'_dummy=fert_spec_`num'!="no" if fert_spec_`num'!="" & survey_season==1 
}

***Create fertilizer dummy per plot
local numplot=0
foreach var of varlist fert_kg_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
replace fert_`num'_dummy=fert_kg_`num'>0 if plot_size_`num'!=. & fert_kg_`num'!=. & survey_season>=2
}

**there are two households who have a cost whose fertilizer kg is missing, create the dummy on the basis of cost. 
replace fert_1_dummy=fert_cost_1>0 if hhh_id==10235043 & survey_season==4
replace fert_2_dummy=fert_cost_2>0 if hhh_id==10078039 & survey_season==7


****total cost of fertilizer

egen fert_cost_tot=rowtotal(fert_cost_?) if  survey_season>=2, missing

*phone survey 
replace fert_cost_tot=fert_cost if   survey_season==7 & form_used=="Phone_Market_Survey_spring2020"

****fertilizer dummy 
egen fert_any=rowmax(fert_?_dummy) 
replace fert_any=(fert_cost_tot>0) if fert_cost_tot!=. &  survey_season==7& form_used=="Phone_Market_Survey_spring2020" 


******************************************************
**********Manure and Booster   ***********************
******************************************************

foreach input in manure booster {
egen `input'_kg_tot=rowtotal(`input'_kg_?) if survey_season>=2, missing
egen `input'_cost_tot=rowtotal(`input'_cost_?) if survey_season>=2, missing
}
***and phone survey 
replace booster_cost_tot=booster_cost if  survey_season==7  & form_used=="Phone_Market_Survey_spring2020"

/*fill in zeros*/
replace manure_cost_tot=0 if manure_cost_tot==. & acreage!=0 & acreage!=. & (survey_season==4 | survey_season==6 | (survey_season==7& form_used=="Market_Survey_spring2020" ))

egen expenses_inputs_ugx=rowtotal(tot_chem_costs booster_cost_tot fert_cost_tot seeds_cost_tot manure_cost_tot), missing

egen expenses_fert_seeds_ugx=rowtotal(fert_cost_tot modern_seeds_cost_tot), missing

label var modern_seeds_any "Any modern seeds"
label var fert_any "Any fertilizer"

****Harvest cost 
egen harvest_cost_tot=rowtotal(harvest_cost_?) if ((survey_season==2) | survey_season==3 ), missing


********************************
********HARVESTED AMOUNT********
********************************


egen harvest_kg_tot=rowtotal(harvest_kg_? ), missing

replace harvest_kg_tot=harvest_kg if season_spring2020==1 & form_used=="Phone_Market_Survey_spring2020"

***YIELD
gen yield=harvest_kg_tot/acreage 
/*there is one person who does not know their harvest on plot 2, so calculate yield as harvest_1/plot_1*/
replace yield=harvest_kg_1/plot_size_1 if hhh_id==10247005 & season_spring2018==1
*these two households do not the size of their first plot, so need to calculate yield on basis of second plot
replace yield=harvest_kg_2/plot_size_2 if (hhh_id==10165041 | hhh_id==10231013) & survey_season==5

**********************************************************
************POST-HARVEST COSTS ***************************
**********************************************************

*****STORING, DRYING
*storage_cost
*drying_cost
*otherph_cost
***ensure missing for those who do not grow maize
replace storage_cost=. if acreage==0 
replace drying_cost=. if acreage==0
replace otherph_cost=. if acreage==0

*****Dry on tarpaulin

gen tarpaulin_d=strmatch(dry_how,"*tarpaulin*")  if survey_season>=2 & dry_how!=""


*****DECOBBING, WINNOWING, SORTING, BAGGING
egen decobbing_cost_tot=rowtotal(decobbing_cost_?) if survey_season==2, missing
*and missing for those who don't grow maize 
replace decobbing_cost_tot=. if acreage==0 


*************************************************
**LABOUR COSTS
*************************************************

*****LABOR COSTS UP TO AND INCLUDING HARVEST
foreach activity in prep plant weed spray harv {
egen labor_cost_`activity'_tot=rowtotal(lc_`activity'_costs_season?) if survey_season!=1, missing
}

/**some missings that should be zeros*/
replace labor_cost_prep_tot=0 if labor_cost_prep_tot==. & acreage!=0 & acreage!=. & survey_season==5
replace labor_cost_plant_tot=0 if labor_cost_plant_tot==. & acreage!=0 & acreage!=. & survey_season==5
replace labor_cost_weed_tot=0 if labor_cost_weed_tot==. & acreage!=0 & acreage!=. & survey_season==5
replace labor_cost_spray_tot=0 if labor_cost_spray_tot==. & acreage!=0 & acreage!=. & survey_season==5
replace labor_cost_harv_tot=0 if labor_cost_harv_tot==. & acreage!=0 & acreage!=. & survey_season==5
replace labor_cost_ph=. if acreage==0 
replace labor_cost_store=0 if labor_cost_store==. & storage!="" & survey_season>=5


***and create total cost up to but excluding harvest
egen expenses_labor_preharvest_ugx=rowtotal(labor_cost_prep_tot labor_cost_plant_tot labor_cost_spray_tot labor_cost_weed_tot) if survey_season!=1 &survey_season!=4& form_used!="Phone_Market_Survey_spring2020", missing
label var expenses_labor_preharvest_ugx "Labour costs pre-harvest (UGX)"

***and also generate the total costs inluding harvest here: 
egen tot_lab_costs_preh_aggh_tot=rowtotal(tot_lab_costs_?) if survey_season>=4, missing
replace  tot_lab_costs_preh_aggh_tot=expenses_labor_preharvest_ugx+labor_cost_harv_tot if survey_season==2|survey_season==3
label var tot_lab_costs_preh_aggh_tot "Labour costs pre-harvest and harvest (UGX)"


*****LABOR HOURS UP TO AND INCLUDING HARVEST
foreach act in prep plant spray weed harv{
egen `act'_unpaid_lab_tothrs=rowtotal(lh_`act'_hours_season?) if survey_season>=5, missing
}

/*replace missings that should be zero*/
replace spray_unpaid_lab_tothrs=0 if spray_unpaid_lab_tothrs==. & acreage!=0 & acreage!=. & survey_season==5

egen  tot_lab_hours_preh_aggh_tot=rowtotal(prep_unpaid_lab_tothrs plant_unpaid_lab_tothrs weed_unpaid_lab_tothrs spray_unpaid_lab_tothrs harv_unpaid_lab_tothrs) if survey_season>=5, missing   

label var tot_lab_hours_preh_aggh_tot "Labour hours pre-harvest and harvest (UGX)"


****hourly wage calculation****
foreach act in prep plant weed harv{
    forvalues n=1/6{
	    cap confirm variable lc_`act'_unit`n'
		if !_rc   gen dailycost_`act'_`n'=  lc_`act'_costs_unit`n' if lc_`act'_unit`n'=="days"
	    cap confirm variable lh_`act'_hours_unit`n'
		if !_rc   gen dailyhours_`act'_`n'=  lh_`act'_hours_unit`n' if lh_`act'_unit`n'=="days"
}
egen med_dailycost_`act'=rowmedian(dailycost_`act'_?)
egen med_dailyhours_`act'=rowmedian(dailyhours_`act'_?)
}
egen med_dailycost=rowmedian(med_dailycost_*)
egen med_dailyhours=rowmedian(med_dailyhours_*)
egen dailyhours=mode(med_dailyhours)
sum dailyhours
local dailyhours = r(mean)
egen daylywage=mode(med_dailycost)
sum daylywage
local hourlywage=round(r(mean)/`dailyhours', 1) 
dis `hourlywage'

gen preh_unpaid_lab_aggh_sh= tot_lab_hours_preh_aggh_tot*`hourlywage'

*****LABOR COSTS POST HARVEST
*labor_cost_ph

label var otherph_cost "Other post-harvest cost, non-labor" 
label var labor_cost_ph "Total hired labor post-harvest cost"

* SPRING 2019, Fall 2019, Spring 2020
foreach var of varlist decob winnow sort bag {
gen `var'_d=(`var'=="yes") if `var'!="" & survey_season>=5
}
foreach activity in decob winnow sort bag {
replace lh_`activity'_hours=0 if lh_`activity'_hours==. & `activity'_d!=. & survey_season>=5
replace lc_`activity'_labour_costs=0 if lc_`activity'_labour_costs==. & `activity'_d!=. & survey_season>=5
replace lc_`activity'_other_costs=0 if lc_`activity'_other_costs==. & `activity'_d!=. & survey_season>=5
}

foreach activity in decob winnow sort bag {
gen lh_`activity'_hours_sh=lh_`activity'_hours*833 if survey_season>=5
}
foreach activity in decob winnow sort bag {
gen lc_`activity'_lmtot_costs=lc_`activity'_labmaize_costs*lc_`activity'_price if survey_season>=5
replace lc_`activity'_lmtot_costs=0 if lc_`activity'_lmtot_costs==. & `activity'_d!=. & survey_season>=5
}
*total cost was entered into lc_decob_labmaize_costs, entering it into lc_decob_lmtot_costs
replace lc_decob_lmtot_costs=lc_decob_labmaize_costs if hhh_id==10247077 & survey_season==7
replace lc_bag_lmtot_costs=lc_bag_labmaize_costs if hhh_id==10247013 & survey_season==7


/*for Spring 2019 and Fall 2019 and Spring 2020*/

foreach activity in decob winnow sort bag {
egen `activity'_cost_tot=rowtotal(lc_`activity'_labour_costs lc_`activity'_lmtot_costs lc_`activity'_other_costs), missing
}
*and create the total expenses disaggregated 
foreach activity in decob winnow sort bag {
egen labor_`activity'_cost_tot=rowtotal(lc_`activity'_labour_costs lc_`activity'_lmtot_costs), missing
}

*labour cost postharvest, including harvest
egen  expenses_labor_postharvest_ugx=rowtotal(labor_cost_harv_tot labor_cost_store lc_decob_labour_costs lc_sort_labour_costs lc_winnow_labour_costs lc_bag_labour_costs) if survey_season>=5 & form_used!="Phone_Market_Survey_spring2020", missing

egen  expenses_labor_posth_ugx_pre=rowtotal(labor_cost_harv_tot labor_cost_ph labor_cost_dry labor_cost_store) if survey_season==2|survey_season==3, missing
replace expenses_labor_postharvest_ugx=  expenses_labor_posth_ugx_pre if survey_season==2|survey_season==3
drop   expenses_labor_posth_ugx_pre

**total cost post harvest
egen  expenses_postharvest_ugx=rowtotal(labor_cost_harv_tot decob_cost_tot winnow_cost_tot sort_cost_tot bag_cost_tot drying_cost storage_cost labor_cost_store) if survey_season>=5 & form_used!="Phone_Market_Survey_spring2020", missing	

egen  expenses_postharvest_ugx_pre=rowtotal(labor_cost_harv_tot harvest_cost_tot storage_cost drying_cost otherph_cost labor_cost_ph labor_cost_dry labor_cost_store decobbing_cost_tot) if survey_season==2|survey_season==3, missing

replace  expenses_postharvest_ugx= expenses_postharvest_ugx_pre if survey_season==2|survey_season==3,
drop  expenses_postharvest_ugx_pre



*****HOME USE OF MAIZE

*home_kg

********************************
******MAIZE SELLING TOTALS******
********************************

*****SELLING IN 2016
egen sold_kg_tot=rowtotal(sold_kg_p_?) , missing
replace sold_kg_tot=sold_kg if survey_season==7 & form_used=="Phone_Market_Survey_spring2020"

/*these are all households who harvested, but who did not sell, so should have zero*/
replace sold_kg_tot=0 if hhh_id==10249047 & survey_season==1
replace sold_kg_tot=0 if hhh_id==10328006 & survey_season==1
replace sold_kg_tot=0 if hhh_id==10165056 & survey_season==2 & survey_round==1 
replace sold_kg_tot=0 if hhh_id==10235011 & survey_season==2 & survey_round==1 
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==2 & survey_round==2 
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==3

replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==5 & sold_crop=="no"
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==6  & sold_crop=="no"
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==7 & sold_crop=="no" & form_used=="Market_Survey_spring2020"
/*sold_kg_tot was zero but they did not plant maize, so should be missing */
replace sold_kg_tot=. if hhh_id==10235035 & season_spring2020==1

replace sold_crop="no" if (hhh_id==10078042 | hhh_id==10181008 ///
 | hhh_id==10181009 | hhh_id==10231001 | hhh_id==10247021 | hhh_id==10326064 ///
| hhh_id==10328005 | hhh_id==10328014 | hhh_id==10328034 | hhh_id==10350040) & survey_season==4
replace sold_kg_tot=0 if (hhh_id==10078042 | hhh_id==10181008 ///
 | hhh_id==10181009 | hhh_id==10231001 | hhh_id==10247021 | hhh_id==10326064 ///
| hhh_id==10328005 | hhh_id==10328014 | hhh_id==10328034 | hhh_id==10350040) & survey_season==4

replace sold_crop="no" if (hhh_id==10219013 | hhh_id==10231002) & survey_season==5
replace sold_kg_tot=0 if (hhh_id==10219013 | hhh_id==10231002) & survey_season==5

replace sold_crop="no" if (hhh_id==10354079) & survey_season==5
replace sold_kg_tot=0 if (hhh_id==10354079) & survey_season==5


gen share_sold=sold_kg_tot/harvest_kg_tot



********Transport cost to buyer****

foreach num of numlist 1 2 3 5 {
replace sale_transport_cost_`num'=0 if sale_transport_yn_`num'=="no" & survey_season>=3
}
egen sale_transport_cost_tot=rowtotal(sale_transport_cost_?) if survey_season>=3, missing
 

****and the total revenue overall
egen rev_tot=rowtotal(tot_rev_combined_?_? tot_rev_combined_?) , missing
replace rev_tot=tot_rev_told_tot if form_used=="Phone_Market_Survey_spring2020"
replace rev_tot=0 if harvest_kg_tot!=. & rev_tot==. & sold_kg_tot==0 

****and generate the average price over all sales
gen price_ugx=rev_tot/sold_kg_tot 

**************************************************************
*****impute price for those who do not sell*******************
************************************************************** 

by ea_code survey_season, sort: egen price_vm=mean(price_ugx) 

egen ea_season=group(ea_code survey_season)
xtset, clear
xfill price_vm, i(ea_season)

xtset hhh_id survey_season

****Harvest value

***for farmers who sold
gen remainder=harvest_kg_tot-sold_kg_tot

***unsold harvest is valued at average village price
gen  harvest_value_ugx=rev_tot+remainder*price_vm if remainder>=0 
***remainder is not valued if sales exceed harvest
replace  harvest_value_ugx=harvest_kg_tot*price_ugx if remainder<0 
*This person didn't give a revenue (although they sold), so we value their harvest. 
replace harvest_value_ugx=harvest_kg_tot*price_vm if hhh_id==10249026  & survey_season==3

**************************
*****EXPENSES ************
**************************
egen expenses_season_fall2017=rowtotal(seeds_cost_tot fert_cost_tot booster_cost_tot manure_cost_tot  tot_chem_costs expenses_labor_preharvest_ugx labor_cost_harv_tot harvest_cost_tot decobbing_cost_tot storage_cost drying_cost otherph_cost labor_cost_ph  cost_transportpre cost_transportpost) if survey_season==2, missing

egen expenses_season_spring2018=rowtotal(seeds_cost_tot fert_cost_tot manure_cost_tot booster_cost_tot equipment_cost_tot expenses_labor_preharvest_ugx labor_cost_harv_tot tot_chem_costs harvest_cost_tot storage_cost drying_cost otherph_cost labor_cost_ph labor_cost_dry labor_cost_store cost_transportpre cost_transportpost sale_transport_cost_tot) if survey_season==3, missing

egen expenses_season_fall2018=rowtotal(fert_cost_tot tot_chem_costs seeds_cost_tot booster_cost_tot manure_cost_tot tot_lab_costs_preh_aggh_tot  drying_cost storage_cost labor_cost_store otherph_cost labor_cost_ph tot_transport_cost sale_transport_cost_tot) if survey_season==4, missing

egen expenses_season_spring2019=rowtotal(fert_cost_tot  seeds_cost_tot booster_cost_tot manure_cost_tot  tot_chem_costs expenses_labor_preharvest_ugx labor_cost_harv_tot drying_cost storage_cost labor_cost_store cost_transportpre cost_transportpost sale_transport_cost_tot decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==5, missing

egen expenses_season_fall2019=rowtotal(fert_cost_tot  seeds_cost_tot booster_cost_tot manure_cost_tot   tot_chem_costs expenses_labor_preharvest_ugx labor_cost_harv_tot drying_cost storage_cost labor_cost_store cost_transportpre cost_transportpost sale_transport_cost_tot decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==6, missing

egen expenses_season_spring2020=rowtotal(fert_cost_tot  seeds_cost_tot booster_cost_tot manure_cost_tot   tot_chem_costs expenses_labor_preharvest_ugx labor_cost_harv_tot drying_cost storage_cost labor_cost_store cost_transportpre cost_transportpost sale_transport_cost_tot decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==7 & form_used=="Market_Survey_spring2020" , missing

 egen expenses_season_spring2020_ps=rowtotal(fert_cost_tot seeds_cost_tot booster_cost_tot) if survey_season==7 & form_used=="Phone_Market_Survey_spring2020" , missing

egen expenses_hours_season_spring2019=rowtotal(fert_cost_tot tot_chem_costs seeds_cost_tot booster_cost_tot manure_cost_tot   expenses_labor_preharvest_ugx labor_cost_harv_tot preh_unpaid_lab_aggh_sh  drying_cost storage_cost labor_cost_store cost_transportpre cost_transportpost sale_transport_cost_tot lh_decob_hours_sh lh_sort_hours_sh lh_winnow_hours_sh lh_bag_hours_sh decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==5, missing

egen expenses_hours_season_fall2019=rowtotal(fert_cost_tot tot_chem_costs seeds_cost_tot booster_cost_tot manure_cost_tot   expenses_labor_preharvest_ugx labor_cost_harv_tot   preh_unpaid_lab_aggh_sh  drying_cost storage_cost labor_cost_store  cost_transportpre cost_transportpost  sale_transport_cost_tot lh_decob_hours_sh lh_sort_hours_sh lh_winnow_hours_sh lh_bag_hours_sh decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==6, missing

egen expenses_hours_season_spring2020=rowtotal(fert_cost_tot tot_chem_costs seeds_cost_tot booster_cost_tot manure_cost_tot   expenses_labor_preharvest_ugx labor_cost_harv_tot   preh_unpaid_lab_aggh_sh drying_cost storage_cost labor_cost_store cost_transportpre cost_transportpost  sale_transport_cost_tot lh_decob_hours_sh lh_sort_hours_sh lh_winnow_hours_sh lh_bag_hours_sh decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==7 & form_used=="Market_Survey_spring2020" , missing

gen expenses_ugx=.
foreach season in season_fall2017 season_spring2018 season_fall2018 season_spring2019 season_fall2019  season_spring2020{
replace expenses_ugx=expenses_`season' if `season'==1
}
*remove because we only collected input expenses, so cannot calculate a comparable surplus
replace expenses_ugx=. if season_spring2020==1 & form_used=="Phone_Market_Survey_spring2020"
* for post-season, where hours were collected
gen expenses_hours_ugx=.
foreach season in  season_spring2019 season_fall2019 season_spring2020 {
replace expenses_hours_ugx=expenses_hours_`season' if `season'==1
} 
* for pre-seasons, where we have expenses, as ANCOVA control
foreach season in season_fall2017 season_spring2018 {
replace expenses_hours_ugx=expenses_`season' if `season'==1
} 

gen surplus_ugx= harvest_value_ugx-expenses_ugx
gen surplus_hrs_ugx= harvest_value_ugx-expenses_hours_ugx 

**Create own hours and hired hours and expenses
egen ownhours=rowtotal( tot_lab_hours_preh_aggh_tot lh_decob_hours lh_sort_hours lh_winnow_hours lh_bag_hours), missing
egen ownhours_expenses_ugx=rowtotal( preh_unpaid_lab_aggh_sh lh_decob_hours_sh lh_sort_hours_sh lh_winnow_hours_sh lh_bag_hours_sh), missing 
*create hired labor expenses
egen hired_labor_expenses_f17=rowtotal(  expenses_labor_preharvest_ugx labor_cost_harv_tot  labor_cost_ph cost_transportpre cost_transportpost) if survey_season==2, missing
egen hired_labor_expenses_s18=rowtotal(  expenses_labor_preharvest_ugx labor_cost_harv_tot  labor_cost_ph labor_cost_dry labor_cost_store) if survey_season==3, missing
egen hired_labor_expenses_f18=rowtotal( tot_lab_costs_preh_aggh_tot labor_cost_store labor_cost_ph) if survey_season==4, missing
egen hired_labor_expenses_ugx=rowtotal(  expenses_labor_preharvest_ugx labor_cost_harv_tot  labor_cost_store lc_decob_labour_costs lc_winnow_labour_costs lc_decob_labour_costs lc_bag_labour_costs) if season_post==1 & survey_season!=4, missing
replace hired_labor_expenses_ugx=hired_labor_expenses_f17 if survey_season==2
replace hired_labor_expenses_ugx=hired_labor_expenses_s18 if survey_season==3
replace hired_labor_expenses_ugx=hired_labor_expenses_f18 if survey_season==4
*get hours by dividing by hourly wage
gen hiredhours= hired_labor_expenses_ugx/833


foreach var in price harvest_value expenses expenses_hours surplus surplus_hrs expenses_fert_seeds ownhours_expenses  expenses_inputs  expenses_labor_preharvest  expenses_postharvest expenses_labor_postharvest {
gen `var'=.
replace `var' =`var'_ugx/3575 if survey_season==1
replace `var' =`var'_ugx/3601 if survey_season==2
replace `var' =`var'_ugx/3626 if survey_season==3
replace `var' =`var'_ugx/3758 if survey_season==4
replace `var' =`var'_ugx/3670 if survey_season==5
replace `var' =`var'_ugx/3685 if survey_season==6
replace `var' =`var'_ugx/3681 if survey_season==7
replace `var' =`var'_ugx/3685 if survey_season==8
}	

*harvest
gen harvest_ton=harvest_kg_tot/1000

*yield
gen yield_ha_ton=yield*2.47105/1000

destring main_road_min, replace


keep hhh_id ea_code survey_season buy_treatment group season_spring2017 season_fall2017 season_spring2018 season_fall2018 season_spring2019 season_fall2019 season_spring2020  season_ante season_post mdm_female mdm_primary  hhr_n distance_kakumiro main_road_min    acreage expenses harvest_ton harvest_kg_tot yield_ha_ton yield share_sold  price harvest_value surplus surplus_hrs expenses_fert_seeds expenses_inputs tarpaulin_d sort_d winnow_d expenses_labor_preharvest  expenses_postharvest expenses_labor_postharvest  modern_seeds_any fert_any  ownhours ownhours_expenses hiredhours 

mmerge hhh_id survey_season using "$repfol\data\raw\buy_data.dta"
save "$repfol\data\end\panel_g1_analysis.dta", replace





```

### `dofiles/FINAL_create_vars_main_g2.do`
```stata
clear all
set maxvar 10000

use "$repfol\data\raw\panel_g2.dta", clear



*******************************
*******MAIZE ACREAGE **********
*******************************

egen acreage=rowtotal(plot_size_? plot_size_??), missing
replace acreage=0 if acreage==. & maize_tot_plotn==0
/*There are three households who are not growing maize and do not know their plot size. They should have zero acreage*/
replace acreage=0 if acreage==. & maize_tot_plotn==. & survey_season==2
replace acreage=acres_tot if (survey_season==7|survey_season==8) & inlist(form_used, "Phone_Market_Survey_spring2020", "Short_Market_Survey_spring2020", "Short_Market_Survey_fall2020")



******************************************************
****CHEMIC COSTS *****
******************************************************

***S18, F18 and S19
egen tot_chem_costs_tot=rowtotal(tot_chem_costs_?) if ( survey_season==3| survey_season==4 | survey_season==6 ), missing

***and S20 and F20 
replace tot_chem_costs_tot=tot_chem_costs if (survey_season==7 | survey_season==8 )
*missing when not growing maize
replace tot_chem_costs_tot=. if acreage==0 & (survey_season==7 | survey_season==8)

****************************
*****INPUTS*****************
**************************** 

*fertilizer dummy per plot F17
local numplot=0
foreach var of varlist fert_spec_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
gen fert_`num'_dummy=fert_spec_`num'!="no" if fert_spec_`num'!="" & survey_season==2
}

***S18, F18, F19 per plot dummy 
local numplot=0
foreach var of varlist fert_kg_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
replace fert_`num'_dummy=fert_kg_`num'>0 if fert_kg_`num'!=. &plot_size_`num'!=. &  ( survey_season==3 |  survey_season==4 | survey_season==6)
}



*** TYPES OF SEEDS, this is only for maize plots

foreach seedtype in own opv hybrid rechyb {
di "`seedtype'"
local numplot=0
foreach var of varlist seeds_types_? {
local numplot=`numplot'+1
}
foreach num of numlist 1/`numplot' {
cap gen `seedtype'_seeds_`num'_dummy=.
replace `seedtype'_seeds_`num'_dummy=strmatch(seeds_types_`num',"*`seedtype'*") if  ( survey_season==2 | survey_season==4 | survey_season==3 | survey_season==6 ) & seeds_types_`num'!="" & seeds_types_`num'!="dk"
}
}

***and create a dummy per plot for whether they used modern versus own seeds
local numplot=0
foreach var of varlist hybrid_seeds_?_dummy {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
gen modern_seeds_`num'_dummy=(opv_seeds_`num'_dummy==1 | hybrid_seeds_`num'_dummy==1 | rechyb_seeds_`num'_dummy==1) if (opv_seeds_`num'_dummy!=. | hybrid_seeds_`num'_dummy!=. | rechyb_seeds_`num'_dummy!=.) & ( survey_season==2 | survey_season==3 |  survey_season==4 |  survey_season==6 )
}
local numplot=0 
foreach var of varlist seeds_kg_? {
local numplot=`numplot'+1
}
*and amounts and costs
forvalues num=1(1)`numplot' {
gen modern_seeds_`num'_kg=seeds_kg_`num'*modern_seeds_`num'_dummy if  (survey_season==3 |  survey_season==4 |  survey_season==6 | survey_season==7)
gen modern_seeds_`num'_cost=seeds_cost_`num'*modern_seeds_`num'_dummy if  (survey_season==3 |  survey_season==4 |  survey_season==6 | survey_season==7)
}


egen modern_seeds_kg_tot=rowtotal(modern_seeds_?_kg) if  ( survey_season==2 | survey_season==3 |  survey_season==4 |  survey_season==6 ), missing
egen modern_seeds_cost_tot=rowtotal(modern_seeds_?_cost) if  ( survey_season==2 | survey_season==3 |  survey_season==4 |  survey_season==6 ), missing
egen modern_seeds_any=rowmax(modern_seeds_?_dummy) if  ( survey_season==2 | survey_season==3 |  survey_season==4 |  survey_season==6 )

***phone survey & short market surveys (spring 2020, fall 2020)
replace modern_seeds_any=1 if (seeds_type=="hybrid" | seeds_type=="rechyb" | seeds_type=="opv" | seeds_type=="hybrid rechyb" | seeds_type=="own hybrid" | seeds_type=="own opv" | seeds_type=="own rechyb") & (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")
replace modern_seeds_any=0 if (modern_seeds_any!=1 & seeds_kg!=.) & (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")

replace modern_seeds_kg_tot=seeds_kg*modern_seeds_any if (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")
replace modern_seeds_cost_tot=seeds_cost if modern_seeds_any==1 & (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")
replace modern_seeds_cost_tot=0 if modern_seeds_any==0 & (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")

***total cost of seeds 
egen seeds_cost_tot=rowtotal(seeds_cost_?) if  ( survey_season==3 |  survey_season==4 | survey_season==6 ), missing
replace seeds_cost_tot=seeds_cost if (survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")

replace seeds_cost_tot=0 if acreage!=0 & acreage!=. & seeds_cost==. &(survey_season==7 |survey_season==8) & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")


****and generate overall kilograms of fertilizer

egen fert_kg_tot=rowtotal(fert_kg_?) if (survey_season==3 |  survey_season==4 | survey_season==6 | survey_season==7), missing


replace fert_kg_tot=fert_kg  if (survey_season==7 | survey_season==8)

**In Season 7 booster costs are collected as part of fertilizer costs. Divide into fertilizer and booster cost below**
replace fert_kg_tot=0 if (fert_type=="boosters" | fert_type=="boosters other") & (survey_season==7 | survey_season==8)
replace fert_kg_tot=0 if acreage!=0 & acreage!=. & fert_kg_tot==. & (survey_season==7 | survey_season==8)

egen fert_cost_tot=rowtotal(fert_cost_?) if  ( survey_season==3 |  survey_season==4 | survey_season==6), missing
replace fert_cost_tot=fert_cost if (survey_season==7  | survey_season==8)
replace fert_cost_tot=0 if (fert_type=="boosters"| fert_type=="boosters other")  & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")
replace fert_cost_tot=0 if acreage!=0 & acreage!=. & fert_cost_tot==. & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")

egen fert_any=rowmax(fert_?_dummy) 
replace fert_any=(fert_kg_tot>0) if fert_kg_tot!=. & (survey_season==7 | survey_season==8)
*Read in cost for this observation
replace fert_any=1 if hhh_id==10985060 & survey_season==8
replace fert_cost_tot=fert_cost if hhh_id==10985060 & survey_season==8
*Correct dummy for this observation
replace fert_any=0 if hhh_id==10975001 & survey_season==4
replace fert_cost_tot=0 if hhh_id==10975001 & survey_season==4 


******************************************************
**********Manure and Booster   ***********************
******************************************************
local numplot=0
foreach var of varlist manure_cost_? {
local numplot=`numplot'+1
}
forvalues num=1(1)`numplot' {
replace manure_cost_`num'=0 if manure_kg_`num'==0 & manure_cost_`num'==. & plot_size_`num'!=. & ( survey_season==3)
}
*F17, S18, F18
foreach input in manure booster {
egen `input'_cost_tot=rowtotal(`input'_cost_?) if (survey_season==6 | ( survey_season==2 ) | survey_season==3 |  survey_season==4 ), missing
}
*S20
replace booster_cost_tot=fert_cost if survey_season==7 & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020")
replace booster_cost_tot=0 if fert_type!="" & fert_type!="boosters" &  acreage!=. &(form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020")
replace booster_cost_tot=. if acreage==0  & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020")

*F20
replace booster_cost_tot=booster_cost if survey_season==8 
*
replace booster_cost_tot=0 if fert_type!="" & fert_type!="boosters" & acreage!=. &(form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020")
replace booster_cost_tot=. if acreage==0  & (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020")
replace booster_cost_tot=0 if booster_kg==. & acreage!=. & acreage!=0 & survey_season==8
replace booster_cost_tot=. if acreage==0 & survey_season==8
/*split costs for booster and fertilizer appropriately */
replace booster_cost_tot=120000 if hhh_id==10029019&survey_season==7
replace fert_cost_tot=300000 if hhh_id==10029019&survey_season==7
*Divide booster and fertilizer cost
replace booster_cost_tot=fert_cost_tot  if hhh_id==10153002 & survey_season==7
replace fert_kg_tot=0 if hhh_id==10153002 & survey_season==7
replace fert_cost_tot=0  if hhh_id==10153002 & survey_season==7
replace fert_any=0 if hhh_id==10153002 & survey_season==7

/*replace missings that should be zero*/
replace manure_cost_tot=0 if manure_cost_tot==. & acreage!=0 & acreage!=. & (survey_season==3)

*two aggregates
egen expenses_fert_seeds_ugx=rowtotal(fert_cost_tot modern_seeds_cost_tot), missing
egen expenses_inputs_ugx=rowtotal(fert_cost_tot seeds_cost_tot tot_chem_costs_tot booster_cost_tot manure_cost_tot), missing

label var modern_seeds_any "Any modern seeds"
label var fert_any "Any fertilizer"


****Harvest cost 
egen harvest_cost_tot=rowtotal(harvest_cost_?) if (survey_season==3 ), missing
*

egen harvest_kg_tot=rowtotal(harvest_kg_? ) if (  survey_season==2 | survey_season==3 |  survey_season==4 | survey_season==6 ), missing
replace harvest_kg_tot=harvest_kg if (survey_season==7 )& (form_used=="Phone_Market_Survey_spring2020"| form_used=="Short_Market_Survey_spring2020")
replace harvest_kg_tot=harvest_kg if (survey_season==8) & ( form_used=="Short_Market_Survey_fall2020")
replace harvest_kg_tot=. if acreage==0


***creat yield
gen yield=harvest_kg_tot/acreage if (survey_season==7 | survey_season==6 |   survey_season==2 | survey_season==3 |  survey_season==4 |survey_season==7 |survey_season==8 )

****************************************************************
************COSTS FOR STORING/DRYING ***************************
****************************************************************
*replace missing when not growing maize
replace storage_cost=0 if storage_cost==. & acreage!=0 & survey_season==4
replace storage_cost=0 if storage_cost==. & acreage!=0 & survey_season==6

replace drying_cost=0 if drying_cost==. & dry_how!="" &  survey_season==4
replace drying_cost=0 if drying_cost==. & dry_how!="" & survey_season==6

*****And labor costs store 
*fill in 
replace labor_cost_store=0 if labor_cost_store==. & acreage!=0 & ( survey_season==6 | survey_season==7| survey_season==8)
********************************************************
************And how did they dry it? *******************
********************************************************

foreach dry_how in garden ground tarpaulin_own tarpaulin_other tarpaulin_va solar other_dryer {
gen `dry_how'=strmatch(dry_how,"*`dry_how'*") if (survey_season==3 |  survey_season==4 | survey_season==6 ) & dry_how!=""
}

*and create the dummy for tarpaulin
gen tarpaulin_d=(tarpaulin_own==1 | tarpaulin_other==1 | tarpaulin_va==1) if tarpaulin_own!=. 

*************************************************
**LABOUR COSTS
*************************************************
*****LABOR COSTS UP TO AND INCLUDING HARVEST

*S18, F19
foreach activity in prep plant weed spray harv {
egen labor_cost_`activity'_tot=rowtotal(lc_`activity'_costs_season?) if (survey_season==3  | survey_season==6), missing
}
**** F20
foreach activity in prep plant weed spray harv {
replace labor_cost_`activity'_tot=lc_`activity'_costs_season if  survey_season==8
}

/*missing if not growing maize*/
replace labor_cost_ph=. if acreage==0 

****Aggregates
*up to and including harvest
*S17, S18, F19, F20
egen expenses_labor_preharvest_ugx=rowtotal(labor_cost_prep_tot labor_cost_plant_tot labor_cost_spray_tot labor_cost_weed_tot) if (survey_season==3  | survey_season==6 | survey_season==8), missing
label var expenses_labor_preharvest_ugx "Labour costs pre-harvest (UGX)"

*F18
egen tot_lab_costs_preh_aggh_tot=rowtotal(tot_lab_costs_?) if  survey_season==4, missing 
replace  tot_lab_costs_preh_aggh_tot=expenses_labor_preharvest_ugx+labor_cost_harv_tot if (survey_season==3  | survey_season==6 | survey_season==8) 
*and as an ANCOVA control
replace expenses_labor_preharvest_ugx=tot_lab_costs_preh_aggh_tot if survey_season==4 
label var tot_lab_costs_preh_aggh_tot "Labour costs pre-harvest and harvest (UGX)"

*S20
replace tot_lab_costs_preh_aggh_tot=tot_lab_costs if survey_season==7 & form_used=="Short_Market_Survey_spring2020"
replace tot_lab_costs_preh_aggh_tot=tot_lab_costs if survey_season==7 & form_used=="Phone_Market_Survey_spring2020"

*replace missing if no maize acreage
replace tot_lab_costs_preh_aggh_tot=. if acreage==0 & survey_season==7

***unpaid labour hours (unpaid_lab)
*F19
foreach activity in prep plant weed spray harv {
egen `activity'_unpaid_lab_tothrs=rowtotal(lh_`activity'_hours_season?)if ( survey_season==6), missing
}
*F20
foreach activity in prep plant weed spray harv {
replace `activity'_unpaid_lab_tothrs=lh_`activity'_hours_season if survey_season==8
}

***and some aggregates***
*F19 and F20
egen tot_lab_hours_preh_aggh_tot=rowtotal(prep_unpaid_lab_tothrs plant_unpaid_lab_tothrs weed_unpaid_lab_tothrs spray_unpaid_lab_tothrs harv_unpaid_lab_tothrs) if ( survey_season==6  |survey_season==8), missing
*S20
replace tot_lab_hours_preh_aggh_tot=tot_lab_hours if survey_season==7 & form_used=="Phone_Market_Survey_spring2020"
replace tot_lab_hours_preh_aggh_tot=tot_lab_hours if survey_season==7 & form_used=="Short_Market_Survey_spring2020"
 
****and now analysis of labor hours and hired labor****
/*this is how you got the wage from group 1
foreach act in prep plant weed harv{
    forvalues n=1/6{
	    cap confirm variable lc_`act'_unit`n'
		if !_rc   gen dailycost_`act'_`n'=  lc_`act'_costs_unit`n' if lc_`act'_unit`n'=="days"
}
egen med_dailycost_`act'=rowmedian(dailycost_`act'_?)
}
egen med_dailycost=rowmedian(med_dailycost_*)
egen daylywage=mode(med_dailycost)
sum daylywage
local hourlywage=round(r(mean)/6, 1) 
dis `hourlywage'
*/

gen  preh_unpaid_lab_aggh_sh=tot_lab_hours_preh_aggh_tot*833

*****POST-HARVEST ACTIVITIES: Decobbing, winnowing, sorting, bagging

* Fall 2019 and Fall 2020 (bag is not there for Fall 2020)
foreach var of varlist decob winnow sort bag {
gen `var'_d=(`var'=="yes") if `var'!="" & (survey_season==6 | survey_season==8)
}
foreach activity in decob winnow sort bag {
replace lh_`activity'_hours=0 if lh_`activity'_hours==. & `activity'_d!=. & (survey_season==6)
replace lc_`activity'_labour_costs=0 if lc_`activity'_labour_costs==. & `activity'_d!=. & (survey_season==6)
replace lc_`activity'_other_costs=0 if lc_`activity'_other_costs==. & `activity'_d!=. & (survey_season==6)

}
foreach activity in decob winnow sort bag {
gen lh_`activity'_hours_sh=lh_`activity'_hours*833 if (survey_season==6)
}

gen labor_hours_ph_sh= labor_hours_ph*833 if survey_season==8|survey_season==7

* create te cost paid in maize
foreach activity in decob winnow sort bag {
gen lc_`activity'_lmtot_costs=lc_`activity'_labmaize_costs*lc_`activity'_price if (survey_season==6)
replace lc_`activity'_lmtot_costs=0 if lc_`activity'_lmtot_costs==. & `activity'_d!=. & (survey_season==6)
}
*This person just reported a total cost in lab_maize. Entering into lc_decob_lmtot_costs
replace lc_decob_lmtot_costs=lc_decob_labmaize_costs if hhh_id==10015047 & survey_season==6

*and create the total expenses disaggregated 
foreach activity in decob winnow sort bag {
egen `activity'_cost_tot=rowtotal(lc_`activity'_labour_costs lc_`activity'_other_costs lc_`activity'_lmtot_costs) if (survey_season==6), missing

}

***read in F19 into aggregates that are the same across years
egen otherph_costf19=rowtotal(lc_decob_other_costs  lc_sort_other_costs lc_winnow_other_costs lc_bag_other_costs) if survey_season==6, missing
replace otherph_cost=otherph_costf19 if survey_season==6 
drop otherph_costf19

egen labor_cost_phf19=rowtotal(lc_decob_lmtot_costs lc_sort_lmtot_costs lc_winnow_lmtot_costs lc_bag_lmtot_costs lc_decob_labour_costs lc_winnow_labour_costs lc_sort_labour_costs lc_bag_labour_costs ) if survey_season==6, missing
replace labor_cost_ph=labor_cost_phf19 if survey_season==6
drop labor_cost_phf19

/*and create the post-harvest aggregates */
*labour cost preharvest
*outcomes
egen ph_exp_lab_tot_f19=rowtotal(labor_cost_harv_tot labor_cost_store lc_decob_labour_costs lc_sort_labour_costs lc_winnow_labour_costs lc_bag_labour_costs) if ( survey_season==6 ), missing
egen ph_exp_lab_tot_f20=rowtotal(labor_cost_harv_tot labor_cost_store labor_cost_ph) if ( survey_season==8 ), missing
*ancova controls
egen ph_exp_lab_tot_pre_s18=rowtotal(labor_cost_harv_tot labor_cost_ph labor_cost_dry labor_cost_store) if survey_season==3 , missing
egen ph_exp_lab_tot_pre_f18=rowtotal(labor_cost_ph labor_cost_store) if  survey_season==4, missing
*labor cost harvest and post-harvest*
gen expenses_labor_postharvest_ugx=ph_exp_lab_tot_f19 if survey_season==6
replace expenses_labor_postharvest_ugx=ph_exp_lab_tot_pre_s18 if survey_season==3
replace expenses_labor_postharvest_ugx=ph_exp_lab_tot_pre_f18 if  survey_season==4
replace expenses_labor_postharvest_ugx=ph_exp_lab_tot_f20 if survey_season==8
drop ph_exp_lab_tot_pre_s18 ph_exp_lab_tot_pre_f18 ph_exp_lab_tot_f20 ph_exp_lab_tot_f19

***total cost post-harvest 
egen ph_exp_tot2_f19=rowtotal(labor_cost_harv_tot decob_cost_tot winnow_cost_tot sort_cost_tot bag_cost_tot drying_cost storage_cost labor_cost_store) if (survey_season==6 )&group==2, missing	
egen ph_exp_tot2_f20=rowtotal(labor_cost_harv_tot labor_cost_ph otherph_cost drying_cost storage_cost labor_cost_store) if (survey_season==8 ), missing	
egen ph_exp_tot_pre2_s18=rowtotal(labor_cost_harv_tot harvest_cost_tot storage_cost drying_cost otherph_cost labor_cost_ph labor_cost_dry labor_cost_store) if survey_season==3, missing
egen ph_exp_tot_pre2_f18=rowtotal(storage_cost drying_cost otherph_cost labor_cost_ph labor_cost_store ) if  survey_season==4, missing

gen expenses_postharvest_ugx=ph_exp_tot2_f19 if survey_season==6
replace expenses_postharvest_ugx=ph_exp_tot2_f20 if survey_season==8
replace expenses_postharvest_ugx=ph_exp_tot_pre2_s18 if survey_season==3
replace expenses_postharvest_ugx=ph_exp_tot_pre2_f18 if  survey_season==4

drop ph_exp_tot_pre2_s18 ph_exp_tot_pre2_s18 ph_exp_tot2_f19 ph_exp_tot2_f20


/*HOME USE*/
*home_kg 

********************************
******SELLING TOTALS************
********************************

egen sold_kg_tot=rowtotal(sold_kg_p_?) , missing

/*these are all households who harvested, but who did not sell, so should have zero*/
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & ( survey_season==2 | survey_season==7 | survey_season==8)
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & (survey_season==3 | survey_season==6) & sold_crop=="no"
replace sold_kg_tot=0 if harvest_kg_tot!=. & sold_kg_tot==. & ( survey_season==4) & sold_crop=="no"

gen share_sold=sold_kg_tot/harvest_kg_tot

**********************************************************
***********TRANSPORT COSTS/Other miscellaneous************
**********************************************************
egen cost_transportpre_tot=rowtotal(cost_transportpre_?) if survey_season==3, missing
egen cost_transportpost_tot=rowtotal(cost_transportpost_?) if survey_season==3, missing
egen equipment_cost_tot=rowtotal(equipment_cost_?) if survey_season==3, missing

egen sale_transport_cost_tot=rowtotal(sale_transport_cost_?) if (survey_season==3 |  survey_season==4 | survey_season==6) , missing

*for S20, F20, we have tot_transport_cost, goes into the expenses aggregate


****************************************************
***********REVENUE AND PRICES***********************
****************************************************

****total revenue
egen rev_tot=rowtotal(tot_rev_combined_?_? tot_rev_combined_?) if (  survey_season==2 | survey_season==3 |  survey_season==4 | survey_season==6), missing

replace rev_tot=tot_rev_told_tot if (form_used=="Phone_Market_Survey_spring2020"|form_used=="Short_Market_Survey_spring2020"|form_used=="Short_Market_Survey_fall2020")&acres_tot!=0

/*some missings that should be zero*/
replace rev_tot=0 if harvest_kg_tot!=. & rev_tot==. & sold_kg_tot==0 

replace rev_tot=. if acreage==0
replace sold_kg_tot=0 if acreage!=0&rev_tot==0&harvest_kg_tot==.
replace sold_kg_tot=0 if sold_kg_tot==. & sold_crop=="no" & survey_season==6
replace rev_tot=0 if sold_kg_tot==0 & survey_season==6


****and generate the average price over all sales
gen price_ugx=rev_tot/sold_kg_tot 

*********************************************
*****impute price for those who do not sell**
********************************************* 

by ea_code survey_season, sort: egen price_vm=mean(price_ugx)

egen ea_season=group(ea_code survey_season)
xtset, clear
xfill price_vm, i(ea_season)

****and let's calculate the value of home maize
gen harvest_value_beforeded=harvest_kg_tot*price_ugx

replace harvest_value_beforeded=harvest_kg_tot*price_vm if harvest_kg_tot!=. & price_ugx==. 

gen remainder=harvest_kg_tot-sold_kg_tot
gen harvest_value_ugx=rev_tot+remainder*price_vm if remainder>=0
replace harvest_value_ugx=harvest_value_beforeded if remainder<0
*Value harvest if sales are missing
replace harvest_value_ugx=harvest_value_beforeded if harvest_kg_tot!=. & sold_kg_tot==. & survey_season==4

*******************************
******EXPENSES*****************
*******************************

egen expenses_season_spring2018=rowtotal(seeds_cost_tot fert_cost_tot manure_cost_tot booster_cost_tot equipment_cost_tot  expenses_labor_preharvest_ugx labor_cost_harv_tot tot_chem_costs_tot harvest_cost_tot storage_cost drying_cost otherph_cost labor_cost_ph labor_cost_dry labor_cost_store cost_transportpre_tot cost_transportpost_tot sale_transport_cost_tot) if survey_season==3, missing
replace expenses_season_spring2018=. if expenses_season_spring2018==0 & acreage==0 & survey_season==3

egen expenses_season_fall2018=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot manure_cost_tot tot_lab_costs_preh_aggh_tot labor_cost_store drying_cost storage_cost otherph_cost labor_cost_ph tot_transport_cost sale_transport_cost_tot ) if  survey_season==4, missing

egen expenses_season_fall2019=rowtotal(fert_cost_tot  seeds_cost_tot booster_cost_tot tot_chem_costs_tot expenses_labor_preharvest_ugx labor_cost_harv_tot  labor_cost_store drying_cost storage_cost preh_transport_cost posth_transport_cost  sale_transport_cost_tot decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==6, missing

egen expenses_season_spring2020=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot tot_lab_costs_preh_aggh_tot labor_cost_store drying_cost storage_cost tot_transport_cost labor_cost_ph otherph_cost) if survey_season==7  , missing

egen expenses_season_fall2020=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot  expenses_labor_preharvest_ugx labor_cost_harv_tot  labor_cost_store drying_cost storage_cost tot_transport_cost labor_cost_ph otherph_cost) if survey_season==8  , missing

egen expenses_hours_season_fall2019=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot manure_cost_tot expenses_labor_preharvest_ugx labor_cost_harv_tot   preh_unpaid_lab_aggh_sh drying_cost storage_cost labor_cost_store  preh_transport_cost posth_transport_cost   sale_transport_cost_tot lh_decob_hours_sh lh_sort_hours_sh lh_winnow_hours_sh lh_bag_hours_sh decob_cost_tot sort_cost_tot winnow_cost_tot bag_cost_tot) if survey_season==6, missing

egen expenses_hours_season_spring2020=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot  tot_lab_costs_preh_aggh_tot  preh_unpaid_lab_aggh_sh  drying_cost storage_cost labor_cost_store tot_transport_cost labor_cost_ph otherph_cost labor_hours_ph_sh   ) if survey_season==7  , missing

egen expenses_hours_season_fall2020=rowtotal(fert_cost_tot tot_chem_costs_tot seeds_cost_tot booster_cost_tot  tot_lab_costs_preh_aggh_tot  preh_unpaid_lab_aggh_sh  drying_cost storage_cost labor_cost_store tot_transport_cost labor_cost_ph otherph_cost labor_hours_ph_sh  ) if survey_season==8  , missing


gen expenses_ugx=.
foreach season in season_spring2018 season_fall2018  season_fall2019 season_spring2020 season_fall2020 {
replace expenses_ugx=expenses_`season' if `season'==1
}

* for post-season, where hours were collected
gen expenses_hours_ugx=.
foreach season in   season_fall2019 season_spring2020 season_fall2020 {
replace expenses_hours_ugx=expenses_hours_`season' if `season'==1
} 
* for pre-seasons, where we have expenses, as ANCOVA control
foreach season in season_fall2018 season_spring2018 {
replace expenses_hours_ugx=expenses_`season' if `season'==1
} 

gen surplus_ugx= harvest_value_ugx-expenses_ugx
gen surplus_hrs_ugx= harvest_value_ugx-expenses_hours_ugx 

foreach var in price harvest_value expenses expenses_hours surplus surplus_hrs expenses_fert_seeds   expenses_inputs  expenses_labor_preharvest  expenses_postharvest expenses_labor_postharvest {
gen `var'=.
replace `var' =`var'_ugx/3575 if survey_season==1
replace `var' =`var'_ugx/3601 if survey_season==2
replace `var' =`var'_ugx/3626 if survey_season==3
replace `var' =`var'_ugx/3758 if survey_season==4
replace `var' =`var'_ugx/3670 if survey_season==5
replace `var' =`var'_ugx/3685 if survey_season==6
replace `var' =`var'_ugx/3681 if survey_season==7
replace `var' =`var'_ugx/3685 if survey_season==8
}	

*harvest
gen harvest_ton=harvest_kg_tot/1000

*yield
gen yield_ha_ton=yield*2.47105/1000

keep hhh_id ea_code survey_season ext_treatment group season_spring2017 season_fall2017 season_spring2018 season_fall2018 season_spring2019 season_fall2019 season_spring2020 season_fall2020 season_ante season_post mdm_female mdm_primary  hhr_n distance_kibaale main_road_min    acreage expenses harvest_ton harvest_kg_tot yield_ha_ton yield share_sold  price harvest_value surplus surplus_hrs expenses_fert_seeds expenses_inputs tarpaulin_d sort_d winnow_d expenses_labor_preharvest  expenses_postharvest expenses_labor_postharvest  modern_seeds_any fert_any
save "$repfol\data\end\panel_g2_analysis.dta", replace
 






```

### `dofiles/FINAL_master.do`
```stata
set more off

*Substitute the path to the working directory “here”  
global repfol " "

cap mkdir "$repfol/output/tables"
cap mkdir "$repfol/output/figures"
cap mkdir "$repfol/other"

***Variable creation

run "$repfol/dofiles/permutations.do"
run "$repfol/dofiles/FINAL_create_vars_gr0.do"
run "$repfol/dofiles/FINAL_create_vars_main_g1.do"
run "$repfol/dofiles/FINAL_create_vars_main_g2.do"
run "$repfol/dofiles/merge_gr1_gr2.do"
run "$repfol/dofiles/FINAL_create_vars_returns.do"
run "$repfol/dofiles/FINAL_create_vars_sellers.do"


***Analysis - main tables

forvalues n=1/7{
	run "$repfol/dofiles/table`n'.do"
}

***Analysis - main figures

forvalues n=1/5{
	run "$repfol/dofiles/figure`n'.do"
}

***Analysis - online appendix tables

forvalues n=1/14{
	run "$repfol/dofiles/XAppendix_table`n'.do"
}

***Analysis - online appendix figures

forvalues n=2/3{
	run "$repfol/dofiles/XAppendix_figure`n'.do"
}

***Replication of results within the text

run "$repfol/dofiles/intext_replication.do"

```

### `dofiles/XAppendix_table1.do`
```stata
* Online appendix Table 1

clear all 
use "$repfol/data/end/sellers_for_analysis.dta", clear
matrix tabA1=J(24,1,.)

keep if survey_season>=3
unique hhh_id survey_season  if buy_treatment==0

matrix tabA1[22,1]=r(N)
matrix tabA1[23,1]=r(unique)

unique hhh_id   if buy_treatment==0
matrix tabA1[24,1]=r(unique)

preserve
collapse buy_treatment priceb (sum) share_sale , by( ea_code type survey_season)
egen share_sale_t=total(share_sale), by(ea_code survey_season)
gen market_share=share_sale/share_sale_t

sum market_share if type==0&buy_treatment==0
matrix tabA1[1,1]=round(r(mean)*100, 0.1)

egen check=total( market_share ), by(ea_code survey_season)
sum check
forvalues s=3/7{
	local r=`s'-1
	sum market_share if type==0&buy_treatment==0&survey_season==`s'
	matrix tabA1[`r',1]=round(r(mean)*100, 0.1)

}
restore

preserve
collapse (max) commercial_once buy_treatment, by(hhh_id)
sum commercial_once if buy_treatment==0
matrix tabA1[7,1]=round(r(mean)*100, 0.1)
restore

preserve
collapse (count) price (mean) buy_treatment, by(hhh_id survey_season)

replace price=3 if price>3&price!=.
count if price!=.&buy_treatment==0
local tot =r(N)
dis `tot'
ta price if buy_treatment==0

forvalues t=1/3{
	local r=`t'+7
	count if price==`t'&buy_treatment==0
	matrix tabA1[`r',1]=round(r(N)*100/`tot', 0.1)

}
restore 

preserve
unique name, by(hhh_id survey_season) gen(buyer_num)
collapse (mean) buyer_num buy_treatment, by(hhh_id survey_season)
sum buyer_num if buy_treatment==0
forvalues t=1/3{
	local r=`t'+10
	count if buyer_num==`t'&buy_treatment==0
	matrix tabA1[`r',1]=round(r(N)*100/`tot', 0.1)
}
restore

preserve
use "$repfol/data/end/panel_g1g2_analysis.dta",clear
gen share_sold100=share_sold*100
sum share_sold100 if buy_treatment==0&survey_season>=3&group==1
matrix tabA1[14,1]=round(r(mean), 0.01)
restore

preserve
keep if buy_treatment==0
egen n_season_in_sample=nvals(survey_season), by(hhh_id)
keep if n_season_in_sample==5
sort hhh_id survey_season name
egen id1=group( hhh_id survey_season name)
collapse hhh_id survey_season name, by(id1)
egen n_trade_mode=mode(name), by(hhh_id ) 
egen n_trade_mode_min=mode(name), minmode by(hhh_id)
replace n_trade_mode_min=. if n_trade_mode~=.
gen common_buyers=1 if name==n_trade_mode
replace common_buyers=1 if name==n_trade_mode_min
collapse (sum) common_buyers, by(hhh_id)


tab common_buyers	
count 
local tot =r(N)
dis `tot'

forvalues t=1/5{
	local r=`t'+14
	count if common_buyers==6-`t'
	matrix tabA1[`r',1]=round(r(N)*100/`tot', 0.1)
}

restore
gen price_reltolocal=.

forvalues s=1/7{
    sum price if buy_treatment==0&local==1&survey_season==`s'
	replace price_reltolocal=price/r(mean) if survey_season==`s'
}

sum price_reltolocal if buy_treatment==0&local==1
matrix tabA1[20,1]=round(r(mean), 0.01)

sum price_reltolocal if buy_treatment==0&commercial==1
matrix tabA1[21,1]=round(r(mean), 0.01)

matrix list tabA1, f(%10.3g)

esttab matrix(tabA1, fmt(a2)) using "$repfol/output/tables/Xtable_A1.rtf", replace title("{\b Table 1.} Local and commercial traders") note("Note. See main text for details.") nonote coll("Mean") nogaps  noobs nonum refcat(r1 "{\i Interactions: local vs. commercial traders}" r8 "{\i Sale pattern over 5 seasons}" r15 "{\i Repeated interactions with local buyers (five seasons)}" r20 "{\i Prices}" r22 "{\i Sample size}", nolabel) nomtitle varwidth(50)  varl(r1 "  Market share of local traders (%)" r2 "     Market share of local traders: season 3 (%)" r3 "     Market share of local traders: season 4 (%)" r4 "     Market share of local traders: season 5 (%)" r5 "     Market share of local traders: season 6 (%)" r6 "     Market share of local traders: season 7 (%)" r7 "  Sold to a commercial trader at least once in five seasons (%)" r8 "  Sold once in the season (%)" r9 "  Sold twice in the season (%)" r10 "  Sold three or more times in the season (%)" r11 "  Sold to one buyer only in the season (%)" r12 "  Sold to two buyers in the season (%)" r13 "  Sold to three buyers in the season (%)" r14 "  Share sold (%)" r15 "  Sold to the same buyer in all seasons (%)" r16 "  Sold to the same buyer in four out of five seasons (%)" r17 "  Sold to the same buyer in three out of five seasons (%)" r18 "  Sold to the same buyer in two out of five seasons (%)" r19 "  Sold to different buyers in each season (%)" r20 "  Normalized price paid by local traders" r21 "  Normalized price paid by commercial traders" r22 "  Sales"  r23 "  Household-seasons"  r24 "  Households" )


```

### `dofiles/XAppendix_table10.do`
```stata
* Online appendix Table 10

clear all
set maxvar 11000
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
local rep 10000
local ri="yes"



foreach group in 1 2 {
	

if `group'==1 local append replace 
if `group'==2 local append append 

if `group'==1 local treatment buy_treatment  
if `group'==2 local treatment ext_treatment 

if `group'==1 local coefl varl(`treatment' "Access to a market for quality maize")
if `group'==2 local coefl varl(`treatment' "Extension service")

if `group'==1 local lastbaseline season_spring2018
if `group'==2 local lastbaseline season_fall2018

if `group'==1 local title title("{\b Table 10.} Impact on investment: Incidence of hybrid seeds and fertilizer use.")
if `group'==2 local title ""

if `group'==1 local panel refcat(`treatment' "{\i {\b Panel A.} Market access experiment}", nolabel) 
if `group'==2 local panel  refcat(`treatment' "{\i {\b Panel B.} Extension service experiment}", nolabel)

if `group'==2 local note note("Note. ANCOVA specification. Clustered-by-village standard errors with p-values in parenthesis. p-values from Fisher-permutations test based on 10,000 permutations of the treatment assignment in brackets. Any improved seeds is a dummy equal to 1 if any improved seeds were used. Any fertilizer is a dummy equal to 1 if any fertilizer was used.")

if `group'==2 local nohead  mlabels(none)  nonum

local ancova " "

eststo clear
local estimate_count=0

preserve
 
if "`ri'"=="yes" {
  keep  modern_seeds_any fert_any  hhh_id survey_season ea_code ext_treatment season_spring2018 season_fall2018 group season_ante season_post

mmerge ea_code using "$repfol/data/end/permutations_gr`group'.dta"

}
noi dis `group'

foreach var of varlist  modern_seeds_any fert_any    {   

local estimate_count=`estimate_count'+1

by hhh_id, sort: egen `var'_p3=mean(`var') if `lastbaseline'==1 &  group==`group'
xfill `var'_p3 , i(hhh_id)
by hhh_id, sort: egen `var'_p=mean(`var') if season_ante==1 &  group==`group'
xfill `var'_p , i(hhh_id)
replace `var'_p3=`var'_p if `var'_p3==. &  group==`group'

local ancova  `var'_p3

reg `var' `treatment'  `ancova' i.survey_season if group==`group' & season_post==1, cluster(ea_code)

if "`ri'"=="yes" {
*noi dis _b[`treatment'] 
*noi dis (2 * ttail(e(df_r), abs(_b[`treatment']/_se[`treatment'])))

local threshold=abs(_b[`treatment'])/_se[`treatment']

matrix TP=J(`rep',1,0)
matrix pvalues=J(1,1,0)

forvalues k=1(1)`rep' {
qui: xi: reg `var' `treatment'`k' `ancova' i.survey_season if group==`group' & season_post==1, cluster(ea_code) 
mat TP[`k',1]=abs(_b[`treatment'])/_se[`treatment']
}
	cap drop TP
	svmat TP
	gen reject=(TP1>`threshold') if TP1!=.
}
	eststo  est`estimate_count':  reg `var' `treatment' `ancova' i.survey_season if  season_post==1 & group==`group' , cluster(ea_code)

	sum  `var' if e(sample)==1&`treatment'==0
	estadd local mean_control =round( `r(mean)', 0.01)
	
if "`ri'"=="yes" {
	sum reject 
	*noi dis `r(mean)'
	matrix pvalues=J(1,1,`r(mean)')
	mat colnames pvalues = `treatment' 
	estadd matrix pvalues = pvalues
	
	drop TP reject	
}		
}
restore
esttab est1 est2  using "$repfol/output/tables/Xtable_A10.rtf", `title' `panel'  `note' nonote stats(N r2 mean_control , fmt( 0 2 2) labels(  "Observations" "R-squared" "Mean control")) cells(b(fmt(a2)) p(par fmt(3)) pvalues(par([ ]) fmt(3))) nogaps order(`treatment') keep(`treatment') onecell `append'  `nohead' `coefl' label collabels(none) 

}


```

### `dofiles/XAppendix_table11.do`
```stata
* Online appendix Table 11

clear all
set maxvar 11000
use "$repfol/data/end/panel_g1g2_analysis.dta", clear

foreach group in 1 2 {
	
noi dis `group'

if `group'==1 local append replace 
if `group'==2 local append append 

if `group'==1 local treatment buy_treatment  
if `group'==2 local treatment ext_treatment 

if `group'==1 local coefl varl(`treatment' "Access to a market for quality maize")
if `group'==2 local coefl varl(`treatment' "Extension service")

if `group'==1 local lastbaseline season_spring2018
if `group'==2 local lastbaseline season_fall2018

if `group'==1 local title title("{\b Table 11.} Impact on productivity and income: Trimmed sample")
if `group'==2 local title ""

if `group'==1 local panel refcat(`treatment' "{\i {\b Panel A.} Market access experiment}", nolabel) 
if `group'==2 local panel  refcat(`treatment' "{\i {\b Panel B.} Extension service experiment}", nolabel)

if `group'==2 local note  note("Note. Trimmed sample: non-negative continuous variables are trimmed at the top 1% observations in each season. Variables that can take both positive and negative values, i.e. profit, are trimmed at the top- and bottom 1% observations in each season. Clustered-by-village standard errors with p-values in parenthesis.")
if `group'==1 local note " "

if `group'==2 local nohead  mlabels(none)  nonum
if `group'==1 local nohead  mlabels("Price" "Maize Acreage" "Harvest (kg)" "Yield (kg/acre)" "Harvest value" "Monetary Expenses" "Profits (Monetary expenses)" "Profits (incl. own hours)")  

local ancova " "

eststo clear
local estimate_count=0

preserve

foreach var of varlist price acreage harvest_kg_tot yield  harvest_value  expenses  surplus  surplus_hrs   {

local estimate_count=`estimate_count'+1

by hhh_id, sort: egen `var'_p3=mean(`var') if `lastbaseline'==1 & group==`group'
xfill `var'_p3 , i(hhh_id)
by hhh_id, sort: egen `var'_p=mean(`var') if season_ante==1 &group==`group'
xfill `var'_p , i(hhh_id)
replace `var'_p3=`var'_p if `var'_p3==. &  group==`group'

local ancova  `var'_p3
gen t_`var'=`var'
label var t_`var' "`:var label `var''"
des  t_`var' 

forvalues s=1/8 {
_pctile `var' if group==`group' & survey_season==`s', p(99)
dis `r(r1)'
	if r(r1)!=. 	replace t_`var'=. if group==`group' &`var'>=`r(r1)' &survey_season==`s'
	if ("`var'"== "surplus"|"`var'"== "surplus_hrs")& r(r1)!=. {
	    _pctile `var' if group==`group' & survey_season==`s', p(1)
	   replace t_`var'=. if `var'<=`r(r1)' &group==`group'&survey_season==`s'
	} 
}


	eststo  est`estimate_count':  reg t_`var' `treatment' `ancova' i.survey_season if group==`group' & season_post==1 , cluster(ea_code)

	sum  t_`var' if e(sample)==1&`treatment'==0
	estadd scalar mean_control =`r(mean)'
	
}

restore

esttab est1 est2  est3 	est4 est5 est6 est7 est8  using "$repfol/output/tables/Xtable_A11.rtf", `title' `panel'   stats(N r2 mean_control , fmt( 0 2 2) labels(  "Observations" "R-squared" "Mean control")) cells(b(fmt(a2)) p(par fmt(3)) ) nogaps order(`treatment') keep(`treatment') onecell `append'  `nohead' `coefl' `note'  collabels(none)

}



```

### `dofiles/XAppendix_table12.do`
```stata
* Online appendix Table 12

clear all
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep if group==1
matrix tabA12=J(21,1,.)



*** Linear model
gen fert_d=fert_any
gen  modern_seeds_d=modern_seeds_any

* Estimating treatment effects:
reg harvest_kg_tot buy_treatment acreage ownhours hiredhours fert_d modern_seeds_d i.survey_season if survey_season>4, cluster(ea_code)
matrix tabA12[21,1]=e(N)



foreach var of varlist acreage ownhours hiredhours fert_d modern_seeds_d {
    sum `var' if survey_season>4 & buy_treatment==1&e(sample)
	local t_`var' =r(mean)
    sum `var' if survey_season>4 & buy_treatment==0&e(sample)
	local c_`var' =r(mean)
} 


lincom buy_treatment + acreage*(`t_acreage'-`c_acreage') + ownhours*(`t_ownhours'-`c_ownhours') + hiredhours*(`t_hiredhours'-`c_hiredhours') + fert_d*(`t_fert_d'-`c_fert_d') + modern_seeds_d*(`t_modern_seeds_d'-`c_modern_seeds_d')

matrix tabA12[1,1]=r(estimate)
matrix tabA12[2,1]=r(p)

lincom buy_treatment + acreage*(`c_acreage') + ownhours*(`c_ownhours') + hiredhours*(`c_hiredhours') + fert_d*(`c_fert_d') + modern_seeds_d*(`t_modern_seeds_d'-`c_modern_seeds_d')

		
*******************************
***Treatment effects in % terms 
*******************************

* due to TFP (unmeasured inputs)
nlcom 	_b[buy_treatment]/(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') ///
		+ _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))
		
		
matrix tabA12[3,1]=r(b)[1,1]
matrix tabA12[4,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))

		
* due to land
nlcom 	_b[acreage]*(`t_acreage'-`c_acreage')/ ///
		(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))

matrix tabA12[5,1]=r(b)[1,1]
matrix tabA12[6,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))

* due to own labor
nlcom 	_b[ownhours]*(`t_ownhours'-`c_ownhours')/ ///
		(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))

matrix tabA12[7,1]=r(b)[1,1]
matrix tabA12[8,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))

* due to hired labor
nlcom 	_b[hiredhours]*(`t_hiredhours'-`c_hiredhours')/ ///
		(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))
	
matrix tabA12[9,1]=r(b)[1,1]
matrix tabA12[10,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))

	
* due to modern inputs
nlcom 	(_b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))/ ///
		(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))

matrix tabA12[11,1]=r(b)[1,1]
matrix tabA12[12,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))


* due to measured inputs
nlcom 	(_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))/ ///
		(_b[buy_treatment]+_b[acreage]*(`t_acreage'-`c_acreage') + _b[ownhours]*(`t_ownhours'-`c_ownhours') + _b[hiredhours]*(`t_hiredhours'-`c_hiredhours') + _b[fert_d]*(`t_fert_d'-`c_fert_d') + _b[modern_seeds_d]*(`c_modern_seeds_d'-`t_modern_seeds_d'))


matrix tabA12[13,1]=r(b)[1,1]
matrix tabA12[14,1]=2*normal(-abs(r(b)[1,1]/sqrt(r(V)[1,1])))

		
* Testing for mediating effects (i)
test acreage ownhours hiredhours fert_d modern_seeds_d

matrix tabA12[17,1]=r(F)
matrix tabA12[18,1]=r(p)


* Testing for mediating effects (ii)
xi i.survey_season

gsem 	(acreage <- buy_treatment _Isurvey_se_5 _Isurvey_se_6 _Isurvey_se_7 ) (ownhours <- buy_treatment _Isurvey_se_5 _Isurvey_se_6 _Isurvey_se_7 ) ///
		(hiredhours <- buy_treatment _Isurvey_se_5 _Isurvey_se_6 _Isurvey_se_7 ) (fert_d <- buy_treatment _Isurvey_se_5 _Isurvey_se_6 _Isurvey_se_7 ) ///
		(modern_seeds_d <- buy_treatment _Isurvey_se_5 _Isurvey_se_6 _Isurvey_se_7 ) if survey_season>4, vce(cluster ea_code)

test [acreage]buy_treatment [ownhours]buy_treatment [hiredhours]buy_treatment [fert_d]buy_treatment [modern_seeds_d]buy_treatment

matrix tabA12[19,1]=r(chi2)
matrix tabA12[20,1]=r(p)

* Test if the experimentally-induced increments in unmeasured inputs are independent of the experimentally induced increments in measured inputs

gen acreage_T=acreage*buy_treatment 
gen ownhours_T=ownhours*buy_treatment
gen hiredhours_T=hiredhours*buy_treatment
gen fert_d_T=fert_d*buy_treatment
gen modern_seeds_d_T=modern_seeds_d*buy_treatment 


reg 	harvest_kg_tot buy_treatment acreage ownhours hiredhours fert_d modern_seeds_d acreage_T ownhours_T hiredhours_T fert_d_T modern_seeds_d_T ///
		i.survey_season if survey_season>4, cluster(ea_code)

test acreage_T ownhours_T hiredhours_T fert_d_T modern_seeds_d_T

matrix tabA12[15,1]=r(F)
matrix tabA12[16,1]=r(p)


esttab matrix(tabA12, fmt(a3)) using "$repfol/output/tables/Xtable_A12.rtf", replace onecell varwidth(40) refcat(r1 "{\b {\i Panel A.}} " r3 "Decomposing {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]" r15 "{\b {\i Panel B.}}" , nolabel) varl(r1 " {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]" r2 " " r3 "\u0916? TFP: \u0916? \u0952? / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r4 " " r5 "\u0916? Land: \u0916? {\i A} / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r6  " " r7 "\u0916? Family labour: \u0916? {\i L \sub F \nosupersub } / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r8  " " r9 "\u0916? Hired labour: \u0916? {\i L \sub H \nosupersub } / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r10  " " r11 "\u0916? Soil enhancing investment: \u0916? \u0956? / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r12  " " r13 "\u0916? Measured inputs total: \u0916?  {\i x} / {\i E}[Y\sub 1 \nosupersub - Y\sub 0 \nosupersub]  " r14  " " r15 "Test of independence" r16 " " r17 "Test I of mediators" r18 " " r19 "Test II of mediators" r20 " " r21 "Observations") coll("Production Function")    noobs note("Note. Sample: households in the last three follow-up seasons in the market access experiment. Panel A: overall treatment effect and the relative magnitudes of measured inputs and unmeasured inputs (TFP). Clustered-by-village standard errors with p-value below the estimate. Panel B: test of independence test the null hypothesis that the experimentally-induced increments in unmeasured inputs are independent of the experimentally induced increments in measured inputs, assuming autonomy. Assuming independence of the observed and unobserved inputs (in both treatment and control), the test is equivalent to testing autonomy; i.e., the parameters of the production function are the same in the control and the treatment group (see Heckman and Pinto, 2015). Test I of mediators tests the  {\i H \sub 0} that the vector of observed inputs do not explain harvest volumes. Test II of mediators tests the {\i H \sub 0} that the vector of observed inputs are not affected by treatment.") nomtitle title("{\b Table 12.} Mechanisms")


```

### `dofiles/XAppendix_table13.do`
```stata
* Online appendix Table 13

clear all
set maxvar 11000
use "$repfol/data/end/sellers_for_analysis.dta", clear

matrix tabA13=J(4,4,.)

reg  local buy_treatment if survey_season==3, cluster(ea_code)
matrix tabA13[1,1]=_b[buy_treatment]+_b[_cons]
matrix tabA13[1,2]=_b[_cons]
matrix tabA13[1,3]=_b[buy_treatment]
matrix tabA13[1,4]=(2 * normal(-abs(_b[buy_treatment]/_se[buy_treatment])))

reg  commercial buy_treatment if survey_season==3, cluster(ea_code)
matrix tabA13[2,1]=_b[buy_treatment]+_b[_cons]
matrix tabA13[2,2]=_b[_cons]
matrix tabA13[2,3]=_b[buy_treatment]
matrix tabA13[2,4]=(2 * normal(-abs(_b[buy_treatment]/_se[buy_treatment])))

reg  price buy_treatment if survey_season==3&local==1, cluster(ea_code)
matrix tabA13[3,1]=_b[buy_treatment]+_b[_cons]
matrix tabA13[3,2]=_b[_cons]
matrix tabA13[3,3]=_b[buy_treatment]
matrix tabA13[3,4]=(2 * normal(-abs(_b[buy_treatment]/_se[buy_treatment])))

reg  price buy_treatment if survey_season==3&commercial==1, cluster(ea_code)
matrix tabA13[4,1]=_b[buy_treatment]+_b[_cons]
matrix tabA13[4,2]=_b[_cons]
matrix tabA13[4,3]=_b[buy_treatment]
matrix tabA13[4,4]=(2 * normal(-abs(_b[buy_treatment]/_se[buy_treatment])))

matrix list tabA13

esttab matrix(tabA13, fmt(a2 a2 3 3)) using "$repfol/output/tables/Xtable_A13.rtf", replace onecell varwidth(40) refcat(r1 "Market shares:" r3 "Prices:" , nolabel) varl(r1 "  Local traders" r2 "  Commercial traders" r3 "  Local traders" r4 "  Commercial traders"  ) coll("T" "C" "Coeff." "{\i p}") noobs nonote note("Note. Market shares and prices are derived from household sales data in season 3 (last baseline season) in the market access experiment. p-values (p) with standard errors clustered at the village level.") title("{\b Table 13.} Market shares and prices at baseline") nomtitles



```

### `dofiles/XAppendix_table14.do`
```stata
* Online appendix Table 14

clear all 
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
preserve
use "$repfol/data/end/sellers_for_analysis.dta", clear
collapse (max)  hq buy_treatment,by(hhh_id survey_season)
tempfile temp
save `temp' , replace
  
restore

merge 1:1 hhh_id survey_season using  `temp', nogen
replace hq=0 if hq==.
gen nohq_1=hq==0&buy_treatment==1

foreach var in  harvest yield {
	if "`var'"=="harvest" local propvar harvest_kg_tot
	if "`var'"=="yield" local propvar yield

	gen `var'_norm=.
	
forvalues group=1/2{
forvalues s =1/7{
	sum `propvar' if buy_treatment==0 & survey_season==`s' &group==`group'
	if `r(N)'>10 replace `var'_norm=( `propvar' -`r(mean)')/`r(mean)' if survey_season==`s'&group==`group'
}
}

gen `var'3=`var'_norm if survey_season==3
xfill `var'3, i(hhh_id)
bys hhh_id: egen `var'bl=mean(`var'_norm) if survey_season<3
xfill `var'bl, i(hhh_id)
replace `var'3=`var'bl if `var'3==.
xfill `var'3, i(hhh_id)

gen `var'_dif=`var'_norm-`var'3
bys survey_season group buy_treatment: egen mean_`var'3= mean(`var'3) if survey_season>3& group==1
gen `var'3_t=`var'3- mean_`var'3
gen `var'_norm_t=`var'_norm- mean_`var'3

local label= strproper("`var'")
label var `var'_dif `label'

*naive diff 
eststo m1`var' :reg `var'_norm_t hq nohq_1 if survey_season>3& group==1, vce(cluster ea_code) 

*causal effect
eststo m2`var' :reg `var'_dif hq nohq_1 if survey_season>3& group==1 ,  vce(cluster ea_code)

}

esttab  m2*  using "$repfol/output/tables/Xtable_A14.rtf", replace  onecell nonote varl(hq "Selling to the high quality buyer" nohq_1 "Selling to other traders" ) cell(b(fmt(a3) ) p(fmt(a3) par([ ]) ) ) coll("") mlab("Harvest" "Yield") drop(_cons) note("Note. Each column reports the causal effect estimated regressing the difference between the (normalized) outcome (harvest in column 1 and yield in column 2) at follow-up and baseline on an indicator whether the household sold to the high quality trader in the follow-up season or not; i.e. specification (17) in online Appendix section F. The unit of observation is the household (658 observations). Clustered-by-village standard errors with p-values in brackets.") title("{\b Table 14.} Impact on productivity adjusting for selection")

```

### `dofiles/XAppendix_table2.do`
```stata
* Online appendix Table 2

clear all 
use "$repfol/data/end/quality_for_analysis.dta", clear

reg defects_lab_ln_r defects_visual_mean_r if treatment==0, robust
eststo m1

reg totalaflatoxins defects_lab_ln_r i.survey_season if treatment==0|quasicontrol==1 , robust
eststo m2

logit totalaflatoxins c.defects_lab_ln_r i.survey_season if treatment==0|quasicontrol==1 , robust
eststo m3

esttab m1 m2 m3 using "$repfol/output/tables/Xtable_A2.rtf", replace title("{\b Table 2.} Correlations between lab and visually verifiable defects and lab verified defects and probability of aflatoxin") varlabels(defects_visual_mean_r "Visually verifiable quality" defects_lab_ln_r "Lab verified quality" _cons "Constant") note("Note: OLS regressions (1)-(2), logit regression (3) with season fixed effects. Unit of observation is a maize bag. Lab verified quality is grams of defects per 200g maize (%), expressed in logs. Visually verifiable quality is the number of defects (out of 10) detected in the bag in the field. Aflatoxin >10ng/g is a dummy variable indicating an aflatoxin level above the limit imposed by the Uganda National Bureau of Standards (10ng/g). Robust standard errors are in parentheses and p-values in brackets.") nonote  nogaps label stats(N r2  , fmt( 0 2) labels(  "Observations" "R-squared"))  cells(b(fmt(2)) se(par fmt(2)) p(par([ ]) fmt(3))) keep(defects_visual_mean_r defects_lab_ln_r _cons) collabels(none) onecell mlabel( "Lab verified quality" "Aflatoxin >10ng/g" " ") varwidth(27)





```

### `dofiles/XAppendix_table3.do`
```stata
* Online appendix Table 3

clear all 
use "$repfol/data/end/quality_for_analysis.dta", clear

keep if quasicontrol==0&sellers==0

* Column 1: acreage
eststo c1: areg  acreage treatment, a(ea_code) robust

* Column 2: expected harvest
eststo c2: areg expected_harvest_ton treatment, a(ea_code) robust

* Column 3: expected to harvest in the 2nd half of the season
eststo c3: areg late treatment, a(ea_code) robust

* Column 4: use of hybrid seeds
eststo c4: areg seed_av treatment, a(ea_code) robust

* Column 5: use of chemicals
eststo c5: areg chemical_av treatment, a(ea_code) robust

* Column 6: Joint balance test
eststo c6: areg treatment seed_av chemical_av late expected_harvest_ton acreage, a(ea_code) robust
test  seed_av chemical_av late expected_harvest_ton acreage

estadd scalar jointtest=r(p)


esttab c1 c2 c3 c4 c5 c6 using "$repfol/output/tables/Xtable_A3.rtf", replace title("{\b Table 3.} Pre-harvest balance: returns to quality experiment") note("Note: OLS regressions with village fixed effects. Robust standard errors in parenthesis and p-values in brackets. All variables are collected pre-harvest (but post-planting) in the fall 2019 season. Specifications: (1) is acreage of land used for planting maize; (2) is expected harvest of maize (tons/acreage); (3) is a binary indicator taking the value 1 if the household expected to harvest their maize in the 2nd half of the season (i.e. in the first week of February 2019 or later); (4) used modern seed (hybrid or OPV seeds); (5) used chemicals (pesticides and/or herbicides); (6) joint balance tests report the p-value from jointly testing whether the variables in columns (1)-(5) predict enrollment into treatment. ") nonote  nogaps label stats(jointtest N   r2 , fmt( 2 0 2 ) labels( "Joint test p-value"  "Observations"  "R-squared") layout(`""[@]""' @ @ ))  cells(b(fmt(2) pattern(1 1 1 1 1 0)) se(par fmt(2) pattern(1 1 1 1 1 0)) p(par([ ]) fmt(2) pattern(1 1 1 1 1 0))) keep(treatment _cons) varl(treatment "Treatment" _cons "Constant") collabels(none) onecell mlabel( "Acreage" "Expected harvest" "Expected to harvest in 2{\super nd} half of season" "Use modern seeds" "Use of chemicals" "Joint balance test")


```

### `dofiles/XAppendix_table4.do`
```stata
* Online appendix Table 4

clear all 
use "$repfol/data/end/quality_for_analysis.dta", clear
matrix tabA4=J(8,4,.)

keep if quasicontrol==0&sellers==0

* Row 1: enrolled households
count 
matrix tabA4[1,1]=r(N)

count if treatment==1
matrix tabA4[1,2]=r(N)

count if treatment==0
matrix tabA4[1,3]=r(N)

* Row 2: visual quality: households
count if add4_random_bag!=.
matrix tabA4[2,1]=r(N)

count if add4_random_bag!=.&treatment==1
matrix tabA4[2,2]=r(N)

count if add4_random_bag!=.&treatment==0
matrix tabA4[2,3]=r(N)

* Row 3: visual quality: bags
preserve
reshape long defects_visual_tot_ , i(hhh) j(number)
keep if defects_visual_tot_!=.

count if add4_random_bag!=.
matrix tabA4[3,1]=r(N)

count if add4_random_bag!=.&treatment==1
matrix tabA4[3,2]=r(N)

count if add4_random_bag!=.&treatment==0
matrix tabA4[3,3]=r(N)
restore

* Row 4: lab quality: household and bags

count if defects_lab_share_r!=.
matrix tabA4[4,1]=r(N)

count if defects_lab_share_r!=.&treatment==1
matrix tabA4[4,2]=r(N)

count if defects_lab_share_r!=.&treatment==0
matrix tabA4[4,3]=r(N)

gen lab_data=defects_lab_share_r!=.
reg lab_data treatment
matrix tabA4[4,4]=round(e(b)[1,1], 0.01)
matrix tabA4[5,4]=round((2 * normal(-abs(e(b)[1,1]/sqrt(e(V)[1,1])))), 0.01)


* Row 6:    III. Price & sales: # Households

count if price_2!=.
matrix tabA4[6,1]=r(N)

count if  price_2!=.&treatment==1
matrix tabA4[6,2]=r(N)

count if  price_2!=.&treatment==0
matrix tabA4[6,3]=r(N)

gen sales_data= price_2!=.
reg sales_data treatment
matrix tabA4[6,4]=round(e(b)[1,1], 0.01)
matrix tabA4[7,4]=round((2 * normal(-abs(e(b)[1,1]/sqrt(e(V)[1,1])))), 0.01)


* Row 6:    III. Price & sales: # Sales
preserve 
reshape long price_, i(hhh) j(sale)
keep if price_!=.
drop if sale==1

count
matrix tabA4[8,1]=r(N)

count if treatment==1
matrix tabA4[8,2]=r(N)

count if treatment==0
matrix tabA4[8,3]=r(N)

restore

matrix list tabA4


esttab matrix(tabA4,fmt(0 0 0 2)) using "$repfol/output/tables/Xtable_A4.rtf", replace title("{\b Table 4.} Sample: returns to quality experiment") note("Note: Sample sizes for the returns to quality experiment. Attrition rate is the share of households, out of all enrolled, not surveyed/tested at follow-up. Robust standard errors, with p-value reported below the estimate.") nonote  nogaps label varl(r1 "Enrolled: Households" r2 "   I. Visual quality: # Households" r3 "   I. Visual quality: # Bags" r4 "   II. Lab quality: # Household & bag" r5 " " r6 "   III. Price & sales: # Households" r7 " " r8 "   III. Price & sales: # Sales") refcat(r2 "Follow-ups:" , nolabel) collabels("All" "Treatment" "Control" "Attrition rate T vs. C (households) ") mlabel(" ") varwidth(35)


```

### `dofiles/XAppendix_table5.do`
```stata
* Online appendix Table 5

clear all 
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
matrix tabA6=J(18,3,.)


* Row 1 and 10: Baseline panel: household-season observations
count if group==1&season_ante==1
matrix tabA6[1,1]=r(N)

count if group==1&season_ante==1&buy_treatment==1
matrix tabA6[1,2]=r(N)

count if group==1&season_ante==1&buy_treatment==0
matrix tabA6[1,3]=r(N)

count if group==2&season_ante==1
matrix tabA6[10,1]=r(N)

count if group==2&season_ante==1&ext_treatment==1
matrix tabA6[10,2]=r(N)

count if group==2&season_ante==1&ext_treatment==0
matrix tabA6[10,3]=r(N)

* Row 2 and 11: Baseline panel: households
unique hhh_id if group==1&season_ante==1
matrix tabA6[2,1]=r(unique)

unique hhh_id if group==1&season_ante==1&buy_treatment==1
matrix tabA6[2,2]=r(unique)

unique hhh_id  if group==1&season_ante==1&buy_treatment==0
matrix tabA6[2,3]=r(unique)

unique hhh_id  if group==2&season_ante==1
matrix tabA6[11,1]=r(unique)

unique hhh_id  if group==2&season_ante==1&ext_treatment==1
matrix tabA6[11,2]=r(unique)

unique hhh_id  if group==2&season_ante==1&ext_treatment==0
matrix tabA6[11,3]=r(unique)


* Row 3 and 12: Baseline panel: clusters
unique ea_code if group==1&season_ante==1
matrix tabA6[3,1]=r(unique)

unique ea_code if group==1&season_ante==1&buy_treatment==1
matrix tabA6[3,2]=r(unique)

unique ea_code  if group==1&season_ante==1&buy_treatment==0
matrix tabA6[3,3]=r(unique)

unique ea_code  if group==2&season_ante==1
matrix tabA6[12,1]=r(unique)

unique ea_code  if group==2&season_ante==1&ext_treatment==1
matrix tabA6[12,2]=r(unique)

unique ea_code  if group==2&season_ante==1&ext_treatment==0
matrix tabA6[12,3]=r(unique)


* Row 4 and 13: Follow-up panel: household-season observations
count if group==1&season_post==1
matrix tabA6[4,1]=r(N)

count if group==1&season_post==1&buy_treatment==1
matrix tabA6[4,2]=r(N)

count if group==1&season_post==1&buy_treatment==0
matrix tabA6[4,3]=r(N)

count if group==2&season_post==1
matrix tabA6[13,1]=r(N)

count if group==2&season_post==1&ext_treatment==1
matrix tabA6[13,2]=r(N)

count if group==2&season_post==1&ext_treatment==0
matrix tabA6[13,3]=r(N)

* Row 5 and 14: Follow-up panel: households
unique hhh_id if group==1&season_post==1
matrix tabA6[5,1]=r(unique)

unique hhh_id if group==1&season_post==1&buy_treatment==1
matrix tabA6[5,2]=r(unique)

unique hhh_id  if group==1&season_post==1&buy_treatment==0
matrix tabA6[5,3]=r(unique)

unique hhh_id  if group==2&season_post==1
matrix tabA6[14,1]=r(unique)

unique hhh_id  if group==2&season_post==1&ext_treatment==1
matrix tabA6[14,2]=r(unique)

unique hhh_id  if group==2&season_post==1&ext_treatment==0
matrix tabA6[14,3]=r(unique)


* Row 6 and 15: Follow-up  panel: clusters
unique ea_code if group==1&season_post==1
matrix tabA6[6,1]=r(unique)

unique ea_code if group==1&season_post==1&buy_treatment==1
matrix tabA6[6,2]=r(unique)

unique ea_code  if group==1&season_post==1&buy_treatment==0
matrix tabA6[6,3]=r(unique)

unique ea_code  if group==2&season_post==1
matrix tabA6[15,1]=r(unique)

unique ea_code  if group==2&season_post==1&ext_treatment==1
matrix tabA6[15,2]=r(unique)

unique ea_code  if group==2&season_post==1&ext_treatment==0
matrix tabA6[15,3]=r(unique)

gen fup=1 if season_post==1
gen bsl=1 if season_ante==1
xfill fup bsl, i(hhh_id)

* Row 7 and 16: Follow-up panel: household-season observations
count if group==1&fup==1&bsl==1
matrix tabA6[7,1]=r(N)

count if group==1&buy_treatment==1&fup==1&bsl==1
matrix tabA6[7,2]=r(N)

count if group==1&buy_treatment==0&fup==1&bsl==1
matrix tabA6[7,3]=r(N)

count if group==2&fup==1&bsl==1
matrix tabA6[16,1]=r(N)

count if group==2&ext_treatment==1&fup==1&bsl==1
matrix tabA6[16,2]=r(N)

count if group==2&ext_treatment==0&fup==1&bsl==1
matrix tabA6[16,3]=r(N)

* Row 8 and 17: Follow-up panel: households
unique hhh_id if group==1&fup==1&bsl==1
matrix tabA6[8,1]=r(unique)

unique hhh_id if group==1&buy_treatment==1&fup==1&bsl==1
matrix tabA6[8,2]=r(unique)

unique hhh_id  if group==1&buy_treatment==0&fup==1&bsl==1
matrix tabA6[8,3]=r(unique)

unique hhh_id  if group==2&fup==1&bsl==1
matrix tabA6[17,1]=r(unique)

unique hhh_id  if group==2&ext_treatment==1&fup==1&bsl==1
matrix tabA6[17,2]=r(unique)

unique hhh_id  if group==2&ext_treatment==0&fup==1&bsl==1
matrix tabA6[17,3]=r(unique)


* Row 9 and 18: Follow-up  panel: clusters
unique ea_code if group==1&fup==1&bsl==1
matrix tabA6[9,1]=r(unique)

unique ea_code if group==1&buy_treatment==1&fup==1&bsl==1
matrix tabA6[9,2]=r(unique)

unique ea_code  if group==1&buy_treatment==0&fup==1&bsl==1
matrix tabA6[9,3]=r(unique)

unique ea_code  if group==2&fup==1&bsl==1
matrix tabA6[18,1]=r(unique)

unique ea_code  if group==2&ext_treatment==1&fup==1&bsl==1
matrix tabA6[18,2]=r(unique)

unique ea_code  if group==2&ext_treatment==0&fup==1&bsl==1
matrix tabA6[18,3]=r(unique)


matrix list tabA6

esttab matrix(tabA6,fmt(0 0 0)) using "$repfol/output/tables/Xtable_A5.rtf", replace title("{\b Table 5.} Samples: Market access and extension experiments") note("Note. Number of household-season observations, households, and clusters in the baseline and follow-up panels. ") nonote  nogaps label varl(r1 "Baseline panel: household-season observations" r2 "Baseline panel: households" r3 "Baseline panel: clusters" r4 "Follow-up panel: household-season observations" r5 "Follow-up panel: households" r6 "Follow-up panel: clusters" r7 "Baseline & Follow-up panel: household-season observations" r8 "Baseline & Follow-up panel: households" r9 "Baseline & Follow-up panel: clusters" r10 "Baseline panel: household-season observations" r11 "Baseline panel: households" r12 "Baseline panel: clusters" r13 "Follow-up panel: household-season observations" r14 "Follow-up panel: households" r15 "Follow-up panel: clusters" r16 "Baseline & Follow-up panel: household-season observations" r17 "Baseline & Follow-up panel: households" r18 "Baseline & Follow-up panel: clusters" ) refcat(r1 "\b{Panel A:} Market access experiment"  r10 "\b{Panel B:} Extension service experiments", nolabel) collabels("All" "Treatment" "Control" ) mlabel(" ") varwidth(50)


```

### `dofiles/XAppendix_table6.do`
```stata
* Online appendix Table 6

clear all 
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
matrix tabA7=J(8,5,.)


preserve
keep hhh_id survey_season group buy_treatment ext_treatment ea_code
gen surveyed=1
reshape wide surveyed, i(hhh_id)  j(survey_season)
forvalues s =1/8{
	replace surveyed`s'=0 if surveyed`s'==.
}

replace surveyed1=. if group==2
replace surveyed5=. if group==2
replace surveyed8=. if group==1

gen fup = surveyed4==1|surveyed5==1|surveyed6==1|surveyed7==1 if group==1
replace fup =surveyed6==1|surveyed7==1|surveyed8==1  if group==2
gen nofup=fup==0

gen control=buy_treatment!=1&ext_treatment!=1

*Households attritted during follow-up:
sum nofup if group==1
matrix tabA7[1,1]=r(mean)
matrix tabA7[1,5]=r(N)

estpost ttest nofup if group==1, by(control)
matrix tabA7[1,2]=e(mu_1)
matrix tabA7[1,3]=e(mu_2)
matrix tabA7[1,4]=e(b)
reg nofup control if group==1,cluster(ea_code)
matrix tabA7[2,4]=r(table)[4,1]

sum nofup if group==2
matrix tabA7[5,1]=r(mean)
matrix tabA7[5,5]=r(N)

estpost ttest nofup if group==2, by(control)
matrix tabA7[5,2]=e(mu_1)
matrix tabA7[5,3]=e(mu_2)
matrix tabA7[5,4]=e(b)

reg nofup control if group==2,cluster(ea_code)
matrix tabA7[6,4]=r(table)[4,1]

*Household-season re-survey rate
egen surveyedg1=rowmean(surveyed4-surveyed7) if group==1
egen surveyedg2=rowmean(surveyed6-surveyed8) if group==2

egen surveyeds1=rowtotal(surveyed4-surveyed7) if group==1
egen surveyeds2=rowtotal(surveyed6-surveyed8) if group==2

sum surveyedg1 if group==1&fup==1
matrix tabA7[3,1]=r(mean)

estpost ttest surveyedg1 if group==1&fup==1, by(control)
matrix tabA7[3,2]=e(mu_1)
matrix tabA7[3,3]=e(mu_2)
matrix tabA7[3,4]=e(b)
reg surveyedg1 control if group==1&fup==1,cluster(ea_code)
matrix tabA7[4,4]=r(table)[4,1]


sum surveyedg2 if group==2&fup==1
matrix tabA7[7,1]=r(mean)

estpost ttest surveyedg2 if group==2&fup==1, by(control)
matrix tabA7[7,2]=e(mu_1)
matrix tabA7[7,3]=e(mu_2)
matrix tabA7[7,4]=e(b)
reg surveyedg2 control if group==2&fup==1,cluster(ea_code)
matrix tabA7[8,4]=r(table)[4,1]

unique hhh_id if fup==1&group==1
matrix tabA7[3,5]=r(N)*4

unique hhh_id if fup==1&group==2
matrix tabA7[7,5]=r(N)*3

restore

matrix list tabA7

esttab matrix(tabA7,fmt(3 3 3 3 0)) using "$repfol/output/tables/Xtable_A6.rtf", replace title("{\b Table 6.} Attrition: Market access and extension experiments") note("Note. Share of households attritted and share of households not surveyed in follow-up seasons. Column (4) is difference in mean outcomes across assignment groups, with p-value on the null hypothesis of equal means reported below the estimate. Standard errors are clustered at the village level.") nonote  nogaps label varl(r1 "Households attritted during follow-up" r2 " " r3 "Household-season re-survey rate: follow-up" r4 " " r5 "Households attritted during follow-up" r6 " " r7 "Household-season re-survey rate: follow-up" r8 " "  ) refcat(r1 "{\b Panel A:} Market access experiment"  r5 "{\b Panel B:} Extension service experiments", nolabel) collabels("All" "Treatment" "Control" "Difference" "Obs.") mlabel(" ") varwidth(40)


```

### `dofiles/XAppendix_table7.do`
```stata
* Online appendix Table 7

use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep if group==2 & season_ante==1
matrix tabA7=J(16,7,.)

local row=0
*Panel A
preserve
collapse (max) mdm_female mdm_primary hhr_n distance_kibaale main_road_min  ext_treatment (first) ea_code, by(hhh_id )
foreach var of varlist mdm_female mdm_primary  hhr_n distance_kibaale main_road_min {
	local row=`row'+1
	sum `var' 
	matrix tabA7[`row',1] =( `r(mean)', `r(sd)')
	unique hhh_id 
	return list
	matrix tabA7[`row',3] =(`r(unique)')
	ttest `var' , by(ext_treatment)
	matrix tabA7[`row',4] =(`r(mu_2)', `r(mu_1)')
	xi: reg `var' ext_treatment , cluster(ea_code)
	matrix tabA7[`row',6] =(_b[ext_treatment],  (2 * ttail(e(df_r), abs(_b[ext_treatment]/_se[ext_treatment]))))
}

mat list tabA7
*Joint test I
xi: reg ext_treatment mdm_female mdm_primary  hhr_n distance_kibaale main_road_min, cluster(ea_code)
test mdm_female mdm_primary  hhr_n distance_kibaale main_road_min
matrix tabA7[14,7] =(`r(p)')
restore


foreach var of varlist  acreage expenses harvest_ton yield_ha_ton share_sold  price harvest_value surplus  {
	local row=`row'+1
	sum `var' 
	matrix tabA7[`row',1] =( `r(mean)', `r(sd)',  `r(N)')
	ttest `var' , by(ext_treatment)
	matrix tabA7[`row',4] =(`r(mu_2)', `r(mu_1)')
	xi: reg `var' ext_treatment i.survey_season, cluster(ea_code)
	matrix tabA7[`row',6] =(_b[ext_treatment],  (2 * ttail(e(df_r), abs(_b[ext_treatment]/_se[ext_treatment]))))

}


*Joint test II
xi: reg ext_treatment acreage harvest_ton yield_ha_ton share_sold  price harvest_value  i.survey_season, cluster(ea_code)
test  acreage harvest_ton yield_ha_ton share_sold  price harvest_value
matrix tabA7[15,7] =(`r(p)')


* * Joint test III
xi: reg ext_treatment acreage harvest_ton expenses yield_ha_ton share_sold  price harvest_value i.survey_season, cluster(ea_code)
test  acreage harvest_ton expenses yield_ha_ton share_sold  price harvest_value 
matrix tabA7[16,7] =(`r(p)')


esttab matrix(tabA7, fmt(a2 a2 0 a2 a2 3 3)) using "$repfol/output/tables/Xtable_A7.rtf", title("{\b Table 7.} Extension experiment: summary statistics and balance at baseline") replace onecell varwidth(40) refcat(r1 "{\b {\i Panel A.}} Household characteristics" r6 "{\b {\i Panel B.}} Farm enteprise characteristics" r14 "", nolabel) varl(r1 "Main decision-maker: female" r2 "Main decision-maker: completed primary school" r3 "Number of household members" r4 "Distance to district capital (km)" r5 "Distance to main road (min)" r6 "Maize acreage" r7 "Expenses (USD)" r8 "Harvest (ton)" r9 "Yield (ton/hectare)" r10 "Share sold" r11 "Price kilogram (USD)" r12 "Harvest value (USD)"  r13  "Profit I (USD)"  r14  "Joint balance test I" r15 "Joint balance test II" r16 "Joint balance test III" ) coll("Mean" "Sd." "Obs." "T" "C" "Coeff." "{\i p}")    noobs note("Note. Households in the baseline panel sample. Panel A: measured at first baseline round. Panel B: pooled data over the three baseline rounds. Difference in means conditioning on season fixed effects in Panel B. Standard errors are clustered at the village level. Expenses is expenses on inputs, equipment, transport and hired labor. Data on hired labor was not collected in season 1. Harvest value includes own-produced consumption, valued at community-specific market value. Profit I is the difference between harvest value and expenses. The joint balance tests report p-values from testing whether the baseline outcomes predict enrollment into treatment, with profit dropped due to collinearity: all household characteristics in test I; farm enterprise outcomes except expenses in test II (seasons 1-3; sample size 452); all farm enterprise outcomes in test III (seasons 2-3; sample size 317) ") nomti

```

### `dofiles/XAppendix_table8.do`
```stata
* Online appendix Table 8

use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep if (group==1 & season_ante==1) | (group==2 & season_ante==1)
matrix tabA8=J(16,9,.)

gen season=survey_season
replace season=survey_season-1 if group==2

local row=0
foreach group in 1 2 {
	foreach var of varlist  acreage expenses harvest_ton yield_ha_ton share_sold  price harvest_value surplus {
    
	local row=`row'+1

	sum `var' if season==1&  group==`group'
	if r(N)>1{
	matrix tabA8[`row',1] =( `r(mean)')
	matrix tabA8[`row',5] =( `r(sd)')
}
	sum `var' if season==2&group==`group'
	if r(N)>1{
	matrix tabA8[`row',2] =( `r(mean)')
	matrix tabA8[`row',6] =( `r(sd)')
}
	sum `var' if season==3&group==`group'
	if r(N)>1{
	matrix tabA8[`row',3] =( `r(mean)')
	matrix tabA8[`row',7] =( `r(sd)')
}	
	sum `var' if season<=3&group==`group'
	if r(N)>1{
	matrix tabA8[`row',4] =( `r(mean)')
	matrix tabA8[`row',8] =( `r(sd)')
	matrix tabA8[`row',9] =( `r(N)')
}	
	}

}


esttab matrix(tabA8, fmt(a2 a2 a2 a2 a2 a2 a2 a2 0)) using "$repfol/output/tables/Xtable_A8.rtf", title("{\b Table 8.} Farm enterprise characteristics at baseline: summary statistics") replace onecell varwidth(40) refcat(r1 "{\b {\i Panel A.}} Market Access Experiment" r9 "{\b {\i Panel B.}} Extension Service Experiment" , nolabel) varl(r1 "Maize acreage" r2 "Expenses (USD)" r3 "Harvest (ton)" r4 "Yield (ton/hectare)" r5 "Share sold" r6 "Price kilogram (USD)" r7 "Harvest value (USD)" r8 "Profit I (USD)" r9 "Maize acreage" r10 "Expenses (USD)" r11 "Harvest (ton)" r12 "Yield (ton/hectare)" r13 "Share sold" r14 "Price kilogram (USD)" r15 "Harvest value (USD)" r16 "Profit I (USD)" ) coll("Season 1" "Season 2" "Season 3" "Pooled" "Season 1" "Season 2" "Season 3" "Pooled" "Obs.")    noobs note("Note: Households in the baseline panel sample. Columns 1-4 report means. Columns 5-8 report standard deviations. Column 9 reports observation counts. Season 1-3 represents the order of seasons (spring 2017, fall 2017, spring 2018 in the market access experiment, and fall2017, spring 2018, fall 2018 in the extension service experiment). Expenses is expenses on inputs and hired labor. Data on hired labor was not collected in season 1. Harvest value includes own-produced consumption, valued at community-specific market value. Profit I is the difference between harvest value and expenses. Obs. is number of observations in the pooled sample.") mtitles("{\i Mean}")

```

### `dofiles/XAppendix_table9.do`
```stata
* Online appendix Table 9

use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep if group==1&buy_treatment==0
append using "$repfol\data\end\panel_g0_analysis.dta"

matrix tabA9=J(15,7,.)

local row=0
gen control=group==1
gen quasi_control=group==0

*Panel A
preserve
collapse (mean) mdm_female mdm_primary hhr_n distance_kakumiro control quasi_control (max) season_fall2018 (first) ea_code, by(hhh_id )

keep if season_fall2018==1
foreach var of varlist mdm_female mdm_primary  hhr_n distance_kakumiro  {
	local row=`row'+1
	sum `var' 
	matrix tabA9[`row',1] =( `r(mean)', `r(sd)', `r(N)')
	ttest `var' , by(quasi_control)
	matrix tabA9[`row',4] =(`r(mu_2)', `r(mu_1)')
	xi: reg `var' quasi_control , cluster(ea_code)
	matrix tabA9[`row',6] =(_b[quasi_control],  (2 * ttail(e(df_r), abs(_b[quasi_control]/_se[quasi_control]))))
}

	local row=`row'+1

*Joint test I
xi: reg quasi_control mdm_female mdm_primary  hhr_n distance_kakumiro  , cluster(ea_code)
test mdm_female mdm_primary  hhr_n distance_kakumiro 
matrix tabA9[14,7] =(`r(p)')
mat list tabA9
restore

keep if survey_season==4

foreach var of varlist  acreage expenses harvest_ton yield_ha_ton share_sold  price harvest_value  surplus  {
	local row=`row'+1
	sum `var' 
	matrix tabA9[`row',1] =( `r(mean)', `r(sd)',  `r(N)')
	ttest `var' , by(quasi_control)
	matrix tabA9[`row',4] =(`r(mu_2)', `r(mu_1)')
	xi: reg `var' quasi_control i.survey_season, cluster(ea_code)
	matrix tabA9[`row',6] =(_b[quasi_control],  (2 * ttail(e(df_r), abs(_b[quasi_control]/_se[quasi_control]))))

}


* * Joint test II
xi: reg quasi_control acreage harvest_ton expenses yield_ha_ton share_sold price harvest_value  i.survey_season if survey_season!=1, cluster(ea_code)
test  acreage harvest_ton expenses yield_ha_ton share_sold price harvest_value
matrix tabA9[15,7] =(`r(p)')


esttab matrix(tabA9, fmt(a2 a2 0 a2 a2 3 3)) using "$repfol/output/tables/Xtable_A9.rtf", title("{\b Table 9.} Baseline balance: Control and quasi-control") replace onecell varwidth(40) refcat(r1 "{\b {\i Panel A.}} Household characteristics" r6 "{\b {\i Panel B.}} Farm enteprise characteristics" r14 "", nolabel) varl(r1 "Main decision-maker: female" r2 "Main decision-maker: completed primary school" r3 "Number of household members" r4 "Distance to district capital (km)" r5 " " r6 "Maize acreage" r7 "Expenses (USD)" r8 "Harvest (ton)" r9 "Yield (ton/hectare)" r10 "Share sold" r11 "Price kilogram (USD)" r12 "Harvest value (USD)"  r13  "Profit I (USD)"  r14 "Joint balance test I" r15 "Joint balance test II"  ) coll("Mean" "Sd." "Obs." "QC" "C" "Coeff." "{\i p}")    noobs note("Note. Households in Sample Frame 1, control group (C) and all households in Sample Frame 3 (quasi-controls (QC)). Columns 1-3 report pooled outcomes. Columns 4-5 report means for QS and C. Columns 6-7 report differences in means. Panel A: measured at first baseline round. Panel B: measured in Season 4. Standard errors are clustered at the village level. Expenses is expenses on inputs and hired labor. Harvest value includes own-produced consumption, valued at community-specific market value. Profit I is the difference between harvest value and expenses. The joint balance tests report p-values from testing whether the baseline outcomes predict enrollment into quasi-control, with profit dropped due to collinearity: all household characteristics in test I; farm enterprise outcomes in test II (sample size 267). ") 


```

### `dofiles/intext_replication.do`
```stata

grstyle init 
grstyle set plain, horizontal nogrid
grstyle set compact


clear all 

*** A - Table_Section_IV_C_1
eststo clear

use "$repfol/data/end/quality_for_analysis.dta", clear
keep if quasicontrol==0&buy_treatment!=1
reshape long defects_visual_tot_  , i(hhh_id) j(number)
drop if defects_visual_tot_==.
gen defects_visual_tot_1=defects_visual_tot_ if treatment==1
gen defects_visual_tot_0=defects_visual_tot_ if treatment==0
gen any_defect_1=(defects_visual_tot_1>0)*100 if treatment==1
gen any_defect_0=(defects_visual_tot_0>0)*100 if treatment==0
eststo ts4c: estpost sum  defects_visual_tot_1 any_defect_1  defects_visual_tot_0 any_defect_0

esttab ts4c  using "$repfol/other/Table_Section_IV_C_1.rtf", replace c("mean(fmt(a1)) sd(fmt(a1)) min(fmt(a1)) max(fmt(a1))  count(fmt(a1))") varl(defects_visual_tot_1 "Number of defects" any_defect_1  "Bags with at least 1 defect (%)" defects_visual_tot_0 "Number of defects" any_defect_0  "Bags with at least 1 defect (%)") note("Number of defects and proportion of bags with at least one defects in the Treatment (panel A) and control (panel B) groups of the Returns to quality experiment") coll(Mean Sd. Min Max Obs.) refcat(defects_visual_tot_1 "{ \i {\b Panel A.} Treatment Group}" defects_visual_tot_0 "{ \i {\b Panel B.} Control Group}", nolabel)


*** B - Table_Section_IV_C_2
eststo clear

use "$repfol/data/end/quality_for_analysis.dta", clear
keep if quasicontrol==0&buy_treatment!=1
drop if excess_moisture_r==.
gen excess_moisture_r1=excess_moisture_r>0*100 if treatment==1
gen excess_moisture_r0=excess_moisture_r>0*100 if treatment==0

eststo ts4c: estpost sum  excess_moisture_r1 excess_moisture_r0

esttab ts4c  using "$repfol/other/Table_Section_IV_C_2.rtf", replace c("mean(fmt(2)) sd(fmt(2))  count(fmt(a1))") varl(excess_moisture_r1 "Bags with excess moisture (%)" excess_moisture_r0 "Bags with excess moisture (%)" ) note("Proportion of bags with moisture level above the threshold in the Treatment (panel A) and control (panel B) groups of the Returns to quality experiment") coll(Mean Sd. Obs.) refcat(excess_moisture_r1  "{ \i {\b Panel A.} Treatment Group}" excess_moisture_r0 "{ \i {\b Panel B.} Control Group}", nolabel)


*** C - Table_Section_IV_C_3
eststo clear

use "$repfol/data/end/quality_for_analysis.dta", clear
keep if quasicontrol==0&buy_treatment!=1

gen gr12=gr1+gr2
eststo ts4c: estpost ttest graded ungraded gr1 gr2 gr12 gr3, by(treatment)

esttab ts4c  using "$repfol/other/Table_Section_IV_C_3.rtf", replace c("mu_1(fmt(2)) mu_2(fmt(2))  count(fmt(a1))") varl( graded "Graded"  ungraded "Ungraded" gr1 "Grade 1" gr2 "Grade 2" gr12 "Grade 1 or 2" gr3 "Grade 3") note("Proportion of bags with graded, ungraded, grade 1, 2 or 3 maize in treatment and control groups of the Returns to quality experiment") coll(C T  Obs.) 


*** D - Table_Section_IV_C_4

eststo clear

use "$repfol/data/end/quality_for_analysis.dta", clear
keep if treatment!=.
reshape long deduct_totalshare100_ deductonly_totalshare100_ , i(hhh_id) j(bag_no)
drop if bag_no==1
gen dedmorethan5= (deduct_totalshare100_>5)*100 if deduct_totalshare100_!=.
ta dedmorethan5 
eststo ts4c: estpost sum deduct_totalshare100_ dedmorethan5  if treatment==0
esttab ts4c using "$repfol/other/Table_Section_IV_C_4.rtf", replace c(mean(fmt(1))) varl(deduct_totalshare100_ "Share deducted" dedmorethan5 "Sales with more than 5% deduction (%)") note("The deductions are the difference between the weight as measured by the buyer and the amount paid for.") coll("Mean")


*** E - Table_Section_IV_C_5
eststo clear

use "$repfol/data/end/quality_for_analysis.dta", clear
keep if treatment!=.
reshape long deduct_totalshare100_ deductonly_totalshare100_ , i(hhh_id) j(bag_no)
drop if bag_no==1
gen discrepancy=deduct_totalshare100_ -deductonly_totalshare100_
eststo ts4c: estpost sum deduct_totalshare100_ deductonly_totalshare100_ discrepancy if treatment==0
esttab ts4c using "$repfol/other/Table_Section_IV_C_5.rtf", replace c(mean(fmt(1)) sd(fmt(1) par)) varl(deduct_totalshare100_ "Total difference" deductonly_totalshare100_ "Deductions" discrepancy "Discrepancy") note("Total difference is the difference between the weight of the bag as measured by the research team and the amount the buyer paid for, in the control group only. The deductions are the difference between the weight as measured by the buyer and the amount paid for. The remaining discrepancy is the difference between the weight as measured by the research team and the weight measured by the buyer.") coll("Mean (Sd.)")


*** F - Table_Section_V_B_1

eststo clear 

use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep hhh_id survey_season group buy_treatment ext_treatment ea_code
gen surveyed=1
reshape wide surveyed, i(hhh_id)  j(survey_season)
forvalues s =1/8{
	replace surveyed`s'=0 if surveyed`s'==.
}

replace surveyed1=. if group==2
replace surveyed5=. if group==2
replace surveyed8=. if group==1

gen fup = surveyed4==1|surveyed5==1|surveyed6==1|surveyed7==1 if group==1
replace fup =surveyed6==1|surveyed7==1|surveyed8==1  if group==2
gen nofup=fup==0
gen allfup1= (surveyed4==1&surveyed5==1&surveyed6==1&surveyed7==1)*100 if group==1
gen allfup2 =(surveyed6==1&surveyed7==1&surveyed8==1 )*100 if group==2

eststo ts5b: estpost sum allfup1 allfup2 if fup==1
esttab ts5b using "$repfol/other/Table_Section_V_B_1.rtf", replace c("mean(fmt(0)) count") mtit("Non attriters surveyed in all follow-up seasons") varl(allfup1 "Group 1" allfup2  "Group 2") note("Non attriters surveyed in all follow-up seasons") coll("% " "Total Obs.") nonum


*** G - Table_Section_V_C_1
eststo clear

use "$repfol/data/end/sellers_for_analysis.dta", clear
collapse (max) hq buy_treatment,by(hhh_id survey_season)
keep if buy_treatment==1&survey_season>3
gen season_label="Season "+string(survey_season)

eststo ts5c: estpost tabstat hq ,by(season_label) s(mean count)

esttab ts5c  using "$repfol/other/Table_Section_V_C_1.rtf", replace cells("mean(fmt(a2)) count") label mlabel("Sold to high quality buyer") coll("Mean" "Count") noobs


*** H - Table_Section_V_C_2

eststo clear
use "$repfol/data/end/sellers_for_analysis.dta", clear
collapse (mean) share_hq=hq (max) hq buy_treatment,by(hhh_id survey_season)
  replace share_hq=share_hq*100
keep if buy_treatment==1&survey_season>3
eststo ts5c: estpost sum share_hq  if hq==1&survey_season==7

esttab ts5c using "$repfol/other/Table_Section_V_C_2.rtf", replace c("mean(fmt(0)) sd(fmt(1) ) count") varl(share_hq "Share of sales to high quality buyer (%)") coll(Mean Sd. Obs. ) noobs


*** I - Table_Section_V_C_3

eststo clear

use  "$repfol/data/end/panel_g1g2_analysis.dta", clear
eststo ts5c: estpost tab status if survey_season>5

esttab ts5c using "$repfol/other/Table_Section_V_C_3.rtf", replace c("pct(fmt(0)) b")  coll(%  Obs. ) mtitle(Interaction with high quality buyer) varwidth(50) noobs



*** J - Table_Section_V_C_4

preserve
use "$repfol/data/end/quality_for_analysis.dta", clear
keep if (quasicontrol==1|buy_treatment==1)&survey_season==7
gen defects_lab_share_r_grade2=(defects_lab_share_r-0.086)*100 ///maximum amount of defects in grade2 maize is 0.086

replace defects_lab_share_r_grade2=0 if defects_lab_share_r_grade2<0 
replace liveinsects=liveinsects*100
eststo ts4c1: estpost ttest defects_lab_share_r_grade2 wet_maize100_r liveinsects, by(buy_treatment)
esttab ts4c1 using "$repfol/other/Table_Section_V_C_4.rtf", replace c("mu_1(fmt(1)) mu_2(fmt(1)) "  ) varl(defects_lab_share_r_grade2 "Share of defects in random bag from lab tests (%)"  wet_maize100_r "Too much moisture (% of bags tested)" liveinsects_r "Has live insects (% of bags tested)") note("") mlabel(Mean) coll("Control" "Treatment")  varw(60)

restore

*** K - Table_Section_V_C_5

preserve
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
egen tot_labexp=rowtotal(expenses_labor_preharvest expenses_labor_postharvest),m 

reg ownhours buy_treatment i.survey_season if group==1&survey_season>4, cluster(ea_code)
local ownh_eff= _b[buy_treatment]
local ownh_p =r(table)[4,1]
reg hiredhours buy_treatment i.survey_season if group==1&survey_season>4, cluster(ea_code)
local hiredh_eff =_b[buy_treatment]
local hiredh_p= r(table)[4,1]
reg tot_labexp buy_treatment i.survey_season if group==1&survey_season>4, cluster(ea_code)
local hiredexp_eff =_b[buy_treatment]
local hiredexp_p= r(table)[4,1]

matrix define effects= [`ownh_eff' , `hiredh_eff' , `hiredexp_eff']
matrix colnames effects= ownhours  hiredhours tot_labexp

matrix define pvals= [`ownh_p' , `hiredh_p' , `hiredexp_p']
matrix colnames pvals= ownhours  hiredhours tot_labexp

eststo ts4c2: estpost ttest ownhours  hiredhours tot_labexp if group==1&survey_season>4, by(buy_treatment)
estadd matrix effects = effects 
estadd matrix pvals_cluster = pvals

mat list e(effects)

esttab ts4c2 using "$repfol/other/Table_Section_V_C_5.rtf", replace c("mu_1(fmt(1)) mu_2(fmt(1)) effects(fmt(1)) pvals_cluster(fmt(3)) count(fmt(0))" ) varl(ownhours "Family labour hours" tot_labexp "Hired labour expenses (USD)" hiredhours "Hired labour hours") note("Note: Data from last 3 seasons. Difference: average difference between treatment and control mean, controlling for season fixed effect. P-values clustered at village level.") coll("Mean Control" "Mean Treatment" "Difference" "{\i p-value}" "Obs.") noobs varwidth(50) nonum 
restore 

*** L - Table_Section_V_C_6

preserve 
use "$repfol/data/raw/panel_g1.dta", clear
keep if group==1&buy_treatment==0&survey_season>=6
egen acreage=rowtotal(plot_size_? plot_size_??), missing
replace acreage=0 if acreage==. & maize_tot_plotn==0
keep lc_prep_unit? lc_plant_unit? lc_weed_unit? lc_harv_unit? lc_prep_costs_unit? lc_plant_costs_unit? lc_weed_costs_unit? lc_harv_costs_unit? lc_prep_costs_season? lc_plant_costs_season? lc_weed_costs_season? lc_harv_costs_season? lh_prep_hours_season? lh_plant_hours_season? lh_weed_hours_season? lh_harv_hours_season? acreage
foreach act in prep plant weed harv{
    forvalues n=1/6{
	    cap confirm variable lc_`act'_unit`n'
		if !_rc   gen dailycost_`act'_`n'=  lc_`act'_costs_unit`n' if lc_`act'_unit`n'=="days"
}
egen med_dailycost_`act'=rowmedian(dailycost_`act'_?)
}
egen med_dailycost=rowmedian(med_dailycost_*)
egen daylywage=mode(med_dailycost)
sum daylywage
local hourlywage=round(r(mean)/6, 1) //assume 6 hrs a day
dis `hourlywage'

*keep if survey_season>=7
foreach act in prep plant weed harv{
   qui{ 
    cap drop lc_`act'_costs_season?i
	destring lc_`act'_costs_season?, replace
    egen lc_`act'=rowmean(lc_`act'_costs_season?)
	egen lh_`act'=rowmean(lh_`act'_hours_season?)
    gen hours_onlyhired_`act'=lc_`act'/`hourlywage' 
    gen hours_onlyown_`act'=lh_`act'
    gen hours_onlyhired_`act'_pa=hours_onlyhired_`act'/acreage
    gen hours_onlyown_`act'_pa=hours_onlyown_`act'/acreage
   }
	sum hours_onlyhired_`act'_pa if hours_onlyhired_`act'_pa!=0&hours_onlyown_`act'_pa==0
	local mean_`act'_hired=round(r(mean), 0.01)
	local n_`act'_hired=r(N)
	sum hours_onlyown_`act'_pa if hours_onlyhired_`act'_pa==0&hours_onlyown_`act'_pa!=0
	local mean_`act'_own=round(r(mean), 0.01)
	local n_`act'_own=r(N)
	local ratio_`act'= min(1, round( `mean_`act'_hired'/`mean_`act'_own', 0.01))
	
	dis "`mean_`act'_hired'   `mean_`act'_own'    `ratio_`act''"
}

local mean_ratio=(`ratio_prep'+`ratio_plant'+`ratio_weed'+`ratio_harv')/4
dis `mean_ratio'

mat ts4c3=J(1, 1,  `mean_ratio')
esttab matrix(ts4c3) using "$repfol/other/Table_Section_V_C_6.rtf", replace varl(r1 "Productivity of family labour relative to hired labour")  noobs varwidth(50) nonum nolabel coll(" ") note("Note: Data from the last season only")
restore

*** M - Table_Section_V_C_7
eststo clear

preserve
use "$repfol/data/end/panel_g1g2_analysis.dta", clear
keep if group==1
gen surplus_theta_hrs= harvest_value-expenses-ownhours_expenses*2/3
su surplus_theta_hrs
replace surplus_theta_hrs=surplus if season_ante==1

by hhh_id, sort: egen surplus_theta_hrs_p3=mean(surplus_theta_hrs) if season_spring2018==1
xfill surplus_theta_hrs_p3 , i(hhh_id)

by hhh_id, sort: egen surplus_theta_hrs_p=mean(surplus_theta_hrs) if season_ante==1 
xfill surplus_theta_hrs_p , i(hhh_id)

replace surplus_theta_hrs_p3=surplus_theta_hrs_p if surplus_theta_hrs_p3==. 

eststo ts5c: reg surplus_theta_hrs buy_treatment surplus_theta_hrs_p3 i.survey_season if  season_post==1 , cluster(ea_code)
	sum  surplus_theta_hrs if e(sample)==1&buy_treatment==0
	estadd local mean_control =round( `r(mean)', 0.01)

esttab ts5c using "$repfol/other/Table_Section_V_C_7.rtf", title("Effect of treatment on surplus with family labour opportunity cost at 2/3 of hired labour cost") nonote stats(N r2 mean_control , fmt( 0 2 2) labels(  "Observations" "R-squared" "Mean control")) cells(b(fmt(a2)) p(par fmt(3)) pvalues(par([ ]) fmt(3))) nogaps order(buy_treatment) keep(buy_treatment) onecell coefl(buy_treatment "market access experiment") label collabels(none) replace

restore


*** N - Table_Section_V_D_1

preserve
use "$repfol/data/end/sellers_for_analysis.dta", clear
keep if survey_season>3&priceb!=.

reg pricedif hq nohq_1  , vce(cluster ea_code)
local eff=_b[nohq_1]
reg nohq buy_treatment, vce(cluster ea_code)
local share=1+_b[buy_treatment]
reg pricedif buy_treatment  , vce(cluster ea_code)
local tot=_b[buy_treatment]

mat ts4d=J(1, 1,  round(`share'*`eff'/`tot'*100, 0.1))
mat list ts4d
esttab matrix(ts4d) using "$repfol/other/Table_Section_V_D_1.rtf", replace varl(r1 "Share of average increase in normalized prices coming from the increase in local market prices (%)")  noobs varwidth(50) nonum nolabel coll(" ")


restore


```

### `dofiles/table1.do`
```stata
* Table 1

clear all 
use "$repfol/data/end/quality_for_analysis.dta", clear

matrix tab1 = J(7, 5, .)

preserve
keep if quasicontrol==0
reshape long defects_visual_tot_ , i(hhh_id) j(number)

sum defects_visual_tot_ if treatment==0
return list
matrix tab1[1,1] =(round(`r(mean)', 0.1), round(`r(sd)', 0.1),round(`r(min)', 1), `r(max)', `r(N)')
restore

sum defects_lab_share100_r  if treatment==0|quasicontrol==1
matrix tab1[2,1] =(round(`r(mean)', 0.1), round(`r(sd)', 0.1), round(`r(min)', 1), round(`r(max)', 1), `r(N)')

sum wet_maize100_r if treatment==0|quasicontrol==1
matrix tab1[3,1] =(round(`r(mean)', 0.1), ., round(`r(min)', 1), round(`r(max)', 0.1), `r(N)')

local row 3
foreach grade in gr1 gr2 gr3 ungraded{
	local row  =`row'+1
	sum `grade' if treatment==0|quasicontrol==1
	matrix tab1[`row',1] =(round(`r(mean)'*100, 0.1), .,.,., `r(N)')

}
 

matrix list tab1

esttab matrix(tab1) using "$repfol/output/tables/table1.rtf", replace title("{\b Table 1.} Maize quality: Summary statistics") note("Note. Unit of observation is a bag. Visually verifiable quality is the number of detected defects out of 10 in a bag of maize. Lab verified quality is grams of defects per 200g maize sample drawn from bags bought in the field (in %). Wet maize is a binary indicator for maize with a moisture level above 13%. Grade 1-3 and ungraded/reject maize are East African Quality Standard (EAS) classifications for maize quality, with grade 1 having the most stringent thresholds for defects (see online Appendix B for details).") nonote coll("Mean" "Sd." "Min" "Max" "Obs.") nogaps  noobs nonum varl( r1 "Visually verifiable quality (#)" r2 "Lab verified quality (%)" r3 "Wet maize (%)" r4 "Grade 1: EAS (%)" r5 "Grade 2: EAS (%)" r6 "Grade 3: EAS (%)" r7 "Ungraded/reject: EAS (%)") nomtitle


```

### `dofiles/table2.do`
```stata
* Table 2

clear all 
use "$repfol/data/end/quality_for_analysis.dta", clear

preserve
keep if quasicontrol==0
reshape long defects_visual_tot_ defects_visual_mean_ excess_moisture_ , i(hhh_id) j(bagnum)

eststo c1: areg defects_visual_tot_ treatment, a(ea_code) cluster(hhh_id)

unique hhh_id if e(sample)==1
estadd local hhs_n =round(`r(unique)', 1)

sum  defects_visual_tot_ if e(sample)==1&treatment==0
estadd local mean_control =round(`r(mean)', 0.01)
restore

eststo c2: areg defects_lab_share_r treatment, a(ea_code) robust

unique hhh_id if e(sample)==1
estadd local hhs_n =round(`r(unique)', 1)

sum  defects_lab_share_r if e(sample)==1&treatment==0
estadd local mean_control =round(`r(mean)', 0.01)

preserve
keep if quasicontrol==0

reshape long price_ week_sale_ deduct_totalshare100_ net_priceavg_, i(hhh_id) j(salenum)
destring ea_code, replace ignore(EA)
drop if price_==.
drop if salenum==1 // all sales of the random bag to the research group are recorded as sale 1
eststo c3 : areg price_ treatment i.ea_code, cluster(hhh_id) a(week_sale_)

unique hhh_id if e(sample)==1
estadd local hhs_n =round(`r(unique)', 1)

sum  price_ if e(sample)==1&treatment==0
estadd local mean_control =round(`r(mean)', 0.01)

eststo c4 : areg deduct_totalshare100_ treatment i.ea_code, cluster(hhh_id) a(week_sale_)

unique hhh_id if e(sample)==1
estadd local hhs_n =round(`r(unique)', 1)

sum  deduct_totalshare100_ if e(sample)==1&treatment==0
estadd local mean_control =round(`r(mean)', 0.01)

eststo c5 : areg net_priceavg_ treatment i.ea_code, cluster(hhh_id) a(week_sale_)

unique hhh_id if e(sample)==1
estadd local hhs_n =round(`r(unique)', 1)

sum  net_priceavg_ if e(sample)==1&treatment==0
estadd local mean_control =round(`r(mean)', 0.01)

restore

esttab c1 c2 c3 c4 c5 using "$repfol/output/tables/table2.rtf", replace title("{\b Table 2.} Returns to quality: treatment effects") note("Note. Unit of observation is a bag in column (1); a random sample from one bag per household in column (2); and maize sale in columns (3)-(5). Defects (visually verifiable) is the number defects (out of 10) verified by trained enumerators in maize bags for sale. Defects (lab) is grams of defects per 200g maize as measured in the lab. Price (p) is in UGX per kilogram. Deductions is defined as (y-z)/y, where y is the weight of maize sold as measured by enumerators and z is the agreed upon (or by the buyer determined) sales volume, expressed in percent. Net-price is price net of any weight deductions; i.e., pz/y, in UGX per kilogram. Specifications (1)-(2) include villages fixed effect. All sales specifications include village fixed effects and week fixed effects. Robust standard errors in column (2) and clustered by household standard errors in parentheses in columns (1), (3)-(5). p-values in brackets. ") nonote  nogaps label stats(N  hhs_n  r2  mean_control , fmt( 0 0 2 2) labels(  "Observations" "Households" "R-squared" "Mean control"))  cells(b(fmt(2)) se(par fmt(3 3 2 3 1 )) p(par([ ]) fmt(3))) keep(treatment) varl(treatment "Treatment") collabels(none) onecell mlabel( "Defects (visually verifiable)" "Defects (lab)" "Price" "Deductions" "Net-price")


```

## How to run a script

Write each script to a file under the output directory, then run it with
exactly this command (the data directory is mounted read-only at its own
path; nothing else from the host is visible; `$SCRIPT` is the absolute path of
the script you wrote):

    SCRIPT=<repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/script.R   # or <repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/attempt-<n>/script.R
    uv run --directory <repo> python -m benchmark.reproducers.run_sandbox --timeout 300 --label retally.run=claude-code-bold-2022-market-access-quality-upgrading-seeded-2026-11-10-a --run-dir "$(dirname "$SCRIPT")" -- docker run --rm --label retally.run=claude-code-bold-2022-market-access-quality-upgrading-seeded-2026-11-10-a --network none --memory 4g --cpus 1.0 --read-only --tmpfs /tmp:size=256m --cap-drop ALL --security-opt no-new-privileges -v "$SCRIPT":/workspace/script.R:ro -v <repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading:<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading:ro --workdir /workspace retally-sandbox-r:latest Rscript /workspace/script.R; echo "exit code: $?"

The sandbox time limit is 300 seconds (memory 4g, 1.0 CPU).  The
command enforces it: `run_sandbox` runs the `docker run` after `--`, writes
its output to `stdout.txt` and `stderr.txt` next to the script, and writes
`timing.json` there too (wall-clock seconds, and whether the limit was
hit).  If the limit is hit it kills the container, appends a line saying
so to `stderr.txt` and exits with code 124: treat the run as a crash.  Do
not add your own timeout, do not redirect its output yourself, and do not
delete `timing.json`; keep it with the run's other files.

If a `docker run` produces no output for more than ten minutes (no
container output, no error, the command does not return), the Docker
daemon is probably wedged.  Stop: kill the command, and do not restart
Docker Desktop or the Docker daemon yourself.  The hung attempt is not
counted: do not save it as an `attempt-<n>` directory or as the final run,
and say in `notes` that it hung.  Report it in your final message (which
step hung, and for how long) instead of retrying.

## Output contract

The output directory `<repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a` already holds `render.json`; leave it
there.  Add:

```
<repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/
  script.R  stdout.txt  stderr.txt  timing.json   # the FINAL run: its RESULT: lines are what is scored
  attempt-1/  attempt-2/  ...           # every execution BEFORE the final one, in order
    script.R  stdout.txt  stderr.txt  timing.json  feedback.txt   # feedback.txt when kind is not ""
  reproduction.json                     # written LAST
```

- `attempt-<n>` directories are every execution before the final one, in
  the order they ran; the final files at the top are the run whose
  `RESULT:` lines are scored.  If you go back to an earlier attempt, copy
  that attempt's files to the top level as the final run.
- `feedback.txt` holds what you acted on before the next attempt: the error
  you fixed (`kind: "error"`) or the `check_attempt` comparison
  (`kind: "claim"`).
- Exploratory runs (inspecting variables, counting rows, checking a filter;
  no estimate of a listed quantity) are attempts with `kind: ""` and need no
  `feedback.txt`.  They must NOT print any `RESULT:` line, not even a
  placeholder: the first run that prints one is scored as your first scored
  attempt.  Print `RESULT:` lines only from a script that estimates the
  listed quantities, and `kind: "error"` only for a run that crashed or
  that was meant to print them and did not.
- Write `reproduction.json` last, in this schema:

```
reproduction.json (schema 1), written last by the agent into its run directory
benchmark/reproductions/<entry_id>/<mode>/<run_id>/:

{
  "schema": 1,
  "entry_id": "montero-2022-cooperative-property-rights",
  "mode": "independent",
  "run_id": "2026-10-22-a",
  "reproducer": "claude-code",
  "language": "r",
  "final": {"script": "script.R", "stdout": "stdout.txt", "stderr": "stderr.txt", "exit_code": 0},
  "attempts": [
    {"dir": "attempt-1", "exit_code": 1, "kind": "error"},
    {"dir": "attempt-2", "exit_code": 0, "kind": "claim"}
  ],
  "deviations": [],
  "notes": "free text: what the agent did, what it could not do",
  "files_read_outside_mount": [],
  "started_at": "2026-10-22T10:00:00Z",
  "finished_at": "2026-10-22T10:40:00Z"
}

* entry_id, mode and run_id must match the directory the file sits in.
* final: the run that is scored -- script.R, stdout.txt, stderr.txt at the
  run-dir root, and its exit code.  If the agent reverts to an earlier
  attempt it copies that attempt's files there.
* attempts: every execution before the final one, oldest first.  Each
  attempt-<n>/ holds script.R, stdout.txt, stderr.txt, and feedback.txt
  when kind is not "".  kind is the refinement that followed it:
  "error" (it crashed or printed no RESULT: line; the agent repaired it),
  "claim" (the agent compared its RESULT: values with the claimed values
  and changed the script; never allowed in blind mode), or "" (neither).
* All paths are relative to the run directory; absolute paths and ".."
  are rejected.
* deviations: free-text methodology changes, in addition to any
  DEVIATION: lines in the final stdout.
* The numbers scored are the RESULT: lines of the files, never anything
  written in this JSON.
```

End your final message with the final run's `RESULT:` lines and a short
note.  Nothing needed for scoring may live only in the message: the files
are the record.

Do not edit any file in the repository; your only writes are under `<repo>/benchmark/reproductions/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a`.
