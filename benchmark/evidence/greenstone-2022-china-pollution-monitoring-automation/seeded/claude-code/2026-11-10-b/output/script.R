# Reproduction of Greenstone, He, Jia, Liu (2022) "Can Technology Solve the
# Principal-Agent Problem? Evidence from China's War on Air Pollution"
# Translates Prepare_Data.do + Tables.do (Table 1 Panels A/B, Table 2 Panel A) to R.
suppressPackageStartupMessages({
  library(haven); library(data.table); library(rdrobust); library(fixest)
})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/seeded/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(D, f)))))

pol  <- rd("pollution_1116.dta")
wea  <- rd("weather_1116.dta")
stl  <- rd("station_list.dta")
mfs  <- rd("mask_filter_search.dta")
aodm <- rd("aod_month.dta")

# Stata %td dates are days since 1960-01-01 (kept numeric here)
stata_date <- function(d) as.Date(d, origin = "1960-01-01")
DL1 <- 19359  # 2013-01-01
DL2 <- 19724  # 2014-01-01

## ---- 1. station_day_1116 --------------------------------------------------
sd <- merge(pol, wea, by = c("station_n", "date"), all = TRUE)
setnames(sd, "station_n", "pm10_n")
sd <- merge(sd, stl[, .(pm10_n, phase, auto_date)], by = "pm10_n", all = TRUE)
dd <- stata_date(sd$date)
sd[, `:=`(year = as.integer(format(dd, "%Y")), month = as.integer(format(dd, "%m")))]
sd[, T := date - auto_date]
setorder(sd, pm10_n, date)

rdr <- function(y, x, cl) {
  r <- rdrobust(y, x, c = 0, p = 1, q = 2, kernel = "triangular",
                vce = "cr1", cluster = cl, masspoints = "off")
  list(coef = unname(r$coef[1, 1]), se = unname(r$se[1, 1]),
       N = sum(r$N_h), h = unname(r$bws[1, 1]))
}
show <- function(lbl, r) cat(sprintf("%-28s coef=%9.4f se=%8.4f Neff=%7d h=%8.2f\n",
                                     lbl, r$coef, r$se, r$N, r$h))

## ---- Table 1A row 1: daily PM10 RD -----------------------------------------
m <- feols(pm10 ~ wind_speed + rain + temp + rh | pm10_n + month, data = sd,
           fixef.rm = "none", notes = FALSE)
sd[, resid_pm10_smw := NA_real_]
sd[obs(m), resid_pm10_smw := resid(m)]
cat("Residualization N:", nobs(m), "\n")

cc <- with(sd, !is.na(temp) & !is.na(rain) & !is.na(rh) & !is.na(wind_speed))
r1 <- with(sd[cc], rdr(pm10, T, code_city));               show("col1 raw", r1)
r2 <- with(sd, rdr(resid_pm10_smw, T, code_city));          show("col2 resid", r2)
r3 <- with(sd[phase == 1], rdr(resid_pm10_smw, T, code_city)); show("col3 wave1", r3)
r4 <- with(sd[phase == 2], rdr(resid_pm10_smw, T, code_city)); show("col4 wave2", r4)
r5 <- with(sd[auto_date %in% c(DL1, DL2)], rdr(resid_pm10_smw, T, code_city)); show("col5 deadline", r5)

## ---- Table 1A row 2: monthly AOD RD ----------------------------------------
# station_month: monthly means (egen mean ignores missing) of pm10..rh
mon_idx <- function(d) { x <- stata_date(d); as.integer(format(x, "%Y")) * 12L + as.integer(format(x, "%m")) - 1L }
sd[, n_month := mon_idx(date) - mon_idx(auto_date)]
mmean <- function(v) if (all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE)
sm <- sd[, .(pm10 = mmean(pm10), wind_speed = mmean(wind_speed), rain = mmean(rain),
             temp = mmean(temp), rh = mmean(rh), code_city = code_city[1],
             phase = phase[1], auto_date = auto_date[1], n_month = n_month[1]),
         by = .(pm10_n, year, month)]
