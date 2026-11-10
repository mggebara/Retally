suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sl <- as.data.table(read_dta(paste0(D,"station_list.dta")))
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta")))
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta")))
p <- merge(p, w, by = c("station_n","date"))
p <- merge(p, sl[, .(station_n = pm10_n, auto_date, phase, lon = station_lon, lat = station_lat)], by = "station_n")
p[, wok := !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
es <- p[!is.na(pm10) & wok & auto_date %in% c(19359, 19724) & date >= 18993 & date <= 19723]
cat("ES", nrow(es), "\n")
nobs <- es[, .N, by = station_n]
st <- unique(es[, .(station_n, code_city, auto_date, lon, lat)])
t1 <- st[auto_date == 19359]; t2 <- st[auto_date == 19724]
hav <- function(lo1, la1, lo2, la2) { r <- pi/180; dl <- (lo2-lo1)*r; dp <- (la2-la1)*r
  a <- sin(dp/2)^2 + cos(la1*r)*cos(la2*r)*sin(dl/2)^2; 2*6371*asin(sqrt(pmin(1,a))) }
t1[, match := sapply(seq_len(.N), function(i) t2$station_n[which.min(hav(lon[i], lat[i], t2$lon, t2$lat))])]
cat("W1 stations", nrow(t1), " unique matched W2", uniqueN(t1$match), "\n")
o1 <- sum(nobs[station_n %in% t1$station_n, N])
cat("W1 obs", o1, "\n")
cat("unique ctrl obs", sum(nobs[station_n %in% unique(t1$match), N]), " total", o1 + sum(nobs[station_n %in% unique(t1$match), N]), "\n")
dup <- sum(nobs[match(t1$match, station_n), N]); cat("dup ctrl obs", dup, " total", o1 + dup, "\n")
# reverse: each W2 to nearest W1
t2[, match := sapply(seq_len(.N), function(i) t1$station_n[which.min(hav(lon[i], lat[i], t1$lon, t1$lat))])]
cat("unique W1 matched by W2", uniqueN(t2$match), "\n")
# euclidean on degrees
t1[, me := sapply(seq_len(.N), function(i) t2$station_n[which.min((lon[i]-t2$lon)^2 + (lat[i]-t2$lat)^2)])]
cat("euclid differs", sum(t1$me != t1$match), "\n")
# pairs at city level?
print(table(table(t1$match)))
cat("log ok", es[pm10 > 0, .N], "\n")
# search weather
ci <- as.data.table(read_dta(paste0(D,"city_info.dta")))
p[, d := as.Date(date, origin = "1960-01-01")]
cw <- p[, .(temp = mean(temp, na.rm=TRUE), rh = mean(rh, na.rm=TRUE), rain = mean(rain, na.rm=TRUE), ws = mean(wind_speed, na.rm=TRUE)), by = .(code_city, y = year(d), mo = month(d))]
cat("city-month weather rows", nrow(cw), " complete", cw[is.finite(temp)&is.finite(rh)&is.finite(rain)&is.finite(ws), .N], "\n")
print(cw[!(is.finite(temp)&is.finite(rh)&is.finite(rain)&is.finite(ws)), .N, by = code_city])
# AOD months
a <- as.data.table(read_dta(paste0(D,"aod_month.dta")))
sw <- p[, .(temp = mean(temp, na.rm=TRUE), rh = mean(rh, na.rm=TRUE), rain = mean(rain, na.rm=TRUE), ws = mean(wind_speed, na.rm=TRUE)), by = .(station_n, y = year(d), mo = month(d))]
a <- merge(a, sw, by.x = c("pm10_n","year","month"), by.y = c("station_n","y","mo"), all.x = TRUE)
cat("aod nonmiss & weather", a[!is.na(aod) & is.finite(temp)&is.finite(rh)&is.finite(rain)&is.finite(ws), .N], "\n")
