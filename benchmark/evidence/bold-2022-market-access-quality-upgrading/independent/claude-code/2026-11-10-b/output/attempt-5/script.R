# Independent reproduction: Bold, Ghisolfi, Nsonzi & Svensson (AER 2022)
# "Market Access and Quality Upgrading: Evidence from Four Field Experiments"
# Table 2 (returns to quality experiment) and Table 6 Panel A (market access experiment).
# Built from the raw data files only; the authors' code was not consulted.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
options(width = 200, dplyr.summarise.inform = FALSE)
D <- "<repo>/benchmark/.cache/claude-code/bold-2022-market-access-quality-upgrading/independent/2026-11-10-b/mount/bold_2022_market_access_quality_upgrading/data/raw"
rs <- function(d, v) { v <- intersect(v, names(d)); m <- as.matrix(d[, v, drop = FALSE]); out <- rowSums(m, na.rm = TRUE); out[rowSums(!is.na(m)) == 0] <- NA; out }
z  <- function(x) ifelse(is.na(x), 0, x)

######################################################################
# TABLE 2: Returns to quality experiment (99 households, 9 villages)
######################################################################
r <- read_dta(file.path(D, "anonym_returns_data.dta"))
r$hhh_id <- as.numeric(r$hhh_id); r$treatment <- as.numeric(r$treatment)

## Column 1: visually verified defects per bag (ten types; insects = live or dead)
defs <- list(dirty = "dirty", cobs = "cobs", stones = "stones", dust = "dust", insect = c("insect", "insect_live"),
             broken = "broken", immature = "immature", damage = "damage", rot = "rot", mould = "mould")
bags <- list()
for (b in 1:20) {
  w <- as.numeric(r[[paste0("add4_weight_", b)]])
  M <- sapply(names(defs), function(d) {
    x <- sapply(paste0("add4_", defs[[d]], "_", b), function(v) as.numeric(r[[v]]))
    if (is.null(dim(x))) x <- matrix(x, ncol = length(defs[[d]]))
    x[x > 1] <- NA                                  # ra/dk codes -> missing
    apply(x, 1, function(q) if (all(is.na(q))) NA else max(q, na.rm = TRUE))
  })
  bags[[b]] <- data.frame(id = r$hhh_id, tr = r$treatment, ea = as.character(r$ea_code), bag = b, w = w,
                          ndef = rowSums(M, na.rm = TRUE), inspected = rowSums(!is.na(M)) > 0)
}
bags <- bind_rows(bags) %>% filter(!is.na(w), inspected)   # bags put up for sale and visually inspected
m1 <- feols(ndef ~ tr | ea, data = bags, cluster = ~id)

## Column 2: lab-verified defects (share of 200 g sample that is waste/defective), one random bag per hh
labc <- c("Foreign_matter_tot_g", "Inorganic_matter_tot_g", "Broken_grains_tot_g", "Pest_damaged_grains_tot_g",
          "Rotten_and_diseased_grain", "Discoloured_grains_tot_g", "Immature_or_shrivelled_gr")
lab <- data.frame(id = r$hhh_id, tr = r$treatment, ea = as.character(r$ea_code),
                  labdef = rowSums(as.matrix(r[, labc]), na.rm = TRUE) / as.numeric(r$Total_weight_of_maize_g)) %>% filter(!is.na(labdef))
m2 <- feols(labdef ~ tr | ea, data = lab, vcov = "hetero")

## Columns 3-5: sales recorded in the final visit.
## Sale 1 in the add5 roster is the single random bag bought by the research team for the lab;
## market sales are rosters 2-4. Enumerator-measured bag weights (add4) are matched in order to the
## bags of each market sale after removing the randomly selected lab bag.
sales <- list()
for (i in seq_len(nrow(r))) {
  wts <- unlist(r[i, paste0("add4_weight_", 1:20)]); wts <- as.numeric(wts[!is.na(wts)])
  rest <- wts[-as.numeric(r$add4_random_bag[i])]
  pos <- 0
  for (k in 2:4) {
    p <- as.numeric(r[[paste0("add5_ppk_", k)]][i]); if (is.na(p)) next
    iw <- as.numeric(unlist(r[i, paste0("add5_ind_weight", 1:20, "_", k)]))
    dw <- as.numeric(unlist(r[i, paste0("add5_ind_ded_weight", 1:20, "_", k)]))
    nb <- sum(!is.na(iw))
    y  <- if (pos + nb <= length(rest)) sum(rest[(pos + 1):(pos + nb)]) else NA
    pos <- pos + nb
    dt <- r[[paste0("add5_sold_when_e_", k)]][i]
    sales[[length(sales) + 1]] <- data.frame(id = r$hhh_id[i], tr = r$treatment[i], ea = as.character(r$ea_code[i]),
      price = p, y = y, zagreed = sum(dw, na.rm = TRUE),
      week = paste0(format(dt, "%Y"), "w", floor((as.numeric(format(dt, "%j")) - 1) / 7) + 1))
  }
}
sales <- bind_rows(sales)
sales$deduction <- 100 * (sales$y - sales$zagreed) / sales$y     # (y - z)/y in percent
sales$netprice  <- sales$price * sales$zagreed / sales$y          # p z / y
m3 <- feols(price ~ tr | ea + week, data = sales, cluster = ~id)
m4 <- feols(deduction ~ tr | ea + week, data = sales, cluster = ~id)
m5 <- feols(netprice ~ tr | ea + week, data = sales, cluster = ~id)