sm <- merge(sm, aodm, by = c("pm10_n", "year", "month"))  # keep(match)
ma <- feols(aod ~ wind_speed + rain + temp + rh | pm10_n + month, data = sm,
            fixef.rm = "none", notes = FALSE)
sm[, resid_aod_smw := NA_real_]
sm[obs(ma), resid_aod_smw := resid(ma)]
ra2 <- with(sm, rdr(resid_aod_smw, n_month, code_city)); show("AOD col2 resid", ra2)

## ---- Table 1B: event study (deadline sample) -------------------------------
add_es <- function(d) {
  d[, treat := as.integer(auto_date == DL1)]
  d[, `:=`(
    tb712 = treat * (year == 2012 & month <= 6),
    tb56  = treat * (year == 2012 & month %in% 7:8),
    tb34  = treat * (year == 2012 & month %in% 9:10),
    ta12  = treat * (year == 2013 & month %in% 1:2),
    ta34  = treat * (year == 2013 & month %in% 3:4),
    ta56  = treat * (year == 2013 & month %in% 5:6),
    ta712 = treat * (year == 2013 & month >= 7))]
  d[, year_month := year * 100L + month]
  d
}
es_f <- ~ tb712 + tb56 + tb34 + ta12 + ta34 + ta56 + ta712 + wind_speed + rain + temp + rh
ddl <- add_es(sd[year %in% 2012:2013 & auto_date %in% c(DL1, DL2)])
e1 <- feols(as.formula(paste("pm10 ~", as.character(es_f)[2], "| pm10_n + month")),
            data = ddl, cluster = ~code_city, fixef.rm = "none", notes = FALSE)
e2 <- feols(as.formula(paste("pm10 ~", as.character(es_f)[2], "| pm10_n + year_month")),
            data = ddl, cluster = ~code_city, fixef.rm = "none", notes = FALSE)
cat("ES col1 ta12:", coef(e1)["ta12"], se(e1)["ta12"], "N", nobs(e1), "\n")
cat("ES col2 ta12:", coef(e2)["ta12"], se(e2)["ta12"], "N", nobs(e2), "\n")

## ---- Matched sample (geonear: nearest Wave-2 deadline station, ellipsoid, <=400km)
vincenty <- function(lat1, lon1, lat2, lon2) {
  a <- 6378137; f <- 1 / 298.257223563; b <- (1 - f) * a
  rad <- pi / 180
  L <- (lon2 - lon1) * rad
  U1 <- atan((1 - f) * tan(lat1 * rad)); U2 <- atan((1 - f) * tan(lat2 * rad))
  sU1 <- sin(U1); cU1 <- cos(U1); sU2 <- sin(U2); cU2 <- cos(U2)
  lam <- L
  for (it in 1:200) {
    sl <- sin(lam); cl <- cos(lam)
    ss <- sqrt((cU2 * sl)^2 + (cU1 * sU2 - sU1 * cU2 * cl)^2)
    cs <- sU1 * sU2 + cU1 * cU2 * cl
    sig <- atan2(ss, cs)
    sa <- ifelse(ss == 0, 0, cU1 * cU2 * sl / ss)
    c2a <- 1 - sa^2
    c2sm <- ifelse(c2a == 0, 0, cs - 2 * sU1 * sU2 / c2a)
    C <- f / 16 * c2a * (4 + f * (4 - 3 * c2a))
    lp <- lam
    lam <- L + (1 - C) * f * sa * (sig + C * ss * (c2sm + C * cs * (-1 + 2 * c2sm^2)))
    if (all(abs(lam - lp) < 1e-12)) break
  }
  u2 <- c2a * (a^2 - b^2) / b^2
  A <- 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)))
  B <- u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)))
  ds <- B * ss * (c2sm + B / 4 * (cs * (-1 + 2 * c2sm^2) - B / 6 * c2sm * (-3 + 4 * ss^2) * (-3 + 4 * c2sm^2)))
  b * A * (sig - ds) / 1000
}
s1 <- stl[auto_date == DL1]; s2 <- stl[auto_date == DL2]
match <- rbindlist(lapply(seq_len(nrow(s1)), function(i) {
  dk <- vincenty(s1$station_lat[i], s1$station_lon[i], s2$station_lat, s2$station_lon)
  j <- which.min(dk)
  data.table(pm10_n1 = s1$pm10_n[i], pm10_n = s2$pm10_n[j], km = dk[j])
}))
match <- match[km <= 400]
cat("Matched treated stations:", nrow(match), " distinct controls:", uniqueN(match$pm10_n), "\n")
sd12 <- sd[year %in% 2012:2013]
tr <- sd12[pm10_n %in% match$pm10_n1]
ct <- merge(sd12, match[, .(pm10_n)], by = "pm10_n", allow.cartesian = TRUE)  # joinby: replicate per match
mt <- add_es(rbind(tr, ct, use.names = TRUE))
mt[, l_pm10 := ifelse(pm10 > 0, log(pm10), NA_real_)]
e3 <- feols(as.formula(paste("pm10 ~", as.character(es_f)[2], "| pm10_n + month")),
            data = mt, cluster = ~code_city, fixef.rm = "none", notes = FALSE)
