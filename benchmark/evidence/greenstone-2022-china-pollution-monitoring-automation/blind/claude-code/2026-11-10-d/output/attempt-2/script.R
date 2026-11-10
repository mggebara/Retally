suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
st <- as.data.table(read_dta(paste0(D,"station_list.dta")))
ci <- as.data.table(read_dta(paste0(D,"city_info.dta")))
po <- as.data.table(read_dta(paste0(D,"pollution_1116.dta")))
we <- as.data.table(read_dta(paste0(D,"weather_1116.dta")))
po <- merge(po, we, by=c("station_n","date"))
po <- merge(po, st[,.(station_n=pm10_n, auto_date, phase, cc2=code_city)], by="station_n")
cat("city code mismatch:", sum(po$code_city!=po$cc2), "\n")
po[, x := date - auto_date]
cat("pm10 nonmiss:", sum(!is.na(po$pm10)), " pm10+weather:", po[!is.na(pm10) & !is.na(temp) & !is.na(rh) & !is.na(rain) & !is.na(wind_speed), .N], "\n")
cat("pm10 nonmiss, |x|<=730:", po[!is.na(pm10) & abs(x)<=730,.N], "\n")
# pm10 rows with pm10==0
cat("pm10==0:", po[pm10==0,.N], "\n")
# deadline cities
st[, deadline := auto_date %in% c(19359, 19724)]
cat("deadline stations:", sum(st$deadline), " cities:", uniqueN(st[deadline==TRUE]$code_city), "\n")
cat("cities on 19359 by phase:\n"); print(st[auto_date==19359, uniqueN(code_city), by=phase])
cat("cities on 19724:", uniqueN(st[auto_date==19724]$code_city), "\n")
cat("auto_date uniform within city:", all(st[, uniqueN(auto_date), by=code_city]$V1==1), "\n")
# event-study sample count
es <- po[auto_date %in% c(19359,19724) & date>=18993 & date<=19722]
cat("ES rows:", nrow(es), " pm10 nonmiss:", es[!is.na(pm10),.N], " with weather:", es[!is.na(pm10)&!is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed),.N], "\n")
cat("date check 18993=", as.character(as.Date(18993-3653)), " 19722=", as.character(as.Date(19722-3653)), "\n")
# search
ms <- as.data.table(read_dta(paste0(D,"mask_filter_search.dta")))
cat("sample cities in search:", sum(ci$code_city %in% ms$code_city), "\n")
print(ci[!code_city %in% ms$code_city])
ms <- ms[code_city %in% ci$code_city]
ms[, d := as.Date(date-3653)]; ms[, ym := year(d)*12+month(d)-1]
mm <- ms[, .(mask=mean(pmmask, na.rm=TRUE), filt=mean(filter, na.rm=TRUE), nm=sum(!is.na(pmmask)), nf=sum(!is.na(filter))), by=.(code_city, ym)]
cat("city-months:", nrow(mm), " mask nonmiss:", mm[nm>0,.N], " filt nonmiss:", mm[nf>0,.N], "\n")
print(summary(mm$mask)); print(summary(mm$filt))
print(table(ms[is.na(filter), year(d)]))
# AOD
ao <- as.data.table(read_dta(paste0(D,"aod_month.dta")))
cat("aod nonmiss:", ao[!is.na(aod),.N], "\n")
# timing test with rdrobust on raw NO2 (not a listed quantity)
t0 <- Sys.time()
z <- po[!is.na(no2)]
r <- rdrobust(z$no2, z$x, c=0, kernel="triangular", bwselect="mserd", cluster=z$code_city, vce="hc1")
cat("NO2 rd timing (s):", as.numeric(difftime(Sys.time(), t0, units="secs")), " h=", r$bws[1,1], " N=", sum(r$N_h), "\n")
cat("done\n")
