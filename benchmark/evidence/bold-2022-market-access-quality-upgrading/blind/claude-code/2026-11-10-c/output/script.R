# Bold, Ghisolfi, Nsonzi & Svensson (2022, AER) -- independent blind reproduction
# Table 2 (returns to quality experiment) and Table 6 Panel A (market access experiment).
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
M <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/blind/2026-11-10-c/mount/bold_2022_market_access_quality_upgrading/data/raw/"
UGX_PER_USD <- 10000 / 3   # paper: "UGX10,000 (approximately US$3)", "UGX30,000; approximately US$9"
num <- function(x) as.numeric(zap_labels(x))

# =====================================================================
# Part 1. Returns to quality experiment (anonym_returns_data.dta)
# =====================================================================
r <- read_dta(paste0(M, "anonym_returns_data.dta"))
r$hhh_id <- num(r$hhh_id); r$treatment <- num(r$treatment)

# ---- Column 1: visually verified defects per bag (10 types) ----
items <- c("dirty", "cobs", "stones", "dust", "insect", "broken", "immature", "damage", "rot", "mould")
yes <- function(v) { x <- if (v %in% names(r)) num(r[[v]]) else rep(NA_real_, nrow(r)); x }
bags <- list()
for (b in 1:20) {
  w <- yes(paste0("add4_weight_", b))
  vals <- sapply(items, function(it) {
    if (it == "insect") {   # insects, live or dead
      a <- yes(paste0("add4_insect_", b)); l <- yes(paste0("add4_insect_live_", b))
      ifelse(is.na(a) & is.na(l), NA, as.numeric((a %in% 1) | (l %in% 1)))
    } else { x <- yes(paste0("add4_", it, "_", b)); ifelse(is.na(x), NA, as.numeric(x == 1)) }
  })
  if (is.null(dim(vals))) vals <- matrix(vals, nrow = nrow(r))
  anyobs <- rowSums(!is.na(vals)) > 0
  keep <- !is.na(w) | anyobs
  bags[[b]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, bag = b,
                          weight = w, inspected = anyobs, defects = rowSums(vals == 1, na.rm = TRUE))[keep, ]
}
bags <- bind_rows(bags)
bags_v <- bags %>% filter(inspected)
cat("Bags with weight or any visual item:", nrow(bags), "; with >=1 visual item:", nrow(bags_v), "\n")
m1 <- feols(defects ~ treatment | ea_code, data = bags_v, cluster = ~hhh_id)
cat("Col1 control mean:", mean(bags_v$defects[bags_v$treatment == 0]), "\n"); print(coeftable(m1))

# ---- Column 2: lab-verified defects (share of 200 g sample) ----
comp <- c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g", "Pest_damaged_grains_tot_g",
          "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr")
lab <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, tw = num(r$Total_weight_of_maize_g))
lab$defg <- rowSums(sapply(comp, function(v) num(r[[v]])), na.rm = TRUE)
lab <- lab %>% filter(!is.na(tw), tw > 0) %>% mutate(lab_def = defg / tw)
m2 <- feols(lab_def ~ treatment | ea_code, data = lab, vcov = "hetero")
cat("Col2 N:", nobs(m2), " control mean:", mean(lab$lab_def[lab$treatment == 0]), "\n"); print(coeftable(m2))

# ---- Columns 3-5: sales recorded in the final visit ----
rb <- num(r$add4_random_bag)
sales <- list()
for (s in 1:4) {
  W  <- sapply(1:20, function(b) num(r[[paste0("add5_ind_weight", b, "_", s)]]))
  DW <- sapply(1:20, function(b) num(r[[paste0("add5_ind_ded_weight", b, "_", s)]]))
  TW <- sapply(1:20, function(b) num(r[[paste0("add4_weight_", b)]]))   # enumerator-measured (true) weight of each bag
  inbag <- !is.na(W)
  y <- rowSums(ifelse(inbag, TW, NA), na.rm = TRUE)   # measured weight of bags in this sale
  z <- rowSums(ifelse(inbag, ifelse(is.na(DW), W, DW), NA), na.rm = TRUE)   # agreed weight after deductions
  nb <- rowSums(inbag)
  only_rb <- nb == 1 & sapply(seq_len(nrow(r)), function(i) isTRUE(inbag[i, rb[i]]))
  has_rb <- sapply(seq_len(nrow(r)), function(i) isTRUE(inbag[i, rb[i]]))
  mis_tw <- rowSums(inbag & is.na(TW))
  d <- r[[paste0("add5_sold_when_e_", s)]]
  sales[[s]] <- data.frame(hhh_id = r$hhh_id, ea_code = r$ea_code, treatment = r$treatment, sale = s,
                           price = num(r[[paste0("add5_ppk_", s)]]), y = y, z = z, nbags = nb,
                           only_rb = only_rb, has_rb = has_rb, mis_tw = mis_tw, date = as.Date(d))
}
sales <- bind_rows(sales) %>% filter(!is.na(price))
cat("Sale records with price:", nrow(sales), "; consisting only of the research team's random bag:", sum(sales$only_rb),
    "; containing random bag plus other bags:", sum(sales$has_rb & !sales$only_rb), "; with bag lacking measured weight:", sum(sales$mis_tw > 0), "\n")
