# Independent, blind reproduction: Bold, Ghisolfi, Nsonzi & Svensson (2022, AER)
# "Market Access and Quality Upgrading: Evidence from Four Field Experiments"
# Table 2 (returns-to-quality experiment) and Table 6 panel A (market access ANCOVA),
# reconstructed from the paper text and the raw data files only.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw/"
plain <- function(d) as.data.frame(lapply(d, function(x) if (inherits(x, "Date")) as.numeric(x) else as.vector(zap_labels(x))),
                                   stringsAsFactors = FALSE)
rs <- function(df, cols) { cols <- intersect(cols, names(df)); if (!length(cols)) return(rep(0, nrow(df)))
  rowSums(as.matrix(df[, cols, drop = FALSE]), na.rm = TRUE) }
anyobs <- function(df, cols) { cols <- intersect(cols, names(df)); rowSums(!is.na(as.matrix(df[, cols, drop = FALSE]))) > 0 }
res <- list()

## ====================== Table 2: returns to quality ======================
r <- plain(read_dta(paste0(D, "anonym_returns_data.dta")))
r$hh <- r$hhh_id; r$village <- r$ea_code

# ---- Column 1: visually verified defects per bag (10 types) ----
# Types (paper Sec. III.A): dirty, cobs, stones, dust, insects (live or dead), broken, immature,
# damaged, rotten, mould.  A bag is "inspected" if at least one defect item was recorded.
bags <- list()
for (b in 1:20) {
  g <- function(t) { v <- paste0("add4_", t, "_", b); if (v %in% names(r)) r[[v]] else rep(NA_real_, nrow(r)) }
  ins <- ifelse(is.na(g("insect")) & is.na(g("insect_live")), NA,
                as.numeric((g("insect") %in% 1) | (g("insect_live") %in% 1)))
  M <- cbind(dirty = g("dirty"), cobs = g("cobs"), stones = g("stones"), dust = g("dust"), insects = ins,
             broken = g("broken"), immature = g("immature"), damage = g("damage"), rot = g("rot"), mould = g("mould"))
  M[!is.na(M) & M > 1] <- NA  # ra/dk codes, if any
  inspected <- !is.na(r[[paste0("add4_weight_", b)]]) & rowSums(!is.na(M)) > 0
  bags[[b]] <- data.frame(hh = r$hh, village = r$village, treatment = r$treatment, bag = b,
                          defects = rowSums(M, na.rm = TRUE))[inspected, ]
}
bags <- bind_rows(bags)
m1 <- feols(defects ~ treatment | village, data = bags, cluster = ~hh)
cat("Col1: bags", nobs(m1), " households", length(unique(bags$hh)), " control bags", sum(bags$treatment == 0),
    " control mean", round(mean(bags$defects[bags$treatment == 0]), 3), "\n")
print(coeftable(m1))
res$treatment_defects_visual_table2_col1 <- coef(m1)[["treatment"]]
res$n_obs_table2_col1_bags <- nobs(m1)

# ---- Column 2: lab-verified defects (share of 200 g sample) ----
labc <- c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g", "Pest_damaged_grains_tot_g",
          "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr")
lab <- r[!is.na(r$Total_weight_of_maize_g), ]
lab$defect_share <- rs(lab, labc) / lab$Total_weight_of_maize_g
m2 <- feols(defect_share ~ treatment | village, data = lab, vcov = "hetero")
cat("Col2: N", nobs(m2), " control mean", round(mean(lab$defect_share[lab$treatment == 0]), 3), "\n")
print(coeftable(m2))
res$treatment_defects_lab_table2_col2 <- coef(m2)[["treatment"]]

# ---- Columns 3-5: sales recorded in the final visit ----
sales <- list()
for (k in 1:4) {
  y <- rep(0, nrow(r)); z <- rep(0, nrow(r)); nb <- rep(0, nrow(r))
  for (b in 1:20) {
    iw <- r[[paste0("add5_ind_weight", b, "_", k)]]; dw <- r[[paste0("add5_ind_ded_weight", b, "_", k)]]
    ew <- r[[paste0("add4_weight_", b)]]
    ok <- !is.na(iw) & !is.na(dw) & !is.na(ew)
    y[ok] <- y[ok] + ew[ok]; z[ok] <- z[ok] + dw[ok]; nb[ok] <- nb[ok] + 1
  }
  sales[[k]] <- data.frame(hh = r$hh, village = r$village, treatment = r$treatment, sale = k,
                           price = r[[paste0("add5_ppk_", k)]], date = r[[paste0("add5_sold_when_e_", k)]],
                           y = ifelse(nb > 0, y, NA), z = ifelse(nb > 0, z, NA))
}
sales <- bind_rows(sales) %>% filter(!is.na(price))
d <- as.Date(sales$date, origin = "1970-01-01")
sales$week <- ifelse(is.na(d), NA, floor((as.numeric(format(d, "%j")) - 1) / 7) + 1)  # Stata week()
sales$deduction <- 100 * (sales$y - sales$z) / sales$y
sales$net_price <- sales$price * sales$z / sales$y
cat("Sales with price:", nrow(sales), " with date:", sum(!is.na(sales$week)), " with deduction:", sum(!is.na(sales$deduction)), "\n")
m3 <- feols(price ~ treatment | village + week, data = sales, cluster = ~hh)
m4 <- feols(deduction ~ treatment | village + week, data = sales, cluster = ~hh)
m5 <- feols(net_price ~ treatment | village + week, data = sales, cluster = ~hh)
for (m in list(m3, m4, m5)) { print(coeftable(m)); cat("N", nobs(m), "\n") }
cat("Control means: price", round(mean(sales$price[sales$treatment == 0 & !is.na(sales$week)]), 2),
    " deduction", round(mean(sales$deduction[sales$treatment == 0], na.rm = TRUE), 2),
    " net price", round(mean(sales$net_price[sales$treatment == 0], na.rm = TRUE), 2), "\n")
