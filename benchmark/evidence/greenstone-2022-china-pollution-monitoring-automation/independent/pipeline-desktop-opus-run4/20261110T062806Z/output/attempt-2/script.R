suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"

rd_dta <- function(f) {
  d <- haven::read_dta(file.path(base, f))
  d <- haven::zap_labels(d)
  as.data.table(d)
}

key <- function(x) {
  x <- haven::zap_labels(x)
  s <- trimws(as.character(x))
  s <- sub("\\.0+$", "", s)
  s
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    x <- as.numeric(x)
    med <- median(x, na.rm = TRUE)
    if (is.finite(med) && med > 1e9) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    if (is.finite(med) && med > 1e7) return(as.Date(as.character(as.integer(x)), format = "%Y%m%d"))
    return(as.Date(x, origin = "1960-01-01"))
  }
  x <- as.character(x)
  as.Date(x, tryFormats = c("%Y-%m-%d", "%Y/%m/%d", "%d%b%Y", "%Y%m%d"), optional = TRUE)
}

num <- function(x) suppressWarnings(as.numeric(x))

results <- list()
put <- function(name, val) {
  results[[name]] <<- val
}

run_rd <- function(y, x, cl, label) {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  y <- y[ok]; x <- x[ok]; cl <- as.integer(factor(cl[ok]))
  r <- tryCatch(
    rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd",
             vce = "hc1", cluster = cl, masspoints = "off"),
    error = function(e) { message(label, " clustered rdrobust failed: ", conditionMessage(e)); NULL })
  if (is.null(r)) {
    r <- tryCatch(
      rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd", vce = "hc1"),
      error = function(e) { message(label, " rdrobust failed: ", conditionMessage(e)); NULL })
  }
  if (is.null(r)) return(NA_real_)
  b <- as.numeric(r$coef[1])
  se <- as.numeric(r$se[1])
  message(sprintf("%s: coef=%.4f se=%.4f h=%.3f N_eff=%s N=%d", label, b, se,
                  as.numeric(r$bws[1, 1]), paste(r$N_h, collapse = "/"), length(y)))
  b
}

resid_full <- function(model, n) {
  out <- rep(NA_real_, n)
  r <- tryCatch(resid(model, na.rm = FALSE), error = function(e) NULL)
  if (!is.null(r) && length(r) == n) return(as.numeric(r))
  idx <- tryCatch(fixest::obs(model), error = function(e) NULL)
  if (is.null(idx)) {
    idx <- seq_len(n)
    if (length(model$obs_selection) > 0) {
      for (s in model$obs_selection) idx <- idx[s]
    }
  }
  out[idx] <- as.numeric(resid(model))
  out
}

# ---------------- Station list ----------------
st <- rd_dta("station_list.dta")
st[, skey := key(pm10_n)]
st[, ckey := key(code_city)]
st[, auto := to_date(auto_date)]
st[, wave := num(gsub("[^0-9.]", "", as.character(phase)))]
if (all(is.na(st$wave))) {
  ci <- rd_dta("city_info.dta")
  ci[, ckey := key(code_city)]
  ci[, wave_ci := num(gsub("[^0-9.]", "", as.character(phase)))]
  st <- merge(st, unique(ci[, .(ckey, wave_ci)], by = "ckey"), by = "ckey", all.x = TRUE)
  st[, wave := wave_ci]
}
if (all(is.na(st$wave))) st[, wave := ifelse(auto < as.Date("2013-07-01"), 1, 2)]
st[, lon := num(station_lon)]
st[, lat := num(station_lat)]
st <- unique(st, by = "skey")
st <- st[wave %in% c(1, 2) & !is.na(auto)]
st[, dl := as.Date(ifelse(wave == 1, "2013-01-01", "2014-01-01"))]
st[, st_dead := !is.na(auto) & auto == dl]
message("Station-level deadline stations: wave1 ", sum(st$st_dead & st$wave == 1), ", wave2 ", sum(st$st_dead & st$wave == 2))
cst <- st[, .(city_auto = min(auto), wave = wave[1]), by = ckey]
cst[, city_dl := as.Date(ifelse(wave == 1, "2013-01-01", "2014-01-01"))]
cst[, city_dead := city_auto == city_dl]
st <- merge(st, cst[, .(ckey, city_auto, city_dead)], by = "ckey", all.x = TRUE)
message("Stations: ", nrow(st), " cities: ", nrow(cst), " deadline cities: ", sum(cst$city_dead))

