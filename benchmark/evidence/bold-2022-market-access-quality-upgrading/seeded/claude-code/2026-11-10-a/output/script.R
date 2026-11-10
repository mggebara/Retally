# Retally reproduction: Bold et al. (2022) "Market Access and Quality Upgrading"
# Seeded mode: translation of FINAL_create_vars_main_g1.do + table6.do (Panel A)
# and FINAL_create_vars_returns.do + table2.do into R.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/data/raw/"

# ---------------- helpers (Stata egen semantics) ----------------
cols_like <- function(df, pats) {
  # Stata wildcard: '?' = exactly one character
  out <- character(0)
  for (p in pats) {
    rx <- paste0("^", gsub("?", ".", p, fixed = TRUE), "$")
    out <- c(out, grep(rx, names(df), value = TRUE))
  }
  unique(out)
}
rowtotal_m <- function(df, cols) {             # egen rowtotal(...), missing
  if (length(cols) == 0) return(rep(NA_real_, nrow(df)))
  m <- as.matrix(df[, cols, drop = FALSE]); storage.mode(m) <- "double"
  s <- rowSums(m, na.rm = TRUE); s[rowSums(!is.na(m)) == 0] <- NA; s
}
rowtotal0 <- function(df, cols) {              # egen rowtotal(...)
  if (length(cols) == 0) return(rep(0, nrow(df)))
  m <- as.matrix(df[, cols, drop = FALSE]); storage.mode(m) <- "double"
  rowSums(m, na.rm = TRUE)
}
rowmean_ <- function(df, cols) {
  m <- as.matrix(df[, cols, drop = FALSE]); storage.mode(m) <- "double"
  r <- rowMeans(m, na.rm = TRUE); r[is.nan(r)] <- NA; r
}
rowmax_ <- function(df, cols) {
  m <- as.matrix(df[, cols, drop = FALSE]); storage.mode(m) <- "double"
  r <- suppressWarnings(apply(m, 1, max, na.rm = TRUE)); r[!is.finite(r)] <- NA; r
}
rowmedian_ <- function(m) {
  apply(m, 1, function(x) { x <- x[!is.na(x)]; if (length(x) == 0) NA_real_ else median(x) })
}
sdiv <- function(a, b) { r <- a / b; r[!is.finite(r)] <- NA; r }   # Stata x/0 = .
stata_mode <- function(x) {                    # egen mode(): missing if several modes
  x <- x[!is.na(x)]; if (!length(x)) return(NA_real_)
  t <- table(x); m <- which(t == max(t))
  if (length(m) > 1) return(NA_real_)
  as.numeric(names(t)[m])
}
nz <- function(x) !is.na(x)
`%==%` <- function(a, b) !is.na(a) & a == b
stata_week <- function(d) {                   # Stata week(): 1..52
  doy <- as.numeric(format(d, "%j")); w <- floor((doy - 1) / 7) + 1; pmin(w, 52)
}

# =================================================================
# PART 1: panel_g1 (market access experiment) -> Table 6 Panel A
# =================================================================
p <- read_dta(paste0(D, "panel_g1.dta"))
p <- zap_labels(p)
p <- as.data.frame(p)
for (v in names(p)) if (is.character(p[[v]])) p[[v]][is.na(p[[v]])] <- ""
cat("panel_g1 rows:", nrow(p), " duplicate hhh_id x season:",
    sum(duplicated(p[, c("hhh_id", "survey_season")])), "\n")
ss <- p$survey_season
phone <- p$form_used == "Phone_Market_Survey_spring2020"
mkt20 <- p$form_used == "Market_Survey_spring2020"

# acreage
p$acreage <- rowtotal_m(p, cols_like(p, c("plot_size_?", "plot_size_??")))
p$acreage[is.na(p$acreage) & p$maize_tot_plotn %==% 0] <- 0
i <- ss == 7 & phone; p$acreage[i] <- p$acres_tot[i]

