suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})

set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
# Convert a date-like column to Stata daily date (days since 1960-01-01)
sday <- function(x) {
  if (inherits(x, "Date")) return(as.numeric(x) + 3653)
  if (inherits(x, "POSIXt")) return(floor(as.numeric(x) / 86400) + 3653)
  as.numeric(zap_labels(x))
}
num <- function(x) as.numeric(zap_labels(x))
sd2date <- function(d) as.Date(d - 3653, origin = "1970-01-01")
mofd <- function(d) {
  dd <- sd2date(d)
  (as.integer(format(dd, "%Y")) - 1960L) * 12L + as.integer(format(dd, "%m")) - 1L
}
nan2na <- function(dt, cols) {
  for (v in cols) set(dt, which(is.nan(dt[[v]]) | is.infinite(dt[[v]])), v, NA_real_)
  invisible(dt)
}

# reghdfe y weather, absorb(fe) res(...)  -> residual vector aligned with rows
resid_fe <- function(dt, y, fe) {
  f <- as.formula(paste0(y, " ~ wind_speed + rain + temp + rh | ", fe))
  m <- feols(f, data = dt, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  r <- resid(m, na.rm = FALSE)
  if (length(r) != nrow(dt)) {
    r2 <- rep(NA_real_, nrow(dt))
    r2[obs(m)] <- resid(m)
    r <- r2
  }
  r
}

# rdrobust y x, c(0) p(1) q(2) kernel(tri) vce(cluster code_city) masspoints(off)
rd_est <- function(y, x, cl, label = "") {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, q = 2, kernel = "triangular",
                vce = "hc1", cluster = cl[ok], masspoints = "off")
  cat(sprintf("[%s] coef=%.4f se=%.4f h=%.2f N_h=%d\n", label, r$coef[1], r$se[1],
              r$bws[1, 1], as.integer(sum(r$N_h))))
  as.numeric(r$coef[1])
}

results <- list()
safe <- function(name, expr) {
  val <- tryCatch(expr, error = function(e) {
    message("Error in ", name, ": ", conditionMessage(e)); NA_real_
  })
  results[[name]] <<- val
}

# ---------------------------------------------------------------------------
# 1. station_day_1116
# ---------------------------------------------------------------------------
pol <- as.data.table(read_dta(file.path(base, "pollution_1116.dta")))
wea <- as.data.table(read_dta(file.path(base, "weather_1116.dta")))
st  <- as.data.table(read_dta(file.path(base, "station_list.dta")))

pol[, date := sday(date)]
wea[, date := sday(date)]
for (v in c("pm10", "no2", "so2", "station_n", "code_city")) set(pol, j = v, value = num(pol[[v]]))
for (v in c("wind_speed", "rh", "rain", "temp", "station_n")) set(wea, j = v, value = num(wea[[v]]))
st[, auto_date := sday(auto_date)]
for (v in c("pm10_n", "phase", "code_city", "station_lon", "station_lat")) set(st, j = v, value = num(st[[v]]))

sd <- merge(pol, wea, by = c("station_n", "date"), all = TRUE)
rm(pol, wea); gc()
setnames(sd, "station_n", "pm10_n")
stm <- st[, .(pm10_n, auto_date, phase, code_city_st = code_city)]
sd <- merge(sd, stm, by = "pm10_n", all.x = TRUE)
sd[is.na(code_city), code_city := code_city_st]
sd[, code_city_st := NULL]

sd[, dd := sd2date(date)]
sd[, year := as.integer(format(dd, "%Y"))]
sd[, month := as.integer(format(dd, "%m"))]
sd[, dd := NULL]
sd[, T := date - auto_date]
setorder(sd, pm10_n, date)

# ---------------------------------------------------------------------------
# Table 1A Row 1: daily PM10 RD
# ---------------------------------------------------------------------------
sd[, resid_pm10_smw := resid_fe(sd, "pm10", "pm10_n + month")]

