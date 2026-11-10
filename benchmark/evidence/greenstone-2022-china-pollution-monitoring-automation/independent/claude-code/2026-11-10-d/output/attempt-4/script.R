suppressPackageStartupMessages({library(haven); library(data.table)})
base <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(base, f)))))
st <- rd("station_list.dta")
p <- rd("pollution_1116.dta"); w <- rd("weather_1116.dta")
p[, c("wind_speed","rain","temp","rh") := w[, .(wind_speed, rain, temp, rh)]]
rm(w); invisible(gc())
p <- p[date >= 18993 & date <= 19723]  # 2012-01-01 .. 2013-12-31
p <- merge(p, st[, .(station_n = pm10_n, phase, auto_date)], by = "station_n")
p[, ok := !is.na(pm10) & !is.na(wind_speed) & !is.na(rain) & !is.na(temp) & !is.na(rh)]
cat("check 2012-13 window ES obs:", p[auto_date %in% c(19359, 19724) & ok, .N], "\n")
okd <- p[ok == TRUE, .(station_n, date)]
nobs <- okd[, .N, by = station_n]
getN <- function(ids) sum(nobs[match(ids, station_n), N], na.rm = TRUE)
hav <- function(lon1, lat1, lon2, lat2) { r <- pi/180; a <- sin((lat2-lat1)*r/2)^2 + cos(lat1*r)*cos(lat2*r)*sin((lon2-lon1)*r/2)^2; 2*6371*asin(sqrt(a)) }
nn <- function(a, b, euc = FALSE) sapply(seq_len(nrow(a)), function(i) { d <- if (euc) (a$station_lon[i]-b$station_lon)^2 + (a$station_lat[i]-b$station_lat)^2 else hav(a$station_lon[i], a$station_lat[i], b$station_lon, b$station_lat); b$pm10_n[which.min(d)] })
report <- function(lab, s1, s2) {
  m <- nn(s1, s2); me <- nn(s1, s2, TRUE)
  W1 <- getN(s1$pm10_n)
  pairs <- data.table(t = s1$pm10_n, c = m)
  both <- 0; w1side <- 0
  for (k in seq_len(nrow(pairs))) {
    dt <- okd[station_n == pairs$t[k], date]; dc <- okd[station_n == pairs$c[k], date]
    both <- both + length(intersect(dt, dc)); w1side <- w1side + length(dt) + length(intersect(dt, dc))
  }
  cat(lab, ": nT", nrow(s1), "nC", nrow(s2), "W1obs", W1, "uniqC", uniqueN(m), "unique", W1 + getN(unique(m)), "stacked", W1 + getN(m),
      "euc-diff", sum(m != me), "2*both", 2 * both, "W1+matchedOnW1days", w1side, "\n")
}
sA1 <- st[auto_date == 19359]; sA2 <- st[auto_date == 19724]
report("all-deadline", sA1, sA2)
report("ownphase", st[auto_date == 19359 & phase == 1], st[auto_date == 19724 & phase == 2])
# match to any phase-2 station, then keep only deadline controls
report("W1 to all phase2", sA1, st[phase == 2 & auto_date != 19359])
# reverse: each W2 deadline station to nearest W1
r <- nn(sA2, sA1)
cat("reverse: W2obs + matched W1 stacked", getN(sA2$pm10_n) + getN(r), " unique", getN(sA2$pm10_n) + getN(unique(r)), "\n")
