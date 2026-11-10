suppressMessages({library(haven); library(dplyr); library(tidyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"
options(width = 220)
g <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
rs <- function(p) { v <- grep(p, names(g), value = TRUE); list(v = v, s = rowSums(g[, v, drop = FALSE], na.rm = TRUE), n = rowSums(!is.na(g[, v, drop = FALSE]))) }
comps <- c("^seeds_cost_[0-9]+$","^fert_cost_[0-9]+$","^booster_cost_[0-9]+$","^manure_cost_[0-9]+$","^tot_chem_costs_[0-9]+$","^tot_lab_costs_[0-9]+$",
           "^lc_(prep|plant|weed|spray|harv)_costs_season[0-9]+$","^equipment_cost_[0-9]+$","^harvest_cost_[0-9]+$","^decobbing_cost_[0-9]+$",
           "^labor_cost_ph$","^otherph_cost$","^drying_cost$","^storage_cost$","^tot_transport_cost$","^cost_transportpre$","^cost_transportpost$",
           "^sale_transport_cost_[0-9]+$","^labor_cost_store$","^labor_cost_dry$","^lc_(decob|winnow|sort|bag)_labour_costs$","^lc_(decob|winnow|sort|bag)_other_costs$",
           "^lc_(decob|bag)_labmaize_costs$","^lh_(prep|plant|weed|spray|harv)_hours_season[0-9]+$","^lh_(decob|winnow|sort|bag)_hours$","^seeds_cost$","^fert_cost$","^booster_cost$")
cat("component: mean (UGX) among control by season 2..7 [n nonNA]\n")
for (p in comps) {
  x <- rs(p)
  cat(sprintf("%-60s", p), paste(sapply(2:7, function(s) { i <- g$survey_season == s & g$buy_treatment == 0; sprintf("%9.0f[%3d]", mean(x$s[i]), sum(x$n[i] > 0)) }), collapse = " "), "\n")
}
cat("\nvars list:\n"); print(rs("^lc_(prep|plant|weed|spray|harv)_costs_season[0-9]+$")$v)
# Check whether tot_lab_costs_j = sum lc_*_costs_seasonj
for (j in 1:3) { a <- g[[paste0("tot_lab_costs_", j)]]; b <- rowSums(g[, paste0("lc_", c("prep","plant","weed","spray","harv"), "_costs_season", j)], na.rm = TRUE)
  cat("plot", j, "tot_lab vs sum lc: summary diff", summary(a - b), "\n") }
# labor_cost_ph vs components
pp <- rowSums(g[, c("lc_decob_labour_costs","lc_winnow_labour_costs","lc_sort_labour_costs","lc_bag_labour_costs","labor_cost_store","labor_cost_dry")], na.rm = TRUE)
cat("labor_cost_ph - sum ph labour comps:\n"); print(summary(g$labor_cost_ph - pp))
# units
for (t in c("prep","plant","weed","spray","harv")) { cat(t, "lc unit:"); print(table(g[[paste0("lc_", t, "_unit1")]], g$survey_season)) }
for (t in c("prep","harv")) { cat(t, "lh unit:"); print(table(g[[paste0("lh_", t, "_unit1")]], g$survey_season)) }
# cost per day for hired labor
cpd <- c(); for (t in c("prep","plant","weed","spray","harv")) for (j in 1:4) { u <- g[[paste0("lc_", t, "_unit", j)]]; c1 <- g[[paste0("lc_", t, "_costs_unit", j)]]; cpd <- c(cpd, c1[u == "days" & !is.na(c1) & c1 > 0]) }
cat("hired cost per day: n", length(cpd), "\n"); print(quantile(cpd, c(.1,.25,.5,.75,.9)))
hpd <- c(); for (t in c("prep","plant","weed","spray","harv")) for (j in 1:4) { u <- g[[paste0("lh_", t, "_unit", j)]]; c1 <- g[[paste0("lh_", t, "_hours_unit", j)]]; hpd <- c(hpd, c1[u == "days" & !is.na(c1) & c1 > 0]) }
cat("family hours per day: n", length(hpd), "\n"); print(quantile(hpd, c(.1,.25,.5,.75,.9)))
# family hours total, control, seasons 5-7
fh <- rs("^lh_(prep|plant|weed|spray|harv)_hours_season[0-9]+$")$s + rs("^lh_(decob|winnow|sort|bag)_hours$")$s
cat("family hours mean control s5-7:", mean(fh[g$survey_season >= 5 & g$buy_treatment == 0]), " treat:", mean(fh[g$survey_season >= 5 & g$buy_treatment == 1]), "\n")
cat("family hours (preharvest only) mean control s5-7:", mean(rs("^lh_(prep|plant|weed|spray|harv)_hours_season[0-9]+$")$s[g$survey_season >= 5 & g$buy_treatment == 0]), "\n")
# households with zero plots in post
z <- g %>% filter(survey_season >= 4, maize_tot_plotn == 0 | is.na(maize_tot_plotn))
print(as.data.frame(z[, c("hhh_id","survey_season","maize_tot_plotn","harvest_kg","acres_tot","plot_size_1","harvest_kg_1","sold_kg_p_1")]))
# harvest_kg vs plot sum in season 7 mismatches
hk <- rowSums(g[, paste0("harvest_kg_", 1:9)], na.rm = TRUE); hkn <- rowSums(!is.na(g[, paste0("harvest_kg_", 1:9)]))
m <- g$survey_season == 7 & !is.na(g$harvest_kg) & hkn == 0
print(as.data.frame(g[m, c("hhh_id","form_used","harvest_kg","acres_tot","maize_tot_plotn")]))
# seller vs sold_kg_p
s <- zap_labels(read_dta(paste0(D, "seller_data.dta")))
hsp <- s %>% group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg = sum(sold_kg_p_), .groups = "drop") %>% mutate(p = rev / kg)
gg <- g %>% select(hhh_id, survey_season, buy_treatment, ea_code) %>% left_join(hsp, by = c("hhh_id","survey_season"))
cat("post rows with price:", sum(gg$survey_season >= 4 & !is.na(gg$p)), "\n")
pre <- gg %>% filter(survey_season <= 3) %>% group_by(hhh_id) %>% summarise(pp = mean(p, na.rm = TRUE))
gg <- gg %>% left_join(pre, by = "hhh_id")
cat("post rows with price & pre price:", sum(gg$survey_season >= 4 & !is.na(gg$p) & is.finite(gg$pp)), "\n")
cat("post rows in g1 hh:", sum(gg$survey_season >= 4), " distinct hh post:", length(unique(gg$hhh_id[gg$survey_season >= 4])), "\n")
cat("mean price UGX control by season:\n"); print(gg %>% filter(buy_treatment == 0) %>% group_by(survey_season) %>% summarise(mp = mean(p, na.rm = TRUE)))
