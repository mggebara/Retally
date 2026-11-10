## Independent reproduction: Greenstone, He, Jia, Liu (2022) "Can Technology Solve the
## Principal-Agent Problem? Evidence from China's War on Air Pollution"
## Table 1 (Panels A and B) and Table 3/Table 2 (search RD, Panel A col 2).
suppressPackageStartupMessages({
  library(haven); library(data.table); library(fixest); library(rdrobust)
})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(nm) as.data.table(zap_labels(zap_formats(read_dta(paste0(D, nm)))))
S <- function(x) as.Date(x, origin = "1960-01-01")   # Stata daily dates

st <- rd("station_list.dta")
st[, auto := S(auto_date)]
## "Deadline" stations: automated exactly on a wave deadline (Jan 1 2013 or Jan 1 2014).
## This yields 242 stations automated 2013-01-01 and 123 automated 2014-01-01, as in the
## Table 1 notes (24 of the 242 are in cities listed as wave 2 that automated early on 2013-01-01).
st[, deadline := auto %in% as.Date(c("2013-01-01", "2014-01-01"))]
## residuals that skip fixed-effect singletons dropped by feols (as reghdfe does)
resid_into <- function(DT, fml) { m <- feols(fml, data = DT); out <- rep(NA_real_, nrow(DT)); out[obs(m)] <- resid(m); out }
cat("deadline stations by wave:\n"); print(st[, .N, by = .(phase, deadline)])
cat("deadline cities:", uniqueN(st[deadline == TRUE]$code_city), "\n")

po <- rd("pollution_1116.dta"); we <- rd("weather_1116.dta")
dd <- merge(po[, .(station_n, date, pm10)], we, by = c("station_n", "date"))
rm(po, we); gc(verbose = FALSE)
dd <- merge(dd, st[, .(station_n = pm10_n, code_city, phase, auto, deadline,
                        lon = station_lon, lat = station_lat)], by = "station_n")
dd[, d := S(date)]
dd[, `:=`(r = as.numeric(d - auto), year = as.integer(format(d, "%Y")),
          month = as.integer(format(d, "%m")))]
dd[, ym := year * 100L + month]
wx <- c("temp", "rh", "rain", "wind_speed")
daily <- dd[!is.na(pm10) & complete.cases(dd[, ..wx])]
cat("daily obs with pm10 and weather:", nrow(daily), " (pm10 only:", sum(!is.na(dd$pm10)), ")\n")

## Local linear RD, triangle kernel, CCT (2014) MSE-optimal bandwidth, city-clustered.
## masspoints = "off" mirrors the pre-2020 Stata rdrobust (no mass-point adjustment);
## with it the selected bandwidths equal the paper's (109 and 263 days in cols 1-2).
rdr <- function(y, x, cl) {
  ok <- !is.na(y); y <- y[ok]; x <- x[ok]; cl <- cl[ok]
  m <- rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd", cluster = cl, masspoints = "off")
  list(b = m$coef[1, 1], se = m$se[1, 1], h = m$bws[1, 1], n = sum(m$N_h))
}
show <- function(lab, z) cat(sprintf("  %-28s b=%9.4f se=%8.4f h=%8.2f N_h=%d\n", lab, z$b, z$se, z$h, z$n))

## ---------------- Table 1 Panel A: daily PM10 RD ----------------
c1 <- rdr(daily$pm10, daily$r, daily$code_city); show("PM10 col1 raw", c1)
f_res <- pm10 ~ temp + rh + rain + wind_speed | station_n + month
daily[, res := resid_into(daily, f_res)]
c2 <- rdr(daily$res, daily$r, daily$code_city); show("PM10 col2 resid", c2)
w1 <- daily[phase == 1]; c3 <- rdr(w1$res, w1$r, w1$code_city); show("PM10 col3 wave1", c3)
w2 <- daily[phase == 2]; c4 <- rdr(w2$res, w2$r, w2$code_city); show("PM10 col4 wave2", c4)
dl <- daily[deadline == TRUE]; c5 <- rdr(dl$res, dl$r, dl$code_city); show("PM10 col5 deadline", c5)
rm(w1, w2, dl)

## ---------------- AOD monthly RD ----------------
ao <- rd("aod_month.dta")
wm <- dd[, lapply(.SD, mean, na.rm = TRUE), by = .(station_n, year, month), .SDcols = wx]
ao <- merge(ao[, .(station_n = pm10_n, year, month, aod)], wm, by = c("station_n", "year", "month"))
ao <- merge(ao, st[, .(station_n = pm10_n, code_city, auto)], by = "station_n")
ao[, rm := (year * 12 + month) - (as.integer(format(auto, "%Y")) * 12 + as.integer(format(auto, "%m")))]
ao <- ao[!is.na(aod) & complete.cases(ao[, ..wx])]
cat("AOD station-month obs:", nrow(ao), "\n")
ao[, res := resid_into(ao, aod ~ temp + rh + rain + wind_speed | station_n + month)]
cat("AOD obs after singleton removal:", sum(!is.na(ao$res)), "\n")
a2 <- rdr(ao$res, ao$rm, ao$code_city); show("AOD col2 resid", a2)