wok <- with(sd, !is.na(temp) & !is.na(rain) & !is.na(rh) & !is.na(wind_speed))
safe("rd_pm_daily_no_controls_table1_panelA_col1",
     rd_est(sd$pm10[wok], sd$T[wok], sd$code_city[wok], "raw all"))
safe("rd_pm_daily_controls_table1_panelA_col2",
     rd_est(sd$resid_pm10_smw, sd$T, sd$code_city, "resid all"))
w1 <- which(sd$phase == 1)
safe("rd_pm_daily_wave1_table1_panelA_col3",
     rd_est(sd$resid_pm10_smw[w1], sd$T[w1], sd$code_city[w1], "resid wave1"))
w2 <- which(sd$phase == 2)
safe("rd_pm_daily_wave2_table1_panelA_col4",
     rd_est(sd$resid_pm10_smw[w2], sd$T[w2], sd$code_city[w2], "resid wave2"))
dl <- which(sd$auto_date %in% c(19359, 19724))
safe("rd_pm_daily_deadline_table1_panelA_col5",
     rd_est(sd$resid_pm10_smw[dl], sd$T[dl], sd$code_city[dl], "resid deadline"))
gc()

# ---------------------------------------------------------------------------
# Table 1A Row 2: monthly AOD RD (station_month)
# ---------------------------------------------------------------------------
safe("rd_aod_monthly_controls_table1_panelA_col2", {
  sm <- sd[, .(pm10 = mean(pm10, na.rm = TRUE), no2 = mean(no2, na.rm = TRUE),
               so2 = mean(so2, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               temp = mean(temp, na.rm = TRUE), auto_date = auto_date[1],
               phase = phase[1], code_city = code_city[1]),
           by = .(pm10_n, year, month)]
  nan2na(sm, c("pm10", "no2", "so2", "wind_speed", "rh", "rain", "temp"))
  sm <- sm[!is.na(auto_date)]
  sm[, n_month := ((year - 1960L) * 12L + month - 1L) - mofd(auto_date)]
  aod <- as.data.table(read_dta(file.path(base, "aod_month.dta")))
  for (v in names(aod)) set(aod, j = v, value = num(aod[[v]]))
  sm <- merge(sm, aod, by = c("pm10_n", "year", "month"))
  sm[, resid_aod_smw := resid_fe(sm, "aod", "pm10_n + month")]
  rd_est(sm$resid_aod_smw, sm$n_month, sm$code_city, "aod resid all")
})

# ---------------------------------------------------------------------------
# Table 1B: event study
# ---------------------------------------------------------------------------
make_es <- function(d) {
  d[, treat := as.integer(auto_date == 19359)]
  d[, m12_before2 := as.integer(year == 2012 & month >= 11 & month <= 12)]
  d[, m34_before2 := as.integer(year == 2012 & month >= 9 & month <= 10)]
  d[, m56_before2 := as.integer(year == 2012 & month >= 7 & month <= 8)]
  d[, m712_before2 := as.integer(year == 2012 & month >= 1 & month <= 6)]
  d[, m12_after2 := as.integer(year == 2013 & month >= 1 & month <= 2)]
  d[, m34_after2 := as.integer(year == 2013 & month >= 3 & month <= 4)]
  d[, m56_after2 := as.integer(year == 2013 & month >= 5 & month <= 6)]
  d[, m712_after2 := as.integer(year == 2013 & month >= 7 & month <= 12)]
  for (v in c("12", "34", "56", "712")) {
    set(d, j = paste0("treat_m", v, "_before2"), value = d$treat * d[[paste0("m", v, "_before2")]])
    set(d, j = paste0("treat_m", v, "_after2"), value = d$treat * d[[paste0("m", v, "_after2")]])
  }
  d[, year_month := year * 100L + month]
  d
}
es_rhs <- "treat_m712_before2 + treat_m56_before2 + treat_m34_before2 + treat_m12_after2 + treat_m34_after2 + treat_m56_after2 + treat_m712_after2 + wind_speed + rain + temp + rh"

es <- sd[year >= 2012 & year <= 2013 & auto_date %in% c(19724, 19359)]
es <- make_es(es)

m1 <- tryCatch(feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = es,
                     cluster = ~code_city, fixef.rm = "singleton", notes = FALSE),
               error = function(e) { message(conditionMessage(e)); NULL })
