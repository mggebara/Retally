# Reproduction of Greenstone, He, Jia & Liu (2022, AER: Insights),
# "Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution"
# Follows Prepare_Data.do and Tables.do (Table 1 Panels A/B, Table 2 Panel A) of the replication package.
suppressPackageStartupMessages({
  library(haven); library(data.table); library(fixest); library(rdrobust)
})
set.seed(42)
setFixest_nthreads(1)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/seeded/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(D, f)))))
tic <- proc.time()[3]
msg <- function(...) cat(sprintf("[%.0fs] ", proc.time()[3] - tic), ..., "\n", sep = "")

# rdrobust as in Stata: c(0) p(1) q(2) kernel(tri) vce(cluster code_city) masspoints(off)
# Stata's vce(cluster) = plug-in residuals with CR1 weights ((n-1)/(n-k))*(G/(G-1));
# in R rdrobust 4.x that is cluster= with vce="cr1".
RDVCE <- "cr1"
rdr <- function(y, x, cl) {
  ok <- !is.na(y) & !is.na(x) & !is.na(cl)
  r <- rdrobust(y[ok], x[ok], c = 0, p = 1, q = 2, kernel = "triangular",
                cluster = cl[ok], vce = RDVCE, masspoints = "off")
  list(coef = unname(r$coef[1, 1]), se = unname(r$se[1, 1]),
       h = unname(r$bws[1, 1]), Nh = sum(r$N_h))
}

## ---- 1. station_day_1116 ----
pol <- rd("pollution_1116.dta")
wea <- rd("weather_1116.dta")
sl  <- rd("station_list.dta")
sd_ <- merge(pol, wea, by = c("station_n", "date"), all = TRUE)
rm(pol, wea); invisible(gc())
setnames(sd_, "station_n", "pm10_n")
sd_ <- merge(sd_, sl[, .(pm10_n, phase, auto_date)], by = "pm10_n", all.x = TRUE)
sd_[, T := date - auto_date]
dts <- as.Date(sd_$date, origin = "1960-01-01")
sd_[, `:=`(year = as.integer(format(dts, "%Y")), month = as.integer(format(dts, "%m")))]
rm(dts)
msg("station_day rows: ", nrow(sd_))

## ---- Table 1A, row 1: daily PM10 ----
m <- feols(pm10 ~ wind_speed + rain + temp + rh | pm10_n + month, data = sd_,
           fixef.rm = "singleton", notes = FALSE, warn = FALSE)
sd_[, resid := resid(m, na.rm = FALSE)]
rm(m); invisible(gc())
wok <- with(sd_, !is.na(temp) & !is.na(rain) & !is.na(rh) & !is.na(wind_speed))
res <- list()
r <- rdr(ifelse(wok, sd_$pm10, NA), sd_$T, sd_$code_city); msg("col1 ", paste(unlist(r), collapse=" ")); res$c1 <- r
r <- rdr(sd_$resid, sd_$T, sd_$code_city); msg("col2 ", paste(unlist(r), collapse=" ")); res$c2 <- r
k <- sd_$phase == 1
r <- rdr(ifelse(k, sd_$resid, NA), sd_$T, sd_$code_city); msg("col3 ", paste(unlist(r), collapse=" ")); res$c3 <- r
k <- sd_$phase == 2
r <- rdr(ifelse(k, sd_$resid, NA), sd_$T, sd_$code_city); msg("col4 ", paste(unlist(r), collapse=" ")); res$c4 <- r
k <- sd_$auto_date %in% c(19359, 19724)
r <- rdr(ifelse(k, sd_$resid, NA), sd_$T, sd_$code_city); msg("col5 ", paste(unlist(r), collapse=" ")); res$c5 <- r
sd_[, resid := NULL]

## ---- Table 1A, row 2: monthly AOD (station_month) ----
mofd <- function(d) { x <- as.Date(d, origin = "1960-01-01"); as.integer(format(x, "%Y")) * 12L + as.integer(format(x, "%m")) - 1L }
sm <- sd_[!is.na(date), .(pm10 = mean(pm10, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE),
                          rain = mean(rain, na.rm = TRUE), temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE),
                          code_city = code_city[1], phase = phase[1], auto_date = auto_date[1], date1 = date[1]),
          by = .(pm10_n, year, month)]
