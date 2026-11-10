# Independent reproduction: Greenstone, He, Jia, Liu (2022) "Can Technology Solve the
# Principal-Agent Problem? Evidence from China's War on Air Pollution", Table 1 and Table 3 (Table 2 in AER:I)
suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
D13 <- 19359; D14 <- 19724   # Stata dates of 2013-01-01 and 2014-01-01 (wave deadlines)

sl <- as.data.table(read_dta(paste0(D, "station_list.dta")))
ci <- as.data.table(read_dta(paste0(D, "city_info.dta")))
p  <- as.data.table(read_dta(paste0(D, "pollution_1116.dta")))
w  <- as.data.table(read_dta(paste0(D, "weather_1116.dta")))
p <- merge(p, w, by = c("station_n", "date"))
p <- merge(p, sl[, .(station_n = pm10_n, auto_date, phase, lon = station_lon, lat = station_lat)], by = "station_n")
p[, d := as.Date(date, origin = "1960-01-01")]
p[, `:=`(yr = year(d), moy = month(d))]
p[, ym := yr * 100L + moy]
p[, rv := date - auto_date]          # days from automation (running variable)
p[, wok := !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
p[, deadline := auto_date %in% c(D13, D14)]

# masspoints = "off": with it the CCT MSE-optimal bandwidths reproduce the paper's reported ones
# (109 and 263 days, 91,470 and 232,326 effective obs.), i.e. the classic rdrobust selector without mass-point adjustment
rdr <- function(y, x, cl, label, mp = "off", clus = TRUE) {
  r <- if (clus) rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd", vce = "cr1", cluster = cl, masspoints = mp)
       else rdrobust(y, x, c = 0, p = 1, kernel = "triangular", bwselect = "mserd", vce = "nn", masspoints = mp)
  cat(sprintf("  %-40s coef=%.4f se=%.4f h=%.2f N_eff=%d\n", label, r$coef[1], r$se[1], r$bws[1, 1], sum(r$N_h)))
  r
}
# residuals aligned to the rows used (fixest drops singleton FE obs)
addres <- function(dt, f) { dt[, res := NA_real_]; dt[obs(f), res := resid(f)]; dt[!is.na(res)] }

# ---------------- Table 1 Panel A: RD in daily PM10 ----------------
pd <- p[!is.na(pm10) & wok]
cat("Daily RD sample (pm10 & weather nonmissing):", nrow(pd), "(paper: 1,049,325)\n")
r1 <- rdr(pd$pm10, pd$rv, pd$code_city, "col1 raw PM10")
fr <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + moy, data = pd)
pd <- addres(pd, fr)
r2 <- rdr(pd$res, pd$rv, pd$code_city, "col2 residual PM10, all")
s3 <- pd[phase == 1]; r3 <- rdr(s3$res, s3$rv, s3$code_city, "col3 residual PM10, wave 1")
s4 <- pd[phase == 2]; r4 <- rdr(s4$res, s4$rv, s4$code_city, "col4 residual PM10, wave 2")
s5 <- pd[deadline == TRUE]
cat("  deadline cities:", uniqueN(s5$code_city), " stations:", uniqueN(s5$station_n), "\n")
r5 <- rdr(s5$res, s5$rv, s5$code_city, "col5 residual PM10, deadline")

# ---------------- Table 1 Panel A: RD in monthly AOD ----------------
a <- as.data.table(read_dta(paste0(D, "aod_month.dta")))
sw <- p[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
            ws = mean(wind_speed, na.rm = TRUE)), by = .(station_n, yr, moy)]
a <- merge(a, sw, by.x = c("pm10_n", "year", "month"), by.y = c("station_n", "yr", "moy"))
a <- merge(a, sl[, .(pm10_n, code_city, auto_date, phase)], by = "pm10_n")
ad <- as.Date(a$auto_date, origin = "1960-01-01")
a[, rvm := (year * 12 + month) - (year(ad) * 12 + month(ad))]
a <- a[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(ws)]
cat("AOD station-month sample:", nrow(a), "\n")
fa <- feols(aod ~ temp + rh + rain + ws | pm10_n + month, data = a)
a <- addres(a, fa)
ra <- rdr(a$res, a$rvm, a$code_city, "AOD col2 residual, all")

