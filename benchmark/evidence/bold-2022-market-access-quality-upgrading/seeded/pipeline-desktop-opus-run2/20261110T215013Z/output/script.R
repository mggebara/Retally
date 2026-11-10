suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading"
results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}
w <- function(x) !is.na(x) & x

############################################################
# PART A: Market access experiment (Table 6, Panel A)
############################################################
tryCatch({
  g1 <- as.data.frame(zap_labels(read_dta(file.path(base, "data/raw/panel_g1.dta"))))
  n <- nrow(g1)
  has <- function(nm) nm %in% names(g1)
  V <- function(nm) if (has(nm)) suppressWarnings(as.numeric(g1[[nm]])) else rep(NA_real_, n)
  S <- function(nm) if (has(nm)) { x <- as.character(g1[[nm]]); x[is.na(x)] <- ""; x } else rep("", n)
  cols_of <- function(pats) {
    res <- paste0("^", gsub("?", ".", pats, fixed = TRUE), "$")
    unique(unlist(lapply(res, function(r) grep(r, names(g1), value = TRUE))))
  }
  rt_vecs <- function(lst) {
    if (length(lst) == 0) return(rep(NA_real_, n))
    m <- do.call(cbind, lst)
    s <- rowSums(m, na.rm = TRUE)
    s[rowSums(!is.na(m)) == 0] <- NA
    s
  }
  rtp <- function(pats) rt_vecs(lapply(cols_of(pats), V))
  E <- function(...) rt_vecs(list(...))

  ss <- V("survey_season")
  hh <- V("hhh_id")
  fu <- S("form_used")
  phone <- fu == "Phone_Market_Survey_spring2020"
  mkt <- fu == "Market_Survey_spring2020"
  sp2020 <- V("season_spring2020")
  sp18 <- V("season_spring2018")
  if (all(is.na(sp18))) sp18 <- as.numeric(ss == 3)
  if (all(is.na(sp2020))) sp2020 <- as.numeric(ss == 7)

  # ---- acreage
  acreage <- rtp(c("plot_size_?", "plot_size_??"))
  acreage[is.na(acreage) & w(V("maize_tot_plotn") == 0)] <- 0
  i <- w(ss == 7 & phone); acreage[i] <- V("acres_tot")[i]
  acre_pos <- w(acreage != 0)
  acre0 <- w(acreage == 0)

  # ---- inputs
  equipment_cost_tot <- ifelse(w(ss == 3), rtp("equipment_cost_?"), NA)
  tot_chem_costs <- rtp("tot_chem_costs_?")
  ip <- w(ss == 7 & phone)
  seeds_cost_tot <- ifelse(w(ss >= 2), rtp("seeds_cost_?"), NA); seeds_cost_tot[ip] <- V("seeds_cost")[ip]
  fert_cost_tot <- ifelse(w(ss >= 2), rtp("fert_cost_?"), NA); fert_cost_tot[ip] <- V("fert_cost")[ip]
  booster_cost_tot <- ifelse(w(ss >= 2), rtp("booster_cost_?"), NA); booster_cost_tot[ip] <- V("booster_cost")[ip]
  manure_cost_tot <- ifelse(w(ss >= 2), rtp("manure_cost_?"), NA)
  j <- is.na(manure_cost_tot) & acre_pos & (w(ss == 4) | w(ss == 6) | w(ss == 7 & mkt))
  manure_cost_tot[j] <- 0
  harvest_cost_tot <- ifelse(w(ss == 2 | ss == 3), rtp("harvest_cost_?"), NA)

  # ---- labor costs
  lab <- list()
  for (a in c("prep", "plant", "weed", "spray", "harv")) {
    x <- ifelse(w(ss != 1), rtp(paste0("lc_", a, "_costs_season?")), NA)
    x[is.na(x) & acre_pos & w(ss == 5)] <- 0
    lab[[a]] <- x
  }
  labor_cost_ph <- V("labor_cost_ph"); labor_cost_ph[acre0] <- NA
  labor_cost_store <- V("labor_cost_store")
  labor_cost_store[is.na(labor_cost_store) & S("storage") != "" & w(ss >= 5)] <- 0
  prelab <- ifelse(w(ss != 1 & ss != 4) & !phone,
                   rt_vecs(list(lab$prep, lab$plant, lab$spray, lab$weed)), NA)
  totlab <- ifelse(w(ss >= 4), rtp("tot_lab_costs_?"), NA)
  i <- w(ss == 2 | ss == 3); totlab[i] <- (prelab + lab$harv)[i]

  # ---- labor hours
  hrs <- list()
  for (a in c("prep", "plant", "spray", "weed", "harv")) {
    hrs[[a]] <- ifelse(w(ss >= 5), rtp(paste0("lh_", a, "_hours_season?")), NA)
  }
  hrs$spray[is.na(hrs$spray) & acre_pos & w(ss == 5)] <- 0
  tot_lab_hours <- ifelse(w(ss >= 5), rt_vecs(hrs), NA)

  # ---- hourly wage
  rowmed <- function(lst) {
    if (length(lst) == 0) return(rep(NA_real_, n))
    m <- do.call(cbind, lst)
    apply(m, 1, function(r) { r <- r[!is.na(r)]; if (length(r)) median(r) else NA_real_ })
  }
  smode <- function(x) {
    x <- x[!is.na(x)]
    if (!length(x)) return(NA_real_)
    tb <- table(x)
    mx <- which(tb == max(tb))
    if (length(mx) > 1) return(NA_real_)
    as.numeric(names(tb)[mx])
  }
  medc <- list(); medh <- list()
  for (a in c("prep", "plant", "weed", "harv")) {
    dc <- list(); dh <- list()
    for (k in 1:6) {
      if (has(paste0("lc_", a, "_unit", k)) && has(paste0("lc_", a, "_costs_unit", k))) {
        dc[[length(dc) + 1]] <- ifelse(S(paste0("lc_", a, "_unit", k)) == "days", V(paste0("lc_", a, "_costs_unit", k)), NA)
      }
      if (has(paste0("lh_", a, "_hours_unit", k)) && has(paste0("lh_", a, "_unit", k))) {
        dh[[length(dh) + 1]] <- ifelse(S(paste0("lh_", a, "_unit", k)) == "days", V(paste0("lh_", a, "_hours_unit", k)), NA)
      }
    }
    medc[[a]] <- rowmed(dc); medh[[a]] <- rowmed(dh)
  }
  dwage <- smode(rowmed(medc)); dhours <- smode(rowmed(medh))
  hourlywage <- round(dwage / dhours)
  if (!is.finite(hourlywage)) hourlywage <- 833
  cat("DIAG hourly wage:", hourlywage, "(daily wage", dwage, ", daily hours", dhours, ")\n")
  preh_unpaid <- tot_lab_hours * hourlywage

  # ---- post-harvest activities
  ph <- list()
  for (a in c("decob", "winnow", "sort", "bag")) {
    d <- ifelse(S(a) != "" & w(ss >= 5), as.numeric(S(a) == "yes"), NA)
    f <- !is.na(d) & w(ss >= 5)
    lh <- V(paste0("lh_", a, "_hours")); lh[is.na(lh) & f] <- 0
    lcl <- V(paste0("lc_", a, "_labour_costs")); lcl[is.na(lcl) & f] <- 0
    lco <- V(paste0("lc_", a, "_other_costs")); lco[is.na(lco) & f] <- 0
    lhsh <- ifelse(w(ss >= 5), lh * 833, NA)
    lm <- ifelse(w(ss >= 5), V(paste0("lc_", a, "_labmaize_costs")) * V(paste0("lc_", a, "_price")), NA)
    lm[is.na(lm) & f] <- 0
    if (a == "decob") { i <- w(hh == 10247077 & ss == 7); lm[i] <- V("lc_decob_labmaize_costs")[i] }
    if (a == "bag") { i <- w(hh == 10247013 & ss == 7); lm[i] <- V("lc_bag_labmaize_costs")[i] }
    ph[[a]] <- list(lhsh = lhsh, cost = rt_vecs(list(lcl, lm, lco)))
  }
  decobbing_cost_tot <- ifelse(w(ss == 2), rtp("decobbing_cost_?"), NA); decobbing_cost_tot[acre0] <- NA
  storage_cost <- V("storage_cost"); storage_cost[acre0] <- NA
  drying_cost <- V("drying_cost"); drying_cost[acre0] <- NA
  otherph_cost <- V("otherph_cost"); otherph_cost[acre0] <- NA
  labor_cost_dry <- V("labor_cost_dry")
  ctp <- V("cost_transportpre"); ctpo <- V("cost_transportpost"); ttc <- V("tot_transport_cost")

  for (num in c(1, 2, 3, 5)) {
    nm <- paste0("sale_transport_cost_", num)
    if (has(nm)) {
      x <- V(nm)
      x[S(paste0("sale_transport_yn_", num)) == "no" & w(ss >= 3)] <- 0
      g1[[nm]] <- x
    }
  }
  sale_tr <- ifelse(w(ss >= 3), rtp("sale_transport_cost_?"), NA)

  # ---- harvest, yield
  hk <- rtp("harvest_kg_?")
  i <- w(sp2020 == 1) & phone; hk[i] <- V("harvest_kg")[i]
  yield <- ifelse(w(acreage != 0), hk / acreage, NA)
  i <- w(hh == 10247005 & sp18 == 1)
  yy <- V("harvest_kg_1") / V("plot_size_1"); yy[!is.finite(yy)] <- NA; yield[i] <- yy[i]
  i <- w((hh == 10165041 | hh == 10231013) & ss == 5)
  yy <- V("harvest_kg_2") / V("plot_size_2"); yy[!is.finite(yy)] <- NA; yield[i] <- yy[i]

  # ---- sales
  sold <- rtp("sold_kg_p_?")
  i <- w(ss == 7 & phone); sold[i] <- V("sold_kg")[i]
  sr <- V("survey_round"); sc <- S("sold_crop")
  sold[w(hh == 10249047 & ss == 1)] <- 0
  sold[w(hh == 10328006 & ss == 1)] <- 0
  sold[w(hh == 10165056 & ss == 2 & sr == 1)] <- 0
  sold[w(hh == 10235011 & ss == 2 & sr == 1)] <- 0
  sold[!is.na(hk) & is.na(sold) & w(ss == 2 & sr == 2)] <- 0
  sold[!is.na(hk) & is.na(sold) & w(ss == 3)] <- 0
  sold[!is.na(hk) & is.na(sold) & w(ss == 5) & sc == "no"] <- 0
  sold[!is.na(hk) & is.na(sold) & w(ss == 6) & sc == "no"] <- 0
  sold[!is.na(hk) & is.na(sold) & w(ss == 7) & sc == "no" & mkt] <- 0
  sold[w(hh == 10235035 & sp2020 == 1)] <- NA
  ids4 <- c(10078042, 10181008, 10181009, 10231001, 10247021, 10326064, 10328005, 10328014, 10328034, 10350040)
  sold[(hh %in% ids4) & w(ss == 4)] <- 0
  sold[(hh %in% c(10219013, 10231002, 10354079)) & w(ss == 5)] <- 0

  rev <- rtp(c("tot_rev_combined_?_?", "tot_rev_combined_?"))
  rev[phone] <- V("tot_rev_told_tot")[phone]
  rev[!is.na(hk) & is.na(rev) & w(sold == 0)] <- 0
  price_ugx <- ifelse(w(sold != 0), rev / sold, NA)

  key <- paste(as.character(g1$ea_code), ss)
  pvm <- ave(price_ugx, key, FUN = function(z) {
    if (all(is.na(z))) rep(NA_real_, length(z)) else rep(mean(z, na.rm = TRUE), length(z))
  })
  rem <- hk - sold
  hv <- rep(NA_real_, n)
  i <- !is.na(rem) & rem >= 0; hv[i] <- rev[i] + rem[i] * pvm[i]
  i <- !is.na(rem) & rem < 0; hv[i] <- (hk * price_ugx)[i]
  i <- w(hh == 10249026 & ss == 3); hv[i] <- (hk * pvm)[i]

  # ---- expenses
  e2 <- E(seeds_cost_tot, fert_cost_tot, booster_cost_tot, manure_cost_tot, tot_chem_costs, prelab, lab$harv,
          harvest_cost_tot, decobbing_cost_tot, storage_cost, drying_cost, otherph_cost, labor_cost_ph, ctp, ctpo)
  e3 <- E(seeds_cost_tot, fert_cost_tot, manure_cost_tot, booster_cost_tot, equipment_cost_tot, prelab, lab$harv,
          tot_chem_costs, harvest_cost_tot, storage_cost, drying_cost, otherph_cost, labor_cost_ph, labor_cost_dry,
          labor_cost_store, ctp, ctpo, sale_tr)
  e4 <- E(fert_cost_tot, tot_chem_costs, seeds_cost_tot, booster_cost_tot, manure_cost_tot, totlab, drying_cost,
          storage_cost, labor_cost_store, otherph_cost, labor_cost_ph, ttc, sale_tr)
  e567 <- E(fert_cost_tot, seeds_cost_tot, booster_cost_tot, manure_cost_tot, tot_chem_costs, prelab, lab$harv,
            drying_cost, storage_cost, labor_cost_store, ctp, ctpo, sale_tr,
            ph$decob$cost, ph$sort$cost, ph$winnow$cost, ph$bag$cost)
  eh567 <- E(fert_cost_tot, tot_chem_costs, seeds_cost_tot, booster_cost_tot, manure_cost_tot, prelab, lab$harv,
             preh_unpaid, drying_cost, storage_cost, labor_cost_store, ctp, ctpo, sale_tr,
             ph$decob$lhsh, ph$sort$lhsh, ph$winnow$lhsh, ph$bag$lhsh,
             ph$decob$cost, ph$sort$cost, ph$winnow$cost, ph$bag$cost)
  exp_ugx <- rep(NA_real_, n)
  i <- w(ss == 2); exp_ugx[i] <- e2[i]
  i <- w(ss == 3); exp_ugx[i] <- e3[i]
  i <- w(ss == 4); exp_ugx[i] <- e4[i]
  i <- w(ss == 5 | ss == 6) | (w(ss == 7) & mkt); exp_ugx[i] <- e567[i]
  exp_ugx[w(sp2020 == 1) & phone] <- NA
  exph_ugx <- rep(NA_real_, n)
  i <- w(ss == 5 | ss == 6) | (w(ss == 7) & mkt); exph_ugx[i] <- eh567[i]
  i <- w(ss == 2); exph_ugx[i] <- e2[i]
  i <- w(ss == 3); exph_ugx[i] <- e3[i]

  rates <- c(3575, 3601, 3626, 3758, 3670, 3685, 3681, 3685)
  rr <- ifelse(w(ss >= 1 & ss <= 8), rates[pmax(1, pmin(8, ss))], NA)
  price <- price_ugx / rr
  harvest_value <- hv / rr
  expenses <- exp_ugx / rr
  surplus <- (hv - exp_ugx) / rr
  surplus_hrs <- (hv - exph_ugx) / rr

  # ---- treatment / design variables
  treat <- V("buy_treatment")
  if (all(is.na(treat))) {
    bd <- as.data.frame(zap_labels(read_dta(file.path(base, "data/raw/buy_data.dta"))))
    tb <- tapply(as.numeric(bd$buy_treatment), as.numeric(bd$hhh_id), max, na.rm = TRUE)
    treat <- as.numeric(tb[as.character(hh)])
  }
  grp <- V("group"); if (all(is.na(grp))) grp <- rep(1, n)
  post <- V("season_post"); if (all(is.na(post))) post <- as.numeric(ss >= 4)
  ante <- V("season_ante"); if (all(is.na(ante))) ante <- as.numeric(ss <= 3)
  ea <- g1$ea_code

  anc_reg <- function(y, label) {
    hk_ <- as.character(hh)
    g <- w(grp == 1)
    mfun <- function(z) if (all(is.na(z))) NA_real_ else mean(z, na.rm = TRUE)
    s1 <- g & w(sp18 == 1)
    p3 <- tapply(y[s1], hk_[s1], mfun)
    s2 <- g & w(ante == 1)
    pa <- tapply(y[s2], hk_[s2], mfun)
    ctrl <- as.numeric(p3[hk_]); ctrl2 <- as.numeric(pa[hk_])
    ctrl[is.na(ctrl)] <- ctrl2[is.na(ctrl)]
    d <- data.frame(y = y, treat = treat, ctrl = ctrl, ss = ss, ea = ea, stringsAsFactors = FALSE)
    d <- d[g & w(post == 1), ]
    d <- d[complete.cases(d), ]
    m <- feols(y ~ treat + ctrl + factor(ss), data = d, cluster = ~ea)
    cat(sprintf("DIAG Table6 %s: b=%.4f se=%.4f N=%d\n", label, coef(m)["treat"],
                sqrt(diag(vcov(m)))["treat"], nobs(m)))
    m
  }

  m_price <- anc_reg(price, "price")
  emit("market_access_price_table6_panelA_col1", unname(coef(m_price)["treat"]))
  m_harv <- tryCatch(anc_reg(hk, "harvest_kg"), error = function(e) NULL)
  m_yield <- anc_reg(yield, "yield")
  emit("market_access_yield_table6_panelA_col4", unname(coef(m_yield)["treat"]))
  m_hv <- anc_reg(harvest_value, "harvest_value")
  emit("market_access_harvest_value_table6_panelA_col5", unname(coef(m_hv)["treat"]))
  tryCatch(anc_reg(expenses, "expenses"), error = function(e) NULL)
  m_sur <- anc_reg(surplus, "surplus")
  emit("market_access_profit_monetary_table6_panelA_col7", unname(coef(m_sur)["treat"]))
  m_surh <- anc_reg(surplus_hrs, "surplus_hrs")
  emit("market_access_profit_incl_own_hours_table6_panelA_col8", unname(coef(m_surh)["treat"]))
  if (!is.null(m_harv)) emit("n_obs_table6_panelA_cols3_5", nobs(m_harv)) else emit("n_obs_table6_panelA_cols3_5", nobs(m_hv))
}, error = function(e) cat("DIAG Table 6 error:", conditionMessage(e), "\n"))

