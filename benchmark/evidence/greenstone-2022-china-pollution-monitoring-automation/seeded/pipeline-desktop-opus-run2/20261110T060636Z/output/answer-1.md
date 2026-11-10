suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"

results <- list()
add_result <- function(name, val) {
  results[[name]] <<- val
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  as.Date(as.numeric(x), origin = "1960-01-01")
}
read_d <- function(f) {
  d <- read_dta(file.path(base, f))
  d <- zap_labels(d)
  as.data.table(d)
}
nan_to_na <- function(dt, cols) {
  for (v in cols) set(dt, which(is.nan(dt[[v]])), v, NA_real_)
  invisible(dt)
}

d13 <- as.Date("2013-01-01")  # Stata 19359
d14 <- as.Date("2014-01-01")  # Stata 19724

# ---------------------------------------------------------------------------
# Build station_day_1116
# ---------------------------------------------------------------------------
pol <- read_d("pollution_1116.dta")
wea <- read_d("weather_1116.dta")
sl  <- read_d("station_list.dta")

pol[, date := to_date(date)]
wea[, date := to_date(date)]
pol[, `:=`(station_n = as.numeric(station_n), code_city = as.numeric(code_city))]
wea[, station_n := as.numeric(station_n)]
wea_cols <- setdiff(names(wea), c("station_n", "date", "code_city"))
wea <- wea[, c("station_n", "date", wea_cols), with = FALSE]

sd <- merge(pol, wea, by = c("station_n", "date"), all = TRUE)
rm(pol, wea); gc()
setnames(sd, "station_n", "pm10_n")

sl[, `:=`(pm10_n = as.numeric(pm10_n), auto_date = to_date(auto_date),
          phase = as.numeric(phase), code_city = as.numeric(code_city),
          station_lat = as.numeric(station_lat), station_lon = as.numeric(station_lon))]
sd <- merge(sd, sl[, .(pm10_n, auto_date, phase)], by = "pm10_n", all.x = TRUE)

for (v in c("pm10", "no2", "so2", "wind_speed", "rh", "rain", "temp")) {
  if (v %in% names(sd)) set(sd, j = v, value = as.numeric(sd[[v]]))
}

sd[, T := as.numeric(date - auto_date)]
sd[, year := as.integer(format(date, "%Y"))]
sd[, month := as.integer(format(date, "%m"))]

run_rd <- function(y, x, cl) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, q = 2, kernel = "triangular",
                bwselect = "mserd", vce = "hc1", cluster = cl[ok], masspoints = "off")
  as.numeric(r$coef[1])
}

# ---------------------------------------------------------------------------
# Table 1A, row 1: daily PM10 RD
# ---------------------------------------------------------------------------
tryCatch({
  m_res <- feols(pm10 ~ wind_speed + rain + temp + rh | pm10_n + month, data = sd,
                 fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  sd[, resid_pm10_smw := resid(m_res, na.rm = FALSE)]
  rm(m_res); gc()
}, error = function(e) message("resid pm10 error: ", conditionMessage(e)))

wok <- !is.na(sd$temp) & !is.na(sd$rain) & !is.na(sd$rh) & !is.na(sd$wind_speed)

tryCatch({
  add_result("rd_pm_daily_no_controls_table1_panelA_col1",
             run_rd(sd$pm10[wok], sd$T[wok], sd$code_city[wok]))
}, error = function(e) message("col1 error: ", conditionMessage(e)))

tryCatch({
  add_result("rd_pm_daily_controls_table1_panelA_col2",
             run_rd(sd$resid_pm10_smw, sd$T, sd$code_city))
}, error = function(e) message("col2 error: ", conditionMessage(e)))

tryCatch({
  s <- which(sd$phase == 1)
  add_result("rd_pm_daily_wave1_table1_panelA_col3",
             run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s]))
}, error = function(e) message("col3 error: ", conditionMessage(e)))

tryCatch({
  s <- which(sd$phase == 2)
  add_result("rd_pm_daily_wave2_table1_panelA_col4",
             run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s]))
}, error = function(e) message("col4 error: ", conditionMessage(e)))

