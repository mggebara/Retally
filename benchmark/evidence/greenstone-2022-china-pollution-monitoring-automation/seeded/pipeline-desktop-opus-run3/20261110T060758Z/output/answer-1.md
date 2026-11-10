suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"

# Convert a date column to Stata daily numbers (days since 1960-01-01)
to_stata_day <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x) + 3653)
  if (inherits(x, "POSIXt")) return(as.numeric(as.Date(x)) + 3653)
  as.numeric(x)
}
rd_dt <- function(path) {
  d <- haven::read_dta(path)
  d <- haven::zap_labels(d)
  as.data.table(d)
}
nan2na <- function(v) { v[is.nan(v)] <- NA_real_; v }
mofd <- function(sday) {
  d <- as.Date(sday - 3653, origin = "1970-01-01")
  (as.integer(format(d, "%Y")) - 1960L) * 12L + as.integer(format(d, "%m")) - 1L
}

results <- list()
emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) results[[name]] <<- val
}

run_rd <- function(y, x, cl) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, q = 2, kernel = "triangular",
                vce = "hc0", cluster = cl[ok], masspoints = "off")
  out <- list(coef = as.numeric(r$coef[1, 1]), se = as.numeric(r$se[1, 1]),
              h = as.numeric(r$bws[1, 1]), N = sum(r$N_h))
  cat(sprintf("  RD: coef=%.4f se=%.4f h=%.2f N_h=%d\n", out$coef, out$se, out$h, out$N))
  out
}

# ---------------------------------------------------------------------------
# 1. station_day_1116
# ---------------------------------------------------------------------------
poll <- rd_dt(file.path(base, "pollution_1116.dta"))
poll[, date := to_stata_day(date)]
wea <- rd_dt(file.path(base, "weather_1116.dta"))
wea[, date := to_stata_day(date)]
wea <- wea[, .(station_n, date, wind_speed, rh, rain, temp)]

sd <- merge(poll, wea, by = c("station_n", "date"), all = TRUE)
rm(poll, wea); invisible(gc())
setnames(sd, "station_n", "pm10_n")

sl <- rd_dt(file.path(base, "station_list.dta"))
sl[, auto_date := to_stata_day(auto_date)]
sl_m <- sl[, .(pm10_n, auto_date, phase, code_city_sl = code_city)]
sd <- merge(sd, sl_m, by = "pm10_n", all.x = TRUE)
sd[is.na(code_city), code_city := code_city_sl]
sd[, code_city_sl := NULL]
sd <- sd[!is.na(date)]

dd <- as.Date(sd$date - 3653, origin = "1970-01-01")
sd[, year := as.integer(format(dd, "%Y"))]
sd[, month := as.integer(format(dd, "%m"))]
rm(dd)
sd[, T := date - auto_date]

# ---------------------------------------------------------------------------
# Table 1A Row 1: daily PM10 RD
# ---------------------------------------------------------------------------
tryCatch({
  m_res <- feols(pm10 ~ wind_speed + rain + temp + rh | pm10_n + month, data = sd)
  sd[, resid_pm10_smw := resid(m_res, na.rm = FALSE)]
  rm(m_res); invisible(gc())
}, error = function(e) cat("Residualization error:", conditionMessage(e), "\n"))

wok <- !is.na(sd$temp) & !is.na(sd$rain) & !is.na(sd$rh) & !is.na(sd$wind_speed)

tryCatch({
  cat("Col 1 (raw)\n")
  r <- run_rd(sd$pm10[wok], sd$T[wok], sd$code_city[wok])
  emit("rd_pm_daily_no_controls_table1_panelA_col1", r$coef)
}, error = function(e) cat("Col1 error:", conditionMessage(e), "\n"))

tryCatch({
  cat("Col 2 (residual)\n")
  r <- run_rd(sd$resid_pm10_smw, sd$T, sd$code_city)
  emit("rd_pm_daily_controls_table1_panelA_col2", r$coef)
}, error = function(e) cat("Col2 error:", conditionMessage(e), "\n"))

tryCatch({
  cat("Col 3 (wave 1)\n")
  s <- which(sd$phase == 1)
  r <- run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s])
  emit("rd_pm_daily_wave1_table1_panelA_col3", r$coef)
}, error = function(e) cat("Col3 error:", conditionMessage(e), "\n"))

tryCatch({
  cat("Col 4 (wave 2)\n")
  s <- which(sd$phase == 2)
  r <- run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s])
  emit("rd_pm_daily_wave2_table1_panelA_col4", r$coef)
}, error = function(e) cat("Col4 error:", conditionMessage(e), "\n"))

