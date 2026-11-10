suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
rd <- function(f) {
  d <- haven::read_dta(file.path(base_dir, "data/raw", f))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}
num <- function(x) suppressWarnings(as.numeric(as.character(x)))
findcol <- function(nm, pats, exclude = NULL) {
  for (p in pats) {
    h <- grep(p, nm, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) h <- h[!grepl(exclude, h, ignore.case = TRUE)]
    if (length(h)) return(h[1])
  }
  NA_character_
}
getcoef <- function(m, v = "treat") tryCatch(unname(coef(m)[v]), error = function(e) NA_real_)
getn <- function(m) tryCatch(nobs(m), error = function(e) NA_real_)

res <- list()
setres <- function(n, v) res[[n]] <<- v
EXCH <- 3700  # UGX per USD, used only if outcomes are stored in UGX

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
R <- rd("anonym_returns_data.dta")
nm <- names(R)
cat("Returns data columns:\n"); print(nm)

R$.treat <- num(R$treatment)
vcol <- findcol(nm, c("^ea_code$", "^village$", "^village_id$", "^vil$", "village", "^ea_", "ea_code"))
idcol <- findcol(nm, c("^hhh_id$", "^hh_id$", "^hhid$", "hhh_id", "hhid", "^id$"))
cat("Village column:", vcol, " HH column:", idcol, "\n")
R$.vil <- if (!is.na(vcol)) as.character(R[[vcol]]) else "1"
R$.hh <- if (!is.na(idcol)) paste(R$.vil, as.character(R[[idcol]])) else as.character(seq_len(nrow(R)))
if (any(duplicated(R$.hh))) R$.hh <- paste(R$.hh, seq_len(nrow(R)))

# ---------- Column (2): lab defects ----------
tryCatch({
  totw <- findcol(nm, c("^Total_weight_of_maize_g$", "total_weight_of_maize", "total_weight"), exclude = "^add")
  cats <- list(broken = "broken", pest = "pest", rotten = "rotten", immature = "immature|shrivel",
               discoloured = "discolou?r", foreign = "foreign")
  labcols <- c()
  for (cn in names(cats)) {
    cand <- grep(cats[[cn]], nm, ignore.case = TRUE, value = TRUE)
    cand <- cand[!grepl("^add|aflatox|total_weight|price|cost", cand, ignore.case = TRUE)]
    cand <- cand[sapply(cand, function(c) is.numeric(R[[c]]))]
    if (!length(cand)) next
    pick <- cand[grepl("tot", cand, ignore.case = TRUE)]
    if (!length(pick)) pick <- cand[grepl("_g$", cand, ignore.case = TRUE)]
    if (!length(pick)) pick <- cand
    labcols <- c(labcols, pick[1])
  }
  cat("Lab defect columns:", labcols, " total weight:", totw, "\n")
  dsum <- rowSums(sapply(labcols, function(c) num(R[[c]])), na.rm = FALSE)
  allna <- rowSums(!is.na(sapply(labcols, function(c) num(R[[c]])))) == 0
  dsum2 <- rowSums(sapply(labcols, function(c) num(R[[c]])), na.rm = TRUE)
  dsum2[allna] <- NA
  if (!is.na(totw)) {
    tw <- num(R[[totw]]); tw[tw <= 0] <- NA
    R$.lab <- 100 * dsum2 / tw
  } else {
    R$.lab <- dsum2 / 2  # grams per 200 g -> percent
  }
  print(summary(R$.lab))
  m2 <- feols(.lab ~ treat | .vil, data = transform(R, treat = .treat), vcov = "hetero")
  print(summary(m2))
  setres("treatment_defects_lab_table2_col2", getcoef(m2))
}, error = function(e) { cat("Lab defects error:", conditionMessage(e), "\n") })

