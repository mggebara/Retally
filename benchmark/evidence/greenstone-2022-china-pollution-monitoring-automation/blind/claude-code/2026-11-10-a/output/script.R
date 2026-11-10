# Independent, blind reproduction of Greenstone, He, Jia & Liu (2022),
# "Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution".
# Table 1 Panels A/B and Table 2 (NBER WP Table 3) Panel A, column (2).
suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D, f, ".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
sd2 <- function(x) as.Date(x - 3653, origin = "1970-01-01")   # Stata daily date -> R Date

st <- rd("station_list"); st[, auto := sd2(auto_date)]
ca <- st[, .N, by = .(code_city, auto)]
cat("Cities with more than one station automation date:\n"); print(ca[code_city %in% ca[duplicated(code_city)]$code_city])
# city-level automation date (for city-month search data): date shared by most stations, ties -> earliest
cityauto <- ca[order(code_city, -N, auto)][, .SD[1], by = code_city][, .(code_city, auto)]
DL <- as.Date(c("2013-01-01", "2014-01-01"))

# ---------- station-day panel: PM10 + nearest weather station ----------
we <- rd("weather_1116")
po <- merge(rd("pollution_1116"), we, by = c("station_n", "date"))
po[, d := sd2(date)]
po <- merge(po, st[, .(station_n = pm10_n, auto, phase)], by = "station_n")
po <- po[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
cat("Daily obs before bandwidth selection:", nrow(po), "\n")
po[, rv := as.integer(d - auto)]          # days from automation (0 = automation day, treated)
po[, mon := month(d)]
po[, ym := year(d) * 100L + month(d)]

# Residualize PM10 on station FE, month-of-year FE and weather (Lee & Lemieux 2010)
po[, res := resid(feols(pm10 ~ temp + rh + rain + wind_speed | station_n + mon, po), na.rm = FALSE)]

# Local linear RD, triangular kernel, CCT (2014) MSE-optimal bandwidth, city-clustered SEs.
rdfit <- function(y, x, cl, lab) {
  ok <- is.finite(y) & is.finite(x)
  r <- rdrobust(y[ok], x[ok], c = 0, p = 1, kernel = "triangular", bwselect = "mserd",
                cluster = cl[ok], vce = "hc1", masspoints = "off")
  cat(sprintf("%-28s coef=%.4f se=%.4f bw=%.2f N_h=%d N=%d\n", lab, r$coef[1], r$se[1], r$bws[1, 1], sum(r$N_h), sum(ok)))
  r$coef[1]
}
res <- list()
res$rd_pm_daily_no_controls_table1_panelA_col1 <- rdfit(po$pm10, po$rv, po$code_city, "PM10 col1 raw")
res$rd_pm_daily_controls_table1_panelA_col2    <- rdfit(po$res, po$rv, po$code_city, "PM10 col2 resid")
w1 <- po[phase == 1]; w2 <- po[phase == 2]; dl <- po[auto %in% DL]
res$rd_pm_daily_wave1_table1_panelA_col3    <- rdfit(w1$res, w1$rv, w1$code_city, "PM10 col3 wave1")
res$rd_pm_daily_wave2_table1_panelA_col4    <- rdfit(w2$res, w2$rv, w2$code_city, "PM10 col4 wave2")
res$rd_pm_daily_deadline_table1_panelA_col5 <- rdfit(dl$res, dl$rv, dl$code_city, "PM10 col5 deadline")
cat("deadline cities:", uniqueN(dl$code_city), "\n")

# ---------- AOD: station-month ----------
a <- rd("aod_month")
we[, `:=`(year = year(sd2(date)), month = month(sd2(date)))]
wm <- we[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             ws = mean(wind_speed, na.rm = TRUE)), by = .(pm10_n = station_n, year, month)]
a <- merge(a, wm, by = c("pm10_n", "year", "month"), all.x = TRUE)
a <- merge(a, st[, .(pm10_n, auto, code_city)], by = "pm10_n")
a <- a[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(ws)]
a[, rvm := (year * 12 + month) - (year(auto) * 12 + month(auto))]   # months from automation month
a[, res := resid(feols(aod ~ temp + rh + rain + ws | pm10_n + month, a), na.rm = FALSE)]
res$rd_aod_monthly_controls_table1_panelA_col2 <- rdfit(a$res, a$rvm, a$code_city, "AOD col2 resid")

