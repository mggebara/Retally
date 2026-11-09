suppressPackageStartupMessages({
  library(data.table)
  library(fixest)
})
set.seed(42)
setFixest_nthreads(0)

base <- "<repo>/.cache/datasets/forsythe_2022_young_workers_recessions.script-free/3 replication package/Data"
f_main <- file.path(base, "yh_data.csv")
f_un   <- file.path(base, "v2unemp_smy.csv")
f_def  <- file.path(base, "wage_deflation_1994_2016.csv")
f_ind  <- file.path(base, "ind_xwalk2002.csv")
f_occ  <- file.path(base, "occ_xwalk2002.csv")

res_names <- c("young_x_unemp_rate_no_controls", "experienced_x_unemp_rate_no_controls",
               "young_x_unemp_rate_preferred", "experienced_x_unemp_rate_preferred",
               "aggregate_unemp_rate_no_controls", "aggregate_unemp_rate_month_year_fe",
               "young_x_unemp_rate_employed", "experienced_x_unemp_rate_employed",
               "young_x_unemp_rate_unemployed", "young_x_unemp_rate_nilf",
               "wage_young_x_unemp_rate_all_hires", "wage_experienced_x_unemp_rate_all_hires",
               "n_obs_full_sample")
RES <- setNames(as.list(rep(NA_real_, length(res_names))), res_names)

print_results <- function() {
  for (nm in res_names) {
    v <- RES[[nm]]
    if (nm == "n_obs_full_sample") {
      cat(sprintf("RESULT:%s=%s\n", nm, if (is.na(v)) "NA" else as.character(as.integer(v))))
    } else {
      cat(sprintf("RESULT:%s=%s\n", nm, if (is.na(v)) "NA" else sprintf("%.6f", v)))
    }
  }
  flush.console()
}

getc <- function(m, nm) {
  v <- tryCatch(unname(coef(m)[nm]), error = function(e) NA_real_)
  if (is.null(v) || length(v) == 0) NA_real_ else as.numeric(v)
}

to_num <- function(d) {
  for (v in names(d)) if (!is.numeric(d[[v]])) suppressWarnings(set(d, j = v, value = as.numeric(d[[v]])))
  invisible(d)
}

fix_year <- function(y) {
  y <- as.integer(y)
  fifelse(!is.na(y) & y < 50L, y + 2000L, fifelse(!is.na(y) & y < 100L, y + 1900L, y))
}

