# Independent reproduction: Bold, Ghisolfi, Nsonzi & Svensson (2022, AER)
# "Market Access and Quality Upgrading: Evidence from Four Field Experiments"
# Table 2 (returns to quality experiment) and Table 6 panel A (market access experiment).
# Built from the raw survey/lab files only; the authors' code was not available/used.
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
PRINT_RESULTS <- TRUE
base <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-d/mount/bold_2022_market_access_quality_upgrading"
rd <- function(f) zap_labels(read_dta(file.path(base, "data/raw", f)))
res <- list()

## ---------------- Table 2: returns to quality experiment ----------------
r <- rd("anonym_returns_data.dta")
# (1) visually verifiable defects: ten defect types checked per bag by enumerators
#     dirty, cobs, stones, dust, insects (dead or live), broken, immature, damaged, rotten, mould
bl <- list()
for (b in 1:20) {
  g <- function(d) r[[paste0("add4_", d, "_", b)]]
  yes <- function(x) !is.na(x) & x == 1
  inspected <- Reduce(`|`, lapply(c("dirty","cobs","stones","dust","broken","immature","damage","rot","insect","insect_live","mould"), function(d) !is.na(g(d))))
  nd <- yes(g("dirty")) + yes(g("cobs")) + yes(g("stones")) + yes(g("dust")) + (yes(g("insect")) | yes(g("insect_live"))) +
        yes(g("broken")) + yes(g("immature")) + yes(g("damage")) + yes(g("rot")) + yes(g("mould"))
  bl[[b]] <- data.frame(hh = r$hhh_id, treatment = r$treatment, ea = r$ea_code, bag = b, ndef = nd, inspected = inspected)
}
bags <- bind_rows(bl) %>% filter(inspected)
cat("Bags inspected:", nrow(bags), " control mean defects:", round(mean(bags$ndef[bags$treatment == 0]), 3), "\n")
# (3)-(5) sales recorded in final visit. Repeat 1 of the sales module is the single random bag
# bought by the research team for lab testing; repeats 2-4 are the household's sales to buyers.
sl <- list()
for (s in 2:4) {
  ppk <- r[[paste0("add5_ppk_", s)]]
  iw <- sapply(1:20, function(b) r[[paste0("add5_ind_weight", b, "_", s)]])       # buyer-stated bag weight
  dw <- sapply(1:20, function(b) r[[paste0("add5_ind_ded_weight", b, "_", s)]])   # agreed weight after deductions
  ew <- sapply(1:20, function(b) r[[paste0("add4_weight_", b)]])                  # enumerator-measured weight
  sel <- !is.na(iw)
  sl[[s]] <- data.frame(hh = r$hhh_id, treatment = r$treatment, ea = r$ea_code, sale = s, price = ppk,
                        date = as.numeric(r[[paste0("add5_sold_when_e_", s)]]),
                        y = rowSums(ifelse(sel, ew, 0), na.rm = TRUE), z = rowSums(ifelse(sel, dw, 0), na.rm = TRUE))
}
sales <- bind_rows(sl) %>% filter(!is.na(price))
sales$deduction <- 100 * (sales$y - sales$z) / sales$y
sales$netprice <- sales$price * sales$z / sales$y
d <- as.Date(sales$date, origin = "1970-01-01")
sales$week <- floor((as.numeric(format(d, "%j")) - 1) / 7) + 1   # Stata week-of-year
cat("Sales:", nrow(sales), " households:", n_distinct(sales$hh), "\n")
print(sales %>% group_by(treatment) %>% summarise(n = n(), price = mean(price), deduction = mean(deduction), netprice = mean(netprice)))
## ---------------- Table 6 panel A: market access experiment ----------------
USD <- 3700   # UGX per US dollar (assumed constant rate; see notes)
p <- rd("panel_g1.dta")
P <- function(stem, k = 1:7) { cols <- paste0(stem, k); cols <- cols[cols %in% names(p)]; m <- as.matrix(p[, cols])
  ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
z0 <- function(x) ifelse(is.na(x), 0, x)
p$post <- as.integer(p$survey_season >= 4)
# harvest (kg) and maize acreage
p$harvest <- ifelse(!is.na(p$harvest_kg), p$harvest_kg, P("harvest_kg_"))
plots <- P("plot_size_", 1:12)
p$acres <- ifelse(!is.na(plots), plots, p$acres_tot)
p$acres[is.na(p$acres) & !is.na(p$maize_tot_plotn) & p$maize_tot_plotn == 0] <- 0
p$yield <- ifelse(p$acres > 0, p$harvest / p$acres, NA)
# sales and prices (seller-level data; identical to panel revenues/kg)
s <- rd("seller_data.dta")
ss <- s %>% group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg = sum(sold_kg_p_), .groups = "drop") %>%
  mutate(price_ugx = ifelse(kg > 0, rev / kg, NA))
