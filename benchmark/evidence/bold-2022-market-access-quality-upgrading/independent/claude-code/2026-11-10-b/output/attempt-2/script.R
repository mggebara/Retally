suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw"
options(width = 250, dplyr.width = Inf, tibble.width = Inf)
r <- read_dta(file.path(D, "anonym_returns_data.dta"))
cat("classes of sold_when:", class(r$add5_sold_when_e_1), "\n")
print(head(r$add5_sold_when_e_1, 10)); print(head(r$add5_sold_when_e_2, 10))
cat("ea per treatment\n"); print(table(r$ea_code, r$treatment))
# per household summary
nb <- function(pref, k) { v <- paste0(pref, 1:20, "_", k); rowSums(!is.na(as.matrix(r[, v]))) }
sw <- function(pref, k) { v <- paste0(pref, 1:20, "_", k); rowSums(as.matrix(r[, v]), na.rm = TRUE) }
bagw <- paste0("add4_weight_", 1:20)
s <- data.frame(id = r$hhh_id, tr = r$treatment, nbags = rowSums(!is.na(as.matrix(r[, bagw]))), wtot = rowSums(as.matrix(r[, bagw]), na.rm = TRUE),
  rb = r$add4_random_bag,
  p1 = r$add5_ppk_1, p2 = r$add5_ppk_2, p3 = r$add5_ppk_3, p4 = r$add5_ppk_4,
  d1 = as.character(r$add5_sold_when_e_1), d2 = as.character(r$add5_sold_when_e_2), d3 = as.character(r$add5_sold_when_e_3), d4 = as.character(r$add5_sold_when_e_4),
  n1 = nb("add5_ind_weight", 1), n2 = nb("add5_ind_weight", 2), n3 = nb("add5_ind_weight", 3), n4 = nb("add5_ind_weight", 4),
  w1 = sw("add5_ind_weight", 1), w2 = sw("add5_ind_weight", 2), w3 = sw("add5_ind_weight", 3), w4 = sw("add5_ind_weight", 4),
  dw1 = sw("add5_ind_ded_weight", 1), dw2 = sw("add5_ind_ded_weight", 2), dw3 = sw("add5_ind_ded_weight", 3), dw4 = sw("add5_ind_ded_weight", 4))
print(s)
cat("total bags with weight:", sum(s$nbags), "\n")
# bag-level defect availability
defs <- c("dirty","cobs","stones","dust","insect","insect_live","broken","immature","damage","rot","mould")
for (b in 1:20) {
  w <- r[[paste0("add4_weight_", b)]]
  cat(sprintf("bag %2d: weight n=%d; ", b, sum(!is.na(w))))
  for (d in defs) { x <- r[[paste0("add4_", d, "_", b)]]; cat(sprintf("%s=%d/%d ", d, sum(!is.na(x) & !is.na(w)), sum(!is.na(x)))) }
  cat("\n")
}
# label values of defect vars
print(attributes(r$add4_cobs_1)); print(attributes(r$add4_dirty_1)); print(table(r$add4_dirty_1, useNA="a")); print(table(r$add4_cobs_1, useNA="a"))
print(table(r$add4_weight_1 < 20)); print(sort(unlist(r[, bagw]))[1:10])
cat("lab vars\n"); print(summary(r[, c("Total_weight_of_maize_g","Foreign_matter_tot_g","Inorganic_matter_tot_g","Broken_grains_tot_g","Pest_damaged_grains_tot_g","Rotten_and_diseased_grain","Discoloured_grains_tot_g","Immature_or_shrivelled_gr")]))
print(table(r$treatment, !is.na(r$Total_weight_of_maize_g)))
print(r[is.na(r$Foreign_matter_tot_g) | is.na(r$Broken_grains_tot_g) | is.na(r$Discoloured_grains_tot_g), c("hhh_id","treatment","Total_weight_of_maize_g","Foreign_matter_tot_g","Broken_grains_tot_g","Discoloured_grains_tot_g","Pest_damaged_grains_tot_g")])
cat("other char vars\n"); print(table(r$Total_aflatoxins)); print(head(r$add1_harvest_new_when_e_1))

## panel_g1
p <- read_dta(file.path(D, "panel_g1.dta"))
cat("\nPANEL g1\n"); print(table(p$survey_season, p$buy_treatment)); print(table(p$survey_season, p$form_used))
print(table(p$survey_season, p$survey_round))
print(p %>% group_by(survey_season) %>% summarise(n = n(), hk = sum(!is.na(harvest_kg)), hk1 = sum(!is.na(harvest_kg_1)), acres = sum(!is.na(acres_tot)), ps1 = sum(!is.na(plot_size_1)), tl1 = sum(!is.na(tot_lab_costs_1)), lc1 = sum(!is.na(lc_prep_costs_season1)), lh1 = sum(!is.na(lh_prep_hours_season1)), rev1 = sum(!is.na(tot_rev_combined_1)), sk1 = sum(!is.na(sold_kg_p_1)), chem = sum(!is.na(tot_chem_costs_1)), seeds = sum(!is.na(seeds_cost_1)), tr = sum(!is.na(tot_transport_cost)), ctp = sum(!is.na(cost_transportpost)), lph = sum(!is.na(labor_cost_ph)), oph = sum(!is.na(otherph_cost)), dec = sum(!is.na(lc_decob_labour_costs)), mhk = mean(harvest_kg, na.rm=TRUE), mac = mean(acres_tot, na.rm=TRUE)))
# check harvest_kg vs sum harvest_kg_k
hk <- rowSums(as.matrix(p[, paste0("harvest_kg_", 1:6)]), na.rm = TRUE)
print(summary(p$harvest_kg - hk)); print(table(abs(p$harvest_kg - hk) < 1, p$survey_season, useNA = "a"))
ps <- rowSums(as.matrix(p[, paste0("plot_size_", 1:6)]), na.rm = TRUE)
print(summary(p$acres_tot - ps)); print(table(abs(p$acres_tot - ps) < 0.01, p$survey_season, useNA = "a"))
# tot_lab_costs vs lc_*_costs_season
lc1 <- rowSums(as.matrix(p[, paste0("lc_", c("prep","plant","weed","spray","harv"), "_costs_season1")]), na.rm = TRUE)
print(table(abs(p$tot_lab_costs_1 - lc1) < 1, p$survey_season, useNA = "a"))
print(summary(p$tot_lab_costs_1 - lc1))
print(head(as.data.frame(p[, c("hhh_id","survey_season","harvest_kg","harvest_kg_1","harvest_kg_2","acres_tot","plot_size_1","plot_size_2","tot_lab_costs_1","lc_prep_costs_season1","lh_prep_hours_season1","lh_prep_unit1","lh_prep_hours_unit1","sold_kg_p_1","tot_rev_combined_1","tot_rev_combined2_1","tot_rev_combined_1_1")]), 30))
# seller data
sd <- read_dta(file.path(D, "seller_data.dta"))
print(head(as.data.frame(sd), 30))
print(sd %>% group_by(survey_season, buy_treatment) %>% summarise(n = n(), mp = mean(price), mp0 = mean(price[price > 0]), nz = sum(price == 0), nn = sum(is.na(name))))
print(table(sd$name[sd$name > 1000]))
bd <- read_dta(file.path(D, "buy_data.dta")); print(table(bd$status, bd$survey_season, useNA = "a")); print(attributes(bd$status))
p0 <- read_dta(file.path(D, "panel_g0.dta")); cat("g0 names:\n"); print(names(p0))
cat("g1 names:\n"); print(names(p))