# ---------- Column (1): visual defects, bag level ----------
tryCatch({
  kw <- c(dirty = "dirt", cobs = "cob", stones = "stone", dust = "dust", insects = "insect",
          broken = "broken", immature = "immature|shrivel", damaged = "damage",
          rotten = "rotten|_rot_|_rot$", moldy = "mou?ld")
  vc <- grep("^add[0-9]+_", nm, value = TRUE)
  vc <- vc[grepl(paste(kw, collapse = "|"), vc, ignore.case = TRUE)]
  vc <- vc[!grepl("cost|price|ppk|weight|_kg", vc, ignore.case = TRUE)]
  vc <- vc[grepl("\\d+$", vc)]
  cat("Visual defect candidate columns:\n"); print(vc)
  tobin <- function(v) {
    if (is.character(v)) {
      t <- tolower(trimws(v))
      out <- ifelse(is.na(t) | t == "" | t == ".", NA, ifelse(t %in% c("0", "no", "none", "false", "n"), 0, 1))
      return(as.numeric(out))
    }
    v <- num(v); v[v < 0] <- NA
    as.numeric(v > 0)
  }
  long <- NULL
  if (length(vc)) {
    info <- data.frame(col = vc, stringsAsFactors = FALSE)
    info$prefix <- sub("_.*$", "", info$col)
    info$key <- paste0(info$prefix, "_", sub("^.*?((\\d+_)*\\d+)$", "\\1", sub("^add[0-9]+_", "", info$col)))
    info$cat <- sapply(info$col, function(c) {
      s <- sub("^add[0-9]+_", "", c)
      w <- which(sapply(kw, function(p) grepl(p, s, ignore.case = TRUE)))
      if (length(w)) names(kw)[w[1]] else NA
    })
    print(head(info, 40))
    keys <- unique(info$key)
    rows <- list()
    for (k in keys) {
      sub_i <- info[info$key == k, ]
      mats <- sapply(sub_i$col, function(c) tobin(R[[c]]))
      if (is.null(dim(mats))) mats <- matrix(mats, nrow = nrow(R))
      exists <- rowSums(!is.na(mats)) > 0
      cnt <- sapply(seq_len(nrow(R)), function(i) {
        if (!exists[i]) return(NA)
        x <- mats[i, ]
        sum(tapply(x, sub_i$cat, function(z) as.numeric(any(z == 1, na.rm = TRUE))), na.rm = TRUE)
      })
      rows[[k]] <- data.frame(hh = R$.hh, vil = R$.vil, treat = R$.treat, key = k, vis = cnt)[exists, ]
    }
    long <- do.call(rbind, rows)
  }
  if (is.null(long) || !nrow(long)) {
    # fallback: multi-select string columns listing defect codes
    ms <- grep("^add[0-9]+_.*(defect|problem|qual).*\\d+$", nm, ignore.case = TRUE, value = TRUE)
    ms <- ms[sapply(ms, function(c) is.character(R[[c]]))]
    cat("Fallback multi-select columns:", ms, "\n")
    rows <- list()
    for (c in ms) {
      v <- R[[c]]
      ex <- !is.na(v) & trimws(v) != ""
      cnt <- sapply(strsplit(ifelse(ex, v, ""), "[ ,;]+"), function(t) {
        t <- num(t); length(unique(t[!is.na(t) & t >= 1 & t <= 10]))
      })
      rows[[c]] <- data.frame(hh = R$.hh, vil = R$.vil, treat = R$.treat, key = c, vis = cnt)[ex, ]
    }
    long <- do.call(rbind, rows)
  }
  cat("Bags constructed:", nrow(long), "\n"); print(summary(long$vis))
  m1 <- feols(vis ~ treat | vil, data = long, cluster = ~hh)
  print(summary(m1))
  setres("treatment_defects_visual_table2_col1", getcoef(m1))
  setres("n_obs_table2_col1_bags", getn(m1))
}, error = function(e) { cat("Visual defects error:", conditionMessage(e), "\n") })

