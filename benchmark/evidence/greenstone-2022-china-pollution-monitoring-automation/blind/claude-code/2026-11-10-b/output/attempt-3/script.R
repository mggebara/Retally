## Greenstone, He, Jia, Liu (2022) -- independent blind reproduction of Table 1 and Table 2/3 (search RDs)
suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sd <- function(x) as.Date(x, origin = "1960-01-01")   # Stata daily dates
T0 <- Sys.time()
tm <- function(msg) cat(sprintf("[%6.1fs] %s\n", as.numeric(difftime(Sys.time(), T0, units = "secs")), msg))

## ---------------- stations ----------------
st <- as.data.table(read_dta(paste0(D, "station_list.dta")))
st[, ad := sd(auto_date)]
## deadline cities: automated exactly on a wave deadline (Jan 1 2013 or Jan 1 2014)
st[, deadline := ad %in% as.Date(c("2013-01-01", "2014-01-01"))]
st[, treat13 := ad == as.Date("2013-01-01")]
st <- st[, .(station_n = pm10_n, code_city, phase, ad, deadline, treat13, lon = station_lon, lat = station_lat)]

## ---------------- daily pollution + weather ----------------
p <- as.data.table(read_dta(paste0(D, "pollution_1116.dta")))[, .(station_n, date, pm10)]
w <- as.data.table(read_dta(paste0(D, "weather_1116.dta")))[, .(station_n, date, wind_speed, rain, temp, rh)]
p <- merge(p, w, by = c("station_n", "date"))
rm(w); invisible(gc())
p[, d := sd(date)]
p <- merge(p, st, by = "station_n")
p[, r := as.numeric(d - ad)]                 # days from automation (0 = automation day, treated)
p[, moy := month(d)]
p[, ym := year(d) * 100L + month(d)]
p[, wx := !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
pp <- p[!is.na(pm10)]
rm(p); invisible(gc())
tm(sprintf("daily obs with PM10: %d", nrow(pp)))

rd <- function(y, x, cl) {
  o <- rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd", cluster = cl, vce = "hc1",
                masspoints = "off")
  list(b = o$coef[1, 1], se = o$se[1, 1], h = o$bws[1, 1], N = sum(o$N_h))
}
show <- function(lab, o) tm(sprintf("%s: b=%.4f se=%.4f h=%.2f N_h=%d", lab, o$b, o$se, o$h, o$N))

## Panel A col 1: raw daily PM10, no controls
pw <- pp[wx == TRUE]   # station-days with PM10 and all four weather variables
tm(sprintf("daily obs with PM10 and weather: %d; deadline cities: %d", nrow(pw), uniqueN(pw[deadline == TRUE]$code_city)))
o1 <- rd(pw$pm10, pw$r, pw$code_city); show("col1", o1)

## Residualize PM10 on station FE, month-of-year FE, weather (full sample, once)
fr <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + moy, data = pw)
pw[, res := resid(fr)]
o2 <- rd(pw$res, pw$r, pw$code_city); show("col2", o2)
s3 <- pw[phase == 1]; o3 <- rd(s3$res, s3$r, s3$code_city); show("col3 wave1", o3)
s4 <- pw[phase == 2]; o4 <- rd(s4$res, s4$r, s4$code_city); show("col4 wave2", o4)
s5 <- pw[deadline == TRUE]; o5 <- rd(s5$res, s5$r, s5$code_city); show("col5 deadline", o5)
rm(s3, s4, s5); invisible(gc())

## ---------------- AOD: station-month ----------------
## monthly station weather = mean of daily weather (all days, incl. days without PM10)
wm <- as.data.table(read_dta(paste0(D, "weather_1116.dta")))
wm[, d := sd(date)]
wm <- wm[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(station_n, year = year(d), month = month(d))]
a <- as.data.table(read_dta(paste0(D, "aod_month.dta")))[, .(station_n = pm10_n, year, month, aod)]
a <- merge(a, wm, by = c("station_n", "year", "month"), all.x = TRUE)
a <- merge(a, st, by = "station_n")
a[, rm := (year * 12 + month) - (year(ad) * 12 + month(ad))]   # months from automation (automation month = 0)
a <- a[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
fa <- feols(aod ~ temp + rh + rain + wind_speed | station_n + month, data = a)
a[, res := resid(fa)]
oa <- rd(a$res, a$rm, a$code_city); show("AOD col2", oa)

## ---------------- Event study (Panel B) ----------------
ev <- pp[deadline == TRUE & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31") & wx == TRUE]
ev[, treat := as.integer(treat13)]
mo_rel <- (year(ev$d) - 2013) * 12 + month(ev$d)    # 1 = Jan 2013 (first month after automation)
ev[, bin := fcase(mo_rel <= -6, "b7_12", mo_rel <= -4, "b5_6", mo_rel <= -2, "b3_4", mo_rel <= 0, "ref",
                  mo_rel <= 2, "a1_2", mo_rel <= 4, "a3_4", mo_rel <= 6, "a5_6", default = "a7_12")]
for (b in c("b7_12", "b5_6", "b3_4", "a1_2", "a3_4", "a5_6", "a7_12")) ev[, (paste0("D_", b)) := as.integer(treat == 1 & bin == b)]
rhs <- "D_b7_12 + D_b5_6 + D_b3_4 + D_a1_2 + D_a3_4 + D_a5_6 + D_a7_12 + temp + rh + rain + wind_speed"
e1 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = ev, cluster = ~code_city)
e2 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = ev, cluster = ~code_city)
tm(sprintf("event stations: W1=%d W2=%d; N=%d / %d",
           uniqueN(ev[treat == 1]$station_n), uniqueN(ev[treat == 0]$station_n), nobs(e1), nobs(e2)))
