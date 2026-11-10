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
  d <- haven::zap_labels(haven::zap_formats(d))
  as.data.table(d)
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.character(x)) {
    d <- suppressWarnings(as.Date(x))
    if (all(is.na(d))) d <- suppressWarnings(as.Date(x, format = "%Y%m%d"))
    return(d)
  }
  x <- as.numeric(x)
  med <- median(x, na.rm = TRUE)
  if (is.finite(med) && med > 1e7 && med < 1e8) {
    # possibly YYYYMMDD
    return(as.Date(as.character(as.integer(x)), format = "%Y%m%d"))
  }
  if (is.finite(med) && med > 1e9) x <- floor(x / 86400000)
  as.Date(x, origin = "1960-01-01")
}

results <- list()
put <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v[1])) v <- NA
  results[[name]] <<- v[1]
}

rd_coef <- function(y, x, cl) {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  clf <- as.integer(factor(cl[ok]))
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, kernel = "triangular",
                bwselect = "mserd", cluster = clf)
  as.numeric(r$coef[1])
}

## ---------------- Load data ----------------
city_info <- rd_dta("city_info.dta")
city_info[, code_city := as.character(code_city)]
station_list <- rd_dta("station_list.dta")
station_list[, code_city := as.character(code_city)]
station_list[, auto_date := to_date(auto_date)]
station_list[, pm10_n := as.character(pm10_n)]

city_auto <- station_list[, .(auto_date = min(auto_date, na.rm = TRUE)), by = code_city]
city_auto <- merge(city_auto, city_info[, .(code_city, phase)], by = "code_city", all.x = TRUE)
if (any(is.na(city_auto$phase))) {
  ph2 <- station_list[, .(phase2 = phase[1]), by = code_city]
  city_auto <- merge(city_auto, ph2, by = "code_city", all.x = TRUE)
  city_auto[is.na(phase), phase := phase2]
  city_auto[, phase2 := NULL]
}
city_auto[, phase := as.numeric(phase)]
city_auto[, deadline := (phase == 1 & auto_date == as.Date("2013-01-01")) |
                        (phase == 2 & auto_date == as.Date("2014-01-01"))]

poll <- rd_dta("pollution_1116.dta")
poll[, code_city := as.character(code_city)]
poll[, station_n := as.character(station_n)]
poll[, date := to_date(date)]
poll <- poll[, .(station_n, code_city, date, pm10 = as.numeric(pm10))]

weather <- rd_dta("weather_1116.dta")
weather[, station_n := as.character(station_n)]
weather[, date := to_date(date)]
weather <- weather[, .(station_n, date, temp = as.numeric(temp), rain = as.numeric(rain),
                       rh = as.numeric(rh), wind_speed = as.numeric(wind_speed))]
weather <- unique(weather, by = c("station_n", "date"))

poll <- merge(poll, weather, by = c("station_n", "date"), all.x = TRUE)
poll <- merge(poll, city_auto, by = "code_city")
poll <- poll[phase %in% c(1, 2)]
poll[, t := as.numeric(date - auto_date)]
poll[, year := as.integer(format(date, "%Y"))]
poll[, month := as.integer(format(date, "%m"))]
poll[, ym := year * 12L + month]

## stations with PM10 data both before and after automation
poll <- poll[!is.na(pm10)]
st_ok <- poll[, .(pre = any(t < 0), post = any(t >= 0)), by = station_n][pre & post, station_n]
poll <- poll[station_n %in% st_ok]

## ---------------- Table 1 Panel A: RD ----------------
tryCatch(put("rd_pm_daily_no_controls_table1_panelA_col1",
             rd_coef(poll$pm10, poll$t, poll$code_city)),
         error = function(e) { message("col1: ", conditionMessage(e)); put("rd_pm_daily_no_controls_table1_panelA_col1", NA) })

poll[, res := NA_real_]
tryCatch({
  m <- feols(pm10 ~ temp + rain + rh + wind_speed | station_n + month, data = poll)
  poll[, res := resid(m, na.rm = FALSE)]
}, error = function(e) message("resid: ", conditionMessage(e)))

pr <- poll[is.finite(res)]
tryCatch(put("rd_pm_daily_controls_table1_panelA_col2", rd_coef(pr$res, pr$t, pr$code_city)),
         error = function(e) { message("col2: ", conditionMessage(e)); put("rd_pm_daily_controls_table1_panelA_col2", NA) })
tryCatch({ s <- pr[phase == 1]; put("rd_pm_daily_wave1_table1_panelA_col3", rd_coef(s$res, s$t, s$code_city)) },
         error = function(e) { message("col3: ", conditionMessage(e)); put("rd_pm_daily_wave1_table1_panelA_col3", NA) })
