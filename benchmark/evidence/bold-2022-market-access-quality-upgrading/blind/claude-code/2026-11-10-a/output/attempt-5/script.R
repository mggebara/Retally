# Bold, Ghisolfi, Nsonzi & Svensson (2022, AER) -- independent blind reproduction
# Table 2 (returns to quality experiment) and Table 6 panel A (market access experiment)
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(M, "data/raw/")
res <- list()
coefT <- function(m, v) unname(coef(m)[v])

## =================== Returns to quality experiment (Table 2) ===================
r <- read_dta(paste0(D, "anonym_returns_data.dta"))
r$ea_code <- as.character(r$ea_code)

# ---- column 1: visually verified defects, unit = bag (all bags inspected) ----
g <- function(stem, b) { v <- paste0("add4_", stem, "_", b); x <- as.numeric(r[[v]]); x[is.na(x)] <- 0; x }
bags <- do.call(rbind, lapply(1:20, function(b) {
  w <- as.numeric(r[[paste0("add4_weight_", b)]])
  insects <- pmax(g("insect", b), g("insect_live", b))   # insects (live or dead) = one defect type
  nd <- g("dirty", b) + g("cobs", b) + g("stones", b) + g("dust", b) + g("broken", b) +
        g("immature", b) + g("damage", b) + g("rot", b) + insects + g("mould", b)
  data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, bag = b, weight = w, defects = nd)
}))
bags <- bags[!is.na(bags$weight), ]
m1 <- feols(defects ~ treatment | ea_code, data = bags, cluster = ~hhh_id)
cat("Col1: N bags =", nobs(m1), " control mean =", mean(bags$defects[bags$treatment == 0]), "\n")
print(coeftable(m1))

# ---- column 2: lab defects (share of 200 g sample), one random bag per household ----
comp <- c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g", "Pest_damaged_grains_tot_g",
          "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr")
lab <- r[!is.na(r$Total_weight_of_maize_g), ]
lab$def_lab <- rowSums(as.matrix(lab[, comp]), na.rm = TRUE) / lab$Total_weight_of_maize_g
m2 <- feols(def_lab ~ treatment | ea_code, data = lab, vcov = "hetero")
cat("Col2: N =", nobs(m2), " control mean =", mean(lab$def_lab[lab$treatment == 0]), "\n")
print(coeftable(m2))

# ---- columns 3-5: sales reported at the final visit ----
# Sale slot 1 in the add5 roster is the research team's purchase of the randomly drawn lab bag
# (its bag weight equals the enumerator weight exactly); market sales are slots 2-4.
A <- as.matrix(r[, paste0("add4_weight_", 1:20)])
sales <- do.call(rbind, lapply(2:4, function(s) {
  W  <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", s)])
  WD <- as.matrix(r[, paste0("add5_ind_ded_weight", 1:20, "_", s)])
  sold <- !is.na(W)
  y <- rowSums(ifelse(sold, A, 0), na.rm = TRUE)      # enumerator-measured weight of the bags sold
  z <- rowSums(ifelse(sold, WD, 0), na.rm = TRUE)     # agreed (buyer-stated, after deduction) weight
  d <- as.character(r[[paste0("add5_sold_when_e_", s)]]); d[!is.na(d) & !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}", d)] <- NA
  data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, sale = s,
             price = as.numeric(r[[paste0("add5_ppk_", s)]]), y = y, z = z, nbags = rowSums(sold),
             date = as.Date(substr(d, 1, 10)))
}))
sales <- sales[!is.na(sales$price), ]
sales$week <- format(sales$date, "%G-%V")
sales$deduction <- ifelse(sales$y > 0, 100 * (sales$y - sales$z) / sales$y, NA)
sales$net_price <- ifelse(sales$y > 0, sales$price * sales$z / sales$y, NA)
cat("Sales:", nrow(sales), " households:", length(unique(sales$hhh_id)), " missing date:", sum(is.na(sales$date)),
    " missing y:", sum(sales$y == 0), "\n")
m3 <- feols(price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)
m4 <- feols(deduction ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)
m5 <- feols(net_price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id)
for (m in list(m3, m4, m5)) { print(coeftable(m)); cat("N =", nobs(m), "\n") }
cat("control means: price", mean(sales$price[sales$treatment == 0]), " ded", mean(sales$deduction[sales$treatment == 0], na.rm = TRUE),
    " net", mean(sales$net_price[sales$treatment == 0], na.rm = TRUE), "\n")

