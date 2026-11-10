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
  d <- haven::zap_formats(d)
  as.data.table(d)
}

to_date <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  if (is.numeric(x)) return(as.Date(x, origin = "1960-01-01"))
  if (is.character(x)) {
    out <- suppressWarnings(as.Date(x))
    if (all(is.na(out[!is.na(x)]))) out <- suppressWarnings(as.Date(x, format = "%d%b%Y"))
    return(out)
  }
  as.Date(x)
}

# ------------------------------------------------------------------
# Load data
# ------------------------------------------------------------------
sl <- rd_dta("station_list.dta")
if (!"station_n" %in% names(sl) && "pm10_n" %in% names(sl)) setnames(sl, "pm10_n", "station_n")
sl[, auto_date := to_date(auto_date)]
sl[, phase := as.numeric(phase)]
sl[, station_n := as.numeric(station_n)]
sl[, code_city := as.numeric(code_city)]
# Running variable and deadline status defined at the CITY level (paper: days relative to the city's automation date;
# deadline cities = cities that automated exactly on their deadline)
sl[, auto_date_station := auto_date]
sl[, auto_date := suppressWarnings(min(auto_date, na.rm = TRUE)), by = code_city]
sl[is.infinite(as.numeric(auto_date)), auto_date := NA]
sl[, deadline_date := as.Date(ifelse(phase == 1, as.numeric(as.Date("2013-01-01")),
                                     ifelse(phase == 2, as.numeric(as.Date("2014-01-01")), NA_real_)),
                              origin = "1970-01-01")]
# Deadline city: at least one station in the city automated exactly on the wave deadline
sl[, deadline := as.integer(any(!is.na(deadline_date) & !is.na(auto_date_station) & auto_date_station == deadline_date)), by = code_city]
sl <- sl[phase %in% c(1, 2)]

pol <- rd_dta("pollution_1116.dta")
pol[, date := to_date(date)]
pol[, station_n := as.numeric(station_n)]
pol[, code_city := NULL]

wea <- rd_dta("weather_1116.dta")
wea[, date := to_date(date)]
wea[, station_n := as.numeric(station_n)]

dt <- merge(pol, wea, by = c("station_n", "date"), all.x = TRUE)
rm(pol); invisible(gc())
dt <- merge(dt, sl[, .(station_n, code_city, phase, auto_date, deadline, station_lon, station_lat)],
            by = "station_n")
dt[, pm10 := as.numeric(pm10)]
dt[, year := as.integer(format(date, "%Y"))]
dt[, moy := as.integer(format(date, "%m"))]
dt[, ym := year * 12L + moy]
dt[, x := as.numeric(date - auto_date)]
dt[, cl := as.numeric(code_city)]

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
rd_est <- function(y, x, cl, h = NULL) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  out <- tryCatch({
    r <- if (is.null(h)) {
      rdrobust(y = y[ok], x = x[ok], c = 0, kernel = "triangular",
               bwselect = "mserd", cluster = cl[ok], vce = "hc1")
    } else {
      rdrobust(y = y[ok], x = x[ok], c = 0, kernel = "triangular",
               h = h, cluster = cl[ok], vce = "hc1")
    }
    list(coef = unname(r$coef[1]), se = unname(r$se[1]), h = unname(r$bws[1, 1]))
  }, error = function(e) {
    message("rdrobust error: ", conditionMessage(e))
    list(coef = NA_real_, se = NA_real_, h = NA_real_)
  })
  out
}

residualize <- function(d, yvar, fe) {
  f <- as.formula(paste0(yvar, " ~ temp + rain + rh + wind_speed | ", fe))
  m <- tryCatch(feols(f, data = d, warn = FALSE, notes = FALSE), error = function(e) NULL)
  if (is.null(m)) return(rep(NA_real_, nrow(d)))
  as.numeric(resid(m, na.rm = FALSE))
}

fmt <- function(v) ifelse(is.na(v), "NA", formatC(v, digits = 8, format = "g"))

results <- list()

# ------------------------------------------------------------------
# Table 1 Panel A: RD in daily PM10
# ------------------------------------------------------------------
rdd <- dt[!is.na(pm10) & !is.na(x)]

# Col 1: no controls
r1 <- rd_est(rdd$pm10, rdd$x, rdd$cl)
results$rd_pm_daily_no_controls_table1_panelA_col1 <- r1$coef
message(sprintf("Col1: %.3f (%.3f), h=%.1f", r1$coef, r1$se, r1$h))

