suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(lubridate)
})
set.seed(42)
options(warn = 1)

root <- "<repo>/.cache/datasets/bold_2022_market_access_quality_upgrading.script-free"
raw  <- file.path(root, "data", "raw")

result_names <- c(
  "treatment_defects_visual_table2_col1",
  "treatment_defects_lab_table2_col2",
  "treatment_price_table2_col3",
  "treatment_deductions_table2_col4",
  "treatment_net_price_table2_col5",
  "n_obs_table2_col1_bags",
  "n_obs_table2_cols3_5_sales",
  "market_access_price_table6_panelA_col1",
  "market_access_yield_table6_panelA_col4",
  "market_access_harvest_value_table6_panelA_col5",
  "market_access_profit_monetary_table6_panelA_col7",
  "market_access_profit_incl_own_hours_table6_panelA_col8",
  "n_obs_table6_panelA_cols3_5"
)
results <- setNames(as.list(rep(NA_real_, length(result_names))), result_names)
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  results[[name]] <<- if (length(v) == 0) NA_real_ else v[1]
}

# ---------------------------------------------------------------- helpers
read_data <- function(f) {
  x <- haven::read_dta(file.path(raw, f))
  labs <- vapply(x, function(col) {
    l <- attr(col, "label", exact = TRUE)
    if (is.null(l)) "" else as.character(l)[1]
  }, character(1))
  x <- haven::zap_labels(x)
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  names(x) <- tolower(names(x))
  names(labs) <- names(x)
  attr(x, "varlabels") <- labs
  x
}

is_char <- function(x) is.character(x) || is.factor(x)

tonum <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x))
  if (inherits(x, "POSIXt")) return(as.numeric(x) / 86400)
  if (is.factor(x)) x <- as.character(x)
  if (is.character(x)) {
    x <- trimws(x)
    x[x %in% c("", ".")] <- NA
    return(suppressWarnings(as.numeric(x)))
  }
  as.numeric(x)
}

keychr <- function(x) {
  n <- suppressWarnings(tonum(x))
  if (sum(!is.na(n)) >= 0.9 * sum(!is.na(x) & as.character(x) != "")) as.character(n) else as.character(x)
}

vil_pats <- c("^ea_code$", "ea_code", "^village$", "^village_id$", "village", "^vil", "^ea$",
              "parish", "community", "^lc1")
bad_vil <- "dist|km|_min|min_|gps|lat|lon|alt|acc|phone"
vcheck <- function(x) {
  ok <- !is.na(x) & as.character(x) != ""
  u <- length(unique(x[ok]))
  u >= 2 && u <= 60 && mean(ok) >= 0.7
}
find_vil <- function(df) {
  for (p in vil_pats) {
    cs <- grep(p, names(df), value = TRUE)
    cs <- cs[!grepl(bad_vil, cs)]
    for (cn in cs) if (vcheck(df[[cn]])) return(cn)
  }
  NA_character_
}

fit <- function(df, y, fes, vc) {
  fes <- fes[vapply(fes, function(f) f %in% names(df) &&
                      length(unique(df[[f]][!is.na(df[[f]])])) > 1, logical(1))]
  f <- if (length(fes)) as.formula(paste(y, "~ treat |", paste(fes, collapse = " + "))) else
    as.formula(paste(y, "~ treat"))
  if (inherits(vc, "formula")) feols(f, data = df, cluster = vc) else feols(f, data = df, vcov = vc)
}

ntok <- function(x) {
  x <- as.character(x)
  out <- rep(NA_real_, length(x))
  ok <- !is.na(x) & trimws(x) != ""
  if (any(ok)) {
    out[ok] <- vapply(strsplit(trimws(x[ok]), "[[:space:],;]+"), function(t)
      sum(!(tolower(t) %in% c("0", "none", "-99", "-98", "no", ""))), numeric(1))
  }
  out
}

to_days <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x))
  if (inherits(x, "POSIXt")) return(as.numeric(as.Date(x)))
  if (is_char(x)) {
    d <- suppressWarnings(lubridate::parse_date_time(as.character(x),
           orders = c("dmy", "ymd", "mdy", "dmy HMS", "ymd HMS", "mdy HMS"), quiet = TRUE))
    return(as.numeric(as.Date(d)))
  }
  v <- as.numeric(x)
  med <- suppressWarnings(median(v, na.rm = TRUE))
  if (is.na(med)) return(v)
  if (med > 1e8) return(v / 86400000 - 3653)       # Stata %tc (ms since 1960)
  if (med > 19000 && med < 30000) return(v - 3653)  # Stata %td (days since 1960)
  v
}

