suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading"
results <- list()
emit <- function(name, value) {
  if (!is.null(value) && length(value) == 1 && is.finite(value)) results[[name]] <<- value
}

# ---------------------------------------------------------------
# Generic helpers (Stata semantics)
# ---------------------------------------------------------------
read_clean <- function(path) {
  x <- haven::read_dta(path)
  x <- haven::zap_labels(x)
  x <- haven::zap_formats(x)
  as.data.frame(x, stringsAsFactors = FALSE)
}
to_num <- function(x) {
  if (is.character(x)) suppressWarnings(as.numeric(x)) else as.numeric(x)
}
to_str <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}
TT <- function(x) !is.na(x) & x   # Stata: missing condition -> false
stata_round1 <- function(x) floor(x + 0.5)
finite_or_na <- function(x) { x[!is.finite(x)] <- NA; x }

# ---------------------------------------------------------------
# PART A: Table 6 Panel A (market access experiment, group 1)
# ---------------------------------------------------------------
tab6 <- tryCatch({
  d <- read_clean(file.path(base_dir, "data/raw/panel_g1.dta"))
  n <- nrow(d)
  has <- function(v) v %in% names(d)
  num <- function(v) if (has(v)) to_num(d[[v]]) else rep(NA_real_, n)
  str <- function(v) if (has(v)) to_str(d[[v]]) else rep("", n)
  pat <- function(re) grep(re, names(d), value = TRUE)
  rowtot <- function(vars, cond = NULL) {
    vars <- unique(vars[vars %in% names(d)])
    if (length(vars) == 0) {
      r <- rep(NA_real_, n)
    } else {
      m <- matrix(sapply(vars, function(v) to_num(d[[v]])), nrow = n)
      r <- rowSums(m, na.rm = TRUE)
      r[rowSums(!is.na(m)) == 0] <- NA
    }
    if (!is.null(cond)) r[!TT(cond)] <- NA
    r
  }
  rowmed <- function(vars) {
    vars <- unique(vars[vars %in% names(d)])
    if (length(vars) == 0) return(rep(NA_real_, n))
    m <- matrix(sapply(vars, function(v) to_num(d[[v]])), nrow = n)
    r <- apply(m, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) median(z) else NA_real_ })
    r
  }
  stata_mode <- function(x) {
    x <- x[!is.na(x)]
    if (!length(x)) return(NA_real_)
    t <- table(x)
    m <- names(t)[t == max(t)]
    if (length(m) > 1) return(NA_real_)
    as.numeric(m)
  }
  repl <- function(v, value, cond) {
    cur <- if (has(v)) to_num(d[[v]]) else rep(NA_real_, n)
    cond <- TT(cond)
    value <- rep_len(value, n)
    cur[cond] <- value[cond]
    d[[v]] <<- cur
  }

  ss <- num("survey_season")
  fu <- str("form_used")
  phone <- fu == "Phone_Market_Survey_spring2020"
  mkt20 <- fu == "Market_Survey_spring2020"
  hid <- num("hhh_id")
  sdum <- function(name, s) if (has(name)) TT(num(name) == 1) else TT(ss == s)
  s_f17 <- sdum("season_fall2017", 2); s_s18 <- sdum("season_spring2018", 3)
  s_f18 <- sdum("season_fall2018", 4); s_s19 <- sdum("season_spring2019", 5)
  s_f19 <- sdum("season_fall2019", 6); s_s20 <- sdum("season_spring2020", 7)
  ss_ge <- function(k) is.na(ss) | ss >= k   # Stata: missing >= k is true

  # acreage
  d$acreage <- rowtot(pat("^plot_size_.{1,2}$"))
  repl("acreage", 0, is.na(d$acreage) & TT(num("maize_tot_plotn") == 0))
  repl("acreage", num("acres_tot"), TT(ss == 7) & phone)
  acre <- function() d$acreage
  acre_ne0 <- function() is.na(d$acreage) | d$acreage != 0
  acre_eq0 <- function() TT(d$acreage == 0)

  d$equipment_cost_tot <- rowtot(pat("^equipment_cost_.$"), ss == 3)
  d$tot_chem_costs <- rowtot(pat("^tot_chem_costs_.$"))

  d$seeds_cost_tot <- rowtot(pat("^seeds_cost_.$"), ss_ge(2))
  repl("seeds_cost_tot", num("seeds_cost"), TT(ss == 7) & phone)

  d$fert_cost_tot <- rowtot(pat("^fert_cost_.$"), ss_ge(2))
  repl("fert_cost_tot", num("fert_cost"), TT(ss == 7) & phone)

  d$manure_cost_tot <- rowtot(pat("^manure_cost_.$"), ss_ge(2))
  d$booster_cost_tot <- rowtot(pat("^booster_cost_.$"), ss_ge(2))
  repl("booster_cost_tot", num("booster_cost"), TT(ss == 7) & phone)
  repl("manure_cost_tot", 0, is.na(d$manure_cost_tot) & acre_ne0() & !is.na(acre()) &
         (TT(ss == 4) | TT(ss == 6) | (TT(ss == 7) & mkt20)))

  d$harvest_cost_tot <- rowtot(pat("^harvest_cost_.$"), TT(ss == 2) | TT(ss == 3))

  # harvest and yield
  d$harvest_kg_tot <- rowtot(pat("^harvest_kg_.$"))
  repl("harvest_kg_tot", num("harvest_kg"), sdum("season_spring2020", 7) & phone)
  d$yield <- finite_or_na(d$harvest_kg_tot / d$acreage)
  repl("yield", finite_or_na(num("harvest_kg_1") / num("plot_size_1")), TT(hid == 10247005) & s_s18)
  repl("yield", finite_or_na(num("harvest_kg_2") / num("plot_size_2")),
       (TT(hid == 10165041) | TT(hid == 10231013)) & TT(ss == 5))

  # post-harvest costs
  repl("storage_cost", NA, acre_eq0())
  repl("drying_cost", NA, acre_eq0())
  repl("otherph_cost", NA, acre_eq0())
  d$decobbing_cost_tot <- rowtot(pat("^decobbing_cost_.$"), ss == 2)
  repl("decobbing_cost_tot", NA, acre_eq0())

  # labor costs
  for (a in c("prep", "plant", "weed", "spray", "harv")) {
    v <- paste0("labor_cost_", a, "_tot")
    d[[v]] <- rowtot(pat(paste0("^lc_", a, "_costs_season.$")), is.na(ss) | ss != 1)
    repl(v, 0, is.na(d[[v]]) & acre_ne0() & !is.na(acre()) & TT(ss == 5))
  }
  repl("labor_cost_ph", NA, acre_eq0())
  repl("labor_cost_store", 0, is.na(num("labor_cost_store")) & str("storage") != "" & ss_ge(5))

  d$expenses_labor_preharvest_ugx <- rowtot(
    c("labor_cost_prep_tot", "labor_cost_plant_tot", "labor_cost_spray_tot", "labor_cost_weed_tot"),
    (is.na(ss) | (ss != 1 & ss != 4)) & !phone)
  d$tot_lab_costs_preh_aggh_tot <- rowtot(pat("^tot_lab_costs_.$"), ss_ge(4))
  repl("tot_lab_costs_preh_aggh_tot", d$expenses_labor_preharvest_ugx + d$labor_cost_harv_tot,
       TT(ss == 2) | TT(ss == 3))

  # labor hours
  for (a in c("prep", "plant", "spray", "weed", "harv")) {
    v <- paste0(a, "_unpaid_lab_tothrs")
    d[[v]] <- rowtot(pat(paste0("^lh_", a, "_hours_season.$")), ss_ge(5))
  }
  repl("spray_unpaid_lab_tothrs", 0, is.na(d$spray_unpaid_lab_tothrs) & acre_ne0() & !is.na(acre()) & TT(ss == 5))
  d$tot_lab_hours_preh_aggh_tot <- rowtot(paste0(c("prep", "plant", "weed", "spray", "harv"), "_unpaid_lab_tothrs"), ss_ge(5))

  # hourly wage
  medc <- list(); medh <- list()
  for (a in c("prep", "plant", "weed", "harv")) {
    dc <- list(); dh <- list()
    for (k in 1:6) {
      if (has(paste0("lc_", a, "_unit", k))) {
        x <- num(paste0("lc_", a, "_costs_unit", k))
        x[str(paste0("lc_", a, "_unit", k)) != "days"] <- NA
        dc[[length(dc) + 1]] <- x
      }
      if (has(paste0("lh_", a, "_hours_unit", k))) {
        x <- num(paste0("lh_", a, "_hours_unit", k))
        x[str(paste0("lh_", a, "_unit", k)) != "days"] <- NA
        dh[[length(dh) + 1]] <- x
      }
    }
    rm_ <- function(lst) {
      if (!length(lst)) return(rep(NA_real_, n))
      m <- do.call(cbind, lst)
      apply(m, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) median(z) else NA_real_ })
    }
    medc[[a]] <- rm_(dc); medh[[a]] <- rm_(dh)
  }
  rmed_list <- function(lst) {
    m <- do.call(cbind, lst)
    apply(m, 1, function(z) { z <- z[!is.na(z)]; if (length(z)) median(z) else NA_real_ })
  }
  dailyhours <- stata_mode(rmed_list(medh))
  dailywage <- stata_mode(rmed_list(medc))
  hourlywage <- stata_round1(dailywage / dailyhours)
  if (!is.finite(hourlywage)) hourlywage <- 833
  cat(sprintf("Hourly wage (UGX): %s (daily wage %s, daily hours %s)\n", hourlywage, dailywage, dailyhours))
  d$preh_unpaid_lab_aggh_sh <- d$tot_lab_hours_preh_aggh_tot * hourlywage

  # post-harvest activities
  acts <- c("decob", "winnow", "sort", "bag")
  for (a in acts) {
    s <- str(a)
    x <- ifelse(s == "yes", 1, 0); x[s == "" | !ss_ge(5)] <- NA
    d[[paste0(a, "_d")]] <- x
  }
  for (a in acts) {
    dnm <- !is.na(d[[paste0(a, "_d")]])
    for (v in c(paste0("lh_", a, "_hours"), paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_other_costs"))) {
      repl(v, 0, is.na(num(v)) & dnm & ss_ge(5))
    }
  }
  for (a in acts) {
    x <- num(paste0("lh_", a, "_hours")) * 833
    x[!ss_ge(5)] <- NA
    d[[paste0("lh_", a, "_hours_sh")]] <- x
  }
  for (a in acts) {
    v <- paste0("lc_", a, "_lmtot_costs")
    x <- num(paste0("lc_", a, "_labmaize_costs")) * num(paste0("lc_", a, "_price"))
    x[!ss_ge(5)] <- NA
    d[[v]] <- x
    repl(v, 0, is.na(d[[v]]) & !is.na(d[[paste0(a, "_d")]]) & ss_ge(5))
  }
  repl("lc_decob_lmtot_costs", num("lc_decob_labmaize_costs"), TT(hid == 10247077) & TT(ss == 7))
  repl("lc_bag_lmtot_costs", num("lc_bag_labmaize_costs"), TT(hid == 10247013) & TT(ss == 7))
  for (a in acts) {
    d[[paste0(a, "_cost_tot")]] <- rowtot(c(paste0("lc_", a, "_labour_costs"), paste0("lc_", a, "_lmtot_costs"),
                                            paste0("lc_", a, "_other_costs")))
  }

  # sales
  d$sold_kg_tot <- rowtot(pat("^sold_kg_p_.$"))
  repl("sold_kg_tot", num("sold_kg"), TT(ss == 7) & phone)
  sr <- num("survey_round")
  sc <- str("sold_crop")
  hk <- function() !is.na(d$harvest_kg_tot)
  repl("sold_kg_tot", 0, TT(hid == 10249047) & TT(ss == 1))
  repl("sold_kg_tot", 0, TT(hid == 10328006) & TT(ss == 1))
  repl("sold_kg_tot", 0, TT(hid == 10165056) & TT(ss == 2) & TT(sr == 1))
  repl("sold_kg_tot", 0, TT(hid == 10235011) & TT(ss == 2) & TT(sr == 1))
  repl("sold_kg_tot", 0, hk() & is.na(d$sold_kg_tot) & TT(ss == 2) & TT(sr == 2))
  repl("sold_kg_tot", 0, hk() & is.na(d$sold_kg_tot) & TT(ss == 3))
  repl("sold_kg_tot", 0, hk() & is.na(d$sold_kg_tot) & TT(ss == 5) & sc == "no")
  repl("sold_kg_tot", 0, hk() & is.na(d$sold_kg_tot) & TT(ss == 6) & sc == "no")
  repl("sold_kg_tot", 0, hk() & is.na(d$sold_kg_tot) & TT(ss == 7) & sc == "no" & mkt20)
  repl("sold_kg_tot", NA, TT(hid == 10235035) & sdum("season_spring2020", 7))
  ids4 <- c(10078042, 10181008, 10181009, 10231001, 10247021, 10326064, 10328005, 10328014, 10328034, 10350040)
  repl("sold_kg_tot", 0, hid %in% ids4 & TT(ss == 4))
  repl("sold_kg_tot", 0, hid %in% c(10219013, 10231002, 10354079) & TT(ss == 5))

  # transport
  for (k in c(1, 2, 3, 5)) {
    v <- paste0("sale_transport_cost_", k)
    if (has(v)) repl(v, 0, str(paste0("sale_transport_yn_", k)) == "no" & ss_ge(3))
  }
  d$sale_transport_cost_tot <- rowtot(pat("^sale_transport_cost_.$"), ss_ge(3))

  # revenue and price
  d$rev_tot <- rowtot(c(pat("^tot_rev_combined_._.$"), pat("^tot_rev_combined_.$")))
  repl("rev_tot", num("tot_rev_told_tot"), phone)
  repl("rev_tot", 0, hk() & is.na(d$rev_tot) & TT(d$sold_kg_tot == 0))
  d$price_ugx <- finite_or_na(d$rev_tot / d$sold_kg_tot)

  grp_key <- paste(to_str(d$ea_code), ss, sep = "_")
  pv <- ave(d$price_ugx, grp_key, FUN = function(z) { m <- mean(z, na.rm = TRUE); if (is.nan(m)) NA_real_ else m })
  d$price_vm <- pv

  d$remainder <- d$harvest_kg_tot - d$sold_kg_tot
  hv <- rep(NA_real_, n)
  ok <- is.na(d$remainder) | d$remainder >= 0
  hv[ok] <- (d$rev_tot + d$remainder * d$price_vm)[ok]
  neg <- TT(d$remainder < 0)
  hv[neg] <- (d$harvest_kg_tot * d$price_ugx)[neg]
  fixr <- TT(hid == 10249026) & TT(ss == 3)
  hv[fixr] <- (d$harvest_kg_tot * d$price_vm)[fixr]
  d$harvest_value_ugx <- hv

  # expenses
  v_f17 <- c("seeds_cost_tot", "fert_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
             "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "harvest_cost_tot", "decobbing_cost_tot",
             "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "cost_transportpre", "cost_transportpost")
  v_s18 <- c("seeds_cost_tot", "fert_cost_tot", "manure_cost_tot", "booster_cost_tot", "equipment_cost_tot",
             "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "tot_chem_costs", "harvest_cost_tot",
             "storage_cost", "drying_cost", "otherph_cost", "labor_cost_ph", "labor_cost_dry", "labor_cost_store",
             "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot")
  v_f18 <- c("fert_cost_tot", "tot_chem_costs", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot",
             "tot_lab_costs_preh_aggh_tot", "drying_cost", "storage_cost", "labor_cost_store", "otherph_cost",
             "labor_cost_ph", "tot_transport_cost", "sale_transport_cost_tot")
  v_post <- c("fert_cost_tot", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot", "tot_chem_costs",
              "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "drying_cost", "storage_cost", "labor_cost_store",
              "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot", "decob_cost_tot", "sort_cost_tot",
              "winnow_cost_tot", "bag_cost_tot")
  v_hrs <- c("fert_cost_tot", "tot_chem_costs", "seeds_cost_tot", "booster_cost_tot", "manure_cost_tot",
             "expenses_labor_preharvest_ugx", "labor_cost_harv_tot", "preh_unpaid_lab_aggh_sh", "drying_cost",
             "storage_cost", "labor_cost_store", "cost_transportpre", "cost_transportpost", "sale_transport_cost_tot",
             "lh_decob_hours_sh", "lh_sort_hours_sh", "lh_winnow_hours_sh", "lh_bag_hours_sh", "decob_cost_tot",
             "sort_cost_tot", "winnow_cost_tot", "bag_cost_tot")
  allv <- unique(c(v_f17, v_s18, v_f18, v_post, v_hrs))
  miss <- allv[!allv %in% names(d)]
  if (length(miss)) cat("Note: expense components not found in panel_g1:", paste(miss, collapse = " "), "\n")

  e_f17 <- rowtot(v_f17, ss == 2)
  e_s18 <- rowtot(v_s18, ss == 3)
  e_f18 <- rowtot(v_f18, ss == 4)
  e_s19 <- rowtot(v_post, ss == 5)
  e_f19 <- rowtot(v_post, ss == 6)
  e_s20 <- rowtot(v_post, TT(ss == 7) & mkt20)
  h_s19 <- rowtot(v_hrs, ss == 5)
  h_f19 <- rowtot(v_hrs, ss == 6)
  h_s20 <- rowtot(v_hrs, TT(ss == 7) & mkt20)

  ex <- rep(NA_real_, n)
  ex[s_f17] <- e_f17[s_f17]; ex[s_s18] <- e_s18[s_s18]; ex[s_f18] <- e_f18[s_f18]
  ex[s_s19] <- e_s19[s_s19]; ex[s_f19] <- e_f19[s_f19]; ex[s_s20] <- e_s20[s_s20]
  ex[s_s20 & phone] <- NA
  exh <- rep(NA_real_, n)
  exh[s_s19] <- h_s19[s_s19]; exh[s_f19] <- h_f19[s_f19]; exh[s_s20] <- h_s20[s_s20]
  exh[s_f17] <- e_f17[s_f17]; exh[s_s18] <- e_s18[s_s18]
  d$expenses_ugx <- ex
  d$expenses_hours_ugx <- exh
  d$surplus_ugx <- d$harvest_value_ugx - d$expenses_ugx
  d$surplus_hrs_ugx <- d$harvest_value_ugx - d$expenses_hours_ugx

  rate <- c(3575, 3601, 3626, 3758, 3670, 3685, 3681, 3685)[ss]
  for (v in c("price", "harvest_value", "expenses", "surplus", "surplus_hrs")) {
    d[[v]] <- d[[paste0(v, "_ugx")]] / rate
  }

  # analysis sample
  d$ss <- ss
  d$hid <- hid
  d$buy_treatment <- num("buy_treatment")
  d$ea_code_c <- to_str(d$ea_code)
  ante <- if (has("season_ante")) TT(num("season_ante") == 1) else TT(ss <= 3)
  post <- if (has("season_post")) TT(num("season_post") == 1) else TT(ss >= 4)
  grp1 <- if (has("group")) TT(num("group") == 1) else rep(TRUE, n)
  d$ante <- ante; d$post <- post; d$grp1 <- grp1; d$s_s18 <- s_s18

  ancova <- function(var) {
    y <- d[[var]]
    m3 <- tapply(ifelse(d$s_s18 & d$grp1, y, NA), d$hid, function(z) { z <- z[!is.na(z)]; if (length(z)) mean(z) else NA_real_ })
    ma <- tapply(ifelse(d$ante & d$grp1, y, NA), d$hid, function(z) { z <- z[!is.na(z)]; if (length(z)) mean(z) else NA_real_ })
    p3 <- as.numeric(m3[as.character(d$hid)])
    pa <- as.numeric(ma[as.character(d$hid)])
    p3[is.na(p3)] <- pa[is.na(p3)]
    dd <- data.frame(y = y, treat = d$buy_treatment, p3 = p3, ss = factor(d$ss), ea = d$ea_code_c)
    dd <- dd[d$grp1 & d$post, ]
    dd <- dd[complete.cases(dd), ]
    m <- feols(y ~ treat + p3 + ss, data = dd, cluster = ~ea)
    list(b = unname(coef(m)["treat"]), se = unname(sqrt(diag(vcov(m)))["treat"]), n = nobs(m))
  }
  out <- list()
  for (v in c("price", "harvest_kg_tot", "yield", "harvest_value", "surplus", "surplus_hrs")) {
    out[[v]] <- tryCatch(ancova(v), error = function(e) { cat("ANCOVA error for", v, ":", conditionMessage(e), "\n"); NULL })
    if (!is.null(out[[v]])) cat(sprintf("Table6A %s: b=%.4f se=%.4f N=%d\n", v, out[[v]]$b, out[[v]]$se, out[[v]]$n))
  }
  out
}, error = function(e) { cat("Table 6 block error:", conditionMessage(e), "\n"); NULL })

