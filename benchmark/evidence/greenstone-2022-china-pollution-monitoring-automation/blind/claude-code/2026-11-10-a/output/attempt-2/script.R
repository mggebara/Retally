suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(f) { x <- as.data.table(read_dta(paste0(D,f,".dta"))); for (v in names(x)) attributes(x[[v]]) <- NULL; x }
st <- rd("station_list"); ci <- rd("city_info")
st[, auto := as.Date(auto_date - 3653, origin="1970-01-01")]
print(table(st$auto, st$phase))
st[, deadline := (phase==1 & auto==as.Date("2013-01-01")) | (phase==2 & auto==as.Date("2014-01-01"))]
print(st[, .(cities=uniqueN(code_city), stations=.N), by=.(phase,deadline)])
po <- rd("pollution_1116"); we <- rd("weather_1116")
setnames(we, "station_n", "station_n")
po <- merge(po, we, by=c("station_n","date"), all.x=TRUE)
po[, d := as.Date(date - 3653, origin="1970-01-01")]
print(range(po$d))
po <- merge(po, st[, .(station_n=pm10_n, auto, phase, deadline, city2=code_city)], by="station_n")
cat("city mismatch:", sum(po$code_city != po$city2), "\n")
po[, rv := as.integer(d - auto)]
p <- po[!is.na(pm10)]
cat("pm10 nonmiss", nrow(p), "\n")
cat("pm10>0", nrow(p[pm10>0]), "\n")
cat("year<2017", nrow(p[year(d)<2017]), "\n")
cat("weather complete", nrow(p[!is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed)]), "\n")
cat("weather complete, <2017", nrow(p[year(d)<2017 & !is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed)]), "\n")
print(table(year(p$d)))
print(quantile(p$pm10, c(0,.001,.01,.5,.99,.999,1)))
cat("pm10==0:", sum(p$pm10==0), " pm10>=1000:", sum(p$pm10>=1000), "\n")
# daily obs for event-study sample
es <- p[deadline==TRUE & d>=as.Date("2012-01-01") & d<=as.Date("2013-12-31")]
cat("ES obs all:", nrow(es), " w/ weather:", nrow(es[!is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed)]), "\n")
print(es[, .(stations=uniqueN(station_n), cities=uniqueN(code_city), n=.N), by=phase])
# search
s <- rd("mask_filter_search"); s[, d := as.Date(date-3653, origin="1970-01-01")]
print(range(s$d)); cat("search cities:", uniqueN(s$code_city), " in sample:", length(intersect(unique(s$code_city), ci$code_city)), "\n")
s <- s[code_city %in% ci$code_city]
sm <- s[, .(mask=mean(pmmask, na.rm=TRUE), filter=mean(filter, na.rm=TRUE), nm=sum(!is.na(pmmask)), nf=sum(!is.na(filter))), by=.(code_city, y=year(d), m=month(d))]
cat("city-months:", nrow(sm), " mask nonmiss:", sum(!is.nan(sm$mask)), " filter nonmiss:", sum(!is.nan(sm$filter)), "\n")
print(sm[, .(mask=mean(mask,na.rm=T), filter=mean(filter,na.rm=T), zeromask=mean(mask==0,na.rm=T), zerof=mean(filter==0, na.rm=T)), by=y])
print(table(sm$nf));
# aod
a <- rd("aod_month"); cat("aod nonmiss:", sum(!is.na(a$aod)), "\n")
# timing of rdrobust on full sample
t0 <- Sys.time()
p[, cityf := code_city]
r <- rdrobust(p$pm10, p$rv, c=0, kernel="triangular", bwselect="mserd", cluster=p$code_city, vce="hc1")
cat("bw:", r$bws[1,], " N:", r$N_h, " time:", format(Sys.time()-t0), "\n")