results[["event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1"]] <-
  if (is.null(m1)) NA_real_ else unname(coef(m1)["treat_m12_after2"])
results[["n_obs_table1_panelB_deadline_cols1_2"]] <- if (is.null(m1)) NA_real_ else nobs(m1)

safe("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", {
  m2 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + year_month")), data = es,
              cluster = ~code_city, fixef.rm = "singleton", notes = FALSE)
  cat("col2 N =", nobs(m2), "\n")
  unname(coef(m2)["treat_m12_after2"])
})

# ---- nearest-neighbour matching (geonear, ellipsoid, n=1, km<=400) ----
vincenty_km <- function(lat1, lon1, lat2, lon2) {
  a <- 6378137; f <- 1 / 298.257223563; b <- (1 - f) * a
  rad <- pi / 180
  L <- (lon2 - lon1) * rad
  U1 <- atan((1 - f) * tan(lat1 * rad)); U2 <- atan((1 - f) * tan(lat2 * rad))
  sinU1 <- sin(U1); cosU1 <- cos(U1); sinU2 <- sin(U2); cosU2 <- cos(U2)
  lambda <- L
  for (i in 1:200) {
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
    if (all(abs(lambda - lambdaP) < 1e-12, na.rm = TRUE)) break
  }
  u2 <- cos2Alpha * (a^2 - b^2) / b^2
  A <- 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)))
  B <- u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)))
  dSigma <- B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM^2) -
              B / 6 * cos2SigmaM * (-3 + 4 * sinSigma^2) * (-3 + 4 * cos2SigmaM^2)))
  s <- b * A * (sigma - dSigma) / 1000
  # haversine fallback for any non-convergent case
  hav <- 2 * 6371.0088 * asin(sqrt(sin((lat2 - lat1) * rad / 2)^2 +
           cos(lat1 * rad) * cos(lat2 * rad) * sin((lon2 - lon1) * rad / 2)^2))
  ifelse(is.finite(s), s, hav)
}

safe_match <- tryCatch({
  s1 <- st[auto_date == 19359 & !is.na(station_lat) & !is.na(station_lon)]
  s2 <- st[auto_date == 19724 & !is.na(station_lat) & !is.na(station_lon)]
  s2 <- s2[order(pm10_n)]
  mt <- rbindlist(lapply(seq_len(nrow(s1)), function(i) {
    d <- vincenty_km(s1$station_lat[i], s1$station_lon[i], s2$station_lat, s2$station_lon)
    j <- which.min(d)
    data.table(pm10_n1 = s1$pm10_n[i], pm10_n = s2$pm10_n[j], km = d[j])
  }))
  mt <- mt[km <= 400]
  cat("Matched treated stations:", nrow(mt), " unique controls:", uniqueN(mt$pm10_n), "\n")

  sdy <- sd[year == 2012 | year == 2013]
  tr <- sdy[pm10_n %in% unique(mt$pm10_n1)]
  ctrl_ids <- mt[, .(pm10_n)]
  ct <- merge(sdy, ctrl_ids, by = "pm10_n", allow.cartesian = TRUE)
  md <- rbind(tr, ct, use.names = TRUE, fill = TRUE)
  md[, l_pm10 := ifelse(!is.na(pm10) & pm10 > 0, log(pm10), NA_real_)]
  md <- make_es(md)
  md
}, error = function(e) { message("Matching error: ", conditionMessage(e)); NULL })