if (!is.null(tab6)) {
  if (!is.null(tab6$price)) emit("market_access_price_table6_panelA_col1", tab6$price$b)
  if (!is.null(tab6$yield)) emit("market_access_yield_table6_panelA_col4", tab6$yield$b)
  if (!is.null(tab6$harvest_value)) emit("market_access_harvest_value_table6_panelA_col5", tab6$harvest_value$b)
  if (!is.null(tab6$surplus)) emit("market_access_profit_monetary_table6_panelA_col7", tab6$surplus$b)
  if (!is.null(tab6$surplus_hrs)) emit("market_access_profit_incl_own_hours_table6_panelA_col8", tab6$surplus_hrs$b)
  if (!is.null(tab6$harvest_kg_tot)) emit("n_obs_table6_panelA_cols3_5", tab6$harvest_kg_tot$n)
}

# ---------------------------------------------------------------
# PART B: Table 2 (returns to quality experiment)
# ---------------------------------------------------------------
rq <- tryCatch(read_clean(file.path(base_dir, "data/raw/anonym_returns_data.dta")),
               error = function(e) { cat("Cannot read returns data:", conditionMessage(e), "\n"); NULL })

if (!is.null(rq)) {
  nr <- nrow(rq)
  nonbag <- grep("^add4_|^add5_ind_", names(rq), value = TRUE, invert = TRUE)
  cat("Returns data columns (excluding add4_ and add5_ind_ columns):\n")
  cat(paste(nonbag, collapse = " "), "\n")

  if ("quasicontrol" %in% names(rq)) rq <- rq[TT(to_num(rq$quasicontrol) == 0), , drop = FALSE]
  nr <- nrow(rq)
  idv <- intersect(c("hhh_id", "hhh", "hhid", "hh_id", "id"), names(rq))[1]
  eav <- intersect(c("ea_code", "ea", "village", "village_code"), names(rq))[1]
  cat("ID var:", idv, " village var:", eav, "\n")
  rq$.id <- if (!is.na(idv)) to_str(rq[[idv]]) else as.character(seq_len(nr))
  rq$.ea <- if (!is.na(eav)) to_str(rq[[eav]]) else "1"
  rq$.treat <- to_num(rq$treatment)

  find_stub <- function(patterns) {
    for (p in patterns) {
      cols <- grep(p, names(rq), value = TRUE, perl = TRUE)
      if (length(cols)) {
        idx <- as.integer(sub(p, "\\1", cols, perl = TRUE))
        names(cols) <- idx
        return(cols[order(idx)])
      }
    }
    NULL
  }
  to01 <- function(x) {
    if (is.character(x)) {
      s <- tolower(trimws(x))
      out <- rep(NA_real_, length(s))
      out[s %in% c("yes", "1", "true", "y")] <- 1
      out[s %in% c("no", "0", "false", "n")] <- 0
      return(out)
    }
    x <- as.numeric(x)
    u <- unique(x[!is.na(x)])
    if (all(u %in% c(0, 1))) return(x)
    if (all(u %in% c(1, 2))) return(ifelse(is.na(x), NA, as.numeric(x == 1)))
    ifelse(is.na(x), NA, as.numeric(x > 0))
  }

  # ---- Column 1: visual defects, bag level ----
  try({
    vis <- find_stub(c("^defects_visual_tot_([0-9]+)$"))
    long <- NULL
    if (!is.null(vis)) {
      long <- do.call(rbind, lapply(names(vis), function(k)
        data.frame(id = rq$.id, ea = rq$.ea, treat = rq$.treat, bag = as.integer(k), y = to_num(rq[[vis[[k]]]]))))
    } else {
      a4 <- grep("^add4_[a-z_]+_[0-9]+$", names(rq), value = TRUE)
      types <- sub("^add4_(.*)_([0-9]+)$", "\\1", a4)
      kw <- "dirt|cob|stone|dust|insect|broken|immature|damag|rotten|rot|mold|mould"
      keep <- grepl(kw, types)
      cat("add4 defect types used:", paste(unique(types[keep]), collapse = " "), "\n")
      cat("add4 types not used:", paste(unique(types[!keep]), collapse = " "), "\n")
      a4 <- a4[keep]
      bagn <- as.integer(sub("^add4_(.*)_([0-9]+)$", "\\2", a4))
      long <- do.call(rbind, lapply(sort(unique(bagn)), function(k) {
        cols <- a4[bagn == k]
        m <- matrix(sapply(cols, function(cn) to01(rq[[cn]])), nrow = nr)
        y <- rowSums(m, na.rm = TRUE)
        y[rowSums(!is.na(m)) == 0] <- NA
        data.frame(id = rq$.id, ea = rq$.ea, treat = rq$.treat, bag = k, y = y)
      }))
    }
    long <- long[!is.na(long$y) & !is.na(long$treat), ]
    m1 <- feols(y ~ treat | ea, data = long, cluster = ~id, fixef.rm = "none")
    cat(sprintf("Table2 col1: b=%.4f se=%.4f N=%d hh=%d\n", coef(m1)["treat"], se(m1)["treat"], nobs(m1), length(unique(long$id))))
    emit("treatment_defects_visual_table2_col1", unname(coef(m1)["treat"]))
    emit("n_obs_table2_col1_bags", nobs(m1))
  })

  # ---- Column 2: lab defects share ----
  try({
    labv <- intersect(c("defects_lab_share_r", "defects_lab_share"), names(rq))[1]
    if (!is.na(labv)) {
      ylab <- to_num(rq[[labv]])
    } else {
      # Column names in the data are e.g. Broken_grains_tot_g, Pest_damaged_grains_tot_g,
      # Rotten_and_diseased_grain, ...: match case-insensitively ignoring underscores.
      nmr <- names(rq)
      nnorm <- tolower(gsub("[^A-Za-z]", "", nmr))
      okc <- !grepl("^add[0-9]", nmr)
      fnd <- function(s) { i <- which(okc & grepl(s, nnorm, fixed = TRUE)); if (length(i)) nmr[i[1]] else NA_character_ }
      stems <- c("brokengrain", "pestdamaged", "rottenanddiseased", "immatureorshrivel", "discoloured",
                 "foreignmatter", "inorganicmatter")
      comp <- unname(sapply(stems, fnd))
      comp <- comp[!is.na(comp)]
      totv <- fnd("totalweightofmaize")
      cat("Lab components:", paste(comp, collapse = " "), " total:", totv, "\n")
      if (!length(comp)) stop("no lab columns found")
      m <- matrix(sapply(comp, function(cn) to_num(rq[[cn]])), nrow = nr)
      s <- rowSums(m, na.rm = TRUE); s[rowSums(!is.na(m)) == 0] <- NA
      den <- if (!is.na(totv)) to_num(rq[[totv]]) else 200
      ylab <- finite_or_na(s / den)
      cat(sprintf("Lab share: mean=%.4f min=%.4f max=%.4f nonmissing=%d\n",
                  mean(ylab, na.rm = TRUE), min(ylab, na.rm = TRUE), max(ylab, na.rm = TRUE), sum(!is.na(ylab))))
    }
    dl <- data.frame(y = ylab, treat = rq$.treat, ea = rq$.ea)
    dl <- dl[complete.cases(dl), ]
    m2 <- feols(y ~ treat | ea, data = dl, vcov = "hetero", fixef.rm = "none")
    cat(sprintf("Table2 col2: b=%.4f se=%.4f N=%d\n", coef(m2)["treat"], se(m2)["treat"], nobs(m2)))
    emit("treatment_defects_lab_table2_col2", unname(coef(m2)["treat"]))
  })

  # ---- Columns 3-5: sales ----
  try({
    pr <- find_stub(c("^add5_ppk_([0-9]+)$", "^price_([0-9]+)$", "^add5_price_([0-9]+)$", "^price([0-9]+)$",
                      "^add5_[a-z_]*price[a-z_]*_([0-9]+)$"))
    wk <- find_stub(c("^week_sale_([0-9]+)$", "(?i)^add5_[a-z_]*week[a-z_]*_([0-9]+)$", "(?i)^week[a-z_]*_([0-9]+)$"))
    dt <- NULL
    # The sale date is stored as add5_sold_when_e_{k} (one per sale)
    if (is.null(wk)) dt <- find_stub(c("^add5_sold_when_e_([0-9]+)$",
                                       "(?i)^add5_[a-z_]*(?:date|day|when)[a-z_]*_([0-9]+)$",
                                       "(?i)^[a-z_]*(?:date|day)[a-z_]*_([0-9]+)$"))
    de <- find_stub(c("^deduct_totalshare100_([0-9]+)$"))
    np <- find_stub(c("^net_priceavg_([0-9]+)$"))
    cat("Sales stubs found: price=", !is.null(pr), " week=", !is.null(wk), " date=", !is.null(dt),
        " deduct=", !is.null(de), " netprice=", !is.null(np), "\n")
    if (!is.null(dt)) {
      cat("Sale date columns:", paste(dt, collapse = " "), "\n")
      cat("Sale date class:", paste(class(rq[[dt[[1]]]]), collapse = "/"), " example values:",
          paste(head(as.character(rq[[dt[[1]]]][!is.na(rq[[dt[[1]]]])], 3), collapse = " | "), "\n")
    }
    if (is.null(pr)) {
      cat("Candidate sales columns:", paste(grep("price|week|date|deduct|weight|kg|sale", names(rq), value = TRUE), collapse = " "), "\n")
      stop("price columns not found")
    }
    # household-level date fallback (single column without sale suffix)
    hhdate <- NULL
    if (is.null(wk) && is.null(dt)) {
      cand <- grep("(?i)(date|week|today|starttime|endtime|submission|day)", names(rq), value = TRUE, perl = TRUE)
      cand <- cand[!grepl("^add4_|^add5_ind_", cand)]
      cat("Household-level date candidates:", paste(cand, collapse = " "), "\n")
      if (length(cand)) hhdate <- cand[1]
    }
    getk <- function(stub, k) if (!is.null(stub) && as.character(k) %in% names(stub)) rq[[stub[[as.character(k)]]]] else rep(NA, nr)
    stata_week <- function(x) {
      if (inherits(x, "Date")) {
        dd <- x
      } else if (inherits(x, "POSIXt")) {
        dd <- as.Date(x)
      } else if (is.numeric(x)) {
        if (isTRUE(median(abs(x), na.rm = TRUE) > 1e7)) {
          dd <- as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC"))
        } else {
          dd <- as.Date(x, origin = "1960-01-01")
        }
      } else {
        xs <- as.character(x)
        xs[trimws(xs) == ""] <- NA
        dd <- suppressWarnings(as.Date(lubridate::parse_date_time(xs,
                 orders = c("Ymd", "dmY", "mdY", "Ymd HMS", "dmY HMS", "mdY HMS", "bdY", "dbY", "bdY HMS", "bdY IMS p"),
                 quiet = TRUE)))
      }
      doy <- as.numeric(format(dd, "%j"))
      yr <- as.numeric(format(dd, "%Y"))
      wkn <- pmin(floor((doy - 1) / 7) + 1, 52)
      ifelse(is.na(wkn), NA_real_, yr * 100 + wkn)
    }

    # Bag-level weights per sale: add5_ind_weight{j}_{k} (measured weight y) and
    # add5_ind_ded_weight{j}_{k} (deducted/paid weight). Decide interpretation from data.
    bagcols <- function(prefix, k) {
      cols <- grep(paste0("^", prefix, "[0-9]+_", k, "$"), names(rq), value = TRUE)
      if (length(cols)) names(cols) <- sub(paste0("^", prefix, "([0-9]+)_", k, "$"), "\\1", cols)
      cols
    }
    ratios <- c()
    for (k in names(pr)) {
      wc <- bagcols("add5_ind_weight", k); dc <- bagcols("add5_ind_ded_weight", k)
      for (j in intersect(names(wc), names(dc))) {
        w <- to_num(rq[[wc[[j]]]]); z <- to_num(rq[[dc[[j]]]])
        okr <- !is.na(w) & !is.na(z) & w > 0
        ratios <- c(ratios, z[okr] / w[okr])
      }
    }
    ded_is_paid_weight <- length(ratios) > 0 && median(ratios) > 0.5
    cat(sprintf("Bag ded_weight/weight ratio: median=%s n=%d -> ded_weight interpreted as %s\n",
                if (length(ratios)) format(median(ratios), digits = 4) else "NA", length(ratios),
                if (ded_is_paid_weight) "weight after deduction (z)" else "amount deducted"))
    sale_weights <- function(k) {
      wc <- bagcols("add5_ind_weight", k); dc <- bagcols("add5_ind_ded_weight", k)
      ysum <- rep(0, nr); zsum <- rep(0, nr); cnt <- rep(0, nr)
      for (j in names(wc)) {
        w <- to_num(rq[[wc[[j]]]])
        dj <- if (j %in% names(dc)) to_num(rq[[dc[[j]]]]) else rep(NA_real_, nr)
        zj <- if (ded_is_paid_weight) ifelse(is.na(dj), w, dj) else w - ifelse(is.na(dj), 0, dj)
        okw <- !is.na(w)
        ysum[okw] <- ysum[okw] + w[okw]; zsum[okw] <- zsum[okw] + zj[okw]; cnt[okw] <- cnt[okw] + 1
      }
      ysum[cnt == 0] <- NA; zsum[cnt == 0] <- NA
      list(y = ysum, z = zsum)
    }

    sl <- do.call(rbind, lapply(names(pr), function(k) {
      w <- if (!is.null(wk)) to_num(getk(wk, k)) else if (!is.null(dt)) stata_week(getk(dt, k)) else
        if (!is.null(hhdate)) stata_week(rq[[hhdate]]) else rep(1, nr)
      sw <- sale_weights(k)
      p <- to_num(getk(pr, k))
      ded <- if (!is.null(de)) to_num(getk(de, k)) else finite_or_na(100 * (sw$y - sw$z) / sw$y)
      netp <- if (!is.null(np)) to_num(getk(np, k)) else finite_or_na(p * sw$z / sw$y)
      data.frame(id = rq$.id, ea = rq$.ea, treat = rq$.treat, sale = as.integer(k),
                 price = p, week = w, deduct = ded, netp = netp, wy = sw$y)
    }))
    if (is.null(wk) && is.null(dt) && is.null(hhdate))
      cat("DEVIATION: No week-of-sale variable found in returns data; week-of-sale FE omitted (village FE only)\n")
    sl <- sl[!is.na(sl$price) & sl$price > 0, ]
    tabs <- function(x) paste(names(table(x$sale)), table(x$sale), sep = ":", collapse = " ")
    cat(sprintf("Sales with price: %d (by sale index: %s), households: %d\n", nrow(sl), tabs(sl), length(unique(sl$id))))

    # Candidate definitions of a valid sale, from least to most restrictive.
    c1 <- sl[!is.na(sl$week), ]
    c2 <- c1[!duplicated(c1[, c("id", "week", "price")]), ]
    c3 <- c2[!is.na(c2$wy), ]
    c4 <- c3[!duplicated(c3[, c("id", "price")]), ]
    cands <- list(dated = c1, dedup_id_week_price = c2, with_bag_weights = c3, dedup_id_price = c4)
    for (nm in names(cands)) {
      cat(sprintf("Sale sample '%s': N=%d hh=%d (by sale index: %s)\n", nm, nrow(cands[[nm]]),
                  length(unique(cands[[nm]]$id)), tabs(cands[[nm]])))
    }
    target_n <- 116
    pick <- NULL
    for (nm in names(cands)) {
      if (nrow(cands[[nm]]) > 0 && abs(nrow(cands[[nm]]) - target_n) / target_n <= 0.05) { pick <- nm; break }
    }
    if (is.null(pick)) {
      nn <- sapply(cands, nrow)
      nn[nn == 0] <- Inf
      pick <- names(cands)[which.min(abs(nn - target_n))]
    }
    cat("Using sale sample:", pick, "\n")
    if (pick != "dated")
      cat(sprintf("DEVIATION: Sale-level sample defined as '%s' (sales with a recorded sale date%s) to match the paper's 116 sales; the exact rule is not stated in the excerpt\n",
                  pick, if (pick == "dated") "" else ", removing duplicate/incomplete sale records"))
    sl <- cands[[pick]]

    run_sale <- function(yv) {
      ds <- sl[!is.na(sl[[yv]]) & !is.na(sl$treat) & !is.na(sl$week), ]
      ds$y <- ds[[yv]]
      feols(y ~ treat | ea + week, data = ds, cluster = ~id, fixef.rm = "none")
    }
    m3 <- run_sale("price")
    cat(sprintf("Table2 col3: b=%.4f se=%.4f N=%d hh=%d\n", coef(m3)["treat"], se(m3)["treat"], nobs(m3), length(unique(sl$id))))
    emit("treatment_price_table2_col3", unname(coef(m3)["treat"]))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    if (any(!is.na(sl$deduct))) {
      m4 <- run_sale("deduct")
      cat(sprintf("Table2 col4: b=%.4f N=%d\n", coef(m4)["treat"], nobs(m4)))
      emit("treatment_deductions_table2_col4", unname(coef(m4)["treat"]))
    }
    if (any(!is.na(sl$netp))) {
      m5 <- run_sale("netp")
      cat(sprintf("Table2 col5: b=%.4f N=%d\n", coef(m5)["treat"], nobs(m5)))
      emit("treatment_net_price_table2_col5", unname(coef(m5)["treat"]))
    }
  })
}

# ---------------------------------------------------------------
# Output
# ---------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}
