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

to_num <- function(x) suppressWarnings(as.numeric(x))

# =====================================================================
# Returns-to-quality experiment (Table 2)
# =====================================================================
rd <- tryCatch(load_dta("data/raw/anonym_returns_data.dta"), error = function(e) NULL)
if (!is.null(rd)) {
  # print non-add4 names compactly (add4 is a wide bag grid)
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
    cat("Value distribution of visual defect items:\n")
    print(table(long$val, useNA = "ifany"))
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

  # ---- Col 2: lab defects ----
  tryCatch({
    lab_col <- find_col(rd, c("lab_def", "def.*lab", "defect_share", "share_def",
                              "lab.*waste", "waste.*lab"))
    cat("Lab defects column:", lab_col, "\n")
    if (!is.na(lab_col)) {
      rd$.lab <- to_num(rd[[lab_col]])
    } else {
      tot <- find_col(rd, c("totalweight"))
      comps <- grep("(broken|pestdamaged|rotten|immature|foreignmatter|inorganicmatter|discoloured|organic).*totg$",
                    nm, ignore.case = TRUE, value = TRUE)
      cat("Lab components:", comps, " total:", tot, "\n")
      if (length(comps) > 0) {
        s <- rowSums(sapply(comps, function(cc) to_num(rd[[cc]])), na.rm = FALSE)
        denom <- if (!is.na(tot)) to_num(rd[[tot]]) else 200
        rd$.lab <- 100 * s / denom
      } else rd$.lab <- NA_real_
    }
    labd <- rd[!is.na(rd$.lab), ]
    if (nrow(labd) > 0) {
      cat("Lab defect summary:\n"); print(summary(labd$.lab))
      m2 <- feols(.lab ~ .treat | .vil, data = labd, vcov = "hetero")
      print(summary(m2))
      emit("treatment_defects_lab_table2_col2", coef(m2)[".treat"])
    }
  }, error = function(e) cat("Col2 error:", conditionMessage(e), "\n"))

  # ---- Cols 3-5: sales ----
  tryCatch({
    scols <- grep("^add5_.*_[0-9]+$", nm, value = TRUE)
    sstems <- unique(sub("^add5_(.*)_([0-9]+)$", "\\1", scols))
    cat("add5 sale stems:\n"); print(sstems)
    pick <- function(pats, excl = NULL) {
      for (p in pats) {
        h <- grep(p, sstems, ignore.case = TRUE, value = TRUE)
        if (!is.null(excl)) h <- h[!grepl(excl, h, ignore.case = TRUE)]
        if (length(h)) return(h[1])
      }
      NA_character_
    }
    st_price <- pick(c("^price$", "price_kg", "price"), excl = "total|unit_?other")
    st_meas <- pick(c("measur", "enum.*w", "weigh", "scale"))
    st_agree <- pick(c("agree", "^kg_sold", "sold_kg", "quant", "kg"), excl = "measur|weigh")
    st_date <- pick(c("week", "date", "day"))
    cat("price:", st_price, " measured:", st_meas, " agreed:", st_agree, " date:", st_date, "\n")
    getw <- function(stem) {
      if (is.na(stem)) return(NULL)
      cc <- grep(paste0("^add5_", stem, "_[0-9]+$"), nm, value = TRUE)
      x <- rd[, c(".hh", ".vil", ".treat", cc), drop = FALSE]
      x[cc] <- lapply(x[cc], function(v) if (inherits(v, "Date")) as.numeric(v) else to_num(v))
      pivot_longer(x, all_of(cc), names_to = "var", values_to = stem) %>%
        mutate(sale = as.integer(sub(".*_([0-9]+)$", "\\1", var))) %>% select(-var)
    }
    sales <- getw(st_price)
    for (s in c(st_meas, st_agree, st_date)) {
      w <- getw(s)
      if (!is.null(w)) sales <- full_join(sales, w, by = c(".hh", ".vil", ".treat", "sale"))
    }
    sales <- sales[!is.na(sales[[st_price]]) & sales[[st_price]] > 0, ]
    sales$price <- sales[[st_price]]
    if (!is.na(st_date)) {
      d <- sales[[st_date]]
      sales$week <- if (median(d, na.rm = TRUE) > 10000) floor(d / 7) else floor(d / 7)
    } else sales$week <- 1
    if (!is.na(st_meas) && !is.na(st_agree)) {
      y <- sales[[st_meas]]; z <- sales[[st_agree]]
      sales$deduct <- 100 * (y - z) / y
      sales$netprice <- sales$price * z / y
    } else {
      sales$deduct <- NA_real_; sales$netprice <- NA_real_
    }
    cat("Sales N:", nrow(sales), " households:", length(unique(sales$.hh)), "\n")
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
  treat_col <- find_col(pg, c("^buy_treatment$", "^treatment$", "^treat$", "treat"))
  hh_col <- find_col(pg, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$"))
  vil_col <- find_col(pg, c("^ea_code$", "^village$", "village", "^ea$"))
  post_col <- find_col(pg, c("^season_post$", "^post$"))
  cat("treat:", treat_col, " hh:", hh_col, " vil:", vil_col, " post:", post_col, "\n")
  print(table(pg$survey_season, pg[[post_col]], useNA = "ifany"))
  pg$.treat <- to_num(pg[[treat_col]])
  pg$.hh <- pg[[hh_col]]; pg$.vil <- pg[[vil_col]]
  pg$.post <- to_num(pg[[post_col]])
  pg$.season <- pg$survey_season

  ex <- "cost|_[0-9]+$|share|dummy|^d_|pre|base|lag"
  outcomes <- list(
    market_access_price_table6_panelA_col1 = c("price_usd", "av.*price", "avg.*price", "mean.*price", "^price$", "price"),
    market_access_yield_table6_panelA_col4 = c("^yield", "yield"),
    market_access_harvest_value_table6_panelA_col5 = c("harvest_val", "value_harv", "harv.*val", "val.*harv"),
    market_access_profit_monetary_table6_panelA_col7 = c("profit_mon", "profit.*money", "profit_monet", "^profit$", "profit"),
    market_access_profit_incl_own_hours_table6_panelA_col8 = c("profit.*own", "profit.*fam", "profit.*hour", "profit.*lab", "profit_tot", "profit_all")
  )
  harvest_col <- find_col(pg, c("^harvest$", "^harvest_kg$", "harvest_kg", "^harvest_tot", "harvest_q"), exclude = "cost|val")
  cat("harvest col:", harvest_col, "\n")

  ancova <- function(ycol, money = FALSE) {
    d <- pg
    d$.y <- to_num(d[[ycol]])
    if (money && median(abs(d$.y[d$.y != 0]), na.rm = TRUE) > 2000) d$.y <- d$.y / UGX_PER_USD
    bl <- d %>% filter(.post == 0) %>% group_by(.hh) %>%
      summarise(.ybl = mean(.y, na.rm = TRUE), .groups = "drop")
    dd <- d %>% filter(.post == 1) %>% left_join(bl, by = ".hh")
    dd$.blmiss <- as.numeric(!is.finite(dd$.ybl))
    dd$.ybl[!is.finite(dd$.ybl)] <- mean(dd$.ybl, na.rm = TRUE)
    m <- feols(.y ~ .treat + .ybl + .blmiss | .season, data = dd, cluster = ~.vil)
    cat("\n--- ANCOVA:", ycol, "---\n"); print(coeftable(m)[".treat", , drop = FALSE])
    m
  }

  for (nmr in names(outcomes)) {
    tryCatch({
      excl <- if (grepl("price", nmr)) paste0(ex, "|transport|seed") else ex
      col <- find_col(pg, outcomes[[nmr]], exclude = excl)
      if (grepl("profit_incl", nmr) && !is.na(col)) {
        mon <- find_col(pg, outcomes[["market_access_profit_monetary_table6_panelA_col7"]], exclude = ex)
        if (identical(col, mon)) col <- NA
      }
      cat("Outcome", nmr, "->", col, "\n")
      if (is.na(col) && grepl("yield", nmr) && !is.na(harvest_col)) {
        pcols <- grep("^plot_size_[0-9]+$", names(pg), value = TRUE)
        pg$.area <- rowSums(sapply(pcols, function(cc) to_num(pg[[cc]])), na.rm = TRUE)
        pg$.yield <- ifelse(pg$.area > 0, to_num(pg[[harvest_col]]) / pg$.area, NA)
        col <- ".yield"
      }
      if (!is.na(col)) {
        money <- !grepl("yield", nmr)
        m <- ancova(col, money = money)
        emit(nmr, coef(m)[".treat"])
        if (grepl("harvest_value", nmr)) emit("n_obs_table6_panelA_cols3_5", nobs(m))
      }
    }, error = function(e) cat("Error", nmr, ":", conditionMessage(e), "\n"))
  }
}, error = function(e) cat("Table 6 error:", conditionMessage(e), "\n"))

cat("\n")
for (n in names(results)) cat(sprintf("RESULT:%s=%.6g\n", n, results[[n]]))
