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
# Exchange rate assumption (not given in the excerpt): ~3,700 UGX per USD over the study period
UGX_PER_USD <- 3700

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
ret <- NULL
safe({
  ret <- rd("anonym_returns_data.dta")
  cat("returns data:", nrow(ret), "rows,", ncol(ret), "cols\n")
  cat("returns columns:", paste(names(ret), collapse = ","), "\n")
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
      cat("defect type", t, ":", length(cols), "bag columns\n")
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

  # ---- Col 2: lab defects (share) ----
  safe({
    grain <- c("brokengrainstotg", "pestdamagedgrainstotg", "rottenanddiseasedgrainstotg",
               "immatureorshrivelledgrainstotg", "discolouredgrainstotg", "foreignmattertotg",
               "inorganicmattertotg")
    lab <- NULL
    gpres <- intersect(grain, names(ret))
    if (length(gpres) > 0 && "totalweightofmaizeg" %in% names(ret)) {
      tot <- num(ret$totalweightofmaizeg)
      s <- rowSums(sapply(gpres, function(g) num(ret[[g]])), na.rm = TRUE)
      lab <- s / tot
      lab[is.na(tot) | tot <= 0] <- NA
    } else {
      lc <- fc(ret, c("lab_def", "defects_lab", "lab_share", "share_def", "def.*lab", "lab"))
      cat("lab column used:", lc, "\n")
      if (!is.na(lc)) {
        lab <- num(ret[[lc]])
        if (median(lab, na.rm = TRUE) > 1) lab <- lab / ifelse(max(lab, na.rm = TRUE) > 100, 200, 100)
      }
    }
    if (!is.null(lab)) {
      d2 <- data.frame(lab = lab, treat = ret$treat, vil = ret$vil)
      d2 <- d2[!is.na(d2$lab), ]
      m2 <- feols(lab ~ treat | vil, data = d2, vcov = "hetero")
      print(summary(m2))
      emit("treatment_defects_lab_table2_col2", coef(m2)["treat"])
    }
  }, "table2 col2")

  # ---- Cols 3-5: price, deductions, net price per sale ----
  safe({
    a5 <- grep("^add5_.*_[0-9]+$", names(ret), value = TRUE)
    stems <- unique(sub("_[0-9]+$", "", a5))
    cat("add5 stems:", paste(stems, collapse = ","), "\n")
    pick <- function(pats, excl = NULL) {
      for (p in pats) {
        h <- grep(p, stems, ignore.case = TRUE, value = TRUE)
        if (!is.null(excl)) h <- h[!grepl(excl, h, ignore.case = TRUE)]
        if (length(h)) return(h[1])
      }
      NA_character_
    }
    pst <- pick(c("price_kg", "price_per", "unit_price", "price"), "net|total|tot|bag")
    yst <- pick(c("measur", "enum.*w", "weigh", "scale"), "price|date")
    zst <- pick(c("agree", "sold_kg", "volume", "quantity", "kg"), "price|date|measur|weigh")
    wst <- pick(c("week", "date", "day"))
    cat("price stem:", pst, " measured weight:", yst, " agreed:", zst, " date:", wst, "\n")
    getk <- function(st, k) {
      cn <- paste0(st, "_", k)
      if (!is.na(st) && cn %in% names(ret)) num(ret[[cn]]) else rep(NA_real_, nrow(ret))
    }
    ks <- sort(unique(as.integer(sub(".*_([0-9]+)$", "\\1", grep(paste0("^", pst, "_[0-9]+$"), a5, value = TRUE)))))
    S <- bind_rows(lapply(ks, function(k) data.frame(hh_row = ret$hh_row, sale = k,
      p = getk(pst, k), y = getk(yst, k), z = getk(zst, k), w = getk(wst, k))))
    S <- S %>% filter(!is.na(p), p > 0) %>% left_join(ret[, c("hh_row", "treat", "vil")], by = "hh_row")
    # if price recorded as a total value, convert to per-kg
    if (median(S$p, na.rm = TRUE) > 5000 && any(!is.na(S$z))) S$p <- S$p / S$z
    if (all(is.na(S$z))) S$z <- S$y
    if (all(is.na(S$y))) S$y <- S$z
    S$ded <- 100 * (S$y - S$z) / S$y
    S$netp <- S$p * S$z / S$y
    if (all(is.na(S$w))) {
      S$week <- 1
    } else if (grepl("week", wst, ignore.case = TRUE)) {
      S$week <- S$w
    } else {
      wv <- S$w
      if (median(wv, na.rm = TRUE) > 1e9) wv <- wv / 86400000  # Stata %tc ms -> days
      S$week <- floor(wv / 7)
    }
    S$week <- as.character(S$week)
    cat("sales:", nrow(S), " households:", length(unique(S$hh_row)), "\n")
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
  cat("panel_g1 columns:", paste(names(g1), collapse = ","), "\n")
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
  g1$harvest <- num(g1[[hvc]])
  pcs <- grep("^plot_size_[0-9]+$", names(g1), value = TRUE)
  g1$area <- if (length(pcs)) rowSums(sapply(pcs, function(x) num(g1[[x]])), na.rm = TRUE) else NA
  g1$area[g1$area <= 0] <- NA
  g1$yield <- g1$harvest / g1$area
  g1$hvalue <- g1$harvest * g1$cprice / UGX_PER_USD

  # --- monetary costs ---
  cc <- grep("cost", names(g1), value = TRUE, ignore.case = TRUE)
  stem <- sub("(_[0-9]+)+$", "", cc)
  numbered <- grepl("_[0-9]+$", cc)
  dbl <- grepl("_[0-9]+_[0-9]+$", cc)
  keep <- (numbered & !dbl) | (dbl & !(stem %in% stem[numbered & !dbl])) | (!numbered & !(stem %in% stem[numbered]))
  cc <- cc[keep]
  cat("cost columns:", paste(cc, collapse = ","), "\n")
  g1$cost <- if (length(cc)) rowSums(sapply(cc, function(x) num(g1[[x]])), na.rm = TRUE) else 0
  g1$profit_m <- g1$hvalue - g1$cost / UGX_PER_USD

  # --- own (family) labour hours valued at a wage ---
  hc <- grep("hour", names(g1), value = TRUE, ignore.case = TRUE)
  hc <- hc[!grepl("hire|paid", hc, ignore.case = TRUE)]
  cat("own-hours columns:", paste(hc, collapse = ","), "\n")
  g1$own_hours <- if (length(hc)) rowSums(sapply(hc, function(x) num(g1[[x]])), na.rm = TRUE) else 0
  WAGE_UGX_HOUR <- 5000 / 8  # assumed market daily wage of 5,000 UGX for 8 hours
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