tryCatch({ s <- pr[phase == 2]; put("rd_pm_daily_wave2_table1_panelA_col4", rd_coef(s$res, s$t, s$code_city)) },
         error = function(e) { message("col4: ", conditionMessage(e)); put("rd_pm_daily_wave2_table1_panelA_col4", NA) })
tryCatch({ s <- pr[deadline == TRUE]; put("rd_pm_daily_deadline_table1_panelA_col5", rd_coef(s$res, s$t, s$code_city)) },
         error = function(e) { message("col5: ", conditionMessage(e)); put("rd_pm_daily_deadline_table1_panelA_col5", NA) })
rm(pr); invisible(gc())

## station -> city map (from pollution data)
st_city <- unique(poll[, .(station_n, code_city)], by = "station_n")

## ---------------- AOD RD ----------------
tryCatch({
  aod <- rd_dta("aod_month.dta")
  aod[, pm10_n := as.character(pm10_n)]
  aod[, year := as.integer(year)]; aod[, month := as.integer(month)]
  aod <- merge(aod, station_list[, .(pm10_n, code_city)], by = "pm10_n")
  aod <- merge(aod, city_auto, by = "code_city")
  aod <- aod[phase %in% c(1, 2)]
  aod[, ym := year * 12L + month]
  aod[, auto_ym := as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m"))]
  aod[, tm := as.numeric(ym - auto_ym)]
  aod <- aod[is.finite(aod)]
  wm <- weather[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
                    rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
                by = .(station_n, year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")))]
  aodw <- merge(aod, wm, by.x = c("pm10_n", "year", "month"), by.y = c("station_n", "year", "month"), all.x = TRUE)
  share <- mean(is.finite(aodw$temp))
  if (share > 0.5) {
    m <- feols(aod ~ temp + rain + rh + wind_speed | pm10_n + month, data = aodw)
  } else {
    m <- feols(aod ~ 1 | pm10_n + month, data = aodw)
  }
  aodw[, res := resid(m, na.rm = FALSE)]
  s <- aodw[is.finite(res)]
  put("rd_aod_monthly_controls_table1_panelA_col2", rd_coef(s$res, s$tm, s$code_city))
}, error = function(e) { message("aod: ", conditionMessage(e)); put("rd_aod_monthly_controls_table1_panelA_col2", NA) })

## ---------------- Table 1 Panel B: event study ----------------
es <- poll[deadline == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es[, treat := as.integer(phase == 1)]
es[, rel := ym - (2013L * 12L + 1L)]
es[, per := fifelse(rel >= -12 & rel <= -7, "b7_12",
            fifelse(rel >= -6 & rel <= -5, "b5_6",
            fifelse(rel >= -4 & rel <= -3, "b3_4",
            fifelse(rel >= -2 & rel <= -1, "ref",
            fifelse(rel >= 0 & rel <= 1, "a1_2",
            fifelse(rel >= 2 & rel <= 3, "a3_4",
            fifelse(rel >= 4 & rel <= 5, "a5_6",
            fifelse(rel >= 6 & rel <= 11, "a7_12", NA_character_))))))))]
for (p in c("b7_12", "b5_6", "b3_4", "a1_2", "a3_4", "a5_6", "a7_12")) {
  es[, (paste0("d_", p)) := as.integer(treat == 1L & per == p)]
}
es[, lpm10 := ifelse(pm10 > 0, log(pm10), NA_real_)]
fml_rhs <- "d_b7_12 + d_b5_6 + d_b3_4 + d_a1_2 + d_a3_4 + d_a5_6 + d_a7_12 + temp + rain + rh + wind_speed"

tryCatch({
  m1 <- feols(as.formula(paste("pm10 ~", fml_rhs, "| station_n + month")), data = es, cluster = ~code_city)
  put("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", coef(m1)["d_a1_2"])
  put("n_obs_table1_panelB_deadline_cols1_2", nobs(m1))
}, error = function(e) { message("es1: ", conditionMessage(e))
  put("event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1", NA)
  put("n_obs_table1_panelB_deadline_cols1_2", NA) })
tryCatch({
  m2 <- feols(as.formula(paste("pm10 ~", fml_rhs, "| station_n + ym")), data = es, cluster = ~code_city)
  put("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", coef(m2)["d_a1_2"])
}, error = function(e) { message("es2: ", conditionMessage(e))
  put("event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2", NA) })

## Matched sample: nearest Wave-2 deadline station for each Wave-1 deadline station
tryCatch({
  coords <- station_list[, .(station_n = pm10_n, lon = as.numeric(station_lon), lat = as.numeric(station_lat))]
  coords <- unique(coords, by = "station_n")
  es_st <- unique(es[, .(station_n, code_city, treat)], by = "station_n")
  if (mean(es_st$station_n %in% coords$station_n) < 0.5) {
    # fall back to city-mean coordinates
    cc <- station_list[, .(lon = mean(as.numeric(station_lon), na.rm = TRUE),
                           lat = mean(as.numeric(station_lat), na.rm = TRUE)), by = code_city]
    es_st <- merge(es_st, cc, by = "code_city", all.x = TRUE)
  } else {
    es_st <- merge(es_st, coords, by = "station_n", all.x = TRUE)
  }
  es_st <- es_st[is.finite(lon) & is.finite(lat)]
  T_st <- es_st[treat == 1]; C_st <- es_st[treat == 0]
  hav <- function(lon1, lat1, lon2, lat2) {
    r <- pi / 180
    dlat <- (lat2 - lat1) * r; dlon <- (lon2 - lon1) * r
    a <- sin(dlat / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin(dlon / 2)^2
    2 * 6371 * asin(pmin(1, sqrt(a)))
  }
  match_c <- sapply(seq_len(nrow(T_st)), function(i) {
    d <- hav(T_st$lon[i], T_st$lat[i], C_st$lon, C_st$lat)
    C_st$station_n[which.min(d)]
  })
  pairs <- data.table(pair = seq_len(nrow(T_st)), t_st = T_st$station_n, c_st = match_c)
  tr_part <- merge(es[treat == 1], pairs[, .(station_n = t_st, pair)], by = "station_n")
  co_part <- merge(es[treat == 0], pairs[, .(station_n = c_st, pair)], by = "station_n", allow.cartesian = TRUE)
  ms <- rbind(tr_part, co_part, fill = TRUE)
  m3 <- feols(as.formula(paste("pm10 ~", fml_rhs, "| station_n + month")), data = ms, cluster = ~code_city)
  put("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", coef(m3)["d_a1_2"])
  m5 <- feols(as.formula(paste("lpm10 ~", fml_rhs, "| station_n + ym")), data = ms, cluster = ~code_city)
  put("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", coef(m5)["d_a1_2"])
}, error = function(e) { message("match: ", conditionMessage(e))
  if (is.null(results[["event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3"]]))
    put("event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3", NA)
  put("event_study_log_pm_1_2_months_after_matched_table1_panelB_col5", NA) })

## ---------------- Searches RD ----------------
tryCatch({
  sr <- rd_dta("mask_filter_search.dta")
  sr[, code_city := as.character(code_city)]
  sr[, date := to_date(date)]
  sr[, year := as.integer(format(date, "%Y"))]
  sr[, month := as.integer(format(date, "%m"))]
  srm <- sr[, .(mask = mean(as.numeric(pmmask), na.rm = TRUE),
                filter = mean(as.numeric(filter), na.rm = TRUE)), by = .(code_city, year, month)]
  srm <- merge(srm, city_auto, by = "code_city")
  srm <- srm[phase %in% c(1, 2)]
  srm[, ym := year * 12L + month]
  srm[, auto_ym := as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m"))]
  srm[, tm := as.numeric(ym - auto_ym)]
  wc <- merge(weather, st_city, by = "station_n")
  wc <- wc[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
           by = .(code_city, year = as.integer(format(date, "%Y")), month = as.integer(format(date, "%m")))]
  srm <- merge(srm, wc, by = c("code_city", "year", "month"), all.x = TRUE)
  for (v in c("mask", "filter")) {
    nm <- if (v == "mask") "rd_face_mask_searches_controls_table2_panelA_col2" else "rd_air_filter_searches_controls_table2_panelA_col2"
    tryCatch({
      d <- srm[is.finite(get(v))]
      m <- feols(as.formula(paste(v, "~ temp + rain + rh + wind_speed | code_city + month")), data = d)
      d[, res := resid(m, na.rm = FALSE)]
      d <- d[is.finite(res)]
      put(nm, rd_coef(d$res, d$tm, d$code_city))
    }, error = function(e) { message(v, ": ", conditionMessage(e)); put(nm, NA) })
  }
}, error = function(e) { message("search: ", conditionMessage(e))
  put("rd_face_mask_searches_controls_table2_panelA_col2", NA)
  put("rd_air_filter_searches_controls_table2_panelA_col2", NA) })

## ---------------- Output ----------------
nms <- c("rd_pm_daily_no_controls_table1_panelA_col1",
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
         "rd_air_filter_searches_controls_table2_panelA_col2")
for (n in nms) {
  v <- results[[n]]
  if (is.null(v)) v <- NA
  cat(sprintf("RESULT:%s=%s\n", n, format(v, digits = 10)))
}