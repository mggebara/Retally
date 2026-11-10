# Retally reproduction: Bold et al. (2022), "Market Access and Quality Upgrading"
# Seeded mode: translates FINAL_create_vars_returns.do + table2.do (Table 2) and
# FINAL_create_vars_main_g1.do + table6.do (Table 6, Panel A) into R.
suppressPackageStartupMessages({
  library(haven); library(dplyr); library(fixest)
})
set.seed(42)

ROOT <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/seeded/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading"
RAW <- file.path(ROOT, "data", "raw")

zap <- function(d) { d <- zap_labels(zap_formats(d)); as.data.frame(d, stringsAsFactors = FALSE) }

# Stata egen rowtotal(..., missing): NA only if all inputs missing
rt <- function(d, cols) {
  cols <- intersect(cols, names(d))
  if (length(cols) == 0) return(rep(NA_real_, nrow(d)))
  m <- sapply(cols, function(v) as.numeric(d[[v]]))
  if (is.null(dim(m))) m <- matrix(m, ncol = length(cols))
  s <- rowSums(m, na.rm = TRUE)
  s[rowSums(!is.na(m)) == 0] <- NA
  s
}
# Stata egen rowtotal without missing: 0 if all missing
rt0 <- function(d, cols) { s <- rt(d, cols); s[is.na(s)] <- 0; s }
rmean <- function(d, cols) {
  cols <- intersect(cols, names(d))
  m <- sapply(cols, function(v) as.numeric(d[[v]]))
  if (is.null(dim(m))) m <- matrix(m, ncol = length(cols))
  s <- rowMeans(m, na.rm = TRUE); s[is.nan(s)] <- NA; s
}
rmedian <- function(m) {
  if (is.null(dim(m))) m <- matrix(m, ncol = 1)
  apply(m, 1, function(x) { x <- x[!is.na(x)]; if (length(x)) median(x) else NA_real_ })
}
q1 <- function(d, prefix) grep(paste0("^", prefix, ".$"), names(d), value = TRUE)    # Stata `prefix?`
q2 <- function(d, prefix) grep(paste0("^", prefix, "..$"), names(d), value = TRUE)   # Stata `prefix??`
nz <- function(x) !is.na(x)
sdiv <- function(a, b) { r <- a / b; r[!is.finite(r)] <- NA; r }   # Stata: x/0 = missing
cond <- function(x) !is.na(x) & x                                    # TRUE only where non-missing TRUE

#############################################################################
# TABLE 2 : Returns to quality experiment
#############################################################################
r <- zap(read_dta(file.path(RAW, "anonym_returns_data.dta")))

for (n in 1:20) {
  r[[paste0("add4_insect_n_", n)]] <- {
    a <- r[[paste0("add4_insect_", n)]]; b <- r[[paste0("add4_insect_live_", n)]]
    out <- pmax(a, b, na.rm = TRUE); out
  }
  items <- paste0(c("add4_dirty_", "add4_cobs_", "add4_stones_", "add4_dust_", "add4_broken_",
                    "add4_immature_", "add4_damage_", "add4_rot_", "add4_insect_n_", "add4_mould_"), n)
  r[[paste0("defects_visual_tot_", n)]] <- rt(r, items)
}
r$defect_lab <- rt(r, c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g",
                        "Pest_damaged_grains_tot_g", "Rotten_and_diseased_grain",
                        "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr"))
r$defects_lab_share_r <- sdiv(r$defect_lab, r$Total_weight_of_maize_g)
r$defects_lab_share_r[cond(r$defects_lab_share_r > 1)] <- 1