# ---------- Columns (3)-(5): sales ----------
tryCatch({
  ppk <- grep("^add5_ppk_\\d+$", nm, value = TRUE)
  idx <- sub("^add5_ppk_", "", ppk)
  a5 <- grep("^add5_.*_\\d+$", nm, value = TRUE)
  stems <- unique(sub("_\\d+$", "", a5))
  cat("add5 stems:\n"); print(stems)
  stems_np <- setdiff(stems, "add5_ppk")
  ystem <- findcol(stems_np, c("measur", "enum", "weigh", "scale", "actual"), exclude = "date|price|ppk|cost")
  zstem <- findcol(setdiff(stems_np, ystem), c("agree", "kg_sold", "sold_kg", "paid_kg", "kg_paid", "quant", "qty", "_kg$", "kg"),
                   exclude = "date|price|ppk|cost")
  dstem <- findcol(stems_np, c("week", "date", "when", "day"))
  cat("Measured weight stem:", ystem, " agreed weight stem:", zstem, " date stem:", dstem, "\n")
  getv <- function(stem, k) { c <- paste0(stem, "_", k); if (!is.na(stem) && c %in% nm) R[[c]] else rep(NA, nrow(R)) }
  rows <- list()
  for (k in idx) {
    p <- num(R[[paste0("add5_ppk_", k)]])
    y <- num(getv(ystem, k)); z <- num(getv(zstem, k))
    dv <- getv(dstem, k)
    if (inherits(dv, "Date")) {
      wk <- ifelse(is.na(dv), NA, format(dv, "%Y-%U"))
    } else if (inherits(dv, "POSIXt")) {
      wk <- ifelse(is.na(dv), NA, format(as.Date(dv), "%Y-%U"))
    } else if (is.numeric(dv) && isTRUE(median(dv, na.rm = TRUE) > 1000)) {
      d2 <- as.Date(dv, origin = "1960-01-01"); wk <- ifelse(is.na(d2), NA, format(d2, "%Y-%U"))
    } else if (is.character(dv)) {
      d2 <- suppressWarnings(as.Date(dv, tryFormats = c("%Y-%m-%d", "%d/%m/%Y", "%d%b%Y", "%m/%d/%Y"), optional = TRUE))
      wk <- ifelse(is.na(d2), ifelse(is.na(dv) | dv == "", NA, dv), format(d2, "%Y-%U"))
    } else {
      wk <- as.character(dv)
    }
    rows[[k]] <- data.frame(hh = R$.hh, vil = R$.vil, treat = R$.treat, sale = k,
                            price = p, y = y, z = z, week = as.character(wk), stringsAsFactors = FALSE)
  }
  S <- do.call(rbind, rows)
  S <- S[!is.na(S$price) & S$price > 0, ]
  S$y[!is.na(S$y) & S$y <= 0] <- NA
  S$ded <- 100 * (S$y - S$z) / S$y
  S$netp <- S$price * S$z / S$y
  cat("Sales constructed:", nrow(S), "\n"); print(summary(S[, c("price", "y", "z", "ded", "netp")]))
  hasweek <- sum(!is.na(S$week)) > 0
  if (hasweek && sum(is.na(S$week)) > 0) S$week[is.na(S$week)] <- "missing"
  fml <- function(v) as.formula(paste(v, "~ treat |", if (hasweek) "vil + week" else "vil"))
  m3 <- feols(fml("price"), data = S, cluster = ~hh); print(summary(m3))
  setres("treatment_price_table2_col3", getcoef(m3))
  setres("n_obs_table2_cols3_5_sales", getn(m3))
  if (sum(!is.na(S$ded)) > 5) {
    m4 <- feols(fml("ded"), data = S, cluster = ~hh); print(summary(m4))
    setres("treatment_deductions_table2_col4", getcoef(m4))
    m5 <- feols(fml("netp"), data = S, cluster = ~hh); print(summary(m5))
    setres("treatment_net_price_table2_col5", getcoef(m5))
  }
}, error = function(e) { cat("Sales error:", conditionMessage(e), "\n") })

