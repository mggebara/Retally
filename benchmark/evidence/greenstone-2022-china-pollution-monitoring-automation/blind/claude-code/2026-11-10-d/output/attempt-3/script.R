# Retally independent/blind reproduction: Greenstone, He, Jia, Liu (2022)
# "Can Technology Solve the Principal-Agent Problem? Evidence from China's War on Air Pollution"
# Table 1 (Panels A and B) and Table 2/3 Panel A col (2) search RDs.
suppressPackageStartupMessages({
  library(haven); library(data.table); library(rdrobust); library(fixest)
})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
STATA0 <- 3653  # Stata day 0 (1960-01-01) in R Date units
D2013 <- 19359  # 2013-01-01 (Wave 1 deadline)
D2014 <- 19724  # 2014-01-01 (Wave 2 deadline)
W <- c("temp", "rh", "rain", "wind_speed")

st <- as.data.table(read_dta(paste0(D, "station_list.dta")))
ci <- as.data.table(read_dta(paste0(D, "city_info.dta")))
po <- as.data.table(read_dta(paste0(D, "pollution_1116.dta")))
we <- as.data.table(read_dta(paste0(D, "weather_1116.dta")))
for (d in list(st, ci, po, we)) for (v in names(d)) attr(d[[v]], "label") <- NULL

po <- merge(po[, .(station_n, code_city, date, pm10)], we, by = c("station_n", "date"))
po <- merge(po, st[, .(station_n = pm10_n, auto_date, phase)], by = "station_n")
po[, d := as.Date(date - STATA0)]
po[, `:=`(yr = year(d), moy = month(d))]
po[, ym := yr * 12L + moy - 1L]
po[, x := date - auto_date]                 # days from automation (running variable)
po[, deadline := auto_date %in% c(D2013, D2014)]

rd <- function(y, x, cl) {
  r <- rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd",
                cluster = cl, vce = "cr1")
  list(coef = unname(r$coef[1, 1]), se = unname(r$se[1, 1]), h = unname(r$bws[1, 1]),
       N = sum(r$N_h))
}
show <- function(lab, r) cat(sprintf("%-40s coef=%9.4f se=%8.4f h=%8.2f N_h=%d\n", lab, r$coef, r$se, r$h, r$N))

# ---------------- Panel A: daily PM10 RD ----------------
dd <- po[!is.na(pm10) & complete.cases(po[, ..W])]
cat("Daily PM10 obs before bandwidth selection:", nrow(dd), "\n")
# col (1): raw PM10, no FE/covariates
r1 <- rd(dd$pm10, dd$x, dd$code_city); show("PM10 col1 (raw)", r1)
# residualize on station FE, month-of-year FE, weather
m_res <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + moy, data = dd)
dd[, pres := resid(m_res)]
r2 <- rd(dd$pres, dd$x, dd$code_city); show("PM10 col2 (resid, all)", r2)
s3 <- dd[phase == 1]; r3 <- rd(s3$pres, s3$x, s3$code_city); show("PM10 col3 (Wave 1)", r3)
s4 <- dd[phase == 2]; r4 <- rd(s4$pres, s4$x, s4$code_city); show("PM10 col4 (Wave 2)", r4)
s5 <- dd[deadline == TRUE]; r5 <- rd(s5$pres, s5$x, s5$code_city); show("PM10 col5 (Deadline)", r5)
cat("Deadline sample: stations", uniqueN(s5$station_n), "cities", uniqueN(s5$code_city), "\n")

