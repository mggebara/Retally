# Independent reproduction: Bold, Ghisolfi, Nsonzi, Svensson (AER 2022)
# "Market Access and Quality Upgrading" -- Table 2 (returns to quality) and Table 6 panel A (market access)
suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"

############################################################
# Table 2: returns to quality experiment
############################################################
r <- zap_labels(read_dta(paste0(D, "anonym_returns_data.dta")))
r$ea_code <- as.character(r$ea_code)

# ---- (1) visually verifiable defects, bag level (ten defect types; dead/live insects count as one type)
bags <- list()
for (b in 1:20) {
  g <- function(v) r[[paste0("add4_", v, "_", b)]]
  m <- cbind(g("dirty"), g("cobs"), g("stones"), g("dust"), g("broken"), g("immature"), g("damage"), g("rot"),
             pmax(g("insect"), g("insect_live"), na.rm = TRUE), g("mould"))
  anyobs <- rowSums(!is.na(cbind(m, g("insect"), g("insect_live")))) > 0
  bags[[b]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, bag = b,
                          defects = rowSums(m, na.rm = TRUE), keep = anyobs)
}
bags <- bind_rows(bags) %>% filter(keep)
m1 <- feols(defects ~ treatment | ea_code, data = bags, cluster = ~hhh_id)

# ---- (2) lab-verified defects: grams of defects and waste per 200 g sample, as a share
lab <- r %>% mutate(def_g = rowSums(cbind(Foreign_matter_tot_g, Inorganic_matter_tot_g, Broken_grains_tot_g,
                                          Pest_damaged_grains_tot_g, Rotten_and_diseased_grain,
                                          Discoloured_grains_tot_g, Immature_or_shrivelled_gr), na.rm = TRUE),
                    lab_share = def_g / Total_weight_of_maize_g) %>% filter(!is.na(Total_weight_of_maize_g))
m2 <- feols(lab_share ~ treatment | ea_code, data = lab, vcov = "hetero")

# ---- (3)-(5) sales. Repeat 1 of the sales module is the bag bought by the research team (lab bag);
# repeats 2-4 are the household's sales to buyers.
stata_week <- function(d) pmin(floor((as.integer(format(d, "%j")) - 1) / 7) + 1, 52)
sales <- list()
for (k in 2:4) {
  w  <- sapply(1:20, function(j) r[[paste0("add5_ind_weight", j, "_", k)]])
  dw <- sapply(1:20, function(j) r[[paste0("add5_ind_ded_weight", j, "_", k)]])
  mw <- sapply(1:20, function(j) r[[paste0("add4_weight_", j)]])
  sold <- !is.na(w)
  y <- rowSums(ifelse(sold, mw, NA), na.rm = TRUE)      # enumerator-measured weight of bags sold
  z <- rowSums(ifelse(sold, dw, NA), na.rm = TRUE)      # agreed (buyer-stated, net of deductions) weight
  sales[[k]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, sale = k,
                           has = rowSums(sold) > 0, price = r[[paste0("add5_ppk_", k)]],
                           date = as.Date(r[[paste0("add5_sold_when_e_", k)]]), y = y, z = z)
}
sales <- bind_rows(sales) %>% filter(has) %>%
  mutate(deduction = 100 * (y - z) / y, net_price = price * z / y, week = stata_week(date))
m3 <- feols(price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)
m4 <- feols(deduction ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)
m5 <- feols(net_price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)

cat("Table 2 control means: defects", mean(bags$defects[bags$treatment == 0]), " lab", mean(lab$lab_share[lab$treatment == 0]),
    " price", mean(sales$price[sales$treatment == 0]), " deduction", mean(sales$deduction[sales$treatment == 0]),
    " net price", mean(sales$net_price[sales$treatment == 0]), "\n")
for (m in list(m1, m2, m3, m4, m5)) cat(sprintf("  coef %.4f se %.4f N %d R2 %.3f\n", coef(m)["treatment"], se(m)["treatment"], nobs(m), r2(m, "r2")))

