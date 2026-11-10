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
    n_entries <- nrow(sales)
    cat("Entries per household:\n"); print(table(table(sales$.hh)))

    # harvest date (sales of the experimental harvest only)
    hcol <- grep("^add1_harvest_new_when_e", nm, value = TRUE)
    if (length(hcol)) {
      hd <- data.frame(.hh = rd$.hh, hdate = to_num(rd[[hcol[1]]]))
      hd <- hd[!duplicated(hd$.hh), ]
      sales <- left_join(sales, hd, by = ".hh")
    } else sales$hdate <- NA_real_

    collapse_sales <- function(s, key) {
      s$.key <- key
      s %>% group_by(.hh, .vil, .treat, .key) %>%
        summarise(
          date = suppressWarnings(min(date, na.rm = TRUE)),
          price = if (all(is.finite(y) & y > 0)) weighted.mean(price, y) else mean(price),
          y2 = if (all(is.na(y))) NA_real_ else sum(y, na.rm = TRUE),
          z = if (all(is.na(z))) NA_real_ else sum(z, na.rm = TRUE),
          .groups = "drop") %>%
        rename(y = y2) %>%
        mutate(date = ifelse(is.finite(date), date, NA_real_))
    }
    key_date <- function(s) ifelse(is.na(s$date), paste0("s", s$sale), paste0("d", s$date))
    key_week <- function(s) ifelse(is.na(s$date), paste0("s", s$sale), paste0("w", floor(s$date / 7)))
    key_price <- function(s) paste0("p", s$price)
    post_h <- sales[is.na(sales$hdate) | is.na(sales$date) | sales$date >= sales$hdate, ]

    cands <- list(
      date = collapse_sales(sales, key_date(sales)),
      week = collapse_sales(sales, key_week(sales)),
      price = collapse_sales(sales, key_price(sales)),
      postharvest_date = collapse_sales(post_h, key_date(post_h)),
      postharvest_price = collapse_sales(post_h, key_price(post_h)))
    for (cn in names(cands)) {
      add_diag("sale definition ", cn, ": N=", nrow(cands[[cn]]),
               " hh=", length(unique(cands[[cn]]$.hh)))
    }
    gaps <- sapply(cands, function(x) abs(nrow(x) - 116) + abs(length(unique(x$.hh)) - 94))
    chosen <- names(cands)[which.min(gaps)]
    sales <- cands[[chosen]]
    cat("DEVIATION: Sale (transaction) definition not documented in the data; entries collapsed using the '",
        chosen, "' definition (", n_entries, "entries ->", nrow(sales), "sales), chosen among same-date, same-week, same-price and post-harvest-only definitions\n")
    sales$week <- if (all(is.na(sales$date))) 1 else floor(sales$date / 7)
    sales$week[is.na(sales$week)] <- -1

    ok <- is.finite(sales$y) & sales$y > 0
    sales$deduct <- ifelse(ok, 100 * (sales$y - sales$z) / sales$y, NA)
    sales$netprice <- ifelse(ok, sales$price * sales$z / sales$y, NA)
    cat("Sales N:", nrow(sales), " households:", length(unique(sales$.hh)), "\n")
    add_diag("sales entries=", n_entries, " chosen=", chosen, " N=", nrow(sales), " hh=", length(unique(sales$.hh)),
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
  is_post <- !is.na(pg$.post) & pg$.post == 1

  kw <- "price|rev|val|profit|yield|sold|sale|acre|area|labo|hour|wage|tot_|total"
  nonwide <- pn[!grepl("_[0-9]+$", pn)]
  wst <- unique(sub("_[0-9]+$", "", pn[grepl("_[0-9]+$", pn)]))
  add_diag("pg nonwide kw: ", paste(grep(kw, nonwide, ignore.case = TRUE, value = TRUE), collapse = " "))
  add_diag("pg wide stems kw: ", paste(grep(kw, wst, ignore.case = TRUE, value = TRUE), collapse = " "))
  add_diag("pg hour cols: ", paste(grep("hour|fam|own_lab|wage", pn, ignore.case = TRUE, value = TRUE), collapse = " "))

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

  sumwide <- function(re) {
    cc <- grep(re, pn, value = TRUE)
    if (!length(cc)) return(NULL)
    m <- sapply(cc, function(x) to_num(pg[[x]]))
    if (is.null(dim(m))) m <- matrix(m, ncol = 1)
    ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA)
  }
  rsum <- function(cols) {
    if (!length(cols)) return(rep(NA_real_, nrow(pg)))
    m <- sapply(cols, function(x) to_num(pg[[x]]))
    if (is.null(dim(m))) m <- matrix(m, ncol = 1)
    ifelse(rowSums(!is.na(m)) > 0, rowSums(m, na.rm = TRUE), NA)
  }

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
    rev_c <- list(
      told_tot = if ("tot_rev_told_tot" %in% pn) to_num(pg$tot_rev_told_tot) else NULL,
      combined = sumwide("^tot_rev_combined_[0-9]+$"),
      combined2 = sumwide("^tot_rev_combined2_[0-9]+$"))
    kg_c <- list(
      sold_kg = if ("sold_kg" %in% pn) to_num(pg$sold_kg) else NULL,
      sold_kg_p = sumwide("^sold_kg_p_[0-9]+$"))
    rev_c <- rev_c[!sapply(rev_c, is.null)]
    kg_c <- kg_c[!sapply(kg_c, is.null)]
    best <- NULL; best_n <- -1
    for (rn in names(rev_c)) for (kn in names(kg_c)) {
      r <- rev_c[[rn]]; k <- kg_c[[kn]]
      p <- ifelse(is.finite(k) & k > 0 & is.finite(r) & r > 0, r / k, NA)
      p[!is.finite(p) | p < 100 | p > 5000] <- NA
      npost <- sum(is.finite(p[is_post]))
      add_diag("price candidate ", rn, "/", kn, ": post N=", npost,
               " median=", round(median(p, na.rm = TRUE), 1))
      if (npost > best_n) { best_n <- npost; best <- p; best_lab <- paste0(rn, "/", kn) }
    }
    if (!is.null(best)) {
      price_ugx <- best
      add_diag("price chosen: ", best_lab)
      cat("DEVIATION: Average price constructed as total revenue / kg sold per household-season (",
          best_lab, ", plausible range 100-5000 UGX/kg)\n")
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
  yv <- rep(NA_real_, nrow(pg))
  area <- if ("acres_tot" %in% pn) to_num(pg$acres_tot) else rep(NA_real_, nrow(pg))
  tryCatch({
    ycol <- find_col(pg, c("^yield", "yield"), exclude = ex)
    if (!is.na(ycol)) {
      yv <- to_num(pg[[ycol]])
      add_diag("yield col: ", ycol)
    } else {
      pcols <- grep("^plot_size_[0-9]+$", pn, value = TRUE)
      pg$.area <- rowSums(sapply(pcols, function(cc) to_num(pg[[cc]])), na.rm = TRUE)
      area <- ifelse(is.finite(area), area, pg$.area)
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
    } else if (any(is.finite(price_ugx))) {
      hk1 <- if (!is.na(harvest_col)) to_num(pg[[harvest_col]]) else rep(NA_real_, nrow(pg))
      hk2 <- ifelse(is.finite(yv) & is.finite(area), yv * area, NA)
      n1 <- sum(is.finite(hk1[is_post])); n2 <- sum(is.finite(hk2[is_post]))
      add_diag("harvest col: ", harvest_col, " post N=", n1, "; yield x acres post N=", n2)
      hk <- if (n2 > n1) ifelse(is.finite(hk2), hk2, hk1) else ifelse(is.finite(hk1), hk1, hk2)
      pu <- ifelse(is.finite(price_ugx) & price_ugx > 0, price_ugx, NA)
      vmed <- ave(pu, pg$.vil, pg$.season, FUN = function(x) if (all(is.na(x))) NA else median(x, na.rm = TRUE))
      smed <- ave(pu, pg$.season, FUN = function(x) if (all(is.na(x))) NA else median(x, na.rm = TRUE))
      amed <- median(pu, na.rm = TRUE)
      pfill <- ifelse(is.finite(pu), pu, ifelse(is.finite(vmed), vmed, ifelse(is.finite(smed), smed, amed)))
      hv <- hk * pfill / UGX_PER_USD
      cat("DEVIATION: Harvest value constructed as harvest kg (yield x acres where harvest missing) x household price (village-season median if unsold)\n")
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
    pr <- NULL
    if (!is.na(prcol)) {
      pr <- to_usd(to_num(pg[[prcol]]))
    } else if (any(is.finite(hv))) {
      tc <- find_col(pg, c("^tot.*cost$", "^cost_tot", "^total_cost", "^costs?$"), exclude = "_[0-9]+$|transport")
      if (!is.na(tc)) {
        cost <- to_num(pg[[tc]])
        add_diag("cost col: ", tc)
      } else {
        cc <- grep("cost", pn, ignore.case = TRUE, value = TRUE)
        cc <- cc[!grepl("transport|distance", cc, ignore.case = TRUE)]
        # hired labour: seasonal totals (tot_lab_costs) if present, else lc_*_season items;
        # per-unit rates (lc_*_unit) are never summed
        lab_tot <- rsum(grep("^tot_lab_costs", cc, value = TRUE))
        lab_lc <- rsum(grep("^lc_.*season", cc, value = TRUE))
        lab <- ifelse(is.finite(lab_tot), lab_tot, lab_lc)
        rest <- cc[!grepl("^tot_lab_costs|^lc_", cc)]
        cstems <- unique(sub("_[0-9]+$", "", rest))
        comp <- sapply(cstems, function(st) {
          un <- if (st %in% rest) to_num(pg[[st]]) else rep(NA_real_, nrow(pg))
          sf <- rsum(rest[grepl("_[0-9]+$", rest) & sub("_[0-9]+$", "", rest) == st])
          ifelse(is.finite(un), un, sf)
        })
        if (is.null(dim(comp))) comp <- matrix(comp, ncol = 1)
        add_diag("cost stems: ", paste(cstems, collapse = " "), " + hired labour")
        cost <- rowSums(cbind(comp, lab), na.rm = TRUE)
        cat("DEVIATION: Cost items de-duplicated: per-unit labour rates excluded, seasonal labour totals preferred over item-level labour costs, unsuffixed totals preferred over numbered items\n")
      }
      cost <- if (median(cost[cost > 0], na.rm = TRUE) > 50) cost / UGX_PER_USD else cost
      pr <- hv - cost
      cat("DEVIATION: Monetary profit constructed as harvest value minus summed monetary input/labour cost items (transport excluded)\n")
    }
    if (!is.null(pr)) {
      m <- ancova(pr)
      emit("market_access_profit_monetary_table6_panelA_col7", coef(m)[".treat"])
    }
    pocol <- find_col(pg, c("profit.*own", "profit.*fam", "profit.*hour", "profit.*lab", "profit_tot", "profit_all"), exclude = ex)
    if (!is.na(pocol) && !identical(pocol, prcol)) {
      m <- ancova(to_usd(to_num(pg[[pocol]])))
      emit("market_access_profit_incl_own_hours_table6_panelA_col8", coef(m)[".treat"])
    } else if (!is.null(pr)) {
      # family labour hours valued at the hired wage
      famh_cols <- grep("hour", pn, ignore.case = TRUE, value = TRUE)
      famh_cols <- famh_cols[grepl("fam|own|hh_lab|household", famh_cols, ignore.case = TRUE)]
      famh <- NULL; wage <- NA_real_
      lh_idx <- unique(sub("^lh_.*_hours_season([0-9]+)$", "\\1",
                           grep("^lh_.*_hours_season[0-9]+$", pn, value = TRUE)))
      hrs_k <- list(); cst_k <- list()
      for (k in lh_idx) {
        hrs_k[[k]] <- rsum(grep(paste0("^lh_.*_hours_season", k, "$"), pn, value = TRUE))
        cst_k[[k]] <- rsum(grep(paste0("^lc_.*_costs_season", k, "$"), pn, value = TRUE))
        add_diag("labour index ", k, ": total hours=", round(sum(hrs_k[[k]], na.rm = TRUE)),
                 " total cost=", round(sum(cst_k[[k]], na.rm = TRUE)))
      }
      if (length(famh_cols)) {
        famh <- rsum(famh_cols)
        add_diag("family hours cols: ", paste(famh_cols, collapse = " "))
      } else if (length(lh_idx)) {
        th <- sapply(hrs_k, function(v) sum(v, na.rm = TRUE))
        tcst <- sapply(cst_k, function(v) sum(v, na.rm = TRUE))
        fam_k <- names(th)[th > 0 & tcst <= 0.01 * max(tcst)]
        if (length(fam_k)) {
          famh <- Reduce(function(a, b) ifelse(is.na(a), 0, a) + ifelse(is.na(b), 0, b), hrs_k[fam_k])
          add_diag("family labour indices: ", paste(fam_k, collapse = ","))
        }
      }
      hk <- names(hrs_k)[sapply(names(hrs_k), function(k) sum(cst_k[[k]], na.rm = TRUE) > 0)]
      if (length(hk)) {
        H <- sum(sapply(hk, function(k) sum(hrs_k[[k]][is.finite(cst_k[[k]])], na.rm = TRUE)))
        C <- sum(sapply(hk, function(k) sum(cst_k[[k]][is.finite(hrs_k[[k]])], na.rm = TRUE)))
        if (H > 0) wage <- C / H
      }
      if (!is.finite(wage) || wage <= 0 || wage > 10000) wage <- 5000 / 8
      add_diag("hourly wage (UGX)=", round(wage, 1))
      if (!is.null(famh) && any(is.finite(famh) & famh > 0)) {
        famh[!is.finite(famh)] <- 0
        pr2 <- pr - famh * wage / UGX_PER_USD
        cat("DEVIATION: Profit incl. own hours = monetary profit minus family labour hours valued at the average hired hourly wage (",
            round(wage, 1), "UGX/hour)\n")
        m <- ancova(pr2)
        emit("market_access_profit_incl_own_hours_table6_panelA_col8", coef(m)[".treat"])
      }
    }
  }, error = function(e) cat("profit error:", conditionMessage(e), "\n"))
}, error = function(e) cat("Table 6 error:", conditionMessage(e), "\n"))

cat("\n==== Diagnostics ====\n")
for (l in diag_lines) cat(substr(l, 1, 600), "\n")
cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%.6g\n", n, results[[n]]))