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

p$hv_a <- p$harvest * ifelse(is.na(p$price_ugx), p$vprice, p$price_ugx) / USD
# expenses variant: post-harvest labour from components when available (drops a 12m UGX labor_cost_ph entry not in components)
labc <- c("lc_decob_labour_costs","lc_winnow_labour_costs","lc_sort_labour_costs","lc_bag_labour_costs")
comp <- rs(p, labc)
p$lph2 <- ifelse(p$season >= 5 & !is.na(comp), comp + z(p$labor_cost_store), p$labor_cost_ph)
cat("labor_cost_ph top values:\n"); print(head(sort(p$labor_cost_ph, decreasing = TRUE), 8))
cat("tot_lab_costs_1 top:\n"); print(head(sort(p$tot_lab_costs_1, decreasing = TRUE), 8))
p$expenses2 <- p$expenses - z(p$labor_cost_ph) / USD + z(p$lph2) / USD
p$expenses2[is.na(p$expenses)] <- NA
p$profit2 <- p$hv - p$expenses2; p$profit_a <- p$hv_a - p$expenses; p$profit_a2 <- p$hv_a - p$expenses2
p$profit_own2 <- p$profit2 - p$fam_hours * wage / USD; p$profit_own_a2 <- p$profit_a2 - p$fam_hours * wage / USD
vars <- c("price","acres","harvest","yield","hv","hv_a","expenses","expenses2","profit","profit2","profit_a","profit_a2","profit_own","profit_own2","profit_own_a2")
ownmap <- c(profit_own = "profit", profit_own2 = "profit2", profit_own_a2 = "profit_a2")
mk <- function(type) {
  b <- p %>% filter(season <= 3) %>% arrange(hhh_id, season)
  out <- data.frame(hhh_id = unique(b$hhh_id))
  for (v in setdiff(vars, names(ownmap))) {
    if (type == "last") { x <- b %>% filter(!is.na(.data[[v]])) %>% group_by(hhh_id) %>% summarise(pre = last(.data[[v]])) }
    else { x <- b %>% filter(season == 3) %>% transmute(hhh_id, pre = .data[[v]]) }
    names(x)[2] <- paste0(v, "_pre"); out <- left_join(out, x, by = "hhh_id")
  }
  for (o in names(ownmap)) out[[paste0(o, "_pre")]] <- out[[paste0(ownmap[o], "_pre")]]
  fu <- p %>% filter(season >= 4) %>% left_join(out, by = "hhh_id")
  if (type %in% c("s3zero", "s3mean")) for (v in vars) { pv <- paste0(v, "_pre"); fu[[paste0(v, "_miss")]] <- as.numeric(is.na(fu[[pv]]))
    fu[[pv]][is.na(fu[[pv]])] <- if (type == "s3zero") 0 else mean(fu[[pv]], na.rm = TRUE) }
  fu
}
show <- function(lbl, fu, md = FALSE) {
  cat("\n---", lbl, "---\n")
  for (v in vars) {
    f <- paste0(v, " ~ treat + factor(season) + ", v, "_pre", if (md) paste0(" + ", v, "_miss") else "")
    m <- feols(as.formula(f), data = fu, cluster = ~ea_code, notes = FALSE)
    if (v %in% c("acres","harvest","expenses","expenses2")) cat(sprintf("%-14s coef %9.4f N %d R2 %.2f\n", v, coef(m)["treat"], nobs(m), r2(m, "r2")))
    else cat(sprintf("%-14s N %d R2 %.2f\n", v, nobs(m), r2(m, "r2")))
  }
}
cat("targets: price R2 .68 N617; acres .046 R2 .27 N677; harvest 239.3 R2 .29; yield R2 .09; hv R2 .32; expenses 18.3 R2 .33 N640; profit R2 .22; profit_own R2 .18 N464\n")
show("last available baseline", mk("last"))
show("s3, missing->0 + dummy", mk("s3zero"), TRUE)
show("s3, missing->mean + dummy", mk("s3mean"), TRUE)
fu <- p %>% filter(season >= 4)
cat("control means: expenses", mean(fu$expenses[fu$treat == 0], na.rm = TRUE), " expenses2", mean(fu$expenses2[fu$treat == 0], na.rm = TRUE), " hv_a", mean(fu$hv_a[fu$treat == 0], na.rm = TRUE),
    " profit_a", mean(fu$profit_a[fu$treat == 0], na.rm = TRUE), " profit_own", mean(fu$profit_own[fu$treat == 0], na.rm = TRUE), " profit_own_a2", mean(fu$profit_own_a2[fu$treat == 0], na.rm = TRUE), "\n")