# ======================================================== RETURNS TO QUALITY
rd <- NULL
tryCatch({
  rd <- read_data("anonym_returns_data.dta")
}, error = function(e) message("Could not read returns data: ", conditionMessage(e)))

if (!is.null(rd)) {
  rlabs <- attr(rd, "varlabels")
  vv <- find_vil(rd)
  message("Returns data village variable: ", vv)
  rd$vil_ <- if (!is.na(vv)) as.character(rd[[vv]]) else "1"
  tv <- if ("treatment" %in% names(rd)) "treatment" else grep("treat", names(rd), value = TRUE)[1]
  rd$treat_ <- tonum(rd[[tv]])
  rd$hh_ <- seq_len(nrow(rd))

  # ---------------- Column 1: visually verifiable defects per bag
  tryCatch({
    bc <- grep("^add4_.+_[0-9]+$", names(rd), value = TRUE)
    binfo <- data.frame(col = bc, stem = sub("_[0-9]+$", "", bc),
                        idx = as.integer(sub("^.*_([0-9]+)$", "\\1", bc)),
                        stringsAsFactors = FALSE)
    binfo$lab <- rlabs[binfo$col]
    binfo$lab[is.na(binfo$lab)] <- ""
    txt <- tolower(paste(binfo$stem, binfo$lab))
    kw <- "dirt|cob|stone|dust|insect|broken|immature|damag|rotten|mou?ld|defect"
    ex <- "none|no_def|clean|moist|weight|_kg|kilo|photo|note|spec|random|gps|time|date|price|ppk|_any|any_"
    binfo <- binfo[grepl(kw, txt) & !grepl(ex, tolower(binfo$stem)), ]
    stems <- unique(binfo$stem)
    message("Visual defect stems: ", paste(stems, collapse = ", "))
    if (length(stems) == 0) stop("no visual defect variables found")
    K <- sort(unique(binfo$idx))
    cls <- vapply(stems, function(s) {
      cols <- binfo$col[binfo$stem == s]
      if (any(vapply(cols, function(cn) is_char(rd[[cn]]), logical(1)))) return("str")
      v <- unlist(lapply(cols, function(cn) tonum(rd[[cn]])))
      v <- v[!is.na(v)]
      if (length(v) == 0) return("empty")
      if (all(v %in% c(0, 1))) "bin" else "cnt"
    }, character(1))
    getmat <- function(s, conv) {
      m <- matrix(NA_real_, nrow(rd), length(K))
      for (j in seq_along(K)) {
        cn <- paste0(s, "_", K[j])
        if (cn %in% names(rd)) m[, j] <- conv(rd[[cn]])
      }
      m
    }
    cntpref <- stems[cls == "cnt" & grepl("n_?def|num|count|tot|ndef", stems)]
    cntpref <- cntpref[vapply(cntpref, function(s) {
      v <- as.vector(getmat(s, tonum)); v <- v[!is.na(v)]
      length(v) > 0 && all(v >= 0 & v <= 10)
    }, logical(1))]
    if (length(cntpref)) {
      use <- cntpref[1]; mode <- "cnt"
    } else if (sum(cls == "bin") >= 2) {
      use <- stems[cls == "bin"]; mode <- "bin"
    } else if (any(cls == "str")) {
      ss <- stems[cls == "str"]
      use <- if (any(grepl("defect", ss))) ss[grepl("defect", ss)][1] else ss[1]; mode <- "str"
    } else {
      use <- stems[cls %in% c("cnt", "bin")]; mode <- "cnt"
    }
    message("Visual defects: mode=", mode, " stems=", paste(use, collapse = ", "))
    conv <- if (mode == "str") ntok else tonum
    mats <- lapply(use, function(s) getmat(s, conv))
    obs <- Reduce(`|`, lapply(mats, function(m) !is.na(m)))
    score <- Reduce(`+`, lapply(mats, function(m) { m[is.na(m)] <- 0; m }))
    bags <- data.frame(hh = rep(seq_len(nrow(rd)), times = length(K)),
                       def = as.vector(score), ob = as.vector(obs))
    bags <- bags[bags$ob, ]
    bags$vil <- rd$vil_[bags$hh]
    bags$treat <- rd$treat_[bags$hh]
    bags <- bags[!is.na(bags$treat), ]
    m1 <- fit(bags, "def", c("vil"), ~hh)
    print(summary(m1))
    put("treatment_defects_visual_table2_col1", coef(m1)["treat"])
    put("n_obs_table2_col1_bags", nobs(m1))
  }, error = function(e) message("Visual defects block failed: ", conditionMessage(e)))

  # ---------------- Column 2: lab defects (one random bag per household)
  tryCatch({
    labnames <- names(rd)[!grepl("^add[0-9]", names(rd))]
    pickone <- function(p) {
      cs <- labnames[grepl(p, labnames)]
      cs <- cs[!grepl("pct|perc|share|prop|count|live|aflat|total_weight|totalweight|ratio|cost|price", cs)]
      cs <- cs[vapply(cs, function(cn) !is_char(rd[[cn]]), logical(1))]
      if (!length(cs)) return(NA_character_)
      g <- cs[grepl("_g$|tot_g|_g_|gram", cs)]
      if (length(g)) g[1] else cs[1]
    }
    kws <- c("broken", "pest", "rotten", "immature|shrivel", "discolo", "foreign", "mou?ld")
    dcols <- unique(na.omit(vapply(kws, pickone, character(1))))
    message("Lab defect columns: ", paste(dcols, collapse = ", "))
    if (!length(dcols)) stop("no lab defect columns")
    dm <- sapply(dcols, function(cn) tonum(rd[[cn]]))
    if (is.null(dim(dm))) dm <- matrix(dm, ncol = 1)
    anyobs <- rowSums(!is.na(dm)) > 0
    dsum <- rowSums(dm, na.rm = TRUE); dsum[!anyobs] <- NA
    tw <- grep("total_weight|totalweight", labnames, value = TRUE)
    tot <- if (length(tw)) tonum(rd[[tw[1]]]) else rep(NA_real_, nrow(rd))
    labdef <- ifelse(!is.na(tot) & tot > 0, 100 * dsum / tot, dsum / 2)
    ld <- data.frame(hh = rd$hh_, vil = rd$vil_, treat = rd$treat_, lab = labdef)
    ld <- ld[!is.na(ld$lab) & !is.na(ld$treat), ]
    m2 <- fit(ld, "lab", c("vil"), "hetero")
    print(summary(m2))
    put("treatment_defects_lab_table2_col2", coef(m2)["treat"])
  }, error = function(e) message("Lab defects block failed: ", conditionMessage(e)))

  # ---------------- Columns 3-5: sales
  tryCatch({
    sc <- grep("^add5_.+_[0-9]+$", names(rd), value = TRUE)
    sinfo <- data.frame(col = sc, stem = sub("_[0-9]+$", "", sc),
                        idx = as.integer(sub("^.*_([0-9]+)$", "\\1", sc)),
                        stringsAsFactors = FALSE)
    stems5 <- unique(sinfo$stem)
    message("Sales stems: ", paste(stems5, collapse = ", "))
    stxt <- vapply(stems5, function(s) {
      l <- rlabs[sinfo$col[sinfo$stem == s][1]]
      tolower(paste(s, ifelse(is.na(l), "", l)))
    }, character(1))
    names(stxt) <- stems5
    ps <- if ("add5_ppk" %in% stems5) "add5_ppk" else
      stems5[grepl("ppk|price", stems5) & !grepl("net|deduct", stems5)][1]
    if (is.na(ps)) stop("no price stem")
    K5 <- sort(unique(sinfo$idx[sinfo$stem == ps]))
    W <- stems5[grepl("kg|weigh|quantit", stxt) &
                  !grepl("ppk|price|bag|deduct|date|ugx|shs|money|revenue|value|transport|cost", stems5)]
    W <- W[vapply(W, function(s) !any(vapply(sinfo$col[sinfo$stem == s],
                                             function(cn) is_char(rd[[cn]]), logical(1))), logical(1))]
    measp <- "meas|enum|scale|weighed|our_|actual|verif|team|true|ra_"
    agrp  <- "agree|sold|trader|buyer|paid|deal|negot|claim|record|reported|said|contract"
    ys <- NA_character_; zs <- NA_character_
    c1 <- W[grepl(measp, stxt[W]) & !grepl(agrp, stxt[W])]
    if (length(c1)) ys <- c1[1] else if (any(grepl(measp, stxt[W]))) ys <- W[grepl(measp, stxt[W])][1]
    c2 <- setdiff(W[grepl(agrp, stxt[W]) & !grepl(measp, stxt[W])], ys)
    if (length(c2)) zs <- c2[1] else {
      c3 <- setdiff(W[grepl(agrp, stxt[W])], ys); if (length(c3)) zs <- c3[1]
    }
    sval <- function(s, k, conv = tonum) {
      cn <- paste0(s, "_", k)
      if (!is.na(s) && cn %in% names(rd)) conv(rd[[cn]]) else rep(NA_real_, nrow(rd))
    }
    stemmean <- function(s) mean(unlist(lapply(K5, function(k) sval(s, k))), na.rm = TRUE)
    stemn <- function(s) sum(!is.na(unlist(lapply(K5, function(k) sval(s, k)))))
    if ((is.na(ys) || is.na(zs)) && length(W) >= 2) {
      top <- W[order(-vapply(W, stemn, numeric(1)))][1:2]
      mm <- vapply(top, stemmean, numeric(1))
      ys <- top[which.max(mm)]; zs <- top[which.min(mm)]
    }
    dstem <- stems5[grepl("deduct", stems5)][1]
    dtst <- stems5[grepl("date|when|week|day", stems5)]
    datestem <- NA_character_
    if (length(dtst)) {
      isd <- vapply(dtst, function(s) inherits(rd[[sinfo$col[sinfo$stem == s][1]]], c("Date", "POSIXt")), logical(1))
      datestem <- if (any(isd)) dtst[isd][1] else dtst[1]
    }
    message("Sales: price=", ps, " measured=", ys, " agreed=", zs, " deduct=", dstem, " date=", datestem)

    sl <- do.call(rbind, lapply(K5, function(k) {
      y <- sval(ys, k); z <- sval(zs, k)
      if (!is.na(dstem)) {
        dd <- sval(dstem, k)
        if (all(is.na(z))) z <- y - dd
        if (all(is.na(y))) y <- z + dd
      }
      if (!is.na(datestem)) {
        cn <- paste0(datestem, "_", k)
        raw_d <- if (cn %in% names(rd)) rd[[cn]] else rep(NA_real_, nrow(rd))
        if (grepl("week", datestem) && !inherits(raw_d, c("Date", "POSIXt")) && !is_char(raw_d)) {
          wk <- as.character(tonum(raw_d))
        } else {
          dys <- to_days(raw_d)
          dts <- as.Date(dys, origin = "1970-01-01")
          wk <- ifelse(is.na(dts), NA_character_, paste(lubridate::isoyear(dts), lubridate::isoweek(dts), sep = "w"))
        }
      } else wk <- rep("1", nrow(rd))
      data.frame(hh = rd$hh_, vil = rd$vil_, treat = rd$treat_, price = sval(ps, k),
                 y = y, z = z, wk = wk, stringsAsFactors = FALSE)
    }))
    sl <- sl[!is.na(sl$price) & sl$price > 0 & !is.na(sl$treat), ]
    sl$ded <- ifelse(!is.na(sl$y) & sl$y > 0 & !is.na(sl$z), 100 * (sl$y - sl$z) / sl$y, NA)
    sl$netp <- ifelse(!is.na(sl$y) & sl$y > 0 & !is.na(sl$z), sl$price * sl$z / sl$y, NA)
    if (any(is.na(sl$wk))) sl$wk[is.na(sl$wk)] <- "missing"
    m3 <- fit(sl, "price", c("vil", "wk"), ~hh)
    print(summary(m3))
    put("treatment_price_table2_col3", coef(m3)["treat"])
    put("n_obs_table2_cols3_5_sales", nobs(m3))
    if (sum(!is.na(sl$ded)) > 5) {
      m4 <- fit(sl[!is.na(sl$ded), ], "ded", c("vil", "wk"), ~hh)
      print(summary(m4))
      put("treatment_deductions_table2_col4", coef(m4)["treat"])
      m5 <- fit(sl[!is.na(sl$netp), ], "netp", c("vil", "wk"), ~hh)
      print(summary(m5))
      put("treatment_net_price_table2_col5", coef(m5)["treat"])
    }
  }, error = function(e) message("Sales block failed: ", conditionMessage(e)))
}

