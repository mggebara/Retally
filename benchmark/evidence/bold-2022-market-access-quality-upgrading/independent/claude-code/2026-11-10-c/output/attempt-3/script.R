suppressMessages({library(haven); library(dplyr); library(tidyr)})
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
options(width = 220)
r <- zap_labels(read_dta(paste0(D, "anonym_returns_data.dta")))
# --- sales structure
for (k in 1:4) {
  w <- sapply(1:20, function(j) r[[paste0("add5_ind_weight", j, "_", k)]])
  dw <- sapply(1:20, function(j) r[[paste0("add5_ind_ded_weight", j, "_", k)]])
  mw <- sapply(1:20, function(j) r[[paste0("add4_weight_", j)]])
  has <- rowSums(!is.na(w)) > 0
  d8 <- r[[paste0("add5_sold_when_e_", k)]]
  cat("sale", k, ": with ind weights", sum(has), "; ppk nonNA", sum(!is.na(r[[paste0("add5_ppk_", k)]])),
      "; date nonempty", sum(!is.na(d8) & d8 != ""), "; ppk & date", sum(!is.na(r[[paste0("add5_ppk_", k)]]) & !is.na(d8) & d8 != ""), "\n")
  # measured weight missing for sold bags?
  sel <- !is.na(w)
  cat("   sold bag-cells", sum(sel), " of which measured weight NA", sum(sel & is.na(mw)), "\n")
  y <- rowSums(ifelse(sel, mw, 0), na.rm = TRUE); z <- rowSums(dw, na.rm = TRUE); wb <- rowSums(w, na.rm = TRUE)
  dd <- ifelse(has, 100 * (y - z) / y, NA)
  cat("   mean (y-z)/y", round(mean(dd, na.rm=TRUE), 3), " mean (wb-z)/wb", round(mean(ifelse(has, 100*(wb-z)/wb, NA), na.rm=TRUE), 3), " mean (y-wb)/y", round(mean(ifelse(has, 100*(y-wb)/y, NA), na.rm=TRUE),3), "\n")
}
print(table(r$add5_sold_when_e_1 == "", useNA = "ifany"))
print(head(sort(unique(c(r$add5_sold_when_e_1, r$add5_sold_when_e_2, r$add5_sold_when_e_3, r$add5_sold_when_e_4))), 200))
# hh with no sale info
cat("households with ppk_1 NA:", sum(is.na(r$add5_ppk_1)), "\n")
# lab
lab <- with(r, Foreign_matter_tot_g + Inorganic_matter_tot_g + Broken_grains_tot_g + Pest_damaged_grains_tot_g + Rotten_and_diseased_grain + Discoloured_grains_tot_g + Immature_or_shrivelled_gr)
cat("lab nonNA", sum(!is.na(lab)), " mean share by treat:", tapply(lab / r$Total_weight_of_maize_g, r$treatment, mean, na.rm = TRUE), "\n")
lab2 <- with(r, Broken_grains_tot_g + Pest_damaged_grains_tot_g + Rotten_and_diseased_grain + Discoloured_grains_tot_g + Immature_or_shrivelled_gr)
cat("lab grains only mean by treat:", tapply(lab2 / r$Total_weight_of_maize_g, r$treatment, mean, na.rm = TRUE), "\n")

