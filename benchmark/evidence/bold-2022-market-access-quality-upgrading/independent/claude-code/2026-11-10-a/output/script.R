# Independent reproduction: Bold, Ghisolfi, Nsonzi & Svensson (AER 2022)
# Table 2 (returns to quality experiment) and Table 6 panel A (market access ANCOVA)
suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
B <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-a/mount/bold_2022_market_access_quality_upgrading/"
D <- paste0(B, "data/raw/")
res <- list()
put <- function(n, v) { res[[n]] <<- v }

# ------------------------------------------------------------------ Table 2
r <- read_dta(paste0(D, "anonym_returns_data.dta"))
r$ea_code <- as.character(r$ea_code)

## (1) visually verifiable defects, bag level
defs <- c("dirty", "cobs", "stones", "dust", "broken", "immature", "damage", "rot", "mould")
bags <- list()
for (b in 1:20) {
  anyobs <- rep(FALSE, nrow(r)); cnt <- rep(0, nrow(r))
  for (d in defs) {
    v <- r[[paste0("add4_", d, "_", b)]]
    anyobs <- anyobs | !is.na(v); cnt <- cnt + ifelse(is.na(v), 0, v == 1)
  }
  ins <- r[[paste0("add4_insect_", b)]]; insl <- r[[paste0("add4_insect_live_", b)]]
  anyobs <- anyobs | !is.na(ins) | !is.na(insl)
  cnt <- cnt + as.numeric((!is.na(ins) & ins == 1) | (!is.na(insl) & insl == 1))
  bags[[b]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, bag = b, defects = cnt, obs = anyobs)
}
bags <- bind_rows(bags) %>% filter(obs)
cat("bags:", nrow(bags), " control mean defects:", mean(bags$defects[bags$treatment == 0]), "\n")
m1 <- feols(defects ~ treatment | ea_code, data = bags, cluster = ~hhh_id)
print(summary(m1))
put("treatment_defects_visual_table2_col1", coef(m1)[["treatment"]])
put("n_obs_table2_col1_bags", nobs(m1))

## (2) lab defects: share of defective grain and waste in the 200 g sample
labv <- c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g", "Pest_damaged_grains_tot_g",
          "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr")
lm_ <- as.matrix(r[, labv])
r$lab_def <- ifelse(is.na(r$Total_weight_of_maize_g), NA, rowSums(lm_, na.rm = TRUE) / r$Total_weight_of_maize_g)
cat("lab n:", sum(!is.na(r$lab_def)), " control mean:", mean(r$lab_def[r$treatment == 0], na.rm = TRUE), "\n")
m2 <- feols(lab_def ~ treatment | ea_code, data = r, vcov = "hetero")
print(summary(m2))
put("treatment_defects_lab_table2_col2", coef(m2)[["treatment"]])

## (3)-(5) sales reported in final visit (buyer slots 2-4; slot 1 = random bag bought by the research team)
aw <- as.matrix(r[, paste0("add4_weight_", 1:20)])
sales <- list()
for (k in 2:4) {
  wk <- as.matrix(r[, paste0("add5_ind_weight", 1:20, "_", k)])
  dk <- as.matrix(r[, paste0("add5_ind_ded_weight", 1:20, "_", k)])
  y <- rowSums(ifelse(is.na(wk), NA, aw), na.rm = TRUE)
  z <- rowSums(dk, na.rm = TRUE)
  sales[[k]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, slot = k,
                           price = r[[paste0("add5_ppk_", k)]], date = as.Date(r[[paste0("add5_sold_when_e_", k)]]),
                           y = y, z = z, nbag = rowSums(!is.na(wk)))
}
sales <- bind_rows(sales) %>% filter(!is.na(price))
sales <- sales %>% mutate(week = paste0(format(date, "%Y"), "-", floor((as.numeric(format(date, "%j")) - 1) / 7) + 1),
                          deduction = ifelse(nbag > 0 & y > 0, 100 * (y - z) / y, NA),
                          net_price = ifelse(nbag > 0 & y > 0, price * z / y, NA))