tryCatch({
  cat("Col 5 (deadline)\n")
  s <- which(sd$auto_date %in% c(19359, 19724))
  r <- run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s])
  emit("rd_pm_daily_deadline_table1_panelA_col5", r$coef)
}, error = function(e) cat("Col5 error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------------------
# Table 1A Row 2: monthly AOD (station_month)
# ---------------------------------------------------------------------------
tryCatch({
  sd[, month_date := (year - 1960L) * 12L + month - 1L]
  auto_m <- sl[, .(pm10_n, month_auto_date = mofd(auto_date))]
  sm <- sd[, .(pm10 = mean(pm10, na.rm = TRUE),
               wind_speed = mean(wind_speed, na.rm = TRUE),
               rain = mean(rain, na.rm = TRUE),
               temp = mean(temp, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE),
               code_city = code_city[1], phase = phase[1], auto_date = auto_date[1],
               month_date = month_date[1]),
           by = .(pm10_n, year, month)]
  for (v in c("pm10", "wind_speed", "rain", "temp", "rh")) set(sm, j = v, value = nan2na(sm[[v]]))
  sm <- merge(sm, auto_m, by = "pm10_n", all.x = TRUE)
  sm[, n_month := month_date - month_auto_date]
  aod <- rd_dt(file.path(base, "aod_month.dta"))
  aod <- aod[, .(pm10_n, year = as.integer(year), month = as.integer(month), aod)]
  sm <- merge(sm, aod, by = c("pm10_n", "year", "month"))
  m_aod <- feols(aod ~ wind_speed + rain + temp + rh | pm10_n + month, data = sm)
  sm[, resid_aod_smw := resid(m_aod, na.rm = FALSE)]
  cat("AOD residual RD\n")
  r <- run_rd(sm$resid_aod_smw, sm$n_month, sm$code_city)
  emit("rd_aod_monthly_controls_table1_panelA_col2", r$coef)
}, error = function(e) cat("AOD error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------------------
# Table 1B: event study
# ---------------------------------------------------------------------------
make_es <- function(d) {
  d[, year_month := year * 100L + month]
  d[, treat := as.integer(auto_date == 19359)]
  d[, `:=`(
    treat_m12_before2  = treat * as.integer(year == 2012 & month >= 11 & month <= 12),
    treat_m34_before2  = treat * as.integer(year == 2012 & month >= 9 & month <= 10),
    treat_m56_before2  = treat * as.integer(year == 2012 & month >= 7 & month <= 8),
    treat_m712_before2 = treat * as.integer(year == 2012 & month >= 1 & month <= 6),
    treat_m12_after2   = treat * as.integer(year == 2013 & month >= 1 & month <= 2),
    treat_m34_after2   = treat * as.integer(year == 2013 & month >= 3 & month <= 4),
    treat_m56_after2   = treat * as.integer(year == 2013 & month >= 5 & month <= 6),
    treat_m712_after2  = treat * as.integer(year == 2013 & month >= 7 & month <= 12)
  )]
  d
}
es_rhs <- "treat_m712_before2 + treat_m56_before2 + treat_m34_before2 + treat_m12_after2 + treat_m34_after2 + treat_m56_after2 + treat_m712_after2 + wind_speed + rain + temp + rh"

tryCatch({
  es <- sd[year >= 2012 & year <= 2013 & auto_date %in% c(19359, 19724),
           .(pm10_n, code_city, date, year, month, auto_date, pm10, wind_speed, rain, temp, rh)]
  es <- make_es(es)
  m1 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = es, cluster = ~code_city)
  m2 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + year_month")), data = es, cluster = ~code_city)
  cat(sprintf("ES col1: %.3f (N=%d); col2: %.3f (N=%d)\n",
              coef(m1)["treat_m12_after2"], nobs(m1), coef(m2)["treat_m12_after2"], nobs(m2)))
  emit("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", unname(coef(m1)["treat_m12_after2"]))
  emit("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", unname(coef(m2)["treat_m12_after2"]))
  emit("n_obs_table1_panelB_deadline_cols1_2", as.numeric(nobs(m1)))
}, error = function(e) cat("ES deadline error:", conditionMessage(e), "\n"))

# Nearest-neighbour matching (geonear, ellipsoid) -- Vincenty inverse distance
vincenty_km <- function(lat1, lon1, lat2, lon2) {
  a <- 6378137; f <- 1 / 298.257223563; b <- (1 - f) * a
  rad <- pi / 180
  L <- (lon2 - lon1) * rad
  U1 <- atan((1 - f) * tan(lat1 * rad)); U2 <- atan((1 - f) * tan(lat2 * rad))
  sinU1 <- sin(U1); cosU1 <- cos(U1); sinU2 <- sin(U2); cosU2 <- cos(U2)
  lambda <- L
  for (it in 1:200) {
    sinL <- sin(lambda); cosL <- cos(lambda)
    sinSigma <- sqrt((cosU2 * sinL)^2 + (cosU1 * sinU2 - sinU1 * cosU2 * cosL)^2)
    cosSigma <- sinU1 * sinU2 + cosU1 * cosU2 * cosL
    sigma <- atan2(sinSigma, cosSigma)
    sinAlpha <- ifelse(sinSigma == 0, 0, cosU1 * cosU2 * sinL / sinSigma)
    cos2Alpha <- 1 - sinAlpha^2
    cos2SigmaM <- ifelse(cos2Alpha != 0, cosSigma - 2 * sinU1 * sinU2 / cos2Alpha, 0)
    C <- f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha))
    lambdaP <- lambda
    lambda <- L + (1 - C) * f * sinAlpha *
      (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM^2)))
    if (max(abs(lambda - lambdaP), na.rm = TRUE) < 1e-12) break
  }
  uSq <- cos2Alpha * (a^2 - b^2) / b^2
  A <- 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
  B <- uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))
  dSigma <- B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM^2) -
            B / 6 * cos2SigmaM * (-3 + 4 * sinSigma^2) * (-3 + 4 * cos2SigmaM^2)))
  s <- b * A * (sigma - dSigma) / 1000
  s[sinSigma == 0] <- 0
  s
}

