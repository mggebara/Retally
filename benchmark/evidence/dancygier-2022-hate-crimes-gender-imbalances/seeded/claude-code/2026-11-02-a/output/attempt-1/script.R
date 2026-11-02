library(haven)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/seeded/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D, "survey.dta"))
vars <- c("wave","hate_violence_means","MateComp.cont","JobComp.cont","LifeSatis.cont","age_group","gender","state","citizenship","marital","religion","eduyrs","occupation","income","household_size","self_econ","ref_integrating","ref_citizenship","ref_reduce","ref_moredone","ref_cultgiveup","ref_economy","ref_crime","ref_terror","ref_loc_services","ref_loc_economy","ref_loc_crime","ref_loc_culture","ref_loc_islam","ref_loc_schools","ref_loc_housing","ref_loc_wayoflife","distance_ref","settle_ref","lrscale","afd","muslim_ind","afd_ind","contact_ind")
for (v in vars) { x <- s[[v]]; lab <- attr(x,"labels"); u <- sort(unique(as.vector(x)))
  cat(v, class(x)[1], "nuniq", length(u), "labelled:", !is.null(lab), "nlab", length(lab), "unlabelled vals:", if(!is.null(lab)) length(setdiff(u[!is.na(u)], lab)) else NA, "head:", head(u,6), "\n") }
print(table(s$wave))
c4 <- read_dta(file.path(D, "context.dta"))
cv <- c("year","Hate_all_muni","Hate_all_muni_bin","pop_15_44_muni_gendergap_2015","log_population_muni_2015","log_popdens_muni_2015","log_unemp_all_muni_2015","d_pop1511_muni","vote_afd_2013_muni","log_ref_inflow_1514","log_pop_ref_2014","log_violence_percap_2015","pc_hidegree_all2011","d_manuf1115","pc_manufacturing_2015","unemp_gendergap_2015","ags_state","ags_county")
for (v in cv) cat(v, class(c4[[v]])[1], "NA", sum(is.na(c4[[v]])), "\n")
print(table(c4$year)); cat(nrow(c4), "\n")
cat(head(c4$ags_muni), "\n")
