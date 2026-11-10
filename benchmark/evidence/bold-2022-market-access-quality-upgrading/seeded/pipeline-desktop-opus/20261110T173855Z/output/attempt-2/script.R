suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)
options(warn = 1, width = 200)

BASE <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading"
RAW <- file.path(BASE, "data", "raw")

results <- list()
add_result <- function(name, value) {
  value <- suppressWarnings(as.numeric(value))
  if (length(value) == 1 && is.finite(value)) {
    results[[name]] <<- value
  } else {
    message("Could not compute ", name)
  }
}

# ------------------------------------------------------------------
# Generic helpers (mimic Stata semantics)
# ------------------------------------------------------------------
read_clean <- function(f) {
  x <- haven::read_dta(f)
  x <- haven::zap_labels(x)
  as.data.frame(x, stringsAsFactors = FALSE)
}
num <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  if (is.numeric(x) || is.logical(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}
strv <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; trimws(x) }
W <- function(cond) { cond <- as.logical(cond); !is.na(cond) & cond }
fin <- function(x) { x[!is.finite(x)] <- NA_real_; x }
rowtot_list <- function(lst, n) {
  if (length(lst) == 0) return(rep(NA_real_, n))
  m <- do.call(cbind, lst)
  s <- rowSums(m, na.rm = TRUE)
  s[rowSums(!is.na(m)) == 0] <- NA_real_
  s
}
rowmed_list <- function(lst, n) {
  if (length(lst) == 0) return(rep(NA_real_, n))
  m <- do.call(cbind, lst)
  apply(m, 1, function(r) if (all(is.na(r))) NA_real_ else stats::median(r, na.rm = TRUE))
}
stata_mode <- function(x) {
  x <- x[!is.na(x)]
  if (!length(x)) return(NA_real_)
  t <- table(as.character(x))
  md <- names(t)[t == max(t)]
  if (length(md) > 1) return(NA_real_)
  as.numeric(md)
}

# Functions operating on the global data frame `d`
missing_vars <- character(0)
V <- function(v) {
  if (v %in% names(d)) num(d[[v]]) else { missing_vars <<- c(missing_vars, v); rep(NA_real_, nrow(d)) }
}
S <- function(v) {
  if (v %in% names(d)) strv(d[[v]]) else { missing_vars <<- c(missing_vars, v); rep("", nrow(d)) }
}
RE <- function(re) grep(re, names(d), value = TRUE)
RT <- function(vars) rowtot_list(lapply(vars, V), nrow(d))
setif <- function(x, cond, val) {
  i <- W(cond)
  if (length(val) == 1) x[i] <- val else x[i] <- val[i]
  x
}
gen_if <- function(val, cond) {
  out <- rep(NA_real_, nrow(d))
  i <- W(cond)
  if (length(val) == 1) out[i] <- val else out[i] <- val[i]
  out
}

