suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
  library(lubridate)
})

set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) {
    x <- as.numeric(zap_labels(x))
    med <- median(x, na.rm = TRUE)
    if (is.na(med)) return(as.Date(x, origin = "1960-01-01"))
    if (med > 1e11) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    if (med > 1e7 && med < 1e8) return(as.Date(as.character(as.integer(x)), format = "%Y%m%d"))
    return(as.Date(x, origin = "1960-01-01"))
  }
  x <- as.character(x)
  d <- suppressWarnings(as.Date(parse_date_time(x, orders = c("ymd", "dmy", "mdy", "Ymd HMS"))))
  d
}

results <- list()
emit <- function(name, val) {
  results[[name]] <<- val
}

run_rd <- function(y, x, cl) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  y <- y[ok]; x <- x[ok]; cl <- as.integer(factor(cl[ok]))
  r <- tryCatch(
    rdrobust(y = y, x = x, c = 0, kernel = "triangular", bwselect = "mserd",
             cluster = cl, masspoints = "off"),
    error = function(e) rdrobust(y = y, x = x, c = 0, kernel = "triangular",
                                 bwselect = "mserd", cluster = cl))
  as.numeric(r$coef[1])
}

resid_fe <- function(dt, yvar, fe) {
  f <- as.formula(paste(yvar, "~ temp + rain + rh + wind_speed |", fe))
  m <- feols(f, data = dt, notes = FALSE, warn = FALSE)
  r <- tryCatch(resid(m, na.rm = FALSE), error = function(e) NULL)
  if (is.null(r) || length(r) != nrow(dt)) {
    r <- rep(NA_real_, nrow(dt))
    r[obs(m)] <- resid(m)
  }
  as.numeric(r)
}

# ---------------- Station list ----------------
st <- as.data.table(read_dta(file.path(base, "station_list.dta")))
st <- as.data.table(lapply(st, function(v) if (is.labelled(v)) zap_labels(v) else v))
setnames(st, "pm10_n", "station_n")
st[, station_n := as.character(station_n)]
st[, auto_date := to_date(auto_date)]
st[, phase := as.numeric(phase)]
st[, code_city := as.character(code_city)]
st <- st[phase %in% c(1, 2)]
st[, deadline := (phase == 1 & auto_date == as.Date("2013-01-01")) |
                  (phase == 2 & auto_date == as.Date("2014-01-01"))]

# ---------------- Daily pollution + weather ----------------
pol <- as.data.table(read_dta(file.path(base, "pollution_1116.dta")))
pol <- as.data.table(lapply(pol, function(v) if (is.labelled(v)) zap_labels(v) else v))
pol[, station_n := as.character(station_n)]
pol[, date := to_date(date)]
pol <- pol[, .(station_n, date, pm10 = as.numeric(pm10))]

wea <- as.data.table(read_dta(file.path(base, "weather_1116.dta")))
wea <- as.data.table(lapply(wea, function(v) if (is.labelled(v)) zap_labels(v) else v))
wea[, station_n := as.character(station_n)]
wea[, date := to_date(date)]
wea <- wea[, .(station_n, date, temp = as.numeric(temp), rain = as.numeric(rain),
               rh = as.numeric(rh), wind_speed = as.numeric(wind_speed))]
wea <- unique(wea, by = c("station_n", "date"))

d <- merge(pol, st[, .(station_n, code_city, phase, auto_date, deadline, station_lon, station_lat)],
           by = "station_n")
d <- merge(d, wea, by = c("station_n", "date"), all.x = TRUE)
d <- d[!is.na(pm10) & !is.na(date)]
d[, x := as.numeric(date - auto_date)]
d[, moy := month(date)]
d[, ym := year(date) * 100 + month(date)]

# Column 1: no controls
emit("rd_pm_daily_no_controls_table1_panelA_col1",
     tryCatch(run_rd(d$pm10, d$x, d$code_city), error = function(e) NA_real_))

