suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"
read_d <- function(f) {
  x <- haven::read_dta(file.path(base, f))
  x <- haven::zap_labels(x)
  x <- haven::zap_formats(x)
  as.data.table(x)
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.character(x)) {
    out <- suppressWarnings(as.Date(lubridate::parse_date_time(x, orders = c("Ymd", "Y-m-d", "dmY", "mdY", "Ymd HMS"))))
    return(out)
  }
  x <- as.numeric(x)
  mx <- suppressWarnings(max(x, na.rm = TRUE))
  if (is.finite(mx) && mx > 1e9) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
  if (is.finite(mx) && mx > 19000000) return(as.Date(as.character(x), format = "%Y%m%d"))
  as.Date(x, origin = "1960-01-01")
}

out <- list()
safe <- function(name, expr) {
  v <- tryCatch(expr, error = function(e) { message("Error in ", name, ": ", conditionMessage(e)); NA_real_ })
  out[[name]] <<- as.numeric(v)[1]
  message(name, " = ", out[[name]])
}

rd_fun <- function(y, x, cl) {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, kernel = "triangular", bwselect = "mserd",
                cluster = cl[ok], vce = "hc1")
  message("  h = ", paste(round(r$bws[1, ], 2), collapse = "/"), ", N = ", sum(r$N_h))
  as.numeric(r$coef[1, 1])
}

wvars <- c("temp", "rain", "rh", "wind_speed")

# ---------------- Station list ----------------
stl <- read_d("station_list.dta")
stl[, station_n := as.character(pm10_n)]
stl[, code_city := as.character(code_city)]
stl[, auto := to_date(auto_date)]
stl[, phase := suppressWarnings(as.numeric(phase))]
if (all(is.na(stl$phase)) || !all(stl$phase %in% c(1, 2))) {
  stl[, phase := ifelse(auto <= as.Date("2013-01-01"), 1, 2)]
}
stl[, deadline := (phase == 1 & auto == as.Date("2013-01-01")) | (phase == 2 & auto == as.Date("2014-01-01"))]
stl[, lon := as.numeric(station_lon)]
stl[, lat := as.numeric(station_lat)]

# ---------------- Daily pollution + weather ----------------
pol <- read_d("pollution_1116.dta")
pol <- pol[, .(station_n = as.character(station_n), date = to_date(date), pm10 = as.numeric(pm10))]
wea <- read_d("weather_1116.dta")
wea <- wea[, .(station_n = as.character(station_n), date = to_date(date),
               temp = as.numeric(temp), rain = as.numeric(rain),
               rh = as.numeric(rh), wind_speed = as.numeric(wind_speed))]
wea <- unique(wea, by = c("station_n", "date"))
d <- merge(pol, wea, by = c("station_n", "date"), all.x = TRUE)
rm(pol, wea); gc()
d <- merge(d, stl[, .(station_n, code_city, phase, auto, deadline)], by = "station_n")
d[, year := as.integer(format(date, "%Y"))]
d[, month := as.integer(format(date, "%m"))]
d <- d[year >= 2011 & year <= 2016]
d[, run := as.numeric(date - auto)]
d[, ym := year * 100L + month]

# ---------------- Table 1 Panel A ----------------
d1 <- d[!is.na(pm10) & !is.na(run)]
message("Col1 obs: ", nrow(d1))
safe("rd_pm_daily_no_controls_table1_panelA_col1", rd_fun(d1$pm10, d1$run, d1$code_city))
rm(d1); gc()

dc <- d[!is.na(pm10) & !is.na(run) & complete.cases(d[, ..wvars])]
mres <- feols(pm10 ~ temp + rain + rh + wind_speed | station_n + month, data = dc)
dc[, res := pm10 - predict(mres, newdata = dc)]
rm(mres); gc()
safe("rd_pm_daily_controls_table1_panelA_col2", rd_fun(dc$res, dc$run, dc$code_city))
s <- dc[phase == 1]
safe("rd_pm_daily_wave1_table1_panelA_col3", rd_fun(s$res, s$run, s$code_city))
s <- dc[phase == 2]
safe("rd_pm_daily_wave2_table1_panelA_col4", rd_fun(s$res, s$run, s$code_city))
s <- dc[deadline == TRUE]
safe("rd_pm_daily_deadline_table1_panelA_col5", rd_fun(s$res, s$run, s$code_city))
rm(s, dc); gc()

# ---------------- AOD (monthly) ----------------
safe("rd_aod_monthly_controls_table1_panelA_col2", {
  aod <- read_d("aod_month.dta")
  aod <- aod[, .(station_n = as.character(pm10_n), year = as.integer(year),
                 month = as.integer(month), aod = as.numeric(aod))]
  wm <- d[, lapply(.SD, function(z) mean(z, na.rm = TRUE)), by = .(station_n, year, month), .SDcols = wvars]
  aod <- merge(aod, wm, by = c("station_n", "year", "month"), all.x = TRUE)
  aod <- merge(aod, stl[, .(station_n, code_city, auto)], by = "station_n")
  aod[, run := (year * 12 + month) - (as.integer(format(auto, "%Y")) * 12 + as.integer(format(auto, "%m")))]
  aod <- aod[is.finite(aod) & is.finite(run) & complete.cases(aod[, ..wvars])]
  ma <- feols(aod ~ temp + rain + rh + wind_speed | station_n + month, data = aod)
  aod[, res := aod - predict(ma, newdata = aod)]
  rd_fun(aod$res, aod$run, aod$code_city)
})

