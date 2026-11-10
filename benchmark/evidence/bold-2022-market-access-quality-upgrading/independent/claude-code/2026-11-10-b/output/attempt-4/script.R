suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw"
options(width = 250, dplyr.width = Inf, tibble.width = Inf, dplyr.summarise.inform = FALSE)
rs <- function(d, v) { v <- intersect(v, names(d)); m <- as.matrix(d[, v, drop = FALSE]); out <- rowSums(m, na.rm = TRUE); out[rowSums(!is.na(m)) == 0] <- NA; out }
z <- function(x) ifelse(is.na(x), 0, x)
USD <- 3700
p <- read_dta(file.path(D, "panel_g1.dta")); p$season <- as.numeric(p$survey_season)
p$harvest <- ifelse(p$season >= 3, p$harvest_kg, rs(p, paste0("harvest_kg_", 1:6)))
p$psum <- rs(p, paste0("plot_size_", 1:6))
p$acres <- ifelse(p$season >= 3 & !is.na(p$acres_tot), p$acres_tot, z(p$psum))
fu <- p %>% filter(season >= 4, !is.na(labor_cost_ph))
c0 <- fu$buy_treatment == 0
mm <- function(v) { x <- fu[[v]]; sprintf("%-26s n=%3d mean0=%8.2f USD  meanAll=%8.2f", v, sum(!is.na(x)), mean(z(x)[c0]) / USD, mean(z(x)) / USD) }
vars <- c(paste0("seeds_cost_", 1:6), "seeds_cost", paste0("fert_cost_", 1:5), "fert_cost", paste0("booster_cost_", 1:5), "booster_cost", paste0("manure_cost_", 1:3), paste0("tot_chem_costs_", 1:6),
  paste0("equipment_cost_", 1:5), paste0("tot_lab_costs_", 1:6), paste0("harvest_cost_", 1:5), paste0("decobbing_cost_", 1:5),
  "labor_cost_dry", "drying_cost", "labor_cost_store", "storage_cost", "labor_cost_ph", "otherph_cost",
  "lc_decob_labour_costs", "lc_decob_labmaize_costs", "lc_decob_other_costs", "lc_winnow_labour_costs", "lc_winnow_other_costs", "lc_sort_labour_costs", "lc_sort_other_costs", "lc_bag_labour_costs", "lc_bag_labmaize_costs", "lc_bag_other_costs",
  "tot_transport_cost", "cost_transportpre", "cost_transportpost", paste0("sale_transport_cost_", c(1,2,3,5)))
for (v in vars) cat(mm(v), "\n")
cat("\nBy season control means (USD) of key aggregates\n")
print(fu %>% mutate(lph = z(labor_cost_ph), oph = z(otherph_cost), dec = z(lc_decob_labour_costs) + z(lc_winnow_labour_costs) + z(lc_sort_labour_costs) + z(lc_bag_labour_costs),
  deco = z(lc_decob_other_costs) + z(lc_winnow_other_costs) + z(lc_sort_other_costs) + z(lc_bag_other_costs), dry = z(drying_cost) + z(storage_cost), dryl = z(labor_cost_dry) + z(labor_cost_store),
  harvc = z(rs(fu, paste0("harvest_cost_", 1:5))), decc = z(rs(fu, paste0("decobbing_cost_", 1:5))), lharv = z(rs(fu, paste0("lc_harv_costs_season", 1:6))), tl = z(rs(fu, paste0("tot_lab_costs_", 1:6))), lpre = z(rs(fu, as.vector(outer(c("prep","plant","weed","spray"), 1:6, function(a,b) paste0("lc_", a, "_costs_season", b)))))) %>%
  group_by(season, buy_treatment) %>% summarise(n = n(), lph = mean(lph)/USD, oph = mean(oph)/USD, dec = mean(dec)/USD, deco = mean(deco)/USD, dry = mean(dry)/USD, dryl = mean(dryl)/USD, harvc = mean(harvc)/USD, decc = mean(decc)/USD, lharv = mean(lharv)/USD, tl = mean(tl)/USD, lpre = mean(lpre)/USD))
