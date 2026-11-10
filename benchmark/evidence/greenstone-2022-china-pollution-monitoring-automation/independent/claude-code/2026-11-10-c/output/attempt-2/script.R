suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sl <- as.data.table(read_dta(paste0(D,"station_list.dta")))
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta")))
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta")))
p <- merge(p, w, by = c("station_n","date"))
p <- merge(p, sl[, .(station_n = pm10_n, auto_date, phase)], by = "station_n")
p[, rv := date - auto_date]
cat("pm10 nonmiss", p[!is.na(pm10), .N], "\n")
cat("pm10>0", p[!is.na(pm10) & pm10 > 0, .N], "\n")
cat("pm10 & all weather", p[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed), .N], "\n")
cat("pm10 <1000", p[!is.na(pm10) & pm10 < 1000, .N], "\n")
cat("pm10 2011-2015", p[!is.na(pm10) & date < 20454, .N], "\n")
cat("pm10 |rv|<=730", p[!is.na(pm10) & abs(rv) <= 730, .N], "\n")
cat("pm10 rv<=1095 ", p[!is.na(pm10) & abs(rv) <= 1095, .N], "\n")
print(p[!is.na(pm10), .N, by = year(as.Date(date, origin = "1960-01-01"))])
# event study sample counts
es <- p[!is.na(pm10) & auto_date %in% c(19359, 19724) & date >= 18993 & date <= 19722]
cat("ES all", nrow(es), " stations", uniqueN(es$station_n), "\n")
print(es[, .(N = .N, st = uniqueN(station_n), city = uniqueN(code_city)), by = auto_date])
cat("ES w/ weather", es[!is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed), .N], "\n")
cat("pm10 0 count", p[pm10 == 0, .N], "\n")
# search
ci <- as.data.table(read_dta(paste0(D,"city_info.dta")))
m <- as.data.table(read_dta(paste0(D,"mask_filter_search.dta")))
cat("cities in search matched", length(intersect(ci$code_city, m$code_city)), "\n")
m <- m[code_city %in% ci$code_city]
m[, d := as.Date(date, origin = "1960-01-01")]
print(range(m$d))
mm <- m[, .(mask = mean(pmmask), filter = mean(filter), nmask = sum(!is.na(pmmask)), nf = sum(!is.na(filter))), by = .(code_city, y = year(d), mo = month(d))]
cat("city-months", nrow(mm), " mask nonmiss", mm[!is.na(mask), .N], " filter nonmiss", mm[!is.na(filter), .N], "\n")
mm2 <- m[, .(mask = mean(pmmask, na.rm=TRUE), filter = mean(filter, na.rm=TRUE)), by = .(code_city, y = year(d), mo = month(d))]
cat("na.rm: mask nonmiss", mm2[is.finite(mask), .N], " filter", mm2[is.finite(filter), .N], "\n")
print(summary(mm2))
print(m[is.na(filter), .N, by = .(code_city)][order(-N)][1:10])
# AOD
a <- as.data.table(read_dta(paste0(D,"aod_month.dta")))
cat("aod nonmiss", a[!is.na(aod), .N], "\n")
# timing test of rdrobust with cluster on no2 subsample
set.seed(42)
sub <- p[!is.na(no2)][sample(.N, 300000)]
t0 <- Sys.time()
r <- rdrobust(sub$no2, sub$rv, c = 0, kernel = "triangular", p = 1, bwselect = "mserd", vce = "hc1", cluster = sub$code_city)
cat("time 300k cluster:", as.numeric(Sys.time() - t0, units = "secs"), " h=", r$bws[1,1], "\n")
t0 <- Sys.time()
r <- rdrobust(sub$no2, sub$rv, c = 0, kernel = "triangular", p = 1, bwselect = "mserd", vce = "hc1", cluster = sub$code_city, masspoints = "off")
cat("time 300k cluster nomass:", as.numeric(Sys.time() - t0, units = "secs"), " h=", r$bws[1,1], "\n")
