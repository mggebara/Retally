suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sl <- as.data.table(read_dta(paste0(D,"station_list.dta")))
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
# also with stations from full station list (incl those w/o data in window)
stall <- sl[auto_date %in% c(19359, 19724), .(station_n = pm10_n, code_city, auto_date, lon = station_lon, lat = station_lat)]
cat("stations in list: ", stall[, .N, by = auto_date][, paste(auto_date, N)], "\n")
for (src in c("es", "all")) {
  S <- if (src == "es") st else stall
  for (metric in c("hav", "euc")) {
    t1 <- S[auto_date == 19359]; t2 <- S[auto_date == 19724]
    dfun <- if (metric == "hav") function(i) hav(t1$lon[i], t1$lat[i], t2$lon, t2$lat) else function(i) (t1$lon[i]-t2$lon)^2 + (t1$lat[i]-t2$lat)^2
    t1[, m := sapply(seq_len(.N), function(i) t2$station_n[which.min(dfun(i))])]
    o1 <- es[station_n %in% t1$station_n, .N]
    A <- unique(t1[, .(code_city, m)]); oA <- sum(nobs[match(A$m, station_n), N], na.rm = TRUE)
    # B: control copies restricted to dates W1 station has data
    pr <- t1[, .(s1 = station_n, m)]
    d1 <- es[, .(station_n, date)]
    B <- merge(merge(pr, d1, by.x = "s1", by.y = "station_n", allow.cartesian = TRUE), d1, by.x = c("m","date"), by.y = c("station_n","date"))
    # dup without restriction
    oD <- sum(nobs[match(t1$m, station_n), N], na.rm = TRUE)
    oU <- sum(nobs[match(unique(t1$m), station_n), N], na.rm = TRUE)
    cat(src, metric, "W1", o1, "uniqueW2", uniqueN(t1$m), "| uniq", o1 + oU, "| cityPairs", nrow(A), o1 + oA, "| dup", o1 + oD, "| overlapCtrl", o1 + nrow(B), "| 2xoverlap", 2*nrow(B), "\n")
  }
}
