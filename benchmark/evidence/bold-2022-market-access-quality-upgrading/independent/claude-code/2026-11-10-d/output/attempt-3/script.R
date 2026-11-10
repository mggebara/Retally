suppressPackageStartupMessages({library(haven); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading"
rd <- function(f) zap_labels(read_dta(file.path(base, "data/raw", f)))
r <- rd("anonym_returns_data.dta")
tryCatch({
cat("=== RETURNS: bags\n")
defs <- c("dirty","cobs","stones","dust","broken","immature","damage","rot","insect","insect_live","mould")
bags <- list()
for (b in 1:20) {
  w <- r[[paste0("add4_weight_", b)]]
  m <- sapply(defs, function(d) r[[paste0("add4_", d, "_", b)]])
  if (is.null(dim(m))) m <- matrix(m, nrow = 1)
  anyd <- rowSums(!is.na(m)) > 0
  bags[[b]] <- data.frame(hh = r$hhh_id, tr = r$treatment, ea = r$ea_code, bag = b, w = w, nd = rowSums(!is.na(m)), m)
}
bg <- bind_rows(bags)
cat("weight nonNA:", sum(!is.na(bg$w)), " any defect nonNA:", sum(bg$nd > 0), " both:", sum(!is.na(bg$w) & bg$nd > 0), " w>0:", sum(bg$w > 0, na.rm=TRUE), "\n")
print(table(nd = bg$nd[!is.na(bg$w) | bg$nd > 0]))
for (d in defs) { cat(d, ": "); print(table(bg[[d]], useNA = "ifany")) }
seeds <- sapply(1:20, function(b) r[[paste0("add4_seeds_", b)]])
cat("seeds nonempty:", sum(!is.na(seeds) & seeds != ""), "\n")
cat("add4_random_bag vs n bags weight:\n"); nb <- tapply(!is.na(bg$w), bg$hh, sum); print(summary(as.numeric(nb)))
cat("hh with no defect vars at all:", sum(tapply(bg$nd, bg$hh, sum) == 0), "\n")
cat("=== RETURNS: sales\n")
for (s in 1:4) {
  ppk <- r[[paste0("add5_ppk_", s)]]; dt <- r[[paste0("add5_sold_when_e_", s)]]
  iw <- sapply(1:20, function(b) r[[paste0("add5_ind_weight", b, "_", s)]])
  dw <- sapply(1:20, function(b) r[[paste0("add5_ind_ded_weight", b, "_", s)]])
  nbw <- rowSums(!is.na(iw))
  cat("sale", s, ": ppk nonNA", sum(!is.na(ppk)), " date nonempty", sum(!is.na(dt) & dt != ""), " any indweight", sum(nbw > 0),
      " ppk&weights", sum(!is.na(ppk) & nbw > 0), " ppk & date", sum(!is.na(ppk) & !is.na(dt) & dt != ""), "\n")
  print(table(ppk_na = is.na(ppk), nbw = pmin(nbw, 3)))
}
# show first 12 hh for sales
for (i in 1:12) {
  cat("hh", r$hhh_id[i], "tr", r$treatment[i], "bags_w:", paste(sapply(1:20, function(b) r[[paste0("add4_weight_", b)]][i]), collapse=","), "\n")
  for (s in 1:4) cat("   s", s, "ppk", r[[paste0("add5_ppk_", s)]][i], "date", r[[paste0("add5_sold_when_e_", s)]][i],
                     "iw:", paste(sapply(1:20, function(b) r[[paste0("add5_ind_weight", b, "_", s)]][i]), collapse=","),
                     "dw:", paste(sapply(1:20, function(b) r[[paste0("add5_ind_ded_weight", b, "_", s)]][i]), collapse=","), "\n")
}
cat("ppk by treatment sale1:\n"); print(tapply(r$add5_ppk_1, r$treatment, mean, na.rm=TRUE)); print(tapply(r$add5_ppk_2, r$treatment, mean, na.rm=TRUE))
lab <- with(r, rowSums(cbind(Foreign_matter_tot_g, Inorganic_matter_tot_g, Broken_grains_tot_g, Pest_damaged_grains_tot_g, Rotten_and_diseased_grain, Discoloured_grains_tot_g, Immature_or_shrivelled_gr), na.rm=TRUE) / Total_weight_of_maize_g)
cat("lab share by tr:\n"); print(tapply(lab, r$treatment, function(x) c(n=sum(!is.na(x)), m=mean(x, na.rm=TRUE))))

}, error=function(e) cat("ERR1", conditionMessage(e), "\n"))
cat("\n=== PANEL G1\n")
tryCatch({
p <- rd("panel_g1.dta")
p$fu <- p$survey_season >= 4
vars <- c("harvest_kg","harvest_kg_1","acres_tot","plot_size_1","maize_tot_plotn","tot_lab_costs_1","lc_prep_costs_season1","lh_prep_hours_season1","labor_cost_ph","otherph_cost","cost_transportpre","cost_transportpost","tot_transport_cost","drying_cost","storage_cost","labor_cost_dry","labor_cost_store","decobbing_cost_1","harvest_cost_1","seeds_cost_1","fert_cost_1","booster_cost_1","tot_chem_costs_1","manure_cost_1","equipment_cost_1","sold_kg_p_1","tot_rev_combined_1","tot_rev_combined2_1","tot_rev_combined_1_1","sold_crop","lh_decob_hours","lc_decob_labour_costs","lc_decob_other_costs","decob","sale_transport_cost_1","seeds_cost","fert_cost","booster_cost","tot_rev_told_tot","sold_kg")
for (v in vars) { x <- p[[v]]; ok <- if (is.character(x)) x != "" & !is.na(x) else !is.na(x); cat(sprintf("%-26s", v), tapply(ok, p$survey_season, sum), "\n") }
print(table(p$form_used, p$survey_season))
s <- rd("seller_data.dta")
cat("seller by season:\n"); print(table(s$survey_season)); print(tapply(s$price, s$survey_season, function(x) c(mean(x), mean(x == 0))))
ss <- s %>% filter(price > 0, sold_kg_p_ > 0) %>% group_by(hhh_id, survey_season) %>% summarise(pr = weighted.mean(price, sold_kg_p_), prm = mean(price), n = n(), .groups = "drop")
cat("hh-season with price, follow-up:", sum(ss$survey_season >= 4), " all price rows fu:", sum(s$survey_season>=4), "\n")
pm <- left_join(p, ss, by = c("hhh_id","survey_season"))
cat("fu rows with price:", sum(pm$fu & !is.na(pm$pr)), "\n")
print(pm %>% filter(fu) %>% group_by(buy_treatment) %>% summarise(pr = mean(pr, na.rm=TRUE), prm = mean(prm, na.rm=TRUE)))
print(pm %>% group_by(survey_season, buy_treatment) %>% summarise(pr = mean(pr, na.rm=TRUE), .groups="drop") %>% as.data.frame())
# harvest
hplots <- rowSums(p[, paste0("harvest_kg_", 1:6)], na.rm = TRUE); anyh <- rowSums(!is.na(p[, paste0("harvest_kg_", 1:6)])) > 0
acr <- rowSums(p[, paste0("plot_size_", 1:6)], na.rm = TRUE); anya <- rowSums(!is.na(p[, paste0("plot_size_", 1:6)])) > 0
cat("harvest_kg vs sum plots, where both:", summary(p$harvest_kg - hplots)[c(1,3,4,6)], " n both", sum(!is.na(p$harvest_kg) & anyh), "\n")
cat("acres_tot vs sum plots:", summary(p$acres_tot - acr)[c(1,3,4,6)], "\n")
p$H <- ifelse(!is.na(p$harvest_kg), p$harvest_kg, ifelse(anyh, hplots, NA)); p$A <- ifelse(anya, acr, ifelse(!is.na(p$acres_tot), p$acres_tot, NA))
p$H2 <- ifelse(anyh, hplots, p$harvest_kg)
cat("H nonNA by season:", tapply(!is.na(p$H), p$survey_season, sum), "\nA nonNA:", tapply(!is.na(p$A), p$survey_season, sum), "\n")
cat("maize_tot_plotn==0 by season:", tapply(p$maize_tot_plotn == 0, p$survey_season, sum, na.rm=TRUE), "\n")
for (cn in c("H","H2","A")) { cat(cn, "fu control mean:", mean(p[[cn]][p$fu & p$buy_treatment == 0], na.rm=TRUE), " n fu:", sum(!is.na(p[[cn]][p$fu])), "\n") }
y <- p$H / p$A; y[!is.finite(y)] <- NA
cat("yield fu control mean:", mean(y[p$fu & p$buy_treatment == 0], na.rm=TRUE), " n:", sum(!is.na(y[p$fu])), "\n")
cat("rows per hh-season dup:", sum(duplicated(p[, c("hhh_id","survey_season")])), "\n")
}, error=function(e) cat("ERR2", conditionMessage(e), "\n"))