res$treatment_defects_visual_table2_col1 <- coefT(m1, "treatment")
res$treatment_defects_lab_table2_col2    <- coefT(m2, "treatment")
res$treatment_price_table2_col3          <- coefT(m3, "treatment")
res$treatment_deductions_table2_col4     <- coefT(m4, "treatment")
res$treatment_net_price_table2_col5      <- coefT(m5, "treatment")
res$n_obs_table2_col1_bags               <- nobs(m1)
res$n_obs_table2_cols3_5_sales           <- nobs(m3)

## =================== Market access experiment (Table 6, panel A) ===================
UGX_PER_USD <- 3700   # assumption: approx. average UGX/USD rate 2017-2020 (not given in the data)
g1 <- read_dta(paste0(D, "panel_g1.dta"))
g1$ea_code <- as.character(g1$ea_code)
s0 <- function(df, vars) { vars <- intersect(vars, names(df)); if (!length(vars)) return(rep(0, nrow(df)))
  rowSums(as.matrix(df[, vars, drop = FALSE]), na.rm = TRUE) }

# sales / prices
sd <- read_dta(paste0(D, "seller_data.dta"))
hp <- sd %>% filter(sold_kg_p_ > 0, price > 0) %>% group_by(hhh_id, survey_season) %>%
  summarise(rev = sum(price * sold_kg_p_), kg_sold = sum(sold_kg_p_), .groups = "drop") %>%
  mutate(price_ugx = rev / kg_sold)
g1 <- left_join(g1, hp, by = c("hhh_id", "survey_season"))
comm <- g1 %>% group_by(ea_code, survey_season) %>% summarise(cp = median(price_ugx, na.rm = TRUE), .groups = "drop")
seasp <- g1 %>% group_by(survey_season) %>% summarise(sp = median(price_ugx, na.rm = TRUE), .groups = "drop")
g1 <- g1 %>% left_join(comm, by = c("ea_code", "survey_season")) %>% left_join(seasp, by = "survey_season") %>%
  mutate(cp = ifelse(is.na(cp), sp, cp))

# harvest, acreage, yield
plot_h <- as.matrix(g1[, paste0("harvest_kg_", 1:6)])
g1$harvest <- ifelse(!is.na(g1$harvest_kg), g1$harvest_kg, ifelse(rowSums(!is.na(plot_h)) > 0, rowSums(plot_h, na.rm = TRUE), NA))
plot_a <- as.matrix(g1[, paste0("plot_size_", 1:6)])
g1$acres <- ifelse(!is.na(g1$acres_tot), g1$acres_tot, ifelse(rowSums(!is.na(plot_a)) > 0, rowSums(plot_a, na.rm = TRUE), NA))
g1$yield <- ifelse(!is.na(g1$acres) & g1$acres > 0, g1$harvest / g1$acres, NA)

# harvest value: sales revenue + unsold (own-consumed) maize at the community (village-season) median price
g1$rev[is.na(g1$rev)] <- 0; g1$kg_sold[is.na(g1$kg_sold)] <- 0
g1$hv_ugx <- ifelse(is.na(g1$harvest), NA, g1$rev + pmax(g1$harvest - g1$kg_sold, 0) * g1$cp)

# monetary expenses: inputs, equipment, transport, hired labor (pre- and postharvest)
pl <- function(stem) paste0(stem, 1:6)
exp_vars <- c(pl("seeds_cost_"), pl("fert_cost_"), pl("booster_cost_"), pl("manure_cost_"), pl("tot_chem_costs_"),
              pl("equipment_cost_"), pl("tot_lab_costs_"), pl("harvest_cost_"), pl("decobbing_cost_"),
              "drying_cost", "storage_cost", "labor_cost_dry", "labor_cost_store", "labor_cost_ph", "otherph_cost",
              pl("sale_transport_cost_"))
g1$transport <- ifelse(!is.na(g1$tot_transport_cost), g1$tot_transport_cost, s0(g1, c("cost_transportpre", "cost_transportpost")))
g1$exp_ugx <- ifelse(is.na(g1$seeds_cost_1), NA, s0(g1, exp_vars) + g1$transport)

