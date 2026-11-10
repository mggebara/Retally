## Exploratory: matched-sample size under more nearest-neighbour definitions
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
dist <- list(
  hav = function(a, B) hav(a$station_lat, a$station_lon, B$station_lat, B$station_lon),
  euc = function(a, B) (a$station_lat - B$station_lat)^2 + (a$station_lon - B$station_lon)^2,
  swapped = function(a, B) hav(a$station_lon, a$station_lat, B$station_lon, B$station_lat))
target <- 186499
nT <- n_of(T1$pm10_n)
for (dn in names(dist)) {
  m <- nn(T1, C1, dist[[dn]])
  pr <- data.table(tc = T1$code_city, cs = m, cc = C1$code_city[match(m, C1$pm10_n)])
  a <- nT + n_of(unique(pr[, .(tc, cs)])$cs)
  b <- nT + sum(sapply(unique(pr[, .(tc, cc)])$cc, function(k) n_of(C1[code_city == k]$pm10_n)))
  b2 <- nT + n_of(C1[code_city %in% unique(pr$cc)]$pm10_n)
  cen <- st[, .(station_lat = mean(station_lat), station_lon = mean(station_lon)), by = code_city]
  TC <- cen[code_city %in% T1$code_city]; CC <- cen[code_city %in% C1$code_city]; CC[, pm10_n := code_city]
  mc <- nn(TC, CC, dist[[dn]])
  c1 <- nT + sum(sapply(mc, function(k) n_of(C1[code_city == k]$pm10_n)))
  c2 <- nT + n_of(C1[code_city %in% unique(mc)]$pm10_n)
  # reverse: each control station -> nearest treated station; sample = controls + matched treated (dup)
  r1 <- nn(C1, T1, dist[[dn]])
  rv <- n_of(C1$pm10_n) + n_of(r1)
  cat(sprintf("%-8s uniq(tcity,cstat)=%d uniq(tcity,ccity)=%d uniqccity=%d citycen_dup=%d citycen_uniq=%d reverse_dup=%d (target %d)\n",
              dn, a, b, b2, c1, c2, rv, target))
}
