suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
raw <- file.path(root, "data", "raw")

res_names <- c("treatment_defects_visual_table2_col1", "treatment_defects_lab_table2_col2",
               "treatment_price_table2_col3", "treatment_deductions_table2_col4",
               "treatment_net_price_table2_col5", "n_obs_table2_col1_bags",
               "n_obs_table2_cols3_5_sales", "market_access_price_table6_panelA_col1",
               "market_access_yield_table6_panelA_col4", "market_access_harvest_value_table6_panelA_col5",
               "market_access_profit_monetary_table6_panelA_col7",
               "market_access_profit_incl_own_hours_table6_panelA_col8",
               "n_obs_table6_panelA_cols3_5")
results <- setNames(as.list(rep(NA_real_, length(res_names))), res_names)
setres <- function(n, v) {
  results[[n]] <<- if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v)[1]
}
msg <- function(...) message(paste0(...))

clean_df <- function(d) {
  d <- as.data.frame(d)
  for (v in names(d)) {
    x <- d[[v]]
    if (inherits(x, "haven_labelled")) x <- haven::zap_labels(x)
    attr(x, "label") <- NULL
    attr(x, "format.stata") <- NULL
    d[[v]] <- x
  }
  d
}
num <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(x))
  suppressWarnings(as.numeric(x))
}
pick <- function(nms, pats, excl = NULL) {
  out <- nms
  for (p in pats) out <- out[grepl(p, out, ignore.case = TRUE)]
  if (!is.null(excl)) out <- out[!grepl(excl, out, ignore.case = TRUE)]
  out
}
first_of <- function(nms, cands) {
  for (cc in cands) {
    h <- nms[tolower(nms) == tolower(cc)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
has_data <- function(d, v) any(!is.na(num(d[[v]])))

to_week <- function(x) {
  if (inherits(x, "Date")) return(format(x, "%Y-%U"))
  if (inherits(x, "POSIXt")) return(format(as.Date(x), "%Y-%U"))
  if (is.character(x)) {
    x[trimws(x) == ""] <- NA
    d <- tryCatch(as.Date(x, tryFormats = c("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%b %d, %Y", "%d%b%Y"),
                          optional = TRUE), error = function(e) rep(as.Date(NA), length(x)))
    out <- ifelse(is.na(d), NA_character_, format(d, "%Y-%U"))
    return(out)
  }
  n <- num(x)
  if (all(is.na(n))) return(rep(NA_character_, length(x)))
  med <- median(n, na.rm = TRUE)
  if (med > 1e9) {
    d <- as.Date(as.POSIXct(n / 1000, origin = "1960-01-01", tz = "UTC"))
  } else if (med > 1000) {
    d <- as.Date(n, origin = "1960-01-01")
  } else {
    return(ifelse(is.na(n), NA_character_, as.character(n)))
  }
  ifelse(is.na(d), NA_character_, format(d, "%Y-%U"))
}

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
rd <- tryCatch(clean_df(read_dta(file.path(raw, "anonym_returns_data.dta"))), error = function(e) NULL)
if (!is.null(rd)) {
  nm <- names(rd)
  msg("returns columns: ", paste(nm, collapse = ", "))
  trt <- first_of(nm, c("treatment", "treat", "treated"))
  rd$treat_ <- num(rd[[trt]])
  vcol <- first_of(nm, c("ea_code", "village", "village_id", "vill", "ea", "village_code", "lc1", "village_name"))
  if (is.na(vcol)) {
    cand <- pick(nm, "vill|^ea_|parish")
    vcol <- if (length(cand)) cand[1] else NA
  }
  msg("village column: ", vcol)
  rd$vill_ <- if (!is.na(vcol)) as.character(rd[[vcol]]) else "1"
  rd$vill_[is.na(rd$vill_)] <- "missing"
  hcol <- first_of(nm, c("hhh_id", "hh_id", "hhid", "household_id", "id", "hhh"))
  rd$hh_ <- if (!is.na(hcol)) as.character(rd[[hcol]]) else as.character(seq_len(nrow(rd)))
  if (any(duplicated(rd$hh_)) || any(is.na(rd$hh_))) rd$hh_ <- as.character(seq_len(nrow(rd)))

  # ---------------- Column (2): lab defects ----------------
  tryCatch({
    tw <- pick(nm, "total_weight", excl = "aflat|^add")
    groups <- list("broken", "pest", "rotten", "immature|shrivel", "discolo", "foreign|filth|inert")
    labcols <- c()
    for (g in groups) {
      cc <- pick(nm, g, excl = "aflat|pct|percent|share|count|num_|^add")
      cc <- cc[vapply(cc, function(v) has_data(rd, v), logical(1))]
      if (length(cc)) {
        pr <- cc[grepl("tot", cc, ignore.case = TRUE)]
        if (!length(pr)) pr <- cc
        labcols <- c(labcols, pr[which.min(nchar(pr))])
      }
    }
    msg("lab defect columns: ", paste(labcols, collapse = ", "), " ; total weight: ", paste(tw, collapse = ","))
    M <- do.call(cbind, lapply(labcols, function(v) num(rd[[v]])))
    defg <- ifelse(rowSums(!is.na(M)) > 0, rowSums(M, na.rm = TRUE), NA)
    totw <- if (length(tw)) num(rd[[tw[1]]]) else rep(NA_real_, nrow(rd))
    rd$lab_def <- ifelse(!is.na(totw) & totw > 0, 100 * defg / totw, defg / 2)
    labd <- rd[!is.na(rd$lab_def) & !is.na(rd$treat_), ]
    m2 <- feols(lab_def ~ treat_ | vill_, data = labd, vcov = "hetero")
    print(summary(m2))
    setres("treatment_defects_lab_table2_col2", coef(m2)["treat_"])
  }, error = function(e) msg("lab error: ", conditionMessage(e)))

  # ---------------- Column (1): visual defects per bag ----------------
  tryCatch({
    kw <- "dirt|cob|stone|dust|insect|broken|immature|damag|rot|mou?ld|weevil"
    bad <- "random|weight|kg|moist|price|cost|ppk|amount"
    find_stems <- function(pool) {
      pool <- pool[grepl("_[0-9]+$", pool)]
      stem <- sub("_[0-9]+$", "", pool)
      bag <- as.integer(sub(".*_([0-9]+)$", "\\1", pool))
      list(pool = pool, stem = stem, bag = bag)
    }
    s <- find_stems(nm[grepl("^add4_", nm)])
    if (!length(s$pool)) s <- find_stems(nm)
    defstems <- unique(s$stem[grepl(kw, s$stem, ignore.case = TRUE) & !grepl(bad, s$stem, ignore.case = TRUE)])
    mode <- "binary"
    if (length(defstems) < 3) {
      st2 <- unique(s$stem[grepl("defect|quality|problem|issue", s$stem, ignore.case = TRUE) &
                             !grepl(bad, s$stem, ignore.case = TRUE)])
      ind <- st2[grepl("_[0-9]+$", st2)]
      if (length(ind) >= 3) {
        defstems <- ind
      } else if (length(st2)) {
        defstems <- st2
        mode <- "string"
      }
    }
    msg("visual defect stems (", mode, "): ", paste(defstems, collapse = ", "))
    bags <- sort(unique(s$bag[s$stem %in% defstems]))
    long <- list()
    for (b in bags) {
      cols <- paste0(defstems, "_", b)
      cols <- cols[cols %in% nm]
      if (!length(cols)) next
      if (mode == "binary") {
        X <- do.call(cbind, lapply(cols, function(v) {
          x <- rd[[v]]
          if (is.character(x)) {
            x <- trimws(x)
            ifelse(x == "", NA, ifelse(tolower(x) %in% c("0", "no"), 0, 1))
          } else num(x)
        }))
        has <- rowSums(!is.na(X)) > 0
        cnt <- rowSums(X > 0 & X < 90, na.rm = TRUE)
      } else {
        x <- as.character(rd[[cols[1]]])
        x[!is.na(x)] <- trimws(x[!is.na(x)])
        has <- !is.na(x) & x != ""
        cnt <- vapply(x, function(z) {
          if (is.na(z) || z == "") return(0)
          toks <- strsplit(z, "[ ,;]+")[[1]]
          toks <- toks[toks != "" & !toks %in% c("0", "none", "11", "99", "-99")]
          length(unique(toks))
        }, numeric(1))
      }
      long[[length(long) + 1]] <- data.frame(hh_ = rd$hh_, vill_ = rd$vill_, treat_ = rd$treat_,
                                             bag = b, vis = cnt)[has, ]
    }
    vis <- bind_rows(long)
    vis <- vis[!is.na(vis$treat_), ]
    m1 <- feols(vis ~ treat_ | vill_, data = vis, cluster = ~hh_)
    print(summary(m1))
    setres("treatment_defects_visual_table2_col1", coef(m1)["treat_"])
    setres("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) msg("visual error: ", conditionMessage(e)))

  # ---------------- Columns (3)-(5): sales ----------------
  tryCatch({
    a5 <- nm[grepl("^add5_", nm) & grepl("_[0-9]+$", nm)]
    st <- sub("_[0-9]+$", "", a5)
    ix <- as.integer(sub(".*_([0-9]+)$", "\\1", a5))
    msg("add5 stems: ", paste(unique(st), collapse = ", "))
    pst <- if ("add5_ppk" %in% st) "add5_ppk" else unique(pick(unique(st), "ppk|price"))[1]
    sales_idx <- sort(unique(ix[st == pst]))
    kgst <- unique(st[grepl("kg|weight|wt|qty|quant|volume", st, ignore.case = TRUE) &
                        !grepl("ppk|price|cost|amount|ugx|money|transport", st, ignore.case = TRUE)])
    kgst <- kgst[vapply(kgst, function(s0) {
      cs <- paste0(s0, "_", sales_idx); cs <- cs[cs %in% nm]
      length(cs) > 0 && any(vapply(cs, function(v) has_data(rd, v), logical(1)))
    }, logical(1))]
    msg("kg stems: ", paste(kgst, collapse = ", "))
    ystem <- kgst[grepl("meas|enum|scale|actual|true|our|weigh|verif", kgst, ignore.case = TRUE) &
                    !grepl("agree", kgst, ignore.case = TRUE)]
    zstem <- kgst[grepl("agree|paid|buyer|trader|deal|bought|record|claim|sold", kgst, ignore.case = TRUE)]
    zstem <- setdiff(zstem, ystem)
    getmat <- function(s0) sapply(sales_idx, function(j) {
      v <- paste0(s0, "_", j); if (v %in% nm) num(rd[[v]]) else rep(NA_real_, nrow(rd))
    })
    if (length(ystem) == 0 || length(zstem) == 0) {
      if (length(kgst) >= 2) {
        mm <- vapply(kgst, function(s0) mean(getmat(s0), na.rm = TRUE), numeric(1))
        o <- order(-mm)
        if (length(ystem) == 0) ystem <- setdiff(kgst[o], zstem)[1]
        if (length(zstem) == 0) zstem <- setdiff(kgst[o], ystem)[1]
      }
    }
    ystem <- ystem[1]; zstem <- zstem[1]
    msg("measured weight stem: ", ystem, " ; agreed weight stem: ", zstem)
    wst <- unique(st[grepl("date|day|week|when", st, ignore.case = TRUE) &
                       !grepl("start|end|submission|today", st, ignore.case = TRUE)])
    wst <- if (length(wst)) wst[1] else NA
    amst <- unique(st[grepl("amount|revenue|total_paid|ugx|money", st, ignore.case = TRUE)])
    msg("week stem: ", wst)
    rows <- list()
    for (j in sales_idx) {
      p <- num(rd[[paste0(pst, "_", j)]])
      yv <- if (!is.na(ystem) && paste0(ystem, "_", j) %in% nm) num(rd[[paste0(ystem, "_", j)]]) else rep(NA_real_, nrow(rd))
      zv <- if (!is.na(zstem) && paste0(zstem, "_", j) %in% nm) num(rd[[paste0(zstem, "_", j)]]) else rep(NA_real_, nrow(rd))
      if (all(is.na(zv)) && length(amst) && paste0(amst[1], "_", j) %in% nm) zv <- num(rd[[paste0(amst[1], "_", j)]]) / p
      wk <- if (!is.na(wst) && paste0(wst, "_", j) %in% nm) to_week(rd[[paste0(wst, "_", j)]]) else rep(NA_character_, nrow(rd))
      rows[[length(rows) + 1]] <- data.frame(hh_ = rd$hh_, vill_ = rd$vill_, treat_ = rd$treat_,
                                             sale = j, price = p, y = yv, z = zv, week = wk,
                                             stringsAsFactors = FALSE)
    }
    sl <- bind_rows(rows)
    sl <- sl[!is.na(sl$price) & sl$price > 0 & !is.na(sl$treat_), ]
    sl$week[is.na(sl$week)] <- "missing"
    sl$deduct <- ifelse(!is.na(sl$y) & sl$y > 0 & !is.na(sl$z), 100 * (sl$y - sl$z) / sl$y, NA)
    sl$netprice <- ifelse(!is.na(sl$y) & sl$y > 0 & !is.na(sl$z), sl$price * sl$z / sl$y, NA)
    msg("number of sales: ", nrow(sl))
    m3 <- feols(price ~ treat_ | vill_ + week, data = sl, cluster = ~hh_)
    print(summary(m3))
    setres("treatment_price_table2_col3", coef(m3)["treat_"])
    setres("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(feols(deduct ~ treat_ | vill_ + week, data = sl, cluster = ~hh_), error = function(e) NULL)
    if (!is.null(m4)) { print(summary(m4)); setres("treatment_deductions_table2_col4", coef(m4)["treat_"]) }
    m5 <- tryCatch(feols(netprice ~ treat_ | vill_ + week, data = sl, cluster = ~hh_), error = function(e) NULL)
    if (!is.null(m5)) { print(summary(m5)); setres("treatment_net_price_table2_col5", coef(m5)["treat_"]) }
  }, error = function(e) msg("sales error: ", conditionMessage(e)))
}

# =====================================================================
# Market access experiment (Table 6, Panel A)
# =====================================================================
tryCatch({
  pg <- clean_df(read_dta(file.path(raw, "panel_g1.dta")))
  pn <- names(pg)
  msg("panel_g1 columns: ", paste(pn, collapse = ", "))
  pg$season_ <- num(pg[["survey_season"]])
  post <- if ("season_post" %in% pn) num(pg$season_post) else rep(NA_real_, nrow(pg))
  if (all(is.na(post)) || length(unique(na.omit(post))) < 2) post <- as.numeric(pg$season_ > 3)
  pg$post_ <- post
  hc <- first_of(pn, c("hhh_id", "hh_id", "hhid", "hhh", "household_id"))
  vc <- first_of(pn, c("ea_code", "village", "village_id", "vill", "ea"))
  pg$hh_ <- as.character(pg[[hc]])
  pg$vill_ <- as.character(pg[[vc]])

  tc <- first_of(pn, c("treatment", "buy_treatment", "treat", "treated", "buy_treat", "treatment_group"))
  if (is.na(tc)) {
    cc <- pick(pn, "treat", excl = "post|_x_|inter")
    tc <- if (length(cc)) cc[1] else NA
  }
  if (!is.na(tc)) {
    pg$treat_ <- num(pg[[tc]])
  } else {
    sd <- clean_df(read_dta(file.path(raw, "seller_data.dta")))
    vt <- sd %>% mutate(ea = as.character(ea_code), bt = num(buy_treatment)) %>%
      group_by(ea) %>% summarise(t = max(bt, na.rm = TRUE), .groups = "drop")
    pg$treat_ <- vt$t[match(pg$vill_, vt$ea)]
  }
  pg$treat_ <- ave(pg$treat_, pg$vill_, FUN = function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE))
  msg("treatment column: ", tc, " ; table: ")
  print(table(pg$treat_, pg$season_, useNA = "ifany"))

  xc <- pick(pn, "exch|xrate|usd_rate|^fx|ex_rate")
  xr <- if (length(xc)) median(num(pg[[xc[1]]]), na.rm = TRUE) else 3700
  if (!is.finite(xr) || xr < 100) xr <- 3700

  excl_base <- "trim|wins|_w[0-9]*$|_t[0-9]+$|p99|_tr$|_[0-9]+$|_ps$"
  choose <- function(cands) {
    if (!length(cands)) return(NA_character_)
    cands <- cands[vapply(cands, function(v) has_data(pg, v), logical(1))]
    if (!length(cands)) return(NA_character_)
    u <- cands[grepl("usd|dollar", cands, ignore.case = TRUE)]
    if (length(u)) cands <- u
    cands[which.min(nchar(cands))]
  }
  to_usd <- function(x, nmv, thr) {
    if (grepl("usd|dollar", nmv, ignore.case = TRUE)) return(x)
    if (median(abs(x), na.rm = TRUE) > thr) x / xr else x
  }

  # price
  pv <- choose(pick(pn, "price", excl = paste0("cost|exp|premium|tc_|trading|market|vill|comm|centre|center|", excl_base)))
  if (!is.na(pv)) {
    pg$price_o <- to_usd(num(pg[[pv]]), pv, 5)
  } else {
    sd <- clean_df(read_dta(file.path(raw, "seller_data.dta")))
    sp <- sd %>% mutate(hh = as.character(hhh_id), s = num(survey_season), p = num(price),
                        k = num(sold_kg_p_)) %>%
      filter(!is.na(p), p > 0) %>%
      group_by(hh, s) %>%
      summarise(pr = if (sum(k, na.rm = TRUE) > 0) sum(p * k, na.rm = TRUE) / sum(k[!is.na(p)], na.rm = TRUE) else mean(p),
                .groups = "drop")
    pg$price_o <- sp$pr[match(paste(pg$hh_, pg$season_), paste(sp$hh, sp$s))]
    pg$price_o <- to_usd(pg$price_o, "x", 5)
    pv <- "seller_data(constructed)"
  }

  # harvest kg
  hk <- first_of(pn, c("harvest_kg_tot", "harvest_kg", "harvest_tot_kg", "harvest_tot", "harvest"))
  if (is.na(hk)) hk <- choose(pick(pn, "harv", excl = paste0("val|usd|cost|hour|price|", excl_base)))
  pg$harv_o <- num(pg[[hk]])

  # yield
  yv <- choose(pick(pn, "yield", excl = excl_base))
  if (!is.na(yv)) {
    pg$yield_o <- num(pg[[yv]])
  } else {
    ac <- first_of(pn, c("acres_tot", "plot_size_tot", "area_tot", "acre_tot", "plot_size", "acres", "area"))
    if (!is.na(ac)) area <- num(pg[[ac]]) else {
      ps <- pn[grepl("^plot_size_[0-9]+$", pn)]
      area <- rowSums(sapply(ps, function(v) num(pg[[v]])), na.rm = TRUE)
      area[area == 0] <- NA
    }
    pg$yield_o <- pg$harv_o / area
    yv <- "constructed"
  }

  # harvest value
  hv <- choose(pick(pn, "harv.*val|val.*harv|harvest_usd|harvestvalue|harvest_value|value_tot|revenue_tot", excl = excl_base))
  if (!is.na(hv)) pg$hval_o <- to_usd(num(pg[[hv]]), hv, 5000) else pg$hval_o <- NA_real_

  # profits
  prof <- pick(pn, "profit", excl = excl_base)
  own_pat <- "own|hour|fam|_hh|full|lab|imput|opp|incl|total"
  p_own <- choose(prof[grepl(own_pat, prof, ignore.case = TRUE)])
  p_mon <- choose(prof[grepl("mon|cash|exp", prof, ignore.case = TRUE) & !grepl(own_pat, prof, ignore.case = TRUE)])
  if (is.na(p_mon)) p_mon <- choose(prof[!grepl(own_pat, prof, ignore.case = TRUE)])
  pg$pmon_o <- if (!is.na(p_mon)) to_usd(num(pg[[p_mon]]), p_mon, 5000) else NA_real_
  pg$pown_o <- if (!is.na(p_own)) to_usd(num(pg[[p_own]]), p_own, 5000) else NA_real_
  msg("panel vars: price=", pv, " harvest=", hk, " yield=", yv, " hval=", hv,
      " profit_mon=", p_mon, " profit_own=", p_own, " xr=", xr)

  ancova <- function(var) {
    d <- pg[, c("hh_", "vill_", "season_", "post_", "treat_", var)]
    names(d)[6] <- "y"
    b <- d %>% filter(post_ == 0) %>% group_by(hh_) %>%
      summarise(base = if (all(is.na(y))) NA_real_ else mean(y, na.rm = TRUE), .groups = "drop")
    f <- d %>% filter(post_ == 1, !is.na(y), !is.na(treat_)) %>% left_join(b, by = "hh_")
    f$base_miss <- as.numeric(is.na(f$base))
    f$base[is.na(f$base)] <- 0
    fml <- if (length(unique(f$base_miss)) > 1) y ~ treat_ + base + base_miss | season_ else y ~ treat_ + base | season_
    m <- feols(fml, data = f, cluster = ~vill_)
    print(summary(m))
    m
  }
  run <- function(var, rname, nname = NULL) {
    tryCatch({
      if (all(is.na(pg[[var]]))) stop("no data for ", var)
      m <- ancova(var)
      setres(rname, coef(m)["treat_"])
      if (!is.null(nname)) setres(nname, nobs(m))
    }, error = function(e) msg(rname, " error: ", conditionMessage(e)))
  }
  run("price_o", "market_access_price_table6_panelA_col1")
  tryCatch({ m <- ancova("harv_o"); setres("n_obs_table6_panelA_cols3_5", nobs(m)) },
           error = function(e) msg("harvest error: ", conditionMessage(e)))
  run("yield_o", "market_access_yield_table6_panelA_col4")
  run("hval_o", "market_access_harvest_value_table6_panelA_col5")
  run("pmon_o", "market_access_profit_monetary_table6_panelA_col7")
  run("pown_o", "market_access_profit_incl_own_hours_table6_panelA_col8")
}, error = function(e) msg("panel error: ", conditionMessage(e)))

for (n in res_names) {
  v <- results[[n]]
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 10))))
}