dt <- NULL
prep_ok <- tryCatch({
  hdr <- names(fread(f_main, nrows = 0))
  cat("Columns in yh_data.csv:\n"); print(hdr)

  cand <- c("hrmonth","hryear","peage","pesex","peeduca","race","prhspnon","pehspnon","pemlr",
            "pwsswgt","v2pwsswgt","v2hrmonth","v2hryear","v2gestfips",
            "v2pemlr","v2puiodp1","v2peio1cow","v2peio1icd","v2peio1ocd",
            "hrmis","v2hrmis","v2unemp_smy","v2prernwa","v2prwernal","prpertyp","peafnow")
  sel <- intersect(cand, hdr)
  dt <- fread(f_main, select = sel, showProgress = FALSE)
  cat("Rows read:", nrow(dt), "\n"); flush.console()
  to_num(dt)
  if (!("prhspnon" %in% names(dt)) && "pehspnon" %in% names(dt)) setnames(dt, "pehspnon", "prhspnon")
  if ("pehspnon" %in% names(dt)) dt[, pehspnon := NULL]

  ## ---- normalise 2-digit years (file mixes e.g. 94 and 2005) ----
  dt[, hryear := fix_year(hryear)]
  dt[, v2hryear := fix_year(v2hryear)]
  cat("Year range (v2hryear):", range(dt$v2hryear, na.rm = TRUE), "\n"); flush.console()

  ## ---- sample restrictions ----
  dt <- dt[!is.na(peage) & peage >= 16 & !is.na(peeduca) & peeduca > 0 &
             pemlr %in% 1:7 & v2pemlr %in% 1:7 &
             !(v2hryear == 1995 & v2hrmonth %in% 5:8) &
             !(hryear == 1995 & hrmonth %in% 5:8) &
             (v2hryear * 100 + v2hrmonth) >= 199401 & (v2hryear * 100 + v2hrmonth) <= 201609]
  gc()
  if ("peafnow" %in% names(dt)) { dt <- dt[is.na(peafnow) | peafnow != 1]; dt[, peafnow := NULL] }
  if ("prpertyp" %in% names(dt)) { dt <- dt[is.na(prpertyp) | prpertyp == 2]; dt[, prpertyp := NULL] }
  if ("hrmis" %in% names(dt)) { dt <- dt[is.na(hrmis) | hrmis != 4]; dt[, hrmis := NULL] }
  if ("v2hrmis" %in% names(dt)) dt <- dt[is.na(v2hrmis) | v2hrmis != 5]
  dt[, c("hryear","hrmonth") := NULL]
  gc()
  cat("Rows after restrictions:", nrow(dt), "\n"); flush.console()

  ## ---- state unemployment rate (update join, no copy) ----
  if (!("v2unemp_smy" %in% names(dt))) {
    un <- fread(f_un)
    to_num(un)
    setnames(un, tolower(names(un)))
    ren <- function(from, to) { f <- intersect(from, names(un)); if (length(f) && !(to %in% names(un))) setnames(un, f[1], to) }
    ren(c("gestfips","statefips","state_fips","fips","state","stfips"), "v2gestfips")
    ren(c("hryear","year","yr"), "v2hryear")
    ren(c("hrmonth","month","mo"), "v2hrmonth")
    if (!("v2unemp_smy" %in% names(un))) {
      uc <- setdiff(grep("unemp|urate|ur", names(un), value = TRUE), c("v2gestfips","v2hryear","v2hrmonth"))
      if (length(uc)) setnames(un, uc[1], "v2unemp_smy")
    }
    un <- un[, .(v2gestfips = as.integer(v2gestfips), v2hryear = fix_year(v2hryear),
                 v2hrmonth = as.integer(v2hrmonth), v2unemp_smy = as.numeric(v2unemp_smy))]
    un <- unique(un, by = c("v2gestfips","v2hryear","v2hrmonth"))
    dt[, v2gestfips := as.integer(v2gestfips)]
    dt[, v2hrmonth := as.integer(v2hrmonth)]
    dt[, v2unemp_smy := NA_real_]
    dt[un, v2unemp_smy := i.v2unemp_smy, on = c("v2gestfips","v2hryear","v2hrmonth")]
    rm(un); gc()
  }
  if (max(dt$v2unemp_smy, na.rm = TRUE) < 1) dt[, v2unemp_smy := 100 * v2unemp_smy]
  dt <- dt[!is.na(v2unemp_smy) & !is.na(v2gestfips)]
  setnames(dt, "v2unemp_smy", "urate")
  gc()
  cat("Rows after unemployment merge:", nrow(dt), "\n"); flush.console()

  ## ---- potential experience ----
  educ_vec <- c(0, 2.5, 5.5, 7.5, 9, 10, 11, 12, 12, 13, 14, 14, 16, 18, 18, 20)  # codes 31..46
  dt[, eyrs := {
    k <- as.integer(peeduca) - 30L
    out <- rep(NA_real_, .N)
    ok <- !is.na(k) & k >= 1L & k <= 16L
    out[ok] <- educ_vec[k[ok]]
    out
  }]
  dt <- dt[!is.na(eyrs)]
  gc()
  dt[, young := as.integer((peage - eyrs - 6) <= 10)]
  dt[, young_U := young * urate]
  dt[, exp_U := (1 - young) * urate]
  cat("Experience built\n"); flush.console()

  ## ---- demographic FE ----
  dt[, educ7 := fcase(peeduca <= 38, 1L, peeduca == 39, 2L, peeduca %in% 40:42, 3L,
                      peeduca == 43, 4L, peeduca == 44, 5L, peeduca == 45, 6L, peeduca == 46, 7L)]
  dt[, demo := as.integer(pesex * 1000 + as.integer(!is.na(race) & race == 1) * 100 +
                            as.integer(!is.na(prhspnon) & prhspnon == 1) * 10 + educ7)]
  dt[, ym := as.integer(v2hryear * 100L + v2hrmonth)]
  dt[, state := v2gestfips]

  ## ---- weights ----
  if ("v2pwsswgt" %in% names(dt)) {
    dt[, w := fifelse(is.na(v2pwsswgt), pwsswgt,
                      fifelse(is.na(pwsswgt), v2pwsswgt, (pwsswgt + v2pwsswgt) / 2))]
  } else dt[, w := pwsswgt]
  dt <- dt[!is.na(w) & w > 0]
  gc()

  ## ---- hire indicator ----
  has_cow <- "v2peio1cow" %in% names(dt)
  has_iodp <- "v2puiodp1" %in% names(dt)
  dt[, hired := 100 * as.numeric((v2pemlr %in% 1:2) &
                                   !(if (has_cow) (v2peio1cow %in% 6:7) else FALSE) &
                                   (!(pemlr %in% 1:2) |
                                      (if (has_iodp) (!is.na(v2puiodp1) & v2puiodp1 == 2) else FALSE)))]
  dt[, lfs_prev := fcase(pemlr %in% 1:2, 1L, pemlr %in% 3:4, 2L, pemlr %in% 5:7, 3L)]
  drop_cols <- intersect(c("pwsswgt","v2pwsswgt","eyrs","race","prhspnon","educ7",
                           "pesex","peage","pemlr","v2pemlr","v2puiodp1","v2peio1cow","peeduca"), names(dt))
  dt[, (drop_cols) := NULL]
  gc()

  cat("Analysis sample:", nrow(dt), " mean hired:", weighted.mean(dt$hired, dt$w), "\n"); flush.console()
  if (nrow(dt) == 0) stop("empty analysis sample")
  TRUE
}, error = function(e) { cat("Data preparation failed:", conditionMessage(e), "\n"); FALSE })