# ---------------- Panel A: monthly AOD RD ----------------
ao <- as.data.table(read_dta(paste0(D, "aod_month.dta")))
for (v in names(ao)) attr(ao[[v]], "label") <- NULL
wm <- po[, lapply(.SD, mean, na.rm = TRUE), by = .(station_n, yr, moy), .SDcols = W]
ao <- merge(ao[, .(station_n = pm10_n, yr = year, moy = month, aod)], wm, by = c("station_n", "yr", "moy"))
ao <- merge(ao, st[, .(station_n = pm10_n, code_city, auto_date)], by = "station_n")
ad <- as.Date(ao$auto_date - STATA0)
ao[, xm := (yr * 12L + moy - 1L) - (year(ad) * 12L + month(ad) - 1L)]  # months from automation
ao <- ao[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
cat("AOD station-months:", nrow(ao), "\n")
m_ao <- feols(aod ~ temp + rh + rain + wind_speed | station_n + moy, data = ao)
ao[, ares := resid(m_ao)]
ra <- rd(ao$ares, ao$xm, ao$code_city); show("AOD col2 (resid, all)", ra)

# ---------------- Panel B: event study (deadline cities, 2012-2013) ----------------
es <- dd[deadline == TRUE & date >= 18993 & date <= 19723]   # 2012-01-01 .. 2013-12-31
es[, treat := as.integer(auto_date == D2013)]
es[, rel := ym - (2013L * 12L)]   # months relative to Jan 2013 (0 = Jan 2013)
es[, `:=`(
  b712 = treat * (rel >= -12 & rel <= -7), b56 = treat * (rel >= -6 & rel <= -5),
  b34  = treat * (rel >= -4 & rel <= -3),
  a12  = treat * (rel >= 0 & rel <= 1),  a34 = treat * (rel >= 2 & rel <= 3),
  a56  = treat * (rel >= 4 & rel <= 5),  a712 = treat * (rel >= 6 & rel <= 11))]
cat("ES stations: treated", uniqueN(es[treat == 1]$station_n), "control", uniqueN(es[treat == 0]$station_n), "\n")
fes1 <- feols(pm10 ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed |
                station_n + moy, data = es, cluster = ~code_city)
fes2 <- feols(pm10 ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed |
                station_n + ym, data = es, cluster = ~code_city)

# nearest-neighbour geographic matching (with replacement): each treated station -> nearest control station
hav <- function(lon1, lat1, lon2, lat2) {
  r <- pi / 180; dlat <- (lat2 - lat1) * r; dlon <- (lon2 - lon1) * r
  a <- sin(dlat / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin(dlon / 2)^2
  2 * 6371 * asin(pmin(1, sqrt(a)))
}
tr <- st[auto_date == D2013]; co <- st[auto_date == D2014]
tr[, match := sapply(seq_len(.N), function(i) co$pm10_n[which.min(hav(station_lon[i], station_lat[i], co$station_lon, co$station_lat))])]
cat("Matched controls: unique", uniqueN(tr$match), "of", nrow(co), "\n")
pairs <- rbind(data.table(station_n = tr$pm10_n, pair = seq_len(nrow(tr))),
               data.table(station_n = tr$match,  pair = seq_len(nrow(tr))))
em <- merge(pairs, es, by = "station_n", allow.cartesian = TRUE)
cat("Matched-sample obs:", nrow(em), "\n")
fes3 <- feols(pm10 ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed |
                station_n + moy, data = em, cluster = ~code_city)
em_l <- em[pm10 > 0][, lpm := log(pm10)]
fes5 <- feols(lpm ~ b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed |
                station_n + ym, data = em_l, cluster = ~code_city)
etable(fes1, fes2, fes3, fes5, keep = "^b|^a[0-9]")

# ---------------- Search RD (city-month) ----------------
ms <- as.data.table(read_dta(paste0(D, "mask_filter_search.dta")))
for (v in names(ms)) attr(ms[[v]], "label") <- NULL
ms <- ms[code_city %in% ci$code_city]
ms[, d := as.Date(date - STATA0)]; ms[, `:=`(yr = year(d), moy = month(d))]
sm <- ms[, .(mask = if (all(is.na(pmmask))) NA_real_ else mean(pmmask, na.rm = TRUE),
             filt = if (all(is.na(filter))) NA_real_ else mean(filter, na.rm = TRUE)),
         by = .(code_city, yr, moy)]
cw <- po[, lapply(.SD, mean, na.rm = TRUE), by = .(code_city, yr, moy), .SDcols = W]
sm <- merge(sm, cw, by = c("code_city", "yr", "moy"), all.x = TRUE)
# city automation date: modal station automation date in the city (earliest on ties)
nd <- st[, .N, by = .(code_city, auto_date)][order(code_city, -N, auto_date)][, .SD[1], by = code_city]
cat("Cities with >1 station automation date:", st[, uniqueN(auto_date), by = code_city][V1 > 1, .N], "\n")
sm <- merge(sm, nd[, .(code_city, auto_date)], by = "code_city")
ad <- as.Date(sm$auto_date - STATA0)
sm[, xm := (yr * 12L + moy - 1L) - (year(ad) * 12L + month(ad) - 1L)]
okw <- sm[, is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
smk <- sm[okw & !is.na(mask)]; sft <- sm[okw & !is.na(filt)]
cat("Search city-months: mask", nrow(smk), "filter", nrow(sft), "\n")
smk[, res := resid(feols(mask ~ temp + rh + rain + wind_speed | code_city + moy, data = smk))]
sft[, res := resid(feols(filt ~ temp + rh + rain + wind_speed | code_city + moy, data = sft))]
rm_ <- rd(smk$res, smk$xm, smk$code_city); show("Mask search col2", rm_)
rf_ <- rd(sft$res, sft$xm, sft$code_city); show("Filter search col2", rf_)

# ---------------- RESULTS ----------------
out <- c(
  rd_pm_daily_no_controls_table1_panelA_col1 = r1$coef,
  rd_pm_daily_controls_table1_panelA_col2 = r2$coef,
  rd_pm_daily_wave1_table1_panelA_col3 = r3$coef,
  rd_pm_daily_wave2_table1_panelA_col4 = r4$coef,
  rd_pm_daily_deadline_table1_panelA_col5 = r5$coef,
  rd_aod_monthly_controls_table1_panelA_col2 = ra$coef,
  event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 = unname(coef(fes1)["a12"]),
  event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 = unname(coef(fes2)["a12"]),
  event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 = unname(coef(fes3)["a12"]),
  event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 = unname(coef(fes5)["a12"]),
  n_obs_table1_panelB_deadline_cols1_2 = nobs(fes1),
  rd_face_mask_searches_controls_table2_panelA_col2 = rm_$coef,
  rd_air_filter_searches_controls_table2_panelA_col2 = rf_$coef)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
