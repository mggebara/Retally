suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
  library(rdrobust)
  library(lubridate)
})

set.seed(42)

base <- "<repo>/.cache/datasets/greenstone_2022_china_pollution_monitoring_automation.script-free/China_Pollution_Monitoring/Data"

# ---------------- helpers ----------------
key <- function(x) {
  x <- haven::zap_labels(haven::zap_formats(x))
  if (is.numeric(x)) {
    if (all(is.na(x) | x == round(x))) return(ifelse(is.na(x), NA_character_, sprintf("%.0f", x)))
    return(format(x, scientific = FALSE, trim = TRUE, drop0trailing = TRUE))
  }
  trimws(as.character(x))
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  x <- haven::zap_labels(haven::zap_formats(x))
  if (is.numeric(x)) {
    med <- median(x, na.rm = TRUE)
    if (is.finite(med) && med > 1e7 && med < 1e8) return(as.Date(sprintf("%.0f", x), "%Y%m%d"))
    if (is.finite(med) && med > 1e11) return(as.Date(as.POSIXct(x / 1000, origin = "1960-01-01", tz = "UTC")))
    return(as.Date(x, origin = "1960-01-01"))
  }
  x <- as.character(x)
  as.Date(lubridate::parse_date_time(x, orders = c("Ymd", "Y-m-d", "dmY", "mdY", "dbY"), quiet = TRUE))
}

num <- function(x) as.numeric(haven::zap_labels(x))

rd_fun <- function(y, x, cl, label = "") {
  ok <- is.finite(y) & is.finite(x) & !is.na(cl)
  y <- y[ok]; x <- x[ok]; cl <- as.integer(factor(cl[ok]))
  r <- tryCatch(
    rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd",
             cluster = cl, vce = "hc1", masspoints = "off"),
    error = function(e) tryCatch(
      rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd",
               cluster = cl, vce = "hc1"),
      error = function(e2) { message(label, " rdrobust error: ", e2$message); NULL }))
  if (is.null(r)) return(NA_real_)
  message(sprintf("%s: coef=%.4f se=%.4f h=%.2f N_h=%d", label, r$coef[1, 1], r$se[1, 1],
                  r$bws[1, 1], sum(r$N_h)))
  r$coef[1, 1]
}

safe_coef <- function(m, nm) {
  if (is.null(m)) return(NA_real_)
  cf <- coef(m)
  if (nm %in% names(cf)) unname(cf[nm]) else NA_real_
}

haversine <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
  a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}

res <- list()

# ---------------- load data ----------------
pol <- as.data.table(read_dta(file.path(base, "pollution_1116.dta")))
pol[, station_n := key(station_n)]
pol[, code_city := key(code_city)]
pol[, date := to_date(date)]
pol[, pm10 := num(pm10)]
pol <- pol[, .(station_n, code_city, date, pm10)]

wea <- as.data.table(read_dta(file.path(base, "weather_1116.dta")))
wea[, station_n := key(station_n)]
wea[, date := to_date(date)]
for (v in c("temp", "rain", "rh", "wind_speed")) set(wea, j = v, value = num(wea[[v]]))
wea <- unique(wea[, .(station_n, date, temp, rain, rh, wind_speed)], by = c("station_n", "date"))

sl <- as.data.table(read_dta(file.path(base, "station_list.dta")))
sl[, pm10_n := key(pm10_n)]
sl[, code_city := key(code_city)]
sl[, auto_date := to_date(auto_date)]
sl[, phase := num(phase)]
sl[, station_lon := num(station_lon)]
sl[, station_lat := num(station_lat)]

ci <- as.data.table(read_dta(file.path(base, "city_info.dta")))
ci[, code_city := key(code_city)]
ci[, phase := num(phase)]
ci <- unique(ci[, .(code_city, phase)], by = "code_city")