tryCatch({
  tr <- sl[auto_date == 19359 & !is.na(station_lat) & !is.na(station_lon)]
  co <- sl[auto_date == 19724 & !is.na(station_lat) & !is.na(station_lon)]
  matches <- rbindlist(lapply(seq_len(nrow(tr)), function(i) {
    dk <- vincenty_km(tr$station_lat[i], tr$station_lon[i], co$station_lat, co$station_lon)
    j <- which.min(dk)
    data.table(pm10_n1 = tr$pm10_n[i], pm10_n = co$pm10_n[j], km = dk[j])
  }))
  matches <- matches[km <= 400]
  cat(sprintf("Matched treated stations: %d; unique controls: %d\n",
              nrow(matches), uniqueN(matches$pm10_n)))
  sd12 <- sd[year >= 2012 & year <= 2013,
             .(pm10_n, code_city, date, year, month, auto_date, pm10, wind_speed, rain, temp, rh)]
  treated_dt <- sd12[pm10_n %in% unique(matches$pm10_n1)]
  ctrl_list <- data.table(pm10_n = matches$pm10_n)
  control_dt <- merge(sd12, ctrl_list, by = "pm10_n", allow.cartesian = TRUE)
  mt <- rbindlist(list(treated_dt, control_dt), use.names = TRUE)
  mt[, l_pm10 := ifelse(!is.na(pm10) & pm10 > 0, log(pm10), NA_real_)]
  mt <- make_es(mt)
  m3 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = mt, cluster = ~code_city)
  m5 <- feols(as.formula(paste("l_pm10 ~", es_rhs, "| pm10_n + year_month")), data = mt, cluster = ~code_city)
  cat(sprintf("ES col3: %.3f (N=%d); col5: %.4f (N=%d)\n",
              coef(m3)["treat_m12_after2"], nobs(m3), coef(m5)["treat_m12_after2"], nobs(m5)))
  emit("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", unname(coef(m3)["treat_m12_after2"]))
  emit("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", unname(coef(m5)["treat_m12_after2"]))
}, error = function(e) cat("ES matched error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------------------
# Table 2A (NBER Table 3): city-month search RD
# ---------------------------------------------------------------------------
tryCatch({
  setorder(sd, code_city, date, -auto_date)
  cd <- sd[, .(wind_speed = mean(wind_speed, na.rm = TRUE),
               rain = mean(rain, na.rm = TRUE),
               temp = mean(temp, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE),
               auto_date = auto_date[1], year = year[1], month = month[1]),
           by = .(code_city, date)]
  for (v in c("wind_speed", "rain", "temp", "rh")) set(cd, j = v, value = nan2na(cd[[v]]))
  mfs <- rd_dt(file.path(base, "mask_filter_search.dta"))
  mfs[, date := to_stata_day(date)]
  mfs <- mfs[, .(code_city, date, filter, pmmask)]
  cd <- merge(cd, mfs, by = c("code_city", "date"))
  cd[, month_date := (year - 1960L) * 12L + month - 1L]
  cd[, month_auto_date := mofd(auto_date)]
  cd[, n_month := month_date - month_auto_date]
  cm <- cd[, .(wind_speed = mean(wind_speed, na.rm = TRUE),
               rain = mean(rain, na.rm = TRUE),
               temp = mean(temp, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE),
               filter = mean(filter, na.rm = TRUE),
               pmmask = mean(pmmask, na.rm = TRUE),
               month = month[1], year = year[1]),
           by = .(code_city, n_month)]
  for (v in c("wind_speed", "rain", "temp", "rh", "filter", "pmmask")) set(cm, j = v, value = nan2na(cm[[v]]))

  mm <- feols(pmmask ~ wind_speed + rain + temp + rh | code_city + month, data = cm)
  cm[, resid_pmmask_smw := resid(mm, na.rm = FALSE)]
  mf <- feols(filter ~ wind_speed + rain + temp + rh | code_city + month, data = cm)
  cm[, resid_filter_smw := resid(mf, na.rm = FALSE)]
  cat(sprintf("Search obs: mask=%d filter=%d\n", nobs(mm), nobs(mf)))

  cat("Mask RD\n")
  r <- run_rd(cm$resid_pmmask_smw, cm$n_month, cm$code_city)
  emit("rd_face_mask_searches_controls_table2_panelA_col2", r$coef)
  cat("Filter RD\n")
  r <- run_rd(cm$resid_filter_smw, cm$n_month, cm$code_city)
  emit("rd_air_filter_searches_controls_table2_panelA_col2", r$coef)
}, error = function(e) cat("Search error:", conditionMessage(e), "\n"))

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, results[[nm]]))
}
