# Exploratory 2: coverage by season, structure checks. No estimates of listed quantities.
suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw/"
g1 <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
g1 <- as.data.frame(lapply(g1, function(x) if (inherits(x, "Date")) as.numeric(x) else as.vector(x)), stringsAsFactors = FALSE)
cat("rows by season x treat\n"); print(table(g1$survey_season, g1$buy_treatment))
cat("season vs survey_round\n"); print(table(g1$survey_season, g1$survey_round))
cat("form_used by season\n"); print(table(g1$form_used, g1$survey_season))
cat("dup hh-season:", sum(duplicated(g1[, c("hhh_id","survey_season")])), "\n")
cat("n hh:", length(unique(g1$hhh_id)), " n ea:", length(unique(g1$ea_code)), "\n")
vars <- c("harvest_kg","harvest_kg_1","acres_tot","plot_size_1","maize_tot_plotn","seeds_cost_1","fert_cost_1","booster_cost_1",
          "manure_cost_1","tot_chem_costs_1","tot_lab_costs_1","equipment_cost_1","harvest_cost_1","labor_cost_ph","otherph_cost",
          "drying_cost","storage_cost","labor_cost_store","labor_cost_dry","tot_transport_cost","cost_transportpre","cost_transportpost",
          "sale_transport_cost_1","decobbing_cost_1","lc_decob_labour_costs","lc_bag_labour_costs","lc_decob_other_costs",
          "lc_prep_costs_season1","lc_harv_costs_season1","lh_prep_hours_season1","lh_decob_hours","sold_kg_p_1","tot_rev_combined_1",
          "tot_rev_combined2_1","tot_rev_combined_1_1","sold_crop","dry_how","sort","winnow","booster_cost","seeds_cost","fert_cost",
          "lc_decob_labmaize_costs","lc_decob_price","lc_bag_labmaize_costs","lc_bag_price","distance_kakumiro")
for (v in vars) { x <- g1[[v]]; nm <- if (is.character(x)) !is.na(x) & x != "" else !is.na(x)
  cat(sprintf("%-26s", v), tapply(nm, g1$survey_season, sum), "| mean by season:",
      if (is.numeric(x)) round(tapply(x, g1$survey_season, mean, na.rm=TRUE),1) else "", "\n") }
