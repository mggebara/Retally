suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading/data/raw/"
options(width=250, dplyr.width=250)
g1 <- zap_labels(read_dta(paste0(D,"panel_g1.dta")))
cat("hired labor unit costs by unit (all plots 1, follow-up)\n")
for (a in c("prep","plant","weed","spray","harv")) {
  u <- g1[[paste0("lc_",a,"_unit1")]]; c <- g1[[paste0("lc_",a,"_costs_unit1")]]
  for (uu in c("hours","days","season")) { x <- c[u==uu & !is.na(c) & c>0]; if (length(x)) cat(a, uu, "n=", length(x), "median=", median(x), "mean=", mean(x), "q=", quantile(x, c(.1,.25,.75,.9)), "\n") }
}
cat("family hours per unit\n")
for (a in c("prep","plant","weed","spray","harv")) {
  u <- g1[[paste0("lh_",a,"_unit1")]]; h <- g1[[paste0("lh_",a,"_hours_unit1")]]
  for (uu in c("hours","days","season")) { x <- h[u==uu & !is.na(h) & h>0]; if (length(x)) cat(a, uu, "n=", length(x), "median=", median(x), "mean=", mean(x), "\n") }
}
cat("check lc season = unit cost * ? \n")
print(head(as.data.frame(g1 %>% filter(lc_weed_unit1=="days") %>% select(survey_season, lc_weed_unit1, lc_weed_costs_unit1, lc_weed_costs_season1, lh_weed_unit1, lh_weed_hours_unit1, lh_weed_hours_season1)), 15))
cat("transport\n"); print(summary(g1 %>% filter(survey_season>=5) %>% transmute(d=tot_transport_cost - cost_transportpre - cost_transportpost)))
cat("ph check\n"); f <- g1 %>% filter(survey_season>=5)
lab <- rowSums(cbind(f$lc_decob_labour_costs, f$lc_winnow_labour_costs, f$lc_sort_labour_costs, f$lc_bag_labour_costs), na.rm=TRUE)
oth <- rowSums(cbind(f$lc_decob_other_costs, f$lc_winnow_other_costs, f$lc_sort_other_costs, f$lc_bag_other_costs), na.rm=TRUE)
print(table(abs(f$labor_cost_ph-lab)<1, useNA="ifany")); print(table(abs(f$otherph_cost-oth)<1, useNA="ifany"))
lab2 <- lab + rowSums(cbind(f$lc_decob_labmaize_costs, f$lc_winnow_labmaize_costs, f$lc_sort_labmaize_costs, f$lc_bag_labmaize_costs), na.rm=TRUE)
print(table(abs(f$labor_cost_ph-lab2)<1, useNA="ifany"))
print(head(as.data.frame(f %>% mutate(lab=lab, oth=oth) %>% filter(abs(labor_cost_ph-lab)>=1 | abs(otherph_cost-oth)>=1) %>% select(survey_season, labor_cost_ph, lab, otherph_cost, oth, drying_cost, storage_cost, labor_cost_store, lc_decob_labmaize_costs, lc_decob_price)), 20))
cat("drying/storage nonzero by season\n"); print(g1 %>% group_by(survey_season) %>% summarise(dry=mean(drying_cost>0,na.rm=T), drym=mean(drying_cost,na.rm=T), sto=mean(storage_cost>0,na.rm=T), stl=mean(labor_cost_store,na.rm=T), ldry=mean(labor_cost_dry,na.rm=T), ph=mean(labor_cost_ph,na.rm=T), oph=mean(otherph_cost,na.rm=T), tr=mean(tot_transport_cost,na.rm=T), trp=mean(cost_transportpre,na.rm=T), trq=mean(cost_transportpost, na.rm=T), hc=mean(harvest_cost_1,na.rm=T), eq=mean(equipment_cost_1,na.rm=T), dc=mean(decobbing_cost_1,na.rm=T)) %>% as.data.frame())
cat("season 2/3 rows example\n")
x <- g1 %>% filter(survey_season==2) %>% head(2)
for (v in names(g1)) { vals <- x[[v]]; if (any(!is.na(vals) & as.character(vals)!="")) cat(v, ":", paste(as.character(vals), collapse=" | "), "\n") }
x <- g1 %>% filter(survey_season==4) %>% head(2)
for (v in names(g1)) { vals <- x[[v]]; if (any(!is.na(vals) & as.character(vals)!="")) cat(v, ":", paste(as.character(vals), collapse=" | "), "\n") }
x <- g1 %>% filter(survey_season==1) %>% head(2)
for (v in names(g1)) { vals <- x[[v]]; if (any(!is.na(vals) & as.character(vals)!="")) cat(v, ":", paste(as.character(vals), collapse=" | "), "\n") }
x <- g1 %>% filter(form_used=="Phone_Market_Survey_spring2020") %>% head(2)
for (v in names(g1)) { vals <- x[[v]]; if (any(!is.na(vals) & as.character(vals)!="")) cat(v, ":", paste(as.character(vals), collapse=" | "), "\n") }
s <- zap_labels(read_dta(paste0(D,"seller_data.dta")))
cat("seller name codes\n"); print(head(sort(table(s$name), decreasing=TRUE), 10)); print(table(s$survey_season, s$name==555, useNA="ifany"))
cat("price==0 rows\n"); print(s[s$price<=0 | s$sold_kg_p_<=0,])
