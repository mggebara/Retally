suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D,f,".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
sd2 <- function(x) as.Date(x - 3653, origin="1970-01-01")
st <- rd("station_list"); st[, auto := sd2(auto_date)]
print(unique(st[auto %in% as.Date(c("2013-01-01","2014-01-01")), .(code_city, phase, auto)])[, .N, by=.(phase, auto)])
we <- rd("weather_1116")
po <- merge(rd("pollution_1116"), we, by=c("station_n","date"))
po[, d := sd2(date)]
po <- merge(po, st[, .(station_n=pm10_n, auto, phase)], by="station_n")
po <- po[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
po[, rv := as.integer(d - auto)]; po[, mon := month(d)]
po[, res := resid(feols(pm10 ~ temp + rh + rain + wind_speed | station_n + mon, po))]
po[, dl_date := auto %in% as.Date(c("2013-01-01","2014-01-01"))]
po[, dl_phase := (phase==1 & auto==as.Date("2013-01-01")) | (phase==2 & auto==as.Date("2014-01-01"))]
for (s in c("w1","w2","dl_date","dl_phase")) {
  x <- switch(s, w1=po[phase==1], w2=po[phase==2], dl_date=po[dl_date==TRUE], dl_phase=po[dl_phase==TRUE])
  r <- rdrobust(x$res, x$rv, kernel="triangular", cluster=x$code_city, vce="hc1", masspoints="off")
  cat(s, "cities", uniqueN(x$code_city), " bw", round(r$bws[1,1],1), " Nh", sum(r$N_h), "\n")
}
# matching variants
es <- po[dl_date==TRUE & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
hav <- function(la1, lo1, la2, lo2) { r <- pi/180; a <- sin((la2-la1)*r/2)^2 + cos(la1*r)*cos(la2*r)*sin((lo2-lo1)*r/2)^2; 2*6371*asin(sqrt(a)) }
stc <- st[auto==as.Date("2014-01-01")]; stt <- st[auto==as.Date("2013-01-01")]
cobs <- es[auto==as.Date("2014-01-01"), .N, by=station_n]; tobs <- nrow(es[auto==as.Date("2013-01-01")])
m <- sapply(seq_len(nrow(stt)), function(i) stc$pm10_n[which.min(hav(stt$station_lon[i], stt$station_lat[i], stc$station_lon, stc$station_lat))])
cat("swapped hav dup", tobs + sum(cobs[match(m, cobs$station_n)]$N), " uniq", tobs + sum(cobs[station_n %in% m]$N), "\n")
# reverse: each control matched to nearest treated
m2 <- sapply(seq_len(nrow(stc)), function(i) stt$pm10_n[which.min(hav(stc$station_lat[i], stc$station_lon[i], stt$station_lat, stt$station_lon))])
tob <- es[auto==as.Date("2013-01-01"), .N, by=station_n]
cat("reverse dup", nrow(es[auto==as.Date("2014-01-01")]) + sum(tob[match(m2, tob$station_n)]$N), " uniq", nrow(es[auto==as.Date("2014-01-01")]) + sum(tob[station_n %in% m2]$N), "\n")
m1 <- sapply(seq_len(nrow(stt)), function(i) stc$pm10_n[which.min(hav(stt$station_lat[i], stt$station_lon[i], stc$station_lat, stc$station_lon))])
cat("both-direction union uniq", nrow(es[station_n %in% c(m1, m2, stt$pm10_n[stt$pm10_n %in% m2])]), "\n")
# stations treated: 2013-01-01 only phase1? controls nearest from all 2014 stations; count pm10 obs incl. no-weather
es2 <- merge(rd("pollution_1116"), st[, .(station_n=pm10_n, auto)], by="station_n")[!is.na(pm10)]
es2[, d := sd2(date)]; es2 <- es2[auto %in% as.Date(c("2013-01-01","2014-01-01")) & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
cb <- es2[auto==as.Date("2014-01-01"), .N, by=station_n]
cat("no-weather-filter: all", nrow(es2), " dup", nrow(es2[auto==as.Date("2013-01-01")]) + sum(cb[match(m1, cb$station_n)]$N), "\n")