# Col 2: residualized on station FE, month FE, weather
res_pm_vec <- residualize(rdd, "pm10", "station_n + moy")
rdd[, res_pm := res_pm_vec]
r2 <- rd_est(rdd$res_pm, rdd$x, rdd$cl, h = 263)
results$rd_pm_daily_controls_table1_panelA_col2 <- r2$coef
message(sprintf("Col2: %.3f (%.3f), h=%.1f", r2$coef, r2$se, r2$h))

sub_rd <- function(d, h = NULL) {
  d <- copy(d)
  rs <- residualize(d, "pm10", "station_n + moy")
  d[, res_sub := rs]
  rd_est(d$res_sub, d$x, d$cl, h = h)
}

r3 <- sub_rd(rdd[phase == 1])
results$rd_pm_daily_wave1_table1_panelA_col3 <- r3$coef
message(sprintf("Col3: %.3f (%.3f), h=%.1f", r3$coef, r3$se, r3$h))

r4 <- sub_rd(rdd[phase == 2])
results$rd_pm_daily_wave2_table1_panelA_col4 <- r4$coef
message(sprintf("Col4: %.3f (%.3f), h=%.1f", r4$coef, r4$se, r4$h))

r5 <- sub_rd(rdd[deadline == 1], h = 184)
results$rd_pm_daily_deadline_table1_panelA_col5 <- r5$coef
message(sprintf("Col5: %.3f (%.3f), h=%.1f", r5$coef, r5$se, r5$h))

rm(rdd); invisible(gc())

# ------------------------------------------------------------------
# Table 1 Panel A: RD in monthly AOD
# ------------------------------------------------------------------
aod <- rd_dta("aod_month.dta")
if (!"station_n" %in% names(aod) && "pm10_n" %in% names(aod)) setnames(aod, "pm10_n", "station_n")
aod[, station_n := as.numeric(station_n)]
aod[, year := as.integer(year)]
aod[, month := as.integer(month)]
aod[, aod := as.numeric(aod)]

wm <- dt[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
         by = .(station_n, year, month = moy)]
for (v in c("temp", "rain", "rh", "wind_speed")) wm[is.nan(get(v)), (v) := NA_real_]