# own/family labor hours (collected seasons 5-7) and market wage for hired labor
lh_vars <- c(outer(paste0("lh_", c("prep", "plant", "weed", "spray", "harv"), "_hours_season"), 1:6, paste0))
g1$own_hours <- ifelse(g1$survey_season >= 5 & !is.na(g1$lh_prep_hours_season1),
                       s0(g1, c(lh_vars, "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours")), NA)
acts <- c("prep", "plant", "weed", "spray", "harv")
day_cost <- unlist(lapply(acts, function(a) { u <- g1[[paste0("lc_", a, "_unit1")]]; c_ <- g1[[paste0("lc_", a, "_costs_unit1")]]; c_[!is.na(u) & u == "days" & !is.na(c_) & c_ > 0] }))
hrs_day  <- unlist(lapply(acts, function(a) { u <- g1[[paste0("lh_", a, "_unit1")]]; h <- g1[[paste0("lh_", a, "_hours_unit1")]]; h[!is.na(u) & u == "days" & !is.na(h) & h > 0] }))
wage_ugx_hr <- median(day_cost) / median(hrs_day)
cat("Hourly wage (UGX):", wage_ugx_hr, " = median daily hired wage", median(day_cost), "/ median hours per day", median(hrs_day), "\n")

g1 <- g1 %>% mutate(
  price_usd = ifelse(kg_sold > 0, price_ugx / UGX_PER_USD, NA),
  hv = hv_ugx / UGX_PER_USD,
  expenses = exp_ugx / UGX_PER_USD,
  profit_m = hv - expenses,
  profit_own = profit_m - wage_ugx_hr * own_hours / UGX_PER_USD)

# ANCOVA: follow-up seasons 4-7; Y = gamma*T + season FE + theta*Y_pre; SEs clustered by village
pre <- g1 %>% filter(survey_season <= 3) %>% group_by(hhh_id) %>%
  summarise(across(c(price_usd, harvest, yield, hv, expenses, profit_m), ~ mean(.x, na.rm = TRUE), .names = "{.col}_pre"), .groups = "drop")
pre[] <- lapply(pre, function(x) ifelse(is.nan(x), NA, x))
fu <- g1 %>% filter(survey_season >= 4) %>% left_join(pre, by = "hhh_id")
fu$profit_own_pre <- fu$profit_m_pre   # own hours not collected at baseline: pretreatment monetary profit used
ancova <- function(y) {
  d <- fu; d$Y <- d[[y]]; d$P <- d[[paste0(y, "_pre")]]
  d$Pmiss <- as.numeric(is.na(d$P)); d$P[is.na(d$P)] <- 0
  m <- feols(Y ~ buy_treatment + P + Pmiss | survey_season, data = d[!is.na(d$Y), ], cluster = ~ea_code)
  cat("\n==", y, " N =", nobs(m), " control mean =", mean(d$Y[d$buy_treatment == 0], na.rm = TRUE), "\n"); print(coeftable(m)[1:2, ])
  m
}
mp <- ancova("price_usd"); mh <- ancova("harvest"); my <- ancova("yield"); mv <- ancova("hv")
me <- ancova("expenses"); m7 <- ancova("profit_m"); m8 <- ancova("profit_own")

res$market_access_price_table6_panelA_col1                 <- coefT(mp, "buy_treatment")
res$market_access_yield_table6_panelA_col4                 <- coefT(my, "buy_treatment")
res$market_access_harvest_value_table6_panelA_col5         <- coefT(mv, "buy_treatment")
res$market_access_profit_monetary_table6_panelA_col7       <- coefT(m7, "buy_treatment")
res$market_access_profit_incl_own_hours_table6_panelA_col8 <- coefT(m8, "buy_treatment")
res$n_obs_table6_panelA_cols3_5                            <- nobs(mh)
cat("N harvest / yield / harvest value:", nobs(mh), nobs(my), nobs(mv), "\n")

cat("DEVIATION: UGX converted to USD at a constant 3700 UGX/USD (rate not provided in data or paper).\n")
cat("DEVIATION: own labor valued at hourly wage = median daily hired-labor wage / median reported hours per day; own hours available seasons 5-7 only, so col 8 uses pretreatment monetary profit as the lagged control.\n")
cat("DEVIATION: missing pretreatment values set to 0 with a missing-indicator in ANCOVA.\n")
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
