# Independent, blind reproduction of Bold, Ghisolfi, Nsonzi & Svensson (2022, AER)
# Table 2 (returns to quality experiment) and Table 6 panel A (market access experiment).
# Built from the paper's text and the raw .dta files only.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
EMIT_RESULTS <- TRUE   # FALSE in the exploratory dry run
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading/data/raw/"
options(width = 200)
out <- function(name, val) {
  if (EMIT_RESULTS) cat(sprintf("RESULT:%s=%.10g\n", name, val)) else cat(sprintf("DIAG:%s=%.10g\n", name, val))
}
rs <- function(m) rowSums(m, na.rm = TRUE)
cols <- function(d, pat) { v <- grep(pat, names(d), value = TRUE); as.matrix(d[, v, drop = FALSE]) }

########################################################################
# Part 1: Returns to quality experiment (Table 2)
########################################################################
r <- zap_labels(read_dta(paste0(D, "anonym_returns_data.dta")))
r$village <- r$ea_code

## (1) visually verifiable defects, unit = bag (all bags inspected/weighed by enumerators)
## ten defect types: dirty, cobs, stones, dust, insects (live or dead), broken, immature,
## insect/vermin damaged, rotten/diseased, mould.  "yes" == 1; anything else counts as absent.
bags <- list()
for (k in 1:20) {
  w <- r[[paste0("add4_weight_", k)]]
  yes <- function(v) { x <- r[[paste0("add4_", v, "_", k)]]; !is.na(x) & x == 1 }
  ndef <- yes("dirty") + yes("cobs") + yes("stones") + yes("dust") +
    (yes("insect") | yes("insect_live")) + yes("broken") + yes("immature") +
    yes("damage") + yes("rot") + yes("mould")
  bags[[k]] <- data.frame(hhh_id = r$hhh_id, village = r$village, treatment = r$treatment,
                          bag = k, weight = w, ndef = ndef)[!is.na(w), ]
}
bags <- bind_rows(bags)
cat("bags inspected:", nrow(bags), " control bags:", sum(bags$treatment == 0),
    " mean defects control:", mean(bags$ndef[bags$treatment == 0]),
    " treat:", mean(bags$ndef[bags$treatment == 1]), "\n")
m1 <- feols(ndef ~ treatment | village, data = bags, cluster = ~hhh_id)
print(summary(m1))

## (2) lab-verified defects: share of the ~200 g sample that is non-grain matter or defective grain
lab <- r %>% mutate(
  defects_g = rs(cbind(Foreign_matter_tot_g, Inorganic_matter_tot_g, Broken_grains_tot_g,
                       Pest_damaged_grains_tot_g, Rotten_and_diseased_grain,
                       Discoloured_grains_tot_g, Immature_or_shrivelled_gr)),
  lab_share = ifelse(is.na(Total_weight_of_maize_g), NA, defects_g / Total_weight_of_maize_g)) %>%
  filter(!is.na(lab_share))
cat("lab sample n:", nrow(lab), " control mean share:", mean(lab$lab_share[lab$treatment == 0]), "\n")
m2 <- feols(lab_share ~ treatment | village, data = lab, vcov = "hetero")
print(summary(m2))

## (3)-(5) sales reported at the final visit.
## add5 sale 1 is the purchase of the random lab bag by the research team (its bag weight equals the
## enumerator weight of add4_random_bag); sales 2-4 are the sales to traders.
chk <- sapply(seq_len(nrow(r)), function(i) {
  b <- which(!is.na(unlist(r[i, paste0("add5_ind_weight", 1:20, "_1")])))
  if (length(b) == 0) NA else all(b == r$add4_random_bag[i])
})
cat("sale-1 bag == random lab bag:", table(chk, useNA = "ifany"), "\n")
sales <- list()
for (s in 2:4) {
  y <- z <- yb <- rep(0, nrow(r)); nb <- rep(0, nrow(r))
  for (k in 1:20) {
    iw <- r[[paste0("add5_ind_weight", k, "_", s)]]
    dw <- r[[paste0("add5_ind_ded_weight", k, "_", s)]]
    ew <- r[[paste0("add4_weight_", k)]]
    ok <- !is.na(iw) & !is.na(dw)
    meas <- ifelse(is.na(ew), iw, ew)              # weight measured by the enumerators
    y[ok] <- y[ok] + meas[ok]; z[ok] <- z[ok] + dw[ok]; yb[ok] <- yb[ok] + iw[ok]; nb[ok] <- nb[ok] + 1
  }
  dt <- as.Date(r[[paste0("add5_sold_when_e_", s)]])
  sales[[s]] <- data.frame(hhh_id = r$hhh_id, village = r$village, treatment = r$treatment, sale = s,
                           price = r[[paste0("add5_ppk_", s)]], date = dt,
                           y = ifelse(nb > 0, y, NA), z = ifelse(nb > 0, z, NA),
                           ybuyer = ifelse(nb > 0, yb, NA), nbags = nb)
}
sales <- bind_rows(sales) %>% filter(!is.na(price))
sales <- sales %>% mutate(
  week = as.integer(floor((as.integer(format(date, "%j")) - 1) / 7) + 1),   # Stata week-of-year
  deduction = 100 * (y - z) / y,
  net_price = price * z / y)
