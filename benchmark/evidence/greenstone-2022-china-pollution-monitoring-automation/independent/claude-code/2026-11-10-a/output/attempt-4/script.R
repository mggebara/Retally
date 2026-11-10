# Independent reproduction: Greenstone, He, Jia, Liu (2022) -- automation of air quality monitoring
suppressPackageStartupMessages({library(haven); library(data.table); library(fixest); library(rdrobust)})
set.seed(42)
t0 <- Sys.time()
tm <- function(msg) cat(sprintf("[%6.1fs] %s\n", as.numeric(difftime(Sys.time(), t0, units = "secs")), msg))
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D, f, ".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
stdate <- function(x) as.Date(x, origin = "1960-01-01")

st   <- rd("station_list")
pol  <- rd("pollution_1116")
wea  <- rd("weather_1116")
aod  <- rd("aod_month")
srch <- rd("mask_filter_search")
tm("loaded")

st[, auto := stdate(auto_date)]
st[, deadline := as.Date(ifelse(phase == 1, as.Date("2013-01-01"), as.Date("2014-01-01")), origin = "1970-01-01")]
st[, on_deadline := auto == deadline]

## ---------------- Daily station panel ----------------
pol[, date := stdate(date)]
wea[, date := stdate(date)]
setnames(wea, "station_n", "station_n")
dd <- merge(pol[, .(station_n, code_city, date, pm10)], wea, by = c("station_n", "date"), all.x = TRUE)
rm(pol, wea); invisible(gc())
dd <- merge(dd, st[, .(station_n = pm10_n, phase, auto, on_deadline, lon = station_lon, lat = station_lat)], by = "station_n")
dd[, x := as.numeric(date - auto)]
dd[, moy := month(date)]
dd[, ym := year(date) * 100L + month(date)]
cat("pm10 nonmissing:", sum(!is.na(dd$pm10)), "\n")
d <- dd[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
cat("daily RD sample (pm10 + weather complete):", nrow(d), "\n")
tm("daily panel built")

resid_fe <- function(dat, y, fe) {
  f <- as.formula(paste0(y, " ~ temp + rh + rain + wind_speed | ", fe))
  m <- feols(f, data = dat, warn = FALSE, notes = FALSE)
  as.numeric(resid(m, na.rm = FALSE))
}

run_rd <- function(y, x, cl, lab) {
  r <- rdrobust(y = y, x = x, c = 0, kernel = "triangular", bwselect = "mserd", cluster = cl, vce = "hc1", masspoints = "off")
  est <- r$coef[1, 1]; se <- r$se[1, 1]
  cat(sprintf("%-40s coef=%9.4f se=%8.4f h=%7.2f N_h=%d+%d=%d\n", lab, est, se, r$bws[1, 1], r$N_h[1], r$N_h[2], sum(r$N_h)))
  est
}

res <- list()
res$rd_pm_daily_no_controls_table1_panelA_col1 <- run_rd(d$pm10, d$x, d$code_city, "PM10 daily, no controls, all")
tm("col1 done")
d[, r_pm := resid_fe(d, "pm10", "station_n + moy")]
res$rd_pm_daily_controls_table1_panelA_col2 <- run_rd(d$r_pm, d$x, d$code_city, "PM10 daily, resid, all")
tm("col2 done")

d1 <- d[phase == 1]; d1[, r := resid_fe(d1, "pm10", "station_n + moy")]
res$rd_pm_daily_wave1_table1_panelA_col3 <- run_rd(d1$r, d1$x, d1$code_city, "PM10 daily, resid, wave 1")
d2 <- d[phase == 2]; d2[, r := resid_fe(d2, "pm10", "station_n + moy")]
res$rd_pm_daily_wave2_table1_panelA_col4 <- run_rd(d2$r, d2$x, d2$code_city, "PM10 daily, resid, wave 2")
cat("city-level automation dates by phase (city counts):\n")
print(dcast(unique(st[, .(code_city, phase, auto)])[, .N, by = .(phase, auto)], auto ~ phase, value.var = "N", fill = 0))
cdef <- st[, .(phase = phase[1], amin = min(auto), amax = max(auto), anydl = any(on_deadline), alldl = all(on_deadline),
               any1314 = any(auto %in% as.Date(c("2013-01-01", "2014-01-01")))), by = code_city]
cat("cities: any station on deadline", sum(cdef$anydl), " all on deadline", sum(cdef$alldl),
    " min date on deadline", sum(cdef[, amin == as.Date(ifelse(phase == 1, as.Date("2013-01-01"), as.Date("2014-01-01")), origin = "1970-01-01")]),
    " any station 2013-01-01/2014-01-01", sum(cdef$any1314), "\n")
cat("stations auto in {2013-01-01,2014-01-01}:", st[auto %in% as.Date(c("2013-01-01", "2014-01-01")), .N], " cities", st[auto %in% as.Date(c("2013-01-01", "2014-01-01")), uniqueN(code_city)], "\n")
dB <- d[auto %in% as.Date(c("2013-01-01", "2014-01-01"))]; dB[, r := resid_fe(dB, "pm10", "station_n + moy")]
invisible(run_rd(dB$r, dB$x, dB$code_city, "DIAG deadline=auto in 2013-01-01/2014-01-01"))
dC <- d[code_city %in% cdef[anydl == TRUE]$code_city]; dC[, r := resid_fe(dC, "pm10", "station_n + moy")]
invisible(run_rd(dC$r, dC$x, dC$code_city, "DIAG deadline=city any station on deadline"))
rm(dB, dC)
d3 <- d[on_deadline == TRUE]; d3[, r := resid_fe(d3, "pm10", "station_n + moy")]
cat("deadline cities:", uniqueN(d3$code_city), " stations:", uniqueN(d3$station_n), "\n")
res$rd_pm_daily_deadline_table1_panelA_col5 <- run_rd(d3$r, d3$x, d3$code_city, "PM10 daily, resid, deadline")
rm(d1, d2, d3); invisible(gc())
tm("panel A PM10 done")

## ---------------- AOD (station-month) ----------------
wm <- dd[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(station_n, year = year(date), month = month(date))]
a <- merge(aod[, .(station_n = pm10_n, year, month, aod)], wm, by = c("station_n", "year", "month"))
a <- merge(a, st[, .(station_n = pm10_n, code_city, auto)], by = "station_n")
a[, xm := (year * 12 + month) - (year(auto) * 12 + month(auto))]
a <- a[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
cat("AOD station-month sample:", nrow(a), "\n")
a[, r := resid_fe(a, "aod", "station_n + month")]
a <- a[!is.na(r)]
cat("AOD obs after FE residualization:", nrow(a), "\n")
res$rd_aod_monthly_controls_table1_panelA_col2 <- run_rd(a$r, a$xm, a$code_city, "AOD monthly, resid, all")
tm("AOD done")

## ---------------- Event study (Panel B) ----------------
es <- dd[date >= as.Date("2012-01-01") & date <= as.Date("2013-12-31") &
         auto %in% as.Date(c("2013-01-01", "2014-01-01"))]
es <- es[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
es[, treat := as.integer(auto == as.Date("2013-01-01"))]
cat("event-study stations: treated", uniqueN(es[treat == 1]$station_n), " control", uniqueN(es[treat == 0]$station_n), "\n")
mk_periods <- function(e) {
  e[, `:=`(b712 = treat * (ym >= 201201 & ym <= 201206), b56 = treat * (ym %in% c(201207, 201208)),
           b34 = treat * (ym %in% c(201209, 201210)), a12 = treat * (ym %in% c(201301, 201302)),
           a34 = treat * (ym %in% c(201303, 201304)), a56 = treat * (ym %in% c(201305, 201306)),
           a712 = treat * (ym >= 201307 & ym <= 201312))]
  e
}
es <- mk_periods(es)
rhs <- "b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed"
m1 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = es, cluster = ~code_city)
m2 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es, cluster = ~code_city)
print(etable(m1, m2))
res$event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 <- coef(m1)[["a12"]]
res$event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 <- coef(m2)[["a12"]]
res$n_obs_table1_panelB_deadline_cols1_2 <- nobs(m1)

# nearest-neighbour matching (with replacement): each treated station -> geographically nearest control station
hav <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180; dlon <- (lon2 - lon1) * rad; dlat <- (lat2 - lat1) * rad
  h <- sin(dlat / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(h)))
}
ts_ <- unique(es[treat == 1, .(station_n, lon, lat)])
cs_ <- unique(es[treat == 0, .(station_n, lon, lat)])
ts_[, match := sapply(seq_len(.N), function(i) cs_$station_n[which.min(hav(lon[i], lat[i], cs_$lon, cs_$lat))])]
cat("matched control stations used:", uniqueN(ts_$match), "\n")
mt <- rbind(es[treat == 1][, pair := station_n],
            merge(ts_[, .(pair = station_n, station_n = match)], es[treat == 0], by = "station_n", allow.cartesian = TRUE))