# equipment (spring 2018 only)
p$equipment_cost_tot <- ifelse(ss == 3, rowtotal_m(p, cols_like(p, "equipment_cost_?")), NA)
# chemicals
p$tot_chem_costs <- rowtotal_m(p, cols_like(p, "tot_chem_costs_?"))
# seeds
p$seeds_cost_tot <- ifelse(ss >= 2, rowtotal_m(p, cols_like(p, "seeds_cost_?")), NA)
i <- ss == 7 & phone; p$seeds_cost_tot[i] <- p$seeds_cost[i]
# fertilizer
p$fert_cost_tot <- ifelse(ss >= 2, rowtotal_m(p, cols_like(p, "fert_cost_?")), NA)
p$fert_cost_tot[i] <- p$fert_cost[i]
# manure, booster
p$manure_cost_tot <- ifelse(ss >= 2, rowtotal_m(p, cols_like(p, "manure_cost_?")), NA)
p$booster_cost_tot <- ifelse(ss >= 2, rowtotal_m(p, cols_like(p, "booster_cost_?")), NA)
p$booster_cost_tot[i] <- p$booster_cost[i]
j <- is.na(p$manure_cost_tot) & nz(p$acreage) & p$acreage != 0 &
  (ss == 4 | ss == 6 | (ss == 7 & mkt20))
p$manure_cost_tot[j] <- 0
# harvest cost
p$harvest_cost_tot <- ifelse(ss == 2 | ss == 3, rowtotal_m(p, cols_like(p, "harvest_cost_?")), NA)

# harvested amount and yield
p$harvest_kg_tot <- rowtotal_m(p, cols_like(p, "harvest_kg_?"))
i <- p$season_spring2020 %==% 1 & phone; p$harvest_kg_tot[i] <- p$harvest_kg[i]
p$yield <- sdiv(p$harvest_kg_tot, p$acreage)
i <- p$hhh_id == 10247005 & p$season_spring2018 %==% 1
p$yield[i] <- sdiv(p$harvest_kg_1[i], p$plot_size_1[i])
i <- (p$hhh_id == 10165041 | p$hhh_id == 10231013) & ss == 5
p$yield[i] <- sdiv(p$harvest_kg_2[i], p$plot_size_2[i])

# post-harvest costs: missing for non-growers
for (v in c("storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph")) p[[v]][p$acreage %==% 0] <- NA
p$decobbing_cost_tot <- ifelse(ss == 2, rowtotal_m(p, cols_like(p, "decobbing_cost_?")), NA)
p$decobbing_cost_tot[p$acreage %==% 0] <- NA

# labor costs up to and including harvest
for (a in c("prep", "plant", "weed", "spray", "harv")) {
  v <- paste0("labor_cost_", a, "_tot")
  p[[v]] <- ifelse(ss != 1, rowtotal_m(p, cols_like(p, paste0("lc_", a, "_costs_season?"))), NA)
  j <- is.na(p[[v]]) & nz(p$acreage) & p$acreage != 0 & ss == 5
  p[[v]][j] <- 0
}
j <- is.na(p$labor_cost_store) & p$storage != "" & ss >= 5
p$labor_cost_store[j] <- 0
p$expenses_labor_preharvest_ugx <- ifelse(ss != 1 & ss != 4 & !phone,
  rowtotal_m(p, c("labor_cost_prep_tot", "labor_cost_plant_tot", "labor_cost_spray_tot", "labor_cost_weed_tot")), NA)
p$tot_lab_costs_preh_aggh_tot <- ifelse(ss >= 4, rowtotal_m(p, cols_like(p, "tot_lab_costs_?")), NA)
i <- ss == 2 | ss == 3
p$tot_lab_costs_preh_aggh_tot[i] <- p$expenses_labor_preharvest_ugx[i] + p$labor_cost_harv_tot[i]

# labor hours up to and including harvest
for (a in c("prep", "plant", "spray", "weed", "harv")) {
  v <- paste0(a, "_unpaid_lab_tothrs")
  p[[v]] <- ifelse(ss >= 5, rowtotal_m(p, cols_like(p, paste0("lh_", a, "_hours_season?"))), NA)
}
j <- is.na(p$spray_unpaid_lab_tothrs) & nz(p$acreage) & p$acreage != 0 & ss == 5
p$spray_unpaid_lab_tothrs[j] <- 0
p$tot_lab_hours_preh_aggh_tot <- ifelse(ss >= 5, rowtotal_m(p,
  c("prep_unpaid_lab_tothrs", "plant_unpaid_lab_tothrs", "weed_unpaid_lab_tothrs",
    "spray_unpaid_lab_tothrs", "harv_unpaid_lab_tothrs")), NA)