cat("sales:", nrow(sales), " households:", length(unique(sales$hhh_id)),
    " missing date:", sum(is.na(sales$date)), " missing bag weights:", sum(is.na(sales$y)), "\n")
cat("control means: price", mean(sales$price[sales$treatment == 0]),
    " deduction", mean(sales$deduction[sales$treatment == 0], na.rm = TRUE),
    " net price", mean(sales$net_price[sales$treatment == 0], na.rm = TRUE),
    " deduction (buyer-scale part)", mean(100 * (sales$ybuyer - sales$z) / sales$ybuyer, na.rm = TRUE), "\n")
m3 <- feols(price ~ treatment | village + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m4 <- feols(deduction ~ treatment | village + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m5 <- feols(net_price ~ treatment | village + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
print(etable(m3, m4, m5))

########################################################################
# Part 2: Market access experiment (Table 6, panel A)
########################################################################
UGX_PER_USD <- 3700   # approximate average 2017-2020 exchange rate (no rate in the data)
g <- zap_labels(read_dta(paste0(D, "panel_g1.dta")))
s <- zap_labels(read_dta(paste0(D, "seller_data.dta")))
g$village <- g$ea_code
g$phone <- g$form_used == "Phone_Market_Survey_spring2020"

## harvest (kg) and acreage
plot_h <- cols(g, "^harvest_kg_[0-9]+$"); plot_a <- cols(g, "^plot_size_[0-9]+$")
g$harvest <- ifelse(!is.na(g$harvest_kg), g$harvest_kg,
                    ifelse(rowSums(!is.na(plot_h)) > 0, rs(plot_h), NA))
g$acres <- ifelse(!is.na(g$acres_tot), g$acres_tot,
                  ifelse(rowSums(!is.na(plot_a)) > 0, rs(plot_a), NA))
g$yield <- ifelse(!is.na(g$acres) & g$acres > 0, g$harvest / g$acres, NA)

## sales and prices (sale-level data)
sv <- s %>% filter(price > 0, sold_kg_p_ > 0)
hp <- sv %>% group_by(hhh_id, survey_season) %>%
  summarise(rev = sum(price * sold_kg_p_), sold = sum(sold_kg_p_), .groups = "drop") %>%
  mutate(avg_price = rev / sold)
## community-specific market price: mean local-market price (excluding the quality buyer, code 555)
## in the village and season; season mean where the village has no sale
cp <- sv %>% filter(is.na(name) | name != 555) %>% group_by(ea_code, survey_season) %>%
  summarise(cprice = sum(price * sold_kg_p_) / sum(sold_kg_p_), .groups = "drop")
sp <- sv %>% filter(is.na(name) | name != 555) %>% group_by(survey_season) %>%
  summarise(sprice = sum(price * sold_kg_p_) / sum(sold_kg_p_), .groups = "drop")
g <- g %>% left_join(hp, by = c("hhh_id", "survey_season")) %>%
  left_join(cp, by = c("ea_code", "survey_season")) %>% left_join(sp, by = "survey_season") %>%
  mutate(cprice = ifelse(is.na(cprice), sprice, cprice),
         rev = ifelse(is.na(rev), 0, rev), sold = ifelse(is.na(sold), 0, sold),
         harvest_value = ifelse(is.na(harvest), NA, rev + pmax(harvest - sold, 0) * cprice))

## monetary expenses: inputs, equipment, transport and hired labour (plot module required;
## hired labour not collected in season 1, phone interviews in season 7 lack the module)
module <- !is.na(g$seeds_types_1) & g$seeds_types_1 != "" & !g$phone & g$survey_season >= 2
inputs <- rs(cols(g, "^seeds_cost_[0-9]+$")) + rs(cols(g, "^fert_cost_[0-9]+$")) +
  rs(cols(g, "^booster_cost_[0-9]+$")) + rs(cols(g, "^manure_cost_[0-9]+$")) +
  rs(cols(g, "^tot_chem_costs_[0-9]+$"))
equip <- rs(cols(g, "^equipment_cost_[0-9]+$")) + rs(cols(g, "^harvest_cost_[0-9]+$")) +
  rs(cols(g, "^decobbing_cost_[0-9]+$")) + rs(cbind(g$drying_cost, g$storage_cost, g$otherph_cost))
hired <- rs(cols(g, "^tot_lab_costs_[0-9]+$")) + rs(cbind(g$labor_cost_ph))
transport <- ifelse(!is.na(g$tot_transport_cost), g$tot_transport_cost,
                    rs(cbind(g$cost_transportpre, g$cost_transportpost)))
g$expenses <- ifelse(module, inputs + equip + hired + transport, NA)
g$profit <- g$harvest_value - g$expenses

## own / family labour hours (collected from season 5 on together with post-harvest hours)
own_h <- rs(cols(g, "^lh_(prep|plant|weed|spray|harv)_hours_season[0-9]+$")) +
  rs(cbind(g$lh_decob_hours, g$lh_winnow_hours, g$lh_sort_hours, g$lh_bag_hours))
has_h <- module & !is.na(g$lh_prep_hours_season1) & !is.na(g$decob) & g$decob != ""
## market wage per hour: median daily wage paid to hired workers / median length of a working day
wd <- c(); hd <- c()
for (a in c("prep", "plant", "weed", "spray", "harv")) {
  u <- g[[paste0("lc_", a, "_unit1")]]; cc <- g[[paste0("lc_", a, "_costs_unit1")]]
  wd <- c(wd, cc[!is.na(u) & u == "days" & !is.na(cc) & cc > 0])
  u <- g[[paste0("lh_", a, "_unit1")]]; hh <- g[[paste0("lh_", a, "_hours_unit1")]]
  hd <- c(hd, hh[!is.na(u) & u == "days" & !is.na(hh) & hh > 0])
}
wage_hr <- median(wd) / median(hd)
cat("hourly wage (UGX):", wage_hr, " = USD", wage_hr / UGX_PER_USD, "\n")
g$own_hours <- ifelse(has_h, own_h, NA)
g$profit_own <- g$profit - wage_hr * g$own_hours

## to US dollars
g <- g %>% mutate(price_usd = avg_price / UGX_PER_USD, hv_usd = harvest_value / UGX_PER_USD,
                  exp_usd = expenses / UGX_PER_USD, profit_usd = profit / UGX_PER_USD,
                  profit_own_usd = profit_own / UGX_PER_USD)

## ANCOVA: follow-up seasons 4-7; outcome on treatment, season dummies and the household's
## pretreatment (mean over baseline seasons 1-3) value of the outcome; missing pretreatment values
## set to zero with an indicator.  SEs clustered by village.
ancova <- function(v) {
  pre <- g %>% filter(survey_season <= 3) %>% group_by(hhh_id) %>%
    summarise(pre = mean(.data[[v]], na.rm = TRUE), .groups = "drop") %>%
    mutate(pre = ifelse(is.nan(pre), NA, pre))
  d <- g %>% filter(survey_season >= 4, !is.na(.data[[v]])) %>% left_join(pre, by = "hhh_id") %>%
    mutate(pre_miss = as.integer(is.na(pre)), pre = ifelse(is.na(pre), 0, pre), y = .data[[v]])
  f <- if (length(unique(d$pre_miss)) > 1) y ~ buy_treatment + pre + pre_miss | survey_season
       else if (all(d$pre_miss == 1)) y ~ buy_treatment | survey_season
       else y ~ buy_treatment + pre | survey_season
  m <- feols(f, data = d, cluster = ~village)
  cat(sprintf("%-15s N=%d  coef=%.4f  se=%.4f  p=%.3f  control mean=%.3f  pre missing=%d\n", v, nobs(m),
              coef(m)["buy_treatment"], se(m)["buy_treatment"], pvalue(m)["buy_treatment"],
              mean(d$y[d$buy_treatment == 0]), sum(d$pre_miss)))
  m
}
t6 <- lapply(c(price = "price_usd", acres = "acres", harvest = "harvest", yield = "yield",
               hv = "hv_usd", exp = "exp_usd", profit = "profit_usd", profit_own = "profit_own_usd"), ancova)

########################################################################
out("treatment_defects_visual_table2_col1", coef(m1)["treatment"])
out("treatment_defects_lab_table2_col2", coef(m2)["treatment"])
out("treatment_price_table2_col3", coef(m3)["treatment"])
out("treatment_deductions_table2_col4", coef(m4)["treatment"])
out("treatment_net_price_table2_col5", coef(m5)["treatment"])
out("n_obs_table2_col1_bags", nobs(m1))
out("n_obs_table2_cols3_5_sales", nobs(m3))
out("market_access_price_table6_panelA_col1", coef(t6$price)["buy_treatment"])
out("market_access_yield_table6_panelA_col4", coef(t6$yield)["buy_treatment"])
out("market_access_harvest_value_table6_panelA_col5", coef(t6$hv)["buy_treatment"])
out("market_access_profit_monetary_table6_panelA_col7", coef(t6$profit)["buy_treatment"])
out("market_access_profit_incl_own_hours_table6_panelA_col8", coef(t6$profit_own)["buy_treatment"])
out("n_obs_table6_panelA_cols3_5", nobs(t6$harvest))
