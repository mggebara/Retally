suppressMessages(library(haven))
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/seeded/2026-11-02-b/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D, "survey.dta"))
vars <- c("wave","hate_violence_means","MateComp.cont","JobComp.cont","LifeSatis.cont","age_group","gender","state","citizenship",
          "marital","religion","eduyrs","occupation","income","household_size","self_econ","ref_integrating","ref_citizenship",
          "ref_reduce","ref_moredone","ref_cultgiveup","ref_economy","ref_crime","ref_terror","ref_loc_services","ref_loc_economy",
          "ref_loc_crime","ref_loc_culture","ref_loc_islam","ref_loc_schools","ref_loc_housing","ref_loc_wayoflife",
          "distance_ref","settle_ref","lrscale","afd","muslim_ind","afd_ind","contact_ind")
cat("missing vars:", setdiff(vars, names(s)), "\n")
for (v in intersect(vars, names(s))) {
  x <- s[[v]]
  lab <- attr(x, "labels")
  cat(v, class(x)[1], "nlabels=", length(lab), "nuniq=", length(unique(x)), "NA=", sum(is.na(x[s$wave==4])),
      "vals:", paste(head(sort(unique(as.numeric(x))), 12), collapse=","), "\n")
}
print(table(s$wave))
cx <- read_dta(file.path(D, "context.dta"))
cat("context dims", dim(cx), "\n")
print(table(cx$year))
idv <- intersect(c("ags_muni","ags_county","ags_state"), names(cx)); print(idv)
a <- cx$ags_muni[cx$year==2015]; b <- cx$ags_muni[cx$year==2016]; c2 <- cx$ags_muni[cx$year==2017]
cat("aligned:", identical(as.character(a), as.character(b)), identical(as.character(a), as.character(c2)), "\n")
for (v in c("Hate_all_muni","Hate_all_muni_bin","pop_15_44_muni_gendergap_2015","log_population_muni_2015","log_popdens_muni_2015",
            "log_unemp_all_muni_2015","d_pop1511_muni","vote_afd_2013_muni","log_ref_inflow_1514","log_pop_ref_2014",
            "log_violence_percap_2015","pc_hidegree_all2011","d_manuf1115","pc_manufacturing_2015","unemp_gendergap_2015","ags_county","ags_state"))
  cat(v, if (v %in% names(cx)) paste(class(cx[[v]])[1], "NA=", sum(is.na(cx[[v]]))) else "MISSING", "\n")