############################################################
# Table 6 panel A: market access experiment (ANCOVA)
############################################################
g <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
g$ea_code <- as.character(g$ea_code)
rsum <- function(p) { v <- grep(p, names(g), value = TRUE); x <- as.matrix(g[, v, drop = FALSE])
  list(s = rowSums(x, na.rm = TRUE), n = rowSums(!is.na(x))) }

# UGX per USD, annual averages (assumption; the paper does not state the rate used)
fx <- c(`1` = 3611, `2` = 3611, `3` = 3727, `4` = 3727, `5` = 3704, `6` = 3704, `7` = 3718)
g$fx <- fx[as.character(g$survey_season)]

# acreage and harvest
ps <- rsum("^plot_size_[0-9]+$"); hk <- rsum("^harvest_kg_[0-9]+$")
g$acreage <- ifelse(!is.na(g$acres_tot), g$acres_tot, ps$s)
g$harvest <- ifelse(g$survey_season >= 4, g$harvest_kg, ifelse(hk$n > 0, hk$s, NA))
g$yield <- ifelse(g$acreage > 0, g$harvest / g$acreage, NA)

# prices from transaction-level seller data
s <- zap_labels(read_dta(paste0(D, "seller_data.dta"))) %>% filter(price > 0, sold_kg_p_ > 0)
hp <- s %>% group_by(hhh_id, survey_season) %>%
  summarise(price_ugx = sum(price * sold_kg_p_) / sum(sold_kg_p_), .groups = "drop")
g <- g %>% left_join(hp, by = c("hhh_id", "survey_season"))
vp <- hp %>% left_join(distinct(g, hhh_id, ea_code), by = "hhh_id") %>% group_by(ea_code, survey_season) %>%
  summarise(vprice = mean(price_ugx), .groups = "drop")
sp <- hp %>% group_by(survey_season) %>% summarise(sprice = mean(price_ugx), .groups = "drop")
g <- g %>% left_join(vp, by = c("ea_code", "survey_season")) %>% left_join(sp, by = "survey_season") %>%
  mutate(cprice = ifelse(is.na(vprice), sprice, vprice))
g$price_usd <- g$price_ugx / g$fx
g$harvest_value <- g$harvest * g$cprice / g$fx

# monetary expenses (inputs, equipment, transport, hired labor), in UGX
comp <- c("^seeds_cost_[0-9]+$", "^fert_cost_[0-9]+$", "^booster_cost_[0-9]+$", "^manure_cost_[0-9]+$", "^tot_chem_costs_[0-9]+$",
          "^tot_lab_costs_[0-9]+$", "^equipment_cost_[0-9]+$", "^harvest_cost_[0-9]+$", "^decobbing_cost_[0-9]+$",
          "^labor_cost_ph$", "^otherph_cost$", "^drying_cost$", "^storage_cost$", "^tot_transport_cost$",
          "^seeds_cost$", "^fert_cost$", "^booster_cost$")
exp_ugx <- Reduce(`+`, lapply(comp, function(p) rsum(p)$s))
# transport before/after harvest is recorded either as a total or split in pre/post
tr_split <- rsum("^cost_transport(pre|post)$")$s
exp_ugx <- exp_ugx + ifelse(rsum("^tot_transport_cost$")$n == 0, tr_split, 0)
plot_inputs_obs <- rsum("^(seeds_cost_[0-9]+|seeds_cost)$")$n > 0
g$expenses <- ifelse(plot_inputs_obs & g$survey_season >= 2, exp_ugx / g$fx, NA)
g$profit <- g$harvest_value - g$expenses

