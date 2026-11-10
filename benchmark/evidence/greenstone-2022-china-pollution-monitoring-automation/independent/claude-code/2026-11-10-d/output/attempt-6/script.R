# Greenstone, He, Jia, Liu (2022) -- independent reproduction of Table 1 (Panels A/B) and Table 2 Panel A col (2)
set.seed(42)
suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
base <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(base, f)))))
D1 <- 19359  # 2013-01-01, Wave 1 deadline (Stata date)
D2 <- 19724  # 2014-01-01, Wave 2 deadline

st <- rd("station_list.dta"); ci <- rd("city_info.dta")
p <- rd("pollution_1116.dta"); w <- rd("weather_1116.dta")
stopifnot(all(w$station_n == p$station_n & w$date == p$date))
p[, c("wind_speed","rain","temp","rh") := w[, .(wind_speed, rain, temp, rh)]]
rm(w); invisible(gc())
p[, c("no2","so2") := NULL]
p <- merge(p, st[, .(station_n = pm10_n, phase, auto_date)], by = "station_n")
p[, dd := as.IDate(date, origin = "1960-01-01")]
p[, `:=`(yr = year(dd), mo = month(dd))]
p[, ym := yr * 100L + mo]
wok <- function(d) !is.na(d$wind_speed) & !is.na(d$rain) & !is.na(d$temp) & !is.na(d$rh)

# ---------------- Panel A: daily RD ----------------
d <- p[!is.na(pm10) & wok(p)]   # 1,049,325 obs, matching the paper's count
cat("Daily RD sample:", nrow(d), "\n")
d[, x := date - auto_date]
rdfit <- function(y, x, cl) {
  r <- rdrobust(y, x, c = 0, kernel = "triangular", bwselect = "mserd", cluster = cl, vce = "hc1", masspoints = "off")
  list(b = r$coef[1], se = r$se[1], h = r$bws[1, 1], n = sum(r$N_h))
}
resid_rd <- function(dat) {
  m <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + mo, data = dat)
  dat <- copy(dat); dat[, res := resid(m, na.rm = FALSE)]
  rdfit(dat$res, dat$x, dat$code_city)
}
r1 <- rdfit(d$pm10, d$x, d$code_city)
r2 <- resid_rd(d)
r3 <- resid_rd(d[phase == 1])
r4 <- resid_rd(d[phase == 2])
r5 <- resid_rd(d[auto_date %in% c(D1, D2)])
# diagnostic: subsamples using residuals from the full-sample (column 2) residualization
mfull <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + mo, data = d)
d[, resF := resid(mfull, na.rm = FALSE)]
for (g in list(d$phase == 1, d$phase == 2, d$auto_date %in% c(D1, D2))) { rr <- rdfit(d$resF[g], d$x[g], d$code_city[g]); cat("diag full-resid subsample: b=", rr$b, " h=", rr$h, " N_h=", rr$n, "\n") }
for (nm in c("r1","r2","r3","r4","r5")) { r <- get(nm); cat(nm, ": b=", r$b, " se=", r$se, " h=", r$h, " N_h=", r$n, "\n") }

# ---------------- Panel A: monthly AOD RD ----------------
aod <- rd("aod_month.dta")
wm <- p[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
            wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(station_n, yr, mo)]
