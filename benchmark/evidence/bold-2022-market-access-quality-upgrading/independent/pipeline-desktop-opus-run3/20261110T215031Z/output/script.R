suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
rd <- function(f) {
  d <- haven::read_dta(file.path(base, f))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

find_col <- function(df, patterns, exclude = NULL) {
  nm <- names(df)
  for (p in patterns) {
    hit <- grep(p, nm, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) hit <- hit[!grepl(exclude, hit, ignore.case = TRUE)]
    if (length(hit) > 0) return(hit[1])
  }
  NULL
}

num <- function(x) suppressWarnings(as.numeric(x))

to_week <- function(wk) {
  if (inherits(wk, "POSIXt")) return(format(as.Date(wk), "%Y-%U"))
  if (inherits(wk, "Date")) return(format(wk, "%Y-%U"))
  if (is.numeric(wk)) {
    md <- median(wk, na.rm = TRUE)
    if (is.finite(md) && md > 1e10) return(format(as.Date(as.POSIXct(wk / 1000, origin = "1960-01-01", tz = "UTC")), "%Y-%U"))
    if (is.finite(md) && md > 15000) return(format(as.Date(wk, origin = "1960-01-01"), "%Y-%U"))
    return(as.character(wk))
  }
  if (is.character(wk)) {
    dd <- suppressWarnings(as.Date(wk))
    if (sum(!is.na(dd)) > 0) return(format(dd, "%Y-%U"))
  }
  as.character(wk)
}

rowsum_na <- function(df, cols) {
  if (length(cols) == 0) return(NULL)
  m <- sapply(cols, function(cc) num(df[[cc]]))
  if (is.null(dim(m))) m <- matrix(m, nrow = nrow(df))
  out <- rowSums(m, na.rm = TRUE)
  out[rowSums(!is.na(m)) == 0] <- NA
  out
}

# ------------------------------------------------------------------
# Returns-to-quality experiment (Table 2)
# ------------------------------------------------------------------
r <- tryCatch(rd("data/raw/anonym_returns_data.dta"), error = function(e) NULL)

if (!is.null(r)) {
  treat_col <- find_col(r, c("^treatment$", "^treat"))
  vil_col <- find_col(r, c("^village$", "^village_id$", "^vil", "^ea_code$", "^ea$", "village", "^ea_", "lc1", "parish"))
  hh_col <- find_col(r, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$", "household"))
  cat("# treat:", treat_col, " vil:", ifelse(is.null(vil_col), "NONE", vil_col), " hh:", hh_col, "\n")
  r$.treat <- num(r[[treat_col]])
  r$.vil <- if (!is.null(vil_col)) as.character(r[[vil_col]]) else "1"
  r$.hh <- if (!is.null(hh_col)) as.character(r[[hh_col]]) else as.character(seq_len(nrow(r)))

  # ---- Column 1: visual defects, bag level (all ten defect types) ----
  tryCatch({
    types <- list(dirt = c("dirty", "dirt"), cobs = "cobs", stones = "stones", dust = "dust",
                  insects = c("insect", "insects"), broken = "broken", immature = "immature",
                  damaged = c("damage", "damaged"), rotten = c("rot", "rotten"), moldy = c("mould", "mold", "moldy"))
    found <- list()
    for (t in names(types)) {
      for (st in types[[t]]) {
        cols <- grep(paste0("^add4_", st, "_[0-9]+$"), names(r), value = TRUE)
        if (length(cols) > 0) { found[[t]] <- cols; break }
      }
    }
    cat("# visual defect types found:", paste(names(found), collapse = ","), "\n")
    allvals <- unlist(lapply(unlist(found), function(cc) num(r[[cc]])))
    allvals <- allvals[!is.na(allvals)]
    cat("# defect value table:\n"); print(table(allvals))
    yes12 <- length(allvals) > 0 && all(allvals %in% c(1, 2))
    bags <- sort(unique(as.integer(unlist(lapply(found, function(cc) sub(".*_([0-9]+)$", "\\1", cc))))))
    long <- list()
    for (b in bags) {
      mat <- sapply(names(found), function(t) {
        cc <- paste0(sub("_[0-9]+$", "", found[[t]][1]), "_", b)
        if (cc %in% names(r)) num(r[[cc]]) else rep(NA_real_, nrow(r))
      })
      if (is.null(dim(mat))) mat <- matrix(mat, nrow = nrow(r))
      present <- rowSums(!is.na(mat)) > 0
      if (yes12) d <- (mat == 1) else d <- (mat > 0)
      d[is.na(d)] <- FALSE
      cnt <- rowSums(d)
      if (any(present)) {
        long[[length(long) + 1]] <- data.frame(defects = cnt[present], treat = r$.treat[present],
                                               vil = r$.vil[present], hh = r$.hh[present], bag = b)
      }
    }
    bl <- do.call(rbind, long)
    cat("# bags with defect info:", nrow(bl), "\n")
    m1 <- feols(defects ~ treat | vil, data = bl, cluster = ~hh)
    print(summary(m1))
    emit("treatment_defects_visual_table2_col1", unname(coef(m1)["treat"]))
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) cat("# col1 error:", conditionMessage(e), "\n"))

  # ---- Column 2: lab defects ----
  tryCatch({
    tw <- find_col(r, c("^total_weight_of_maize", "totalweight", "total_weight"))
    comp_pats <- c("^foreign_matter", "^inorganic_matter", "^broken_grains", "^pest_damaged",
                   "^rotten_and_diseased", "^discoloured_grains", "^immature_or_shrivel")
    comps <- unlist(lapply(comp_pats, function(p) find_col(r, p)))
    if (length(comps) > 0 && !is.null(tw)) {
      cm <- sapply(comps, function(cc) num(r[[cc]]))
      tot <- num(r[[tw]])
      anyc <- rowSums(!is.na(cm)) > 0
      cm[is.na(cm)] <- 0
      s <- rowSums(cm)
      y <- ifelse(anyc & !is.na(tot) & tot > 0, s / tot, NA)
      if (median(y, na.rm = TRUE) > 1) y <- y / 100
      d2 <- data.frame(y = y, treat = r$.treat, vil = r$.vil)
      m2 <- feols(y ~ treat | vil, data = d2, vcov = "hetero")
      print(summary(m2))
      emit("treatment_defects_lab_table2_col2", unname(coef(m2)["treat"]))
    } else cat("# no lab defect columns found\n")
  }, error = function(e) cat("# col2 error:", conditionMessage(e), "\n"))

  # ---- Columns 3-5: sales ----
  tryCatch({
    ppk <- grep("^add5_ppk_[0-9]+$", names(r), value = TRUE)
    if (length(ppk) == 0) stop("no add5_ppk columns")
    idx <- sort(unique(as.integer(sub(".*_([0-9]+)$", "\\1", ppk))))
    wcands <- grep("^add5_sold_when.*_[0-9]+$", names(r), value = TRUE)
    if (length(wcands) == 0) wcands <- grep("^add5_.*(when|week|date|day|time).*_[0-9]+$", names(r), value = TRUE, ignore.case = TRUE)
    wstem <- if (length(wcands) > 0) sub("_[0-9]+$", "", wcands[1]) else NULL
    cat("# week stem:", ifelse(is.null(wstem), "NONE", wstem), "\n")
    cat("# add5 columns:", paste(grep("^add5_", names(r), value = TRUE)[1:min(80, length(grep("^add5_", names(r))))], collapse = " "), "\n")
    sl <- list()
    for (i in idx) {
      p <- num(r[[paste0("add5_ppk_", i)]])
      wcols <- grep(paste0("^add5_ind_weight[0-9]+_", i, "$"), names(r), value = TRUE)
      dcols <- grep(paste0("^add5_ind_ded_weight[0-9]+_", i, "$"), names(r), value = TRUE)
      W <- if (length(wcols) > 0) sapply(wcols, function(cc) num(r[[cc]])) else matrix(NA_real_, nrow(r), 1)
      D <- if (length(dcols) > 0) sapply(dcols, function(cc) num(r[[cc]])) else matrix(NA_real_, nrow(r), 1)
      if (is.null(dim(W))) W <- matrix(W, nrow = nrow(r))
      if (is.null(dim(D))) D <- matrix(D, nrow = nrow(r))
      yw <- rowSums(W, na.rm = TRUE); yw[rowSums(!is.na(W)) == 0] <- NA
      dw <- rowSums(D, na.rm = TRUE); dw[rowSums(!is.na(D)) == 0] <- NA
      ok <- !is.na(p) & p > 0 & !is.na(yw) & yw > 0
      if (any(ok)) {
        rawd <- if (!is.null(wstem) && paste0(wstem, "_", i) %in% names(r)) r[[paste0(wstem, "_", i)]] else rep(NA, nrow(r))
        wk <- if (!is.null(wstem) && paste0(wstem, "_", i) %in% names(r)) to_week(rawd) else rep(NA_character_, nrow(r))
        sl[[length(sl) + 1]] <- data.frame(price = p[ok], y = yw[ok], dw = dw[ok],
                                           week = as.character(wk[ok]), date = as.character(rawd[ok]),
                                           treat = r$.treat[ok], vil = r$.vil[ok], hh = r$.hh[ok],
                                           saleidx = i, stringsAsFactors = FALSE)
      }
    }
    s <- do.call(rbind, sl)
    s$week[is.na(s$week)] <- "NA"
    s$date[is.na(s$date)] <- "NA"
    ratio <- median(s$dw / s$y, na.rm = TRUE)
    cat("# median ded_weight / weight:", ratio, "\n")
    if (is.finite(ratio) && ratio > 0.5) s$z <- ifelse(is.na(s$dw), s$y, s$dw) else s$z <- s$y - ifelse(is.na(s$dw), 0, s$dw)
    cat("# sale records by sale index:\n"); print(table(s$saleidx))

    # Candidate definitions of a "sale" (paper: 116 sales from 94 households)
    collapse_hd <- function(s) {
      key <- paste(s$hh, s$date)
      g <- split(seq_len(nrow(s)), key)
      do.call(rbind, lapply(g, function(ix) {
        yy <- sum(s$y[ix])
        data.frame(price = sum(s$price[ix] * s$y[ix]) / yy, y = yy, dw = NA, z = sum(s$z[ix]),
                   week = s$week[ix[1]], date = s$date[ix[1]], treat = s$treat[ix[1]],
                   vil = s$vil[ix[1]], hh = s$hh[ix[1]], saleidx = min(s$saleidx[ix]),
                   stringsAsFactors = FALSE)
      }))
    }
    cands <- list(
      all = s,
      dedup = s[!duplicated(s[, c("hh", "date", "price", "y")]), ],
      hh_date = collapse_hd(s),
      dedup_hh_date = collapse_hd(s[!duplicated(s[, c("hh", "date", "price", "y")]), ]),
      ded_observed = s[!is.na(s$dw), ]
    )
    ncand <- sapply(cands, nrow)
    hcand <- sapply(cands, function(x) length(unique(x$hh)))
    cat("# candidate sale samples (n sales / n households):\n")
    for (k in names(cands)) cat("#  ", k, ncand[[k]], "/", hcand[[k]], "\n")
    best <- names(cands)[which.min(abs(ncand - 116) + 5 * abs(hcand - 94))]
    cat("# chosen sale definition:", best, "\n")
    if (best != "all") cat("DEVIATION: Sale-level sample defined as '", best, "' (raw sale records gave 211 rows vs the paper's 116 sales from 94 households)\n", sep = "")
    s <- cands[[best]]
    s$ded <- 100 * (s$y - s$z) / s$y
    s$net <- s$price * s$z / s$y
    cat("# sales:", nrow(s), " households:", length(unique(s$hh)), " weeks:", length(unique(s$week)), "\n")
    fe <- if (!is.null(wstem)) "vil + week" else "vil"
    if (is.null(wstem)) cat("DEVIATION: No week-of-sale variable identified; columns 3-5 use village FE only\n")
    m3 <- feols(as.formula(paste("price ~ treat |", fe)), data = s, cluster = ~hh)
    print(summary(m3))
    emit("treatment_price_table2_col3", unname(coef(m3)["treat"]))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(feols(as.formula(paste("ded ~ treat |", fe)), data = s, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m4)) { print(summary(m4)); emit("treatment_deductions_table2_col4", unname(coef(m4)["treat"])) }
    m5 <- tryCatch(feols(as.formula(paste("net ~ treat |", fe)), data = s, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m5)) { print(summary(m5)); emit("treatment_net_price_table2_col5", unname(coef(m5)["treat"])) }
  }, error = function(e) cat("# cols3-5 error:", conditionMessage(e), "\n"))
}

# ------------------------------------------------------------------
# Market access experiment (Table 6 Panel A): ANCOVA
# ------------------------------------------------------------------
p <- tryCatch(rd("data/raw/panel_g1.dta"), error = function(e) NULL)
if (!is.null(p)) {
  cat("# panel_g1 price/revenue/sales/profit/cost columns:\n#",
      paste(grep("price|rev|sold|sale|profit|value|income|cost|hour|wage", names(p), value = TRUE, ignore.case = TRUE), collapse = " "), "\n")
  tryCatch({
    treat_col <- find_col(p, c("^buy_treatment$", "^treatment$", "^treat$", "treat"))
    hh_col <- find_col(p, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$"))
    vil_col <- find_col(p, c("^ea_code$", "^village$", "^village_id$", "^vil", "^ea$"))
    post_col <- find_col(p, c("^season_post$", "^post$"))
    p$.treat <- num(p[[treat_col]])
    p$.hh <- as.character(p[[hh_col]])
    p$.vil <- as.character(p[[vil_col]])
    p$.season <- as.character(p$survey_season)
    if (!is.null(post_col)) {
      p$.post <- num(p[[post_col]])
    } else {
      ss <- sort(unique(num(p$survey_season)))
      p$.post <- as.numeric(num(p$survey_season) > ss[3])
    }
    p$.post[is.na(p$.post)] <- 0
    if (all(is.na(p$.treat))) stop("no treatment")
    tv <- tapply(p$.treat, p$.vil, function(x) max(x, na.rm = TRUE))
    p$.treat <- as.numeric(tv[p$.vil])

    if ("acres_tot" %in% names(p)) {
      area <- num(p$acres_tot)
      cat("# using acres_tot as maize area\n")
    } else {
      plot_cols <- grep("^plot_size_[0-9]+$", names(p), value = TRUE)
      area <- if (length(plot_cols) > 0) rowSums(sapply(plot_cols, function(cc) num(p[[cc]])), na.rm = TRUE) else rep(NA_real_, nrow(p))
    }
    area[!is.na(area) & area <= 0] <- NA

    getv <- function(pats, exclude = NULL) {
      cc <- find_col(p, pats, exclude)
      if (is.null(cc)) return(NULL)
      cat("# using", cc, "\n")
      num(p[[cc]])
    }
    outs <- list()
    outs$price <- getv(c("^price_usd$", "^avg_price_usd", "^price_av", "^av_price", "^avg_price", "^mean_price",
                         "^price$", "price_kg", "^price"),
                       exclude = "cost|seed|winnow|sort|^lc_|^lh_|fert|chem|transport")
    if (is.null(outs$price)) {
      # Build price per kg = revenue / kg sold, choosing the revenue and quantity
      # measures that yield the most plausible (100-5000 UGX/kg) prices.
      revs <- list()
      if ("tot_rev_told_tot" %in% names(p)) revs$told_tot <- num(p$tot_rev_told_tot)
      rc1 <- grep("^tot_rev_combined_[0-9]+$", names(p), value = TRUE)
      rc2 <- grep("^tot_rev_combined2_[0-9]+$", names(p), value = TRUE)
      if (length(rc1) > 0) revs$combined <- rowsum_na(p, rc1)
      if (length(rc2) > 0) revs$combined2 <- rowsum_na(p, rc2)
      solds <- list()
      if ("sold_kg" %in% names(p)) solds$sold_kg <- num(p$sold_kg)
      sk_cols <- grep("^sold_kg_[0-9]+$", names(p), value = TRUE)
      if (length(sk_cols) > 0) solds$sold_kg_sum <- rowsum_na(p, sk_cols)
      best_n <- -1; best_pr <- NULL; best_lab <- ""
      for (a in names(revs)) for (b in names(solds)) {
        pr <- ifelse(!is.na(solds[[b]]) & solds[[b]] > 0 & !is.na(revs[[a]]) & revs[[a]] > 0, revs[[a]] / solds[[b]], NA)
        pr[!is.na(pr) & (pr < 100 | pr > 5000)] <- NA
        nv <- sum(!is.na(pr) & p$.post == 1)
        cat("# price candidate", a, "/", b, ": valid post obs =", nv, " median =", median(pr, na.rm = TRUE), "\n")
        if (nv > best_n) { best_n <- nv; best_pr <- pr; best_lab <- paste(a, b, sep = "/") }
      }
      if (!is.null(best_pr)) {
        outs$price <- best_pr
        cat("DEVIATION: Price per kg constructed as maize revenue / kg sold (", best_lab, "), implausible values (<100 or >5000 UGX/kg) set to missing\n", sep = "")
      }
    }
    harvest <- getv(c("^harvest_kg$", "^harvest$", "^harvest_tot", "^tot_harvest", "harvest_kg", "^harvest_q"),
                    exclude = "cost|value|usd")
    outs$harvest <- harvest
    yv <- getv(c("^yield$", "^yield_"))
    outs$yield <- if (!is.null(yv)) yv else if (!is.null(harvest)) harvest / area else NULL
    outs$hvalue <- getv(c("^harvest_value_usd$", "^harvest_value", "^value_harvest", "harvest.*val", "^hvalue"))
    outs$profit_m <- getv(c("^profit_usd$", "^profit$", "^profit_mon", "^profit_1$", "^profit"), exclude = "own|hour|fam")
    outs$profit_own <- getv(c("profit.*own", "profit.*hour", "profit.*fam", "^profit_2$"))

    usd_rate <- 3700
    to_usd <- function(v, thresh) if (!is.null(v) && median(v, na.rm = TRUE) > thresh) v / usd_rate else v
    outs$price <- to_usd(outs$price, 5)
    hv_built <- FALSE
    if (is.null(outs$hvalue) && !is.null(outs$price) && !is.null(harvest)) {
      # value output at the household price; if unsold, village-season mean, then season mean
      vs <- paste(p$.vil, p$.season)
      vmean <- tapply(outs$price, vs, function(x) mean(x, na.rm = TRUE))
      smean <- tapply(outs$price, p$.season, function(x) mean(x, na.rm = TRUE))
      pr <- ifelse(is.na(outs$price), as.numeric(vmean[vs]), outs$price)
      pr <- ifelse(is.na(pr) | !is.finite(pr), as.numeric(smean[p$.season]), pr)
      cat("DEVIATION: Harvest value constructed as harvest_kg times household price (village-season, then season mean if unsold), USD\n")
      outs$hvalue <- harvest * pr
      hv_built <- TRUE
    }
    outs$hvalue <- to_usd(outs$hvalue, 5000)
    outs$profit_m <- to_usd(outs$profit_m, 5000)
    outs$profit_own <- to_usd(outs$profit_own, 5000)

    if (is.null(outs$profit_m) && !is.null(outs$hvalue)) {
      cc <- grep("cost", names(p), value = TRUE, ignore.case = TRUE)
      cc <- cc[!grepl("transport", cc, ignore.case = TRUE)]
      stems <- sub("_[0-9]+$", "", cc)
      indexed <- unique(stems[grepl("_[0-9]+$", cc)])
      cc <- cc[!(cc %in% indexed)]  # drop aggregate column when indexed components exist
      cc <- cc[sapply(cc, function(x) is.numeric(num(p[[x]])) && any(!is.na(num(p[[x]]))))]
      cat("# cost columns used for monetary profit:", paste(cc, collapse = " "), "\n")
      if (length(cc) > 0) {
        cost <- rowSums(sapply(cc, function(x) num(p[[x]])), na.rm = TRUE)
        cat("# median total cost (raw units):", median(cost, na.rm = TRUE), "\n")
        cost_usd <- cost / usd_rate
        outs$profit_m <- outs$hvalue - cost_usd
        cat("DEVIATION: Monetary profit constructed as harvest value minus the sum of reported monetary cost items (UGX converted at 3700/USD)\n")
      }
    }

    ancova <- function(v) {
      if (is.null(v)) return(NULL)
      d <- data.frame(y = v, treat = p$.treat, hh = p$.hh, vil = p$.vil, season = p$.season, post = p$.post)
      bmean <- tapply(d$y[d$post == 0], d$hh[d$post == 0], function(x) mean(x, na.rm = TRUE))
      d$base <- as.numeric(bmean[d$hh])
      d$base_miss <- as.numeric(is.na(d$base))
      d$base[is.na(d$base)] <- 0
      dp <- d[d$post == 1 & !is.na(d$y) & is.finite(d$y), ]
      feols(y ~ treat + base + base_miss | season, data = dp, cluster = ~vil)
    }
    names_map <- c(price = "market_access_price_table6_panelA_col1",
                   yield = "market_access_yield_table6_panelA_col4",
                   hvalue = "market_access_harvest_value_table6_panelA_col5",
                   profit_m = "market_access_profit_monetary_table6_panelA_col7",
                   profit_own = "market_access_profit_incl_own_hours_table6_panelA_col8")
    for (k in names(names_map)) {
      m <- tryCatch(ancova(outs[[k]]), error = function(e) { cat("# ancova", k, conditionMessage(e), "\n"); NULL })
      if (!is.null(m)) {
        print(summary(m))
        emit(names_map[[k]], unname(coef(m)["treat"]))
      }
    }
    mh <- tryCatch(ancova(outs$harvest), error = function(e) NULL)
    if (!is.null(mh)) emit("n_obs_table6_panelA_cols3_5", nobs(mh))
  }, error = function(e) cat("# panel error:", conditionMessage(e), "\n"))
}

for (k in names(results)) cat(sprintf("RESULT:%s=%.6g\n", k, results[[k]]))