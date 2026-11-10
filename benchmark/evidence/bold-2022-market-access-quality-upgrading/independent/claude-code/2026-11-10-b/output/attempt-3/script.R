suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw"
options(width = 250, dplyr.width = Inf, tibble.width = Inf, dplyr.summarise.inform = FALSE)
rs <- function(d, v) { v <- intersect(v, names(d)); m <- as.matrix(d[, v, drop = FALSE]); out <- rowSums(m, na.rm = TRUE); out[rowSums(!is.na(m)) == 0] <- NA; out }
z <- function(x) ifelse(is.na(x), 0, x)

## ---------- Returns experiment: control means / counts only (no treatment effects) ----------
r <- read_dta(file.path(D, "anonym_returns_data.dta"))
defs <- list(dirty = "dirty", cobs = "cobs", stones = "stones", dust = "dust", insect = c("insect", "insect_live"), broken = "broken", immature = "immature", damage = "damage", rot = "rot", mould = "mould")
bags <- list()
for (b in 1:20) {
  w <- r[[paste0("add4_weight_", b)]]
  M <- sapply(names(defs), function(d) { vs <- paste0("add4_", defs[[d]], "_", b); x <- sapply(vs, function(v) as.numeric(r[[v]])); if (is.null(dim(x))) x <- matrix(x, ncol = length(vs)); x[x > 1] <- NA; y <- apply(x, 1, function(q) if (all(is.na(q))) NA else max(q, na.rm = TRUE)); y })
  anyobs <- rowSums(!is.na(M)) > 0
  bags[[b]] <- data.frame(id = r$hhh_id, tr = r$treatment, ea = r$ea_code, bag = b, w = w, ndef = rowSums(M, na.rm = TRUE), anyobs = anyobs, nobs = rowSums(!is.na(M)))
}
bags <- bind_rows(bags) %>% filter(!is.na(w))
cat("bags with weight", nrow(bags), " with any defect obs", sum(bags$anyobs), "\n")
print(table(bags$nobs))
cat("mean ndef control (anyobs):", mean(bags$ndef[bags$anyobs & bags$tr == 0]), " all:", mean(bags$ndef[bags$tr == 0]), "\n")
print(table(bags$tr, bags$anyobs)); print(bags %>% filter(!anyobs) %>% count(id, tr))
cat("excluding weight<20:", sum(bags$w >= 20), "\n")
# lab
labc <- c("Foreign_matter_tot_g","Inorganic_matter_tot_g","Broken_grains_tot_g","Pest_damaged_grains_tot_g","Rotten_and_diseased_grain","Discoloured_grains_tot_g","Immature_or_shrivelled_gr")
r$labdef <- rowSums(as.matrix(r[, labc]), na.rm = TRUE) / r$Total_weight_of_maize_g
cat("lab n", sum(!is.na(r$labdef)), " control mean", mean(r$labdef[r$treatment == 0], na.rm = TRUE), " /200:", mean(rowSums(as.matrix(r[r$treatment==0, labc]), na.rm = TRUE)[!is.na(r$Total_weight_of_maize_g[r$treatment==0])]/200), "\n")
# sales
sales <- list()
for (i in seq_len(nrow(r))) {
  wts <- unlist(r[i, paste0("add4_weight_", 1:20)]); wts <- wts[!is.na(wts)]
  rb <- r$add4_random_bag[i]
  rest <- wts[-rb]
  pos <- 0
  for (k in 2:4) {
    p <- r[[paste0("add5_ppk_", k)]][i]
    if (is.na(p)) next
    iw <- unlist(r[i, paste0("add5_ind_weight", 1:20, "_", k)]); dw <- unlist(r[i, paste0("add5_ind_ded_weight", 1:20, "_", k)])
    nb <- sum(!is.na(iw))
    yv <- if (pos + nb <= length(rest)) rest[(pos + 1):(pos + nb)] else NA
    pos <- pos + nb
    sales[[length(sales) + 1]] <- data.frame(id = r$hhh_id[i], tr = r$treatment[i], ea = r$ea_code[i], k = k, p = p, date = r[[paste0("add5_sold_when_e_", k)]][i], nb = nb,
      y = sum(yv), x = sum(iw, na.rm = TRUE), zz = sum(dw, na.rm = TRUE))
  }
}
sales <- bind_rows(sales)
sales$ded <- 100 * (sales$y - sales$zz) / sales$y
sales$ded2 <- 100 * (sales$x - sales$zz) / sales$x
sales$cheat <- 100 * (sales$y - sales$x) / sales$y
sales$net <- sales$p * sales$zz / sales$y
cat("sales n", nrow(sales), " hh", length(unique(sales$id)), "\n")
print(summary(sales[, c("p","ded","ded2","cheat","net")]))
cat("control means: p", mean(sales$p[sales$tr==0]), " ded", mean(sales$ded[sales$tr==0]), " net", mean(sales$net[sales$tr==0]), "\n")
cat("all means: ded", mean(sales$ded), " ded2", mean(sales$ded2), " cheat", mean(sales$cheat), " share>5", mean(sales$ded > 5), "\n")
sales$week <- format(sales$date, "%Y-%U"); print(table(sales$week))
print(sales %>% filter(ded < -1 | ded > 15))