if (!is.null(safe_match)) {
  md <- safe_match
  safe("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", {
    m3 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = md,
                cluster = ~code_city, fixef.rm = "singleton", notes = FALSE)
    cat("col3 N =", nobs(m3), "\n")
    unname(coef(m3)["treat_m12_after2"])
  })
  safe("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", {
    m5 <- feols(as.formula(paste("l_pm10 ~", es_rhs, "| pm10_n + year_month")), data = md,
                cluster = ~code_city, fixef.rm = "singleton", notes = FALSE)
    cat("col5 N =", nobs(m5), "\n")
    unname(coef(m5)["treat_m12_after2"])
  })
} else {
  results[["event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3"]] <- NA_real_
  results[["event_study_log_pm_1_2_months_after_matched_table1_panelB_col5"]] <- NA_real_
}
rm(es, safe_match); gc()

# ---------------------------------------------------------------------------
# Table 2A (NBER Table 3): city-month online search RD
# ---------------------------------------------------------------------------
search_ok <- tryCatch({
  setorder(sd, code_city, date, -auto_date)
  cdv <- c("pm10", "no2", "so2", "wind_speed", "rh", "rain", "temp")
  cd <- sd[, .(pm10 = mean(pm10, na.rm = TRUE), no2 = mean(no2, na.rm = TRUE),
               so2 = mean(so2, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               temp = mean(temp, na.rm = TRUE), auto_date = auto_date[1], phase = phase[1]),
           by = .(code_city, date)]
  nan2na(cd, cdv)
  mfs <- as.data.table(read_dta(file.path(base, "mask_filter_search.dta")))
  mfs[, date := sday(date)]
  for (v in c("filter", "pmmask", "code_city")) set(mfs, j = v, value = num(mfs[[v]]))
  cd <- merge(cd, mfs, by = c("code_city", "date"))
  cd <- cd[!is.na(auto_date)]
  cd[, dd := sd2date(date)]
  cd[, year := as.integer(format(dd, "%Y"))]
  cd[, month := as.integer(format(dd, "%m"))]
  cd[, n_month := ((year - 1960L) * 12L + month - 1L) - mofd(auto_date)]
  setorder(cd, code_city, n_month, date)
  scm <- cd[, .(pm10 = mean(pm10, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE),
                rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
                temp = mean(temp, na.rm = TRUE), filter = mean(filter, na.rm = TRUE),
                pmmask = mean(pmmask, na.rm = TRUE), year = year[1], month = month[1],
                auto_date = auto_date[1], phase = phase[1]),
            by = .(code_city, n_month)]
  nan2na(scm, c("pm10", "wind_speed", "rh", "rain", "temp", "filter", "pmmask"))
  scm
}, error = function(e) { message("Search data error: ", conditionMessage(e)); NULL })

if (!is.null(search_ok)) {
  scm <- search_ok
  safe("rd_face_mask_searches_controls_table2_panelA_col2", {
    scm[, resid_pmmask_smw := resid_fe(scm, "pmmask", "code_city + month")]
    rd_est(scm$resid_pmmask_smw, scm$n_month, scm$code_city, "pmmask resid all")
  })
  safe("rd_air_filter_searches_controls_table2_panelA_col2", {
    scm[, resid_filter_smw := resid_fe(scm, "filter", "code_city + month")]
    rd_est(scm$resid_filter_smw, scm$n_month, scm$code_city, "filter resid all")
  })
} else {
  results[["rd_face_mask_searches_controls_table2_panelA_col2"]] <- NA_real_
  results[["rd_air_filter_searches_controls_table2_panelA_col2"]] <- NA_real_
}

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
out_names <- c(
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
for (nm in out_names) {
  v <- results[[nm]]
  if (is.null(v) || length(v) == 0) v <- NA_real_
  cat(sprintf("RESULT:%s=%s\n", nm, format(as.numeric(v), digits = 10)))
}