cat("==== Table 2 ====\n")
for (m in list(m1, m2, m3, m4, m5)) print(coeftable(m))
cat(sprintf("Control means: defects %.3f, lab %.3f, price %.2f, deductions %.3f, net price %.2f\n",
  mean(bags$ndef[bags$tr == 0]), mean(lab$labdef[lab$tr == 0]), mean(sales$price[sales$tr == 0]),
  mean(sales$deduction[sales$tr == 0]), mean(sales$netprice[sales$tr == 0])))
cat(sprintf("N: bags %d (hh %d), lab %d, sales %d (hh %d)\n", nobs(m1), length(unique(bags$id)), nobs(m2), nobs(m3), length(unique(sales$id))))

######################################################################
# TABLE 6 Panel A: Market access experiment, ANCOVA on follow-up seasons 4-7
######################################################################
USD <- 3700   # UGX per US dollar (approximate 2017-2020 average; the paper does not state the rate)
p <- read_dta(file.path(D, "panel_g1.dta"))
p$season <- as.numeric(p$survey_season); p$hhh_id <- as.numeric(p$hhh_id); p$treat <- as.numeric(p$buy_treatment)
p$ea_code <- as.character(p$ea_code)

# Harvest: household total (harvest_kg from season 3 on; sum over plots in seasons 1-2)
p$harvest <- ifelse(p$season >= 3, p$harvest_kg, rs(p, paste0("harvest_kg_", 1:6)))
p$psum    <- rs(p, paste0("plot_size_", 1:6))
p$acres   <- ifelse(p$season >= 3 & !is.na(p$acres_tot), p$acres_tot, z(p$psum))
p$yield   <- ifelse(!is.na(p$psum) & p$psum > 0, p$harvest / p$psum, ifelse(p$acres > 0, p$harvest / p$acres, NA))

# Prices from the sale-level file: average price per kg (revenue / kg sold), household-season
sd <- read_dta(file.path(D, "seller_data.dta")); sd$season <- as.numeric(sd$survey_season); sd$hhh_id <- as.numeric(sd$hhh_id)
pr <- sd %>% filter(price > 0, sold_kg_p_ > 0) %>% group_by(hhh_id, season) %>%
  summarise(rev = sum(price * sold_kg_p_), sold = sum(sold_kg_p_), .groups = "drop") %>% mutate(price_ugx = rev / sold)
p <- left_join(p, pr, by = c("hhh_id", "season"))
vp <- p %>% group_by(ea_code, season) %>% summarise(vprice = mean(price_ugx, na.rm = TRUE), .groups = "drop")
p <- left_join(p, vp, by = c("ea_code", "season"))

# Harvest value: sales revenue + unsold (own-consumed) maize at the community-season market price
p$hv_ugx <- ifelse(is.na(p$harvest), NA, z(p$rev) + pmax(p$harvest - z(p$sold), 0) * p$vprice)

# Monetary expenses: inputs, hired labour (pre-harvest and harvest), post-harvest labour and equipment,
# drying/storage, transport. Defined when the expense module was administered (labor_cost_ph observed).
inputs <- c(paste0("seeds_cost_", 1:6), "seeds_cost", paste0("fert_cost_", 1:5), "fert_cost", paste0("booster_cost_", 1:5), "booster_cost",
            paste0("manure_cost_", 1:3), paste0("tot_chem_costs_", 1:6))
p$exp_ugx <- z(rs(p, inputs)) + z(rs(p, paste0("equipment_cost_", 1:5))) + z(rs(p, paste0("tot_lab_costs_", 1:6))) +
  z(rs(p, paste0("harvest_cost_", 1:5))) + z(rs(p, paste0("decobbing_cost_", 1:5))) +
  z(p$labor_cost_ph) + z(p$otherph_cost) + z(p$drying_cost) + z(p$storage_cost) + z(p$labor_cost_store) +
  ifelse(!is.na(p$tot_transport_cost), p$tot_transport_cost, z(p$cost_transportpre) + z(p$cost_transportpost))
p$exp_ugx[is.na(p$labor_cost_ph)] <- NA

