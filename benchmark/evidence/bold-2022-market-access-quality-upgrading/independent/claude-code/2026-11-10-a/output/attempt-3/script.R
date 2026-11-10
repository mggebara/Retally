suppressMessages({library(haven); library(dplyr); library(readxl); library(tidyr)})
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
options(width = 250)
# survey instrument add5 and add4
for (f in c("survey_materials/return_survey/add5_bags_sales.xlsx", "survey_materials/return_survey/add4_measuring_bags.xlsx")) {
  cat("=====", f, "\n"); print(excel_sheets(paste0(B, f)))
  s <- read_excel(paste0(B, f), sheet = 1)
  cat(paste(names(s), collapse = " | "), "\n")
  keep <- intersect(c("type", "name", "label", "label::English", "relevance", "calculation", "repeat_count", "constraint"), names(s))
  s <- s[, keep]
  for (i in seq_len(nrow(s))) {
    r <- s[i, ]; if (all(is.na(r))) next
    cat(i, ":", paste(substr(ifelse(is.na(unlist(r)), "", unlist(r)), 1, 110), collapse = " || "), "\n")
  }
}
r <- read_dta(paste0(D, "anonym_returns_data.dta"))
cat("==== returns\n")
print(table(r$treatment, r$ea_code))
# per sale (suffix) count weights
for (k in 1:4) {
  w <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", k)])
  nb <- rowSums(!is.na(w))
  cat("sale", k, "ppk nonmiss", sum(!is.na(r[[paste0("add5_ppk_", k)]])), " hh with any weight", sum(nb > 0),
      " both", sum(nb > 0 & !is.na(r[[paste0("add5_ppk_", k)]])), " date nonmiss", sum(!is.na(r[[paste0("add5_sold_when_e_", k)]]) & r[[paste0("add5_sold_when_e_", k)]] != ""), "\n")
}
print(head(as.data.frame(r[, c("hhh_id", "treatment", paste0("add5_ppk_", 1:4), paste0("add5_sold_when_e_", 1:4), paste0("add5_ind_weight1_", 1:4), paste0("add5_ind_ded_weight1_", 1:4))]), 40))
# visual defects
defs <- c("dirty", "cobs", "stones", "dust", "insect", "insect_live", "broken", "immature", "damage", "rot", "mould")
nbag <- 0; nbag2 <- 0
for (b in 1:20) {
  wt <- r[[paste0("add4_weight_", b)]]
  anyd <- rep(FALSE, nrow(r))
  for (d in defs) { v <- paste0("add4_", d, "_", b); if (v %in% names(r)) anyd <- anyd | !is.na(r[[v]]) }
  nbag <- nbag + sum(!is.na(wt)); nbag2 <- nbag2 + sum(anyd)
}
cat("bags with weight", nbag, " bags with any defect var", nbag2, "\n")
for (b in 1:3) { m <- sapply(defs, function(d) sum(!is.na(r[[paste0("add4_", d, "_", b)]]))); print(m) }
print(table(treat = r$treatment, nb = rowSums(!is.na(as.matrix(r[, paste0("add4_weight_", 1:20)])))))
print(table(r$add4_random_bag))
cat("lab: \n"); print(summary(r$Total_weight_of_maize_g)); print(table(is.na(r$Total_weight_of_maize_g), r$treatment))
print(head(as.data.frame(r[, c("hhh_id", "add1_harvest_new_when_e_1", "add4_moisture_1", "add4_weight_1", "add4_weight_2", "add4_random_bag")]), 10))
cat("==== panel_g1\n")
g <- read_dta(paste0(D, "panel_g1.dta"))
print(table(g$survey_season, g$buy_treatment))
print(table(g$survey_season, g$form_used))
print(g %>% group_by(survey_season) %>% summarise(n = n(), hk = sum(!is.na(harvest_kg)), hk1 = sum(!is.na(harvest_kg_1)), ac = sum(!is.na(acres_tot)), ps1 = sum(!is.na(plot_size_1)),
  lab1 = sum(!is.na(tot_lab_costs_1)), lhp = sum(!is.na(lh_prep_hours_season1)), lcp = sum(!is.na(lc_prep_costs_season1)), sk = sum(!is.na(sold_kg_p_1)), rev = sum(!is.na(tot_rev_combined_1)),
  rev11 = sum(!is.na(tot_rev_combined_1_1)), seeds = sum(!is.na(seeds_cost_1)), chem = sum(!is.na(tot_chem_costs_1)), phl = sum(!is.na(labor_cost_ph)), oph = sum(!is.na(otherph_cost)), tr = sum(!is.na(tot_transport_cost)),
  ctp = sum(!is.na(cost_transportpost)), dec = sum(!is.na(decob)), mean_hk = mean(harvest_kg, na.rm = TRUE), mean_ac = mean(acres_tot, na.rm = TRUE)) %>% as.data.frame())
# harvest_kg vs sum of plot harvests
hs <- rowSums(as.matrix(g[, paste0("harvest_kg_", 1:6)]), na.rm = TRUE)
ps <- rowSums(as.matrix(g[, paste0("plot_size_", 1:6)]), na.rm = TRUE)
print(summary(g$harvest_kg - hs)); print(summary(g$acres_tot - ps))
print(head(as.data.frame(g[g$survey_season == 5, c("hhh_id", "harvest_kg", paste0("harvest_kg_", 1:3), "acres_tot", paste0("plot_size_", 1:3), "maize_tot_plotn", "tot_lab_costs_1", "lc_prep_costs_season1", "lc_plant_costs_season1", "lc_weed_costs_season1", "lc_spray_costs_season1", "lc_harv_costs_season1", "lh_prep_hours_season1", "sold_kg_p_1", "tot_rev_combined_1", "tot_rev_combined2_1", "tot_rev_combined_1_1")]), 15))
print(head(as.data.frame(g[g$survey_season == 1, c("hhh_id", "harvest_kg", paste0("harvest_kg_", 1:3), "acres_tot", paste0("plot_size_", 1:3), "maize_tot_plotn", "tot_lab_costs_1", "lc_prep_costs_season1", "lh_prep_hours_season1", "sold_kg_p_1", "tot_rev_combined_1", "tot_rev_combined_1_1", "labor_cost_ph", "otherph_cost")]), 10))
cat("hh in followup:", length(unique(g$hhh_id[g$survey_season >= 4])), " obs followup:", sum(g$survey_season >= 4), "\n")
cat("==== seller\n")
s <- read_dta(paste0(D, "seller_data.dta"))
print(head(as.data.frame(s), 20))
print(s %>% group_by(survey_season) %>% summarise(n = n(), nh = n_distinct(hhh_id), p = mean(price[price > 0]), p0 = sum(price == 0)) %>% as.data.frame())
cat("==== buy\n"); b <- read_dta(paste0(D, "buy_data.dta")); print(head(as.data.frame(b))); print(table(b$status, b$survey_season))