## ---------- Market access panel ----------
p <- read_dta(file.path(D, "panel_g1.dta"))
p$season <- as.numeric(p$survey_season)
units <- c("lh_prep_unit1","lc_prep_unit1","lc_weed_unit1","lc_harv_unit1")
for (u in units) { cat(u, "\n"); print(table(p[[u]], p$season)) }
# hired wage per unit
for (t in c("prep","plant","weed","harv")) {
  u <- p[[paste0("lc_", t, "_unit1")]]; cu <- p[[paste0("lc_", t, "_costs_unit1")]]; cs <- p[[paste0("lc_", t, "_costs_season1")]]
  cat(t, ": cost/unit by unit\n"); print(tapply(cu, u, function(x) round(quantile(x[x > 0], c(.1,.25,.5,.75,.9), na.rm = TRUE))))
}
for (t in c("prep","plant","weed","harv")) { u <- p[[paste0("lh_", t, "_unit1")]]; h <- p[[paste0("lh_", t, "_hours_unit1")]]; cat(t, " lh hours per unit by unit\n"); print(tapply(h, u, function(x) quantile(x, c(.25,.5,.75), na.rm = TRUE))) }

USD <- 3700
p$harvest <- ifelse(p$season >= 3, p$harvest_kg, rs(p, paste0("harvest_kg_", 1:6)))
p$acres <- ifelse(p$season >= 3 & !is.na(p$acres_tot), p$acres_tot, z(rs(p, paste0("plot_size_", 1:6))))
p$yield <- ifelse(p$acres > 0, p$harvest / p$acres, NA)
sd <- read_dta(file.path(D, "seller_data.dta"))
sd$season <- as.numeric(sd$survey_season)
pr <- sd %>% filter(price > 0, sold_kg_p_ > 0) %>% group_by(hhh_id, season) %>% summarise(price_w = sum(price * sold_kg_p_) / sum(sold_kg_p_), price_m = mean(price), sold = sum(sold_kg_p_), rev = sum(price * sold_kg_p_), nsale = n(), .groups = "drop")
p <- left_join(p, pr, by = c("hhh_id", "season"))
vp <- p %>% group_by(ea_code, season) %>% summarise(vprice = mean(price_w, na.rm = TRUE), vprice_med = median(price_w, na.rm = TRUE), .groups = "drop")
p <- left_join(p, vp, by = c("ea_code", "season"))
p$hv_a <- p$harvest * ifelse(is.na(p$price_w), p$vprice, p$price_w)
p$hv_b <- z(p$rev) + pmax(p$harvest - z(p$sold), 0) * p$vprice
p$hv_c <- p$harvest * p$vprice
# expenses
inputs <- c(paste0("seeds_cost_", 1:6), paste0("fert_cost_", 1:5), paste0("booster_cost_", 1:5), "booster_cost", "seeds_cost", "fert_cost", paste0("manure_cost_", 1:3), paste0("tot_chem_costs_", 1:6))
p$e_inputs <- z(rs(p, inputs))
p$e_equip <- z(rs(p, paste0("equipment_cost_", 1:5)))
p$e_hlab_pre <- z(rs(p, paste0("tot_lab_costs_", 1:6)))
p$e_harv <- z(rs(p, paste0("harvest_cost_", 1:5)))
p$e_ph <- z(rs(p, c("labor_cost_ph", "otherph_cost", "drying_cost", "storage_cost")))
p$e_ph2 <- z(rs(p, c("labor_cost_ph", "otherph_cost")))
p$e_transp <- ifelse(!is.na(p$tot_transport_cost), p$tot_transport_cost, z(p$cost_transportpre) + z(p$cost_transportpost))
p$e_dec <- z(rs(p, paste0("decobbing_cost_", 1:5)))
p$expA <- with(p, e_inputs + e_equip + e_hlab_pre + e_harv + e_ph2 + e_transp)
p$expA[is.na(p$labor_cost_ph)] <- NA
p$fam_hours <- rs(p, c(as.vector(outer(c("prep","plant","weed","spray","harv"), 1:6, function(a, b) paste0("lh_", a, "_hours_season", b))), "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours"))
fu <- p %>% filter(season >= 4)
cat("\nFollow-up counts: all", nrow(fu), " harvest", sum(!is.na(fu$harvest)), " yield", sum(!is.na(fu$yield)), " price", sum(!is.na(fu$price_w)), " exp", sum(!is.na(fu$expA)), " famh", sum(!is.na(fu$fam_hours)), " hv_a", sum(!is.na(fu$hv_a)), " hv_b", sum(!is.na(fu$hv_b)), "\n")
cm <- function(x) mean(x[fu$buy_treatment == 0], na.rm = TRUE)
cat("control means (target: price .15 acre 2.29 harv 1887.52 yield 791.97 hv 286.17 exp 106.38 prof 177.23)\n")
cat(" price", cm(fu$price_w) / USD, cm(fu$price_m) / USD, " acres", cm(fu$acres), " harvest", cm(fu$harvest), " yield", cm(fu$yield), "\n")
cat(" hv_a", cm(fu$hv_a) / USD, " hv_b", cm(fu$hv_b) / USD, " hv_c", cm(fu$hv_c) / USD, "\n")
for (v in c("e_inputs","e_equip","e_hlab_pre","e_harv","e_ph","e_ph2","e_transp","e_dec","expA")) cat(" ", v, cm(fu[[v]][!is.na(fu$expA)]) / USD, "\n")
cat(" profitA", cm(fu$hv_a - fu$expA) / USD, cm(fu$hv_b - fu$expA) / USD, " famhours", cm(fu$fam_hours), "\n")
bl <- p %>% filter(season <= 3)
cat("\nBaseline counts: n", nrow(bl), " harvest", sum(!is.na(bl$harvest)), " yield", sum(!is.na(bl$yield)), " price", sum(!is.na(bl$price_w)), " exp", sum(!is.na(bl$expA)), "\n")
cat("baseline means (target acre 2.16 exp 146.3 harv 2100 yield(t/ha) 2.09 price .20 hv 433.2 profit 263.7):\n")
cat(" acres", mean(bl$acres), " harvest", mean(bl$harvest, na.rm = TRUE), " yield t/ha", mean(bl$yield, na.rm = TRUE) * 2.471 / 1000, " price", mean(bl$price_w, na.rm = TRUE) / USD, " hv_a", mean(bl$hv_a, na.rm = TRUE) / USD, " hv_b", mean(bl$hv_b, na.rm = TRUE) / USD, " exp", mean(bl$expA, na.rm = TRUE) / USD, "\n")
print(bl %>% group_by(season) %>% summarise(n = n(), harv = sum(!is.na(harvest)), pr = sum(!is.na(price_w)), mp = mean(price_w, na.rm = TRUE), ac = sum(acres > 0)))
# households in follow-up without any baseline value
hb <- bl %>% group_by(hhh_id) %>% summarise(h = mean(harvest, na.rm = TRUE), pr = mean(price_w, na.rm = TRUE), e = mean(expA, na.rm = TRUE))
fu2 <- left_join(fu, hb, by = "hhh_id")
cat("fu harvest obs missing baseline harvest:", sum(!is.na(fu2$harvest) & is.na(fu2$h)), " price obs missing bl price:", sum(!is.na(fu2$price_w) & is.na(fu2$pr)), " exp missing bl:", sum(!is.na(fu2$expA) & is.na(fu2$e)), "\n")
cat("fu hh:", length(unique(fu$hhh_id)), " bl hh:", length(unique(bl$hhh_id)), " fu hh not in bl:", length(setdiff(fu$hhh_id, bl$hhh_id)), "\n")
# wage: check hired cost per hour where unit hours
# fam hours by season
print(fu %>% group_by(season, buy_treatment) %>% summarise(fh = mean(fam_hours, na.rm = TRUE), nfh = sum(!is.na(fam_hours)), hl = mean(e_hlab_pre, na.rm = TRUE) / USD))