# ---------------- Pollution + weather ----------------
po <- rd_dta("pollution_1116.dta")
po <- po[, .(skey = key(station_n), ckey_p = key(code_city), date = to_date(date), pm10 = num(pm10))]
we <- rd_dta("weather_1116.dta")
we <- we[, .(skey = key(station_n), date = to_date(date), temp = num(temp), rain = num(rain),
             rh = num(rh), wind = num(wind_speed))]
we <- unique(we, by = c("skey", "date"))

# monthly station weather (for AOD and city-level searches)
we[, `:=`(yr = year(date), mo = month(date))]
wm <- we[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             rh = mean(rh, na.rm = TRUE), wind = mean(wind, na.rm = TRUE)), by = .(skey, yr, mo)]
we[, c("yr", "mo") := NULL]

po <- merge(po, we, by = c("skey", "date"), all.x = TRUE)
rm(we); invisible(gc())

match_rate <- mean(po$skey %in% st$skey)
message("Station key match rate: ", round(match_rate, 3))
if (match_rate >= 0.5) {
  po <- merge(po, st[, .(skey, ckey, auto, wave, city_dead, st_dead)], by = "skey")
} else {
  message("Falling back to city-level automation dates")
  po[, ckey := ckey_p]
  po <- merge(po, cst[, .(ckey, auto = city_auto, wave, city_dead)], by = "ckey")
  po[, st_dead := city_dead]
}
po <- po[!is.na(pm10) & !is.na(auto) & !is.na(date) & wave %in% c(1, 2)]
po <- po[date >= as.Date("2011-01-01") & date <= as.Date("2016-12-31")]
po[, x := as.numeric(date - auto)]
po[, keep := any(x < 0) & any(x >= 0), by = skey]
po <- po[keep == TRUE]
po[, keep := NULL]
po[, `:=`(moy = month(date), ym = year(date) * 100L + month(date))]
message("Daily RD sample: ", nrow(po), " obs, ", uniqueN(po$skey), " stations, ", uniqueN(po$ckey), " cities")

# ---------------- Table 1 Panel A: RD in daily PM10 ----------------
tryCatch({
  put("rd_pm_daily_no_controls_table1_panelA_col1",
      run_rd(po$pm10, po$x, po$ckey, "RD PM10 no controls"))
}, error = function(e) message("col1 error: ", conditionMessage(e)))

tryCatch({
  rr <- feols(pm10 ~ temp + rain + rh + wind | skey + moy, data = po, notes = FALSE, warn = FALSE)
  po[, res := resid_full(rr, nrow(po))]
  rm(rr); invisible(gc())
}, error = function(e) {
  message("residualization error: ", conditionMessage(e))
  po[, res := NA_real_]
})

tryCatch({
  put("rd_pm_daily_controls_table1_panelA_col2",
      run_rd(po$res, po$x, po$ckey, "RD PM10 residualized"))
}, error = function(e) message("col2 error: ", conditionMessage(e)))
tryCatch({
  s <- po[wave == 1]
  put("rd_pm_daily_wave1_table1_panelA_col3", run_rd(s$res, s$x, s$ckey, "RD PM10 wave 1"))
}, error = function(e) message("col3 error: ", conditionMessage(e)))
tryCatch({
  s <- po[wave == 2]
  put("rd_pm_daily_wave2_table1_panelA_col4", run_rd(s$res, s$x, s$ckey, "RD PM10 wave 2"))
}, error = function(e) message("col4 error: ", conditionMessage(e)))
tryCatch({
  s <- po[city_dead == TRUE]
  put("rd_pm_daily_deadline_table1_panelA_col5", run_rd(s$res, s$x, s$ckey, "RD PM10 deadline"))
}, error = function(e) message("col5 error: ", conditionMessage(e)))