# ---------------- Table 1 Panel B: event study ----------------
es <- pd[deadline == TRUE & date >= 18993 & date <= 19723]   # 2012-01-01 .. 2013-12-31
cat("Event-study sample:", nrow(es), "(paper: 176,426); W1 stations", uniqueN(es[auto_date == D13]$station_n),
    " W2 stations", uniqueN(es[auto_date == D14]$station_n), "\n")
mkbins <- function(dt) {
  dt[, treat := as.integer(auto_date == D13)]
  dt[, relm := (yr - 2013L) * 12L + (moy - 1L)]
  dt[, `:=`(b_m4 = treat * (relm >= -12 & relm <= -7), b_m3 = treat * (relm %in% -6:-5),
            b_m2 = treat * (relm %in% -4:-3), b_a1 = treat * (relm %in% 0:1),
            b_a2 = treat * (relm %in% 2:3), b_a3 = treat * (relm %in% 4:5),
            b_a4 = treat * (relm >= 6 & relm <= 11))]
  dt
}
es <- mkbins(es)
rhs <- "b_m4 + b_m3 + b_m2 + b_a1 + b_a2 + b_a3 + b_a4 + temp + rh + rain + wind_speed"
e1 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = es, cluster = ~code_city)
e2 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + ym")), data = es, cluster = ~code_city)
cat("ES col1:\n"); print(coeftable(e1)[1:7, 1:2]); cat("N=", nobs(e1), " R2=", r2(e1, "r2"), "\n")
cat("ES col2:\n"); print(coeftable(e2)[1:7, 1:2]); cat("N=", nobs(e2), "\n")

# matched sample: each Wave-1 deadline station paired with geographically nearest Wave-2 deadline station (with replacement)
st <- unique(es[, .(station_n, code_city, auto_date, lon, lat)])
t1 <- st[auto_date == D13]; t2 <- st[auto_date == D14]
hav <- function(lo1, la1, lo2, la2) { r <- pi / 180; dl <- (lo2 - lo1) * r; dp <- (la2 - la1) * r
  q <- sin(dp / 2)^2 + cos(la1 * r) * cos(la2 * r) * sin(dl / 2)^2; 2 * 6371 * asin(sqrt(pmin(1, q))) }
t1[, m := sapply(seq_len(.N), function(i) t2$station_n[which.min(hav(lon[i], lat[i], t2$lon, t2$lat))])]
cat("Matched: W1 stations", nrow(t1), " distinct matched W2 stations", uniqueN(t1$m), "\n")
# paired sample: each pair contributes the W1 station and its matched W2 station (controls duplicated across pairs)
esm <- rbind(es[station_n %in% t1$station_n],
             es[data.table(station_n = t1$m), on = "station_n", allow.cartesian = TRUE])
esu <- es[station_n %in% c(t1$station_n, t1$m)]
cat("Matched sample obs (pairs, duplicated controls):", nrow(esm), " (unique stations):", nrow(esu), " (paper 186,499)\n")
# Final choice (after comparing attempt 8 with the claims): matched sample = the Wave-1 deadline stations plus the
# distinct set of Wave-2 deadline stations that are someone's nearest neighbour, each station entering once.
e3p <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = esm, cluster = ~code_city)
e5p <- feols(as.formula(paste("log(pm10) ~", rhs, "| station_n + ym")), data = esm[pm10 > 0], cluster = ~code_city)
e3 <- feols(as.formula(paste("pm10 ~", rhs, "| station_n + moy")), data = esu, cluster = ~code_city)
e5 <- feols(as.formula(paste("log(pm10) ~", rhs, "| station_n + ym")), data = esu[pm10 > 0], cluster = ~code_city)
cat("ES col3 (matched, distinct stations):\n"); print(coeftable(e3)[1:7, 1:2]); cat("N=", nobs(e3), "\n")
cat("ES col5 (matched, distinct stations):\n"); print(coeftable(e5)[1:7, 1:2]); cat("N=", nobs(e5), "\n")
cat("Alternative (pairs, duplicated controls) col3 a1:", coef(e3p)["b_a1"], " col5 a1:", coef(e5p)["b_a1"], "\n")
cat("DEVIATION: matched sample has", nobs(e3), "obs (paper 186,499); the paper's matching construction could not be pinned down from the text\n")