for (v in c("pm10", "wind_speed", "rain", "temp", "rh")) set(sm, which(is.nan(sm[[v]])), v, NA_real_)
sm[, n_month := (year * 12L + month - 1L) - mofd(auto_date)]
aod <- rd("aod_month.dta")
sm <- merge(sm, aod, by = c("pm10_n", "year", "month"))
m <- feols(aod ~ wind_speed + rain + temp + rh | pm10_n + month, data = sm,
           fixef.rm = "singleton", notes = FALSE, warn = FALSE)
sm[, resid := resid(m, na.rm = FALSE)]
r <- rdr(sm$resid, sm$n_month, sm$code_city); msg("aod col2 ", paste(unlist(r), collapse=" ")); res$aod2 <- r

## ---- Table 1B: event study, deadline cities 2012-2013 ----
evvars <- c("treat_m712_before2", "treat_m56_before2", "treat_m34_before2",
            "treat_m12_after2", "treat_m34_after2", "treat_m56_after2", "treat_m712_after2")
mk_ev <- function(d) {
  d[, year_month := (year - 2012L) * 12L + month]
  d[, treat := as.integer(auto_date == 19359)]
  d[, `:=`(
    treat_m712_before2 = treat * (year == 2012 & month >= 1 & month <= 6),
    treat_m56_before2  = treat * (year == 2012 & month >= 7 & month <= 8),
    treat_m34_before2  = treat * (year == 2012 & month >= 9 & month <= 10),
    treat_m12_after2   = treat * (year == 2013 & month >= 1 & month <= 2),
    treat_m34_after2   = treat * (year == 2013 & month >= 3 & month <= 4),
    treat_m56_after2   = treat * (year == 2013 & month >= 5 & month <= 6),
    treat_m712_after2  = treat * (year == 2013 & month >= 7 & month <= 12))]
  d
}
rhs <- paste(c(evvars, "wind_speed", "rain", "temp", "rh"), collapse = " + ")
ev <- mk_ev(sd_[year >= 2012 & year <= 2013 & auto_date %in% c(19724, 19359)])
e1 <- feols(as.formula(paste("pm10 ~", rhs, "| pm10_n + month")), data = ev,
            cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
e2 <- feols(as.formula(paste("pm10 ~", rhs, "| pm10_n + year_month")), data = ev,
            cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
msg("ev col1 b=", coef(e1)["treat_m12_after2"], " se=", se(e1)["treat_m12_after2"], " N=", nobs(e1))
msg("ev col2 b=", coef(e2)["treat_m12_after2"], " se=", se(e2)["treat_m12_after2"], " N=", nobs(e2))

## nearest-neighbour matching (geonear, ellipsoid = Vincenty on WGS84), within 400 km, with replacement
vincenty <- function(lat1, lon1, lat2, lon2) {
  a <- 6378137; f <- 1 / 298.257223563; b <- a * (1 - f)
  rad <- pi / 180
  L <- (lon2 - lon1) * rad
  U1 <- atan((1 - f) * tan(lat1 * rad)); U2 <- atan((1 - f) * tan(lat2 * rad))
  sU1 <- sin(U1); cU1 <- cos(U1); sU2 <- sin(U2); cU2 <- cos(U2)
  lam <- L
  for (it in 1:200) {
    sl <- sin(lam); cl <- cos(lam)
    sS <- sqrt((cU2 * sl)^2 + (cU1 * sU2 - sU1 * cU2 * cl)^2)
    cS <- sU1 * sU2 + cU1 * cU2 * cl
    sig <- atan2(sS, cS)
    sA <- ifelse(sS == 0, 0, cU1 * cU2 * sl / sS)
    c2A <- 1 - sA^2
    c2sm <- ifelse(c2A == 0, 0, cS - 2 * sU1 * sU2 / c2A)
    C <- f / 16 * c2A * (4 + f * (4 - 3 * c2A))
    lamP <- lam
    lam <- L + (1 - C) * f * sA * (sig + C * sS * (c2sm + C * cS * (-1 + 2 * c2sm^2)))
    if (all(abs(lam - lamP) < 1e-12)) break
  }
  u2 <- c2A * (a^2 - b^2) / b^2
  A <- 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)))
  B <- u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)))
  dS <- B * sS * (c2sm + B / 4 * (cS * (-1 + 2 * c2sm^2) - B / 6 * c2sm * (-3 + 4 * sS^2) * (-3 + 4 * c2sm^2)))
  ifelse(sS == 0, 0, b * A * (sig - dS)) / 1000
}
s1 <- sl[auto_date == 19359]; s2 <- sl[auto_date == 19724]
mt <- rbindlist(lapply(seq_len(nrow(s1)), function(i) {
  dk <- vincenty(s1$station_lat[i], s1$station_lon[i], s2$station_lat, s2$station_lon)
  j <- which.min(dk)
  data.table(pm10_n1 = s1$pm10_n[i], pm10_n = s2$pm10_n[j], km = dk[j])
}))
mt <- mt[km <= 400]
msg("matched treated stations: ", nrow(mt), " distinct controls: ", uniqueN(mt$pm10_n))
base <- sd_[year >= 2012 & year <= 2013]
tr <- base[pm10_n %in% mt$pm10_n1]
ctl <- merge(base, mt[, .(pm10_n)], by = "pm10_n", allow.cartesian = TRUE)
mm <- mk_ev(rbind(tr, ctl, use.names = TRUE))
mm[, l_pm10 := ifelse(!is.na(pm10) & pm10 > 0, log(pm10), NA_real_)]
e3 <- feols(as.formula(paste("pm10 ~", rhs, "| pm10_n + month")), data = mm,
            cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
e5 <- feols(as.formula(paste("l_pm10 ~", rhs, "| pm10_n + year_month")), data = mm,
            cluster = ~code_city, fixef.rm = "singleton", notes = FALSE, warn = FALSE)
msg("ev col3 b=", coef(e3)["treat_m12_after2"], " se=", se(e3)["treat_m12_after2"], " N=", nobs(e3))
msg("ev col5 b=", coef(e5)["treat_m12_after2"], " se=", se(e5)["treat_m12_after2"], " N=", nobs(e5))
rm(base, tr, ctl, mm, ev); invisible(gc())

## ---- Table 2A: city-month Baidu search ----
cd <- sd_[!is.na(date), .(pm10 = mean(pm10, na.rm = TRUE), wind_speed = mean(wind_speed, na.rm = TRUE),
                          rain = mean(rain, na.rm = TRUE), temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE),
                          auto_date = max(auto_date)), by = .(code_city, date)]