# hourly wage (mode of household median daily wage / mode of median daily hours)
med_cost <- list(); med_hours <- list()
for (a in c("prep", "plant", "weed", "harv")) {
  dc <- list(); dh <- list()
  for (n in 1:6) {
    if (paste0("lc_", a, "_unit", n) %in% names(p))
      dc[[length(dc) + 1]] <- ifelse(p[[paste0("lc_", a, "_unit", n)]] == "days", p[[paste0("lc_", a, "_costs_unit", n)]], NA)
    if (paste0("lh_", a, "_hours_unit", n) %in% names(p))
      dh[[length(dh) + 1]] <- ifelse(p[[paste0("lh_", a, "_unit", n)]] == "days", p[[paste0("lh_", a, "_hours_unit", n)]], NA)
  }
  med_cost[[a]] <- rowmedian_(do.call(cbind, dc))
  med_hours[[a]] <- rowmedian_(do.call(cbind, dh))
}
med_dailycost <- rowmedian_(do.call(cbind, med_cost))
med_dailyhours <- rowmedian_(do.call(cbind, med_hours))
dailyhours <- stata_mode(med_dailyhours)
dailywage <- stata_mode(med_dailycost)
hourlywage <- round(dailywage / dailyhours)
cat("daily hours mode:", dailyhours, " daily wage mode:", dailywage, " hourly wage:", hourlywage, "\n")
p$preh_unpaid_lab_aggh_sh <- p$tot_lab_hours_preh_aggh_tot * hourlywage