# harvest_kg vs sum of plots
hs <- rowSums(g1[, paste0("harvest_kg_", 1:6)], na.rm=TRUE)
cat("harvest_kg vs plot sum: diff summary\n"); print(summary(g1$harvest_kg - hs))
ps <- rowSums(g1[, paste0("plot_size_", 1:6)], na.rm=TRUE)
cat("acres_tot vs plot sum diff\n"); print(summary(g1$acres_tot - ps))
cat("units lc_prep_unit1\n"); print(table(g1$lc_prep_unit1, g1$survey_season))
cat("units lh_prep_unit1\n"); print(table(g1$lh_prep_unit1, g1$survey_season))
cat("tot_lab_costs_1 vs sum lc seasons\n"); lcs <- rowSums(g1[, paste0("lc_", c("prep","plant","weed","spray","harv"), "_costs_season1")], na.rm=TRUE)
print(summary(g1$tot_lab_costs_1 - lcs))
cat("tot_rev_combined_1 / sold_kg_p_1 quantiles\n"); print(quantile(g1$tot_rev_combined_1 / g1$sold_kg_p_1, c(.01,.1,.5,.9,.99), na.rm=TRUE))
cat("tot_rev_combined2_1 / sold_kg_p_1 quantiles\n"); print(quantile(g1$tot_rev_combined2_1 / g1$sold_kg_p_1, c(.01,.1,.5,.9,.99), na.rm=TRUE))
s <- zap_labels(read_dta(paste0(D, "seller_data.dta"))); s <- as.data.frame(lapply(s, as.vector))
cat("\nseller rows by season x treat\n"); print(table(s$survey_season, s$buy_treatment))
cat("seller: per hh-season counts\n"); print(table(table(paste(s$hhh_id, s$survey_season))))
cat("seller: sold_kg_p_ vs sold_kg_tot equal share:", mean(s$sold_kg_p_ == s$sold_kg_tot), "\n")
cat("seller: price==0:", sum(s$price==0), " name NA:", sum(is.na(s$name)), "\n")
print(head(s, 15))
cat("top names\n"); print(head(sort(table(s$name), decreasing=TRUE), 10))
cat("name x treat in follow-up for top codes\n"); top <- as.numeric(names(head(sort(table(s$name[s$survey_season>=4]), decreasing=TRUE), 5)))
print(table(s$name[s$name %in% top & s$survey_season>=4], s$buy_treatment[s$name %in% top & s$survey_season>=4]))
cat("seller price mean by season x treat\n"); print(round(tapply(s$price[s$price>0], list(s$survey_season[s$price>0], s$buy_treatment[s$price>0]), mean),1))
b <- zap_labels(read_dta(paste0(D, "buy_data.dta"))); print(head(as.data.frame(b))); print(table(b$status, b$survey_season))
# merge check: hh-season in seller but not in g1
k1 <- paste(g1$hhh_id, g1$survey_season); ks <- unique(paste(s$hhh_id, s$survey_season))
cat("seller keys not in g1:", sum(!ks %in% k1), " g1 keys with sold_kg_p_1>0 not in seller:", sum(!(k1[!is.na(g1$sold_kg_p_1) & g1$sold_kg_p_1>0] %in% ks)), "\n")
# returns data
r <- read_dta(paste0(D, "anonym_returns_data.dta"))
r <- as.data.frame(lapply(r, function(x) if (inherits(x, "Date")) as.numeric(x) else as.vector(zap_labels(x))), stringsAsFactors=FALSE)
types <- c("dirty","cobs","stones","dust","insect","insect_live","broken","immature","damage","rot","mould")
nb <- 0; nb_any <- 0; nb_all <- 0
for (b in 1:20) {
  w <- r[[paste0("add4_weight_", b)]]
  M <- sapply(types, function(t) { v <- paste0("add4_", t, "_", b); if (v %in% names(r)) r[[v]] else rep(NA, nrow(r)) })
  nb <- nb + sum(!is.na(w)); nb_any <- nb_any + sum(!is.na(w) & rowSums(!is.na(M))>0); nb_all <- nb_all + sum(!is.na(w) & rowSums(is.na(M))==0)
}
cat("bags with weight:", nb, " with any defect info:", nb_any, " with all info:", nb_all, "\n")
cat("bag var exists up to: "); for (t in types) cat(t, max(as.numeric(sub(paste0("add4_",t,"_"), "", grep(paste0("^add4_",t,"_[0-9]+$"), names(r), value=TRUE)))), "; "); cat("\n")
cat("missing pattern bag1 by treatment (dirty, broken, immature NA):\n"); print(table(is.na(r$add4_dirty_1), r$treatment))
print(table(r$add4_weight_1 > 0, useNA="ifany"))
cat("sales per hh (ppk nonmiss):", table(rowSums(!is.na(r[, paste0("add5_ppk_",1:4)]))), "\n")
cat("sale k: ppk & date both:", sapply(1:4, function(k) sum(!is.na(r[[paste0("add5_ppk_",k)]]) & !is.na(r[[paste0("add5_sold_when_e_",k)]]))), "\n")
cat("sale k: any ind_weight:", sapply(1:4, function(k) sum(rowSums(!is.na(r[, paste0("add5_ind_weight",1:20,"_",k)]))>0)), "\n")
cat("bags with ind_weight but no add4 weight:", sum(sapply(1:4, function(k) sum(sapply(1:20, function(b) sum(!is.na(r[[paste0("add5_ind_weight",b,"_",k)]]) & is.na(r[[paste0("add4_weight_",b)]])))))), "\n")
cat("dates range:", as.character(as.Date(range(unlist(r[, paste0("add5_sold_when_e_",1:4)]), na.rm=TRUE), origin="1970-01-01")), "\n")
cat("lab NA pattern:\n"); print(colSums(is.na(r[, c("Total_weight_of_maize_g","Foreign_matter_tot_g","Inorganic_matter_tot_g","Broken_grains_tot_g","Pest_damaged_grains_tot_g","Rotten_and_diseased_grain","Discoloured_grains_tot_g","Immature_or_shrivelled_gr")])))
cat("n ea in returns:", length(unique(r$ea_code)), "\n")
