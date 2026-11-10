suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
UGX_PER_USD <- 3700

results <- list()
emit <- function(name, val) {
  if (length(val) == 1 && is.finite(val)) results[[name]] <<- as.numeric(val)
}

load_dta <- function(rel) {
  d <- haven::read_dta(file.path(base, rel))
  d <- haven::zap_labels(d)
  as.data.frame(d)
}

find_col <- function(df, patterns, exclude = NULL) {
  nm <- names(df)
  for (p in patterns) {
    hits <- grep(p, nm, ignore.case = TRUE, value = TRUE)
    if (!is.null(exclude)) hits <- hits[!grepl(exclude, hits, ignore.case = TRUE)]
    if (length(hits) > 0) return(hits[1])
  }
  NA_character_
}

show_names <- function(label, df) {
  cat("\n==== Columns of", label, "(", nrow(df), "rows ) ====\n")
  print(names(df))
}

to_num <- function(x) {
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(as.numeric(as.Date(x)))
  suppressWarnings(as.numeric(x))
}

diag_lines <- character(0)
add_diag <- function(...) diag_lines <<- c(diag_lines, paste0(...))

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
rd <- tryCatch(load_dta("data/raw/anonym_returns_data.dta"), error = function(e) NULL)
if (!is.null(rd)) {
  nm <- names(rd)
  cat("\n==== Returns data: stems of wide variables ====\n")
  stems <- unique(sub("_[0-9]+$", "", nm))
  print(stems)

  treat_col <- find_col(rd, c("^treatment$", "^treat$", "treat"))
  hh_col <- find_col(rd, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$", "household"))
  vil_col <- find_col(rd, c("^ea_code$", "^village$", "village", "^ea$", "^vil", "lc1"))
  cat("treat:", treat_col, " hh:", hh_col, " village:", vil_col, "\n")
  rd$.hh <- if (!is.na(hh_col)) rd[[hh_col]] else seq_len(nrow(rd))
  rd$.vil <- if (!is.na(vil_col)) rd[[vil_col]] else 1
  rd$.treat <- to_num(rd[[treat_col]])

  # ---- Col 1: visual defects per bag ----
  tryCatch({
    defects <- c("dirt", "cobs?", "stones?", "dust", "insects?", "broken",
                 "immature", "damaged", "rotten", "mou?ldy?")
    pat <- paste0("^add4_(", paste(defects, collapse = "|"), ")_([0-9]+)$")
    vcols <- grep(pat, nm, ignore.case = TRUE, value = TRUE)
    cat("Visual defect columns found:", length(vcols), "\n")
    long <- rd[, c(".hh", ".vil", ".treat", vcols)] %>%
      mutate(across(all_of(vcols), to_num)) %>%
      pivot_longer(all_of(vcols), names_to = "var", values_to = "val") %>%
      mutate(defect = sub(pat, "\\1", var, ignore.case = TRUE),
             bag = as.integer(sub(pat, "\\2", var, ignore.case = TRUE)))
    vals <- unique(long$val[!is.na(long$val)])
    if (all(vals %in% c(1, 2)) && !any(vals == 0)) {
      long$yes <- as.numeric(long$val == 1)
    } else {
      long$yes <- as.numeric(long$val > 0 & long$val < 90)
    }
    long$yes[is.na(long$val)] <- NA
    bags <- long %>% group_by(.hh, .vil, .treat, bag) %>%
      summarise(n_obs = sum(!is.na(yes)),
                defects = sum(yes, na.rm = TRUE), .groups = "drop") %>%
      filter(n_obs > 0)
    m1 <- feols(defects ~ .treat | .vil, data = bags, cluster = ~.hh)
    print(summary(m1))
    emit("treatment_defects_visual_table2_col1", coef(m1)[".treat"])
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) cat("Col1 error:", conditionMessage(e), "\n"))

  # ---- Col 2: lab defects (share of sample weight) ----
  tryCatch({
    tot <- grep("^Total_weight", nm, ignore.case = TRUE, value = TRUE)
    tot <- tot[!grepl("aflatox", tot, ignore.case = TRUE)][1]
    comp_prefixes <- c("^Foreign_matter", "^Inorganic_matter", "^Broken_grain",
                       "^Pest_damaged", "^Rotten_and_diseased", "^Discoloured",
                       "^Immature_or_shriv")
    comps <- unlist(lapply(comp_prefixes, function(p) {
      h <- grep(p, nm, ignore.case = TRUE, value = TRUE)
      if (length(h)) h[1] else NULL
    }))
    cat("Lab components:", comps, " total:", tot, "\n")
    add_diag("lab comps: ", paste(comps, collapse = ","), " total: ", tot)
    if (length(comps) > 0 && !is.na(tot)) {
      cm <- sapply(comps, function(cc) to_num(rd[[cc]]))
      if (is.null(dim(cm))) cm <- matrix(cm, ncol = length(comps))
      allna <- rowSums(!is.na(cm)) == 0
      s <- rowSums(cm, na.rm = TRUE)
      s[allna] <- NA
      denom <- to_num(rd[[tot]])
      rd$.lab <- ifelse(is.finite(denom) & denom > 0, s / denom, NA)
    } else rd$.lab <- NA_real_
    labd <- rd[is.finite(rd$.lab), ]
    if (nrow(labd) > 0) {
      cat("Lab defect share summary:\n"); print(summary(labd$.lab))
      m2 <- feols(.lab ~ .treat | .vil, data = labd, vcov = "hetero")
      print(summary(m2))
      add_diag("lab N=", nobs(m2), " mean=", round(mean(labd$.lab), 4))
      emit("treatment_defects_lab_table2_col2", coef(m2)[".treat"])
    }
  }, error = function(e) cat("Col2 error:", conditionMessage(e), "\n"))

  # ---- Cols 3-5: sales ----
  tryCatch({
    ppk_cols <- grep("^add5_ppk_[0-9]+$", nm, value = TRUE)
    S <- as.integer(sub(".*_([0-9]+)$", "\\1", ppk_cols))
    sales <- rd[, c(".hh", ".vil", ".treat", ppk_cols), drop = FALSE]
    sales[ppk_cols] <- lapply(sales[ppk_cols], to_num)
    sales <- pivot_longer(sales, all_of(ppk_cols), names_to = "var", values_to = "price") %>%
      mutate(sale = as.integer(sub(".*_([0-9]+)$", "\\1", var))) %>% select(-var)

    date_cols <- grep("^add5_sold_when_e_[0-9]+$", nm, value = TRUE)
    if (length(date_cols)) {
      dd <- rd[, c(".hh", date_cols), drop = FALSE]
      dd[date_cols] <- lapply(dd[date_cols], to_num)
      dd <- pivot_longer(dd, all_of(date_cols), names_to = "var", values_to = "date") %>%
        mutate(sale = as.integer(sub(".*_([0-9]+)$", "\\1", var))) %>% select(-var)
      sales <- left_join(sales, dd, by = c(".hh", "sale"))
    } else sales$date <- NA_real_

    bag_long <- function(prefix) {
      re <- paste0("^add5_", prefix, "([0-9]+)_([0-9]+)$")
      cc <- grep(re, nm, value = TRUE)
      if (!length(cc)) return(NULL)
      x <- rd[, c(".hh", cc), drop = FALSE]
      x[cc] <- lapply(x[cc], to_num)
      x <- pivot_longer(x, all_of(cc), names_to = "var", values_to = "w")
      a <- as.integer(sub(re, "\\1", x$var)); b <- as.integer(sub(re, "\\2", x$var))
      x$sale <- if (max(b) <= max(S)) b else a
      x %>% group_by(.hh, sale) %>%
        summarise(w = if (all(is.na(w))) NA_real_ else sum(w, na.rm = TRUE), .groups = "drop")
    }
    yw <- bag_long("ind_weight")
    dw <- bag_long("ind_ded_weight")
    if (!is.null(yw)) sales <- left_join(sales, rename(yw, y = w), by = c(".hh", "sale")) else sales$y <- NA_real_
    if (!is.null(dw)) sales <- left_join(sales, rename(dw, dsum = w), by = c(".hh", "sale")) else sales$dsum <- NA_real_

    sales <- sales[!is.na(sales$price) & sales$price > 0, ]
    sales$week <- if (all(is.na(sales$date))) 1 else floor(sales$date / 7)

    ratio <- sales$dsum / sales$y
    ded_is_amount <- median(ratio[is.finite(ratio)], na.rm = TRUE) < 0.5
    cat("Deducted-weight variable interpreted as",
        if (isTRUE(ded_is_amount)) "kg deducted" else "net (paid) weight", "\n")
    if (isTRUE(ded_is_amount)) {
      d0 <- ifelse(is.na(sales$dsum), 0, sales$dsum)
      sales$z <- sales$y - d0
    } else {
      sales$z <- ifelse(is.na(sales$dsum), sales$y, sales$dsum)
    }
    ok <- is.finite(sales$y) & sales$y > 0
    sales$deduct <- ifelse(ok, 100 * (sales$y - sales$z) / sales$y, NA)
    sales$netprice <- ifelse(ok, sales$price * sales$z / sales$y, NA)
    cat("Sales N:", nrow(sales), " households:", length(unique(sales$.hh)), "\n")
    add_diag("sales N=", nrow(sales), " hh=", length(unique(sales$.hh)),
             " ded_is_amount=", ded_is_amount,
             " mean deduct=", round(mean(sales$deduct, na.rm = TRUE), 3))

    m3 <- feols(price ~ .treat | .vil + week, data = sales, cluster = ~.hh)
    print(summary(m3))
    emit("treatment_price_table2_col3", coef(m3)[".treat"])
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    if (any(is.finite(sales$deduct))) {
      m4 <- feols(deduct ~ .treat | .vil + week, data = sales, cluster = ~.hh)
      emit("treatment_deductions_table2_col4", coef(m4)[".treat"])
      m5 <- feols(netprice ~ .treat | .vil + week, data = sales, cluster = ~.hh)
      emit("treatment_net_price_table2_col5", coef(m5)[".treat"])
    }
  }, error = function(e) cat("Cols3-5 error:", conditionMessage(e), "\n"))
}

# =====================================================================
# Market access experiment (Table 6, Panel A) -- panel_g1
# =====================================================================
tryCatch({
  pg <- load_dta("data/raw/panel_g1.dta")
  show_names("panel_g1", pg)
  pn <- names(pg)
  treat_col <- find_col(pg, c("^buy_treatment$", "^treatment$", "^treat$", "treat"))
  hh_col <- find_col(pg, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$"))
  vil_col <- find_col(pg, c("^ea_code$", "^village$", "village", "^ea$"))
  post_col <- find_col(pg, c("^season_post$", "^post$"))
  pg$.treat <- to_num(pg[[treat_col]])
  pg$.hh <- pg[[hh_col]]; pg$.vil <- pg[[vil_col]]
  pg$.post <- to_num(pg[[post_col]])
  pg$.season <- pg$survey_season

  kw <- "price|rev|val|profit|yield|sold|sale|acre|area|labo|hour|wage|tot_|total"
  nonwide <- pn[!grepl("_[0-9]+$", pn)]
  wst <- unique(sub("_[0-9]+$", "", pn[grepl("_[0-9]+$", pn)]))
  add_diag("pg nonwide kw: ", paste(grep(kw, nonwide, ignore.case = TRUE, value = TRUE), collapse = " "))
  add_diag("pg wide stems kw: ", paste(grep(kw, wst, ignore.case = TRUE, value = TRUE), collapse = " "))

  ancova <- function(y) {
    d <- pg
    d$.y <- y
    bl <- d %>% filter(.post == 0) %>% group_by(.hh) %>%
      summarise(.ybl = mean(.y, na.rm = TRUE), .groups = "drop")
    dd <- d %>% filter(.post == 1) %>% left_join(bl, by = ".hh")
    dd$.blmiss <- as.numeric(!is.finite(dd$.ybl))
    fill <- mean(dd$.ybl[is.finite(dd$.ybl)])
    if (!is.finite(fill)) fill <- 0
    dd$.ybl[!is.finite(dd$.ybl)] <- fill
    m <- feols(.y ~ .treat + .ybl + .blmiss | .season, data = dd, cluster = ~.vil)
    print(coeftable(m)[".treat", , drop = FALSE])
    m
  }
  to_usd <- function(v) if (median(abs(v[is.finite(v) & v != 0]), na.rm = TRUE) > 2000) v / UGX_PER_USD else v

  ex <- "cost|_[0-9]+$|share|dummy|^d_|pre|base|lag"
  harvest_col <- find_col(pg, c("^harvest$", "^harvest_kg$", "harvest_kg", "^harvest_tot", "harvest_q"), exclude = "cost|val")

  # ---- price (household average price, USD/kg) ----
  price_ugx <- rep(NA_real_, nrow(pg))
  pcol <- find_col(pg, c("^price$", "av.*price", "avg.*price", "mean.*price", "price_av", "price_kg",
                         "unit_price", "price"),
                   exclude = paste0(ex, "|transport|seed|decob|lc_|fert|chem|herb|pest|input"))
  if (!is.na(pcol)) {
    price_ugx <- to_num(pg[[pcol]])
    add_diag("price col: ", pcol)
  } else {
    rev_col <- find_col(pg, c("^tot_rev$", "^revenue", "rev_tot", "tot_rev$", "^tot_rev_combined$", "revenue"),
                        exclude = "_[0-9]+$")
    kg_col <- find_col(pg, c("^kg_sold$", "sold_kg$", "^tot_sold", "quant.*sold", "sold.*quant", "^sold$", "kg_sold"),
                       exclude = "_[0-9]+$")
    if (is.na(rev_col)) {
      rc <- grep("^tot_rev_combined_[0-9]+$", pn, value = TRUE)
      if (length(rc)) {
        rm_ <- sapply(rc, function(cc) to_num(pg[[cc]]))
        pg$.rev <- ifelse(rowSums(!is.na(rm_)) > 0, rowSums(rm_, na.rm = TRUE), NA)
        rev_col <- ".rev"
      }
    }
    if (is.na(kg_col)) {
      kc <- grep("^(kg_sold|sold_kg|quantity_sold|qty_sold|q_sold|sold_q)_[0-9]+$", pn, value = TRUE)
      if (length(kc)) {
        km <- sapply(kc, function(cc) to_num(pg[[cc]]))
        pg$.kgs <- ifelse(rowSums(!is.na(km)) > 0, rowSums(km, na.rm = TRUE), NA)
        kg_col <- ".kgs"
      }
    }
    add_diag("rev col: ", rev_col, " kg sold col: ", kg_col)
    if (!is.na(rev_col) && !is.na(kg_col)) {
      r <- to_num(pg[[rev_col]]); k <- to_num(pg[[kg_col]])
      price_ugx <- ifelse(is.finite(k) & k > 0 & is.finite(r) & r > 0, r / k, NA)
      cat("DEVIATION: Average price constructed as total revenue / kg sold per household-season\n")
    }
  }
  if (any(is.finite(price_ugx))) {
    price_usd <- if (median(price_ugx, na.rm = TRUE) > 20) price_ugx / UGX_PER_USD else price_ugx
    tryCatch({
      m <- ancova(price_usd)
      emit("market_access_price_table6_panelA_col1", coef(m)[".treat"])
    }, error = function(e) cat("price error:", conditionMessage(e), "\n"))
  }

  # ---- yield ----
  tryCatch({
    ycol <- find_col(pg, c("^yield", "yield"), exclude = ex)
    if (!is.na(ycol)) {
      yv <- to_num(pg[[ycol]])
    } else {
      pcols <- grep("^plot_size_[0-9]+$", pn, value = TRUE)
      pg$.area <- rowSums(sapply(pcols, function(cc) to_num(pg[[cc]])), na.rm = TRUE)
      yv <- ifelse(pg$.area > 0, to_num(pg[[harvest_col]]) / pg$.area, NA)
    }
    m <- ancova(yv)
    emit("market_access_yield_table6_panelA_col4", coef(m)[".treat"])
  }, error = function(e) cat("yield error:", conditionMessage(e), "\n"))

  # ---- harvest value (USD/season) ----
  hv <- rep(NA_real_, nrow(pg))
  tryCatch({
    hcol <- find_col(pg, c("harvest_val", "value_harv", "harv.*val", "val.*harv", "harvest_usd"), exclude = ex)
    if (!is.na(hcol)) {
      hv <- to_usd(to_num(pg[[hcol]]))
    } else if (any(is.finite(price_ugx)) && !is.na(harvest_col)) {
      pu <- ifelse(is.finite(price_ugx) & price_ugx > 0, price_ugx, NA)
      vmed <- ave(pu, pg$.vil, pg$.season, FUN = function(x) if (all(is.na(x))) NA else median(x, na.rm = TRUE))
      smed <- ave(pu, pg$.season, FUN = function(x) if (all(is.na(x))) NA else median(x, na.rm = TRUE))
      pfill <- ifelse(is.finite(pu), pu, ifelse(is.finite(vmed), vmed, smed))
      hv <- to_num(pg[[harvest_col]]) * pfill / UGX_PER_USD
      cat("DEVIATION: Harvest value constructed as harvest kg x household price (village-season median if unsold)\n")
    }
    if (any(is.finite(hv))) {
      m <- ancova(hv)
      emit("market_access_harvest_value_table6_panelA_col5", coef(m)[".treat"])
      emit("n_obs_table6_panelA_cols3_5", nobs(m))
    }
  }, error = function(e) cat("harvest value error:", conditionMessage(e), "\n"))

  # ---- profit (monetary) ----
  tryCatch({
    prcol <- find_col(pg, c("profit_mon", "profit.*money", "profit_monet", "^profit$", "profit"), exclude = ex)
    if (!is.na(prcol)) {
      pr <- to_usd(to_num(pg[[prcol]]))
    } else if (any(is.finite(hv))) {
      tc <- find_col(pg, c("^tot.*cost$", "^cost_tot", "^total_cost", "^costs?$"), exclude = "_[0-9]+$")
      if (!is.na(tc)) {
        cost <- to_num(pg[[tc]])
      } else {
        cc <- grep("cost", pn, ignore.case = TRUE, value = TRUE)
        cc <- cc[!grepl("transportpre|transportpost|distance", cc)]
        cm <- sapply(cc, function(x) to_num(pg[[x]]))
        cost <- rowSums(cm, na.rm = TRUE)
      }
      cost <- if (median(cost[cost > 0], na.rm = TRUE) > 50) cost / UGX_PER_USD else cost
      pr <- hv - cost
      cat("DEVIATION: Monetary profit constructed as harvest value minus summed monetary cost items\n")
    } else pr <- NULL
    if (!is.null(pr)) {
      m <- ancova(pr)
      emit("market_access_profit_monetary_table6_panelA_col7", coef(m)[".treat"])
    }
    pocol <- find_col(pg, c("profit.*own", "profit.*fam", "profit.*hour", "profit.*lab", "profit_tot", "profit_all"), exclude = ex)
    if (!is.na(pocol) && !identical(pocol, prcol)) {
      m <- ancova(to_usd(to_num(pg[[pocol]])))
      emit("market_access_profit_incl_own_hours_table6_panelA_col8", coef(m)[".treat"])
    }
  }, error = function(e) cat("profit error:", conditionMessage(e), "\n"))
}, error = function(e) cat("Table 6 error:", conditionMessage(e), "\n"))

cat("\n==== Diagnostics ====\n")
for (l in diag_lines) cat(substr(l, 1, 600), "\n")
cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%.6g\n", n, results[[n]]))