# own/family labor hours valued at the hourly market wage for hired labor
fam <- rsum("^lh_(prep|plant|weed|spray|harv)_hours_season[0-9]+$"); famph <- rsum("^lh_(decob|winnow|sort|bag)_hours$")
g$fam_hours <- ifelse(fam$n > 0, fam$s + famph$s, NA)
cpd <- c(); hpd <- c()
for (t in c("prep", "plant", "weed", "spray", "harv")) for (j in 1:6) {
  u <- g[[paste0("lc_", t, "_unit", j)]]; c1 <- g[[paste0("lc_", t, "_costs_unit", j)]]
  if (!is.null(u)) cpd <- c(cpd, c1[!is.na(u) & u == "days" & !is.na(c1) & c1 > 0])
  u <- g[[paste0("lh_", t, "_unit", j)]]; h1 <- g[[paste0("lh_", t, "_hours_unit", j)]]
  if (!is.null(u)) hpd <- c(hpd, h1[!is.na(u) & u == "days" & !is.na(h1) & h1 > 0])
}
wage_ugx_hr <- median(cpd) / median(hpd)
cat("hourly wage (UGX):", wage_ugx_hr, " from day rate", median(cpd), "and hours/day", median(hpd), "\n")
g$profit_own <- ifelse(g$survey_season >= 5, g$profit - wage_ugx_hr * g$fam_hours / g$fx, NA)

# ANCOVA: follow-up seasons 4-7, outcome on treatment, season dummies and household's pre-treatment mean
pre_mean <- function(v) g %>% filter(survey_season <= 3) %>% group_by(hhh_id) %>%
  summarise(pre = mean(.data[[v]][is.finite(.data[[v]])]), .groups = "drop")
post <- g %>% filter(survey_season >= 4)
ancova <- function(v, prevar = v) {
  d <- post %>% left_join(pre_mean(prevar), by = "hhh_id") %>% filter(is.finite(.data[[v]]), is.finite(pre))
  m <- feols(as.formula(paste(v, "~ buy_treatment + pre | survey_season")), data = d, cluster = ~ea_code)
  cat(sprintf("  %-14s coef %9.4f se %8.4f N %4d R2 %.2f control mean %.3f\n", v, coef(m)["buy_treatment"], se(m)["buy_treatment"],
              nobs(m), r2(m, "r2"), mean(d[[v]][d$buy_treatment == 0])))
  m
}
cat("Table 6 panel A\n")
t6 <- list(price = ancova("price_usd"), acreage = ancova("acreage"), harvest = ancova("harvest"), yield = ancova("yield"),
           hv = ancova("harvest_value"), exp = ancova("expenses"), profit = ancova("profit"),
           profit_own = ancova("profit_own", "profit"))

cat("DEVIATION: UGX/USD exchange rates assumed (annual averages 3611/3727/3704/3718 for 2017-2020); not stated in the paper\n")
cat("DEVIATION: hourly wage = median hired day rate / median family hours per day; profit incl. own hours uses pre-treatment monetary profit as the lagged control (no baseline family-hour data)\n")
cat("DEVIATION: community price = village-season mean of household average sale prices (seller_data); expenses aggregated from survey cost items as described\n")

cat(sprintf("RESULT:treatment_defects_visual_table2_col1=%.6f\n", coef(m1)["treatment"]))
cat(sprintf("RESULT:treatment_defects_lab_table2_col2=%.6f\n", coef(m2)["treatment"]))
cat(sprintf("RESULT:treatment_price_table2_col3=%.6f\n", coef(m3)["treatment"]))
cat(sprintf("RESULT:treatment_deductions_table2_col4=%.6f\n", coef(m4)["treatment"]))
cat(sprintf("RESULT:treatment_net_price_table2_col5=%.6f\n", coef(m5)["treatment"]))
cat(sprintf("RESULT:n_obs_table2_col1_bags=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table2_cols3_5_sales=%d\n", nobs(m3)))
cat(sprintf("RESULT:market_access_price_table6_panelA_col1=%.6f\n", coef(t6$price)["buy_treatment"]))
cat(sprintf("RESULT:market_access_yield_table6_panelA_col4=%.6f\n", coef(t6$yield)["buy_treatment"]))
cat(sprintf("RESULT:market_access_harvest_value_table6_panelA_col5=%.6f\n", coef(t6$hv)["buy_treatment"]))
cat(sprintf("RESULT:market_access_profit_monetary_table6_panelA_col7=%.6f\n", coef(t6$profit)["buy_treatment"]))
cat(sprintf("RESULT:market_access_profit_incl_own_hours_table6_panelA_col8=%.6f\n", coef(t6$profit_own)["buy_treatment"]))
cat(sprintf("RESULT:n_obs_table6_panelA_cols3_5=%d\n", nobs(t6$harvest)))