for (v in c("pm10", "wind_speed", "rain", "temp", "rh")) set(cd, which(is.nan(cd[[v]])), v, NA_real_)
rm(sd_); invisible(gc())
srch <- rd("mask_filter_search.dta")
cd <- merge(cd, srch, by = c("code_city", "date"))
cd[, n_month := mofd(date) - mofd(auto_date)]
cd[, month := as.integer(format(as.Date(date, origin = "1960-01-01"), "%m"))]
setorder(cd, code_city, n_month, date)
cm <- cd[, .(wind_speed = mean(wind_speed, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
             temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE),
             pmmask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE),
             month = month[1]), by = .(code_city, n_month)]
for (v in c("wind_speed", "rain", "temp", "rh", "pmmask", "filter")) set(cm, which(is.nan(cm[[v]])), v, NA_real_)
msg("search city-months: ", nrow(cm), " cities: ", uniqueN(cm$code_city))
for (y in c("pmmask", "filter")) {
  m <- feols(as.formula(paste(y, "~ wind_speed + rain + temp + rh | code_city + month")), data = cm,
             fixef.rm = "singleton", notes = FALSE, warn = FALSE)
  rr <- resid(m, na.rm = FALSE)
  r <- rdr(rr, cm$n_month, cm$code_city); msg(y, " col2 ", paste(unlist(r), collapse=" ")); res[[y]] <- r
}

## ---- results ----
out <- c(
  rd_pm_daily_no_controls_table1_panelA_col1 = res$c1$coef,
  rd_pm_daily_controls_table1_panelA_col2 = res$c2$coef,
  rd_pm_daily_wave1_table1_panelA_col3 = res$c3$coef,
  rd_pm_daily_wave2_table1_panelA_col4 = res$c4$coef,
  rd_pm_daily_deadline_table1_panelA_col5 = res$c5$coef,
  rd_aod_monthly_controls_table1_panelA_col2 = res$aod2$coef,
  event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 = unname(coef(e1)["treat_m12_after2"]),
  event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 = unname(coef(e2)["treat_m12_after2"]),
  event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 = unname(coef(e3)["treat_m12_after2"]),
  event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 = unname(coef(e5)["treat_m12_after2"]),
  n_obs_table1_panelB_deadline_cols1_2 = nobs(e1),
  rd_face_mask_searches_controls_table2_panelA_col2 = res$pmmask$coef,
  rd_air_filter_searches_controls_table2_panelA_col2 = res$filter$coef
)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