# city-level automation date (modal station date within city)
cityauto <- sl[!is.na(auto_date), .(auto_date = {
  tb <- table(as.character(auto_date)); as.Date(names(tb)[which.max(tb)])
}), by = code_city]
cityinfo <- merge(ci, cityauto, by = "code_city", all = TRUE)
if (any(is.na(cityinfo$phase))) {
  slph <- sl[!is.na(phase), .(phase_sl = phase[1]), by = code_city]
  cityinfo <- merge(cityinfo, slph, by = "code_city", all.x = TRUE)
  cityinfo[is.na(phase), phase := phase_sl]
  cityinfo[, phase_sl := NULL]
}
cityinfo[, deadline := (phase == 1 & auto_date == as.Date("2013-01-01")) |
                       (phase == 2 & auto_date == as.Date("2014-01-01"))]
message("Cities by phase:"); print(table(cityinfo$phase, useNA = "ifany"))
message("Deadline cities: ", sum(cityinfo$deadline, na.rm = TRUE))

# ---------------- daily station panel ----------------
dt <- merge(pol, wea, by = c("station_n", "date"), all.x = TRUE)
rm(pol); gc()
dt <- merge(dt, cityinfo, by = "code_city", all.x = TRUE)
dt <- dt[phase %in% c(1, 2) & !is.na(pm10) & !is.na(auto_date) & !is.na(date)]
dt[, x := as.numeric(date - auto_date)]
dt[, month := month(date)]
dt[, year := year(date)]
allp <- copy(dt)

# stations with data before and after automation
dt[, `:=`(has_pre = any(x < 0), has_post = any(x >= 0)), by = station_n]
dt <- dt[has_pre & has_post]
message("RD full sample N = ", nrow(dt), "; stations = ", uniqueN(dt$station_n),
        "; cities = ", uniqueN(dt$code_city))

# Col 1: no controls
res$rd_pm_daily_no_controls_table1_panelA_col1 <- rd_fun(dt$pm10, dt$x, dt$code_city, "col1")

# Col 2: residualize on station FE, month FE, weather
m_res <- feols(pm10 ~ temp + rain + rh + wind_speed | station_n + month, data = dt)
dt[, pm_res := NA_real_]
dt[obs(m_res), pm_res := resid(m_res)]
res$rd_pm_daily_controls_table1_panelA_col2 <- rd_fun(dt$pm_res, dt$x, dt$code_city, "col2")

s <- dt[phase == 1]
res$rd_pm_daily_wave1_table1_panelA_col3 <- rd_fun(s$pm_res, s$x, s$code_city, "col3 wave1")
s <- dt[phase == 2]
res$rd_pm_daily_wave2_table1_panelA_col4 <- rd_fun(s$pm_res, s$x, s$code_city, "col4 wave2")
s <- dt[deadline == TRUE]
res$rd_pm_daily_deadline_table1_panelA_col5 <- rd_fun(s$pm_res, s$x, s$code_city, "col5 deadline")
rm(s); gc()

# ---------------- city-month weather ----------------
stmap <- unique(allp[, .(station_n, code_city)], by = "station_n")
wcm <- merge(wea, stmap, by = "station_n")
wcm[, `:=`(year = year(date), month = month(date))]
wcm <- wcm[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
           by = .(code_city, year, month)]
for (v in c("temp", "rain", "rh", "wind_speed")) set(wcm, which(!is.finite(wcm[[v]])), v, NA_real_)