# ---------------- AOD RD (monthly) ----------------
tryCatch({
  ao <- rd_dta("aod_month.dta")
  ao <- ao[, .(skey = key(pm10_n), yr = as.integer(num(year)), mo = as.integer(num(month)), aod = num(aod))]
  ao <- merge(ao, st[, .(skey, ckey, auto, wave)], by = "skey")
  ao <- merge(ao, wm, by = c("skey", "yr", "mo"), all.x = TRUE)
  ao <- ao[!is.na(aod) & yr >= 2011 & yr <= 2016]
  ao[, xm := (yr * 12 + mo) - (year(auto) * 12 + month(auto))]
  ao <- ao[is.finite(temp) & is.finite(rain) & is.finite(rh) & is.finite(wind)]
  ra <- feols(aod ~ temp + rain + rh + wind | skey + mo, data = ao, notes = FALSE, warn = FALSE)
  ao[, res := resid_full(ra, nrow(ao))]
  put("rd_aod_monthly_controls_table1_panelA_col2", run_rd(ao$res, ao$xm, ao$ckey, "RD AOD residualized"))
}, error = function(e) message("AOD error: ", conditionMessage(e)))

# ---------------- Table 1 Panel B: event study ----------------
# Deadline stations defined at station level (station automated exactly on its wave deadline),
# matching the paper's 242 Wave-1 / 123 Wave-2 deadline stations
es <- po[st_dead == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es[, treat := as.integer(wave == 1)]
es[, m := (year(date) - 2013L) * 12L + month(date) - 1L]
es[, `:=`(
  b_712 = treat * as.integer(m >= -12 & m <= -7),
  b_56  = treat * as.integer(m %in% c(-6L, -5L)),
  b_34  = treat * as.integer(m %in% c(-4L, -3L)),
  a_12  = treat * as.integer(m %in% c(0L, 1L)),
  a_34  = treat * as.integer(m %in% c(2L, 3L)),
  a_56  = treat * as.integer(m %in% c(4L, 5L)),
  a_712 = treat * as.integer(m >= 6 & m <= 11)
)]
message("Event study sample: ", nrow(es), " obs; treated stations ", uniqueN(es[treat == 1]$skey),
        "; control stations ", uniqueN(es[treat == 0]$skey))

es_rhs <- "b_712 + b_56 + b_34 + a_12 + a_34 + a_56 + a_712 + temp + rain + rh + wind"

tryCatch({
  m1 <- feols(as.formula(paste("pm10 ~", es_rhs, "| skey + moy")), data = es, cluster = ~ckey, notes = FALSE)
  print(coeftable(m1))
  put("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", unname(coef(m1)["a_12"]))
  put("n_obs_table1_panelB_deadline_cols1_2", nobs(m1))
}, error = function(e) message("ES col1 error: ", conditionMessage(e)))

tryCatch({
  m2 <- feols(as.formula(paste("pm10 ~", es_rhs, "| skey + ym")), data = es, cluster = ~ckey, notes = FALSE)
  print(coeftable(m2))
  put("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", unname(coef(m2)["a_12"]))
}, error = function(e) message("ES col2 error: ", conditionMessage(e)))

# Matched sample: each Wave-1 deadline station paired with nearest Wave-2 deadline station (with replacement)
tryCatch({
  tsk <- unique(es[treat == 1]$skey)
  csk <- unique(es[treat == 0]$skey)
  tco <- st[match(tsk, st$skey), .(skey, lon, lat)]
  cco <- st[match(csk, st$skey), .(skey, lon, lat)]
  tco <- tco[is.finite(lon) & is.finite(lat)]
  cco <- cco[is.finite(lon) & is.finite(lat)]
  hav <- function(lon1, lat1, lon2, lat2) {
    rad <- pi / 180
    dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
    a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
    2 * 6371 * asin(pmin(1, sqrt(a)))
  }
  pr <- rbindlist(lapply(seq_len(nrow(tco)), function(i) {
    d <- hav(tco$lon[i], tco$lat[i], cco$lon, cco$lat)
    data.table(tskey = tco$skey[i], cskey = cco$skey[which.min(d)])
  }))
  trd <- es[treat == 1 & skey %in% pr$tskey]
  trd[, unit := paste0("T_", skey)]
  ctd <- merge(es[treat == 0], pr, by.x = "skey", by.y = "cskey", allow.cartesian = TRUE)
  ctd[, unit := paste0("C_", tskey)]
  ctd[, tskey := NULL]
  mt <- rbindlist(list(trd, ctd), use.names = TRUE, fill = TRUE)
  message("Matched sample: ", nrow(mt), " obs; pairs ", nrow(pr), "; unique controls ", uniqueN(pr$cskey))

  m3 <- feols(as.formula(paste("pm10 ~", es_rhs, "| unit + moy")), data = mt, cluster = ~ckey, notes = FALSE)
  print(coeftable(m3))
  put("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", unname(coef(m3)["a_12"]))

  mt5 <- mt[pm10 > 0]
  mt5[, lpm := log(pm10)]
  m5 <- feols(as.formula(paste("lpm ~", es_rhs, "| unit + ym")), data = mt5, cluster = ~ckey, notes = FALSE)
  print(coeftable(m5))
  put("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", unname(coef(m5)["a_12"]))
}, error = function(e) message("Matched ES error: ", conditionMessage(e)))

# ---------------- Baidu searches RD (city-month) ----------------
tryCatch({
  ms <- rd_dta("mask_filter_search.dta")
  ms <- ms[, .(ckey = key(code_city), date = to_date(date), mask = num(pmmask), filter = num(filter))]
  ms <- ms[ckey %in% cst$ckey & !is.na(date)]
  ms <- ms[date >= as.Date("2011-01-01") & date <= as.Date("2016-12-31")]
  msm <- ms[, .(mask = mean(mask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)),
            by = .(ckey, yr = year(date), mo = month(date))]
  rm(ms); invisible(gc())

  cwm <- merge(wm, st[, .(skey, ckey)], by = "skey")
  cwm <- cwm[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
                 rh = mean(rh, na.rm = TRUE), wind = mean(wind, na.rm = TRUE)), by = .(ckey, yr, mo)]
  msm <- merge(msm, cst[, .(ckey, city_auto, wave)], by = "ckey")
  msm <- merge(msm, cwm, by = c("ckey", "yr", "mo"), all.x = TRUE)
  msm[, xm := (yr * 12 + mo) - (year(city_auto) * 12 + month(city_auto))]
  msm <- msm[is.finite(temp) & is.finite(rain) & is.finite(rh) & is.finite(wind)]
  message("Search sample: ", nrow(msm), " city-months, ", uniqueN(msm$ckey), " cities")

  mk <- msm[is.finite(mask)]
  rm1 <- feols(mask ~ temp + rain + rh + wind | ckey + mo, data = mk, notes = FALSE, warn = FALSE)
  mk[, res := resid_full(rm1, nrow(mk))]
  put("rd_face_mask_searches_controls_table2_panelA_col2", run_rd(mk$res, mk$xm, mk$ckey, "RD mask searches"))

  fl <- msm[is.finite(filter)]
  rm2 <- feols(filter ~ temp + rain + rh + wind | ckey + mo, data = fl, notes = FALSE, warn = FALSE)
  fl[, res := resid_full(rm2, nrow(fl))]
  put("rd_air_filter_searches_controls_table2_panelA_col2", run_rd(fl$res, fl$xm, fl$ckey, "RD filter searches"))
}, error = function(e) message("Search RD error: ", conditionMessage(e)))

# ---------------- Output ----------------
names_out <- c(
  "rd_pm_daily_no_controls_table1_panelA_col1",
  "rd_pm_daily_controls_table1_panelA_col2",
  "rd_pm_daily_wave1_table1_panelA_col3",
  "rd_pm_daily_wave2_table1_panelA_col4",
  "rd_pm_daily_deadline_table1_panelA_col5",
  "rd_aod_monthly_controls_table1_panelA_col2",
  "event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1",
  "event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2",
  "event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3",
  "event_study_log_pm_1_2_months_after_matched_table1_panelB_col5",
  "n_obs_table1_panelB_deadline_cols1_2",
  "rd_face_mask_searches_controls_table2_panelA_col2",
  "rd_air_filter_searches_controls_table2_panelA_col2"
)
for (nm in names_out) {
  v <- results[[nm]]
  if (is.null(v) || length(v) == 0 || !is.finite(as.numeric(v))) {
    cat(sprintf("RESULT:%s=NA\n", nm))
  } else {
    cat(sprintf("RESULT:%s=%s\n", nm, format(as.numeric(v), digits = 10, scientific = FALSE)))
  }
}