aod <- merge(aod[, .(station_n = pm10_n, yr = year, mo = month, aod)], wm, by = c("station_n", "yr", "mo"))
aod <- merge(aod, st[, .(station_n = pm10_n, code_city, auto_date)], by = "station_n")
aod[, ad := as.IDate(auto_date, origin = "1960-01-01")]
aod[, x := (yr * 12 + mo) - (year(ad) * 12 + month(ad))]
aod <- aod[!is.na(aod) & is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
ma <- feols(aod ~ temp + rh + rain + wind_speed | station_n + mo, data = aod)
aod[, res := resid(ma, na.rm = FALSE)]
ra <- rdfit(aod$res, aod$x, aod$code_city)
cat("AOD: n=", nrow(aod), " b=", ra$b, " se=", ra$se, " h=", ra$h, " N_h=", ra$n, "\n")

# ---------------- Panel B: event study ----------------
es <- p[dd >= as.IDate("2012-01-01") & dd <= as.IDate("2013-12-31") & auto_date %in% c(D1, D2) & !is.na(pm10)]
es <- es[wok(es)]
es[, treat := as.integer(auto_date == D1)]
es[, rel := (yr - 2013L) * 12L + (mo - 1L)]   # months relative to Jan 2013 (0 = Jan 2013)
es[, `:=`(b712 = treat * (rel >= -12 & rel <= -7), b56 = treat * (rel %in% -6:-5), b34 = treat * (rel %in% -4:-3),
          a12 = treat * (rel %in% 0:1), a34 = treat * (rel %in% 2:3), a56 = treat * (rel %in% 4:5), a712 = treat * (rel >= 6))]
cat("ES sample:", nrow(es), " treated stations:", es[treat == 1, uniqueN(station_n)], " control:", es[treat == 0, uniqueN(station_n)], "\n")
rhs <- "b712 + b56 + b34 + a12 + a34 + a56 + a712 + temp + rh + rain + wind_speed"
fm <- function(y, fe) as.formula(paste(y, "~", rhs, "|", fe))
e1 <- feols(fm("pm10", "station_n + mo"), data = es, cluster = ~code_city)
e2 <- feols(fm("pm10", "station_n + ym"), data = es, cluster = ~code_city)

# nearest-neighbour matching (great-circle distance), with replacement: each treated station paired
# with its nearest control station; the paired sample stacks the pairs (controls repeat when reused)
s1 <- st[auto_date == D1]; s2 <- st[auto_date == D2]
hav <- function(lon1, lat1, lon2, lat2) { r <- pi/180; a <- sin((lat2-lat1)*r/2)^2 + cos(lat1*r)*cos(lat2*r)*sin((lon2-lon1)*r/2)^2; 2*6371*asin(sqrt(a)) }
s1[, ctrl := sapply(seq_len(.N), function(i) s2$pm10_n[which.min(hav(station_lon[i], station_lat[i], s2$station_lon, s2$station_lat))])]
pairs <- data.table(pair = seq_len(nrow(s1)), tr = s1$pm10_n, ct = s1$ctrl)
em <- rbind(merge(pairs[, .(pair, station_n = tr)], es, by = "station_n", allow.cartesian = TRUE),
            merge(pairs[, .(pair, station_n = ct)], es, by = "station_n", allow.cartesian = TRUE))
cat("Matched sample:", nrow(em), " unique controls:", uniqueN(pairs$ct), "\n")
e3 <- feols(fm("pm10", "station_n + mo"), data = em, cluster = ~code_city)
e4 <- feols(fm("pm10", "station_n + ym"), data = em, cluster = ~code_city)
e5 <- feols(fm("log(pm10)", "station_n + ym"), data = em[pm10 > 0], cluster = ~code_city)
emu <- es[station_n %in% c(pairs$tr, unique(pairs$ct))]
e3u <- feols(fm("pm10", "station_n + mo"), data = emu, cluster = ~code_city)
cat("diag matched (unique controls, unstacked): n=", nobs(e3u), " a12=", coef(e3u)["a12"], "\n")
etable(e1, e2, e3, e4, e5, keep = c("b712","b56","b34","a12","a34","a56","a712"))

# ---------------- Table 2 Panel A: search RD ----------------
ms <- rd("mask_filter_search.dta")[code_city %in% ci$code_city]
ms[, dd := as.IDate(date, origin = "1960-01-01")]
ms <- ms[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)), by = .(code_city, yr = year(dd), mo = month(dd))]
wc <- p[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE),
            wind_speed = mean(wind_speed, na.rm = TRUE)), by = .(code_city, yr, mo)]
ms <- merge(ms, wc, by = c("code_city", "yr", "mo"))
ms <- ms[is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(wind_speed)]
# city automation date: the date most of the city's stations automated (ties -> earliest)
ca <- st[, .N, by = .(code_city, auto_date)][order(code_city, -N, auto_date)][, .SD[1], by = code_city]
ms <- merge(ms, ca[, .(code_city, auto_date)], by = "code_city")
ms[, ad := as.IDate(auto_date, origin = "1960-01-01")]
ms[, x := (yr * 12 + mo) - (year(ad) * 12 + month(ad))]
srd <- function(v) {
  dd_ <- ms[is.finite(get(v))]
  m <- feols(as.formula(paste(v, "~ temp + rh + rain + wind_speed | code_city + mo")), data = dd_)
  dd_[, res := resid(m, na.rm = FALSE)]
  c(n = nrow(dd_), unlist(rdfit(dd_$res, dd_$x, dd_$code_city)))
}
sm <- srd("mask"); sf <- srd("filter")
print(rbind(mask = sm, filter = sf))

cat(sprintf("RESULT:rd_pm_daily_no_controls_table1_panelA_col1=%.4f\n", r1$b))
cat(sprintf("RESULT:rd_pm_daily_controls_table1_panelA_col2=%.4f\n", r2$b))
cat(sprintf("RESULT:rd_pm_daily_wave1_table1_panelA_col3=%.4f\n", r3$b))
cat(sprintf("RESULT:rd_pm_daily_wave2_table1_panelA_col4=%.4f\n", r4$b))
cat(sprintf("RESULT:rd_pm_daily_deadline_table1_panelA_col5=%.4f\n", r5$b))
cat(sprintf("RESULT:rd_aod_monthly_controls_table1_panelA_col2=%.5f\n", ra$b))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_month_fe_table1_panelB_col1=%.4f\n", coef(e1)["a12"]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_deadline_year_month_fe_table1_panelB_col2=%.4f\n", coef(e2)["a12"]))
cat(sprintf("RESULT:event_study_pm_1_2_months_after_matched_month_fe_table1_panelB_col3=%.4f\n", coef(e3)["a12"]))
cat(sprintf("RESULT:event_study_log_pm_1_2_months_after_matched_table1_panelB_col5=%.4f\n", coef(e5)["a12"]))
cat(sprintf("RESULT:n_obs_table1_panelB_deadline_cols1_2=%d\n", nobs(e1)))
cat(sprintf("RESULT:rd_face_mask_searches_controls_table2_panelA_col2=%.4f\n", sm["b"]))
cat(sprintf("RESULT:rd_air_filter_searches_controls_table2_panelA_col2=%.4f\n", sf["b"]))
cat("DEVIATION: matched sample built from the package's shifted station coordinates (nearest Wave-2 deadline station by great-circle distance, pairs stacked); obs differ from the paper's 186,499\n")