# Own/family labour hours (collected from season 5 on), valued at the hired-labour market wage:
# median daily wage for hired labour reported per day / median hours worked per day.
lhv <- c(as.vector(outer(c("prep", "plant", "weed", "spray", "harv"), 1:6, function(a, b) paste0("lh_", a, "_hours_season", b))),
         "lh_decob_hours", "lh_winnow_hours", "lh_sort_hours", "lh_bag_hours")
p$fam_hours <- ifelse(p$season >= 5, rs(p, lhv), NA)
cpd <- c(); hpd <- c()
for (t in c("prep", "plant", "weed", "spray", "harv")) for (k in 1:6) {
  u <- paste0("lc_", t, "_unit", k); cu <- paste0("lc_", t, "_costs_unit", k)
  if (all(c(u, cu) %in% names(p))) { s <- p[[u]] == "days" & !is.na(p[[cu]]) & p[[cu]] > 0; cpd <- c(cpd, p[[cu]][s]) }
  u2 <- paste0("lh_", t, "_unit", k); h2 <- paste0("lh_", t, "_hours_unit", k)
  if (all(c(u2, h2) %in% names(p))) { s <- p[[u2]] == "days" & !is.na(p[[h2]]) & p[[h2]] > 0; hpd <- c(hpd, p[[h2]][s]) }
}
wage <- median(cpd) / median(hpd)
cat(sprintf("\nHourly wage (UGX): %.1f = %.0f per day / %.1f hours\n", wage, median(cpd), median(hpd)))

p <- p %>% mutate(price = price_ugx / USD, hv = hv_ugx / USD, expenses = exp_ugx / USD,
                  profit = hv - expenses, profit_own = profit - fam_hours * wage / USD)

# Pre-treatment value: household mean over the baseline seasons 1-3.
base <- p %>% filter(season <= 3) %>% group_by(hhh_id) %>%
  summarise(across(c(price, acres, harvest, yield, hv, expenses, profit), ~ mean(.x, na.rm = TRUE), .names = "{.col}_pre")) %>%
  mutate(across(ends_with("_pre"), ~ ifelse(is.nan(.x), NA, .x)))
base$profit_own_pre <- base$profit_pre   # own hours were not collected at baseline: use baseline monetary profit
fu <- p %>% filter(season >= 4) %>% left_join(base, by = "hhh_id")

anc <- function(v) {
  f <- as.formula(paste0(v, " ~ treat + factor(season) + ", v, "_pre"))
  feols(f, data = fu, cluster = ~ea_code)
}
outs <- c("price", "acres", "harvest", "yield", "hv", "expenses", "profit", "profit_own")
res <- lapply(outs, anc); names(res) <- outs
cat("\n==== Table 6 Panel A (ANCOVA, follow-up seasons, village-clustered SE) ====\n")
for (v in outs) {
  m <- res[[v]]; ct <- coeftable(m)["treat", ]
  used <- fu[obs(m), ]
  cat(sprintf("%-11s coef %10.4f  se %9.4f  p %.3f  N %d  R2 %.2f  control mean %.3f\n", v, ct[1], ct[2], ct[4], nobs(m), r2(m, "r2"),
              mean(used[[v]][used$treat == 0])))
}

######################################################################
cat("\n")
cat(sprintf("RESULT:treatment_defects_visual_table2_col1=%.6f\n", coef(m1)["tr"]))
cat(sprintf("RESULT:treatment_defects_lab_table2_col2=%.6f\n", coef(m2)["tr"]))
cat(sprintf("RESULT:treatment_price_table2_col3=%.6f\n", coef(m3)["tr"]))
cat(sprintf("RESULT:treatment_deductions_table2_col4=%.6f\n", coef(m4)["tr"]))
cat(sprintf("RESULT:treatment_net_price_table2_col5=%.6f\n", coef(m5)["tr"]))
cat(sprintf("RESULT:n_obs_table2_col1_bags=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table2_cols3_5_sales=%d\n", nobs(m3)))
cat(sprintf("RESULT:market_access_price_table6_panelA_col1=%.6f\n", coef(res$price)["treat"]))
cat(sprintf("RESULT:market_access_yield_table6_panelA_col4=%.6f\n", coef(res$yield)["treat"]))
cat(sprintf("RESULT:market_access_harvest_value_table6_panelA_col5=%.6f\n", coef(res$hv)["treat"]))
cat(sprintf("RESULT:market_access_profit_monetary_table6_panelA_col7=%.6f\n", coef(res$profit)["treat"]))
cat(sprintf("RESULT:market_access_profit_incl_own_hours_table6_panelA_col8=%.6f\n", coef(res$profit_own)["treat"]))
cat(sprintf("RESULT:n_obs_table6_panelA_cols3_5=%d\n", nobs(res$harvest)))