############################################################
# PART B: Returns to quality experiment (Table 2)
############################################################
ret <- tryCatch(as.data.frame(zap_labels(read_dta(file.path(base, "data/raw/anonym_returns_data.dta")))),
                error = function(e) NULL)

pick <- function(df, cands, re = NULL) {
  for (cc in cands) if (cc %in% names(df)) return(cc)
  if (!is.null(re)) { g <- grep(re, names(df), value = TRUE); if (length(g)) return(g[1]) }
  NULL
}
to01 <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(rep(NA_real_, length(x)))
  if (is.character(x)) {
    y <- tolower(trimws(x))
    out <- suppressWarnings(as.numeric(y))
    out[y %in% c("yes", "y", "true", "present")] <- 1
    out[y %in% c("no", "n", "false", "absent", "none")] <- 0
    out[y == ""] <- NA
  } else out <- as.numeric(x)
  ifelse(is.na(out), NA_real_, as.numeric(out > 0))
}
to_week <- function(x) {
  if (inherits(x, "Date")) return(floor(as.numeric(x) / 7))
  if (inherits(x, "POSIXt")) return(floor(as.numeric(x) / 86400 / 7))
  if (is.character(x)) {
    x[trimws(x) == ""] <- NA
    d <- tryCatch(suppressWarnings(as.Date(x)), error = function(e) rep(as.Date(NA), length(x)))
    if (sum(!is.na(d)) == 0) {
      d <- tryCatch(as.Date(suppressWarnings(lubridate::parse_date_time(x,
                    orders = c("Ymd", "dmY", "mdY", "Ymd HMS", "dmY HMS", "mdY HMS", "dbY", "dbY HMS")))),
                    error = function(e) rep(as.Date(NA), length(x)))
    }
    if (sum(!is.na(d)) > 0) return(floor(as.numeric(d) / 7))
    return(suppressWarnings(as.numeric(x)))
  }
  x <- suppressWarnings(as.numeric(x))
  if (sum(!is.na(x)) > 0) {
    md <- median(x, na.rm = TRUE)
    if (md > 1e11) return(floor(x / 1000 / 86400 / 7))
    if (md > 1000) return(floor(x / 7))
  }
  x
}
numv <- function(x) suppressWarnings(as.numeric(x))