# ---------------- AOD RD (monthly) ----------------
res$rd_aod_monthly_controls_table1_panelA_col2 <- tryCatch({
  aod <- as.data.table(read_dta(file.path(base, "aod_month.dta")))
  aod[, pm10_n := key(pm10_n)]
  aod[, `:=`(year = num(year), month = num(month), aod = num(aod))]
  aod <- merge(aod, unique(sl[, .(pm10_n, code_city)], by = "pm10_n"), by = "pm10_n")
  aod <- merge(aod, cityinfo, by = "code_city")
  aod <- aod[phase %in% c(1, 2) & !is.na(aod) & !is.na(auto_date)]
  aod[, x := (year * 12 + month) - (year(auto_date) * 12 + month(auto_date))]
  aod <- merge(aod, wcm, by = c("code_city", "year", "month"), all.x = TRUE)
  aod[, `:=`(has_pre = any(x < 0), has_post = any(x >= 0)), by = pm10_n]
  aod <- aod[has_pre & has_post]
  ma <- feols(aod ~ temp + rain + rh + wind_speed | pm10_n + month, data = aod)
  aod[, aod_res := NA_real_]
  aod[obs(ma), aod_res := resid(ma)]
  rd_fun(aod$aod_res, aod$x, aod$code_city, "AOD")
}, error = function(e) { message("AOD error: ", e$message); NA_real_ })

# ---------------- Event study (Panel B) ----------------
bins <- c("b7_12", "b5_6", "b3_4", "a1_2", "a3_4", "a5_6", "a7_12")
make_es <- function(d) {
  d <- copy(d)
  d[, rel := (year - 2013) * 12 + month - 1]
  d[, bin := fifelse(rel >= -12 & rel <= -7, "b7_12",
             fifelse(rel >= -6 & rel <= -5, "b5_6",
             fifelse(rel >= -4 & rel <= -3, "b3_4",
             fifelse(rel >= -2 & rel <= -1, "ref",
             fifelse(rel >= 0 & rel <= 1, "a1_2",
             fifelse(rel >= 2 & rel <= 3, "a3_4",
             fifelse(rel >= 4 & rel <= 5, "a5_6",
             fifelse(rel >= 6 & rel <= 11, "a7_12", NA_character_))))))))]
  d[, treated := as.integer(phase == 1)]
  for (b in bins) set(d, j = paste0("D_", b), value = as.integer(d$treated == 1 & d$bin == b))
  d[, ym := year * 100 + month]
  d
}
rhs <- paste(c(paste0("D_", bins), "temp", "rain", "rh", "wind_speed"), collapse = " + ")

es <- allp[deadline == TRUE & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es <- make_es(es)
message("ES deadline stations: treated=", uniqueN(es[treated == 1]$station_n),
        " control=", uniqueN(es[treated == 0]$station_n))

es1 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + month")), data = es, cluster = ~code_city),
                error = function(e) { message(e$message); NULL })
es2 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es, cluster = ~code_city),
                error = function(e) { message(e$message); NULL })
res$event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 <- safe_coef(es1, "D_a1_2")
res$event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 <- safe_coef(es2, "D_a1_2")
res$n_obs_table1_panelB_deadline_cols1_2 <- if (!is.null(es1)) nobs(es1) else NA_real_

