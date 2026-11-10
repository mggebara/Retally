suppressMessages({library(haven); library(dplyr); library(tidyr)})
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
options(width = 250)
r <- read_dta(paste0(D, "anonym_returns_data.dta"))
# slot-1 bags per household vs random bag
nb <- function(k) rowSums(!is.na(as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", k)])))
print(table(slot1_nbags = nb(1)))
w1 <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_1")])
idx1 <- apply(w1, 1, function(x) if (any(!is.na(x))) which(!is.na(x))[1] else NA)
print(table(match = idx1 == r$add4_random_bag, useNA = "ifany"))
print(table(slot2_nbags = nb(2)))
# sample counts in control by slot2-4
cat("sales slots 2-4:", sum(!is.na(r$add5_ppk_2)) + sum(!is.na(r$add5_ppk_3)) + sum(!is.na(r$add5_ppk_4)), "\n")
cat("hh with slot2:", sum(!is.na(r$add5_ppk_2)), " slot1 ppk ctrl mean", mean(r$add5_ppk_1[r$treatment == 0], na.rm = TRUE), "\n")
pp <- c(r$add5_ppk_2[r$treatment == 0], r$add5_ppk_3[r$treatment == 0], r$add5_ppk_4[r$treatment == 0])
cat("ctrl mean price slots2-4", mean(pp, na.rm = TRUE), "\n")
pp <- c(r$add5_ppk_1[r$treatment == 0], r$add5_ppk_2[r$treatment == 0], r$add5_ppk_3[r$treatment == 0], r$add5_ppk_4[r$treatment == 0])
cat("ctrl mean price slots1-4", mean(pp, na.rm = TRUE), "\n")
# do sold bag indices in slot 2 overlap random bag?
w2 <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_2")])
ov <- sapply(seq_len(nrow(r)), function(i) !is.na(r$add4_random_bag[i]) && !is.na(w2[i, r$add4_random_bag[i]]))
cat("slot2 includes random bag:", sum(ov), "\n")
# measured weight vs buyer weight for slot 2 bags
aw <- as.matrix(r[, paste0("add4_weight_", 1:20)])
for (k in 1:4) {
  wk <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", k)]); dk <- as.matrix(r[, paste0("add5_ind_ded_weight", 1:20, "_", k)])
  y <- rowSums(ifelse(is.na(wk), NA, aw), na.rm = TRUE); z <- rowSums(dk, na.rm = TRUE); zb <- rowSums(wk, na.rm = TRUE)
  ok <- rowSums(!is.na(wk)) > 0
  cat("slot", k, "mean (y-z)/y", mean(((y - z) / y)[ok]) * 100, " (y-zb)/y", mean(((y - zb) / y)[ok]) * 100, " missing y bags", sum(!is.na(wk) & is.na(aw)), "\n")
}
g <- read_dta(paste0(D, "panel_g1.dta"))
num <- function(v) if (v %in% names(g)) g[[v]] else rep(NA_real_, nrow(g))
rs <- function(vs) { m <- sapply(vs, num); rowSums(m, na.rm = TRUE) * ifelse(rowSums(!is.na(m)) > 0, 1, NA) }
g$harv_plots <- rs(paste0("harvest_kg_", 1:9)); g$acres_plots <- rs(paste0("plot_size_", 1:12))
print(g %>% group_by(survey_season) %>% summarise(hk = mean(harvest_kg, na.rm = T), hp = mean(harv_plots, na.rm = T), ac = mean(acres_tot, na.rm = T), ap = mean(acres_plots, na.rm = T),
   d = mean(harvest_kg - harv_plots, na.rm = T), nd = sum(abs(harvest_kg - harv_plots) > 1, na.rm = T)) %>% as.data.frame())
fu <- g$survey_season >= 4 & g$buy_treatment == 0
X <- 3700
comps <- list(seeds = paste0("seeds_cost_", 1:6), fert = paste0("fert_cost_", 1:5), boost = paste0("booster_cost_", 1:5), manure = paste0("manure_cost_", 1:3), chem = paste0("tot_chem_costs_", 1:6),
  equip = paste0("equipment_cost_", 1:5), lab = paste0("tot_lab_costs_", 1:6), lcprep = paste0("lc_prep_costs_season", 1:6), lcplant = paste0("lc_plant_costs_season", 1:6), lcweed = paste0("lc_weed_costs_season", 1:6),
  lcspray = paste0("lc_spray_costs_season", 1:6), lcharv = paste0("lc_harv_costs_season", 1:6), harvc = paste0("harvest_cost_", 1:5), decobc = paste0("decobbing_cost_", 1:5), lph = "labor_cost_ph", oph = "otherph_cost",
  dry = "drying_cost", stor = "storage_cost", ldry = "labor_cost_dry", lstore = "labor_cost_store", ttc = "tot_transport_cost", ctpre = "cost_transportpre", ctpost = "cost_transportpost", stc = paste0("sale_transport_cost_", 1:5),
  dlab = "lc_decob_labour_costs", doth = "lc_decob_other_costs", wlab = "lc_winnow_labour_costs", woth = "lc_winnow_other_costs", slab = "lc_sort_labour_costs", soth = "lc_sort_other_costs", blab = "lc_bag_labour_costs", both = "lc_bag_other_costs",
  booster = "booster_cost", seedsc = "seeds_cost", fertc = "fert_cost",
  lhprep = paste0("lh_prep_hours_season", 1:6), lhplant = paste0("lh_plant_hours_season", 1:6), lhweed = paste0("lh_weed_hours_season", 1:6), lhspray = paste0("lh_spray_hours_season", 1:6), lhharv = paste0("lh_harv_hours_season", 1:6),
  lhdecob = "lh_decob_hours", lhwin = "lh_winnow_hours", lhsort = "lh_sort_hours", lhbag = "lh_bag_hours")
out <- list()
for (s in 1:7) for (nm in names(comps)) {
  v <- rs(comps[[nm]]); sel <- g$survey_season == s
  out[[length(out) + 1]] <- data.frame(s = s, comp = nm, n = sum(!is.na(v[sel])), mean_usd_all = round(mean(v[sel], na.rm = TRUE) / ifelse(grepl("^lh", nm), 1, X), 2))
}
o <- bind_rows(out)
print(o %>% pivot_wider(id_cols = comp, names_from = s, values_from = c(n, mean_usd_all)) %>% as.data.frame())
# control followup means
cm <- sapply(names(comps), function(nm) { v <- rs(comps[[nm]]); round(mean(v[fu], na.rm = TRUE) / ifelse(grepl("^lh", nm), 1, X), 2) })
print(cm)
# check tot_lab = sum lc components
lcs <- rs(c(paste0("lc_prep_costs_season", 1:6), paste0("lc_plant_costs_season", 1:6), paste0("lc_weed_costs_season", 1:6), paste0("lc_spray_costs_season", 1:6), paste0("lc_harv_costs_season", 1:6)))
print(summary(rs(paste0("tot_lab_costs_", 1:6)) - lcs))
# labor_cost_ph vs components
ph <- rs(c("lc_decob_labour_costs", "lc_winnow_labour_costs", "lc_sort_labour_costs", "lc_bag_labour_costs"))
sel <- g$survey_season %in% 5:7
print(summary((g$labor_cost_ph - ph)[sel])); print(summary((g$labor_cost_ph - ph - rs(paste0("lc_harv_costs_season", 1:6)))[sel]))
print(summary((g$otherph_cost - rs(c("lc_decob_other_costs", "lc_winnow_other_costs", "lc_sort_other_costs", "lc_bag_other_costs")))[sel]))
print(head(as.data.frame(g[sel, c("labor_cost_ph", "otherph_cost", "lc_decob_labour_costs", "lc_decob_labmaize_costs", "lc_decob_price", "lc_decob_other_costs", "lc_winnow_labour_costs", "lc_bag_labour_costs", "lc_bag_labmaize_costs", "lc_bag_price", "lc_bag_other_costs", "lc_harv_costs_season1", "drying_cost", "storage_cost", "labor_cost_dry", "labor_cost_store", "tot_transport_cost", "cost_transportpre", "cost_transportpost")]), 20))
s <- read_dta(paste0(D, "seller_data.dta"))
print(summary(s$sold_kg_p_)); print(table(s$name, useNA = "ifany")[1:10])
hs <- s %>% filter(price > 0, sold_kg_p_ > 0) %>% group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg = sum(sold_kg_p_), kgt = first(sold_kg_tot), .groups = "drop")
gg <- g %>% left_join(hs, by = c("hhh_id", "survey_season"))
cat("followup hh-seasons with price:", sum(!is.na(gg$rev) & gg$survey_season >= 4), "\n")
revp <- rs(paste0("tot_rev_combined_", 1:7)); kgp <- rs(paste0("sold_kg_p_", 1:7))
print(summary((revp - gg$rev)[gg$survey_season >= 4])); print(summary((kgp - gg$kg)[gg$survey_season >= 4]))
print(gg %>% filter(survey_season >= 4) %>% group_by(buy_treatment) %>% summarise(p = mean(rev / kg, na.rm = T) / X, n = sum(!is.na(rev))))
print(gg %>% group_by(survey_season) %>% summarise(p = mean(rev / kg, na.rm = T) / X, n = sum(!is.na(rev))))
cat("sold_crop table followup:\n"); print(table(g$sold_crop[g$survey_season >= 4], useNA = "ifany"))