# ---------------- Table 1 Panel B: event study ----------------
es <- d[deadline == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es[, treat := as.integer(phase == 1)]
es[, m := (year - 2013L) * 12L + month - 1L]
es[, `:=`(
  b712 = treat * as.integer(m >= -12 & m <= -7),
  b56  = treat * as.integer(m >= -6 & m <= -5),
  b34  = treat * as.integer(m >= -4 & m <= -3),
  a12  = treat * as.integer(m >= 0 & m <= 1),
  a34  = treat * as.integer(m >= 2 & m <= 3),
  a56  = treat * as.integer(m >= 4 & m <= 5),
  a712 = treat * as.integer(m >= 6 & m <= 11)
)]
es <- es[!is.na(pm10)]
f_rhs <- "b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rain + rh + wind_speed"

m1 <- tryCatch(feols(as.formula(paste("pm10 ~", f_rhs, "| station_n + month")), data = es, cluster = ~code_city),
               error = function(e) NULL)
safe("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", coef(m1)["a12"])
m2 <- tryCatch(feols(as.formula(paste("pm10 ~", f_rhs, "| station_n + ym")), data = es, cluster = ~code_city),
               error = function(e) NULL)
safe("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", coef(m2)["a12"])
safe("n_obs_table1_panelB_deadline_cols1_2", nobs(m1))

# Matching: each Wave-1 deadline station to nearest Wave-2 deadline station (with replacement)
hav <- function(lon1, lat1, lon2, lat2) {
  r <- pi / 180
  dlat <- (lat2 - lat1) * r; dlon <- (lon2 - lon1) * r
  a <- sin(dlat / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}
tr <- stl[deadline == TRUE & phase == 1 & station_n %in% unique(es$station_n)]
ct <- stl[deadline == TRUE & phase == 2 & station_n %in% unique(es$station_n)]
pairs <- tr[, .(pair = seq_len(.N), station_n,
                ctrl = vapply(seq_len(.N), function(i) ct$station_n[which.min(hav(lon[i], lat[i], ct$lon, ct$lat))], ""))]
mt_t <- merge(es, pairs[, .(station_n, pair)], by = "station_n")
mt_c <- merge(es, pairs[, .(station_n = ctrl, pair)], by = "station_n", allow.cartesian = TRUE)
mt <- rbind(mt_t, mt_c)
rm(mt_t, mt_c); gc()

m3 <- tryCatch(feols(as.formula(paste("pm10 ~", f_rhs, "| station_n + month")), data = mt, cluster = ~code_city),
               error = function(e) NULL)
safe("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", coef(m3)["a12"])
mt_l <- mt[pm10 > 0]
mt_l[, lpm := log(pm10)]
m5 <- tryCatch(feols(as.formula(paste("lpm ~", f_rhs, "| station_n + ym")), data = mt_l, cluster = ~code_city),
               error = function(e) NULL)
safe("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", coef(m5)["a12"])
rm(mt, mt_l, es); gc()

# ---------------- Searches (monthly, city level) ----------------
city_month <- NULL
tryCatch({
  ms <- read_d("mask_filter_search.dta")
  ms[, code_city := as.character(code_city)]
  rawd <- ms$date
  if (is.numeric(rawd) && !inherits(rawd, "Date") && suppressWarnings(max(rawd, na.rm = TRUE)) < 1500) {
    ms[, year := 1960L + as.integer(rawd) %/% 12L]
    ms[, month := as.integer(rawd) %% 12L + 1L]
  } else {
    dd <- to_date(rawd)
    ms[, year := as.integer(format(dd, "%Y"))]
    ms[, month := as.integer(format(dd, "%m"))]
  }
  ms <- ms[code_city %in% unique(stl$code_city) & year >= 2011 & year <= 2016]
  ms <- ms[, .(mask = mean(as.numeric(pmmask), na.rm = TRUE),
               filter = mean(as.numeric(filter), na.rm = TRUE)), by = .(code_city, year, month)]
  wc <- d[, lapply(.SD, function(z) mean(z, na.rm = TRUE)), by = .(code_city, year, month), .SDcols = wvars]
  ms <- merge(ms, wc, by = c("code_city", "year", "month"), all.x = TRUE)
  ca <- unique(stl[, .(code_city, auto)], by = "code_city")
  ms <- merge(ms, ca, by = "code_city")
  ms[, run := (year * 12 + month) - (as.integer(format(auto, "%Y")) * 12 + as.integer(format(auto, "%m")))]
  city_month <- ms
}, error = function(e) message("search data error: ", conditionMessage(e)))

rd_search <- function(v) {
  s <- city_month[is.finite(get(v)) & is.finite(run) & complete.cases(city_month[, ..wvars])]
  s[, y := get(v)]
  ms_m <- feols(y ~ temp + rain + rh + wind_speed | code_city + month, data = s)
  s[, res := y - predict(ms_m, newdata = s)]
  message(v, " obs: ", nrow(s))
  rd_fun(s$res, s$run, s$code_city)
}
safe("rd_face_mask_searches_controls_table2_panelA_col2", rd_search("mask"))
safe("rd_air_filter_searches_controls_table2_panelA_col2", rd_search("filter"))

# ---------------- Output ----------------
for (nm in names(out)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(out[[nm]], digits = 10)))
}