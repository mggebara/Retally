suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(2)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_ur   <- file.path(base, "v2unemp_smy.csv")
f_cpi  <- file.path(base, "wage_deflation_1994_2016.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")

# results are initialised to NA and always printed at the end, even if a step fails
res <- list(
  young_x_unemp_rate_no_controls = NA_real_,
  experienced_x_unemp_rate_no_controls = NA_real_,
  young_x_unemp_rate_preferred = NA_real_,
  experienced_x_unemp_rate_preferred = NA_real_,
  aggregate_unemp_rate_no_controls = NA_real_,
  aggregate_unemp_rate_month_year_fe = NA_real_,
  young_x_unemp_rate_employed = NA_real_,
  experienced_x_unemp_rate_employed = NA_real_,
  young_x_unemp_rate_unemployed = NA_real_,
  young_x_unemp_rate_nilf = NA_real_,
  wage_young_x_unemp_rate_all_hires = NA_real_,
  wage_experienced_x_unemp_rate_all_hires = NA_real_,
  n_obs_full_sample = NA_real_
)
fmt <- function(x) format(x, digits = 10, scientific = FALSE)
print_results <- function() {
  for (k in names(res)) cat(sprintf("RESULT:%s=%s\n", k, fmt(res[[k]])))
}

num <- function(x) suppressWarnings(as.numeric(x))

map_mlr <- function(x) {
  if (is.numeric(x)) return(x)
  y <- num(x)
  if (mean(is.na(y)) < 0.5) return(y)
  s <- tolower(as.character(x)); out <- rep(NA_real_, length(s))
  out[grepl("at work", s)] <- 1
  out[grepl("absent", s)] <- 2
  out[grepl("layoff", s)] <- 3
  out[grepl("looking", s)] <- 4
  out[grepl("retired", s)] <- 5
  out[grepl("disab", s)] <- 6
  out[grepl("other", s) & is.na(out)] <- 7
  out
}

map_educ <- function(x) {
  if (is.numeric(x)) return(x)
  y <- num(x)
  if (mean(is.na(y)) < 0.5) return(y)
  s <- tolower(as.character(x)); out <- rep(NA_real_, length(s))
  setv <- function(pat, v) { i <- is.na(out) & grepl(pat, s); out[i] <<- v }
  setv("less than", 31)
  setv("12th", 38)
  setv("11th", 37)
  setv("10th", 36)
  setv("9th", 35)
  setv("7th|8th", 34)
  setv("5th|6th", 33)
  setv("1st|2nd|3rd|4th", 32)
  setv("high school", 39)
  setv("some college", 40)
  setv("vocational|occupational", 41)
  setv("academic", 42)
  setv("bachelor", 43)
  setv("master", 44)
  setv("professional", 45)
  setv("doctor", 46)
  out
}