res$treatment_price_table2_col3 <- coef(m3)[["treatment"]]
res$treatment_deductions_table2_col4 <- coef(m4)[["treatment"]]
res$treatment_net_price_table2_col5 <- coef(m5)[["treatment"]]
res$n_obs_table2_cols3_5_sales <- nobs(m3)

## ====================== Table 6 panel A: market access ======================
FX <- 3700  # UGX per US dollar (assumed constant; see notes)
g1 <- plain(read_dta(paste0(D, "panel_g1.dta")))
g1$season <- g1$survey_season; g1$village <- g1$ea_code; g1$hh <- g1$hhh_id; g1$treat <- g1$buy_treatment
sd <- plain(read_dta(paste0(D, "seller_data.dta")))
sd <- sd %>% filter(!is.na(price), price > 0, !is.na(sold_kg_p_), sold_kg_p_ > 0)

# Household-season average price and sales revenue (all buyers, incl. the quality buyer)
hhp <- sd %>% group_by(hhh_id, survey_season) %>%
  summarise(rev = sum(price * sold_kg_p_), sold = sum(sold_kg_p_), .groups = "drop") %>%
  mutate(avg_price = rev / sold)
# Community (village-season) market price: mean price of sales to buyers other than the quality buyer (code 555)
vp <- sd %>% filter(is.na(name) | name != 555) %>% group_by(ea_code, survey_season) %>%
  summarise(p_comm = mean(price), .groups = "drop")
sp <- sd %>% filter(is.na(name) | name != 555) %>% group_by(survey_season) %>% summarise(p_season = mean(price), .groups = "drop")
g1 <- g1 %>% left_join(hhp, by = c("hh" = "hhh_id", "season" = "survey_season")) %>%
  left_join(vp, by = c("village" = "ea_code", "season" = "survey_season")) %>%
  left_join(sp, by = c("season" = "survey_season")) %>%
  mutate(p_comm = ifelse(is.na(p_comm), p_season, p_comm))

# Harvest (kg) and acreage
hcols <- paste0("harvest_kg_", 1:9); pcols <- paste0("plot_size_", 1:12)
g1$harvest <- ifelse(anyobs(g1, hcols), rs(g1, hcols), g1$harvest_kg)
g1$acres <- ifelse(anyobs(g1, pcols), rs(g1, pcols), ifelse(!is.na(g1$acres_tot), g1$acres_tot,
                   ifelse(!is.na(g1$maize_tot_plotn) & g1$maize_tot_plotn == 0, 0, NA)))
g1$yield <- ifelse(!is.na(g1$acres) & g1$acres > 0, g1$harvest / g1$acres, NA)

# Price (USD per kg)
g1$price_usd <- g1$avg_price / FX

# Harvest value: sales revenue + unsold harvest valued at the community market price
g1$rev[is.na(g1$rev)] <- 0; g1$sold[is.na(g1$sold)] <- 0
g1$hv <- ifelse(is.na(g1$harvest), NA, (g1$rev + pmax(g1$harvest - g1$sold, 0) * g1$p_comm) / FX)

# Monetary expenses: inputs, equipment, transport, hired labour (UGX -> USD)
inputs <- rs(g1, c(paste0("seeds_cost_", 1:6), paste0("fert_cost_", 1:5), paste0("booster_cost_", 1:5),
                   paste0("manure_cost_", 1:3), paste0("tot_chem_costs_", 1:6), "seeds_cost", "fert_cost", "booster_cost"))
equip <- rs(g1, c(paste0("equipment_cost_", 1:5), paste0("harvest_cost_", 1:5), paste0("decobbing_cost_", 1:5), "otherph_cost"))
transport <- ifelse(!is.na(g1$tot_transport_cost), g1$tot_transport_cost, rs(g1, c("cost_transportpre", "cost_transportpost")))
hired <- rs(g1, c(paste0("tot_lab_costs_", 1:6), "labor_cost_ph"))
has_exp <- !is.na(g1$seeds_cost_1) | !is.na(g1$seeds_cost)
g1$expenses <- ifelse(has_exp & g1$season >= 2, (inputs + equip + transport + hired) / FX, NA)
g1$profit_m <- g1$hv - g1$expenses

