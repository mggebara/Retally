# Independent, blind reproduction of Greenstone, He, Jia & Liu (2022)
# "Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution"
# Table 1 (Panels A and B) and the Table 3 (NBER WP) Panel A column (2) search RDs.
PRINT_RESULTS <- FALSE

suppressPackageStartupMessages({
  library(haven); library(data.table); library(fixest); library(rdrobust)
})
set.seed(42)
setFixest_nthreads(1)
t0 <- Sys.time()
tick <- function(msg) message(sprintf("[%6.1fs] %s", as.numeric(difftime(Sys.time(), t0, units = "secs")), msg))

D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) { x <- as.data.table(zap_formats(zap_labels(read_dta(file.path(D, f))))); x }

# Stata daily dates (origin 1960-01-01)
sdate <- function(d) as.Date(d, origin = "1960-01-01")
DL1 <- as.numeric(as.Date("2013-01-01") - as.Date("1960-01-01"))  # 19359
DL2 <- as.numeric(as.Date("2014-01-01") - as.Date("1960-01-01"))  # 19724

## ---------------- stations ----------------
sl <- rd("station_list.dta")
setnames(sl, "pm10_n", "station_n")
sl[, deadline := (phase == 1 & auto_date == DL1) | (phase == 2 & auto_date == DL2)]
ad <- sdate(sl$auto_date)
sl[, auto_ym := as.integer(format(ad, "%Y")) * 12L + as.integer(format(ad, "%m"))]
message("stations: ", nrow(sl), "; cities: ", uniqueN(sl$code_city),
        "; deadline cities: ", uniqueN(sl[deadline == TRUE]$code_city),
        "; deadline stations: ", sum(sl$deadline))

## ---------------- daily station panel ----------------
po <- rd("pollution_1116.dta")[, .(station_n, date, pm10)]
we <- rd("weather_1116.dta")
d <- merge(po, we, by = c("station_n", "date"), all.x = TRUE)
rm(po); gc(verbose = FALSE)
d <- merge(d, sl[, .(station_n, code_city, phase, auto_date, deadline)], by = "station_n")
dd <- sdate(d$date)
d[, `:=`(year = as.integer(format(dd, "%Y")), month = as.integer(format(dd, "%m")))]
rm(dd)
d[, ym := year * 12L + month]
d[, x := date - auto_date]   # days from automation (running variable)
d <- d[!is.na(pm10)]
tick(sprintf("daily panel built: %d obs with PM10", nrow(d)))

## ---------------- RD helper ----------------
rdfit <- function(y, x, cl) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  r <- rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, kernel = "triangular",
                bwselect = "mserd", vce = "hc0", cluster = cl[ok], masspoints = "off")
  list(coef = unname(r$coef[1, 1]), se = unname(r$se[1, 1]), h = unname(r$bws[1, 1]),
       nl = r$N_h[1], nr = r$N_h[2])
}
rep_rd <- function(lab, r) message(sprintf("%s: h=%.2f, Nh=%d (bw obs)", lab, r$h, r$nl + r$nr))

res <- list()

## Table 1 Panel A col (1): raw daily PM10, no controls, all stations
r1 <- rdfit(d$pm10, d$x, d$code_city); rep_rd("col1", r1); tick("col1 done")
res$rd_pm_daily_no_controls_table1_panelA_col1 <- r1$coef

## Residualize PM10 on station FE, month-of-year FE and weather controls (full sample)
m_res <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + month, data = d)
d[, pm_res := NA_real_]
d[obs(m_res), pm_res := resid(m_res)]
tick(sprintf("residualization done: %d obs", nobs(m_res)))

dr <- d[!is.na(pm_res)]
r2 <- rdfit(dr$pm_res, dr$x, dr$code_city); rep_rd("col2", r2); tick("col2 done")
res$rd_pm_daily_controls_table1_panelA_col2 <- r2$coef
s <- dr$phase == 1
r3 <- rdfit(dr$pm_res[s], dr$x[s], dr$code_city[s]); rep_rd("col3", r3); tick("col3 done")
res$rd_pm_daily_wave1_table1_panelA_col3 <- r3$coef
s <- dr$phase == 2
r4 <- rdfit(dr$pm_res[s], dr$x[s], dr$code_city[s]); rep_rd("col4", r4); tick("col4 done")
res$rd_pm_daily_wave2_table1_panelA_col4 <- r4$coef
s <- dr$deadline
r5 <- rdfit(dr$pm_res[s], dr$x[s], dr$code_city[s]); rep_rd("col5", r5); tick("col5 done")
res$rd_pm_daily_deadline_table1_panelA_col5 <- r5$coef
rm(dr, s); gc(verbose = FALSE)

## ---------------- monthly station weather ----------------
# weather for all station-days (also days with missing PM10) for monthly aggregates
we[, dd := sdate(date)]
we[, `:=`(year = as.integer(format(dd, "%Y")), month = as.integer(format(dd, "%m")))]
wm <- we[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE),
             rain = mean(rain, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
         by = .(station_n, year, month)]
for (v in c("temp", "rh", "rain", "wind_speed")) set(wm, which(is.nan(wm[[v]])), v, NA_real_)

## ---------------- AOD RD (station-month) ----------------
ao <- rd("aod_month.dta"); setnames(ao, "pm10_n", "station_n")
ao <- merge(ao, wm, by = c("station_n", "year", "month"), all.x = TRUE)
ao <- merge(ao, sl[, .(station_n, code_city, auto_ym)], by = "station_n")
ao[, x := (year * 12L + month) - auto_ym]
ao <- ao[!is.na(aod)]
m_ao <- feols(aod ~ temp + rh + rain + wind_speed | station_n + month, data = ao)
ao[, aod_res := NA_real_]; ao[obs(m_ao), aod_res := resid(m_ao)]
ra <- rdfit(ao$aod_res, ao$x, ao$code_city); rep_rd("AOD col2", ra); tick("AOD done")
res$rd_aod_monthly_controls_table1_panelA_col2 <- ra$coef