# --- panel g1
g <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
cat("\nseason x treatment\n"); print(table(g$survey_season, g$buy_treatment))
cat("hh count", length(unique(g$hhh_id)), "\n")
post <- g$survey_season >= 4
cat("post rows", sum(post), " harvest_kg nonNA post", sum(!is.na(g$harvest_kg[post])), " acres_tot nonNA post", sum(!is.na(g$acres_tot[post])), "\n")
hk <- rowSums(g[, paste0("harvest_kg_", 1:9)], na.rm = TRUE); hkn <- rowSums(!is.na(g[, paste0("harvest_kg_", 1:9)]))
ps <- rowSums(g[, paste0("plot_size_", 1:12)], na.rm = TRUE); psn <- rowSums(!is.na(g[, paste0("plot_size_", 1:12)]))
cat("post: plot harvest any nonNA", sum(hkn[post] > 0), "; plot size any", sum(psn[post] > 0), "; maize_tot_plotn nonNA", sum(!is.na(g$maize_tot_plotn[post])), "\n")
print(summary(cbind(harvest_kg = g$harvest_kg, hk = ifelse(hkn > 0, hk, NA), acres_tot = g$acres_tot, ps = ifelse(psn > 0, ps, NA))))
cat("by season: n, nonNA harvest_kg, nonNA hk, nonNA acres_tot, nonNA ps, mean harvest_kg, mean hk\n")
for (s in 1:7) { i <- g$survey_season == s
  cat(s, sum(i), sum(!is.na(g$harvest_kg[i])), sum(hkn[i] > 0), sum(!is.na(g$acres_tot[i])), sum(psn[i] > 0), round(mean(g$harvest_kg[i], na.rm=TRUE)), round(mean(hk[i][hkn[i] > 0])), round(mean(g$acres_tot[i], na.rm=TRUE),2), round(mean(ps[i][psn[i]>0]),2), "\n") }
cat("max diff harvest_kg vs hk:", summary(g$harvest_kg - ifelse(hkn > 0, hk, NA)), "\n")
cat("maize_tot_plotn==0 post:", sum(g$maize_tot_plotn[post] == 0, na.rm = TRUE), "\n")
print(table(g$survey_season, g$form_used))
# seller data
s <- zap_labels(read_dta(paste0(D, "seller_data.dta")))
cat("\nseller rows by season:\n"); print(table(s$survey_season))
s1 <- s %>% filter(hhh_id %in% g$hhh_id)
cat("seller rows matching g1 hh:", nrow(s1), " price==0:", sum(s1$price == 0), " sold==0:", sum(s1$sold_kg_p_ == 0), "\n")
hs <- s1 %>% filter(price > 0, sold_kg_p_ > 0) %>% group_by(hhh_id, survey_season) %>% summarise(n = n(), .groups = "drop")
cat("hh-seasons with positive price sales:", nrow(hs), " post:", sum(hs$survey_season >= 4), "\n")
hs2 <- s1 %>% group_by(hhh_id, survey_season) %>% summarise(n = n(), .groups = "drop")
cat("hh-seasons any seller row:", nrow(hs2), " post:", sum(hs2$survey_season >= 4), "\n")
print(s1 %>% group_by(survey_season) %>% summarise(mp = mean(price[price > 0]), med = median(price[price > 0])))
print(head(as.data.frame(s1), 30))
cat("name NA by season\n"); print(table(s1$survey_season, is.na(s1$name)))
# buy data
bd <- zap_labels(read_dta(paste0(D, "buy_data.dta")))
print(head(as.data.frame(bd))); print(table(bd$status, bd$survey_season))
# key g1 vars by season (non-missing counts)
vars <- c("seeds_cost_1","fert_cost_1","booster_cost_1","tot_chem_costs_1","equipment_cost_1","tot_lab_costs_1","harvest_cost_1","labor_cost_ph","otherph_cost","drying_cost","storage_cost","tot_transport_cost","cost_transportpre","cost_transportpost","decobbing_cost_1","lh_prep_hours_season1","lc_prep_costs_season1","lc_harv_costs_season1","tot_rev_told_tot","sold_kg","sold_kg_p_1","tot_rev_combined_1","lc_decob_labour_costs","lh_decob_hours","sold_crop","seeds_cost","fert_cost","labor_cost_store","labor_cost_dry","lh_winnow_hours")
for (v in vars) { cat(sprintf("%-24s", v), sapply(1:7, function(ss) sum(!is.na(g[[v]][g$survey_season == ss]) & g[[v]][g$survey_season == ss] != "")), "\n") }