print(etable(e1, e2, keep = "D_"))

## Nearest-neighbour matching (great-circle distance), W1 deadline -> nearest W2 deadline, with replacement
hav <- function(lon1, lat1, lon2, lat2) {
  rad <- pi / 180; dl <- (lat2 - lat1) * rad; dn <- (lon2 - lon1) * rad
  h <- sin(dl / 2)^2 + cos(lat1 * rad) * cos(lat2 * rad) * sin(dn / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(h)))
}
s1 <- st[deadline == TRUE & treat13 == TRUE & station_n %in% ev$station_n]
s2 <- st[deadline == TRUE & treat13 == FALSE & station_n %in% ev$station_n]
s1[, match := sapply(seq_len(.N), function(i) s2$station_n[which.min(hav(lon[i], lat[i], s2$lon, s2$lat))])]
ctrl <- unique(s1$match)
tm(sprintf("matched: %d W1 stations, %d distinct W2 controls", nrow(s1), length(ctrl)))
evm <- ev[station_n %in% c(s1$station_n, ctrl)]
e3 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = evm, cluster = ~code_city)
e4 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = evm, cluster = ~code_city)
evm[, lpm := ifelse(pm10 > 0, log(pm10), NA_real_)]
e5 <- feols(as.formula(paste("lpm ~", rhs, "| station_n + ym")), data = evm, cluster = ~code_city)
print(etable(e3, e4, e5, keep = "D_"))

## ---------------- Baidu search RDs (city-month) ----------------
ci <- as.data.table(read_dta(paste0(D, "city_info.dta")))
cad <- unique(st[, .(code_city, ad)])
stopifnot(!anyDuplicated(cad$code_city))
m <- as.data.table(read_dta(paste0(D, "mask_filter_search.dta")))
m <- m[code_city %in% ci$code_city]
m[, d := sd(date)]
m <- m[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)), by = .(code_city, year = year(d), month = month(d))]
## city-month weather = mean over the city's stations of station-month weather
wcm <- merge(wm, st[, .(station_n, code_city)], by = "station_n")
wcm <- wcm[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
               wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(code_city, year, month)]
m <- merge(m, wcm, by = c("code_city", "year", "month"), all.x = TRUE)
m <- merge(m, cad, by = "code_city")
m[, rm := (year * 12 + month) - (year(ad) * 12 + month(ad))]
m[, wx := is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
tm(sprintf("search city-months: mask %d, filter %d", sum(is.finite(m$mask)), sum(is.finite(m$filter))))
mk <- m[is.finite(mask) & wx == TRUE]
fm <- feols(mask ~ temp + rh + rain + wind_speed | code_city + month, data = mk); mk[, res := resid(fm)]
om <- rd(mk$res, mk$rm, mk$code_city); show("mask col2", om)
fl <- m[is.finite(filter) & wx == TRUE]
ff <- feols(filter ~ temp + rh + rain + wind_speed | code_city + month, data = fl); fl[, res := resid(ff)]
of <- rd(fl$res, fl$rm, fl$code_city); show("filter col2", of)

## ---------------- results ----------------
cat(sprintf("RESULT:rd_pm_daily_no_controls_table1_panelA_col1=%.6f\n", o1$b))
cat(sprintf("RESULT:rd_pm_daily_controls_table1_panelA_col2=%.6f\n", o2$b))
cat(sprintf("RESULT:rd_pm_daily_wave1_table1_panelA_col3=%.6f\n", o3$b))
cat(sprintf("RESULT:rd_pm_daily_wave2_table1_panelA_col4=%.6f\n", o4$b))
cat(sprintf("RESULT:rd_pm_daily_deadline_table1_panelA_col5=%.6f\n", o5$b))
cat(sprintf("RESULT:rd_aod_monthly_controls_table1_panelA_col2=%.6f\n", oa$b))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1=%.6f\n", coef(e1)[["D_a1_2"]]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2=%.6f\n", coef(e2)[["D_a1_2"]]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3=%.6f\n", coef(e3)[["D_a1_2"]]))
cat(sprintf("RESULT:event_study_log_pm_1_2_months_after_matched_table1_panelB_col5=%.6f\n", coef(e5)[["D_a1_2"]]))
cat(sprintf("RESULT:n_obs_table1_panelB_deadline_cols1_2=%d\n", nobs(e1)))
cat(sprintf("RESULT:rd_face_mask_searches_controls_table2_panelA_col2=%.6f\n", om$b))
cat(sprintf("RESULT:rd_air_filter_searches_controls_table2_panelA_col2=%.6f\n", of$b))
tm("done")