# ======================================================== MARKET ACCESS (Table 6A)
tryCatch({
  p <- read_data("panel_g1.dta")
  hv <- c("hhh_id", "hh_id", "hhid", "hhh")[c("hhh_id", "hh_id", "hhid", "hhh") %in% names(p)][1]
  p$hh <- keychr(p[[hv]])
  vv <- find_vil(p)
  message("Panel village variable: ", vv)
  p$vil <- as.character(p[[vv]])
  p$season_num <- tonum(p$survey_season)
  p$season <- as.character(p$season_num)
  sidx <- match(p$season_num, sort(unique(p$season_num)))
  if ("season_post" %in% names(p) && all(na.omit(tonum(p$season_post)) %in% c(0, 1))) {
    p$post <- tonum(p$season_post) == 1
    p$post[is.na(p$post)] <- sidx[is.na(p$post)] >= 4
  } else p$post <- sidx >= 4

  # treatment indicator (village-level)
  tcands <- grep("treat", names(p), value = TRUE)
  tvar <- NA_character_
  for (cn in tcands) {
    v <- tonum(p[[cn]])
    if (sum(!is.na(v)) > 0.8 * nrow(p) && all(na.omit(v) %in% c(0, 1)) && length(unique(na.omit(v))) == 2) {
      within <- tapply(v, p$vil, function(z) length(unique(na.omit(z))))
      if (all(within <= 1, na.rm = TRUE)) { tvar <- cn; break }
    }
  }
  if (!is.na(tvar)) {
    p$treat <- tonum(p[[tvar]])
    vt <- tapply(p$treat, p$vil, function(z) max(z, na.rm = TRUE))
    p$treat <- as.numeric(vt[p$vil])
  } else {
    tv <- character(0)
    for (f in c("buy_data.dta", "seller_data.dta")) {
      x <- tryCatch(read_data(f), error = function(e) NULL)
      if (!is.null(x) && all(c("ea_code", "buy_treatment") %in% names(x)))
        tv <- c(tv, as.character(x$ea_code[tonum(x$buy_treatment) == 1 & !is.na(x$buy_treatment)]))
    }
    p$treat <- as.numeric(p$vil %in% unique(tv))
  }
  message("Treatment variable: ", tvar, "; treated villages: ",
          length(unique(p$vil[p$treat == 1])), " of ", length(unique(p$vil)))

  # exchange rate
  fx <- 3700
  fxc <- grep("exch|fx|xrate|usd_rate|rate_usd|ugx_usd", names(p), value = TRUE)
  for (cn in fxc) {
    v <- tonum(p[[cn]]); md <- suppressWarnings(median(v, na.rm = TRUE))
    if (!is.na(md) && md > 2000 && md < 5000) { p$fx <- ifelse(is.na(v), md, v); break }
  }
  if (is.null(p$fx)) p$fx <- fx

  # ---- price (UGX/kg)
  pnames <- c("price", "price_kg", "avg_price", "price_avg", "mean_price", "price_per_kg", "ppk",
              "price_kg_avg", "sale_price", "price_ugx")
  pp <- intersect(pnames, names(p))
  price_ugx <- NULL
  if (length(pp)) {
    v <- tonum(p[[pp[1]]]); v[!is.na(v) & v <= 0] <- NA
    md <- median(v, na.rm = TRUE)
    price_ugx <- if (!is.na(md) && md < 5) v * p$fx else v
    message("Price from panel variable ", pp[1])
  }
  if (is.null(price_ugx)) {
    revc <- grep("^revenue|rev_tot|revenue_tot|sales_value|sale_value|tot_rev|revenue", names(p), value = TRUE)
    revc <- revc[!grepl("_[0-9]+$", revc)]
    if (length(revc) && "sold_kg_tot" %in% names(p)) {
      r <- tonum(p[[revc[1]]]); s <- tonum(p$sold_kg_tot)
      price_ugx <- ifelse(!is.na(s) & s > 0 & !is.na(r) & r > 0, r / s, NA)
      message("Price = ", revc[1], " / sold_kg_tot")
    }
  }
  if (is.null(price_ugx) || all(is.na(price_ugx))) {
    sd <- read_data("seller_data.dta")
    sd$hh <- keychr(sd$hhh_id)
    sd$season <- as.character(tonum(sd$survey_season))
    sd$pr <- tonum(sd$price); sd$kg <- tonum(sd$sold_kg_p_)
    agg <- sd %>% filter(!is.na(pr), pr > 0) %>% group_by(hh, season) %>%
      summarise(pw = if (sum(!is.na(kg) & kg > 0) > 0)
                  sum((pr * kg)[!is.na(kg) & kg > 0]) / sum(kg[!is.na(kg) & kg > 0]) else mean(pr),
                .groups = "drop")
    p <- p %>% left_join(agg, by = c("hh", "season"))
    price_ugx <- p$pw
    md <- median(price_ugx, na.rm = TRUE)
    if (!is.na(md) && md < 5) price_ugx <- price_ugx * p$fx
    message("Price from seller_data (weighted by kg)")
  }
  p$price_ugx <- price_ugx
  p$price_usd <- p$price_ugx / p$fx

  # ---- harvest and area
  hk <- if ("harvest_kg_tot" %in% names(p)) "harvest_kg_tot" else grep("harvest_kg", names(p), value = TRUE)[1]
  p$harvest <- tonum(p[[hk]])
  acre_c <- names(p)[grepl("acre|area", names(p)) &
                       !grepl("cost|price|dist|share|pct|unit|_min", names(p))]
  acre_c <- acre_c[vapply(acre_c, function(cn) !is_char(p[[cn]]), logical(1))]
  area <- NULL
  tot_a <- acre_c[grepl("tot", acre_c) & !grepl("_[0-9]+$", acre_c)]
  single_a <- acre_c[!grepl("_[0-9]+$", acre_c)]
  if (length(tot_a)) { area <- tonum(p[[tot_a[1]]]); message("Area var: ", tot_a[1]) } else
    if (length(single_a)) { area <- tonum(p[[single_a[1]]]); message("Area var: ", single_a[1]) }
  if (is.null(area) || all(is.na(area))) {
    psz <- grep("^plot_size_[0-9]+$", names(p), value = TRUE)
    if (!length(psz)) psz <- acre_c[grepl("_[0-9]+$", acre_c)]
    m <- sapply(psz, function(cn) tonum(p[[cn]]))
    if (is.null(dim(m))) m <- matrix(m, ncol = 1)
    area <- rowSums(m, na.rm = TRUE); area[rowSums(!is.na(m)) == 0] <- NA
    message("Area = sum of ", paste(psz, collapse = ", "))
  }
  yv <- grep("^yield", names(p), value = TRUE)
  yv <- yv[!grepl("_[0-9]+$", yv)]
  if (length(yv)) {
    p$yield <- tonum(p[[yv[1]]]); message("Yield var: ", yv[1])
  } else {
    p$yield <- ifelse(!is.na(area) & area > 0, p$harvest / area, NA)
  }

  # ---- harvest value at community-specific market price
  cp <- p %>% group_by(vil, season) %>% summarise(cpv = median(price_ugx, na.rm = TRUE), .groups = "drop")
  sp <- p %>% group_by(season) %>% summarise(cps = median(price_ugx, na.rm = TRUE), .groups = "drop")
  p <- p %>% left_join(cp, by = c("vil", "season")) %>% left_join(sp, by = "season")
  p$comm_price <- ifelse(is.na(p$cpv), p$cps, p$cpv)
  p$comm_price[is.na(p$comm_price)] <- median(p$price_ugx, na.rm = TRUE)
  p$hv_ugx <- p$harvest * p$comm_price
  p$harvest_value <- p$hv_ugx / p$fx

  # ---- monetary expenses
  cc <- names(p)[grepl("cost|expens|_paid|payment", names(p)) &
                   !grepl("tot|_ps$|own|fam|opportun|value|price|share|pct|per_|_per", names(p))]
  cc <- cc[vapply(cc, function(cn) !is_char(p[[cn]]), logical(1))]
  message("Cost columns: ", paste(cc, collapse = ", "))
  if (length(cc)) {
    cm <- sapply(cc, function(cn) tonum(p[[cn]]))
    if (is.null(dim(cm))) cm <- matrix(cm, ncol = 1)
    cost_ugx <- rowSums(cm, na.rm = TRUE)
  } else cost_ugx <- 0
  p$profit_mon <- (p$hv_ugx - cost_ugx) / p$fx

  # ---- own labour
  hc <- names(p)[grepl("hour|hrs", names(p)) &
                   !grepl("cost|wage|pay|price|dist|_min|min_|travel|walk", names(p))]
  hc <- hc[vapply(hc, function(cn) !is_char(p[[cn]]), logical(1))]
  hc <- hc[!vapply(hc, function(cn) {
    v <- tonum(p[[cn]]); v <- v[!is.na(v)]
    grepl("unit", cn) && length(v) > 0 && all(v %in% 1:6) && max(v) <= 6 && length(unique(v)) <= 6 &&
      FALSE
  }, logical(1))]
  own <- hc[grepl("fam|own|^fl_|^lf_|household|^hhl", hc)]
  if (!length(own)) own <- hc[!grepl("hire|hired|paid|^hl_", hc)]
  message("Own-labour hour columns: ", paste(own, collapse = ", "))
  if (length(own)) {
    hm <- sapply(own, function(cn) tonum(p[[cn]]))
    if (is.null(dim(hm))) hm <- matrix(hm, ncol = 1)
    own_hours <- rowSums(hm, na.rm = TRUE)
  } else own_hours <- 0
  wage_h <- 5000 / 8
  wc <- grep("wage", names(p), value = TRUE)
  wc <- wc[vapply(wc, function(cn) !is_char(p[[cn]]), logical(1))]
  if (length(wc)) {
    wv <- unlist(lapply(wc, function(cn) tonum(p[[cn]]))); wv <- wv[!is.na(wv) & wv > 0]
    if (length(wv)) { mw <- median(wv); wage_h <- if (mw > 2000) mw / 8 else mw }
  }
  message("Hourly wage (UGX): ", wage_h)
  p$profit_own <- p$profit_mon - own_hours * wage_h / p$fx

  # ---- ANCOVA
  ancova <- function(df, yv) {
    d <- data.frame(hh = df$hh, vil = df$vil, treat = df$treat, season = df$season,
                    post = df$post, y = df[[yv]], stringsAsFactors = FALSE)
    d$y[!is.finite(d$y)] <- NA
    b <- d %>% filter(!post) %>% group_by(hh) %>%
      summarise(b = if (all(is.na(y))) NA_real_ else mean(y, na.rm = TRUE), .groups = "drop")
    f <- d %>% filter(post, !is.na(y), !is.na(treat)) %>% left_join(b, by = "hh")
    f$bmiss <- as.numeric(is.na(f$b))
    f$b[is.na(f$b)] <- if (any(!is.na(f$b))) mean(f$b, na.rm = TRUE) else 0
    fml <- if (length(unique(f$bmiss)) > 1) y ~ treat + b + bmiss | season else y ~ treat + b | season
    feols(fml, data = f, cluster = ~vil)
  }
  run6 <- function(name, var, nname = NULL) {
    tryCatch({
      m <- ancova(p, var)
      print(summary(m))
      put(name, coef(m)["treat"])
      if (!is.null(nname)) put(nname, nobs(m))
    }, error = function(e) message("ANCOVA ", var, " failed: ", conditionMessage(e)))
  }
  run6("market_access_price_table6_panelA_col1", "price_usd")
  run6("market_access_yield_table6_panelA_col4", "yield")
  run6("market_access_harvest_value_table6_panelA_col5", "harvest_value")
  run6("market_access_profit_monetary_table6_panelA_col7", "profit_mon")
  run6("market_access_profit_incl_own_hours_table6_panelA_col8", "profit_own")
  tryCatch({
    mh <- ancova(p, "harvest")
    put("n_obs_table6_panelA_cols3_5", nobs(mh))
  }, error = function(e) message("Harvest ANCOVA failed: ", conditionMessage(e)))
}, error = function(e) message("Market access block failed: ", conditionMessage(e)))

# ======================================================== OUTPUT
for (nm in result_names) {
  v <- results[[nm]]
  cat(sprintf("RESULT:%s=%s\n", nm, if (is.na(v)) "NA" else format(v, digits = 10, scientific = FALSE)))
}