p <- left_join(p, ss, by = c("hhh_id", "survey_season"))
vp <- p %>% filter(!is.na(price_ugx)) %>% group_by(ea_code, survey_season) %>% summarise(vprice = mean(price_ugx), .groups = "drop")
p <- left_join(p, vp, by = c("ea_code", "survey_season"))
p$price <- p$price_ugx / USD
# harvest value: sales revenue plus unsold harvest (own consumption/stock) valued at the village-season mean price
p$hvalue <- ifelse(is.na(p$harvest), NA, (z0(p$rev) + pmax(p$harvest - z0(p$kg), 0) * p$vprice) / USD)
# monetary expenses: inputs (seeds, fertilizer, booster, chemicals, manure), equipment, hired labour
# (pre-harvest + harvest), post-harvest labour and other post-harvest costs, transport
inputs <- P("seeds_cost_")
p$exp_ugx <- ifelse(is.na(inputs), NA,
  inputs + z0(P("fert_cost_")) + z0(P("booster_cost_")) + z0(P("tot_chem_costs_")) + z0(P("manure_cost_")) + z0(P("equipment_cost_")) +
  z0(P("tot_lab_costs_")) + z0(p$labor_cost_ph) + z0(p$otherph_cost) +
  ifelse(!is.na(p$tot_transport_cost), p$tot_transport_cost, z0(p$cost_transportpre) + z0(p$cost_transportpost)))
p$expenses <- p$exp_ugx / USD
p$profit <- p$hvalue - p$expenses
# own/family labour hours (collected from season 5 onwards) valued at the hourly market wage for hired labour
lhpre <- P("lh_prep_hours_season"); lhs <- cbind(lhpre, P("lh_plant_hours_season"), P("lh_weed_hours_season"), P("lh_spray_hours_season"), P("lh_harv_hours_season"),
                                                  p$lh_decob_hours, p$lh_winnow_hours, p$lh_sort_hours, p$lh_bag_hours)
p$famhours <- ifelse(rowSums(!is.na(lhs[, 1:5])) > 0, rowSums(lhs, na.rm = TRUE), NA)
dw <- unlist(lapply(c("prep","plant","weed","spray","harv"), function(t) { u <- p[[paste0("lc_", t, "_unit1")]]; v <- p[[paste0("lc_", t, "_costs_unit1")]]; v[!is.na(u) & u == "days" & !is.na(v) & v > 0] }))
hd <- unlist(lapply(c("prep","plant","weed","spray","harv"), function(t) { u <- p[[paste0("lh_", t, "_unit1")]]; v <- p[[paste0("lh_", t, "_hours_unit1")]]; v[!is.na(u) & u == "days" & !is.na(v) & v > 0] }))
wage <- median(dw) / median(hd)
cat("Daily hired wage (median UGX):", median(dw), " hours/day (median):", median(hd), " hourly wage UGX:", round(wage, 1), " USD:", round(wage / USD, 3), "\n")
p$famcost <- p$famhours * wage / USD
p$profit_own <- p$profit - p$famcost
# diagnostics against Table 3 baseline summary statistics (not claims)
bl <- p %>% filter(post == 0)
cat("Baseline means (USD): harvest value", round(mean(bl$hvalue, na.rm = TRUE), 1), "n", sum(!is.na(bl$hvalue)),
    "| price", round(mean(bl$price, na.rm = TRUE), 3), "n", sum(!is.na(bl$price)),
    "| expenses", round(mean(bl$expenses, na.rm = TRUE), 1), "n", sum(!is.na(bl$expenses)),
    "| profit", round(mean(bl$profit, na.rm = TRUE), 1), "| harvest", round(mean(bl$harvest, na.rm = TRUE)), "| acres", round(mean(bl$acres, na.rm = TRUE), 2), "\n")
# ANCOVA: follow-up seasons, outcome on treatment, season dummies and household's pre-treatment (baseline mean) outcome
pre <- p %>% filter(post == 0) %>% group_by(hhh_id) %>%
  summarise(across(c(price, acres, harvest, yield, hvalue, expenses, profit), ~ if (all(is.na(.x))) NA_real_ else mean(.x, na.rm = TRUE), .names = "{.col}_pre"))
fu <- p %>% filter(post == 1) %>% left_join(pre, by = "hhh_id")
fu$profit_own_pre <- fu$profit_pre   # no baseline family-hours data: monetary profit used as pre-treatment control
for (v in c("price","acres","harvest","yield","hvalue","expenses","profit","profit_own")) { ok <- !is.na(fu[[v]]) & !is.na(fu[[paste0(v, "_pre")]])
  cat(sprintf("%-11s n_with_pre=%d n_nonNA=%d ctl_mean=%9.3f\n", v, sum(ok), sum(!is.na(fu[[v]])), mean(fu[[v]][ok & fu$buy_treatment == 0]))) }
a2 <- ifelse(!is.na(fu$acres_tot), fu$acres_tot, fu$acres); y2 <- ifelse(a2 > 0, fu$harvest / a2, NA)
cat("yield alt (acres_tot first) ctl mean:", mean(y2[fu$buy_treatment == 0 & !is.na(fu$yield_pre)], na.rm = TRUE), " n:", sum(!is.na(y2) & !is.na(fu$yield_pre)), "\n")
cat("famhours ctl FU mean:", mean(fu$famhours[fu$buy_treatment == 0], na.rm = TRUE), " famcost:", mean(fu$famcost[fu$buy_treatment == 0], na.rm = TRUE), "\n")
cat("profit ctl FU (seasons 5-7, famhours nonNA):", mean(fu$profit[fu$buy_treatment == 0 & !is.na(fu$famhours)], na.rm = TRUE), "\n")
cat("acres NA FU rows:", sum(is.na(fu$acres)), "\n")