# post-harvest activities (spring 2019 onwards)
acts <- c("decob", "winnow", "sort", "bag")
for (a in acts) {
  d <- ifelse(p[[a]] != "" & ss >= 5, as.numeric(p[[a]] == "yes"), NA); p[[paste0(a, "_d")]] <- d
  for (v in c(paste0("lh_", a, "_hours"), paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_other_costs"))) {
    j <- is.na(p[[v]]) & nz(d) & ss >= 5; p[[v]][j] <- 0
  }
}
for (a in acts) p[[paste0("lh_", a, "_hours_sh")]] <- ifelse(ss >= 5, p[[paste0("lh_", a, "_hours")]] * 833, NA)
for (a in acts) {
  v <- paste0("lc_", a, "_lmtot_costs")
  p[[v]] <- ifelse(ss >= 5, p[[paste0("lc_", a, "_labmaize_costs")]] * p[[paste0("lc_", a, "_price")]], NA)
  j <- is.na(p[[v]]) & nz(p[[paste0(a, "_d")]]) & ss >= 5; p[[v]][j] <- 0
}
i <- p$hhh_id == 10247077 & ss == 7; p$lc_decob_lmtot_costs[i] <- p$lc_decob_labmaize_costs[i]
i <- p$hhh_id == 10247013 & ss == 7; p$lc_bag_lmtot_costs[i] <- p$lc_bag_labmaize_costs[i]
for (a in acts) p[[paste0(a, "_cost_tot")]] <- rowtotal_m(p,
  paste0("lc_", a, c("_labour_costs", "_lmtot_costs", "_other_costs")))

# sold amounts
p$sold_kg_tot <- rowtotal_m(p, cols_like(p, "sold_kg_p_?"))
i <- ss == 7 & phone; p$sold_kg_tot[i] <- p$sold_kg[i]
h <- p$hhh_id
p$sold_kg_tot[h == 10249047 & ss == 1] <- 0
p$sold_kg_tot[h == 10328006 & ss == 1] <- 0
p$sold_kg_tot[h == 10165056 & ss == 2 & p$survey_round == 1] <- 0
p$sold_kg_tot[h == 10235011 & ss == 2 & p$survey_round == 1] <- 0
hk <- nz(p$harvest_kg_tot); sm <- is.na(p$sold_kg_tot)
p$sold_kg_tot[hk & sm & ss == 2 & p$survey_round == 2] <- 0
sm <- is.na(p$sold_kg_tot); p$sold_kg_tot[hk & sm & ss == 3] <- 0
sm <- is.na(p$sold_kg_tot); p$sold_kg_tot[hk & sm & ss == 5 & p$sold_crop == "no"] <- 0
sm <- is.na(p$sold_kg_tot); p$sold_kg_tot[hk & sm & ss == 6 & p$sold_crop == "no"] <- 0
sm <- is.na(p$sold_kg_tot); p$sold_kg_tot[hk & sm & ss == 7 & p$sold_crop == "no" & mkt20] <- 0
p$sold_kg_tot[h == 10235035 & p$season_spring2020 %==% 1] <- NA
l4 <- c(10078042, 10181008, 10181009, 10231001, 10247021, 10326064, 10328005, 10328014, 10328034, 10350040)
p$sold_crop[h %in% l4 & ss == 4] <- "no"; p$sold_kg_tot[h %in% l4 & ss == 4] <- 0
l5 <- c(10219013, 10231002, 10354079)
p$sold_crop[h %in% l5 & ss == 5] <- "no"; p$sold_kg_tot[h %in% l5 & ss == 5] <- 0

# transport cost to buyer
for (n in c(1, 2, 3, 5)) {
  v <- paste0("sale_transport_cost_", n)
  p[[v]][p[[paste0("sale_transport_yn_", n)]] == "no" & ss >= 3] <- 0
}
p$sale_transport_cost_tot <- ifelse(ss >= 3, rowtotal_m(p, cols_like(p, "sale_transport_cost_?")), NA)

# revenue and price
p$rev_tot <- rowtotal_m(p, cols_like(p, c("tot_rev_combined_?_?", "tot_rev_combined_?")))
p$rev_tot[phone] <- p$tot_rev_told_tot[phone]
p$rev_tot[nz(p$harvest_kg_tot) & is.na(p$rev_tot) & p$sold_kg_tot %==% 0] <- 0
p$price_ugx <- sdiv(p$rev_tot, p$sold_kg_tot)
p <- p %>% group_by(ea_code, survey_season) %>%
  mutate(price_vm = { x <- price_ugx[!is.na(price_ugx)]; if (length(x)) mean(x) else NA_real_ }) %>%
  ungroup() %>% as.data.frame()
ss <- p$survey_season; phone <- p$form_used == "Phone_Market_Survey_spring2020"; mkt20 <- p$form_used == "Market_Survey_spring2020"

# harvest value
p$remainder <- p$harvest_kg_tot - p$sold_kg_tot
# Stata: 'if remainder>=0' is also true for missing remainder (result then missing anyway)
p$harvest_value_ugx <- ifelse(is.na(p$remainder) | p$remainder >= 0, p$rev_tot + p$remainder * p$price_vm, NA)
i <- p$remainder < 0 & nz(p$remainder); p$harvest_value_ugx[i] <- p$harvest_kg_tot[i] * p$price_ugx[i]
i <- p$hhh_id == 10249026 & ss == 3; p$harvest_value_ugx[i] <- p$harvest_kg_tot[i] * p$price_vm[i]

# expenses by season
E <- function(cols, cond) ifelse(cond, rowtotal_m(p, cols), NA)
ex_f17 <- E(c("seeds_cost_tot", "fert_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
  "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "harvest_cost_tot", "decobbing_cost_tot", "storage_cost",
  "drying_cost", "otherph_cost", "labor_cost_ph", "cost_transportpre", "cost_transportpost"), ss == 2)
ex_s18 <- E(c("seeds_cost_tot", "fert_cost_tot", "manure_cost_tot", "booster_cost_tot", "equipment_cost_tot",
  "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "tot_chem_costs", "harvest_cost_tot", "storage_cost",
  "drying_cost", "otherph_cost", "labor_cost_ph", "labor_cost_dry", "labor_cost_store", "cost_transportpre",
  "cost_transportpost", "sale_transport_cost_tot"), ss == 3)
ex_f18 <- E(c("fert_cost_tot", "tot_chem_costs", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot",
  "tot_lab_costs_preh_aggh_tot", "drying_cost", "storage_cost", "labor_cost_store", "otherph_cost", "labor_cost_ph",
  "tot_transport_cost", "sale_transport_cost_tot"), ss == 4)
post_cols <- c("fert_cost_tot", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
  "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "drying_cost", "storage_cost", "labor_cost_store",
  "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot", "decob_cost_tot", "sort_cost_tot",
  "winnow_cost_tot", "bag_cost_tot")
ex_s19 <- E(post_cols, ss == 5)
ex_f19 <- E(post_cols, ss == 6)
ex_s20 <- E(post_cols, ss == 7 & mkt20)
hrs_cols <- c(post_cols, "preh_unpaid_lab_aggh_sh", "lh_decob_hours_sh", "lh_sort_hours_sh",
  "lh_winnow_hours_sh", "lh_bag_hours_sh")
exh_s19 <- E(hrs_cols, ss == 5)
exh_f19 <- E(hrs_cols, ss == 6)
exh_s20 <- E(hrs_cols, ss == 7 & mkt20)

p$expenses_ugx <- NA_real_
for (k in list(list("season_fall2017", ex_f17), list("season_spring2018", ex_s18), list("season_fall2018", ex_f18),
               list("season_spring2019", ex_s19), list("season_fall2019", ex_f19), list("season_spring2020", ex_s20))) {
  i <- p[[k[[1]]]] %==% 1; p$expenses_ugx[i] <- k[[2]][i]
}
p$expenses_ugx[p$season_spring2020 %==% 1 & phone] <- NA
p$expenses_hours_ugx <- NA_real_
for (k in list(list("season_spring2019", exh_s19), list("season_fall2019", exh_f19), list("season_spring2020", exh_s20),
               list("season_fall2017", ex_f17), list("season_spring2018", ex_s18))) {
  i <- p[[k[[1]]]] %==% 1; p$expenses_hours_ugx[i] <- k[[2]][i]
}
p$surplus_ugx <- p$harvest_value_ugx - p$expenses_ugx
p$surplus_hrs_ugx <- p$harvest_value_ugx - p$expenses_hours_ugx

# convert to USD with season exchange rates
fx <- c(`1` = 3575, `2` = 3601, `3` = 3626, `4` = 3758, `5` = 3670, `6` = 3685, `7` = 3681, `8` = 3685)
rate <- fx[as.character(p$survey_season)]
for (v in c("price", "harvest_value", "expenses", "expenses_hours", "surplus", "surplus_hrs"))
  p[[v]] <- p[[paste0(v, "_ugx")]] / rate

# ---------------- Table 6 Panel A: ANCOVA ----------------
g1 <- p[p$group %==% 1, ]
t6 <- list()
for (v in c("price", "acreage", "harvest_kg_tot", "yield", "harvest_value", "expenses", "surplus", "surplus_hrs")) {
  b3 <- g1 %>% filter(season_spring2018 %==% 1, !is.na(.data[[v]])) %>% group_by(hhh_id) %>%
    summarise(p3 = mean(.data[[v]]), .groups = "drop")
  ba <- g1 %>% filter(season_ante %==% 1, !is.na(.data[[v]])) %>% group_by(hhh_id) %>%
    summarise(pa = mean(.data[[v]]), .groups = "drop")
  d <- g1 %>% left_join(b3, by = "hhh_id") %>% left_join(ba, by = "hhh_id") %>%
    mutate(ctrl = ifelse(is.na(p3), pa, p3)) %>% filter(season_post %==% 1)
  d$y <- d[[v]]
  m <- feols(y ~ buy_treatment + ctrl + i(survey_season), data = d, cluster = ~ea_code)
  t6[[v]] <- m
  cat(sprintf("Table6A %-15s b=%.4f se=%.4f N=%d\n", v, coef(m)["buy_treatment"], se(m)["buy_treatment"], nobs(m)))
}

# =================================================================
# PART 2: returns-to-quality experiment -> Table 2
# =================================================================
r <- as.data.frame(zap_labels(read_dta(paste0(D, "anonym_returns_data.dta"))))
for (v in names(r)) if (is.character(r[[v]])) r[[v]][is.na(r[[v]])] <- ""
for (n in 1:20) {
  r[[paste0("add4_insect_n_", n)]] <- rowmax_(r, paste0(c("add4_insect_", "add4_insect_live_"), n))
  dv <- paste0(c("add4_dirty_", "add4_cobs_", "add4_stones_", "add4_dust_", "add4_broken_", "add4_immature_",
                 "add4_damage_", "add4_rot_", "add4_insect_n_", "add4_mould_"), n)
  r[[paste0("defects_visual_tot_", n)]] <- rowtotal_m(r, dv)
}
r$defect_lab <- rowtotal_m(r, c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g",
  "Pest_damaged_grains_tot_g", "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr"))