cat("matched sample obs:", nrow(mt), "\n")
mt[, ndate := .N, by = .(pair, date)]
cat("matched obs with both pair members on same date:", nrow(mt[ndate == 2]), "\n")
mc <- mt[ndate == 2]
m3b <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = mc, cluster = ~code_city)
cat("DIAG matched common-date sample col3 a12:", coef(m3b)[["a12"]], " N", nobs(m3b), "\n")
mu <- unique(mt[, .(station_n, date, pm10, temp, rh, rain, wind_speed, moy, ym, code_city, b712, b56, b34, a12, a34, a56, a712)])
m3c <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = mu, cluster = ~code_city)
cat("DIAG matched dedup sample col3 a12:", coef(m3c)[["a12"]], " N", nobs(m3c), "\n")
m3 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = mt, cluster = ~code_city)
m4 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = mt, cluster = ~code_city)
mt[, lpm := ifelse(pm10 > 0, log(pm10), NA_real_)]
m5 <- feols(as.formula(paste("lpm ~", rhs, "| station_n + ym")), data = mt, cluster = ~code_city)
print(etable(m3, m4, m5))
res$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- coef(m3)[["a12"]]
res$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- coef(m5)[["a12"]]
tm("event study done")

## ---------------- Search RD (city-month) ----------------
city_auto <- st[, .(auto = min(auto)), by = code_city]
srch[, date := stdate(date)]
sm <- srch[code_city %in% city_auto$code_city,
           .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE),
             nmask = sum(!is.na(pmmask)), nfilter = sum(!is.na(filter))),
           by = .(code_city, year = year(date), month = month(date))]
sm[nmask == 0, mask := NA]; sm[nfilter == 0, filter := NA]
wc <- dd[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(code_city, year = year(date), month = month(date))]
sm <- merge(sm, wc, by = c("code_city", "year", "month"), all.x = TRUE)
sm <- merge(sm, city_auto, by = "code_city")
sm[, xm := (year * 12 + month) - (year(auto) * 12 + month(auto))]
sm <- sm[is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
smk <- sm[!is.na(mask)]; sfl <- sm[!is.na(filter)]
cat("search city-month obs: mask", nrow(smk), " filter", nrow(sfl), " cities", uniqueN(sm$code_city), "\n")
smk[, r := resid_fe(smk, "mask", "code_city + month")]
sfl[, r := resid_fe(sfl, "filter", "code_city + month")]
smk <- smk[!is.na(r)]; sfl <- sfl[!is.na(r)]
res$rd_face_mask_searches_controls_table2_panelA_col2 <- run_rd(smk$r, smk$xm, smk$code_city, "Mask search, resid")
res$rd_air_filter_searches_controls_table2_panelA_col2 <- run_rd(sfl$r, sfl$xm, sfl$code_city, "Filter search, resid")
tm("search done")

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