# ---------------- Table 3 (AER:I Table 2) Panel A: RD in Baidu searches ----------------
ms <- as.data.table(read_dta(paste0(D, "mask_filter_search.dta")))
ms <- ms[code_city %in% ci$code_city]
ms[, dd := as.Date(date, origin = "1960-01-01")]
mm <- ms[, .(mask = mean(pmmask), filter = mean(filter)), by = .(code_city, yr = year(dd), moy = month(dd))]
cw <- p[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
            ws = mean(wind_speed, na.rm = TRUE)), by = .(code_city, yr, moy)]
mm <- merge(mm, cw, by = c("code_city", "yr", "moy"))
# city automation date: the date shared by most of the city's stations (a few cities have stations with
# different dates); ties broken by the earliest date
cauto <- sl[, .N, by = .(code_city, auto_date)][order(code_city, -N, auto_date)][, .SD[1], by = code_city][, .(code_city, auto_date)]
mm <- merge(mm, cauto, by = "code_city")
cad <- as.Date(mm$auto_date, origin = "1960-01-01")
mm[, rvm := (yr * 12 + moy) - (year(cad) * 12 + month(cad))]
mm <- mm[is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(ws)]
mk <- mm[!is.na(mask)]; fl <- mm[!is.na(filter)]
cat("Search samples: mask", nrow(mk), "(paper 8,661) filter", nrow(fl), "(paper 8,590)\n")
fm <- feols(mask ~ temp + rh + rain + ws | code_city + moy, data = mk); mk <- addres(mk, fm)
ff <- feols(filter ~ temp + rh + rain + ws | code_city + moy, data = fl); fl <- addres(fl, ff)
rm1 <- rdr(mk$mask, mk$rvm, mk$code_city, "mask col1 raw")
rm2 <- rdr(mk$res, mk$rvm, mk$code_city, "mask col2 residual")
rf1 <- rdr(fl$filter, fl$rvm, fl$code_city, "filter col1 raw")
rf2 <- rdr(fl$res, fl$rvm, fl$code_city, "filter col2 residual")

cat(sprintf("RESULT:rd_pm_daily_no_controls_table1_panelA_col1=%.6f\n", r1$coef[1]))
cat(sprintf("RESULT:rd_pm_daily_controls_table1_panelA_col2=%.6f\n", r2$coef[1]))
cat(sprintf("RESULT:rd_pm_daily_wave1_table1_panelA_col3=%.6f\n", r3$coef[1]))
cat(sprintf("RESULT:rd_pm_daily_wave2_table1_panelA_col4=%.6f\n", r4$coef[1]))
cat(sprintf("RESULT:rd_pm_daily_deadline_table1_panelA_col5=%.6f\n", r5$coef[1]))
cat(sprintf("RESULT:rd_aod_monthly_controls_table1_panelA_col2=%.6f\n", ra$coef[1]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1=%.6f\n", coef(e1)["b_a1"]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2=%.6f\n", coef(e2)["b_a1"]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3=%.6f\n", coef(e3)["b_a1"]))
cat(sprintf("RESULT:event_study_log_pm_1_2_months_after_matched_table1_panelB_col5=%.6f\n", coef(e5)["b_a1"]))
cat(sprintf("RESULT:n_obs_table1_panelB_deadline_cols1_2=%d\n", nobs(e1)))
cat(sprintf("RESULT:rd_face_mask_searches_controls_table2_panelA_col2=%.6f\n", rm2$coef[1]))
cat(sprintf("RESULT:rd_air_filter_searches_controls_table2_panelA_col2=%.6f\n", rf2$coef[1]))