# Columns 2-5: residualized within each sample
rd_resid <- function(sub) {
  sub <- copy(sub)
  sub[, res := resid_fe(sub, "pm10", "station_n + moy")]
  run_rd(sub$res, sub$x, sub$code_city)
}
emit("rd_pm_daily_controls_table1_panelA_col2",
     tryCatch(rd_resid(d), error = function(e) NA_real_))
emit("rd_pm_daily_wave1_table1_panelA_col3",
     tryCatch(rd_resid(d[phase == 1]), error = function(e) NA_real_))
emit("rd_pm_daily_wave2_table1_panelA_col4",
     tryCatch(rd_resid(d[phase == 2]), error = function(e) NA_real_))
emit("rd_pm_daily_deadline_table1_panelA_col5",
     tryCatch(rd_resid(d[deadline == TRUE]), error = function(e) NA_real_))

# ---------------- AOD monthly ----------------
wea_m <- copy(wea)
wea_m[, `:=`(year = year(date), month = month(date))]
wea_m <- wea_m[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
                   rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
               by = .(station_n, year, month)]
for (v in c("temp", "rain", "rh", "wind_speed")) set(wea_m, which(is.nan(wea_m[[v]])), v, NA_real_)

aod_val <- tryCatch({
  aod <- as.data.table(read_dta(file.path(base, "aod_month.dta")))
  aod <- as.data.table(lapply(aod, function(v) if (is.labelled(v)) zap_labels(v) else v))
  setnames(aod, "pm10_n", "station_n")
  aod[, station_n := as.character(station_n)]
  aod[, `:=`(year = as.integer(year), month = as.integer(month), aod = as.numeric(aod))]
  aod <- merge(aod, st[, .(station_n, code_city, auto_date)], by = "station_n")
  aod <- merge(aod, wea_m, by = c("station_n", "year", "month"), all.x = TRUE)
  aod <- aod[!is.na(aod)]
  aod[, x := (year * 12 + month) - (year(auto_date) * 12 + month(auto_date))]
  aod[, res := resid_fe(aod, "aod", "station_n + month")]
  run_rd(aod$res, aod$x, aod$code_city)
}, error = function(e) NA_real_)
emit("rd_aod_monthly_controls_table1_panelA_col2", aod_val)

# ---------------- Event study ----------------
es <- d[deadline == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es[, treat := as.integer(phase == 1)]
es[, rm := (year(date) - 2013) * 12 + month(date) - 1]
es[, `:=`(
  D_b712 = treat * as.integer(rm >= -12 & rm <= -7),
  D_b56  = treat * as.integer(rm >= -6 & rm <= -5),
  D_b34  = treat * as.integer(rm >= -4 & rm <= -3),
  D_a12  = treat * as.integer(rm >= 0 & rm <= 1),
  D_a34  = treat * as.integer(rm >= 2 & rm <= 3),
  D_a56  = treat * as.integer(rm >= 4 & rm <= 5),
  D_a712 = treat * as.integer(rm >= 6 & rm <= 11)
)]
es[, lpm10 := ifelse(pm10 > 0, log(pm10), NA_real_)]
rhs <- "D_b712 + D_b56 + D_b34 + D_a12 + D_a34 + D_a56 + D_a712 + temp + rain + rh + wind_speed"

m1 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = es,
                     cluster = ~code_city, notes = FALSE, warn = FALSE), error = function(e) NULL)
m2 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es,
                     cluster = ~code_city, notes = FALSE, warn = FALSE), error = function(e) NULL)
emit("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1",
     if (is.null(m1)) NA_real_ else unname(coef(m1)["D_a12"]))
emit("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2",
     if (is.null(m2)) NA_real_ else unname(coef(m2)["D_a12"]))