stata_week <- function(d) pmin(floor((as.numeric(format(d, "%j")) - 1) / 7) + 1, 52)
for (s in 1:4) {
  r[[paste0("week_sale_", s)]] <- stata_week(r[[paste0("add5_sold_when_e_", s)]])
  ded_tot <- matrix(NA_real_, nrow(r), 20); wt <- matrix(NA_real_, nrow(r), 20); np <- matrix(NA_real_, nrow(r), 20)
  for (b in 1:20) {
    w <- r[[paste0("add4_weight_", b)]]
    dw <- r[[paste0("add5_ind_ded_weight", b, "_", s)]]
    has <- !is.na(dw)
    ded_tot[, b] <- ifelse(has, w - dw, NA)
    wt[, b] <- ifelse(has, w, NA)
    np[, b] <- sdiv(dw, w) * r[[paste0("add5_ppk_", s)]]
  }
  dt <- rowSums(ded_tot, na.rm = TRUE); wtt <- rowSums(wt, na.rm = TRUE)
  r[[paste0("deduct_totalshare100_", s)]] <- sdiv(dt, wtt) * 100
  m <- rowMeans(np, na.rm = TRUE); m[is.nan(m)] <- NA
  r[[paste0("net_priceavg_", s)]] <- m
  r[[paste0("price_", s)]] <- r[[paste0("add5_ppk_", s)]]
}

# Column 1: bag-level, all inspected bags (reshape long over 20 bags)
bags <- do.call(rbind, lapply(1:20, function(b) data.frame(
  hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, bagnum = b,
  defects = r[[paste0("defects_visual_tot_", b)]])))
bags <- bags[!is.na(bags$defects) & !is.na(bags$treatment), ]
m1 <- feols(defects ~ treatment | ea_code, data = bags, cluster = ~hhh_id, fixef.rm = "none")

# Column 2: lab sample, one bag per household; robust SE
d2 <- r[!is.na(r$defects_lab_share_r) & !is.na(r$treatment), ]
m2 <- feols(defects_lab_share_r ~ treatment | ea_code, data = d2, vcov = "hetero", fixef.rm = "none")

# Columns 3-5: sale-level (sales 2-4; sale 1 is the random bag sold to the research team)
sales <- do.call(rbind, lapply(1:4, function(s) data.frame(
  hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, salenum = s,
  price = r[[paste0("price_", s)]], week_sale = r[[paste0("week_sale_", s)]],
  deduct = r[[paste0("deduct_totalshare100_", s)]], net_price = r[[paste0("net_priceavg_", s)]])))