# The randomly selected bag was bought by the research team for lab testing: not a market sale.
mk <- sales %>% filter(!only_rb) %>%
  mutate(week = ifelse(is.na(date), "missing", paste0(format(date, "%Y"), "-", (as.integer(format(date, "%j")) - 1) %/% 7 + 1)),
         deduction = ifelse(y > 0 & mis_tw == 0, 100 * (y - z) / y, NA),
         net_price = ifelse(y > 0 & mis_tw == 0, price * z / y, NA))
cat("Market sales:", nrow(mk), " households:", length(unique(mk$hhh_id)), " missing dates:", sum(is.na(mk$date)),
    " missing deduction:", sum(is.na(mk$deduction)), "\n")
m3 <- feols(price ~ treatment | ea_code + week, data = mk, cluster = ~hhh_id)
m4 <- feols(deduction ~ treatment | ea_code + week, data = mk, cluster = ~hhh_id)
m5 <- feols(net_price ~ treatment | ea_code + week, data = mk, cluster = ~hhh_id)
for (m in list(m3, m4, m5)) { print(coeftable(m)); cat("N =", nobs(m), "\n") }
cat("Control means: price", mean(mk$price[mk$treatment == 0]), " deduction", mean(mk$deduction[mk$treatment == 0], na.rm = TRUE),
    " net price", mean(mk$net_price[mk$treatment == 0], na.rm = TRUE), "\n")

# =====================================================================
# Part 2. Market access experiment (panel_g1.dta + seller_data.dta)
# =====================================================================
g <- read_dta(paste0(M, "panel_g1.dta"))
g <- g %>% mutate(hhh_id = num(hhh_id), survey_season = num(survey_season), buy_treatment = num(buy_treatment))
col <- function(v) if (v %in% names(g)) num(g[[v]]) else rep(NA_real_, nrow(g))
rsum <- function(vs) { m <- sapply(vs, col); if (is.null(dim(m))) m <- matrix(m, ncol = 1); ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA) }
P <- 1:12

harv_plot <- rsum(paste0("harvest_kg_", P))
g$harvest <- ifelse(!is.na(col("harvest_kg")), col("harvest_kg"), harv_plot)
acres_plot <- rsum(paste0("plot_size_", P))
g$acres <- ifelse(!is.na(col("acres_tot")), col("acres_tot"), acres_plot)
g$yield <- ifelse(!is.na(g$acres) & g$acres > 0, g$harvest / g$acres, NA)

# sales: price, revenue, kg sold per household-season
sd <- read_dta(paste0(M, "seller_data.dta")) %>%
  mutate(hhh_id = num(hhh_id), survey_season = num(survey_season), price = num(price), kg = num(sold_kg_p_))
sdv <- sd %>% filter(!is.na(price), price > 0, !is.na(kg), kg > 0)
hs <- sdv %>% group_by(hhh_id, survey_season) %>% summarise(rev = sum(price * kg), kg_sold = sum(kg), .groups = "drop") %>%
  mutate(price_ugx = rev / kg_sold)
vp <- sdv %>% group_by(ea_code, survey_season) %>% summarise(vprice = sum(price * kg) / sum(kg), .groups = "drop")
sp <- sdv %>% group_by(survey_season) %>% summarise(sprice = sum(price * kg) / sum(kg), .groups = "drop")
g <- g %>% left_join(hs, by = c("hhh_id", "survey_season")) %>% left_join(vp, by = c("ea_code", "survey_season")) %>%
  left_join(sp, by = "survey_season") %>%
  mutate(cprice = ifelse(is.na(vprice), sprice, vprice),
         rev = ifelse(is.na(rev), 0, rev), kg_sold = ifelse(is.na(kg_sold), 0, kg_sold),
         price = price_ugx / UGX_PER_USD,
         # harvest value: sales revenue + unsold harvest (own consumption etc.) at the village-season market price
         harvest_value = ifelse(is.na(harvest), NA, (rev + pmax(harvest - kg_sold, 0) * cprice) / UGX_PER_USD))

# monetary expenses: inputs, equipment, transport, hired labor (UGX)
inputs <- rsum(c(paste0("seeds_cost_", P), paste0("fert_cost_", P), paste0("booster_cost_", P), paste0("manure_cost_", P),
                 paste0("tot_chem_costs_", P)))
equip <- rsum(paste0("equipment_cost_", P))
transport <- ifelse(!is.na(col("tot_transport_cost")), col("tot_transport_cost"), rsum(c("cost_transportpre", "cost_transportpost")))
hired <- rsum(c(paste0("tot_lab_costs_", P), "labor_cost_ph", "labor_cost_dry", "labor_cost_store"))
other_ph <- rsum(c("otherph_cost", "drying_cost", "storage_cost"))
has_costs <- !is.na(inputs) | !is.na(hired)
g$expenses <- ifelse(has_costs, rowSums(cbind(inputs, equip, transport, hired, other_ph), na.rm = TRUE) / UGX_PER_USD, NA)
g$profit <- g$harvest_value - g$expenses