# Matched sample: nearest Wave-2 deadline station for each Wave-1 deadline station
matched <- tryCatch({
  sl <- unique(st[deadline == TRUE & station_n %in% unique(es$station_n),
                  .(station_n, phase, lon = as.numeric(station_lon), lat = as.numeric(station_lat))])
  tr <- sl[phase == 1]; co <- sl[phase == 2]
  hav <- function(lon1, lat1, lon2, lat2) {
    r <- pi / 180
    a <- sin((lat2 - lat1) * r / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin((lon2 - lon1) * r / 2)^2
    2 * 6371 * asin(pmin(1, sqrt(a)))
  }
  nn <- sapply(seq_len(nrow(tr)), function(i) {
    which.min(hav(tr$lon[i], tr$lat[i], co$lon, co$lat))
  })
  pairs <- data.table(pair = seq_len(nrow(tr)), t = tr$station_n, c = co$station_n[nn])
  long <- rbind(pairs[, .(pair, station_n = t)], pairs[, .(pair, station_n = c)])
  merge(long, es, by = "station_n", allow.cartesian = TRUE)
}, error = function(e) NULL)

m3 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = matched,
                     cluster = ~code_city, notes = FALSE, warn = FALSE), error = function(e) NULL)
m5 <- tryCatch(feols(as.formula(paste("lpm10 ~", rhs, "| station_n + ym")), data = matched,
                     cluster = ~code_city, notes = FALSE, warn = FALSE), error = function(e) NULL)
emit("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3",
     if (is.null(m3)) NA_real_ else unname(coef(m3)["D_a12"]))
emit("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5",
     if (is.null(m5)) NA_real_ else unname(coef(m5)["D_a12"]))
emit("n_obs_table1_panelB_deadline_cols1_2",
     if (is.null(m1)) NA_real_ else nobs(m1))

# ---------------- Baidu searches (monthly city panel) ----------------
search_res <- tryCatch({
  ms <- as.data.table(read_dta(file.path(base, "mask_filter_search.dta")))
  ms <- as.data.table(lapply(ms, function(v) if (is.labelled(v)) zap_labels(v) else v))
  ms[, date := to_date(date)]
  ms[, code_city := as.character(code_city)]
  ms[, `:=`(year = year(date), month = month(date))]
  ms <- ms[year >= 2011 & year <= 2016]
  ms <- ms[, .(mask = if (all(is.na(pmmask))) NA_real_ else mean(as.numeric(pmmask), na.rm = TRUE),
               filter = if (all(is.na(filter))) NA_real_ else mean(as.numeric(filter), na.rm = TRUE)),
           by = .(code_city, year, month)]
  city_auto <- unique(st[, .(code_city, auto_date)], by = "code_city")
  ms <- merge(ms, city_auto, by = "code_city")
  wc <- merge(wea_m, st[, .(station_n, code_city)], by = "station_n")
  wc <- wc[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
           by = .(code_city, year, month)]
  for (v in c("temp", "rain", "rh", "wind_speed")) set(wc, which(is.nan(wc[[v]])), v, NA_real_)
  ms <- merge(ms, wc, by = c("code_city", "year", "month"), all.x = TRUE)
  ms[, x := (year * 12 + month) - (year(auto_date) * 12 + month(auto_date))]
  mk <- ms[!is.na(mask)]
  mk[, res := resid_fe(mk, "mask", "code_city + month")]
  b_mask <- tryCatch(run_rd(mk$res, mk$x, mk$code_city), error = function(e) NA_real_)
  fl <- ms[!is.na(filter)]
  fl[, res := resid_fe(fl, "filter", "code_city + month")]
  b_filter <- tryCatch(run_rd(fl$res, fl$x, fl$code_city), error = function(e) NA_real_)
  c(b_mask, b_filter)
}, error = function(e) c(NA_real_, NA_real_))
emit("rd_face_mask_searches_controls_table2_panelA_col2", search_res[1])
emit("rd_air_filter_searches_controls_table2_panelA_col2", search_res[2])

# ---------------- Output ----------------
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(results[[nm]], digits = 10)))
}