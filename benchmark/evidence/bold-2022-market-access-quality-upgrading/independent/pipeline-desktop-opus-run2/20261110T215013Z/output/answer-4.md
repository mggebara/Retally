suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
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
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  results[[name]] <<- as.numeric(val)
}

find_col <- function(df, exact = character(0), regex = NULL, exclude = NULL) {
  nm <- names(df)
  for (e in exact) if (e %in% nm) return(e)
  if (!is.null(regex)) {
    cand <- grep(regex, nm, value = TRUE, ignore.case = TRUE)
    if (!is.null(exclude)) cand <- cand[!grepl(exclude, cand, ignore.case = TRUE)]
    if (length(cand) > 0) return(cand[1])
  }
  NULL
}

to_num <- function(x) {
  if (is.numeric(x)) return(as.numeric(x))
  suppressWarnings(as.numeric(as.character(x)))
}

get_coef <- function(m, v = "treat") {
  cf <- coef(m)
  if (v %in% names(cf)) return(unname(cf[v]))
  NA
}

rowsum_na <- function(df, cols) {
  if (length(cols) == 0) return(rep(NA_real_, nrow(df)))
  mat <- sapply(cols, function(cn) to_num(df[[cn]]))
  if (is.null(dim(mat))) mat <- matrix(mat, ncol = length(cols))
  s <- rowSums(mat, na.rm = TRUE)
  s[rowSums(!is.na(mat)) == 0] <- NA
  s
}

# ------------------------------------------------------------------
# Returns-to-quality experiment (Table 2)
# ------------------------------------------------------------------
ret <- tryCatch(rd("data/raw/anonym_returns_data.dta"), error = function(e) NULL)