r$defects_lab_share_r <- sdiv(r$defect_lab, r$Total_weight_of_maize_g)
r$defects_lab_share_r[nz(r$defects_lab_share_r) & r$defects_lab_share_r > 1] <- 1

for (s in 1:4) {
  r[[paste0("week_sale_", s)]] <- stata_week(r[[paste0("add5_sold_when_e_", s)]])
  dt <- wt <- matrix(NA_real_, nrow(r), 20); np <- matrix(NA_real_, nrow(r), 20)
  for (b in 1:20) {
    dw <- r[[paste0("add5_ind_ded_weight", b, "_", s)]]; w <- r[[paste0("add4_weight_", b)]]
    dt[, b] <- ifelse(nz(dw), w - dw, NA)
    wt[, b] <- ifelse(nz(dw), w, NA)
    np[, b] <- sdiv(dw, w) * r[[paste0("add5_ppk_", s)]]
  }
  dtot <- rowSums(dt, na.rm = TRUE); wtot <- rowSums(wt, na.rm = TRUE)
  r[[paste0("deduct_totalshare100_", s)]] <- sdiv(dtot, wtot) * 100
  npa <- rowMeans(np, na.rm = TRUE); npa[is.nan(npa)] <- NA
  r[[paste0("net_priceavg_", s)]] <- npa
  r[[paste0("price_", s)]] <- r[[paste0("add5_ppk_", s)]]
}
r$ea_num <- as.numeric(gsub("EA", "", r$ea_code))
# (the quasi-control and bought samples appended in the .do file have treatment missing,
#  so they never enter the Table 2 regressions; they are omitted here)