# ==================================================================
# PART A: Table 6 Panel A (market access experiment, group 1)
# Port of FINAL_create_vars_main_g1.do + ANCOVA (as in XAppendix_table11 w/o trimming)
# ==================================================================
tryCatch({
  d <- read_clean(file.path(RAW, "panel_g1.dta"))
  n <- nrow(d)
  cat("panel_g1 rows:", n, "\n")
  ss <- V("survey_season")
  fu <- S("form_used")
  phone <- fu == "Phone_Market_Survey_spring2020"
  mkt20 <- fu == "Market_Survey_spring2020"
  hh <- V("hhh_id")
  s2020 <- V("season_spring2020")
  s2018 <- V("season_spring2018")

  # ---- acreage
  acreage <- RT(c(RE("^plot_size_.$"), RE("^plot_size_..$")))
  acreage <- setif(acreage, is.na(acreage) & V("maize_tot_plotn") == 0, 0)
  acreage <- setif(acreage, ss == 7 & phone, V("acres_tot"))
  d$acreage <- acreage

  # ---- input expenses
  d$equipment_cost_tot <- gen_if(RT(RE("^equipment_cost_.$")), ss == 3)
  d$tot_chem_costs <- RT(RE("^tot_chem_costs_.$"))
  x <- gen_if(RT(RE("^seeds_cost_.$")), ss >= 2)
  d$seeds_cost_tot <- setif(x, ss == 7 & phone, V("seeds_cost"))
  x <- gen_if(RT(RE("^fert_cost_.$")), ss >= 2)
  d$fert_cost_tot <- setif(x, ss == 7 & phone, V("fert_cost"))
  d$manure_cost_tot <- gen_if(RT(RE("^manure_cost_.$")), ss >= 2)
  x <- gen_if(RT(RE("^booster_cost_.$")), ss >= 2)
  d$booster_cost_tot <- setif(x, ss == 7 & phone, V("booster_cost"))
  d$manure_cost_tot <- setif(d$manure_cost_tot,
                             is.na(d$manure_cost_tot) & acreage != 0 & !is.na(acreage) &
                               (ss == 4 | ss == 6 | (ss == 7 & mkt20)), 0)
  d$harvest_cost_tot <- gen_if(RT(RE("^harvest_cost_.$")), ss == 2 | ss == 3)

  # ---- harvest and yield
  x <- RT(RE("^harvest_kg_.$"))
  d$harvest_kg_tot <- setif(x, s2020 == 1 & phone, V("harvest_kg"))
  y <- fin(d$harvest_kg_tot / acreage)
  y <- setif(y, hh == 10247005 & s2018 == 1, fin(V("harvest_kg_1") / V("plot_size_1")))
  y <- setif(y, (hh == 10165041 | hh == 10231013) & ss == 5, fin(V("harvest_kg_2") / V("plot_size_2")))
  d$yield <- fin(y)

  # ---- post-harvest costs
  for (v in c("storage_cost", "drying_cost", "otherph_cost")) d[[v]] <- setif(V(v), acreage == 0, NA)
  x <- gen_if(RT(RE("^decobbing_cost_.$")), ss == 2)
  d$decobbing_cost_tot <- setif(x, acreage == 0, NA)

  # ---- labour costs
  for (a in c("prep", "plant", "weed", "spray", "harv")) {
    x <- gen_if(RT(RE(paste0("^lc_", a, "_costs_season.$"))), ss != 1)
    x <- setif(x, is.na(x) & acreage != 0 & !is.na(acreage) & ss == 5, 0)
    d[[paste0("labor_cost_", a, "_tot")]] <- x
  }
  d$labor_cost_ph <- setif(V("labor_cost_ph"), acreage == 0, NA)
  lcs <- V("labor_cost_store")
  d$labor_cost_store <- setif(lcs, is.na(lcs) & S("storage") != "" & ss >= 5, 0)
  d$labor_cost_dry <- V("labor_cost_dry")
  d$expenses_labor_preharvest_ugx <- gen_if(
    RT(c("labor_cost_prep_tot", "labor_cost_plant_tot", "labor_cost_spray_tot", "labor_cost_weed_tot")),
    ss != 1 & ss != 4 & !phone)
  x <- gen_if(RT(RE("^tot_lab_costs_.$")), ss >= 4)
  d$tot_lab_costs_preh_aggh_tot <- setif(x, ss == 2 | ss == 3,
                                         d$expenses_labor_preharvest_ugx + d$labor_cost_harv_tot)

  # ---- labour hours
  for (a in c("prep", "plant", "spray", "weed", "harv")) {
    d[[paste0(a, "_unpaid_lab_tothrs")]] <- gen_if(RT(RE(paste0("^lh_", a, "_hours_season.$"))), ss >= 5)
  }
  d$spray_unpaid_lab_tothrs <- setif(d$spray_unpaid_lab_tothrs,
                                     is.na(d$spray_unpaid_lab_tothrs) & acreage != 0 & !is.na(acreage) & ss == 5, 0)
  d$tot_lab_hours_preh_aggh_tot <- gen_if(
    RT(paste0(c("prep", "plant", "weed", "spray", "harv"), "_unpaid_lab_tothrs")), ss >= 5)

  # ---- hourly wage
  mc <- list(); mh <- list()
  for (a in c("prep", "plant", "weed", "harv")) {
    dc <- list(); dh <- list()
    for (k in 1:6) {
      u <- paste0("lc_", a, "_unit", k)
      if (u %in% names(d)) dc[[length(dc) + 1]] <- ifelse(S(u) == "days", V(paste0("lc_", a, "_costs_unit", k)), NA_real_)
      hu <- paste0("lh_", a, "_hours_unit", k); hu2 <- paste0("lh_", a, "_unit", k)
      if (hu %in% names(d) && hu2 %in% names(d)) dh[[length(dh) + 1]] <- ifelse(S(hu2) == "days", V(hu), NA_real_)
    }
    mc[[a]] <- rowmed_list(dc, n); mh[[a]] <- rowmed_list(dh, n)
  }
  dailyhours <- stata_mode(rowmed_list(mh, n))
  dailywage <- stata_mode(rowmed_list(mc, n))
  hourlywage <- floor(dailywage / dailyhours + 0.5)
  cat("Daily wage mode:", dailywage, " daily hours mode:", dailyhours, " hourly wage:", hourlywage, "\n")
  if (!is.finite(hourlywage)) { hourlywage <- 833; cat("Hourly wage fallback to 833\n") }
  d$preh_unpaid_lab_aggh_sh <- d$tot_lab_hours_preh_aggh_tot * hourlywage

  # ---- post-harvest activities (seasons >= 5)
  for (a in c("decob", "winnow", "sort", "bag")) {
    sa <- S(a)
    ad <- ifelse(sa != "" & ss >= 5, as.numeric(sa == "yes"), NA_real_)
    d[[paste0(a, "_d")]] <- ad
    for (v in c(paste0("lh_", a, "_hours"), paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_other_costs"))) {
      xv <- V(v)
      d[[v]] <- setif(xv, is.na(xv) & !is.na(ad) & ss >= 5, 0)
    }
    d[[paste0("lh_", a, "_hours_sh")]] <- gen_if(V(paste0("lh_", a, "_hours")) * 833, ss >= 5)
    xv <- gen_if(V(paste0("lc_", a, "_labmaize_costs")) * V(paste0("lc_", a, "_price")), ss >= 5)
    d[[paste0("lc_", a, "_lmtot_costs")]] <- setif(xv, is.na(xv) & !is.na(ad) & ss >= 5, 0)
  }
  d$lc_decob_lmtot_costs <- setif(d$lc_decob_lmtot_costs, hh == 10247077 & ss == 7, V("lc_decob_labmaize_costs"))
  d$lc_bag_lmtot_costs <- setif(d$lc_bag_lmtot_costs, hh == 10247013 & ss == 7, V("lc_bag_labmaize_costs"))
  for (a in c("decob", "winnow", "sort", "bag")) {
    d[[paste0(a, "_cost_tot")]] <- RT(c(paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_lmtot_costs"),
                                        paste0("lc_", a, "_other_costs")))
  }

  # ---- sale transport
  for (k in c(1, 2, 3, 5)) {
    v <- paste0("sale_transport_cost_", k)
    d[[v]] <- setif(V(v), S(paste0("sale_transport_yn_", k)) == "no" & ss >= 3, 0)
  }
  d$sale_transport_cost_tot <- gen_if(RT(RE("^sale_transport_cost_.$")), ss >= 3)

  # ---- quantities sold
  hk <- d$harvest_kg_tot
  sr <- V("survey_round"); sc <- S("sold_crop")
  x <- RT(RE("^sold_kg_p_.$"))
  x <- setif(x, ss == 7 & phone, V("sold_kg"))
  x <- setif(x, hh == 10249047 & ss == 1, 0)
  x <- setif(x, hh == 10328006 & ss == 1, 0)
  x <- setif(x, hh == 10165056 & ss == 2 & sr == 1, 0)
  x <- setif(x, hh == 10235011 & ss == 2 & sr == 1, 0)
  x <- setif(x, !is.na(hk) & is.na(x) & ss == 2 & sr == 2, 0)
  x <- setif(x, !is.na(hk) & is.na(x) & ss == 3, 0)
  x <- setif(x, !is.na(hk) & is.na(x) & ss == 5 & sc == "no", 0)
  x <- setif(x, !is.na(hk) & is.na(x) & ss == 6 & sc == "no", 0)
  x <- setif(x, !is.na(hk) & is.na(x) & ss == 7 & sc == "no" & mkt20, 0)
  x <- setif(x, hh == 10235035 & s2020 == 1, NA)
  x <- setif(x, hh %in% c(10078042, 10181008, 10181009, 10231001, 10247021, 10326064,
                          10328005, 10328014, 10328034, 10350040) & ss == 4, 0)
  x <- setif(x, hh %in% c(10219013, 10231002, 10354079) & ss == 5, 0)
  d$sold_kg_tot <- x

  # ---- revenue, price, harvest value
  x <- RT(c(RE("^tot_rev_combined_._.$"), RE("^tot_rev_combined_.$")))
  x <- setif(x, phone, V("tot_rev_told_tot"))
  x <- setif(x, !is.na(hk) & is.na(x) & d$sold_kg_tot == 0, 0)
  d$rev_tot <- x
  d$price_ugx <- fin(d$rev_tot / d$sold_kg_tot)
  key <- paste(strv(d$ea_code), ss)
  pv <- ave(d$price_ugx, key, FUN = function(z) if (all(is.na(z))) rep(NA_real_, length(z)) else rep(mean(z, na.rm = TRUE), length(z)))
  rem <- hk - d$sold_kg_tot
  hv <- ifelse(W(rem >= 0), d$rev_tot + rem * pv, NA_real_)
  hv <- setif(hv, rem < 0, hk * d$price_ugx)
  hv <- setif(hv, hh == 10249026 & ss == 3, hk * pv)
  d$harvest_value_ugx <- hv

  # ---- expenses by season
  EXP <- function(vars, cond) gen_if(RT(vars), cond)
  e_f17 <- EXP(c("seeds_cost_tot", "fert_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
                 "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "harvest_cost_tot", "decobbing_cost_tot",
                 "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "cost_transportpre",
                 "cost_transportpost"), ss == 2)
  e_s18 <- EXP(c("seeds_cost_tot", "fert_cost_tot", "manure_cost_tot", "booster_cost_tot", "equipment_cost_tot",
                 "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "tot_chem_costs", "harvest_cost_tot",
                 "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "labor_cost_dry",
                 "labor_cost_store", "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot"), ss == 3)
  e_f18 <- EXP(c("fert_cost_tot", "tot_chem_costs", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot",
                 "tot_lab_costs_preh_aggh_tot", "drying_cost", "storage_cost", "labor_cost_store", "otherph_cost",
                 "labor_cost_ph", "tot_transport_cost", "sale_transport_cost_tot"), ss == 4)
  post_common <- c("fert_cost_tot", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
                   "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "drying_cost", "storage_cost",
                   "labor_cost_store", "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot",
                   "decob_cost_tot", "sort_cost_tot", "winnow_cost_tot", "bag_cost_tot")
  e_s19 <- EXP(post_common, ss == 5)
  e_f19 <- EXP(post_common, ss == 6)
  e_s20 <- EXP(post_common, ss == 7 & mkt20)
  hrs_common <- c(post_common, "preh_unpaid_lab_aggh_sh", "lh_decob_hours_sh", "lh_sort_hours_sh",
                  "lh_winnow_hours_sh", "lh_bag_hours_sh")
  eh_s19 <- EXP(hrs_common, ss == 5)
  eh_f19 <- EXP(hrs_common, ss == 6)
  eh_s20 <- EXP(hrs_common, ss == 7 & mkt20)

  expn <- rep(NA_real_, n)
  for (p in list(list("season_fall2017", e_f17), list("season_spring2018", e_s18),
                 list("season_fall2018", e_f18), list("season_spring2019", e_s19),
                 list("season_fall2019", e_f19), list("season_spring2020", e_s20))) {
    expn <- setif(expn, V(p[[1]]) == 1, p[[2]])
  }
  expn <- setif(expn, s2020 == 1 & phone, NA)
  exph <- rep(NA_real_, n)
  for (p in list(list("season_spring2019", eh_s19), list("season_fall2019", eh_f19),
                 list("season_spring2020", eh_s20), list("season_fall2017", e_f17),
                 list("season_spring2018", e_s18))) {
    exph <- setif(exph, V(p[[1]]) == 1, p[[2]])
  }
  d$expenses_ugx <- expn
  d$expenses_hours_ugx <- exph
  d$surplus_ugx <- d$harvest_value_ugx - d$expenses_ugx
  d$surplus_hrs_ugx <- d$harvest_value_ugx - d$expenses_hours_ugx

  rates <- c(`1` = 3575, `2` = 3601, `3` = 3626, `4` = 3758, `5` = 3670, `6` = 3685, `7` = 3681, `8` = 3685)
  rate <- as.numeric(rates[as.character(ss)])
  for (v in c("price", "harvest_value", "expenses", "expenses_hours", "surplus", "surplus_hrs")) {
    d[[v]] <- d[[paste0(v, "_ugx")]] / rate
  }

  if (length(missing_vars)) cat("Variables referenced but not found in panel_g1:", paste(unique(missing_vars), collapse = " "), "\n")

  # ---- treatment indicator
  if (!("buy_treatment" %in% names(d))) {
    bd <- read_clean(file.path(RAW, "buy_data.dta"))
    bt <- tapply(num(bd$buy_treatment), as.character(num(bd$hhh_id)), max, na.rm = TRUE)
    d$buy_treatment <- as.numeric(bt[as.character(hh)])
  }
  d$buy_treatment <- num(d$buy_treatment)
  d$survey_season <- ss
  d$hhh_id <- hh
  d$ea_code_c <- strv(d$ea_code)
  grp <- if ("group" %in% names(d)) V("group") else rep(1, n)
  g1 <- d[W(grp == 1), ]
  cat("Group 1 rows:", nrow(g1), "\n")

  ancova <- function(df, var) {
    xv <- df[[var]]
    h <- as.character(df$hhh_id)
    hmean <- function(sel) {
      s <- W(sel) & !is.na(xv)
      if (!any(s)) return(rep(NA_real_, length(xv)))
      mm <- tapply(xv[s], h[s], mean)
      as.numeric(mm[h])
    }
    p3 <- hmean(num(df$season_spring2018) == 1)
    pp <- hmean(num(df$season_ante) == 1)
    p3[is.na(p3)] <- pp[is.na(p3)]
    df$yv <- xv
    df$p3v <- p3
    est <- df[W(num(df$season_post) == 1), ]
    feols(yv ~ buy_treatment + p3v + factor(survey_season), data = est, cluster = ~ea_code_c)
  }

  t6 <- list()
  for (v in c("price", "acreage", "harvest_kg_tot", "yield", "harvest_value", "expenses", "surplus", "surplus_hrs")) {
    t6[[v]] <- tryCatch(ancova(g1, v), error = function(e) { message("ANCOVA failed for ", v, ": ", conditionMessage(e)); NULL })
    if (!is.null(t6[[v]])) {
      cat(sprintf("Table6 A %-15s b=%.4f se=%.4f N=%d\n", v, coef(t6[[v]])["buy_treatment"],
                  se(t6[[v]])["buy_treatment"], nobs(t6[[v]])))
    }
  }
  gb <- function(m) if (is.null(m)) NA else unname(coef(m)["buy_treatment"])
  add_result("market_access_price_table6_panelA_col1", gb(t6$price))
  add_result("market_access_yield_table6_panelA_col4", gb(t6$yield))
  add_result("market_access_harvest_value_table6_panelA_col5", gb(t6$harvest_value))
  add_result("market_access_profit_monetary_table6_panelA_col7", gb(t6$surplus))
  add_result("market_access_profit_incl_own_hours_table6_panelA_col8", gb(t6$surplus_hrs))
  if (!is.null(t6$harvest_kg_tot)) add_result("n_obs_table6_panelA_cols3_5", nobs(t6$harvest_kg_tot))
}, error = function(e) message("Table 6 block failed: ", conditionMessage(e)))

# ==================================================================
# PART B: Table 2 (returns-to-quality experiment)
# ==================================================================
rd <- NULL
tryCatch({
  rd <- read_clean(file.path(RAW, "anonym_returns_data.dta"))
  cat("anonym_returns_data rows:", nrow(rd), " cols:", ncol(rd), "\n")
  stems_all <- unique(sub("_[0-9]+$", "", names(rd)))
  cat("Returns data column stems:\n", paste(stems_all, collapse = " "), "\n")
}, error = function(e) message("Cannot read returns data: ", conditionMessage(e)))

pick <- function(nms, cands) { for (cc in cands) if (cc %in% nms) return(cc); NA_character_ }
ind <- function(x) {
  if (is.numeric(x) || is.logical(x)) {
    v <- as.numeric(x)
    return(ifelse(is.na(v), NA_real_, as.numeric(v > 0)))
  }
  s <- tolower(trimws(as.character(x)))
  out <- rep(NA_real_, length(s))
  out[s %in% c("yes", "1", "true", "y")] <- 1
  out[s %in% c("no", "0", "false", "n")] <- 0
  out
}
to_week <- function(x) {
  if (inherits(x, "POSIXt")) x <- as.Date(x)
  if (inherits(x, "Date")) {
    yr <- as.integer(format(x, "%Y")); doy <- as.integer(format(x, "%j"))
    return(yr * 100 + pmin(52L, (doy - 1L) %/% 7L + 1L))
  }
  if (is.numeric(x)) {
    xx <- x[!is.na(x)]
    if (length(xx) && all(xx <= 60)) return(x)
    if (length(xx) && median(xx) > 1e9) return(to_week(as.Date(x / 86400000, origin = "1960-01-01")))
    return(to_week(as.Date(x, origin = "1960-01-01")))
  }
  s <- strv(x)
  for (f in c("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%d%b%Y", "%d-%b-%Y", "%b %d, %Y", "%d.%m.%Y")) {
    dt <- as.Date(s, format = f)
    if (sum(!is.na(dt)) >= 0.5 * sum(s != "") && sum(!is.na(dt)) > 0) return(to_week(dt))
  }
  suppressWarnings(as.numeric(s))
}

if (!is.null(rd)) {
  idv <- pick(names(rd), c("hhh_id", "hhh", "hh_id", "id"))
  eav <- pick(names(rd), c("ea_code", "ea", "village", "village_id", "ea_id"))
  if (is.na(eav)) { g <- grep("ea_code|village", names(rd), value = TRUE); if (length(g)) eav <- g[1] }
  cat("ID var:", idv, " village var:", eav, "\n")
  hid <- rd[[idv]]
  eac <- strv(rd[[eav]])
  trt <- num(rd$treatment)
  cat("Treatment counts:\n"); print(table(trt, useNA = "ifany"))

  # ---------------- Column 1: visually verifiable defects (bag level)
  tryCatch({
    pre <- grep("^defects_visual_tot_[0-9]+$", names(rd), value = TRUE)
    long <- NULL
    if (length(pre)) {
      long <- do.call(rbind, lapply(pre, function(v) data.frame(hhh_id = hid, ea_code = eac, treatment = trt,
                                                                 bag = as.integer(sub(".*_", "", v)), y = num(rd[[v]]))))
    } else {
      a4 <- grep("^add4_[a-z]+_[0-9]+$", names(rd), value = TRUE)
      st <- sub("^add4_([a-z]+)_[0-9]+$", "\\1", a4)
      bg <- as.integer(sub("^.*_([0-9]+)$", "\\1", a4))
      cat("add4 stems:", paste(unique(st), collapse = " "), "\n")
      defect_stems <- unique(st[grepl("dirt|cob|stone|dust|insect|broken|immature|damag|rot|mold|mould|soil", st)])
      cat("Defect stems used:", paste(defect_stems, collapse = " "), "\n")
      if (length(defect_stems)) {
        cat("Value table, first defect stem bag 1:\n")
        fv <- paste0("add4_", defect_stems[1], "_1")
        if (fv %in% names(rd)) print(table(rd[[fv]], useNA = "ifany"))
      }
      bags <- sort(unique(bg[st %in% defect_stems]))
      long <- do.call(rbind, lapply(bags, function(b) {
        vs <- paste0("add4_", defect_stems, "_", b)
        vs <- vs[vs %in% names(rd)]
        tot <- rowtot_list(lapply(vs, function(v) ind(rd[[v]])), nrow(rd))
        data.frame(hhh_id = hid, ea_code = eac, treatment = trt, bag = b, y = tot)
      }))
    }
    long <- long[!is.na(long$y) & !is.na(long$treatment), ]
    m1 <- feols(y ~ treatment | ea_code, data = long, cluster = ~hhh_id, fixef.rm = "none")
    cat(sprintf("Table2 col1: b=%.4f se=%.4f N=%d control mean=%.3f\n", coef(m1)["treatment"], se(m1)["treatment"],
                nobs(m1), mean(long$y[long$treatment == 0])))
    add_result("treatment_defects_visual_table2_col1", coef(m1)["treatment"])
    add_result("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) message("Table 2 col 1 failed: ", conditionMessage(e)))

  # ---------------- Column 2: lab defects share (lab variables are in the returns data itself)
  tryCatch({
    nmr <- names(rd)
    fcol <- function(re) {
      g <- grep(re, nmr, value = TRUE, ignore.case = TRUE)
      if (length(g) > 1) cat("  multiple matches for", re, ":", paste(g, collapse = " "), "\n")
      if (length(g)) g[1] else NA_character_
    }
    tw <- fcol("^Total_weight_of_maize")
    comps <- c(fcol("^Foreign_matter"), fcol("^Inorganic_matter"), fcol("^Broken_grain"),
               fcol("^Pest_damaged"), fcol("^Rotten_and_diseased"), fcol("^Discoloured"),
               fcol("^Immature_or_shrivel"))
    comps <- comps[!is.na(comps)]
    cat("Lab total weight:", tw, " components:", paste(comps, collapse = " "), "\n")
    if (is.na(tw) || !length(comps)) stop("lab variables not found in returns data")
    tot <- num(rd[[tw]])
    s <- rowtot_list(lapply(comps, function(v) num(rd[[v]])), nrow(rd))
    s[is.na(tot) | tot <= 0] <- NA_real_
    lab <- data.frame(hhh_id = hid, ea_code = eac, treatment = trt, y = fin(s / tot))
    lab <- lab[!is.na(lab$y) & !is.na(lab$treatment), ]
    cat("Lab share summary:\n"); print(summary(lab$y))
    if (length(unique(lab$ea_code)) > 1) {
      m2 <- feols(y ~ treatment | ea_code, data = lab, vcov = "hetero", fixef.rm = "none")
    } else {
      m2 <- feols(y ~ treatment, data = lab, vcov = "hetero")
    }
    cat(sprintf("Table2 col2: b=%.4f se=%.4f N=%d control mean=%.3f\n", coef(m2)["treatment"], se(m2)["treatment"],
                nobs(m2), mean(lab$y[lab$treatment == 0])))
    add_result("treatment_defects_lab_table2_col2", coef(m2)["treatment"])
  }, error = function(e) message("Table 2 col 2 failed: ", conditionMessage(e)))

  # ---------------- Columns 3-5: sales (add5_ppk = price per kg, add5_sold_when_e = sale date,
  # add5_ind_weight<bag>_<sale> = measured bag weight y, add5_ind_ded_weight<bag>_<sale> = deducted/paid weight)
  tryCatch({
    nmr <- names(rd)
    pcols <- grep("^add5_ppk(_[0-9]+)?$", nmr, value = TRUE)
    if (!length(pcols)) stop("no add5_ppk price variables")
    sfx_of <- function(v, stem) sub(paste0("^", stem), "", v)
    sale_list <- list(); bag_list <- list()
    for (pc in pcols) {
      sfx <- sfx_of(pc, "add5_ppk")
      j <- if (sfx == "") 1L else as.integer(sub("^_", "", sfx))
      wc <- paste0("add5_sold_when_e", sfx)
      wk <- if (wc %in% nmr) to_week(rd[[wc]]) else rep(NA_real_, nrow(rd))
      sale_list[[length(sale_list) + 1]] <- data.frame(row = seq_len(nrow(rd)), salenum = j,
                                                       price = num(rd[[pc]]), week = wk)
      iwc <- grep(paste0("^add5_ind_weight[0-9]+", sfx, "$"), nmr, value = TRUE)
      for (v in iwc) {
        b <- as.integer(sub(paste0("^add5_ind_weight([0-9]+)", sfx, "$"), "\\1", v))
        dv <- paste0("add5_ind_ded_weight", b, sfx)
        bag_list[[length(bag_list) + 1]] <- data.frame(row = seq_len(nrow(rd)), salenum = j, bag = b,
                                                       iw = num(rd[[v]]),
                                                       dw = if (dv %in% nmr) num(rd[[dv]]) else NA_real_)
      }
    }
    sales <- do.call(rbind, sale_list)
    bags <- do.call(rbind, bag_list)
    bags <- bags[!is.na(bags$iw) & bags$iw > 0, ]
    both <- !is.na(bags$dw)
    ratio <- if (any(both)) sum(bags$dw[both]) / sum(bags$iw[both]) else NA_real_
    cat("Bag-level rows:", nrow(bags), " with ded weight:", sum(both), " sum(ded)/sum(ind) =", ratio, "\n")
    if (is.finite(ratio) && ratio > 0.5) {
      # ded_weight is the weight after deduction (z); missing -> no deduction
      bags$z <- ifelse(is.na(bags$dw), bags$iw, bags$dw)
      cat("NOTE: add5_ind_ded_weight interpreted as weight paid for (after deduction)\n")
    } else {
      # ded_weight is the amount deducted; missing -> zero deduction
      bags$z <- bags$iw - ifelse(is.na(bags$dw), 0, bags$dw)
      cat("NOTE: add5_ind_ded_weight interpreted as kg deducted\n")
    }
    key_b <- paste(bags$row, bags$salenum)
    ysum <- tapply(bags$iw, key_b, sum)
    zsum <- tapply(bags$z, key_b, sum)
    key_s <- paste(sales$row, sales$salenum)
    sales$ykg <- as.numeric(ysum[key_s])
    sales$zkg <- as.numeric(zsum[key_s])
    sales$deduct <- fin((sales$ykg - sales$zkg) / sales$ykg * 100)
    sales$netprice <- fin(sales$price * sales$zkg / sales$ykg)
    sales$hhh_id <- hid[sales$row]
    sales$ea_code <- eac[sales$row]
    sales$treatment <- trt[sales$row]
    sales <- sales[!is.na(sales$price) & !is.na(sales$treatment), ]
    cat("Sales with price:", nrow(sales), " households:", length(unique(sales$hhh_id)), "\n")
    print(table(sales$salenum))
    cat("Price summary:\n"); print(summary(sales$price))
    cat("Deduction summary:\n"); print(summary(sales$deduct))
    cat("Week values:\n"); print(table(sales$week, useNA = "ifany"))
    cat("Control mean price:", mean(sales$price[sales$treatment == 0]), "\n")
    has_week <- sum(!is.na(sales$week)) > 0
    fml <- function(dep) {
      if (has_week) as.formula(paste(dep, "~ treatment | ea_code + week"))
      else as.formula(paste(dep, "~ treatment | ea_code"))
    }
    if (!has_week) cat("WARNING: no week-of-sale variable found; using village FE only\n")
    m3 <- feols(fml("price"), data = sales, cluster = ~hhh_id, fixef.rm = "none")
    cat(sprintf("Table2 col3: b=%.4f se=%.4f N=%d\n", coef(m3)["treatment"], se(m3)["treatment"], nobs(m3)))
    add_result("treatment_price_table2_col3", coef(m3)["treatment"])
    add_result("n_obs_table2_cols3_5_sales", nobs(m3))
    if (sum(!is.na(sales$deduct)) > 0) {
      m4 <- feols(fml("deduct"), data = sales, cluster = ~hhh_id, fixef.rm = "none")
      cat(sprintf("Table2 col4: b=%.4f se=%.4f N=%d\n", coef(m4)["treatment"], se(m4)["treatment"], nobs(m4)))
      add_result("treatment_deductions_table2_col4", coef(m4)["treatment"])
    }
    if (sum(!is.na(sales$netprice)) > 0) {
      m5 <- feols(fml("netprice"), data = sales, cluster = ~hhh_id, fixef.rm = "none")
      cat(sprintf("Table2 col5: b=%.4f se=%.4f N=%d\n", coef(m5)["treatment"], se(m5)["treatment"], nobs(m5)))
      add_result("treatment_net_price_table2_col5", coef(m5)["treatment"])
    }
  }, error = function(e) message("Table 2 cols 3-5 failed: ", conditionMessage(e)))
}

# ==================================================================
# Output
# ==================================================================
order_names <- c("treatment_defects_visual_table2_col1", "treatment_defects_lab_table2_col2",
                 "treatment_price_table2_col3", "treatment_deductions_table2_col4",
                 "treatment_net_price_table2_col5", "n_obs_table2_col1_bags", "n_obs_table2_cols3_5_sales",
                 "market_access_price_table6_panelA_col1", "market_access_yield_table6_panelA_col4",
                 "market_access_harvest_value_table6_panelA_col5", "market_access_profit_monetary_table6_panelA_col7",
                 "market_access_profit_incl_own_hours_table6_panelA_col8", "n_obs_table6_panelA_cols3_5")
for (nm in order_names) {
  if (!is.null(results[[nm]])) cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}