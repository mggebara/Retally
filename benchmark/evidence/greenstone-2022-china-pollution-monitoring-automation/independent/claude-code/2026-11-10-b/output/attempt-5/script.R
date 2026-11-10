## Exploratory: matched-sample size under alternative nearest-neighbour definitions
## (target from Table 1 notes: 186,499 obs). Prints sample sizes only.
suppressPackageStartupMessages({ library(haven); library(data.table) })
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(nm) as.data.table(zap_labels(zap_formats(read_dta(paste0(D, nm)))))
S <- function(x) as.Date(x, origin = "1960-01-01")
st <- rd("station_list.dta"); st[, auto := S(auto_date)]
po <- rd("pollution_1116.dta"); we <- rd("weather_1116.dta")
dd <- merge(po[, .(station_n, date, pm10)], we, by = c("station_n", "date")); rm(po, we)
dd[, d := S(date)]
es <- dd[!is.na(pm10) & complete.cases(dd[, .(temp, rh, rain, wind_speed)]) & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
nobs_st <- es[, .N, by = station_n]
n_of <- function(ids) sum(nobs_st$N[match(ids, nobs_st$station_n)], na.rm = TRUE)
hav <- function(lat1, lon1, lat2, lon2) { r <- pi / 180
  a <- sin((lat2 - lat1) * r / 2)^2 + cos(lat1 * r) * cos(lat2 * r) * sin((lon2 - lon1) * r / 2)^2
  2 * 6371 * asin(sqrt(a)) }
nn <- function(A, B, f) sapply(seq_len(nrow(A)), function(i) B$pm10_n[which.min(f(A[i], B))])
T1 <- st[auto == as.Date("2013-01-01")]; C1 <- st[auto == as.Date("2014-01-01")]
T1p <- T1[phase == 1]
dist <- list(
  hav = function(a, B) hav(a$station_lat, a$station_lon, B$station_lat, B$station_lon),
  euc = function(a, B) (a$station_lat - B$station_lat)^2 + (a$station_lon - B$station_lon)^2,
  swapped = function(a, B) hav(a$station_lon, a$station_lat, B$station_lon, B$station_lat))
for (dn in names(dist)) for (tn in c("all242", "phase1_218")) {
  TT <- if (tn == "all242") T1 else T1p
  m <- nn(TT, C1, dist[[dn]])
  cat(sprintf("%-8s %-10s treated=%d  dup-controls=%d  unique-controls(%d)=%d  both-directions-unique=%d\n",
    dn, tn, n_of(TT$pm10_n), n_of(TT$pm10_n) + n_of(m), uniqueN(m), n_of(TT$pm10_n) + n_of(unique(m)),
    { m2 <- nn(C1, TT, dist[[dn]]); n_of(unique(c(TT$pm10_n, m, C1$pm10_n[C1$pm10_n %in% m], m2))) + 0 }))
}
cat("all deadline:", n_of(c(T1$pm10_n, C1$pm10_n)), " controls total:", n_of(C1$pm10_n), "\n")
# city-level nearest: each treated station matched to nearest control city's stations