## ---------------- Table 1 Panel B: event study ----------------
es <- daily[deadline == TRUE & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
es[, treat := as.integer(auto == as.Date("2013-01-01"))]
es[, bin := fcase(year == 2012 & month <= 6, "b7_12",
                  year == 2012 & month <= 8, "b5_6",
                  year == 2012 & month <= 10, "b3_4",
                  year == 2012, "b1_2",
                  year == 2013 & month <= 2, "a1_2",
                  year == 2013 & month <= 4, "a3_4",
                  year == 2013 & month <= 6, "a5_6",
                  default = "a7_12")]
mk <- function(D) { for (b in c("b7_12", "b5_6", "b3_4", "a1_2", "a3_4", "a5_6", "a7_12"))
  set(D, j = paste0("E_", b), value = as.integer(D$treat == 1 & D$bin == b)); D }
es <- mk(es)
ev <- "E_b7_12 + E_b5_6 + E_b3_4 + E_a1_2 + E_a3_4 + E_a5_6 + E_a7_12 + temp + rh + rain + wind_speed"
e1 <- feols(as.formula(paste("pm10 ~", ev, "| station_n + month")), data = es, cluster = ~code_city)
e2 <- feols(as.formula(paste("pm10 ~", ev, "| station_n + ym")), data = es, cluster = ~code_city)
cat("ES stations treated/control:", uniqueN(es[treat == 1]$station_n), uniqueN(es[treat == 0]$station_n), "\n")
cat("ES col1 nobs", nobs(e1), "\n"); print(coeftable(e1)[1:7, ]); print(coeftable(e2)[1:7, ])

## matching: each wave-1 deadline station -> nearest wave-2 deadline station (with replacement)
s1 <- st[auto == as.Date("2013-01-01")]; s2 <- st[auto == as.Date("2014-01-01")]
hav <- function(lat1, lon1, lat2, lon2) { r <- pi / 180
  a <- sin((lat2 - lat1) * r / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin((lon2 - lon1) * r / 2)^2
  2 * 6371 * asin(sqrt(a)) }
s1[, match := sapply(seq_len(.N), function(i) s2$pm10_n[which.min(hav(station_lat[i], station_lon[i], s2$station_lat, s2$station_lon))])]
mt <- rbind(es[treat == 1],
            rbindlist(lapply(s1$match, function(m) es[station_n == m])))
cat("matched sample obs:", nrow(mt), " unique controls:", uniqueN(s1$match), "\n")
e3 <- feols(as.formula(paste("pm10 ~", ev, "| station_n + month")), data = mt, cluster = ~code_city)
mtl <- mt[pm10 > 0]; mtl[, lpm := log(pm10)]
e5 <- feols(as.formula(paste("lpm ~", ev, "| station_n + ym")), data = mtl, cluster = ~code_city)
print(coeftable(e3)[1:7, ]); cat("e3 nobs", nobs(e3), " e5 nobs", nobs(e5), "\n"); print(coeftable(e5)[1:7, ])

## ---------------- Search RD (city-month) ----------------
ms <- rd("mask_filter_search.dta")
ms <- ms[code_city %in% st$code_city]
ms[, d := S(date)][, `:=`(year = as.integer(format(d, "%Y")), month = as.integer(format(d, "%m")))]
msm <- ms[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)), by = .(code_city, year, month)]
cw <- dd[, lapply(.SD, mean, na.rm = TRUE), by = .(code_city, year, month), .SDcols = wx]
msm <- merge(msm, cw, by = c("code_city", "year", "month"))
cauto <- st[, .N, by = .(code_city, auto)][order(code_city, -N, auto)][, .SD[1], by = code_city]
msm <- merge(msm, cauto[, .(code_city, auto)], by = "code_city")
msm[, rm := (year * 12 + month) - (as.integer(format(auto, "%Y")) * 12 + as.integer(format(auto, "%m")))]
msm <- msm[complete.cases(msm[, ..wx])]
for (v in c("mask", "filter")) {
  sub <- msm[is.finite(get(v))]
  sub[, res := resid_into(sub, as.formula(paste(v, "~ temp + rh + rain + wind_speed | code_city + month")))]
  z <- rdr(sub$res, sub$rm, sub$code_city); show(paste("search", v), z); assign(paste0("s_", v), z)
  cat("  obs", nrow(sub), "\n")
}

cat(sprintf("RESULT:rd_pm_daily_no_controls_table1_panelA_col1=%.4f\n", c1$b))
cat(sprintf("RESULT:rd_pm_daily_controls_table1_panelA_col2=%.4f\n", c2$b))
cat(sprintf("RESULT:rd_pm_daily_wave1_table1_panelA_col3=%.4f\n", c3$b))
cat(sprintf("RESULT:rd_pm_daily_wave2_table1_panelA_col4=%.4f\n", c4$b))
cat(sprintf("RESULT:rd_pm_daily_deadline_table1_panelA_col5=%.4f\n", c5$b))
cat(sprintf("RESULT:rd_aod_monthly_controls_table1_panelA_col2=%.5f\n", a2$b))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1=%.4f\n", coef(e1)[["E_a1_2"]]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2=%.4f\n", coef(e2)[["E_a1_2"]]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3=%.4f\n", coef(e3)[["E_a1_2"]]))
cat(sprintf("RESULT:event_study_log_pm_1_2_months_after_matched_table1_panelB_col5=%.4f\n", coef(e5)[["E_a1_2"]]))
cat(sprintf("RESULT:n_obs_table1_panelB_deadline_cols1_2=%d\n", nobs(e1)))
cat(sprintf("RESULT:rd_face_mask_searches_controls_table2_panelA_col2=%.4f\n", s_mask$b))
cat(sprintf("RESULT:rd_air_filter_searches_controls_table2_panelA_col2=%.4f\n", s_filter$b))
