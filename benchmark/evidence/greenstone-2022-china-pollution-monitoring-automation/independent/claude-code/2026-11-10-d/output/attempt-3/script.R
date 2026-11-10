suppressPackageStartupMessages({library(haven); library(data.table)})
base <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
rd <- function(f) as.data.table(zap_labels(zap_formats(read_dta(file.path(base, f)))))
st <- rd("station_list.dta"); ci <- rd("city_info.dta")
p <- rd("pollution_1116.dta"); w <- rd("weather_1116.dta")
p[, c("wind_speed","rain","temp","rh") := w[, .(wind_speed, rain, temp, rh)]]
rm(w); invisible(gc())
p <- merge(p, st[, .(station_n = pm10_n, phase, auto_date)], by = "station_n")
p[, dd := as.IDate(date, origin = "1960-01-01")]
p[, wok := !is.na(wind_speed) & !is.na(rain) & !is.na(temp) & !is.na(rh)]
# mixed cities
mix <- st[, .(nd = uniqueN(auto_date), nph = uniqueN(phase)), by = code_city][nd > 1 | nph > 1]
print(merge(mix, st[, .N, by = .(code_city, phase, auto_date)], by = "code_city"))
cat("station-phase vs city-phase agree:", nrow(merge(st, ci[, .(code_city, cph = phase)])[phase != cph]), "disagreements\n")
es <- p[dd >= as.IDate("2012-01-01") & dd <= as.IDate("2013-12-31") & auto_date %in% c(19359, 19724) & !is.na(pm10) & wok]
nobs <- es[, .N, by = station_n]
s1 <- st[auto_date == 19359]; s2 <- st[auto_date == 19724]
cat("W1 obs:", sum(nobs[station_n %in% s1$pm10_n, N]), " W2 obs:", sum(nobs[station_n %in% s2$pm10_n, N]), "\n")
hav <- function(lon1, lat1, lon2, lat2) { r <- pi/180; a <- sin((lat2-lat1)*r/2)^2 + cos(lat1*r)*cos(lat2*r)*sin((lon2-lon1)*r/2)^2; 2*6371*asin(sqrt(a)) }
nn <- function(a, b, excl_city = FALSE) sapply(seq_len(nrow(a)), function(i) { d <- hav(a$station_lon[i], a$station_lat[i], b$station_lon, b$station_lat); if (excl_city) d[b$code_city == a$code_city[i]] <- Inf; b$pm10_n[which.min(d)] })
getN <- function(ids) sum(nobs[match(ids, station_n), N], na.rm = TRUE)
W1 <- getN(s1$pm10_n)
m1 <- nn(s1, s2); m2 <- nn(s1, s2, TRUE)
cat("same-city W2 exists for W1 stations:", sum(s1$code_city %in% s2$code_city), "\n")
cat("v1 unique", W1 + getN(unique(m1)), " stacked", W1 + getN(m1), "\n")
cat("v2 excl city unique", W1 + getN(unique(m2)), " stacked", W1 + getN(m2), " nuniq", uniqueN(m2), "\n")
# reverse match too
r1 <- nn(s2, s1)
cat("v3 union both directions unique:", getN(unique(c(s1$pm10_n[s1$pm10_n %in% r1], m1))), " W1 all + W2 all", W1 + getN(s2$pm10_n), "\n")
# city-level: centroid
cc <- st[auto_date %in% c(19359, 19724), .(station_lon = mean(station_lon), station_lat = mean(station_lat)), by = .(code_city, auto_date)]
c1 <- cc[auto_date == 19359]; c2 <- cc[auto_date == 19724]
c1[, pm10_n := code_city]; c2[, pm10_n := code_city]
mc <- nn(c1, c2)
w2c_ids <- function(cities) unlist(lapply(cities, function(cc_) s2[code_city == cc_, pm10_n]))
cat("v4 city match unique", W1 + getN(unique(w2c_ids(unique(mc)))), " stacked", W1 + getN(w2c_ids(mc)), "\n")
# station matched to nearest W2 city centroid -> all stations of that city
ms <- nn(s1, c2)
cat("v5 station->W2 city unique", W1 + getN(w2c_ids(unique(ms))), " stacked-by-city", W1 + getN(w2c_ids(ms)), "\n")
# W1 per city deduplicated: unique pairs (W1 city, W2 station)
pr <- unique(data.table(c = s1$code_city, m = m1))
cat("v6 unique (W1city,W2station) pairs", W1 + getN(pr$m), "\n")
# search & weather
m <- rd("mask_filter_search.dta")[code_city %in% ci$code_city]
m[, dd := as.IDate(date, origin = "1960-01-01")]
mm <- m[, .(mask = mean(pmmask, na.rm = TRUE), filter = mean(filter, na.rm = TRUE)), by = .(code_city, y = year(dd), mo = month(dd))]
wc <- p[, .(temp = mean(temp, na.rm = TRUE), rh = mean(rh, na.rm = TRUE), rain = mean(rain, na.rm = TRUE), ws = mean(wind_speed, na.rm = TRUE)), by = .(code_city, y = year(dd), mo = month(dd))]
mm <- merge(mm, wc, by = c("code_city", "y", "mo"), all.x = TRUE)
cat("search rows with all weather:", mm[!is.nan(temp) & !is.nan(rh) & !is.nan(rain) & !is.nan(ws) & !is.na(temp), .N], "\n")
cat("filter + weather:", mm[!is.nan(filter) & !is.na(temp) & !is.nan(temp) & !is.nan(rh) & !is.nan(rain) & !is.nan(ws), .N], "\n")
print(mm[is.na(temp) | is.nan(temp) | is.nan(rh) | is.nan(rain) | is.nan(ws), .N, by = code_city])
print(mm[, .N, by = code_city][N != 71])
# how many cities have multiple auto dates (for monthly running var)
cat("AOD station-months in sample:", nrow(rd("aod_month.dta")), "\n")