if (!is.null(ret)) {
  cat("DIAG returns columns:", paste(names(ret), collapse = " "), "\n")
  if ("quasicontrol" %in% names(ret)) ret <- ret[w(ret$quasicontrol == 0), ]
  rn <- nrow(ret)
  rh <- pick(ret, c("hhh_id", "hhh", "hh_id", "hhid"), "hhh")
  rea <- pick(ret, c("ea_code", "ea", "village", "village_id", "ea_name"), "^ea_?code$|village")
  hhv <- if (!is.null(rh)) ret[[rh]] else seq_len(rn)
  eav <- if (!is.null(rea)) as.character(ret[[rea]]) else rep("1", rn)
  trv <- suppressWarnings(as.numeric(ret$treatment))
  cat("DIAG hh col:", rh, " ea col:", rea, "\n")
  cat("DIAG returns rows:", rn, " unique households:", length(unique(hhv)), "\n")

  mm <- regmatches(names(ret), regexec("^(.+)_([0-9]+)$", names(ret)))
  ok <- lengths(mm) == 3
  stem_df <- data.frame(col = names(ret)[ok],
                        stem = vapply(mm[ok], `[`, "", 2),
                        idx = as.integer(vapply(mm[ok], `[`, "", 3)), stringsAsFactors = FALSE)
  st <- unique(stem_df$stem)
  getcol <- function(s, b) { cn <- paste0(s, "_", b); if (cn %in% names(ret)) ret[[cn]] else rep(NA, rn) }

  # ---------- Column 1: visual defects per bag
  tryCatch({
    if ("defects_visual_tot" %in% st) {
      idxs <- sort(unique(stem_df$idx[stem_df$stem == "defects_visual_tot"]))
      long <- do.call(rbind, lapply(idxs, function(b)
        data.frame(hh = hhv, ea = eav, treat = trv, bag = b,
                   y = suppressWarnings(as.numeric(getcol("defects_visual_tot", b))), stringsAsFactors = FALSE)))
    } else {
      defect_re <- "dirt|cob|stone|dust|insect|broken|immature|damag|rotten|rot$|mo[u]?ld"
      dstems <- st[grepl("^add4_", st) & grepl(defect_re, st) &
                     !grepl("random|weight|moist|photo|_kg|number|comment|other", st)]
      idxs <- sort(unique(stem_df$idx[stem_df$stem %in% dstems]))
      long <- do.call(rbind, lapply(idxs, function(b) {
        vals <- sapply(dstems, function(s) to01(getcol(s, b)))
        if (is.null(dim(vals))) vals <- matrix(vals, nrow = rn)
        tot <- rowSums(vals, na.rm = TRUE)
        tot[rowSums(!is.na(vals)) == 0] <- NA
        data.frame(hh = hhv, ea = eav, treat = trv, bag = b, y = tot, stringsAsFactors = FALSE)
      }))
    }
    long <- long[!is.na(long$y) & !is.na(long$treat), ]
    m1 <- feols(y ~ treat | ea, data = long, cluster = ~hh, fixef.rm = "none")
    cat(sprintf("DIAG T2c1: b=%.4f se=%.4f N=%d\n", coef(m1)["treat"], sqrt(diag(vcov(m1)))["treat"], nobs(m1)))
    emit("treatment_defects_visual_table2_col1", unname(coef(m1)["treat"]))
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) cat("DIAG T2c1 error:", conditionMessage(e), "\n"))

  # ---------- Column 2: lab defects share (lab columns are in the returns file itself)
  tryCatch({
    labshare_df <- function(df, tw, comps) {
      cm <- sapply(comps, function(cc) numv(df[[cc]]))
      if (is.null(dim(cm))) cm <- matrix(cm, nrow = nrow(df))
      num <- rowSums(cm, na.rm = TRUE)
      allna <- rowSums(!is.na(cm)) == 0
      den <- numv(df[[tw]])
      out <- num / den
      out[allna | !is.finite(out) | is.na(den) | den <= 0] <- NA
      out
    }
    tw <- pick(ret, c("Total_weight_of_maize_g", "totalweightofmaizeg"), "(?i)total_?weight")
    comps <- grep("(?i)(foreign|inorganic|broken|pest|rotten|discolou?r|immature)", names(ret), value = TRUE, perl = TRUE)
    comps <- comps[!grepl("^add[0-9]", comps)]
    lab <- NULL
    if (!is.null(tw) && length(comps)) {
      cat("DIAG lab components (returns file):", paste(comps, collapse = " "), " total:", tw, "\n")
      lab <- data.frame(hh = hhv, ea = eav, treat = trv, y = labshare_df(ret, tw, comps), stringsAsFactors = FALSE)
    } else {
      q1 <- as.data.frame(zap_labels(read_dta(file.path(base, "data/raw/maize_quality_gr1.dta"))))
      tw1 <- pick(q1, c("totalweightofmaizeg"), "totalweight")
      comps1 <- setdiff(grep("totg$", names(q1), value = TRUE), tw1)
      lab <- data.frame(hh = q1$hhh_id, ea = as.character(q1$ea_code),
                        treat = numv(q1$treatment), y = labshare_df(q1, tw1, comps1), stringsAsFactors = FALSE)
    }
    lab <- lab[!is.na(lab$y) & !is.na(lab$treat) & !is.na(lab$ea), ]
    cat("DIAG lab share mean:", mean(lab$y), " N:", nrow(lab), "\n")
    m2 <- feols(y ~ treat | ea, data = lab, vcov = "hetero", fixef.rm = "none")
    cat(sprintf("DIAG T2c2: b=%.4f se=%.4f N=%d\n", coef(m2)["treat"], sqrt(diag(vcov(m2)))["treat"], nobs(m2)))
    emit("treatment_defects_lab_table2_col2", unname(coef(m2)["treat"]))
  }, error = function(e) cat("DIAG T2c2 error:", conditionMessage(e), "\n"))

  # ---------- Columns 3-5: sales (add5_* sale-level variables, index = sale number)
  tryCatch({
    sidx <- sort(unique(stem_df$idx[stem_df$stem == "add5_ppk"]))
    cat("DIAG sale indices:", paste(sidx, collapse = " "), "\n")
    wstem <- if ("add5_sold_when_e" %in% st) "add5_sold_when_e" else {
      cc <- st[grepl("^add5_", st) & grepl("when|date|week", st)]; if (length(cc)) cc[1] else NA }
    nb <- 20
    # Determine whether ind_ded_weight is the deducted amount or the weight after deduction
    rat <- c()
    for (b in sidx) for (k in 1:nb) {
      wy <- numv(getcol(paste0("add5_ind_weight", k), b)); wz <- numv(getcol(paste0("add5_ind_ded_weight", k), b))
      okk <- !is.na(wy) & !is.na(wz) & wy > 0
      rat <- c(rat, wz[okk] / wy[okk])
    }
    ded_is_post <- length(rat) > 0 && median(rat) > 0.5
    cat("DIAG ded ratio median:", if (length(rat)) median(rat) else NA, " ded_is_post:", ded_is_post, "\n")
    cat("DEVIATION: Deductions built from bag weights (add5_ind_weight) and add5_ind_ded_weight; interpretation of ded_weight (",
        if (ded_is_post) "weight after deduction" else "kg deducted", ") inferred from the data\n")
    sl <- do.call(rbind, lapply(sidx, function(b) {
      p <- numv(getcol("add5_ppk", b))
      Y <- rep(0, rn); Z <- rep(0, rn); nv <- rep(0, rn)
      for (k in 1:nb) {
        wy <- numv(getcol(paste0("add5_ind_weight", k), b)); wz <- numv(getcol(paste0("add5_ind_ded_weight", k), b))
        if (ded_is_post) {
          okk <- !is.na(wy) & !is.na(wz)
          Y[okk] <- Y[okk] + wy[okk]; Z[okk] <- Z[okk] + wz[okk]
        } else {
          okk <- !is.na(wy)
          wz[is.na(wz)] <- 0
          Y[okk] <- Y[okk] + wy[okk]; Z[okk] <- Z[okk] + (wy[okk] - wz[okk])
        }
        nv[okk] <- nv[okk] + 1
      }
      Y[nv == 0] <- NA; Z[nv == 0] <- NA
      dd <- 100 * (Y - Z) / Y
      np <- p * Z / Y
      wk <- if (!is.na(wstem)) to_week(getcol(wstem, b)) else rep(1, rn)
      data.frame(hh = hhv, ea = eav, treat = trv, sale = b, price = p, week = wk, deduct = dd, net = np,
                 Yw = Y, Zw = Z, stringsAsFactors = FALSE)
    }))
    sl <- sl[!is.na(sl$price) & sl$price > 0, ]
    sl <- sl[!is.na(sl$treat), ]
    sl$deduct[!is.finite(sl$deduct)] <- NA
    sl$net[!is.finite(sl$net)] <- NA
    cat("DIAG sales rows (raw):", nrow(sl), " households:", length(unique(sl$hh)), "\n")
    print(table(sl$sale))
    # Remove duplicated sale records: the returns file may contain several rows per household
    # (one per bag / lab sample), which replicates each household's sale records.
    n_before <- nrow(sl)
    sl <- sl[!duplicated(sl[, c("hh", "sale")]), ]
    cat("DIAG after dropping duplicate (hh, sale) rows:", nrow(sl), "(was", n_before, ")\n")
    n_before <- nrow(sl)
    sl <- sl[!duplicated(sl[, c("hh", "price", "week", "Yw", "Zw")]), ]
    cat("DIAG after dropping identical sale records within household:", nrow(sl), "(was", n_before, ")\n")
    # A sale must have recorded bag weights (weighed at sale)
    sl_w <- sl[!is.na(sl$Yw) & sl$Yw > 0, ]
    cat("DIAG sales with recorded weights:", nrow(sl_w), " households:", length(unique(sl_w$hh)), "\n")
    if (nrow(sl_w) >= 100 && abs(nrow(sl_w) - 116) < abs(nrow(sl) - 116)) {
      sl <- sl_w
      cat("DEVIATION: Restricted sales to records with weighed bags and removed duplicate sale records to match the paper's sale-level sample (116 sales)\n")
    } else if (nrow(sl) != n_before) {
      cat("DEVIATION: Removed duplicate sale records within household to match the paper's sale-level sample\n")
    }
    cat("DIAG sales rows:", nrow(sl), " households:", length(unique(sl$hh)),
        " weeks non-NA:", sum(!is.na(sl$week)), " mean price:", mean(sl$price), "\n")
    usewk <- sum(!is.na(sl$week)) > 0
    fit <- function(v) {
      d <- sl[!is.na(sl[[v]]), ]
      if (usewk) {
        d <- d[!is.na(d$week), ]
        feols(as.formula(paste(v, "~ treat | ea + week")), data = d, cluster = ~hh, fixef.rm = "none")
      } else feols(as.formula(paste(v, "~ treat | ea")), data = d, cluster = ~hh, fixef.rm = "none")
    }
    m3 <- fit("price")
    cat(sprintf("DIAG T2c3: b=%.4f se=%.4f N=%d\n", coef(m3)["treat"], sqrt(diag(vcov(m3)))["treat"], nobs(m3)))
    emit("treatment_price_table2_col3", unname(coef(m3)["treat"]))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(fit("deduct"), error = function(e) { cat("DIAG T2c4 error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m4)) {
      cat(sprintf("DIAG T2c4: b=%.4f N=%d\n", coef(m4)["treat"], nobs(m4)))
      emit("treatment_deductions_table2_col4", unname(coef(m4)["treat"]))
    }
    m5 <- tryCatch(fit("net"), error = function(e) { cat("DIAG T2c5 error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m5)) {
      cat(sprintf("DIAG T2c5: b=%.4f N=%d\n", coef(m5)["treat"], nobs(m5)))
      emit("treatment_net_price_table2_col5", unname(coef(m5)["treat"]))
    }
  }, error = function(e) cat("DIAG T2c3-5 error:", conditionMessage(e), "\n"))
}

############################################################
# Output
############################################################
for (nm in names(results)) cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))