suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sl <- as.data.table(read_dta(paste0(D,"station_list.dta")))
mult <- sl[, .(nd = uniqueN(auto_date)), by = code_city][nd > 1]
print(sl[code_city %in% mult$code_city, .N, by = .(code_city, phase, auto_date)])
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta")))
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta")))
p <- merge(p, w, by = c("station_n","date"))
p <- merge(p, sl[, .(station_n = pm10_n, auto_date, phase, lon = station_lon, lat = station_lat)], by = "station_n")
p[, wok := !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
es <- p[!is.na(pm10) & wok & auto_date %in% c(19359, 19724) & date >= 18993 & date <= 19723]
nobs <- es[, .N, by = station_n]
st <- unique(es[, .(station_n, code_city, auto_date, lon, lat)])
hav <- function(lo1, la1, lo2, la2) { r <- pi/180; dl <- (lo2-lo1)*r; dp <- (la2-la1)*r
  a <- sin(dp/2)^2 + cos(la1*r)*cos(la2*r)*sin(dl/2)^2; 2*6371*asin(sqrt(pmin(1,a))) }
t1 <- st[auto_date == 19359]; t2 <- st[auto_date == 19724]
o1 <- nrow(es[auto_date == 19359])
for (sw in c(FALSE, TRUE)) {
  if (sw) { x1 <- t1$lat; y1 <- t1$lon; x2 <- t2$lat; y2 <- t2$lon } else { x1 <- t1$lon; y1 <- t1$lat; x2 <- t2$lon; y2 <- t2$lat }
  m <- sapply(seq_along(x1), function(i) t2$station_n[which.min(hav(x1[i], y1[i], x2, y2))])
  cat("swap", sw, "uniqueW2", uniqueN(m), " uniq obs", o1 + sum(nobs[match(unique(m), station_n), N]), " pairs obs", o1 + sum(nobs[match(m, station_n), N]), "\n")
}
# W2 -> nearest W1 (stack pairs both ways)
m2 <- sapply(seq_len(nrow(t2)), function(i) t1$station_n[which.min(hav(t2$lon[i], t2$lat[i], t1$lon, t1$lat))])
cat("W2 + matched W1 unique obs", nrow(es[auto_date == 19724]) + sum(nobs[match(unique(m2), station_n), N]), "\n")
# per-city matching: W1 station -> nearest W2 city (all its stations)
m <- sapply(seq_len(nrow(t1)), function(i) t2$station_n[which.min(hav(t1$lon[i], t1$lat[i], t2$lon, t2$lat))])
mc <- t2$code_city[match(m, t2$station_n)]
cat("matched W2 cities unique", uniqueN(mc), " obs W1 + all stations of matched cities", o1 + nrow(es[code_city %in% mc & auto_date == 19724]), "\n")
pc <- unique(data.table(c1 = t1$code_city, mc))
cat("W1 + (W1city, W2city) pairs, all stations", o1 + sum(sapply(pc$mc, function(cc) nrow(es[code_city == cc & auto_date == 19724]))), "\n")
cat("W1 + per W1 station copies of matched W2 city", o1 + sum(sapply(mc, function(cc) nrow(es[code_city == cc & auto_date == 19724]))), "\n")