# =====================================================================
# Market access experiment (Table 6 Panel A)
# =====================================================================
tryCatch({
  P <- rd("panel_g1.dta")
  pn <- names(P)
  cat("panel_g1 columns:\n"); print(pn)
  pvil <- findcol(pn, c("^ea_code$", "^village$", "ea_code", "village"))
  phh <- findcol(pn, c("^hhh_id$", "^hh_id$", "^hhid$", "hhh_id", "hhid"))
  P$.vil <- as.character(P[[pvil]])
  P$.hh <- paste(P$.vil, as.character(P[[phh]]))
  P$.season <- as.character(P$survey_season)
  if ("season_post" %in% pn) {
    P$.post <- num(P$season_post)
  } else {
    ss <- sort(unique(P$survey_season)); P$.post <- as.numeric(match(P$survey_season, ss) > 3)
  }
  tcol <- findcol(pn, c("^treatment$", "^buy_treatment$", "^treat$", "^treated$", "^buy$", "^treatment_"))
  if (!is.na(tcol)) {
    P$.treat <- num(P[[tcol]])
  } else {
    B <- rd("buy_data.dta")
    bt <- B %>% group_by(ea_code) %>% summarise(bt = max(num(buy_treatment), na.rm = TRUE))
    P$.treat <- bt$bt[match(P[[pvil]], bt$ea_code)]
  }
  cat("Treatment column:", tcol, "; table:\n"); print(table(P$.treat, P$.post, useNA = "ifany"))
  print(table(P$.season, P$.post))

  cand <- grep("price|yield|harv|value|profit|usd|income|revenue|acre|area|plot", pn, ignore.case = TRUE, value = TRUE)
  cat("Outcome candidates:\n"); print(cand)

  usdify <- function(col, x, thresh) {
    if (grepl("usd|dollar", col, ignore.case = TRUE)) return(x)
    if (isTRUE(median(abs(x), na.rm = TRUE) > thresh)) return(x / EXCH)
    x
  }

  # Price
  pcol <- findcol(pn, c("price.*usd", "usd.*price", "^price$", "avg_price", "price_avg", "mean_price", "price_kg", "^price"),
                  exclude = "cost|premium|expect|tc_|trading")
  if (!is.na(pcol)) {
    P$.price <- usdify(pcol, num(P[[pcol]]), 5)
  } else {
    SD <- rd("seller_data.dta")
    SD$w <- num(SD$sold_kg_p_); SD$pr <- num(SD$price)
    agg <- SD %>% filter(!is.na(pr), pr > 0) %>%
      mutate(w = ifelse(is.na(w) | w <= 0, 1, w)) %>%
      group_by(ea_code, hhh_id, survey_season) %>% summarise(pr = sum(pr * w) / sum(w), .groups = "drop")
    key <- paste(agg$ea_code, agg$hhh_id, agg$survey_season)
    P$.price <- agg$pr[match(paste(P[[pvil]], P[[phh]], P$survey_season), key)]
    P$.price <- usdify("ugx", P$.price, 5)
    pcol <- "seller_data"
  }
  cat("Price column:", pcol, "\n"); print(summary(P$.price))

  # Harvest (kg) and yield
  hcol <- findcol(pn, c("^harvest_kg_tot$", "harvest_kg", "^harvest$"), exclude = "value|usd|cost")
  ycol <- findcol(pn, c("^yield$", "yield_acre", "yield"), exclude = "usd|value")
  if (!is.na(ycol)) {
    P$.yield <- num(P[[ycol]])
  } else {
    acol <- findcol(pn, c("^acres?$", "acres_tot", "area_tot", "plot_size_tot", "^area", "acre"), exclude = "cost")
    if (!is.na(acol)) area <- num(P[[acol]]) else {
      pcs <- grep("^plot_size_\\d+$", pn, value = TRUE)
      area <- rowSums(sapply(pcs, function(c) num(P[[c]])), na.rm = TRUE); area[area == 0] <- NA
    }
    P$.yield <- num(P[[hcol]]) / area
    ycol <- paste0("constructed from ", hcol)
  }
  cat("Yield:", ycol, "\n"); print(summary(P$.yield))

  # Harvest value
  hvcol <- findcol(pn, c("harvest_val.*usd", "harv_val.*usd", "harvest_value", "harv_value", "harv_val", "value_harv"))
  if (!is.na(hvcol)) {
    P$.hv <- usdify(hvcol, num(P[[hvcol]]), 1000)
  } else {
    mp <- P %>% group_by(.vil, .season) %>% summarise(mp = median(.price, na.rm = TRUE), .groups = "drop")
    P$.hv <- num(P[[hcol]]) * mp$mp[match(paste(P$.vil, P$.season), paste(mp$.vil, mp$.season))]
    hvcol <- "constructed"
  }
  cat("Harvest value:", hvcol, "\n"); print(summary(P$.hv))

  # Profits
  prcol <- findcol(pn, c("profit.*usd", "^profit$", "profit_mon", "profit"), exclude = "hour|own|fam|lab|incl|tot_lab")
  pocol <- findcol(pn, c("profit.*(own|hour|fam|incl|lab)"))
  cat("Profit (monetary):", prcol, " Profit incl own hours:", pocol, "\n")
  P$.prof <- if (!is.na(prcol)) usdify(prcol, num(P[[prcol]]), 1000) else NA
  P$.profo <- if (!is.na(pocol)) usdify(pocol, num(P[[pocol]]), 1000) else NA

  ancova <- function(var) {
    d <- data.frame(y = P[[var]], hh = P$.hh, vil = P$.vil, s = P$.season, post = P$.post, t = P$.treat)
    b <- d %>% filter(post == 0) %>% group_by(hh) %>% summarise(base = mean(y, na.rm = TRUE), .groups = "drop")
    b$base[is.nan(b$base)] <- NA
    d <- d %>% filter(post == 1) %>% left_join(b, by = "hh") %>%
      mutate(bm = as.integer(is.na(base)), base = ifelse(is.na(base), 0, base), treat = t)
    if (sum(d$bm) > 0) feols(y ~ treat + base + bm | s, data = d, cluster = ~vil)
    else feols(y ~ treat + base | s, data = d, cluster = ~vil)
  }
  run <- function(var, name) {
    if (all(is.na(P[[var]]))) return(NULL)
    m <- tryCatch(ancova(var), error = function(e) { cat(name, "error:", conditionMessage(e), "\n"); NULL })
    if (!is.null(m)) { cat("==", name, "==\n"); print(summary(m)); setres(name, getcoef(m)) }
    m
  }
  run(".price", "market_access_price_table6_panelA_col1")
  my <- run(".yield", "market_access_yield_table6_panelA_col4")
  mhv <- run(".hv", "market_access_harvest_value_table6_panelA_col5")
  run(".prof", "market_access_profit_monetary_table6_panelA_col7")
  run(".profo", "market_access_profit_incl_own_hours_table6_panelA_col8")
  if (!is.na(hcol)) {
    P$.harv <- num(P[[hcol]])
    mh <- tryCatch(ancova(".harv"), error = function(e) NULL)
    if (!is.null(mh)) { cat("== harvest kg ==\n"); print(summary(mh)); setres("n_obs_table6_panelA_cols3_5", getn(mh)) }
  }
  if (is.null(res[["n_obs_table6_panelA_cols3_5"]]) && !is.null(my)) setres("n_obs_table6_panelA_cols3_5", getn(my))
}, error = function(e) { cat("Market access error:", conditionMessage(e), "\n") })

# =====================================================================
names_out <- c("treatment_defects_visual_table2_col1", "treatment_defects_lab_table2_col2",
               "treatment_price_table2_col3", "treatment_deductions_table2_col4",
               "treatment_net_price_table2_col5", "n_obs_table2_col1_bags", "n_obs_table2_cols3_5_sales",
               "market_access_price_table6_panelA_col1", "market_access_yield_table6_panelA_col4",
               "market_access_harvest_value_table6_panelA_col5", "market_access_profit_monetary_table6_panelA_col7",
               "market_access_profit_incl_own_hours_table6_panelA_col8", "n_obs_table6_panelA_cols3_5")
for (n in names_out) {
  v <- res[[n]]
  if (is.null(v) || length(v) == 0) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}