tryCatch({
  hdr <- names(fread(f_main, nrows = 0))
  hdr_l <- tolower(hdr)
  cat("Columns in main file:", paste(hdr, collapse = ","), "\n")

  pick <- function(cands) {
    for (c in cands) { i <- which(hdr_l == tolower(c)); if (length(i)) return(hdr[i[1]]) }
    NA_character_
  }

  wanted <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pemlr","pwsswgt",
              "v2hrmonth","v2hryear","v2gestfips","v2pemlr","v2puiodp1","v2peio1cow",
              "v2peio1icd","v2peio1ocd","v2pwsswgt","v2peage","hrmis","v2hrmis",
              "v2unemp_smy","v2occ_codeyear","v2ind_codeyear")
  earn_col  <- pick(c("v2prernwa","v2pternwa","v2ernwa","v2prernwa_r","v2weekly_earn"))
  alloc_col <- pick(c("v2prwernal","v2pthwernal","v2prhernal","v2pternal"))
  if (is.na(earn_col)) {
    g <- hdr[grepl("^v2.*ernwa", hdr_l)]; if (length(g)) earn_col <- g[1]
  }
  if (is.na(alloc_col)) {
    g <- hdr[grepl("^v2.*wernal", hdr_l)]; if (length(g)) alloc_col <- g[1]
  }
  sel <- unique(c(hdr[hdr_l %in% wanted], na.omit(c(earn_col, alloc_col))))
  cat("Selected:", paste(sel, collapse = ","), "\n")

  dt <- fread(f_main, select = sel, showProgress = FALSE)
  setnames(dt, tolower(names(dt)))
  if (!is.na(earn_col)) earn_col <- tolower(earn_col)
  if (!is.na(alloc_col)) alloc_col <- tolower(alloc_col)
  cat("Rows read:", nrow(dt), "\n")

  # ---- memory-light early restrictions: timing first ----
  for (v in c("hrmonth","hryear","v2hrmonth","v2hryear"))
    if (v %in% names(dt) && !is.numeric(dt[[v]])) set(dt, j = v, value = num(dt[[v]]))
  dt <- dt[!is.na(hryear) & !is.na(v2hryear) &
           ((v2hryear * 12 + v2hrmonth) - (hryear * 12 + hrmonth)) == 1 &
           (v2hryear * 12 + v2hrmonth) >= 1994 * 12 + 1 &
           (v2hryear * 12 + v2hrmonth) <= 2016 * 12 + 9 &
           !(hryear == 1995 & hrmonth %in% 5:8) & !(v2hryear == 1995 & v2hrmonth %in% 5:8)]
  invisible(gc())
  cat("Rows after timing restrictions:", nrow(dt), "\n")

  # ---- age / education ----
  if (!is.numeric(dt$peage)) dt[, peage := num(peage)]
  dt[, peeduca := map_educ(peeduca)]
  dt <- dt[!is.na(peage) & !is.na(peeduca) & peeduca >= 31 & peeduca <= 46 & peage >= 16]
  invisible(gc())

  # ---- labour force status ----
  dt[, pemlr := map_mlr(pemlr)]
  dt[, v2pemlr := map_mlr(v2pemlr)]
  dt <- dt[pemlr %in% 1:7 & v2pemlr %in% 1:7]
  if ("v2hrmis" %in% names(dt)) dt <- dt[!(num(v2hrmis) %in% 5)]
  invisible(gc())
  cat("Rows after restrictions:", nrow(dt), "\n")

  if ("v2puiodp1" %in% names(dt)) {
    x <- dt$v2puiodp1
    if (!is.numeric(x)) {
      y <- num(x)
      if (mean(is.na(y)) > 0.9) { s <- tolower(as.character(x)); y <- ifelse(grepl("^y", s), 1, ifelse(grepl("^n", s), 2, NA)) }
      x <- y
    }
    dt[, sameemp := x]
    dt[, v2puiodp1 := NULL]
    rm(x)
  } else dt[, sameemp := NA_real_]

  if ("v2peio1cow" %in% names(dt)) {
    x <- dt$v2peio1cow
    if (is.numeric(x)) {
      dt[, selfemp := x %in% c(6, 7)]
    } else {
      y <- num(x)
      if (mean(is.na(y)) < 0.9) {
        dt[, selfemp := y %in% c(6, 7)]
      } else {
        dt[, selfemp := grepl("self", tolower(as.character(x)))]
      }
    }
    dt[, v2peio1cow := NULL]
    rm(x)
  } else dt[, selfemp := FALSE]
  invisible(gc())

  for (v in c("v2gestfips","pwsswgt","v2pwsswgt"))
    if (v %in% names(dt) && !is.numeric(dt[[v]])) set(dt, j = v, value = num(dt[[v]]))

  dt[, t1 := v2hryear * 12 + v2hrmonth]

  # ---- hire indicator ----
  dt[, hired := 0]
  dt[pemlr %in% 3:7 & v2pemlr %in% 1:2 & !selfemp, hired := 100]
  dt[pemlr %in% 1:2 & v2pemlr %in% 1:2 & sameemp %in% 2 & !selfemp, hired := 100]

  # ---- potential experience & demographics ----
  edyrs <- c(`31`=0,`32`=2.5,`33`=5.5,`34`=7.5,`35`=9,`36`=10,`37`=11,`38`=11,`39`=12,
             `40`=13,`41`=14,`42`=14,`43`=16,`44`=18,`45`=20,`46`=21)
  dt[, educ_yrs := unname(edyrs[as.character(peeduca)])]
  dt[, pe := peage - educ_yrs - 6]
  dt[, young := as.integer(pe <= 10)]
  dt[, ed7 := fifelse(peeduca <= 38, 1L, fifelse(peeduca == 39, 2L, fifelse(peeduca <= 42, 3L,
              fifelse(peeduca == 43, 4L, fifelse(peeduca == 44, 5L, fifelse(peeduca == 45, 6L, 7L))))))]
  if (is.numeric(dt$race)) dt[, white := as.integer(race == 1)] else
    dt[, white := as.integer(grepl("^white", tolower(as.character(race))))]
  if ("prhspnon" %in% names(dt)) {
    if (is.numeric(dt$prhspnon)) dt[, hisp := as.integer(prhspnon == 1)] else
      dt[, hisp := as.integer(grepl("^hisp", tolower(as.character(prhspnon))))]
  } else dt[, hisp := 0L]
  dt[, demo := as.integer(factor(paste(pesex, white, hisp, ed7, sep = "_")))]
  drop_cols <- intersect(c("race","prhspnon","pesex","educ_yrs"), names(dt))
  if (length(drop_cols)) dt[, (drop_cols) := NULL]
  dt[, ym := t1]
  dt[, state := v2gestfips]

  # ---- weights ----
  if ("v2pwsswgt" %in% names(dt)) dt[, w := (pwsswgt + v2pwsswgt) / 2] else dt[, w := pwsswgt]
  dt <- dt[!is.na(w) & w > 0]
  invisible(gc())

  # ---- state unemployment rate ----
  if (!("v2unemp_smy" %in% names(dt))) {
    ur <- fread(f_ur)
    setnames(ur, tolower(names(ur)))
    nm <- names(ur)
    fcol <- if ("v2gestfips" %in% nm) "v2gestfips" else nm[grepl("fips", nm)][1]
    ycol <- if ("v2hryear" %in% nm) "v2hryear" else nm[grepl("year", nm)][1]
    mcol <- if ("v2hrmonth" %in% nm) "v2hrmonth" else nm[grepl("month", nm)][1]
    ucol <- if ("v2unemp_smy" %in% nm) "v2unemp_smy" else nm[grepl("unemp|ur", nm)][1]
    ur <- data.table(v2gestfips = num(ur[[fcol]]), v2hryear = num(ur[[ycol]]),
                     v2hrmonth = num(ur[[mcol]]), v2unemp_smy = num(ur[[ucol]]))
    ur <- unique(ur, by = c("v2gestfips","v2hryear","v2hrmonth"))
    setkeyv(ur, c("v2gestfips","v2hryear","v2hrmonth"))
    dt[ur, v2unemp_smy := i.v2unemp_smy, on = c("v2gestfips","v2hryear","v2hrmonth")]
    rm(ur)
  } else dt[, v2unemp_smy := num(v2unemp_smy)]
  if (max(dt$v2unemp_smy, na.rm = TRUE) < 1) dt[, v2unemp_smy := 100 * v2unemp_smy]
  dt <- dt[!is.na(v2unemp_smy) & !is.na(pe) & !is.na(state)]
  dt[, ur := v2unemp_smy]
  dt[, ur_y := ur * young]
  dt[, ur_e := ur * (1 - young)]
  invisible(gc())
  cat("Final N:", nrow(dt), " mean hired:", weighted.mean(dt$hired, dt$w), "\n")

  getc <- function(m, v) {
    if (is.null(m)) return(NA_real_)
    cc <- coef(m); if (v %in% names(cc)) unname(cc[v]) else NA_real_
  }
  run <- function(fml, data) {
    tryCatch(feols(fml, data = data, weights = ~w, cluster = ~state, lean = TRUE, mem.clean = TRUE),
             error = function(e) { cat("Regression error:", conditionMessage(e), "\n"); NULL })
  }

  mA1 <- run(hired ~ ur, dt)
  res$aggregate_unemp_rate_no_controls <- getc(mA1, "ur")
  res$n_obs_full_sample <- if (!is.null(mA1)) nobs(mA1) else nrow(dt)
  rm(mA1); invisible(gc())
  mA4 <- run(hired ~ ur | state + demo + ym, dt)
  res$aggregate_unemp_rate_month_year_fe <- getc(mA4, "ur"); rm(mA4); invisible(gc())

  mB1 <- run(hired ~ young + ur_y + ur_e, dt)
  res$young_x_unemp_rate_no_controls <- getc(mB1, "ur_y")
  res$experienced_x_unemp_rate_no_controls <- getc(mB1, "ur_e"); rm(mB1); invisible(gc())
  mB4 <- run(hired ~ young + ur_y + ur_e | state + demo + ym, dt)
  res$young_x_unemp_rate_preferred <- getc(mB4, "ur_y")
  res$experienced_x_unemp_rate_preferred <- getc(mB4, "ur_e")
  if (!is.null(mB4)) print(summary(mB4))
  rm(mB4); invisible(gc())

  mE <- run(hired ~ young + ur_y + ur_e | state + demo + ym, dt[pemlr %in% 1:2])
  res$young_x_unemp_rate_employed <- getc(mE, "ur_y")
  res$experienced_x_unemp_rate_employed <- getc(mE, "ur_e"); rm(mE); invisible(gc())
  mU <- run(hired ~ young + ur_y + ur_e | state + demo + ym, dt[pemlr %in% 3:4])
  res$young_x_unemp_rate_unemployed <- getc(mU, "ur_y"); rm(mU); invisible(gc())
  mN <- run(hired ~ young + ur_y + ur_e | state + demo + ym, dt[pemlr %in% 5:7])
  res$young_x_unemp_rate_nilf <- getc(mN, "ur_y"); rm(mN); invisible(gc())

  # ---- wages of new hires ----
  tryCatch({
    if (is.na(earn_col)) stop("no earnings column found")
    h <- dt[hired == 100]
    rm(dt); invisible(gc())
    h[, earn := num(get(earn_col))]
    if ("v2hrmis" %in% names(h)) h <- h[num(v2hrmis) %in% c(4, 8)]
    if (!is.na(alloc_col)) h <- h[!(num(get(alloc_col)) %in% 1)]
    h <- h[!is.na(earn) & earn > 0]
    cpi <- fread(f_cpi); setnames(cpi, tolower(names(cpi)))
    cpi[, `:=`(year = num(year), month = num(month), cpi = num(cpi))]
    c94 <- mean(cpi[year == 1994, cpi])
    h <- merge(h, cpi[, .(v2hryear = year, v2hrmonth = month, cpi)], by = c("v2hryear","v2hrmonth"))
    h[, lw := log(earn * c94 / cpi)]

    vint_occ <- function(y) fifelse(y < 2003, 1L, fifelse(y < 2011, 2L, 3L))
    vint_ind <- function(y) fifelse(y < 2003, 1L, fifelse(y < 2009, 2L, fifelse(y < 2014, 3L, 4L)))
    h[, occ_raw := num(v2peio1ocd)]; h[, ind_raw := num(v2peio1icd)]
    ox <- fread(f_occ); setnames(ox, tolower(names(ox)))
    ix <- fread(f_ind); setnames(ix, tolower(names(ix)))
    assign_cy <- function(y, U, vfun, nper) {
      U <- sort(unique(U))
      if (length(U) == nper) U[vfun(y)] else sapply(y, function(z) { k <- U[U <= z]; if (length(k)) max(k) else min(U) })
    }
    if ("v2occ_codeyear" %in% names(h)) h[, ocy := num(v2occ_codeyear)] else
      h[, ocy := assign_cy(v2hryear, num(ox$v2occ_codeyear), vint_occ, 3)]
    if ("v2ind_codeyear" %in% names(h)) h[, icy := num(v2ind_codeyear)] else
      h[, icy := assign_cy(v2hryear, num(ix$v2ind_codeyear), vint_ind, 4)]
    ox2 <- unique(ox[, .(occ_raw = num(v2peio1ocd), ocy = num(v2occ_codeyear), occ02 = v2censusocc_2002recode)],
                  by = c("occ_raw","ocy"))
    ix2 <- unique(ix[, .(ind_raw = num(v2peio1icd), icy = num(v2ind_codeyear), ind02 = v2censusind_2002recode)],
                  by = c("ind_raw","icy"))
    h <- merge(h, ox2, by = c("occ_raw","ocy"), all.x = TRUE)
    h <- merge(h, ix2, by = c("ind_raw","icy"), all.x = TRUE)
    cat("Occ match rate:", mean(!is.na(h$occ02)), " Ind match rate:", mean(!is.na(h$ind02)), "\n")
    if (mean(!is.na(h$occ02)) < 0.5) h[, occ02 := paste(vint_occ(v2hryear), occ_raw)]
    if (mean(!is.na(h$ind02)) < 0.5) h[, ind02 := paste(vint_ind(v2hryear), ind_raw)]
    h <- h[!is.na(occ02) & !is.na(ind02) & !is.na(lw)]
    cat("Wage sample N:", nrow(h), "\n")
    mW <- feols(lw ~ young + ur_y + ur_e | state + ym + occ02 + ind02 + demo, data = h,
                weights = ~w, cluster = ~state)
    print(summary(mW))
    res$wage_young_x_unemp_rate_all_hires <- getc(mW, "ur_y")
    res$wage_experienced_x_unemp_rate_all_hires <- getc(mW, "ur_e")
  }, error = function(e) cat("Wage regression error:", conditionMessage(e), "\n"))
}, error = function(e) cat("Pipeline error:", conditionMessage(e), "\n"))

print_results()
