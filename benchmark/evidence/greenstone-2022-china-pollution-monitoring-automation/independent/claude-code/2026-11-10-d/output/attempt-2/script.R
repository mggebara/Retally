suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
base <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(base, f)))))
st <- rd("station_list.dta"); ci <- rd("city_info.dta")
p <- rd("pollution_1116.dta"); w <- rd("weather_1116.dta")
p[, c("wind_speed","rain","temp","rh") := w[, .(wind_speed, rain, temp, rh)]]
rm(w); gc()
p <- merge(p, st[, .(station_n = pm10_n, phase, auto_date, lon = station_lon, lat = station_lat)], by = "station_n")
p[, dd := as.IDate(date, origin = "1960-01-01")]
cat("date range", format(range(p$dd)), "\n")
p[, wok := !is.na(wind_speed) & !is.na(rain) & !is.na(temp) & !is.na(rh)]
cat("pm10 nonmiss:", p[!is.na(pm10), .N], " +weather:", p[!is.na(pm10) & wok, .N], " pm10>0:", p[!is.na(pm10) & pm10 > 0, .N], "\n")
p[, x := date - auto_date]
cat("x range", range(p$x), "\n")
print(p[!is.na(pm10), .(N = .N, nst = uniqueN(station_n)), by = year(dd)])
# cities on deadline
cty <- unique(st[, .(code_city, phase, auto_date)])
cat("city rows", nrow(cty), "unique cities", uniqueN(cty$code_city), "\n")
cat("deadline own phase:", cty[(phase == 1 & auto_date == 19359) | (phase == 2 & auto_date == 19724), uniqueN(code_city)], "\n")
cat("deadline any:", cty[auto_date %in% c(19359, 19724), uniqueN(code_city)], "\n")
cat("phase2 on 19359 cities:", cty[phase == 2 & auto_date == 19359, uniqueN(code_city)], "\n")
# event study sample
es <- p[dd >= as.IDate("2012-01-01") & dd <= as.IDate("2013-12-31") & auto_date %in% c(19359, 19724)]
cat("ES nonmiss pm10:", es[!is.na(pm10), .N], " +weather:", es[!is.na(pm10) & wok, .N], "\n")
cat("ES stations T/C:", es[auto_date == 19359, uniqueN(station_n)], es[auto_date == 19724, uniqueN(station_n)], "\n")
cat("ES cities T/C:", es[auto_date == 19359, uniqueN(code_city)], es[auto_date == 19724, uniqueN(code_city)], "\n")
# matching
s1 <- st[auto_date == 19359]; s2 <- st[auto_date == 19724]
hav <- function(lon1, lat1, lon2, lat2) { r <- pi/180; a <- sin((lat2-lat1)*r/2)^2 + cos(lat1*r)*cos(lat2*r)*sin((lon2-lon1)*r/2)^2; 2*6371*asin(sqrt(a)) }
s1[, match := sapply(seq_len(.N), function(i) s2$pm10_n[which.min(hav(station_lon[i], station_lat[i], s2$station_lon, s2$station_lat))])]
cat("unique matched W2:", uniqueN(s1$match), "\n")
esok <- es[!is.na(pm10) & wok]
nobs <- esok[, .N, by = station_n]
nA <- sum(nobs[station_n %in% c(s1$pm10_n, unique(s1$match)), N])
nB <- sum(nobs[station_n %in% s1$pm10_n, N]) + sum(nobs[match(s1$match, station_n), N], na.rm = TRUE)
cat("matched obs (unique):", nA, " (stacked pairs):", nB, "\n")
esok2 <- es[!is.na(pm10)]; nobs2 <- esok2[, .N, by = station_n]
cat("no-weather versions:", sum(nobs2[station_n %in% c(s1$pm10_n, unique(s1$match)), N]), "\n")
cat("log obs (unique, pm10>0):", esok[station_n %in% c(s1$pm10_n, unique(s1$match)) & pm10 > 0, .N], "\n")
# AOD
aod <- rd("aod_month.dta")
cat("AOD nonmiss", aod[!is.na(aod), .N], "\n")
# search
m <- rd("mask_filter_search.dta")
m <- m[code_city %in% ci$code_city]
m[, dd := as.IDate(date, origin = "1960-01-01")]
cat("search range", format(range(m$dd)), "\n")
mm <- m[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE), nm = sum(!is.na(pmmask)), nf = sum(!is.na(filter))), by = .(code_city, y = year(dd), mo = month(dd))]
cat("monthly rows", nrow(mm), " mask nonNaN", mm[!is.nan(mask), .N], " filter nonNaN", mm[!is.nan(filter), .N], "\n")
print(mm[, .(mask = mean(mask, na.rm=TRUE), filter = mean(filter, na.rm=TRUE), zero_mask = mean(mask == 0, na.rm=TRUE)), by = y])
# timing test of rdrobust on full daily sample
d <- p[!is.na(pm10)]
t0 <- Sys.time()
r <- rdrobust(d$pm10, d$x, c = 0, kernel = "triangular", bwselect = "mserd", cluster = d$code_city, vce = "hc1")
cat("rdrobust time", format(Sys.time() - t0), "\n")
cat("h", r$bws[1,1], "N_h", sum(r$N_h), "\n")