e5 <- feols(as.formula(paste("l_pm10 ~", as.character(es_f)[2], "| pm10_n + year_month")),
            data = mt, cluster = ~code_city, fixef.rm = "none", notes = FALSE)
cat("ES col3 ta12:", coef(e3)["ta12"], se(e3)["ta12"], "N", nobs(e3), "\n")
cat("ES col5 ta12:", coef(e5)["ta12"], se(e5)["ta12"], "N", nobs(e5), "\n")

## ---- Table 2A: city-month Baidu searches -----------------------------------
# city-day: mean over stations of pm10..rh; auto_date/phase from station with latest auto_date
setorder(sd, code_city, date, -auto_date, pm10_n)
cd <- sd[, .(wind_speed = mmean(wind_speed), rain = mmean(rain), temp = mmean(temp),
             rh = mmean(rh), auto_date = auto_date[1], phase = phase[1]),
         by = .(code_city, date)]
cd <- merge(cd, mfs, by = c("code_city", "date"))   # keep(match)
cdd <- stata_date(cd$date)
cd[, `:=`(year = as.integer(format(cdd, "%Y")), month = as.integer(format(cdd, "%m")))]
cd[, n_month := mon_idx(date) - mon_idx(auto_date)]
cm <- cd[, .(wind_speed = mmean(wind_speed), rain = mmean(rain), temp = mmean(temp),
             rh = mmean(rh), pmmask = mmean(pmmask), filter = mmean(filter),
             year = year[1], month = month[1]),
         by = .(code_city, n_month)]
res_search <- list()
for (y in c("pmmask", "filter")) {
  ms <- feols(as.formula(paste(y, "~ wind_speed + rain + temp + rh | code_city + month")),
              data = cm, fixef.rm = "none", notes = FALSE)
  cm[, rr := NA_real_]; cm[obs(ms), rr := resid(ms)]
  res_search[[y]] <- with(cm, rdr(rr, n_month, code_city))
  show(paste("search", y, "col2"), res_search[[y]])
}

## ---- Results ---------------------------------------------------------------
out <- c(
  rd_pm_daily_no_controls_table1_panelA_col1 = r1$coef,
  rd_pm_daily_controls_table1_panelA_col2 = r2$coef,
  rd_pm_daily_wave1_table1_panelA_col3 = r3$coef,
  rd_pm_daily_wave2_table1_panelA_col4 = r4$coef,
  rd_pm_daily_deadline_table1_panelA_col5 = r5$coef,
  rd_aod_monthly_controls_table1_panelA_col2 = ra2$coef,
  event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1 = unname(coef(e1)["ta12"]),
  event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2 = unname(coef(e2)["ta12"]),
  event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3 = unname(coef(e3)["ta12"]),
  event_study_log_pm_1_2_months_after_matched_table1_panelB_col5 = unname(coef(e5)["ta12"]),
  n_obs_table1_panelB_deadline_cols1_2 = nobs(e1),
  rd_face_mask_searches_controls_table2_panelA_col2 = res_search$pmmask$coef,
  rd_air_filter_searches_controls_table2_panelA_col2 = res_search$filter$coef
)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