## ---------------- Event study (Table 1 Panel B) ----------------
es <- d[auto_date %in% c(DL1, DL2) & date >= as.numeric(as.Date("2012-01-01") - as.Date("1960-01-01")) &
          date <= as.numeric(as.Date("2013-12-31") - as.Date("1960-01-01"))]
es[, treat := as.integer(auto_date == DL1)]
es[, rel := ym - (2013L * 12L + 1L)]   # 0 = Jan 2013 (first automated month)
es[, `:=`(
  b7_12 = treat * (rel >= -12 & rel <= -7),
  b5_6  = treat * (rel >= -6 & rel <= -5),
  b3_4  = treat * (rel >= -4 & rel <= -3),
  a1_2  = treat * (rel >= 0 & rel <= 1),
  a3_4  = treat * (rel >= 2 & rel <= 3),
  a5_6  = treat * (rel >= 4 & rel <= 5),
  a7_12 = treat * (rel >= 6 & rel <= 11))]
message("event-study stations: treated ", uniqueN(es[treat == 1]$station_n),
        ", control ", uniqueN(es[treat == 0]$station_n),
        "; cities treated ", uniqueN(es[treat == 1]$code_city), ", control ", uniqueN(es[treat == 0]$code_city))
fml_m  <- pm10 ~ b7_12 + b5_6 + b3_4 + a1_2 + a3_4 + a5_6 + a7_12 + temp + rh + rain + wind_speed | station_n + month
fml_ym <- pm10 ~ b7_12 + b5_6 + b3_4 + a1_2 + a3_4 + a5_6 + a7_12 + temp + rh + rain + wind_speed | station_n + ym
e1 <- feols(fml_m, data = es, cluster = ~code_city)
e2 <- feols(fml_ym, data = es, cluster = ~code_city)
tick(sprintf("event study cols 1-2 done: N=%d / %d", nobs(e1), nobs(e2)))
res$event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 <- unname(coef(e1)["a1_2"])
res$event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 <- unname(coef(e2)["a1_2"])
res$n_obs_table1_panelB_deadline_cols1_2 <- nobs(e1)

## Nearest-neighbour geographic matching (with replacement): each treated deadline
## station paired with its closest control (Wave 2 deadline) station.
hav <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180
  dlat <- (lat2 - lat1) * rad; dlon <- (lon2 - lon1) * rad
  a <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}
tr <- sl[auto_date == DL1]; co <- sl[auto_date == DL2]
tr[, match := co$station_n[sapply(seq_len(.N), function(i)
  which.min(hav(station_lon[i], station_lat[i], co$station_lon, co$station_lat)))]]
message("matched: ", nrow(tr), " treated stations to ", uniqueN(tr$match), " distinct controls")
pairs <- rbind(
  es[treat == 1][, pair := station_n],
  rbindlist(lapply(seq_len(nrow(tr)), function(i) es[station_n == tr$match[i]][, pair := tr$station_n[i]]))
)
pairs[, lpm10 := fifelse(pm10 > 0, log(pm10), NA_real_)]
e3 <- feols(fml_m, data = pairs, cluster = ~code_city)
e5 <- feols(lpm10 ~ b7_12 + b5_6 + b3_4 + a1_2 + a3_4 + a5_6 + a7_12 + temp + rh + rain + wind_speed | station_n + ym,
            data = pairs, cluster = ~code_city)
tick(sprintf("matched event study done: N=%d / %d", nobs(e3), nobs(e5)))
res$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- unname(coef(e3)["a1_2"])
res$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- unname(coef(e5)["a1_2"])
rm(es, pairs, d); gc(verbose = FALSE)

## ---------------- Online search RDs (city-month) ----------------
cities <- unique(sl[, .(code_city, auto_ym)])
sr <- rd("mask_filter_search.dta")[code_city %in% cities$code_city]
sd_ <- sdate(sr$date)
sr[, `:=`(year = as.integer(format(sd_, "%Y")), month = as.integer(format(sd_, "%m")))]
srm <- sr[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)),
          by = .(code_city, year, month)]
for (v in c("mask", "filter")) set(srm, which(is.nan(srm[[v]])), v, NA_real_)
wcm <- merge(wm, sl[, .(station_n, code_city)], by = "station_n")[
  , .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE),
      rain = mean(rain, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE)),
  by = .(code_city, year, month)]
srm <- merge(srm, wcm, by = c("code_city", "year", "month"), all.x = TRUE)
srm <- merge(srm, cities, by = "code_city")
srm[, x := (year * 12L + month) - auto_ym]
message("search city-months: ", nrow(srm), "; cities ", uniqueN(srm$code_city))
for (v in c("mask", "filter")) {
  sub <- srm[!is.na(get(v))]
  mm <- feols(as.formula(paste(v, "~ temp + rh + rain + wind_speed | code_city + month")), data = sub)
  sub[, yres := NA_real_]; sub[obs(mm), yres := resid(mm)]
  rs <- rdfit(sub$yres, sub$x, sub$code_city); rep_rd(paste("search", v), rs)
  if (v == "mask") res$rd_face_mask_searches_controls_table2_panelA_col2 <- rs$coef
  else res$rd_air_filter_searches_controls_table2_panelA_col2 <- rs$coef
}
tick("search RDs done")

if (PRINT_RESULTS) {
  for (n in names(res)) cat(sprintf("RESULT:%s=%.10g\n", n, res[[n]]))
} else {
  message("computed ", length(res), " quantities (not printed)")
}
