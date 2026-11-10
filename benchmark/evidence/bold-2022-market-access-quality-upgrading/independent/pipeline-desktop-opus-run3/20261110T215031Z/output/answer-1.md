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

# ------------------------------------------------------------------
# Returns-to-quality experiment (Table 2)
# ------------------------------------------------------------------
r <- tryCatch(rd("data/raw/anonym_returns_data.dta"), error = function(e) NULL)

if (!is.null(r)) {
  cat("# returns data columns (non add4):\n")
  cat("#", paste(names(r)[!grepl("^add4_", names(r))], collapse = " "), "\n")

  treat_col <- find_col(r, c("^treatment$", "^treat"))
  vil_col <- find_col(r, c("^village$", "^village_id$", "^vil", "^ea_code$", "^ea$", "village", "^ea_", "lc1", "parish"))
  hh_col <- find_col(r, c("^hhh_id$", "^hh_id$", "^hhid$", "^id$", "household"))
  r$.treat <- num(r[[treat_col]])
  r$.vil <- if (!is.null(vil_col)) as.character(r[[vil_col]]) else "1"
  r$.hh <- if (!is.null(hh_col)) as.character(r[[hh_col]]) else as.character(seq_len(nrow(r)))

  # ---- Column 1: visual defects, bag level ----
  tryCatch({
    types <- c("dirt", "cobs", "stones", "dust", "insects", "broken", "immature", "damaged", "rotten", "moldy")
    found <- list()
    for (t in types) {
      cols <- grep(paste0("^add4_", t, "_[0-9]+$"), names(r), value = TRUE)
      if (length(cols) == 0) cols <- grep(paste0("_", t, "_[0-9]+$"), names(r), value = TRUE)
      if (length(cols) > 0) found[[t]] <- cols
    }
    cat("# visual defect types found:", paste(names(found), collapse = ","), "\n")
    allvals <- unlist(lapply(unlist(found), function(cc) num(r[[cc]])))
    allvals <- allvals[!is.na(allvals)]
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
    m1 <- feols(defects ~ treat | vil, data = bl, cluster = ~hh)
    print(summary(m1))
    emit("treatment_defects_visual_table2_col1", unname(coef(m1)["treat"]))
    emit("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) cat("# col1 error:", conditionMessage(e), "\n"))

  # ---- Column 2: lab defects ----
  tryCatch({
    labc <- find_col(r, c("lab_def", "defects_lab", "lab.*defect", "defect.*lab", "^lab"))
    y <- NULL
    if (!is.null(labc)) {
      y <- num(r[[labc]])
    } else {
      tw <- find_col(r, c("totalweightofmaizeg", "totalweight"))
      comps <- grep("(broken|pestdamaged|rotten|immature|foreignmatter|inorganic|discoloured|shrivel).*totg$",
                    names(r), value = TRUE, ignore.case = TRUE)
      if (length(comps) > 0) {
        s <- rowSums(sapply(comps, function(cc) num(r[[cc]])), na.rm = FALSE)
        tot <- if (!is.null(tw)) num(r[[tw]]) else 200
        y <- s / tot
      }
    }
    if (!is.null(y)) {
      if (median(y, na.rm = TRUE) > 1) y <- y / 100
      d2 <- data.frame(y = y, treat = r$.treat, vil = r$.vil)
      m2 <- feols(y ~ treat | vil, data = d2, vcov = "hetero")
      print(summary(m2))
      emit("treatment_defects_lab_table2_col2", unname(coef(m2)["treat"]))
    } else cat("# no lab defect columns found\n")
  }, error = function(e) cat("# col2 error:", conditionMessage(e), "\n"))

  # ---- Columns 3-5: sales ----
  tryCatch({
    add5 <- grep("^add5_", names(r), value = TRUE)
    cat("# add5 columns:", paste(head(add5, 200), collapse = " "), "\n")
    pcols <- grep("price", names(r), value = TRUE, ignore.case = TRUE)
    pcols <- pcols[grepl("_[0-9]+$", pcols)]
    pstem <- unique(sub("_[0-9]+$", "", pcols))
    pstem <- pstem[!grepl("total|tot_|unit", pstem)]
    if (length(pstem) == 0) stop("no price columns")
    pstem <- pstem[1]
    stem_of <- function(pats) {
      for (p in pats) {
        cc <- grep(p, names(r), value = TRUE, ignore.case = TRUE)
        cc <- cc[grepl("_[0-9]+$", cc)]
        if (length(cc) > 0) return(sub("_[0-9]+$", "", cc[1]))
      }
      NULL
    }
    ystem <- stem_of(c("measured", "weight_enum", "enum.*kg", "weigh"))
    zstem <- stem_of(c("agreed", "kg_sold", "sold_kg", "quantity", "_kg"))
    wstem <- stem_of(c("week", "date"))
    idx <- sort(unique(as.integer(sub(".*_([0-9]+)$", "\\1", grep(paste0("^", pstem, "_[0-9]+$"), names(r), value = TRUE)))))
    sl <- list()
    for (i in idx) {
      g <- function(st) if (!is.null(st) && paste0(st, "_", i) %in% names(r)) r[[paste0(st, "_", i)]] else rep(NA, nrow(r))
      p <- num(g(pstem))
      ok <- !is.na(p) & p > 0
      if (any(ok)) {
        wk <- g(wstem)
        if (inherits(wk, "Date") || inherits(wk, "POSIXt")) wk <- format(as.Date(wk), "%Y-%U")
        sl[[length(sl) + 1]] <- data.frame(price = p[ok], y = num(g(ystem))[ok], z = num(g(zstem))[ok],
                                           week = as.character(wk[ok]), treat = r$.treat[ok],
                                           vil = r$.vil[ok], hh = r$.hh[ok])
      }
    }
    s <- do.call(rbind, sl)
    s$week[is.na(s$week)] <- "NA"
    s$ded <- 100 * (s$y - s$z) / s$y
    s$net <- s$price * s$z / s$y
    m3 <- feols(price ~ treat | vil + week, data = s, cluster = ~hh)
    print(summary(m3))
    emit("treatment_price_table2_col3", unname(coef(m3)["treat"]))
    emit("n_obs_table2_cols3_5_sales", nobs(m3))
    m4 <- tryCatch(feols(ded ~ treat | vil + week, data = s, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m4)) emit("treatment_deductions_table2_col4", unname(coef(m4)["treat"]))
    m5 <- tryCatch(feols(net ~ treat | vil + week, data = s, cluster = ~hh), error = function(e) NULL)
    if (!is.null(m5)) emit("treatment_net_price_table2_col5", unname(coef(m5)["treat"]))
  }, error = function(e) cat("# cols3-5 error:", conditionMessage(e), "\n"))
}

# ------------------------------------------------------------------
# Market access experiment (Table 6 Panel A): ANCOVA
# ------------------------------------------------------------------
p <- tryCatch(rd("data/raw/panel_g1.dta"), error = function(e) NULL)
if (!is.null(p)) {
  cat("# panel_g1 columns:\n#", paste(names(p), collapse = " "), "\n")
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
    # treatment is a village-level assignment; fill across seasons
    tv <- tapply(p$.treat, p$.vil, function(x) max(x, na.rm = TRUE))
    p$.treat <- as.numeric(tv[p$.vil])

    plot_cols <- grep("^plot_size_[0-9]+$", names(p), value = TRUE)
    area <- if (length(plot_cols) > 0) rowSums(sapply(plot_cols, function(cc) num(p[[cc]])), na.rm = TRUE) else NA
    area[area == 0] <- NA

    getv <- function(pats, exclude = NULL) {
      cc <- find_col(p, pats, exclude)
      if (is.null(cc)) return(NULL)
      cat("# using", cc, "\n")
      num(p[[cc]])
    }
    outs <- list()
    outs$price <- getv(c("^price_usd$", "^avg_price_usd", "^price_av", "^av_price", "^price$", "price_kg", "^price"),
                       exclude = "cost|seed")
    harvest <- getv(c("^harvest_kg$", "^harvest$", "^harvest_tot", "^tot_harvest", "harvest_kg", "^harvest_q"),
                    exclude = "cost|value|usd")
    outs$harvest <- harvest
    yv <- getv(c("^yield$", "^yield_"))
    outs$yield <- if (!is.null(yv)) yv else if (!is.null(harvest)) harvest / area else NULL
    outs$hvalue <- getv(c("^harvest_value_usd$", "^harvest_value", "^value_harvest", "harvest.*val"))
    outs$profit_m <- getv(c("^profit_usd$", "^profit$", "^profit_mon", "^profit_1$", "^profit"), exclude = "own|hour|fam")
    outs$profit_own <- getv(c("profit.*own", "profit.*hour", "profit.*fam", "^profit_2$"))

    usd_rate <- 3700
    to_usd <- function(v, thresh) if (!is.null(v) && median(v, na.rm = TRUE) > thresh) v / usd_rate else v
    outs$price <- to_usd(outs$price, 5)
    outs$hvalue <- to_usd(outs$hvalue, 5000)
    outs$profit_m <- to_usd(outs$profit_m, 5000)
    outs$profit_own <- to_usd(outs$profit_own, 5000)

    ancova <- function(v) {
      if (is.null(v)) return(NULL)
      d <- data.frame(y = v, treat = p$.treat, hh = p$.hh, vil = p$.vil, season = p$.season, post = p$.post)
      bmean <- tapply(d$y[d$post == 0], d$hh[d$post == 0], function(x) mean(x, na.rm = TRUE))
      d$base <- as.numeric(bmean[d$hh])
      d$base_miss <- as.numeric(is.na(d$base))
      d$base[is.na(d$base)] <- 0
      dp <- d[d$post == 1 & !is.na(d$y), ]
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