# ---------- Event study (Table 1 Panel B) ----------
es <- po[auto %in% DL & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
es[, treat := as.integer(auto == as.Date("2013-01-01"))]
es[, mo := (year(d) * 12 + month(d)) - (2013 * 12 + 1)]   # 0 = Jan 2013
es[, `:=`(
  b712 = treat * (mo >= -12 & mo <= -7), b56 = treat * (mo >= -6 & mo <= -5), b34 = treat * (mo >= -4 & mo <= -3),
  a12  = treat * (mo >= 0 & mo <= 1),    a34 = treat * (mo >= 2 & mo <= 3),   a56 = treat * (mo >= 4 & mo <= 5),
  a712 = treat * (mo >= 6 & mo <= 11))]
cat("ES stations: treated", uniqueN(es[treat == 1]$station_n), " control", uniqueN(es[treat == 0]$station_n), "\n")
f_m  <- pm10 ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed | station_n + mon
f_ym <- pm10 ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed | station_n + ym
e1 <- feols(f_m, es, cluster = ~code_city)
e2 <- feols(f_ym, es, cluster = ~code_city)
print(coeftable(e1)[1:7, ]); print(coeftable(e2)[1:7, ])
cat("R2 col1", r2(e1, "r2"), " col2", r2(e2, "r2"), " N", nobs(e1), nobs(e2), "\n")
res$event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 <- unname(coef(e1)["a12"])
res$event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 <- unname(coef(e2)["a12"])
res$n_obs_table1_panelB_deadline_cols1_2 <- nobs(e1)

# Nearest-neighbour matching (great-circle distance), Wave-1 deadline station -> nearest Wave-2 deadline station,
# with replacement; paired sample stacks each treated station with its matched control (controls repeated).
hav <- function(la1, lo1, la2, lo2) { r <- pi / 180; h <- sin((la2 - la1) * r / 2)^2 + cos(la1 * r) * cos(la2 * r) * sin((lo2 - lo1) * r / 2)^2; 2 * 6371 * asin(sqrt(h)) }
stt <- st[auto == DL[1]]; stc <- st[auto == DL[2]]
mt <- sapply(seq_len(nrow(stt)), function(i) stc$pm10_n[which.min(hav(stt$station_lat[i], stt$station_lon[i], stc$station_lat, stc$station_lon))])
pairs <- data.table(pair = seq_along(mt), tr = stt$pm10_n, co = mt)
ms <- rbind(merge(pairs[, .(pair, station_n = tr)], es, by = "station_n"),
            merge(pairs[, .(pair, station_n = co)], es, by = "station_n"))
cat("Matched sample obs:", nrow(ms), " unique controls:", uniqueN(mt), "\n")
e3 <- feols(f_m, ms, cluster = ~code_city)
ms[, lpm := ifelse(pm10 > 0, log(pm10), NA_real_)]
e5 <- feols(lpm ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed | station_n + ym, ms, cluster = ~code_city)
print(coeftable(e3)[1:7, ]); print(coeftable(e5)[1:7, ])
cat("R2 col3", r2(e3, "r2"), " col5", r2(e5, "r2"), " N", nobs(e3), nobs(e5), "\n")
res$event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 <- unname(coef(e3)["a12"])
res$event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 <- unname(coef(e5)["a12"])

# ---------- Baidu searches (city-month) ----------
s <- rd("mask_filter_search"); s <- s[code_city %in% cityauto$code_city]
s[, `:=`(year = year(sd2(date)), month = month(sd2(date)))]
sm <- s[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)), by = .(code_city, year, month)]
cw <- merge(we, st[, .(station_n = pm10_n, code_city)], by = "station_n")[,
  .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE), ws = mean(wind_speed, na.rm = TRUE)),
  by = .(code_city, year, month)]
sm <- merge(sm, cw, by = c("code_city", "year", "month"))
sm <- merge(sm, cityauto[, .(code_city, auto)], by = "code_city")
sm <- sm[is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(ws)]
sm[, rvm := (year * 12 + month) - (year(auto) * 12 + month(auto))]
smm <- sm[is.finite(mask)]; smf <- sm[is.finite(filter)]
cat("search obs: mask", nrow(smm), " filter", nrow(smf), "\n")
smm[, res := resid(feols(mask ~ temp + rh + rain + ws | code_city + month, smm), na.rm = FALSE)]
smf[, res := resid(feols(filter ~ temp + rh + rain + ws | code_city + month, smf), na.rm = FALSE)]
res$rd_face_mask_searches_controls_table2_panelA_col2 <- rdfit(smm$res, smm$rvm, smm$code_city, "Mask col2 resid")
res$rd_air_filter_searches_controls_table2_panelA_col2 <- rdfit(smf$res, smf$rvm, smf$code_city, "Filter col2 resid")

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