if (isTRUE(prep_ok)) {
  ## ---- Table 1 ----
  tryCatch({
    m_a1 <- feols(hired ~ urate, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
    RES$aggregate_unemp_rate_no_controls <- getc(m_a1, "urate"); rm(m_a1); gc()
  }, error = function(e) cat("m_a1 failed:", conditionMessage(e), "\n"))
  tryCatch({
    m_a4 <- feols(hired ~ urate | state + demo + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
    RES$aggregate_unemp_rate_month_year_fe <- getc(m_a4, "urate"); rm(m_a4); gc()
  }, error = function(e) cat("m_a4 failed:", conditionMessage(e), "\n"))
  tryCatch({
    m_b1 <- feols(hired ~ young + young_U + exp_U, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_b1))
    RES$young_x_unemp_rate_no_controls <- getc(m_b1, "young_U")
    RES$experienced_x_unemp_rate_no_controls <- getc(m_b1, "exp_U"); rm(m_b1); gc()
  }, error = function(e) cat("m_b1 failed:", conditionMessage(e), "\n"))
  tryCatch({
    m_b4 <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt, weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_b4))
    RES$young_x_unemp_rate_preferred <- getc(m_b4, "young_U")
    RES$experienced_x_unemp_rate_preferred <- getc(m_b4, "exp_U")
    RES$n_obs_full_sample <- nobs(m_b4); rm(m_b4); gc()
  }, error = function(e) cat("m_b4 failed:", conditionMessage(e), "\n"))
  flush.console()

  ## ---- Table 2 ----
  tryCatch({
    m_E <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt, subset = dt$lfs_prev == 1L,
                 weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_E))
    RES$young_x_unemp_rate_employed <- getc(m_E, "young_U")
    RES$experienced_x_unemp_rate_employed <- getc(m_E, "exp_U"); rm(m_E); gc()
  }, error = function(e) cat("m_E failed:", conditionMessage(e), "\n"))
  tryCatch({
    m_U <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt, subset = dt$lfs_prev == 2L,
                 weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_U))
    RES$young_x_unemp_rate_unemployed <- getc(m_U, "young_U"); rm(m_U); gc()
  }, error = function(e) cat("m_U failed:", conditionMessage(e), "\n"))
  tryCatch({
    m_N <- feols(hired ~ young + young_U + exp_U | state + demo + ym, data = dt, subset = dt$lfs_prev == 3L,
                 weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_N))
    RES$young_x_unemp_rate_nilf <- getc(m_N, "young_U"); rm(m_N); gc()
  }, error = function(e) cat("m_N failed:", conditionMessage(e), "\n"))
  flush.console()

  ## print intermediate results in case the wage step fails hard
  cat("Intermediate results:\n"); print(unlist(RES)); flush.console()

  ## ---- Table 10: wages of new hires ----
  tryCatch({
    wcol <- if ("v2prernwa" %in% names(dt)) "v2prernwa" else NA
    if (is.na(wcol)) stop("no weekly wage column")
    h <- dt[hired == 100]
    rm(dt); gc()
    h[, wage := get(wcol)]
    if ("v2hrmis" %in% names(h)) h <- h[v2hrmis %in% c(4, 8)]
    h <- h[!is.na(wage) & wage > 0]
    if ("v2prwernal" %in% names(h)) h <- h[is.na(v2prwernal) | v2prwernal == 0]
    def <- fread(f_def)
    setnames(def, tolower(names(def)))
    if (!("year" %in% names(def))) { yc <- grep("year", names(def), value = TRUE); if (length(yc)) setnames(def, yc[1], "year") }
    if (!("month" %in% names(def))) { mc <- grep("month", names(def), value = TRUE); if (length(mc)) setnames(def, mc[1], "month") }
    if (!("cpi" %in% names(def))) {
      cc <- setdiff(names(def), c("year","month"))
      cc <- cc[sapply(def[, ..cc], function(x) is.numeric(x) || !all(is.na(suppressWarnings(as.numeric(x)))))]
      if (length(cc)) setnames(def, cc[1], "cpi")
    }
    def <- def[, .(year = fix_year(as.numeric(year)), month = as.integer(as.numeric(month)), cpi = as.numeric(cpi))]
    def <- unique(def, by = c("year","month"))
    base_cpi <- mean(def[year == 1994, cpi], na.rm = TRUE)
    h <- merge(h, def, by.x = c("v2hryear","v2hrmonth"), by.y = c("year","month"), all.x = TRUE)
    h[, lw := log(wage / (cpi / base_cpi))]
    h <- h[is.finite(lw)]
    ix <- fread(f_ind); ox <- fread(f_occ)
    ix <- unique(ix[, .(code = as.numeric(v2peio1icd), cy = as.numeric(v2ind_codeyear), ind02 = v2censusind_2002recode)], by = c("code","cy"))
    ox <- unique(ox[, .(code = as.numeric(v2peio1ocd), cy = as.numeric(v2occ_codeyear), occ02 = v2censusocc_2002recode)], by = c("code","cy"))
    pick_cy <- function(yr, cys) { cys <- sort(unique(cys[!is.na(cys)])); sapply(yr, function(y) { s <- cys[cys <= y]; if (length(s)) max(s) else min(cys) }) }
    yrs <- sort(unique(h$v2hryear))
    im <- data.table(v2hryear = yrs, icy = pick_cy(yrs, ix$cy), ocy = pick_cy(yrs, ox$cy))
    h <- merge(h, im, by = "v2hryear")
    h <- merge(h, ix, by.x = c("v2peio1icd","icy"), by.y = c("code","cy"), all.x = TRUE)
    h <- merge(h, ox, by.x = c("v2peio1ocd","ocy"), by.y = c("code","cy"), all.x = TRUE)
    h[, ind_fe := ifelse(is.na(ind02), paste0("raw", icy, "_", v2peio1icd), as.character(ind02))]
    h[, occ_fe := ifelse(is.na(occ02), paste0("raw", ocy, "_", v2peio1ocd), as.character(occ02))]
    cat("Wage sample:", nrow(h), "\n")
    m_w <- feols(lw ~ young + young_U + exp_U | state + demo + ym + occ_fe + ind_fe,
                 data = h, weights = ~w, cluster = ~state, lean = TRUE)
    print(coeftable(m_w))
    RES$wage_young_x_unemp_rate_all_hires <- getc(m_w, "young_U")
    RES$wage_experienced_x_unemp_rate_all_hires <- getc(m_w, "exp_U")
  }, error = function(e) cat("Wage regression failed:", conditionMessage(e), "\n"))
}

print_results()