aod <- merge(aod, wm, by = c("station_n", "year", "month"), all.x = TRUE)
aod <- merge(aod, sl[, .(station_n, code_city, auto_date)], by = "station_n")
aod[, auto_ym := as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m"))]
aod[, xm := as.numeric(year * 12L + month - auto_ym)]
aod[, moy := month]
aod[, cl := as.numeric(code_city)]
aod <- aod[!is.na(aod) & !is.na(xm)]
res_aod_vec <- residualize(aod, "aod", "station_n + moy")
aod[, res_aod := res_aod_vec]
ra <- rd_est(aod$res_aod, aod$xm, aod$cl)
results$rd_aod_monthly_controls_table1_panelA_col2 <- ra$coef
message(sprintf("AOD: %.4f (%.4f), h=%.1f", ra$coef, ra$se, ra$h))

# ------------------------------------------------------------------
# Table 1 Panel B: event study, deadline cities 2012-2013
# ------------------------------------------------------------------
es <- dt[deadline == 1 & date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31")]
es[, treat := as.integer(phase == 1)]
es[, rel := (year - 2013L) * 12L + (moy - 1L)]
es[, b_m12_7 := treat * as.integer(rel >= -12 & rel <= -7)]
es[, b_m6_5  := treat * as.integer(rel >= -6 & rel <= -5)]
es[, b_m4_3  := treat * as.integer(rel >= -4 & rel <= -3)]
es[, b_p0_1  := treat * as.integer(rel >= 0 & rel <= 1)]
es[, b_p2_3  := treat * as.integer(rel >= 2 & rel <= 3)]
es[, b_p4_5  := treat * as.integer(rel >= 4 & rel <= 5)]
es[, b_p6_11 := treat * as.integer(rel >= 6 & rel <= 11)]
es[, lpm10 := ifelse(!is.na(pm10) & pm10 > 0, log(pm10), NA_real_)]

rhs <- "b_m12_7 + b_m6_5 + b_m4_3 + b_p0_1 + b_p2_3 + b_p4_5 + b_p6_11 + temp + rain + rh + wind_speed"

es1 <- feols(as.formula(paste0("pm10 ~ ", rhs, " | station_n + moy")),
             data = es, cluster = ~code_city)
es2 <- feols(as.formula(paste0("pm10 ~ ", rhs, " | station_n + ym")),
             data = es, cluster = ~code_city)
results$event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 <- unname(coef(es1)["b_p0_1"])
results$event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 <- unname(coef(es2)["b_p0_1"])
results$n_obs_table1_panelB_deadline_cols1_2 <- nobs(es1)
message(sprintf("ES col1: %.3f; col2: %.3f; N=%d", coef(es1)["b_p0_1"], coef(es2)["b_p0_1"], nobs(es1)))

# Matched sample: each Wave-1 deadline station paired with nearest Wave-2 deadline station (with replacement)
hav <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
  a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}
tr_st <- sl[deadline == 1 & phase == 1 & !is.na(station_lon) & !is.na(station_lat)]
co_st <- sl[deadline == 1 & phase == 2 & !is.na(station_lon) & !is.na(station_lat)]
match_id <- sapply(seq_len(nrow(tr_st)), function(i) {
  d <- hav(tr_st$station_lon[i], tr_st$station_lat[i], co_st$station_lon, co_st$station_lat)
  co_st$station_n[which.min(d)]
})
pairs <- data.table(pair = seq_len(nrow(tr_st)), tr = tr_st$station_n, co = match_id)

tr_part <- merge(es, pairs[, .(station_n = tr, pair)], by = "station_n")
co_part <- merge(es, pairs[, .(station_n = co, pair)], by = "station_n", allow.cartesian = TRUE)
mt <- rbind(tr_part, co_part)

es3 <- feols(as.formula(paste0("pm10 ~ ", rhs, " | station_n + moy")),
             data = mt, cluster = ~code_city)
es5 <- feols(as.formula(paste0("lpm10 ~ ", rhs, " | station_n + ym")),
             data = mt, cluster = ~code_city)
results$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- unname(coef(es3)["b_p0_1"])
results$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- unname(coef(es5)["b_p0_1"])
message(sprintf("ES matched col3: %.3f; col5: %.4f; N=%d", coef(es3)["b_p0_1"], coef(es5)["b_p0_1"], nobs(es3)))

# ------------------------------------------------------------------
# Search indices: monthly city-level RD (Table 2 / NBER Table 3 Panel A col 2)
# ------------------------------------------------------------------
srch <- rd_dta("mask_filter_search.dta")
srch[, date := to_date(date)]
srch[, code_city := as.numeric(code_city)]
srch[, year := as.integer(format(date, "%Y"))]
srch[, month := as.integer(format(date, "%m"))]
sm <- srch[, .(mask = mean(as.numeric(pmmask), na.rm = TRUE),
               filter = mean(as.numeric(filter), na.rm = TRUE)),
           by = .(code_city, year, month)]
for (v in c("mask", "filter")) sm[is.nan(get(v)), (v) := NA_real_]

cw <- dt[, .(temp = mean(temp, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             rh = mean(rh, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
         by = .(code_city, year, month = moy)]
for (v in c("temp", "rain", "rh", "wind_speed")) cw[is.nan(get(v)), (v) := NA_real_]

city_auto <- sl[, .(auto_date = min(auto_date, na.rm = TRUE)), by = code_city]
sm <- merge(sm, city_auto, by = "code_city")
sm <- merge(sm, cw, by = c("code_city", "year", "month"), all.x = TRUE)
sm[, auto_ym := as.integer(format(auto_date, "%Y")) * 12L + as.integer(format(auto_date, "%m"))]
sm[, xm := as.numeric(year * 12L + month - auto_ym)]
sm[, moy := month]
sm[, cl := code_city]

smm <- sm[!is.na(mask)]
res_m_vec <- residualize(smm, "mask", "code_city + moy")
smm[, res := res_m_vec]
rm_ <- rd_est(smm$res, smm$xm, smm$cl)
results$rd_face_mask_searches_controls_table2_panelA_col2 <- rm_$coef
message(sprintf("Mask: %.3f (%.3f), h=%.1f, N=%d", rm_$coef, rm_$se, rm_$h, nrow(smm)))

smf <- sm[!is.na(filter)]
res_f_vec <- residualize(smf, "filter", "code_city + moy")
smf[, res := res_f_vec]
rf_ <- rd_est(smf$res, smf$xm, smf$cl)
results$rd_air_filter_searches_controls_table2_panelA_col2 <- rf_$coef
message(sprintf("Filter: %.3f (%.3f), h=%.1f, N=%d", rf_$coef, rf_$se, rf_$h, nrow(smf)))

# ------------------------------------------------------------------
# Output
# ------------------------------------------------------------------
cat("DEVIATION: City automation date taken as the earliest station automation date within each city; running variable defined at city level\n")
cat("DEVIATION: Deadline city defined as a city with at least one station automated exactly on its wave deadline\n")
cat("DEVIATION: Table 1 Panel A cols 2 and 5 use the paper's reported CCT bandwidths (263 and 184 days) as fixed bandwidths instead of re-selecting them, since the R MSE-optimal selector returned much wider bandwidths\n")
for (nm in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", nm, fmt(as.numeric(results[[nm]]))))
}