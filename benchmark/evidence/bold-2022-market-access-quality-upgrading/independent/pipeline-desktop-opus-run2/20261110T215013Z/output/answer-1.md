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

# ------------------------------------------------------------------
# Returns-to-quality experiment (Table 2)
# ------------------------------------------------------------------
ret <- tryCatch(rd("data/raw/anonym_returns_data.dta"), error = function(e) NULL)

if (!is.null(ret)) {
  cat("Returns data columns (sample):\n")
  print(head(names(ret), 60))
  stems <- unique(sub("_[0-9]+$", "", grep("_[0-9]+$", names(ret), value = TRUE)))
  cat("Indexed stems:\n"); print(stems)

  ret$treat <- to_num(ret[[find_col(ret, c("treatment", "treat"), "treat")]])
  ret$hh_row <- seq_len(nrow(ret))
  hhcol <- find_col(ret, c("hhh_id", "hh_id", "hhid", "household_id"), "hh.*id")
  ret$hh <- if (!is.null(hhcol)) as.character(ret[[hhcol]]) else as.character(ret$hh_row)
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
    cat("Defect values:\n"); print(sort(vals))
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
    labcol <- find_col(ret, c("lab_defects", "defects_lab", "lab_defect", "labdefects", "lab_def",
                              "share_defects", "defect_share", "totaldefects", "total_defects"),
                       "(lab.*(defect|waste|bad))|((defect|waste).*lab)|totaldefect", exclude = "_[0-9]+$")
    if (is.null(labcol)) {
      # try to construct from grams variables
      gcols <- grep("(broken|pestdamaged|rotten|immature|foreign|inorganic|discolour).*totg", names(ret),
                    value = TRUE, ignore.case = TRUE)
      wcol <- find_col(ret, c("totalweightofmaizeg"), "totalweight")
      if (length(gcols) > 0) {
        tot <- if (!is.null(wcol)) to_num(ret[[wcol]]) else 200
        ret$labdef <- rowSums(sapply(gcols, function(g) to_num(ret[[g]]))) / tot
      } else stop("no lab defect column")
    } else {
      ret$labdef <- to_num(ret[[labcol]])
      if (median(ret$labdef, na.rm = TRUE) > 1) ret$labdef <- ret$labdef / 200
    }
    cat("Lab column:", ifelse(is.null(labcol), "constructed", labcol), "\n")
    m2 <- feols(labdef ~ treat | vill, data = ret[!is.na(ret$labdef), ], vcov = "hetero")
    print(summary(m2))
    emit("treatment_defects_lab_table2_col2", get_coef(m2))
  }, error = function(e) cat("Col2 error:", conditionMessage(e), "\n"))

  # ---- Cols 3-5: sales ----
  tryCatch({
    idx <- grep("_[0-9]+$", names(ret), value = TRUE)
    sale_idx <- idx[grepl("^add5", idx)]
    if (length(sale_idx) == 0) sale_idx <- idx
    sstems <- unique(sub("_[0-9]+$", "", sale_idx))
    cat("Sale stems:\n"); print(sstems)
    pick <- function(rx, ex = NULL) {
      c <- grep(rx, sstems, value = TRUE, ignore.case = TRUE)
      if (!is.null(ex)) c <- c[!grepl(ex, c, ignore.case = TRUE)]
      if (length(c)) c[1] else NULL
    }
    pstem <- pick("price", "total|value|net")
    ystem <- pick("(measur|enum|weigh|scale)", "agree|price")
    zstem <- pick("(agree|sold|quant|kg|volume)", "price|measur|weigh")
    wstem <- pick("(week|date)")
    cat("stems used: price=", pstem, " y=", ystem, " z=", zstem, " week=", wstem, "\n")
    ks <- sort(unique(as.integer(sub(".*_([0-9]+)$", "\\1", grep(paste0("^", pstem, "_[0-9]+$"), names(ret), value = TRUE)))))
    sales <- do.call(rbind, lapply(ks, function(k) {
      g <- function(s) { cn <- paste0(s, "_", k); if (!is.null(s) && cn %in% names(ret)) ret[[cn]] else rep(NA, nrow(ret)) }
      data.frame(hh = ret$hh, vill = ret$vill, treat = ret$treat, k = k,
                 price = to_num(g(pstem)), y = to_num(g(ystem)), z = to_num(g(zstem)),
                 week = g(wstem), stringsAsFactors = FALSE)
    }))
    sales <- sales[!is.na(sales$price) & sales$price > 0, ]
    if (inherits(sales$week, "Date") || inherits(sales$week, "POSIXt")) {
      sales$week <- format(as.Date(sales$week), "%Y-%U")
    } else if (is.numeric(sales$week) && median(sales$week, na.rm = TRUE) > 1000) {
      sales$week <- format(as.Date(sales$week, origin = "1960-01-01"), "%Y-%U")
    }
    sales$week <- as.character(sales$week)
    sales$week[is.na(sales$week)] <- "none"
    sales$deduct <- (sales$y - sales$z) / sales$y * 100
    sales$netprice <- sales$price * sales$z / sales$y
    m3 <- feols(price ~ treat | vill + week, data = sales, cluster = ~hh)
    print(summary(m3))
    emit("treatment_price_table2_col3", get_coef(m3))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(feols(deduct ~ treat | vill + week, data = sales, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m4)) emit("treatment_deductions_table2_col4", get_coef(m4))
    m5 <- tryCatch(feols(netprice ~ treat | vill + week, data = sales, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m5)) emit("treatment_net_price_table2_col5", get_coef(m5))
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

  # price (UGX/kg)
  prcol <- find_col(p, c("price", "avg_price", "price_avg", "price_kg", "mean_price"), "price", exclude = "_[0-9]+$")
  if (!is.null(prcol)) {
    p$price_ugx <- to_num(p[[prcol]])
  } else {
    pc <- grep("price.*_[0-9]+$", names(p), value = TRUE)
    kc <- sub("price", "sold_kg", pc)
    num <- 0; den <- 0
    for (i in seq_along(pc)) {
      pr <- to_num(p[[pc[i]]]); kg <- if (kc[i] %in% names(p)) to_num(p[[kc[i]]]) else rep(1, nrow(p))
      ok <- !is.na(pr) & !is.na(kg) & pr > 0
      num <- num + ifelse(ok, pr * kg, 0); den <- den + ifelse(ok, kg, 0)
    }
    p$price_ugx <- ifelse(den > 0, num / den, NA)
  }
  p$price_ugx[p$price_ugx <= 0] <- NA
  p$price_usd <- p$price_ugx / usd

  # community price for harvest value
  p <- p %>% group_by(vill, season) %>% mutate(comm_price = median(price_ugx, na.rm = TRUE)) %>% ungroup() %>%
    group_by(season) %>% mutate(comm_price = ifelse(is.na(comm_price), median(price_ugx, na.rm = TRUE), comm_price)) %>%
    ungroup() %>% as.data.frame()
  hvalcol <- find_col(p, c("harvest_value", "harvest_val", "value_harvest"), "harvest_val")
  p$hvalue <- if (!is.null(hvalcol)) to_num(p[[hvalcol]]) / usd else p$harvest * p$comm_price / usd
  p$yield <- p$harvest / p$area

  # monetary costs
  ccols <- grep("cost", names(p), value = TRUE)
  ccols <- ccols[!grepl("^(seeds_cost)$", ccols) | !any(grepl("^seeds_cost_[0-9]+$", names(p)))]
  ccols <- ccols[!grepl("own|family|fam", ccols)]
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

  ancova <- function(v) {
    bl <- p %>% filter(post == 0) %>% group_by(hh) %>% summarise(base = mean(.data[[v]], na.rm = TRUE), .groups = "drop")
    d <- p %>% filter(post == 1) %>% left_join(bl, by = "hh")
    d$base[is.nan(d$base)] <- NA
    d$y <- d[[v]]
    feols(y ~ treat + base | season, data = d, cluster = ~vill)
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
