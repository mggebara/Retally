suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
for (f in c("station_list","city_info","search_sale","aod_month")) {
  x <- as.data.table(read_dta(paste0(D,f,".dta"))); cat("====",f,"\n"); str(x); print(head(x,4)); print(summary(x))
}
st <- as.data.table(read_dta(paste0(D,"station_list.dta")))
print(table(st$phase)); print(table(format(as.Date(st$auto_date),"%Y-%m"), st$phase))
print(st[, .(n=.N, ncity=uniqueN(code_city)), by=.(phase, dl = as.Date(auto_date) %in% as.Date(c("2013-01-01","2014-01-01")))])
ci <- as.data.table(read_dta(paste0(D,"city_info.dta"))); print(table(ci$phase))
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta"))); cat("==== pollution\n"); str(p); print(summary(p))
cat("nonmissing pm10", sum(!is.na(p$pm10)), "\n")
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta"))); cat("==== weather\n"); str(w); print(summary(w))
m <- as.data.table(read_dta(paste0(D,"mask_filter_search.dta"))); cat("==== mfs\n"); str(m); print(summary(m))
print(uniqueN(p$station_n)); print(uniqueN(w$station_n)); print(head(unique(p$station_n)))
print(head(st$pm10_n))
print(all(p$station_n == w$station_n)); print(all(p$date == w$date))
# match station to list
print(length(intersect(unique(p$station_n), st$pm10_n)))
pp <- merge(p[!is.na(pm10)], st[, .(station_n=pm10_n, auto_date)], by="station_n")
pp[, r := as.numeric(as.Date(date) - as.Date(auto_date))]
print(summary(pp$r)); cat("n with pm10:", nrow(pp), "\n")
print(pp[, .(pre=sum(r<0), post=sum(r>=0)), by=.(yr=year(as.Date(date)))])
a <- as.data.table(read_dta(paste0(D,"aod_month.dta"))); print(length(intersect(unique(a$pm10_n), st$pm10_n)))
ss <- as.data.table(read_dta(paste0(D,"search_sale.dta"))); print(table(ss$year, is.na(ss$mask)))
print(uniqueN(m$code_city)); print(range(m$date)); print(head(m[!is.na(pmmask)]))
mm <- m[, .(mask=mean(pmmask,na.rm=TRUE), filt=mean(filter,na.rm=TRUE), n=.N, nm=sum(!is.na(pmmask)), nf=sum(!is.na(filter))), by=.(code_city, y=year(as.Date(date)), mo=month(as.Date(date)))]
cat("city-months", nrow(mm), sum(mm$nm>0), sum(mm$nf>0), "\n")
print(length(intersect(unique(m$code_city), ci$code_city)))