sales <- sales[!is.na(sales$price) & sales$salenum != 1, ]
m3 <- feols(price ~ treatment | ea_code + week_sale, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m4 <- feols(deduct ~ treatment | ea_code + week_sale, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m5 <- feols(net_price ~ treatment | ea_code + week_sale, data = sales, cluster = ~hhh_id, fixef.rm = "none")

#############################################################################
# TABLE 6 Panel A : Market access experiment (group 1 panel)
#############################################################################
g <- zap(read_dta(file.path(RAW, "panel_g1.dta")))
S <- g$survey_season
phone <- g$form_used == "Phone_Market_Survey_spring2020"
mkt20 <- g$form_used == "Market_Survey_spring2020"
id <- g$hhh_id

# acreage
g$acreage <- rt(g, c(q1(g, "plot_size_"), q2(g, "plot_size_")))
g$acreage[is.na(g$acreage) & cond(g$maize_tot_plotn == 0)] <- 0
g$acreage[S == 7 & phone] <- g$acres_tot[S == 7 & phone]
acre0 <- cond(g$acreage == 0)
acre_pos <- !is.na(g$acreage) & g$acreage != 0

# equipment, chemicals
g$equipment_cost_tot <- ifelse(S == 3, rt(g, q1(g, "equipment_cost_")), NA)
g$tot_chem_costs <- rt(g, q1(g, "tot_chem_costs_"))

# seeds, fertilizer, manure, booster
g$seeds_cost_tot <- ifelse(S >= 2, rt(g, q1(g, "seeds_cost_")), NA)
g$seeds_cost_tot[S == 7 & phone] <- g$seeds_cost[S == 7 & phone]
g$fert_cost_tot <- ifelse(S >= 2, rt(g, q1(g, "fert_cost_")), NA)
g$fert_cost_tot[S == 7 & phone] <- g$fert_cost[S == 7 & phone]
g$manure_cost_tot <- ifelse(S >= 2, rt(g, q1(g, "manure_cost_")), NA)
g$booster_cost_tot <- ifelse(S >= 2, rt(g, q1(g, "booster_cost_")), NA)
g$booster_cost_tot[S == 7 & phone] <- g$booster_cost[S == 7 & phone]
g$manure_cost_tot[is.na(g$manure_cost_tot) & acre_pos & (S == 4 | S == 6 | (S == 7 & mkt20))] <- 0

g$harvest_cost_tot <- ifelse(S == 2 | S == 3, rt(g, q1(g, "harvest_cost_")), NA)

# harvest and yield
g$harvest_kg_tot <- rt(g, q1(g, "harvest_kg_"))
sel <- cond(g$season_spring2020 == 1) & phone
g$harvest_kg_tot[sel] <- g$harvest_kg[sel]
g$yield <- sdiv(g$harvest_kg_tot, g$acreage)
sel <- id == 10247005 & g$season_spring2018 == 1
g$yield[sel] <- sdiv(g$harvest_kg_1, g$plot_size_1)[sel]
sel <- (id == 10165041 | id == 10231013) & S == 5
g$yield[sel] <- sdiv(g$harvest_kg_2, g$plot_size_2)[sel]

# post-harvest
for (v in c("storage_cost", "drying_cost", "otherph_cost")) g[[v]][acre0] <- NA
g$decobbing_cost_tot <- ifelse(S == 2, rt(g, q1(g, "decobbing_cost_")), NA)
g$decobbing_cost_tot[acre0] <- NA

# labour costs
for (a in c("prep", "plant", "weed", "spray", "harv")) {
  v <- paste0("labor_cost_", a, "_tot")
  g[[v]] <- ifelse(S != 1, rt(g, q1(g, paste0("lc_", a, "_costs_season"))), NA)
  g[[v]][is.na(g[[v]]) & acre_pos & S == 5] <- 0
}
g$labor_cost_ph[acre0] <- NA
g$labor_cost_store[is.na(g$labor_cost_store) & g$storage != "" & S >= 5] <- 0

g$expenses_labor_preharvest_ugx <- ifelse(S != 1 & S != 4 & !phone,
  rt(g, c("labor_cost_prep_tot", "labor_cost_plant_tot", "labor_cost_spray_tot", "labor_cost_weed_tot")), NA)
g$tot_lab_costs_preh_aggh_tot <- ifelse(S >= 4, rt(g, q1(g, "tot_lab_costs_")), NA)
sel <- S == 2 | S == 3
g$tot_lab_costs_preh_aggh_tot[sel] <- (g$expenses_labor_preharvest_ugx + g$labor_cost_harv_tot)[sel]

# labour hours
for (a in c("prep", "plant", "spray", "weed", "harv")) {
  v <- paste0(a, "_unpaid_lab_tothrs")
  g[[v]] <- ifelse(S >= 5, rt(g, q1(g, paste0("lh_", a, "_hours_season"))), NA)
}
g$spray_unpaid_lab_tothrs[is.na(g$spray_unpaid_lab_tothrs) & acre_pos & S == 5] <- 0
g$tot_lab_hours_preh_aggh_tot <- ifelse(S >= 5, rt(g, paste0(c("prep", "plant", "weed", "spray", "harv"), "_unpaid_lab_tothrs")), NA)

# hourly wage (modal daily wage / modal daily hours)
stata_mode <- function(x) {
  x <- x[!is.na(x)]; tb <- table(x); mx <- max(tb); md <- as.numeric(names(tb)[tb == mx])
  if (length(md) > 1) { message("mode tie: ", paste(md, collapse = ",")); return(NA_real_) }
  md
}
medc <- list(); medh <- list()
for (a in c("prep", "plant", "weed", "harv")) {
  dc <- list(); dh <- list()
  for (n in 1:6) {
    if (paste0("lc_", a, "_unit", n) %in% names(g))
      dc[[length(dc) + 1]] <- ifelse(g[[paste0("lc_", a, "_unit", n)]] == "days", g[[paste0("lc_", a, "_costs_unit", n)]], NA)
    if (paste0("lh_", a, "_hours_unit", n) %in% names(g))
      dh[[length(dh) + 1]] <- ifelse(g[[paste0("lh_", a, "_unit", n)]] == "days", g[[paste0("lh_", a, "_hours_unit", n)]], NA)
  }
  medc[[a]] <- rmedian(do.call(cbind, dc)); medh[[a]] <- rmedian(do.call(cbind, dh))
}
med_dailycost <- rmedian(do.call(cbind, medc)); med_dailyhours <- rmedian(do.call(cbind, medh))
hourlywage <- round(stata_mode(med_dailycost) / stata_mode(med_dailyhours))
message("hourly wage: ", hourlywage, " (daily wage ", stata_mode(med_dailycost), ", daily hours ", stata_mode(med_dailyhours), ")")
g$preh_unpaid_lab_aggh_sh <- g$tot_lab_hours_preh_aggh_tot * hourlywage

# post-harvest activities
for (a in c("decob", "winnow", "sort", "bag")) {
  dd <- ifelse(g[[a]] != "" & S >= 5, as.numeric(g[[a]] == "yes"), NA)
  fill <- !is.na(dd) & S >= 5
  for (v in c(paste0("lh_", a, "_hours"), paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_other_costs")))
    g[[v]][is.na(g[[v]]) & fill] <- 0
  g[[paste0("lh_", a, "_hours_sh")]] <- ifelse(S >= 5, g[[paste0("lh_", a, "_hours")]] * 833, NA)
  lm <- ifelse(S >= 5, g[[paste0("lc_", a, "_labmaize_costs")]] * g[[paste0("lc_", a, "_price")]], NA)
  lm[is.na(lm) & fill] <- 0
  g[[paste0("lc_", a, "_lmtot_costs")]] <- lm
}
sel <- id == 10247077 & S == 7; g$lc_decob_lmtot_costs[sel] <- g$lc_decob_labmaize_costs[sel]
sel <- id == 10247013 & S == 7; g$lc_bag_lmtot_costs[sel] <- g$lc_bag_labmaize_costs[sel]
for (a in c("decob", "winnow", "sort", "bag"))
  g[[paste0(a, "_cost_tot")]] <- rt(g, paste0("lc_", a, c("_labour_costs", "_lmtot_costs", "_other_costs")))

# sales
g$sold_kg_tot <- rt(g, q1(g, "sold_kg_p_"))
g$sold_kg_tot[S == 7 & phone] <- g$sold_kg[S == 7 & phone]
g$sold_kg_tot[id == 10249047 & S == 1] <- 0
g$sold_kg_tot[id == 10328006 & S == 1] <- 0
g$sold_kg_tot[id == 10165056 & S == 2 & g$survey_round == 1] <- 0
g$sold_kg_tot[id == 10235011 & S == 2 & g$survey_round == 1] <- 0
hk <- nz(g$harvest_kg_tot)
g$sold_kg_tot[hk & is.na(g$sold_kg_tot) & S == 2 & g$survey_round == 2] <- 0
g$sold_kg_tot[hk & is.na(g$sold_kg_tot) & S == 3] <- 0
g$sold_kg_tot[hk & is.na(g$sold_kg_tot) & S == 5 & g$sold_crop == "no"] <- 0
g$sold_kg_tot[hk & is.na(g$sold_kg_tot) & S == 6 & g$sold_crop == "no"] <- 0
g$sold_kg_tot[hk & is.na(g$sold_kg_tot) & S == 7 & g$sold_crop == "no" & mkt20] <- 0
g$sold_kg_tot[id == 10235035 & cond(g$season_spring2020 == 1)] <- NA
ids4 <- c(10078042, 10181008, 10181009, 10231001, 10247021, 10326064, 10328005, 10328014, 10328034, 10350040)
g$sold_crop[id %in% ids4 & S == 4] <- "no"; g$sold_kg_tot[id %in% ids4 & S == 4] <- 0
ids5 <- c(10219013, 10231002, 10354079)
g$sold_crop[id %in% ids5 & S == 5] <- "no"; g$sold_kg_tot[id %in% ids5 & S == 5] <- 0

# transport to buyer
for (k in c(1, 2, 3, 5)) {
  v <- paste0("sale_transport_cost_", k)
  g[[v]][g[[paste0("sale_transport_yn_", k)]] == "no" & S >= 3] <- 0
}
g$sale_transport_cost_tot <- ifelse(S >= 3, rt(g, q1(g, "sale_transport_cost_")), NA)

# revenue, price, harvest value
g$rev_tot <- rt(g, c(grep("^tot_rev_combined_._.$", names(g), value = TRUE), q1(g, "tot_rev_combined_")))
g$rev_tot[phone] <- g$tot_rev_told_tot[phone]
g$rev_tot[hk & is.na(g$rev_tot) & cond(g$sold_kg_tot == 0)] <- 0
g$price_ugx <- sdiv(g$rev_tot, g$sold_kg_tot)
g <- g %>% group_by(ea_code, survey_season) %>%
  mutate(price_vm = { m <- mean(price_ugx, na.rm = TRUE); if (is.nan(m)) NA_real_ else m }) %>% ungroup() %>% as.data.frame()
g$remainder <- g$harvest_kg_tot - g$sold_kg_tot
g$harvest_value_ugx <- ifelse(nz(g$remainder) & g$remainder >= 0, g$rev_tot + g$remainder * g$price_vm, NA)
sel <- nz(g$remainder) & g$remainder < 0
g$harvest_value_ugx[sel] <- (g$harvest_kg_tot * g$price_ugx)[sel]
sel <- id == 10249026 & S == 3
g$harvest_value_ugx[sel] <- (g$harvest_kg_tot * g$price_vm)[sel]

# expenses by season
ex <- list(
  `2` = c("seeds_cost_tot", "fert_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
          "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "harvest_cost_tot", "decobbing_cost_tot",
          "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "cost_transportpre", "cost_transportpost"),
  `3` = c("seeds_cost_tot", "fert_cost_tot", "manure_cost_tot", "booster_cost_tot", "equipment_cost_tot",
          "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "tot_chem_costs", "harvest_cost_tot",
          "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "labor_cost_dry", "labor_cost_store",
          "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot"),
  `4` = c("fert_cost_tot", "tot_chem_costs", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot",
          "tot_lab_costs_preh_aggh_tot", "drying_cost", "storage_cost", "labor_cost_store", "otherph_cost",
          "labor_cost_ph", "tot_transport_cost", "sale_transport_cost_tot"))
post_list <- c("fert_cost_tot", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
               "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "drying_cost", "storage_cost",
               "labor_cost_store", "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot",
               "decob_cost_tot", "sort_cost_tot", "winnow_cost_tot", "bag_cost_tot")
hrs_list <- c(post_list, "preh_unpaid_lab_aggh_sh", "lh_decob_hours_sh", "lh_sort_hours_sh",
              "lh_winnow_hours_sh", "lh_bag_hours_sh")
season_dummy <- c(`2` = "season_fall2017", `3` = "season_spring2018", `4` = "season_fall2018",
                  `5` = "season_spring2019", `6` = "season_fall2019", `7` = "season_spring2020")
g$expenses_ugx <- NA_real_; g$expenses_hours_ugx <- NA_real_
for (s in 2:7) {
  cols <- if (s <= 4) ex[[as.character(s)]] else post_list
  ok <- S == s; if (s == 7) ok <- ok & mkt20
  val <- ifelse(ok, rt(g, cols), NA)
  dsel <- cond(g[[season_dummy[as.character(s)]]] == 1)
  g$expenses_ugx[dsel] <- val[dsel]
  if (s >= 5) {
    hv <- ifelse(ok, rt(g, hrs_list), NA)
    g$expenses_hours_ugx[dsel] <- hv[dsel]
  } else if (s <= 3) {
    g$expenses_hours_ugx[dsel] <- val[dsel]
  }
}
g$expenses_ugx[cond(g$season_spring2020 == 1) & phone] <- NA
g$surplus_ugx <- g$harvest_value_ugx - g$expenses_ugx
g$surplus_hrs_ugx <- g$harvest_value_ugx - g$expenses_hours_ugx

fx <- c(`1` = 3575, `2` = 3601, `3` = 3626, `4` = 3758, `5` = 3670, `6` = 3685, `7` = 3681, `8` = 3685)
rate <- fx[as.character(S)]
for (v in c("price", "harvest_value", "expenses", "surplus", "surplus_hrs"))
  g[[v]] <- g[[paste0(v, "_ugx")]] / rate

# ANCOVA (table6.do, group 1): pretreatment value = last baseline (spring 2018) mean, else mean over baseline seasons
hh_mean <- function(x, sel, id) {
  m <- tapply(ifelse(sel, x, NA), id, function(z) { z <- z[!is.na(z)]; if (length(z)) mean(z) else NA_real_ })
  unname(m[as.character(id)])
}
anc <- function(var) {
  p3 <- hh_mean(g[[var]], cond(g$season_spring2018 == 1) & g$group == 1, g$hhh_id)
  p <- hh_mean(g[[var]], cond(g$season_ante == 1) & g$group == 1, g$hhh_id)
  p3[is.na(p3)] <- p[is.na(p3)]
  d <- g[g$group == 1 & cond(g$season_post == 1), ]
  d$y <- d[[var]]; d$p3 <- p3[g$group == 1 & cond(g$season_post == 1)]
  d <- d[!is.na(d$y) & !is.na(d$p3) & !is.na(d$buy_treatment), ]
  feols(y ~ buy_treatment + p3 + factor(survey_season), data = d, cluster = ~ea_code)
}
outs <- c("price", "acreage", "harvest_kg_tot", "yield", "harvest_value", "expenses", "surplus", "surplus_hrs")
t6 <- lapply(outs, anc); names(t6) <- outs
for (v in outs) message(sprintf("T6 %-15s b=%9.4f se=%8.4f N=%d", v, coef(t6[[v]])["buy_treatment"],
                                se(t6[[v]])["buy_treatment"], nobs(t6[[v]])))
for (m in list(m1, m2, m3, m4, m5)) message(sprintf("T2 b=%8.4f se=%8.4f N=%d", coef(m)["treatment"], se(m)["treatment"], nobs(m)))

cat(sprintf("RESULT:treatment_defects_visual_table2_col1=%.6f\n", coef(m1)["treatment"]))
cat(sprintf("RESULT:treatment_defects_lab_table2_col2=%.6f\n", coef(m2)["treatment"]))
cat(sprintf("RESULT:treatment_price_table2_col3=%.6f\n", coef(m3)["treatment"]))
cat(sprintf("RESULT:treatment_deductions_table2_col4=%.6f\n", coef(m4)["treatment"]))
cat(sprintf("RESULT:treatment_net_price_table2_col5=%.6f\n", coef(m5)["treatment"]))
cat(sprintf("RESULT:n_obs_table2_col1_bags=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table2_cols3_5_sales=%d\n", nobs(m3)))
cat(sprintf("RESULT:market_access_price_table6_panelA_col1=%.6f\n", coef(t6$price)["buy_treatment"]))
cat(sprintf("RESULT:market_access_yield_table6_panelA_col4=%.6f\n", coef(t6$yield)["buy_treatment"]))
cat(sprintf("RESULT:market_access_harvest_value_table6_panelA_col5=%.6f\n", coef(t6$harvest_value)["buy_treatment"]))
cat(sprintf("RESULT:market_access_profit_monetary_table6_panelA_col7=%.6f\n", coef(t6$surplus)["buy_treatment"]))
cat(sprintf("RESULT:market_access_profit_incl_own_hours_table6_panelA_col8=%.6f\n", coef(t6$surplus_hrs)["buy_treatment"]))
cat(sprintf("RESULT:n_obs_table6_panelA_cols3_5=%d\n", nobs(t6$harvest_value)))