# own / family labor hours and market wage
own_h <- rsum(c(as.vector(outer(c("lh_prep_hours_season", "lh_plant_hours_season", "lh_weed_hours_season",
                                  "lh_spray_hours_season", "lh_harv_hours_season"), 1:6, paste0)),
                "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours"))
g$own_hours <- ifelse(!is.na(rsum(as.vector(outer(c("lh_prep_hours_season", "lh_harv_hours_season"), 1:6, paste0)))), own_h, NA)
# hourly market wage: daily hired-labor rates (cost per person-day) divided by the median hours per working day
# reported for family labor; season-specific median over all hired-labor entries
tasks <- c("prep", "plant", "weed", "spray", "harv")
wl <- list(); hl <- list()
for (t in tasks) for (p in 1:6) {
  u <- paste0("lc_", t, "_unit", p); cst <- paste0("lc_", t, "_costs_unit", p)
  if (u %in% names(g) && cst %in% names(g)) wl[[length(wl) + 1]] <- data.frame(survey_season = g$survey_season, unit = as.character(g[[u]]), cost = num(g[[cst]]))
  u2 <- paste0("lh_", t, "_unit", p); h2 <- paste0("lh_", t, "_hours_unit", p)
  if (u2 %in% names(g) && h2 %in% names(g)) hl[[length(hl) + 1]] <- data.frame(unit = as.character(g[[u2]]), hrs = num(g[[h2]]))
}
wl <- bind_rows(wl); hl <- bind_rows(hl)
hpd <- median(hl$hrs[hl$unit == "days" & hl$hrs > 0], na.rm = TRUE)
wage <- wl %>% filter(unit == "days", cost > 0) %>% group_by(survey_season) %>% summarise(wage_h = median(cost) / hpd, n = n(), .groups = "drop")
cat("Hours per day:", hpd, "\n"); print(as.data.frame(wage))
wage_all <- median(wl$cost[wl$unit == "days" & wl$cost > 0], na.rm = TRUE) / hpd
g <- g %>% left_join(wage %>% select(survey_season, wage_h), by = "survey_season") %>%
  mutate(wage_h = ifelse(is.na(wage_h), wage_all, wage_h),
         profit_own = profit - own_hours * wage_h / UGX_PER_USD)

# ANCOVA: follow-up seasons 4-7; Y ~ D + season FE + household pre-treatment (seasons 1-3 mean) value of Y
ancova <- function(v) {
  pre <- g %>% filter(survey_season <= 3) %>% group_by(hhh_id) %>% summarise(pre = mean(.data[[v]], na.rm = TRUE), .groups = "drop") %>%
    mutate(pre = ifelse(is.nan(pre), NA, pre))
  d <- g %>% filter(survey_season >= 4, !is.na(.data[[v]])) %>% left_join(pre, by = "hhh_id") %>%
    mutate(pre_miss = as.numeric(is.na(pre)), pre0 = ifelse(is.na(pre), 0, pre), y = .data[[v]])
  f <- if (all(d$pre_miss == 1)) y ~ buy_treatment | survey_season else if (any(d$pre_miss == 1)) y ~ buy_treatment + pre0 + pre_miss | survey_season else y ~ buy_treatment + pre0 | survey_season
  m <- feols(f, data = d, cluster = ~ea_code)
  cat(sprintf("%-14s N=%d  pre missing=%d  coef=%.4f  se=%.4f  p=%.3f  control mean=%.3f\n", v, nobs(m), sum(d$pre_miss),
              coef(m)["buy_treatment"], se(m)["buy_treatment"], pvalue(m)["buy_treatment"], mean(d$y[d$buy_treatment == 0])))
  m
}
t6 <- lapply(c("price", "acres", "harvest", "yield", "harvest_value", "expenses", "profit", "profit_own"), ancova)
names(t6) <- c("price", "acres", "harvest", "yield", "harvest_value", "expenses", "profit", "profit_own")

cat("DEVIATION: UGX->USD conversion fixed at 3,333.33 UGX/USD (paper's stated approximation UGX10,000 ~ US$3); the paper's exact rate is not given.\n")
cat("DEVIATION: Profit incl. own hours has no pre-treatment value (family hours only collected from season 4/5 on); the ANCOVA for column 8 therefore omits the lagged outcome.\n")
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
cat(sprintf("RESULT:market_access_profit_monetary_table6_panelA_col7=%.6f\n", coef(t6$profit)["buy_treatment"]))
cat(sprintf("RESULT:market_access_profit_incl_own_hours_table6_panelA_col8=%.6f\n", coef(t6$profit_own)["buy_treatment"]))
cat(sprintf("RESULT:n_obs_table6_panelA_cols3_5=%d\n", nobs(t6$harvest)))