# Matched sample: each Wave-1 deadline station -> nearest Wave-2 deadline station (with replacement)
matched <- tryCatch({
  coords <- unique(sl[!is.na(station_lon) & !is.na(station_lat), .(pm10_n, code_city, station_lon, station_lat)],
                   by = "pm10_n")
  es_st <- unique(es[, .(station_n, code_city, treated)], by = "station_n")
  overlap <- mean(es_st$station_n %in% coords$pm10_n)
  message("Station key overlap with station_list: ", round(overlap, 3))
  if (overlap > 0.8) {
    st <- merge(es_st, coords[, .(station_n = pm10_n, station_lon, station_lat)], by = "station_n")
    tr <- st[treated == 1]; co <- st[treated == 0]
    nn <- sapply(seq_len(nrow(tr)), function(i) {
      d <- haversine(tr$station_lon[i], tr$station_lat[i], co$station_lon, co$station_lat)
      co$station_n[which.min(d)]
    })
    cnt <- table(nn)
    parts <- list(es[treated == 1 & station_n %in% tr$station_n])
    for (k in names(cnt)) {
      blk <- es[station_n == k]
      parts[[length(parts) + 1]] <- blk[rep(seq_len(nrow(blk)), as.integer(cnt[[k]]))]
    }
    rbindlist(parts)
  } else {
    cc <- coords[, .(lon = mean(station_lon), lat = mean(station_lat)), by = code_city]
    ec <- unique(es[, .(code_city, treated)], by = "code_city")
    ec <- merge(ec, cc, by = "code_city")
    trc <- ec[treated == 1]; coc <- ec[treated == 0]
    nnc <- sapply(seq_len(nrow(trc)), function(i) {
      d <- haversine(trc$lon[i], trc$lat[i], coc$lon, coc$lat)
      coc$code_city[which.min(d)]
    })
    cnt <- table(nnc)
    parts <- list(es[treated == 1 & code_city %in% trc$code_city])
    for (k in names(cnt)) {
      blk <- es[code_city == k]
      parts[[length(parts) + 1]] <- blk[rep(seq_len(nrow(blk)), as.integer(cnt[[k]]))]
    }
    rbindlist(parts)
  }
}, error = function(e) { message("Matching error: ", e$message); NULL })

if (!is.null(matched)) {
  message("Matched sample N = ", nrow(matched))
  es3 <- tryCatch(feols(as.formula(paste("pm10 ~", rhs, "| station_n + month")), data = matched, cluster = ~code_city),
                  error = function(e) { message(e$message); NULL })
  matched[, lpm10 := ifelse(pm10 > 0, log(pm10), NA_real_)]
  es5 <- tryCatch(feols(as.formula(paste("lpm10 ~", rhs, "| station_n + ym")), data = matched, cluster = ~code_city),
                  error = function(e) { message(e$message); NULL })
  res$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- safe_coef(es3, "D_a1_2")
  res$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- safe_coef(es5, "D_a1_2")
} else {
  res$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- NA_real_
  res$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- NA_real_
}

# ---------------- Baidu search RD (monthly, city level) ----------------
srch <- tryCatch({
  ms <- as.data.table(read_dta(file.path(base, "mask_filter_search.dta")))
  ms[, code_city := key(code_city)]
  ms[, date := to_date(date)]
  ms[, `:=`(pmmask = num(pmmask), filter = num(filter))]
  ms[, `:=`(year = year(date), month = month(date))]
  ms <- ms[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)),
           by = .(code_city, year, month)]
  for (v in c("mask", "filter")) set(ms, which(!is.finite(ms[[v]])), v, NA_real_)
  ms <- merge(ms, cityinfo, by = "code_city")
  ms <- ms[phase %in% c(1, 2) & !is.na(auto_date)]
  ms[, x := (year * 12 + month) - (year(auto_date) * 12 + month(auto_date))]
  ms <- merge(ms, wcm, by = c("code_city", "year", "month"), all.x = TRUE)
  ms
}, error = function(e) { message("Search load error: ", e$message); NULL })

search_rd <- function(var) {
  if (is.null(srch)) return(NA_real_)
  tryCatch({
    d <- srch[!is.na(get(var))]
    message(var, " obs = ", nrow(d))
    m <- feols(as.formula(paste(var, "~ temp + rain + rh + wind_speed | code_city + month")), data = d)
    d[, yres := NA_real_]
    d[obs(m), yres := resid(m)]
    rd_fun(d$yres, d$x, d$code_city, paste("search", var))
  }, error = function(e) { message("Search RD error: ", e$message); NA_real_ })
}
res$rd_face_mask_searches_controls_table2_panelA_col2 <- search_rd("mask")
res$rd_air_filter_searches_controls_table2_panelA_col2 <- search_rd("filter")

# ---------------- output ----------------
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
  v <- res[[nm]]
  if (is.null(v)) v <- NA_real_
  cat(sprintf("RESULT:%s=%s\n", nm, format(as.numeric(v), digits = 8)))
}