cat("sales:", nrow(sales), " hh:", n_distinct(sales$hhh_id), " ctrl mean price", mean(sales$price[sales$treatment == 0]),
    " ded", mean(sales$deduction[sales$treatment == 0], na.rm = TRUE), " net", mean(sales$net_price[sales$treatment == 0], na.rm = TRUE), "\n")
m3 <- feols(price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m4 <- feols(deduction ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
m5 <- feols(net_price ~ treatment | ea_code + week, data = sales, cluster = ~hhh_id, fixef.rm = "none")
print(etable(m3, m4, m5))
put("treatment_price_table2_col3", coef(m3)[["treatment"]])
put("treatment_deductions_table2_col4", coef(m4)[["treatment"]])
put("treatment_net_price_table2_col5", coef(m5)[["treatment"]])
put("n_obs_table2_cols3_5_sales", nobs(m3))

# ------------------------------------------------------------------ Table 6 panel A
XR <- 3700  # UGX per US dollar (not stated in paper; chosen so baseline mean price ~ US$0.20/kg as in Table 3)
WAGE_USD <- 26 / 118  # hourly market wage implied by text: US$26 of hired labour = 118 hours
g <- read_dta(paste0(D, "panel_g1.dta"))
g$ea_code <- as.character(g$ea_code); g$survey_season <- as.numeric(g$survey_season)
num <- function(v) if (v %in% names(g)) as.numeric(g[[v]]) else rep(NA_real_, nrow(g))
rs <- function(vs) { m <- sapply(vs, num); if (is.null(dim(m))) m <- matrix(m, ncol = 1)
  ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
z0 <- function(x) ifelse(is.na(x), 0, x)

# harvest (kg) and acreage
harv_plots <- rs(paste0("harvest_kg_", 1:9)); acres_plots <- rs(paste0("plot_size_", 1:12))
g$harvest <- ifelse(g$survey_season == 2 | is.na(g$harvest_kg), harv_plots, g$harvest_kg)
g$acres <- ifelse(is.na(g$acres_tot), acres_plots, g$acres_tot)
g$yield <- ifelse(!is.na(g$harvest) & !is.na(g$acres) & g$acres > 0, g$harvest / g$acres, NA)

# prices from sale-level data
s <- read_dta(paste0(D, "seller_data.dta"))
hs <- s %>% filter(price > 0, sold_kg_p_ > 0) %>% mutate(survey_season = as.numeric(survey_season)) %>%
  group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * sold_kg_p_), kg_sold = sum(sold_kg_p_), .groups = "drop")
g <- g %>% left_join(hs, by = c("hhh_id", "survey_season"))
g$price_ugx <- g$rev / g$kg_sold
comm <- g %>% filter(!is.na(price_ugx)) %>% group_by(ea_code, survey_season) %>% summarise(p_comm = median(price_ugx), .groups = "drop")
seas <- g %>% filter(!is.na(price_ugx)) %>% group_by(survey_season) %>% summarise(p_seas = median(price_ugx), .groups = "drop")
g <- g %>% left_join(comm, by = c("ea_code", "survey_season")) %>% left_join(seas, by = "survey_season") %>%
  mutate(p_comm = ifelse(is.na(p_comm), p_seas, p_comm))
g$price <- g$price_ugx / XR
g$hvalue <- ifelse(is.na(g$harvest), NA, (z0(g$rev) + pmax(g$harvest - z0(g$kg_sold), 0) * g$p_comm) / XR)

# monetary expenses: inputs, equipment, hired labour (pre-harvest + harvest), post-harvest labour & other costs, drying, storage, transport
inputs <- rs(c(paste0("seeds_cost_", 1:6), paste0("fert_cost_", 1:5), paste0("booster_cost_", 1:5), paste0("manure_cost_", 1:3),
               paste0("tot_chem_costs_", 1:6), "seeds_cost", "fert_cost", "booster_cost"))
equip <- rs(paste0("equipment_cost_", 1:5))
hired <- rs(paste0("tot_lab_costs_", 1:6))
post <- rs(c("labor_cost_ph", "otherph_cost", "drying_cost", "storage_cost", "labor_cost_store", paste0("harvest_cost_", 1:5), paste0("decobbing_cost_", 1:5)))
transport <- ifelse(!is.na(g$tot_transport_cost), g$tot_transport_cost, rs(c("cost_transportpre", "cost_transportpost")))
seeds_rep <- rs(paste0("seeds_cost_", 1:6))
g$expenses <- ifelse(is.na(seeds_rep), NA, (inputs + z0(equip) + z0(hired) + z0(post) + z0(transport)) / XR)
g$profit <- g$hvalue - g$expenses
own_hours <- rs(c(paste0("lh_", rep(c("prep", "plant", "weed", "spray", "harv"), each = 6), "_hours_season", 1:6),
                  "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours"))
g$own_hours <- ifelse(g$survey_season >= 5, own_hours, NA)
g$profit_own <- g$profit - WAGE_USD * g$own_hours

fu <- g %>% filter(survey_season >= 4)
base <- g %>% filter(survey_season <= 3)
# Pretreatment control: the household's value in its last observed baseline season (season 3 for almost all).
ancova <- function(y, prey = y, variant = "last", verbose = TRUE) {
  bb <- if (variant == "last") base %>% filter(!is.na(.data[[prey]])) %>% group_by(hhh_id) %>% filter(survey_season == max(survey_season)) else base
  pre <- bb %>% group_by(hhh_id) %>% summarise(pre = mean(.data[[prey]], na.rm = TRUE), .groups = "drop") %>%
    mutate(pre = ifelse(is.nan(pre), NA, pre))
  d <- fu %>% left_join(pre, by = "hhh_id") %>% filter(!is.na(.data[[y]])) %>% mutate(yy = .data[[y]])
  m <- if (variant == "none") feols(yy ~ buy_treatment | survey_season, data = d, cluster = ~ea_code) else
    feols(yy ~ buy_treatment + pre | survey_season, data = d, cluster = ~ea_code)
  if (verbose) { cat("----", y, "pre =", prey, variant, " N =", nobs(m), " ctrl mean =", round(mean(d$yy[d$buy_treatment == 0]), 3), "\n"); print(coeftable(m)) }
  m
}
t1 <- ancova("price"); t3 <- ancova("harvest"); t4 <- ancova("yield"); t5 <- ancova("hvalue")
t6 <- ancova("expenses"); t7 <- ancova("profit"); t8 <- ancova("profit_own", prey = "profit")
cat("\nDiagnostics: treatment coefficient under alternative pretreatment controls\n")
for (v in c("mean", "last", "none")) for (y in c("price", "harvest", "yield", "hvalue", "expenses", "profit")) {
  m <- ancova(y, variant = v, verbose = FALSE); cat(sprintf("  %-6s %-9s b=%9.4f se=%8.4f N=%d\n", v, y, coef(m)[["buy_treatment"]], se(m)[["buy_treatment"]], nobs(m)))
}
put("market_access_price_table6_panelA_col1", coef(t1)[["buy_treatment"]])
put("market_access_yield_table6_panelA_col4", coef(t4)[["buy_treatment"]])
put("market_access_harvest_value_table6_panelA_col5", coef(t5)[["buy_treatment"]])
put("market_access_profit_monetary_table6_panelA_col7", coef(t7)[["buy_treatment"]])
put("market_access_profit_incl_own_hours_table6_panelA_col8", coef(t8)[["buy_treatment"]])
put("n_obs_table6_panelA_cols3_5", nobs(t5))
cat("DEVIATION: Table 6 pretreatment control = outcome in the household's last observed baseline season (not the baseline mean); profit incl. own hours uses last-baseline monetary profit as its pretreatment control (own hours not measured at baseline); hourly wage fixed at US$26/118 (implied by the text); exchange rate 3700 UGX/USD (not stated in the paper).\n")

for (n in names(res)) cat(sprintf("RESULT:%s=%.6g\n", n, res[[n]]))