if (!is.null(ret)) {
  stems <- unique(sub("_[0-9]+$", "", grep("_[0-9]+$", names(ret), value = TRUE)))
  cat("Indexed stems (non add5_ind):\n"); print(stems[!grepl("^add5_ind_", stems)])
  cat("Non-indexed columns:\n"); print(names(ret)[!grepl("_[0-9]+$", names(ret))])

  ret$treat <- to_num(ret[[find_col(ret, c("treatment", "treat"), "treat")]])
  ret$hh_row <- seq_len(nrow(ret))
  hhcol <- find_col(ret, c("hhh_id", "hh_id", "hhid", "household_id"), "hh.*id")
  ret$hh <- if (!is.null(hhcol)) as.character(ret[[hhcol]]) else as.character(ret$hh_row)
  cat("Rows in returns data:", nrow(ret), " distinct households:", length(unique(ret$hh)), "\n")
  vcol <- find_col(ret, c("village", "village_id", "ea_code", "vill", "village_code", "lc1", "ea"),
                   "^(village|vill|ea_)", exclude = "_[0-9]+$")
  ret$vill <- if (!is.null(vcol)) as.character(ret[[vcol]]) else "1"
  cat("Village column:", ifelse(is.null(vcol), "NONE", vcol), "\n")

  # ---- Col 1: visual defects per bag ----
  tryCatch({
    types <- c("dirt", "cob", "stone", "dust", "insect", "broken", "immature", "damage", "rotten", "mold|mould")
    defcols <- grep(paste0("^add4_.*(", paste(types, collapse = "|"), ").*_[0-9]+$"),
                    names(ret), value = TRUE, ignore.case = TRUE)
    cat("Number of defect columns:", length(defcols), "\n")
    long <- ret[, c("hh", "vill", "treat", defcols)] %>%
      mutate(across(all_of(defcols), to_num)) %>%
      pivot_longer(all_of(defcols), names_to = "var", values_to = "val") %>%
      mutate(bag = as.integer(sub(".*_([0-9]+)$", "\\1", var)),
             stem = sub("_[0-9]+$", "", var))
    vals <- unique(na.omit(long$val))
    if (all(vals %in% c(1, 2))) {
      long$pres <- as.numeric(long$val == 1)
    } else {
      long$pres <- as.numeric(long$val > 0)
    }
    bags <- long %>% group_by(hh, vill, treat, bag) %>%
      summarise(nonmiss = sum(!is.na(val)),
                defects = sum(pres, na.rm = TRUE), .groups = "drop") %>%
      filter(nonmiss > 0)
    m1 <- feols(defects ~ treat | vill, data = bags, cluster = ~hh)
    print(summary(m1))
    emit("treatment_defects_visual_table2_col1", get_coef(m1))
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) cat("Col1 error:", conditionMessage(e), "\n"))

  # ---- Col 2: lab defects ----
  tryCatch({
    nm <- names(ret)
    nm_clean <- tolower(gsub("_", "", nm))
    gcols <- nm[grepl("^(foreign|inorganic|broken|pest|rotten|discolou|immature)", nm_clean) &
                  !grepl("_[0-9]+$", nm)]
    wcol <- nm[grepl("^totalweight", nm_clean)][1]
    if (length(gcols) == 0) stop("no lab defect column")
    gsum <- rowsum_na(ret, gcols)
    tot <- if (!is.na(wcol)) to_num(ret[[wcol]]) else rep(200, nrow(ret))
    tot[is.na(tot) | tot <= 0] <- 200
    ret$labdef <- gsum / tot
    m2 <- feols(labdef ~ treat | vill, data = ret[!is.na(ret$labdef), ], vcov = "hetero")
    print(summary(m2))
    emit("treatment_defects_lab_table2_col2", get_coef(m2))
  }, error = function(e) cat("Col2 error:", conditionMessage(e), "\n"))

  # ---- Cols 3-5: sales ----
  tryCatch({
    idx <- grep("_[0-9]+$", names(ret), value = TRUE)
    sale_idx <- idx[grepl("^add5", idx)]
    sstems <- unique(sub("_[0-9]+$", "", sale_idx))
    sstems_short <- sstems[!grepl("^add5_ind_(ded_)?weight[0-9]+$", sstems)]
    cat("Sale stems (excluding bag weights):\n"); print(sstems_short)
    pstem <- if ("add5_ppk" %in% sstems) "add5_ppk" else grep("(ppk|price)", sstems, value = TRUE, ignore.case = TRUE)[1]
    # The sale date is recorded in add5_sold_when_e ("when sold")
    wstems <- grep("(week|date|day|wk|when)", sstems, value = TRUE, ignore.case = TRUE)
    wstems <- wstems[!grepl("weight", wstems, ignore.case = TRUE)]
    wstem <- if (length(wstems)) wstems[1] else NULL
    cat("stems used: price=", pstem, " week=", ifelse(is.null(wstem), "NONE", wstem), "\n")
    hh_week <- NULL
    if (is.null(wstem)) {
      wc <- grep("(week|date|wk)", names(ret), value = TRUE, ignore.case = TRUE)
      wc <- wc[!grepl("weight", wc, ignore.case = TRUE)]
      cat("Household-level week/date candidates:\n"); print(wc)
      if (length(wc)) hh_week <- ret[[wc[1]]]
    }
    ks <- sort(unique(as.integer(sub(".*_([0-9]+)$", "\\1",
                                     grep(paste0("^", pstem, "_[0-9]+$"), names(ret), value = TRUE)))))
    sales <- do.call(rbind, lapply(ks, function(k) {
      wcols <- grep(paste0("^add5_ind_weight[0-9]+_", k, "$"), names(ret), value = TRUE)
      dcols <- grep(paste0("^add5_ind_ded_weight[0-9]+_", k, "$"), names(ret), value = TRUE)
      wk <- if (!is.null(wstem) && paste0(wstem, "_", k) %in% names(ret)) ret[[paste0(wstem, "_", k)]] else
        if (!is.null(hh_week)) hh_week else rep(NA, nrow(ret))
      if (inherits(wk, "Date")) wk <- as.numeric(wk)
      if (inherits(wk, "POSIXt")) wk <- as.numeric(as.Date(wk))
      data.frame(hh = ret$hh, vill = ret$vill, treat = ret$treat, k = k,
                 price = to_num(ret[[paste0(pstem, "_", k)]]),
                 ysum = rowsum_na(ret, wcols), dsum = rowsum_na(ret, dcols),
                 week = I(wk), stringsAsFactors = FALSE)
    }))
    sales$week <- unclass(sales$week)
    cat("Raw week variable sample:\n"); print(head(unique(sales$week[!is.na(sales$week)]), 20))
    sales <- sales[!is.na(sales$price) & sales$price > 0, ]
    cat("Sales with positive price:", nrow(sales), "\n")
    sales <- sales[!is.na(sales$ysum) & sales$ysum > 0, ]
    cat("Sales with price and recorded weight:", nrow(sales), "\n")
    sales <- sales[!duplicated(sales[, c("hh", "price", "ysum", "dsum")]), ]
    cat("Sales after removing duplicate records:", nrow(sales), " households:", length(unique(sales$hh)), "\n")
    r <- median(sales$dsum / sales$ysum, na.rm = TRUE)
    cat("Median ded_weight / weight ratio:", r, "\n")
    if (!is.na(r) && r > 0.5) {
      sales$y <- sales$ysum
      sales$z <- ifelse(is.na(sales$dsum), sales$ysum, sales$dsum)
    } else {
      sales$y <- sales$ysum
      sales$z <- sales$ysum - ifelse(is.na(sales$dsum), 0, sales$dsum)
    }
    # Convert sale date to week of sale
    wv <- sales$week
    if (is.character(wv)) {
      dd <- suppressWarnings(as.Date(wv, tryFormats = c("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%d%b%Y"), optional = TRUE))
      wv <- ifelse(is.na(dd), ifelse(wv == "", NA, wv), format(dd, "%Y-%U"))
    } else if (is.numeric(wv) && isTRUE(median(wv, na.rm = TRUE) > 1e9)) {
      wv <- format(as.Date(as.POSIXct(wv / 1000, origin = "1960-01-01", tz = "UTC")), "%Y-%U")
    } else if (is.numeric(wv) && isTRUE(median(wv, na.rm = TRUE) > 1000)) {
      wv <- format(as.Date(wv, origin = "1960-01-01"), "%Y-%U")
    }
    sales$week <- as.character(wv)
    cat("Sales with non-missing sale date:", sum(!is.na(sales$week)), "\n")
    if (sum(!is.na(sales$week)) > 0) {
      sales <- sales[!is.na(sales$week), ]
      cat("DEVIATION: Sale records restricted to entries with positive price, recorded bag weight and a recorded sale date (add5_sold_when_e), used for the week-of-sale fixed effect\n")
    } else {
      sales$week[is.na(sales$week)] <- "none"
    }
    cat("Sales used:", nrow(sales), " households:", length(unique(sales$hh)), "\n")
    cat("Distinct weeks:", length(unique(sales$week)), "\n")
    sales$deduct <- (sales$y - sales$z) / sales$y * 100
    sales$netprice <- sales$price * sales$z / sales$y
    print(summary(sales[, c("price", "y", "z", "deduct", "netprice")]))
    m3 <- feols(price ~ treat | vill + week, data = sales, cluster = ~hh)
    print(summary(m3))
    emit("treatment_price_table2_col3", get_coef(m3))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(feols(deduct ~ treat | vill + week, data = sales, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m4)) { print(summary(m4)); emit("treatment_deductions_table2_col4", get_coef(m4)) }
    m5 <- tryCatch(feols(netprice ~ treat | vill + week, data = sales, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m5)) { print(summary(m5)); emit("treatment_net_price_table2_col5", get_coef(m5)) }
  }, error = function(e) cat("Cols3-5 error:", conditionMessage(e), "\n"))
}

