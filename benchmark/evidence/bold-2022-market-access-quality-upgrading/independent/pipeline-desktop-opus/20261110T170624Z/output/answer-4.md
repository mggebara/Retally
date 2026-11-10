suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
rd <- function(f) {
  d <- haven::read_dta(file.path(base, "data/raw", f))
  d <- haven::zap_labels(d)
  as.data.frame(d, stringsAsFactors = FALSE)
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
tonum <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x))
  if (inherits(x, "POSIXt")) return(as.numeric(x) / 86400)
  if (is.character(x)) {
    v <- num(x)
    if (sum(!is.na(v)) >= sum(!is.na(x) & x != "") * 0.9) return(v)
    out <- rep(NA_real_, length(x))
    for (f in c("%Y-%m-%d", "%d/%m/%Y", "%m/%d/%Y", "%d-%m-%Y", "%d%b%Y", "%d %b %Y", "%Y/%m/%d")) {
      dd <- suppressWarnings(as.Date(x, format = f))
      fill <- is.na(out) & !is.na(dd)
      out[fill] <- as.numeric(dd[fill])
    }
    if (all(is.na(out))) {
      # unparseable text: use as categorical code
      xx <- ifelse(is.na(x) | x == "", NA, x)
      out <- as.numeric(factor(xx))
    }
    return(out)
  }
  num(x)
}
fc <- function(d, pats, exclude = NULL) {
  nm <- names(d)
  for (p in pats) {
    h <- grep(p, nm, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) h <- h[!grepl(exclude, h, ignore.case = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
res <- list()
emit <- function(n, v) {
  v <- suppressWarnings(as.numeric(v))
  if (length(v) == 1 && is.finite(v)) res[[n]] <<- v
}
safe <- function(expr, label) {
  tryCatch(expr, error = function(e) cat("ERROR in", label, ":", conditionMessage(e), "\n"))
}
yesno <- function(v) {
  v <- num(v)
  u <- unique(v[!is.na(v)])
  if (length(u) && all(u %in% c(1, 2))) as.numeric(v == 1) else as.numeric(v > 0)
}
rsum_na <- function(m) {
  m <- as.matrix(m)
  out <- rowSums(m, na.rm = TRUE)
  out[rowSums(!is.na(m)) == 0] <- NA
  out
}
# Exchange rate assumption (not given in the excerpt): ~3,450 UGX per USD over the study period
UGX_PER_USD <- 3450
cat("DEVIATION: Exchange rate set to 3,450 UGX/USD (rate not given in excerpt; previous 3,700 assumption)\n")

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
ret <- NULL
safe({
  ret <- rd("anonym_returns_data.dta")
  cat("returns data:", nrow(ret), "rows,", ncol(ret), "cols\n")
}, "load returns")

if (!is.null(ret)) {
  ret$hh_row <- seq_len(nrow(ret))
  ret$treat <- num(ret[[fc(ret, c("^treatment$", "treat"))]])
  vcol <- fc(ret, c("^village$", "village_id", "^village", "ea_code", "^ea$", "vill", "lc1", "parish"))
  cat("village column used:", vcol, "\n")
  ret$vil <- if (!is.na(vcol)) as.character(ret[[vcol]]) else "1"

  # ---- Col 1: visual defects per bag ----
  safe({
    types <- c("dirt", "cob", "stone", "dust", "insect", "broken", "immature", "damage", "rotten", "mo[u]?ld")
    rows <- list()
    for (t in types) {
      cols <- grep(paste0("^add4_[a-z_]*", t, "[a-z]*_([0-9]+)$"), names(ret), value = TRUE, ignore.case = TRUE)
      for (cc in cols) {
        k <- as.integer(sub(".*_([0-9]+)$", "\\1", cc))
        rows[[length(rows) + 1]] <- data.frame(hh_row = ret$hh_row, bag = k, type = t,
                                               raw = num(ret[[cc]]), stringsAsFactors = FALSE)
      }
    }
    L <- bind_rows(rows)
    L$val <- yesno(L$raw)
    bags <- L %>% group_by(hh_row, bag) %>%
      summarise(nn = sum(!is.na(val)), defects = sum(val, na.rm = TRUE), .groups = "drop") %>%
      filter(nn > 0) %>%
      left_join(ret[, c("hh_row", "treat", "vil")], by = "hh_row")
    cat("bags:", nrow(bags), "\n")
    m1 <- feols(defects ~ treat | vil, data = bags, cluster = ~hh_row)
    print(summary(m1))
    emit("treatment_defects_visual_table2_col1", coef(m1)["treat"])
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, "table2 col1")

  # ---- Col 2: lab defects (share of sample weight) ----
  safe({
    nn <- tolower(gsub("_", "", names(ret)))
    totc <- names(ret)[grepl("^totalweight", nn)][1]
    comp_pats <- c("^foreignmatter", "^inorganicmatter", "^brokengrain", "^pestdamaged",
                   "^rottenand", "^discoloured", "^immatureor")
    compc <- unique(unlist(lapply(comp_pats, function(p) names(ret)[grepl(p, nn)])))
    cat("lab total column:", totc, " components:", paste(compc, collapse = ","), "\n")
    tot <- num(ret[[totc]])
    s <- rsum_na(sapply(compc, function(g) num(ret[[g]])))
    lab <- s / tot
    lab[is.na(tot) | tot <= 0] <- NA
    d2 <- data.frame(lab = lab, treat = ret$treat, vil = ret$vil)
    d2 <- d2[!is.na(d2$lab), ]
    cat("lab obs:", nrow(d2), " mean share:", mean(d2$lab), "\n")
    m2 <- feols(lab ~ treat | vil, data = d2, vcov = "hetero")
    print(summary(m2))
    emit("treatment_defects_lab_table2_col2", coef(m2)["treat"])
  }, "table2 col2")

  # ---- Cols 3-5: price, deductions, net price per sale ----
  safe({
    a5 <- grep("^add5_.*_[0-9]+$", names(ret), value = TRUE)
    ks <- sort(unique(as.integer(sub("^add5_ppk_([0-9]+)$", "\\1", grep("^add5_ppk_[0-9]+$", a5, value = TRUE)))))
    stems <- unique(sub("_[0-9]+$", "", a5))
    other <- stems[!grepl("weight|ppk", stems, ignore.case = TRUE)]
    cat("other add5 stems:", paste(other, collapse = ","), "\n")
    wst <- NA_character_
    for (p in c("week", "date", "when", "day", "time")) {
      h <- grep(p, other, ignore.case = TRUE, value = TRUE)
      if (length(h)) { wst <- h[1]; break }
    }
    cat("sale date stem:", wst, "\n")
    S <- bind_rows(lapply(ks, function(k) {
      wc <- grep(paste0("^add5_ind_weight[0-9]+_", k, "$"), names(ret), value = TRUE)
      dc <- grep(paste0("^add5_ind_ded_weight[0-9]+_", k, "$"), names(ret), value = TRUE)
      y <- if (length(wc)) rsum_na(sapply(wc, function(x) num(ret[[x]]))) else rep(NA_real_, nrow(ret))
      dd <- if (length(dc)) rsum_na(sapply(dc, function(x) num(ret[[x]]))) else rep(NA_real_, nrow(ret))
      wcn <- paste0(wst, "_", k)
      w <- if (!is.na(wst) && wcn %in% names(ret)) tonum(ret[[wcn]]) else rep(NA_real_, nrow(ret))
      data.frame(hh_row = ret$hh_row, sale = k, p = num(ret[[paste0("add5_ppk_", k)]]),
                 y = y, dd = dd, w = w)
    }))
    S <- S %>% filter(!is.na(p), p > 0) %>% left_join(ret[, c("hh_row", "treat", "vil")], by = "hh_row")
    # ded_weight: either the deducted amount or the weight after deduction
    r <- sum(S$dd, na.rm = TRUE) / sum(S$y[!is.na(S$dd)], na.rm = TRUE)
    cat("ded/measured weight ratio:", r, "\n")
    S$dd[is.na(S$dd) & !is.na(S$y)] <- if (is.finite(r) && r > 0.5) S$y[is.na(S$dd) & !is.na(S$y)] else 0
    S$z <- if (is.finite(r) && r > 0.5) S$dd else S$y - S$dd
    cat("bag/transaction records:", nrow(S), "\n")
    cat("records with measured weight:", sum(!is.na(S$y) & S$y > 0),
        " hh:", length(unique(S$hh_row[!is.na(S$y) & S$y > 0])), "\n")
    cat("distinct hh x date:", nrow(unique(S[, c("hh_row", "w")])), "\n")
    cat("distinct hh x date (weighed only):",
        nrow(unique(S[!is.na(S$y) & S$y > 0, c("hh_row", "w")])), "\n")

    # Week of sale
    if (all(is.na(S$w))) {
      S$week <- NA_real_
    } else {
      wv <- S$w
      med <- median(wv, na.rm = TRUE)
      if (med > 1e9) wv <- wv / 86400000  # Stata %tc ms -> days
      if (median(wv, na.rm = TRUE) > 1000) {
        S$week <- floor(wv / 7)          # dates in days -> week
      } else {
        S$week <- wv                      # already a week / period code
      }
    }

    # Deductions and net price need the measured weight y and the paid weight z:
    # keep only sale records where the company/enumerator weighed the maize.
    S <- S %>% filter(!is.na(y), y > 0)
    cat("DEVIATION: Sales restricted to records with measured weights (needed for deductions and net price)\n")

    # A "sale" = one transaction: the records of a household sold on the same date
    S$wkey <- ifelse(is.na(S$w), paste0("na", S$sale), as.character(S$w))
    S <- S %>% group_by(hh_row, wkey) %>%
      summarise(treat = first(treat), vil = first(vil), week = first(week),
                p = sum(p * y) / sum(y),
                y = sum(y, na.rm = TRUE), z = sum(z, na.rm = TRUE),
                nrec = n(), .groups = "drop") %>% as.data.frame()
    cat("DEVIATION: Records of the same household on the same sale date collapsed into one sale (weight-weighted price; sale definition not given in excerpt)\n")
    S$ded <- 100 * (S$y - S$z) / S$y
    S$netp <- S$p * S$z / S$y
    if (all(is.na(S$week))) {
      S$week <- "1"
      cat("DEVIATION: No sale date found in returns data; week-of-sale FE omitted\n")
    } else {
      S$week <- ifelse(is.na(S$week), "missing", as.character(S$week))
    }
    cat("sales:", nrow(S), " households:", length(unique(S$hh_row)), " weeks:", length(unique(S$week)), "\n")
    m3 <- feols(p ~ treat | vil + week, data = S, cluster = ~hh_row)
    print(summary(m3))
    emit("treatment_price_table2_col3", coef(m3)["treat"])
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- feols(ded ~ treat | vil + week, data = S, cluster = ~hh_row)
    print(summary(m4))
    emit("treatment_deductions_table2_col4", coef(m4)["treat"])
    m5 <- feols(netp ~ treat | vil + week, data = S, cluster = ~hh_row)
    print(summary(m5))
    emit("treatment_net_price_table2_col5", coef(m5)["treat"])
  }, "table2 cols3-5")
}

# =====================================================================
# Market access experiment (Table 6, Panel A) -- panel_g1
# =====================================================================
safe({
  g1 <- rd("panel_g1.dta")
  cat("panel_g1:", nrow(g1), "rows\n")
  hcol <- fc(g1, c("^hhh_id$", "hhh_id", "^hh_id$", "hhid", "household"))
  vcol <- fc(g1, c("^ea_code$", "ea_code", "^village$", "village"))
  cat("hh:", hcol, " village:", vcol, "\n")
  g1$hh <- as.character(g1[[hcol]])
  g1$vil <- as.character(g1[[vcol]])
  g1$season <- num(g1$survey_season)

  tcol <- fc(g1, c("^buy_treatment$", "buy_treat", "^treatment$", "^treat$", "treat"))
  if (!is.na(tcol)) {
    g1$treat <- num(g1[[tcol]])
  } else {
    bd <- rd("buy_data.dta")
    bt <- bd %>% mutate(vil = as.character(ea_code)) %>% group_by(vil) %>%
      summarise(treat = max(num(buy_treatment), na.rm = TRUE), .groups = "drop")
    g1 <- left_join(g1, bt, by = "vil")
  }
  g1$post <- if ("season_post" %in% names(g1)) num(g1$season_post) else as.numeric(g1$season > 3)
  cat("treat table:\n"); print(table(g1$treat, g1$post, useNA = "ifany"))

  # --- price from seller data (sale-level), quantity weighted per hh-season ---
  sd <- rd("seller_data.dta")
  wq <- if ("sold_kg_p_" %in% names(sd)) num(sd$sold_kg_p_) else rep(1, nrow(sd))
  sd <- sd %>% mutate(hh = as.character(hhh_id), season = num(survey_season), vil = as.character(ea_code),
                      price = num(price), wq = ifelse(is.na(wq) | wq <= 0, 1, wq)) %>%
    filter(!is.na(price), price > 0)
  hp <- sd %>% group_by(hh, season) %>%
    summarise(price_ugx = sum(price * wq) / sum(wq), .groups = "drop")
  cp <- sd %>% group_by(vil, season) %>% summarise(cprice = median(price), .groups = "drop")
  sp <- sd %>% group_by(season) %>% summarise(sprice = median(price), .groups = "drop")
  g1 <- g1 %>% left_join(hp, by = c("hh", "season")) %>% left_join(cp, by = c("vil", "season")) %>%
    left_join(sp, by = "season")
  g1$cprice <- ifelse(is.na(g1$cprice), g1$sprice, g1$cprice)
  g1$price_usd <- g1$price_ugx / UGX_PER_USD

  # --- harvest, area, yield ---
  hvc <- fc(g1, c("^harvest_kg$", "^harvest_tot", "^harvest$", "harvest_kg", "maize_harvest", "harvest"),
            exclude = "cost|price|value|date|labou?r|hour|time|month|type")
  cat("harvest column:", hvc, "\n")
  cat("harvest-like columns:", paste(grep("harvest", names(g1), value = TRUE, ignore.case = TRUE), collapse = ","), "\n")
  g1$harvest <- num(g1[[hvc]])
  pcs <- grep("^plot_size_[0-9]+$", names(g1), value = TRUE)
  g1$area <- if (length(pcs)) rowSums(sapply(pcs, function(x) num(g1[[x]])), na.rm = TRUE) else NA
  g1$area[g1$area <= 0] <- NA
  g1$yield <- g1$harvest / g1$area
  # Harvest valued at the household's own realized sale price (so the price premium enters
  # harvest value), falling back to the village-season median price for non-sellers.
  g1$vprice <- ifelse(is.na(g1$price_ugx), g1$cprice, g1$price_ugx)
  g1$hvalue <- g1$harvest * g1$vprice / UGX_PER_USD
  cat("DEVIATION: Harvest value uses household's own sale price (village-season median if no sale); valuation price not given in excerpt\n")

  # --- monetary costs ---
  cc <- grep("cost", names(g1), value = TRUE, ignore.case = TRUE)
  stem <- sub("(_[0-9]+)+$", "", cc)
  numbered <- grepl("_[0-9]+$", cc)
  dbl <- grepl("_[0-9]+_[0-9]+$", cc)
  keep <- (numbered & !dbl) | (dbl & !(stem %in% stem[numbered & !dbl])) | (!numbered & !(stem %in% stem[numbered]))
  cc <- cc[keep]
  # Avoid double counting totals and their components
  if (any(grepl("^tot_lab_costs", cc))) cc <- cc[!grepl("^lc_", cc)]
  if (any(grepl("^tot_transport_cost", cc))) cc <- cc[!grepl("^sale_transport_cost|^cost_transport(pre|post)", cc)]
  cat("DEVIATION: Dropped component cost columns when a matching total column exists (avoid double counting)\n")
  cat("cost columns:", paste(cc, collapse = ","), "\n")
  g1$cost <- if (length(cc)) rowSums(sapply(cc, function(x) num(g1[[x]])), na.rm = TRUE) else 0
  g1$profit_m <- g1$hvalue - g1$cost / UGX_PER_USD

  # --- own (family) labour hours valued at the observed hired-labour wage ---
  hall <- grep("hour", names(g1), value = TRUE, ignore.case = TRUE)
  hc <- hall[!grepl("hire|paid", hall, ignore.case = TRUE)]
  hhc <- hall[grepl("hire|paid", hall, ignore.case = TRUE)]
  cat("own hour cols:", paste(hc, collapse = ","), "\n")
  cat("hired hour cols:", paste(hhc, collapse = ","), "\n")
  g1$own_hours <- if (length(hc)) rowSums(sapply(hc, function(x) num(g1[[x]])), na.rm = TRUE) else 0
  WAGE_UGX_HOUR <- NA_real_
  labc <- grep("^tot_lab_cost", names(g1), value = TRUE)
  if (length(labc) && length(hhc)) {
    lcost <- rowSums(sapply(labc, function(x) num(g1[[x]])), na.rm = TRUE)
    hhrs <- rowSums(sapply(hhc, function(x) num(g1[[x]])), na.rm = TRUE)
    ok <- is.finite(lcost) & is.finite(hhrs) & lcost > 0 & hhrs > 0
    if (sum(ok) > 10) WAGE_UGX_HOUR <- sum(lcost[ok]) / sum(hhrs[ok])
  }
  cat("data-derived hired wage (UGX/hour):", WAGE_UGX_HOUR, "\n")
  if (!is.finite(WAGE_UGX_HOUR) || WAGE_UGX_HOUR < 300 || WAGE_UGX_HOUR > 5000) {
    WAGE_UGX_HOUR <- 10000 / 7
    cat("DEVIATION: Own hours valued at assumed wage of 10,000 UGX per 7-hour day (hired wage not recoverable)\n")
  } else {
    cat("DEVIATION: Own hours valued at the average hired-labour wage observed in the data (wage not given in excerpt)\n")
  }
  g1$profit_h <- g1$profit_m - g1$own_hours * WAGE_UGX_HOUR / UGX_PER_USD

  ancova <- function(v) {
    bl <- g1 %>% filter(post == 0) %>% group_by(hh) %>%
      summarise(bl = mean(.data[[v]], na.rm = TRUE), .groups = "drop")
    d <- g1 %>% filter(post == 1, !is.na(.data[[v]]), !is.na(treat)) %>% left_join(bl, by = "hh")
    d$bl[!is.finite(d$bl)] <- NA
    d$bl_miss <- as.numeric(is.na(d$bl))
    d$bl[is.na(d$bl)] <- mean(d$bl, na.rm = TRUE)
    d$y <- d[[v]]
    m <- feols(y ~ treat + bl + bl_miss | season, data = d, cluster = ~vil)
    print(summary(m))
    m
  }
  mp <- ancova("price_usd"); emit("market_access_price_table6_panelA_col1", coef(mp)["treat"])
  my <- ancova("yield"); emit("market_access_yield_table6_panelA_col4", coef(my)["treat"])
  mh <- ancova("hvalue"); emit("market_access_harvest_value_table6_panelA_col5", coef(mh)["treat"])
  emit("n_obs_table6_panelA_cols3_5", nobs(mh))
  m7 <- ancova("profit_m"); emit("market_access_profit_monetary_table6_panelA_col7", coef(m7)["treat"])
  m8 <- ancova("profit_h"); emit("market_access_profit_incl_own_hours_table6_panelA_col8", coef(m8)["treat"])
}, "table6")

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