# check identities in s5-7
s <- fu %>% filter(season >= 5)
d1 <- z(s$labor_cost_ph) - (z(s$lc_decob_labour_costs) + z(s$lc_winnow_labour_costs) + z(s$lc_sort_labour_costs) + z(s$lc_bag_labour_costs) + z(s$labor_cost_dry) + z(s$labor_cost_store))
cat("labor_cost_ph - sum(lc_*_labour + dry + store): "); print(summary(d1)); print(mean(abs(d1) < 1))
d1b <- z(s$labor_cost_ph) - (z(s$lc_decob_labour_costs) + z(s$lc_winnow_labour_costs) + z(s$lc_sort_labour_costs) + z(s$lc_bag_labour_costs))
cat("labor_cost_ph - sum(lc_*_labour): "); print(summary(d1b)); print(mean(abs(d1b) < 1))
d2 <- z(s$otherph_cost) - (z(s$lc_decob_other_costs) + z(s$lc_winnow_other_costs) + z(s$lc_sort_other_costs) + z(s$lc_bag_other_costs))
cat("otherph - sum(lc_*_other): "); print(summary(d2)); print(mean(abs(d2) < 1))
d3 <- z(s$otherph_cost) - (z(s$lc_decob_other_costs) + z(s$lc_winnow_other_costs) + z(s$lc_sort_other_costs) + z(s$lc_bag_other_costs) + z(s$drying_cost) + z(s$storage_cost))
cat("otherph - sum(lc_*_other + drying + storage): "); print(summary(d3)); print(mean(abs(d3) < 1))
s4 <- fu %>% filter(season == 4)
cat("season 4 otherph vs decobbing_cost etc\n"); print(head(as.data.frame(s4[, c("labor_cost_ph","otherph_cost","drying_cost","storage_cost","labor_cost_dry","labor_cost_store","decobbing_cost_1","harvest_cost_1","equipment_cost_1","tot_transport_cost","cost_transportpre","cost_transportpost")]), 15))
cat("season 6 sample\n"); print(head(as.data.frame(s[s$season == 6, c("labor_cost_ph","otherph_cost","lc_decob_labour_costs","lc_decob_other_costs","lc_bag_labour_costs","lc_bag_other_costs","drying_cost","storage_cost","tot_transport_cost","cost_transportpre","cost_transportpost")]), 15))
d4 <- z(s$tot_transport_cost) - z(s$cost_transportpre) - z(s$cost_transportpost); cat("transport identity: "); print(mean(abs(d4) < 1))
# chem vs tot_chem
# inputs check: is tot_chem in seeds? fert includes boosters? Compare tot_chem_costs vs booster
print(summary(fu[, c("tot_chem_costs_1","booster_cost_1","fert_cost_1","seeds_cost_1")]))
# tot_lab_costs vs lc_*_costs_season sum
tl <- z(rs(fu, paste0("tot_lab_costs_", 1:6))); lcs <- z(rs(fu, as.vector(outer(c("prep","plant","weed","spray","harv"), 1:6, function(a,b) paste0("lc_", a, "_costs_season", b)))))
print(table(abs(tl - lcs) < 1, fu$season))
# yield alternatives
fu2 <- p %>% filter(season >= 4)
c02 <- fu2$buy_treatment == 0
y1 <- ifelse(fu2$acres > 0, fu2$harvest / fu2$acres, NA); y2 <- ifelse(fu2$psum > 0, fu2$harvest / fu2$psum, NA)
cat("yield acres_tot", mean(y1[c02], na.rm = TRUE), sum(!is.na(y1)), " yield psum", mean(y2[c02], na.rm = TRUE), sum(!is.na(y2)), "\n")
y3 <- ifelse(!is.na(fu2$psum) & fu2$psum > 0, fu2$harvest / fu2$psum, y1); cat("yield psum else acres", mean(y3[c02], na.rm = TRUE), sum(!is.na(y3)), "\n")
cat("acres==0 & harvest>0:", sum(fu2$acres == 0 & fu2$harvest > 0, na.rm = TRUE), " harvest==0:", sum(fu2$harvest == 0, na.rm = TRUE), "\n")
print(summary(y1)); print(sort(y1, decreasing = TRUE)[1:10])
# wage info: cost per day where unit days
w <- c(); hpd <- c()
for (t in c("prep","plant","weed","spray","harv")) for (k in 1:6) {
  u <- paste0("lc_", t, "_unit", k); cu <- paste0("lc_", t, "_costs_unit", k)
  if (u %in% names(p) && cu %in% names(p)) { sel <- p[[u]] == "days" & !is.na(p[[cu]]) & p[[cu]] > 0; w <- rbind(w, data.frame(season = p$season[sel], ea = p$ea_code[sel], cpd = p[[cu]][sel])) }
  u2 <- paste0("lh_", t, "_unit", k); h2 <- paste0("lh_", t, "_hours_unit", k)
  if (u2 %in% names(p) && h2 %in% names(p)) { sel <- p[[u2]] == "days" & !is.na(p[[h2]]) & p[[h2]] > 0; hpd <- c(hpd, p[[h2]][sel]) }
}
print(w %>% group_by(season) %>% summarise(n = n(), med = median(cpd), mean = mean(cpd)))
cat("hours per day (family) median", median(hpd), " mean", mean(hpd), "\n")