# ------------------------------------------------------------------
# Market access experiment (Table 6 Panel A)
# ------------------------------------------------------------------
usd <- 3700
tryCatch({
  p <- rd("data/raw/panel_g1.dta")
  cat("panel_g1 columns:\n"); print(names(p))
  tcol <- find_col(p, c("buy_treatment", "treatment", "treat", "treated"), "treat")
  p$treat <- to_num(p[[tcol]])
  if (all(is.na(p$treat))) stop("no treatment")
  if (!all(na.omit(unique(p$treat)) %in% c(0, 1))) p$treat <- as.numeric(p$treat == max(p$treat, na.rm = TRUE))
  vcol <- find_col(p, c("ea_code", "village", "village_id", "vill"), "^(ea|vill)")
  hcol <- find_col(p, c("hhh_id", "hh_id", "hhid"), "hh.*id")
  p$vill <- as.character(p[[vcol]]); p$hh <- as.character(p[[hcol]])
  p$season <- to_num(p$survey_season)
  if ("season_post" %in% names(p)) {
    p$post <- to_num(p$season_post)
  } else {
    p$post <- as.numeric(p$season > 3)
  }
  if (!all(na.omit(unique(p$post)) %in% c(0, 1))) p$post <- as.numeric(p$post > 0)

  # area
  pscols <- grep("^plot_size_[0-9]+$", names(p), value = TRUE)
  area <- rowSums(sapply(pscols, function(cn) to_num(p[[cn]])), na.rm = TRUE)
  area[area <= 0] <- NA
  acol <- find_col(p, c("maize_area", "area", "total_area", "plot_size_tot", "plot_size"), NULL)
  if (!is.null(acol)) area <- to_num(p[[acol]])
  p$area <- area

  # harvest kg
  hvcol <- find_col(p, c("harvest_kg", "harvest", "harvest_tot", "total_harvest", "harvest_total", "maize_harvest"),
                    "harvest", exclude = "cost|value|_[0-9]+$|labo|hour|date")
  p$harvest <- to_num(p[[hvcol]])
  cat("harvest column:", hvcol, "\n")

  # price (UGX/kg) of maize sold. Labour-cost ("lc_") and input prices are not maize prices.
  pcands <- grep("(price|ppk|per_kg|perkg)", names(p), value = TRUE, ignore.case = TRUE)
  pcands <- pcands[!grepl("^lc_|cost|seed|fert|chem|labo|wage|hire", pcands, ignore.case = TRUE)]
  cat("maize price-like columns:\n"); print(pcands)
  plaus <- function(x) { x[!is.na(x) & (x < 50 | x > 5000)] <- NA; x }
  opts <- list()
  for (cn in pcands[!grepl("_[0-9]+$", pcands)]) opts[[paste0("col:", cn)]] <- plaus(to_num(p[[cn]]))
  pc <- pcands[grepl("_[0-9]+$", pcands)]
  if (length(pc) > 0) {
    num <- 0; den <- 0
    for (i in seq_along(pc)) {
      pr <- plaus(to_num(p[[pc[i]]]))
      kcands <- c(sub("price", "sold_kg", pc[i]), sub("price", "kg_sold", pc[i]), sub("price", "quantity", pc[i]),
                  sub("price", "qty", pc[i]), sub("price", "kg", pc[i]), sub("price", "sold", pc[i]))
      kcn <- kcands[kcands %in% names(p) & kcands != pc[i]][1]
      kg <- if (!is.na(kcn)) to_num(p[[kcn]]) else rep(1, nrow(p))
      kg[is.na(kg) | kg <= 0] <- if (is.na(kcn)) 1 else NA
      ok <- !is.na(pr) & !is.na(kg)
      num <- num + ifelse(ok, pr * kg, 0); den <- den + ifelse(ok, kg, 0)
    }
    opts[["indexed_price"]] <- ifelse(den > 0, num / den, NA)
    # unweighted mean of indexed prices
    pm <- sapply(pc, function(cn) plaus(to_num(p[[cn]])))
    if (is.null(dim(pm))) pm <- matrix(pm, ncol = length(pc))
    mm <- rowMeans(pm, na.rm = TRUE); mm[is.nan(mm)] <- NA
    opts[["indexed_price_mean"]] <- mm
  }
  # indexed revenue / quantity pairs (sale-level records)
  idxc <- grep("_[0-9]+$", names(p), value = TRUE)
  idxc <- idxc[!grepl("^lc_|cost|seed|fert|chem|labo|wage|hire|plot", idxc, ignore.case = TRUE)]
  rev_i <- idxc[grepl("(rev|amount|value|income|receiv|earn|money)", idxc, ignore.case = TRUE)]
  qty_i <- idxc[grepl("(sold|quant|qty|kg)", idxc, ignore.case = TRUE) &
                  !grepl("(rev|amount|value|income|receiv|earn|money|price|date|when)", idxc, ignore.case = TRUE)]
  cat("indexed revenue candidates:\n"); print(rev_i); cat("indexed quantity candidates:\n"); print(qty_i)
  if (length(rev_i) && length(qty_i)) {
    rs <- unique(sub("_[0-9]+$", "", rev_i)); qs <- unique(sub("_[0-9]+$", "", qty_i))
    for (a in rs) for (b in qs) {
      ra <- grep(paste0("^", a, "_[0-9]+$"), names(p), value = TRUE)
      kk <- sub(".*_([0-9]+)$", "\\1", ra)
      qb <- paste0(b, "_", kk)
      keep <- qb %in% names(p)
      if (!any(keep)) next
      rr <- rowsum_na(p, ra[keep]); qq <- rowsum_na(p, qb[keep])
      opts[[paste0("idx_rev_over_qty:", a, "/", b)]] <- plaus(ifelse(!is.na(qq) & qq > 0, rr / qq, NA))
    }
  }
  revc <- grep("(tot_rev|revenue|rev_|_rev|income|sales_val|value_sold|amount)", names(p), value = TRUE, ignore.case = TRUE)
  revc <- revc[!grepl("_[0-9]+$|^lc_|cost", revc, ignore.case = TRUE)]
  soldc <- grep("(sold|quant_sold|qty_sold|sale)", names(p), value = TRUE, ignore.case = TRUE)
  soldc <- soldc[!grepl("_[0-9]+$|price|rev|value|date|^lc_|cost", soldc, ignore.case = TRUE)]
  cat("revenue candidates:\n"); print(revc); cat("quantity sold candidates:\n"); print(soldc)
  if (length(revc) && length(soldc)) {
    for (rc in revc) for (sc in soldc) {
      rv <- to_num(p[[rc]]); sk <- to_num(p[[sc]])
      opts[[paste0("rev_over_sold:", rc, "/", sc)]] <- plaus(ifelse(!is.na(sk) & sk > 0, rv / sk, NA))
    }
  }
  cov <- sapply(opts, function(x) sum(!is.na(x)))
  cov_post <- sapply(opts, function(x) sum(!is.na(x) & p$post == 1, na.rm = TRUE))
  cat("Price option coverage (all / post):\n"); print(rbind(cov, cov_post))
  if (length(opts) == 0 || max(cov) == 0) stop("no price")
  best <- names(cov_post)[which.max(cov_post)]
  cat("Price construction used:", best, "\n")
  cat("DEVIATION: Maize price excludes labour-cost (lc_) and input price columns; chosen as the maize sale price construction with the widest post-treatment coverage\n")
  p$price_ugx <- opts[[best]]
  p$price_usd <- p$price_ugx / usd

  # community price for harvest value
  p <- p %>% group_by(vill, season) %>% mutate(comm_price = median(price_ugx, na.rm = TRUE)) %>% ungroup() %>%
    group_by(season) %>% mutate(comm_price = ifelse(is.na(comm_price), median(price_ugx, na.rm = TRUE), comm_price)) %>%
    ungroup() %>% as.data.frame()
  p$comm_price[is.na(p$comm_price)] <- median(p$price_ugx, na.rm = TRUE)
  hvalcol <- find_col(p, c("harvest_value", "harvest_val", "value_harvest"), "harvest_val")
  p$hvalue <- if (!is.null(hvalcol)) to_num(p[[hvalcol]]) / usd else p$harvest * p$comm_price / usd
  p$yield <- p$harvest / p$area

  # monetary costs
  ccols <- grep("cost", names(p), value = TRUE)
  ccols <- ccols[!grepl("^(seeds_cost)$", ccols) | !any(grepl("^seeds_cost_[0-9]+$", names(p)))]
  ccols <- ccols[!grepl("own|family|fam", ccols)]
  cat("cost columns:\n"); print(ccols)
  cmat <- sapply(ccols, function(cn) to_num(p[[cn]]))
  if (is.null(dim(cmat))) cmat <- matrix(cmat, ncol = length(ccols))
  p$cost <- rowSums(cmat, na.rm = TRUE) / usd
  p$profit_m <- p$hvalue - p$cost

  # own labor hours
  hcols <- grep("hour", names(p), value = TRUE)
  own <- hcols[grepl("own|fam|hh|household", hcols)]
  if (length(own) == 0) own <- hcols[!grepl("hire", hcols)]
  wcol <- find_col(p, c("wage", "market_wage", "wage_hour", "hourly_wage"), "wage")
  if (length(own) > 0) {
    omat <- sapply(own, function(cn) to_num(p[[cn]]))
    if (is.null(dim(omat))) omat <- matrix(omat, ncol = length(own))
    ownh <- rowSums(omat, na.rm = TRUE)
    wage <- if (!is.null(wcol)) to_num(p[[wcol]]) else 1000
    p$profit_h <- p$profit_m - ownh * wage / usd
  } else p$profit_h <- NA

  cat("DEVIATION: Missing household baseline means set to 0 with a missing-baseline indicator in the ANCOVA (estimating equation not in excerpt)\n")
  ancova <- function(v) {
    bl <- p %>% filter(post == 0) %>% group_by(hh) %>% summarise(base = mean(.data[[v]], na.rm = TRUE), .groups = "drop")
    d <- p %>% filter(post == 1) %>% left_join(bl, by = "hh")
    d$base[is.nan(d$base)] <- NA
    d$base_miss <- as.numeric(is.na(d$base))
    d$base[is.na(d$base)] <- 0
    d$y <- d[[v]]
    feols(y ~ treat + base + base_miss | season, data = d, cluster = ~vill)
  }
  for (spec in list(c("price_usd", "market_access_price_table6_panelA_col1"),
                    c("yield", "market_access_yield_table6_panelA_col4"),
                    c("hvalue", "market_access_harvest_value_table6_panelA_col5"),
                    c("profit_m", "market_access_profit_monetary_table6_panelA_col7"),
                    c("profit_h", "market_access_profit_incl_own_hours_table6_panelA_col8"))) {
    m <- tryCatch(ancova(spec[1]), error = function(e) { cat(spec[1], "error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m)) {
      print(summary(m))
      emit(spec[2], get_coef(m))
      if (spec[1] == "hvalue") emit("n_obs_table6_panelA_cols3_5", nobs(m))
    }
  }
}, error = function(e) cat("Table 6 error:", conditionMessage(e), "\n"))

allnames <- c("treatment_defects_visual_table2_col1", "treatment_defects_lab_table2_col2",
              "treatment_price_table2_col3", "treatment_deductions_table2_col4",
              "treatment_net_price_table2_col5", "n_obs_table2_col1_bags", "n_obs_table2_cols3_5_sales",
              "market_access_price_table6_panelA_col1", "market_access_yield_table6_panelA_col4",
              "market_access_harvest_value_table6_panelA_col5", "market_access_profit_monetary_table6_panelA_col7",
              "market_access_profit_incl_own_hours_table6_panelA_col8", "n_obs_table6_panelA_cols3_5")
for (n in allnames) {
  v <- if (!is.null(results[[n]])) results[[n]] else NA
  cat(sprintf("RESULT:%s=%s\n", n, ifelse(is.na(v), "NA", format(v, digits = 8))))
}