tryCatch({
  s <- which(sd$auto_date == d13 | sd$auto_date == d14)
  add_result("rd_pm_daily_deadline_table1_panelA_col5",
             run_rd(sd$resid_pm10_smw[s], sd$T[s], sd$code_city[s]))
}, error = function(e) message("col5 error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 1A, row 2: monthly AOD RD (station_month)
# ---------------------------------------------------------------------------
tryCatch({
  mean_vars <- intersect(c("pm10", "no2", "so2", "wind_speed", "rh", "rain", "temp"), names(sd))
  sm <- sd[, lapply(.SD, mean, na.rm = TRUE), by = .(pm10_n, year, month), .SDcols = mean_vars]
  nan_to_na(sm, mean_vars)
  info <- sd[, .(code_city = code_city[1], auto_date = auto_date[1], phase = phase[1]),
             by = .(pm10_n, year, month)]
  sm <- merge(sm, info, by = c("pm10_n", "year", "month"))
  sm[, auto_y := as.integer(format(auto_date, "%Y"))]
  sm[, auto_m := as.integer(format(auto_date, "%m"))]
  sm[, n_month := (year * 12L + month) - (auto_y * 12L + auto_m)]
  aod <- read_d("aod_month.dta")
  aod[, `:=`(pm10_n = as.numeric(pm10_n), year = as.integer(year), month = as.integer(month),
             aod = as.numeric(aod))]
  sm <- merge(sm, aod[, .(pm10_n, year, month, aod)], by = c("pm10_n", "year", "month"))
  m_aod <- feols(aod ~ wind_speed + rain + temp + rh | pm10_n + month, data = sm,
                 fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  sm[, resid_aod_smw := resid(m_aod, na.rm = FALSE)]
  add_result("rd_aod_monthly_controls_table1_panelA_col2",
             run_rd(sm$resid_aod_smw, sm$n_month, sm$code_city))
}, error = function(e) message("aod error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Table 1B: event study
# ---------------------------------------------------------------------------
add_es <- function(dt) {
  dt[, treat := as.integer(auto_date == d13)]
  dt[, m12_before2 := as.integer(year == 2012 & month >= 11 & month <= 12)]
  dt[, m34_before2 := as.integer(year == 2012 & month >= 9 & month <= 10)]
  dt[, m56_before2 := as.integer(year == 2012 & month >= 7 & month <= 8)]
  dt[, m712_before2 := as.integer(year == 2012 & month >= 1 & month <= 6)]
  dt[, m12_after2 := as.integer(year == 2013 & month >= 1 & month <= 2)]
  dt[, m34_after2 := as.integer(year == 2013 & month >= 3 & month <= 4)]
  dt[, m56_after2 := as.integer(year == 2013 & month >= 5 & month <= 6)]
  dt[, m712_after2 := as.integer(year == 2013 & month >= 7 & month <= 12)]
  for (v in c("12", "34", "56", "712")) {
    dt[, paste0("treat_m", v, "_before2") := treat * get(paste0("m", v, "_before2"))]
    dt[, paste0("treat_m", v, "_after2") := treat * get(paste0("m", v, "_after2"))]
  }
  dt[, year_month := year * 100L + month]
  dt
}
es_rhs <- "treat_m712_before2 + treat_m56_before2 + treat_m34_before2 + treat_m12_after2 + treat_m34_after2 + treat_m56_after2 + treat_m712_after2 + wind_speed + rain + temp + rh"

sd1213 <- sd[year >= 2012 & year <= 2013]

tryCatch({
  es <- copy(sd1213[auto_date == d13 | auto_date == d14])
  es <- add_es(es)
  m1 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = es,
              cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  add_result("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1",
             unname(coef(m1)["treat_m12_after2"]))
  add_result("n_obs_table1_panelB_deadline_cols1_2", nobs(m1))
  m2 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + year_month")), data = es,
              cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  add_result("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2",
             unname(coef(m2)["treat_m12_after2"]))
}, error = function(e) message("event study error: ", conditionMessage(e)))

# Matched sample: nearest Wave-2 deadline station for each Wave-1 deadline station (<=400km)
tryCatch({
  tr <- sl[auto_date == d13]
  ct <- sl[auto_date == d14]
  hav <- function(lat1, lon1, lat2, lon2) {
    rad <- pi / 180
    dlat <- (lat2 - lat1) * rad
    dlon <- (lon2 - lon1) * rad
    a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
    2 * 6371.0088 * asin(pmin(1, sqrt(a)))
  }
  mt <- rbindlist(lapply(seq_len(nrow(tr)), function(i) {
    dd <- hav(tr$station_lat[i], tr$station_lon[i], ct$station_lat, ct$station_lon)
    j <- which.min(dd)
    data.table(pm10_n1 = tr$pm10_n[i], pm10_n = ct$pm10_n[j], km = dd[j])
  }))
  mt <- mt[km <= 400]
  tr_days <- sd1213[pm10_n %in% unique(mt$pm10_n1)]
  ct_days <- merge(sd1213, mt[, .(pm10_n)], by = "pm10_n", allow.cartesian = TRUE)
  mm <- rbindlist(list(tr_days, ct_days), use.names = TRUE, fill = TRUE)
  mm[, l_pm10 := ifelse(!is.na(pm10) & pm10 > 0, log(pm10), NA_real_)]
  mm <- add_es(mm)
  m3 <- feols(as.formula(paste("pm10 ~", es_rhs, "| pm10_n + month")), data = mm,
              cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  add_result("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3",
             unname(coef(m3)["treat_m12_after2"]))
  m5 <- feols(as.formula(paste("l_pm10 ~", es_rhs, "| pm10_n + year_month")), data = mm,
              cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  add_result("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5",
             unname(coef(m5)["treat_m12_after2"]))
}, error = function(e) message("matched event study error: ", conditionMessage(e)))

rm(sd1213); gc()

# ---------------------------------------------------------------------------
# Table 2A (NBER Table 3): city-month Baidu searches RD
# ---------------------------------------------------------------------------
tryCatch({
  cvars <- intersect(c("pm10", "no2", "so2", "wind_speed", "rh", "rain", "temp"), names(sd))
  cd <- sd[, lapply(.SD, mean, na.rm = TRUE), by = .(code_city, date), .SDcols = cvars]
  nan_to_na(cd, cvars)
  cad <- sd[, .(auto_date = if (all(is.na(auto_date))) as.Date(NA) else max(auto_date, na.rm = TRUE)),
            by = .(code_city, date)]
  cd <- merge(cd, cad, by = c("code_city", "date"))
  ms <- read_d("mask_filter_search.dta")
  ms[, `:=`(date = to_date(date), code_city = as.numeric(code_city),
            filter = as.numeric(filter), pmmask = as.numeric(pmmask))]
  cd <- merge(cd, ms[, .(code_city, date, filter, pmmask)], by = c("code_city", "date"))
  cd[, year := as.integer(format(date, "%Y"))]
  cd[, month := as.integer(format(date, "%m"))]
  cd[, n_month := (year * 12L + month) -
         (as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m")))]
  avars <- c(cvars, "filter", "pmmask")
  cm <- cd[, c(lapply(.SD, mean, na.rm = TRUE)), by = .(code_city, n_month), .SDcols = avars]
  nan_to_na(cm, avars)
  cinfo <- cd[order(code_city, date), .(year = year[1], month = month[1], auto_date = auto_date[1]),
              by = .(code_city, n_month)]
  cm <- merge(cm, cinfo, by = c("code_city", "n_month"))

  for (y in c("pmmask", "filter")) {
    mr <- feols(as.formula(paste(y, "~ wind_speed + rain + temp + rh | code_city + month")),
                data = cm, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
    cm[, resid_y := resid(mr, na.rm = FALSE)]
    est <- run_rd(cm$resid_y, cm$n_month, cm$code_city)
    if (y == "pmmask") add_result("rd_face_mask_searches_controls_table2_panelA_col2", est)
    if (y == "filter") add_result("rd_air_filter_searches_controls_table2_panelA_col2", est)
  }
}, error = function(e) message("search RD error: ", conditionMessage(e)))

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
for (nm in names(results)) {
  v <- results[[nm]]
  if (!is.null(v) && length(v) == 1 && is.finite(v)) {
    cat(sprintf("RESULT:%s=%s\n", nm, format(v, digits = 10, scientific = FALSE)))
  }
}