# Own/family labour hours and the hourly market wage for hired labour
tasks <- c("prep", "plant", "weed", "spray", "harv")
g1$fam_hours <- rs(g1, c(as.vector(outer(tasks, 1:6, function(t, p) paste0("lh_", t, "_hours_season", p))),
                         "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours"))
has_hours <- anyobs(g1, paste0("lh_", tasks, "_hours_season1")) & anyobs(g1, c("lh_decob_hours", "lh_bag_hours", "lh_winnow_hours", "lh_sort_hours"))
# hours per working day: median family-reported hours per day (unit == "days") by season
hpd <- c(); wobs <- list()
for (s in sort(unique(g1$season))) {
  hh_s <- unlist(lapply(tasks, function(t) lapply(1:6, function(p) { u <- g1[[paste0("lh_", t, "_unit", p)]]; h <- g1[[paste0("lh_", t, "_hours_unit", p)]]
    if (is.null(u) || is.null(h)) return(NULL); h[g1$season == s & u %in% "days" & !is.na(h) & h > 0] })))
  hpd[as.character(s)] <- if (length(hh_s)) median(hh_s) else NA
}
for (t in tasks) for (p in 1:6) {
  u <- g1[[paste0("lc_", t, "_unit", p)]]; c <- g1[[paste0("lc_", t, "_costs_unit", p)]]
  if (is.null(u) || is.null(c)) next
  ok <- u %in% c("hours", "days") & !is.na(c) & c > 0
  hrs <- ifelse(u == "hours", 1, hpd[as.character(g1$season)])
  wobs[[length(wobs) + 1]] <- data.frame(season = g1$season[ok], w = (c / hrs)[ok])
}
wobs <- bind_rows(wobs) %>% filter(!is.na(w))
wage <- wobs %>% group_by(season) %>% summarise(wage = median(w), n = n(), .groups = "drop")
wall <- median(wobs$w)
cat("Hours per day by season:", round(hpd, 2), "\nHourly wage (UGX) by season:\n"); print(as.data.frame(wage)); cat("pooled", wall, "\n")
g1 <- g1 %>% left_join(wage %>% dplyr::select(season, wage), by = "season") %>% mutate(wage = ifelse(is.na(wage), wall, wage))
g1$profit_h <- ifelse(has_hours & g1$season >= 5, g1$profit_m - g1$wage * g1$fam_hours / FX, NA)

# ANCOVA: outcome on treatment, season dummies and household pretreatment (seasons 1-3 mean) value
ancova <- function(v) {
  pre <- g1 %>% filter(season <= 3) %>% group_by(hh) %>% summarise(pre = mean(.data[[v]], na.rm = TRUE), .groups = "drop") %>%
    mutate(pre = ifelse(is.nan(pre), NA, pre))
  dd <- g1 %>% filter(season >= 4, !is.na(.data[[v]])) %>% left_join(pre, by = "hh")
  dd$y <- dd[[v]]; dd$pre_miss <- as.numeric(is.na(dd$pre)); dd$pre[is.na(dd$pre)] <- 0
  f <- if (all(dd$pre_miss == 1)) y ~ treat + i(season) else if (any(dd$pre_miss == 1)) y ~ treat + i(season) + pre + pre_miss else y ~ treat + i(season) + pre
  m <- feols(f, data = dd, cluster = ~village)
  cat(sprintf("%-10s b=%10.4f se=%9.4f p=%6.3f N=%d  ctrl mean=%.3f  pre missing=%d\n", v, coef(m)[["treat"]], se(m)[["treat"]],
              pvalue(m)[["treat"]], nobs(m), mean(dd$y[dd$treat == 0]), sum(dd$pre_miss)))
  m
}
mp <- ancova("price_usd"); ma <- ancova("acres"); mh <- ancova("harvest"); my <- ancova("yield")
mv <- ancova("hv"); me <- ancova("expenses"); m7 <- ancova("profit_m"); m8 <- ancova("profit_h")
res$market_access_price_table6_panelA_col1 <- coef(mp)[["treat"]]
res$market_access_yield_table6_panelA_col4 <- coef(my)[["treat"]]
res$market_access_harvest_value_table6_panelA_col5 <- coef(mv)[["treat"]]
res$market_access_profit_monetary_table6_panelA_col7 <- coef(m7)[["treat"]]
res$market_access_profit_incl_own_hours_table6_panelA_col8 <- coef(m8)[["treat"]]
res$n_obs_table6_panelA_cols3_5 <- nobs(mh)
cat("N cols 3/4/5:", nobs(mh), nobs(my), nobs(mv), "\n")

cat("DEVIATION: US dollar values use a constant exchange rate of 3700 UGX/USD (rate not stated in the paper)\n")
for (n in names(res)) cat(sprintf("RESULT:%s=%.10g\n", n, res[[n]]))
