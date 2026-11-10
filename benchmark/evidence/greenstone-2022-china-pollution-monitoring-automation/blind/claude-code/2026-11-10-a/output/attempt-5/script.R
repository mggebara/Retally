suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D,f,".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
sd2 <- function(x) as.Date(x - 3653, origin="1970-01-01")
st <- rd("station_list"); ci <- rd("city_info")
st[, auto := sd2(auto_date)]
we <- rd("weather_1116"); we[, d := sd2(date)]
po <- merge(rd("pollution_1116"), we, by=c("station_n","date"))
po <- merge(po, st[, .(station_n=pm10_n, auto, phase)], by="station_n")
po <- po[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
# matching variants
es <- po[auto %in% as.Date(c("2013-01-01","2014-01-01")) & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
hav <- function(la1, lo1, la2, lo2) { r <- pi/180; a <- sin((la2-la1)*r/2)^2 + cos(la1*r)*cos(la2*r)*sin((lo2-lo1)*r/2)^2; 2*6371*asin(sqrt(a)) }
stc <- st[auto==as.Date("2014-01-01")]
cobs <- es[auto==as.Date("2014-01-01"), .N, by=station_n]
for (tset in c("242","218")) {
  stt <- if (tset=="242") st[auto==as.Date("2013-01-01")] else st[auto==as.Date("2013-01-01") & phase==1]
  tobs <- nrow(es[station_n %in% stt$pm10_n])
  for (met in c("hav","eucl")) {
    m <- sapply(seq_len(nrow(stt)), function(i) { dd <- if (met=="hav") hav(stt$station_lat[i], stt$station_lon[i], stc$station_lat, stc$station_lon) else (stt$station_lat[i]-stc$station_lat)^2 + (stt$station_lon[i]-stc$station_lon)^2; stc$pm10_n[which.min(dd)] })
    cat(tset, met, "treated obs", tobs, " dup", tobs + sum(cobs[match(m, cobs$station_n)]$N, na.rm=TRUE), " uniq", tobs + sum(cobs[station_n %in% m]$N), " nuniq", length(unique(m)), "\n")
  }
}
# also: within-city-pairs dates where both observed? skip
# AOD
a <- rd("aod_month")
wm2 <- we[, .(temp=mean(temp,na.rm=T), rh=mean(rh,na.rm=T), rain=mean(rain,na.rm=T), ws=mean(wind_speed,na.rm=T)), by=.(pm10_n=station_n, year=year(d), month=month(d))]
a <- merge(a, wm2, by=c("pm10_n","year","month"), all.x=TRUE)
a <- merge(a, st[, .(pm10_n, auto, code_city)], by="pm10_n")
a <- a[!is.na(aod)]
a[, ym := year*12+month]
a[, rv_a := ym - (year(auto)*12 + month(auto))]
a[, rv_b := rv_a - (mday(auto) > 15)]
a[, rv_c := floor(as.numeric(as.Date(sprintf("%d-%02d-01", year, month)) - auto)/30)]
a[, rv_d := ifelse(mday(auto)==1, rv_a, rv_a - 1)]
aw <- a[is.finite(temp) & is.finite(rh) & is.finite(rain) & is.finite(ws)]
aw[, res := resid(feols(aod ~ temp + rh + rain + ws | pm10_n + month, aw))]
for (v in c("rv_a","rv_b","rv_c","rv_d")) {
  for (clu in c(TRUE, FALSE)) {
    r1 <- if (clu) rdrobust(a$aod, a[[v]], kernel="triangular", cluster=a$code_city, vce="hc1", masspoints="off") else rdrobust(a$aod, a[[v]], kernel="triangular", masspoints="off")
    r2 <- if (clu) rdrobust(aw$res, aw[[v]], kernel="triangular", cluster=aw$code_city, vce="hc1", masspoints="off") else rdrobust(aw$res, aw[[v]], kernel="triangular", masspoints="off")
    r3 <- rdrobust(aw$aod, aw[[v]], kernel="triangular", cluster=aw$code_city, vce="hc1", masspoints="off")
    cat("AOD", v, "clu", clu, " raw bw", round(r1$bws[1,1],2), sum(r1$N_h), " res bw", round(r2$bws[1,1],2), sum(r2$N_h), " rawW bw", round(r3$bws[1,1],2), sum(r3$N_h), "\n")
  }
}
# search counts
s <- rd("mask_filter_search"); s[, d := sd2(date)]; s <- s[code_city %in% ci$code_city]
sm <- s[, .(mask=mean(pmmask, na.rm=TRUE), filter=mean(filter, na.rm=TRUE), nmask=sum(!is.na(pmmask)), nfil=sum(!is.na(filter))), by=.(code_city, year=year(d), month=month(d))]
cw <- merge(we, st[, .(station_n=pm10_n, code_city)], by="station_n")[, .(temp=mean(temp,na.rm=T), rh=mean(rh,na.rm=T), rain=mean(rain,na.rm=T), ws=mean(wind_speed,na.rm=T)), by=.(code_city, year=year(d), month=month(d))]
sm <- merge(sm, cw, by=c("code_city","year","month"), all.x=TRUE)
sm[, wx := is.finite(temp)&is.finite(rh)&is.finite(rain)&is.finite(ws)]
cat("mask&wx", sum(is.finite(sm$mask)&sm$wx), " filter&wx", sum(is.finite(sm$filter)&sm$wx), "\n")
cat("excl 2016-11: mask", sum(is.finite(sm$mask) & !(sm$year==2016&sm$month==11)), " filter", sum(is.finite(sm$filter) & !(sm$year==2016&sm$month==11)), "\n")
print(sm[!wx, .N, by=.(year,month)])
print(sm[!wx, .N, by=code_city])