# column (1): bags, long by bag number
bags <- do.call(rbind, lapply(1:20, function(b) data.frame(hhh_id = r$hhh_id, ea_num = r$ea_num,
  treatment = r$treatment, bagnum = b, y = r[[paste0("defects_visual_tot_", b)]])))
bags <- bags[nz(bags$y) & nz(bags$treatment), ]
m1 <- feols(y ~ treatment | ea_num, data = bags, cluster = ~hhh_id, fixef.rm = "none")
# column (2): lab share, robust SE
m2 <- feols(defects_lab_share_r ~ treatment | ea_num, data = r, vcov = "hetero", fixef.rm = "none")
# columns (3)-(5): sales, long by sale number, drop sale 1 (random bag sold to research team)
sales <- do.call(rbind, lapply(1:4, function(s) data.frame(hhh_id = r$hhh_id, ea_num = r$ea_num,
  treatment = r$treatment, salenum = s, price_ = r[[paste0("price_", s)]],
  week_sale_ = r[[paste0("week_sale_", s)]], deduct_ = r[[paste0("deduct_totalshare100_", s)]],
  netp_ = r[[paste0("net_priceavg_", s)]])))
sales <- sales[nz(sales$price_) & sales$salenum != 1, ]
m3 <- feols(price_ ~ treatment | ea_num + week_sale_, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m4 <- feols(deduct_ ~ treatment | ea_num + week_sale_, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m5 <- feols(netp_ ~ treatment | ea_num + week_sale_, data = sales, cluster = ~hhh_id, fixef.rm = "none")
for (nm in c("m1", "m2", "m3", "m4", "m5")) {
  m <- get(nm)
  cat(sprintf("Table2 %s b=%.4f se=%.4f N=%d\n", nm, coef(m)["treatment"], se(m)["treatment"], nobs(m)))
}

# ---------------- RESULTS ----------------
res <- c(
  treatment_defects_visual_table2_col1 = unname(coef(m1)["treatment"]),
  treatment_defects_lab_table2_col2 = unname(coef(m2)["treatment"]),
  treatment_price_table2_col3 = unname(coef(m3)["treatment"]),
  treatment_deductions_table2_col4 = unname(coef(m4)["treatment"]),
  treatment_net_price_table2_col5 = unname(coef(m5)["treatment"]),
  n_obs_table2_col1_bags = nobs(m1),
  n_obs_table2_cols3_5_sales = nobs(m3),
  market_access_price_table6_panelA_col1 = unname(coef(t6$price)["buy_treatment"]),
  market_access_yield_table6_panelA_col4 = unname(coef(t6$yield)["buy_treatment"]),
  market_access_harvest_value_table6_panelA_col5 = unname(coef(t6$harvest_value)["buy_treatment"]),
  market_access_profit_monetary_table6_panelA_col7 = unname(coef(t6$surplus)["buy_treatment"]),
  market_access_profit_incl_own_hours_table6_panelA_col8 = unname(coef(t6$surplus_hrs)["buy_treatment"]),
  n_obs_table6_panelA_cols3_5 = nobs(t6$harvest_value)
)
for (k in names(res)) cat(sprintf("RESULT:%s=%.6g\n", k, res[[k]]))
