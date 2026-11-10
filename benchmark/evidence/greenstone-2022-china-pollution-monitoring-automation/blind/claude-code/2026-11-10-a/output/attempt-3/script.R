suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D,f,".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
sd2 <- function(x) as.Date(x - 3653, origin="1970-01-01")
st <- rd("station_list"); ci <- rd("city_info")
st[, auto := sd2(auto_date)]
cat("cities by auto date class:\n"); print(unique(st[, .(code_city, phase, auto)])[, .N, by=.(phase, dl=auto %in% as.Date(c("2013-01-01","2014-01-01")))])
po <- merge(rd("pollution_1116"), rd("weather_1116"), by=c("station_n","date"))
po[, d := sd2(date)]
po <- merge(po, st[, .(station_n=pm10_n, auto, phase, lat=station_lat, lon=station_lon)], by="station_n")
po <- po[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed)]
po[, rv := as.integer(d - auto)]; po[, mon := month(d)]
cat("N", nrow(po), "\n")
po[, res := resid(feols(pm10 ~ temp + rh + rain + wind_speed | station_n + mon, po))]
bwtry <- function(y, x, cl, lab) {
  for (mp in c("adjust","off")) for (useclu in c(TRUE,FALSE)) {
    r <- if (useclu) rdrobust(y, x, kernel="triangular", cluster=cl, vce="hc1", masspoints=mp) else rdrobust(y, x, kernel="triangular", masspoints=mp)
    cat(lab, "mp=", mp, "clu=", useclu, " bw=", round(r$bws[1,1],1), " Nh=", sum(r$N_h), "\n")
  }
}
bwtry(po$pm10, po$rv, po$code_city, "col1")
bwtry(po$res, po$rv, po$code_city, "col2")
# event study sample + matching N
es <- po[auto %in% as.Date(c("2013-01-01","2014-01-01")) & d >= as.Date("2012-01-01") & d <= as.Date("2013-12-31")]
es[, treat := auto == as.Date("2013-01-01")]
cat("ES N", nrow(es), " treated st", uniqueN(es[treat==TRUE]$station_n), " ctrl st", uniqueN(es[treat==FALSE]$station_n), "\n")
stt <- st[auto==as.Date("2013-01-01")]; stc <- st[auto==as.Date("2014-01-01")]
hav <- function(la1, lo1, la2, lo2) { r <- pi/180; a <- sin((la2-la1)*r/2)^2 + cos(la1*r)*cos(la2*r)*sin((lo2-lo1)*r/2)^2; 2*6371*asin(sqrt(a)) }
mh <- sapply(seq_len(nrow(stt)), function(i) stc$pm10_n[which.min(hav(stt$station_lat[i], stt$station_lon[i], stc$station_lat, stc$station_lon))])
me <- sapply(seq_len(nrow(stt)), function(i) stc$pm10_n[which.min((stt$station_lat[i]-stc$station_lat)^2 + (stt$station_lon[i]-stc$station_lon)^2)])
cat("match differ hav vs eucl:", sum(mh != me), " unique ctrl:", length(unique(mh)), "\n")
tobs <- nrow(es[treat==TRUE]); cobs <- es[treat==FALSE, .N, by=station_n]
cat("treated obs", tobs, " dup ctrl obs", sum(cobs[match(mh, cobs$station_n)]$N, na.rm=TRUE), " uniq ctrl obs", sum(cobs[station_n %in% mh]$N), "\n")
# AOD
a <- rd("aod_month"); wm <- po[, .(temp=mean(temp), rh=mean(rh), rain=mean(rain), ws=mean(wind_speed)), by=.(pm10_n=station_n, year=year(d), month=month(d))]
we <- rd("weather_1116"); we[, d := sd2(date)]
wm2 <- we[, .(temp=mean(temp,na.rm=T), rh=mean(rh,na.rm=T), rain=mean(rain,na.rm=T), ws=mean(wind_speed,na.rm=T)), by=.(pm10_n=station_n, year=year(d), month=month(d))]
a <- merge(a, wm2, by=c("pm10_n","year","month"), all.x=TRUE)
a <- merge(a, st[, .(pm10_n, auto, code_city)], by="pm10_n")
a <- a[!is.na(aod)]
cat("aod N", nrow(a), " w/ weather", nrow(a[!is.nan(temp)&!is.na(temp)]), "\n")
a[, rv := (year*12+month) - (year(auto)*12 + month(auto))]
r <- rdrobust(a$aod, a$rv, kernel="triangular", cluster=a$code_city, vce="hc1"); cat("aod raw bw", r$bws[1,1], sum(r$N_h), "\n")
r <- rdrobust(a$aod, a$rv, kernel="triangular"); cat("aod raw bw noclu", r$bws[1,1], sum(r$N_h), "\n")
# search
s <- rd("mask_filter_search"); s[, d := sd2(date)]; s <- s[code_city %in% ci$code_city]
sm <- s[, .(mask=mean(pmmask, na.rm=TRUE), filter=mean(filter, na.rm=TRUE), ndays=.N), by=.(code_city, year=year(d), month=month(d))]
cw <- merge(we, st[, .(station_n=pm10_n, code_city)], by="station_n")[, .(temp=mean(temp,na.rm=T), rh=mean(rh,na.rm=T), rain=mean(rain,na.rm=T), ws=mean(wind_speed,na.rm=T)), by=.(code_city, year=year(d), month=month(d))]
sm <- merge(sm, cw, by=c("code_city","year","month"), all.x=TRUE)
cat("search N", nrow(sm), " mask ok", sum(!is.nan(sm$mask)), " filter ok", sum(!is.nan(sm$filter)), " wx ok", sum(!is.nan(sm$temp)), "\n")
print(sm[ndays < 28, .N, by=.(year, month)])
print(sm[is.nan(filter), .N, by=.(code_city)])
