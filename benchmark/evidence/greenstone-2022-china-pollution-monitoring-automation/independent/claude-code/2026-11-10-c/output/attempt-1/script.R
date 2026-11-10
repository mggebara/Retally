suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
for (f in c("station_list","city_info","search_sale","pm10_corrected_reference","aod_month")) {
  x <- as.data.table(read_dta(paste0(D,f,".dta"))); cat("\n====",f,"\n"); str(x); print(head(x)); print(summary(x))
}
sl <- as.data.table(read_dta(paste0(D,"station_list.dta")))
print(table(sl$phase)); print(table(sl$auto_date, sl$phase))
ci <- as.data.table(read_dta(paste0(D,"city_info.dta"))); print(table(ci$phase))
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta"))); str(p); print(summary(p))
cat("nonmiss pm10", sum(!is.na(p$pm10)), "\n")
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta"))); str(w); print(summary(w))
m <- as.data.table(read_dta(paste0(D,"mask_filter_search.dta"))); str(m); print(summary(m))
print(length(unique(m$code_city)))
print(length(unique(p$station_n)))
print(class(p$date)); print(range(p$date))
pp <- merge(p, sl[, .(station_n = pm10_n, auto_date, phase)], by = "station_n")
pp[, rv := as.numeric(date - auto_date)]
cat("nonmiss pm10 merged", sum(!is.na(pp$pm10)), "\n")
print(pp[!is.na(pm10), .(n=.N, minrv=min(rv), maxrv=max(rv)), by=phase])
print(pp[!is.na(pm10), .N, by=.(pre = rv < 0)])
# deadline cities
dl <- unique(sl[, .(code_city, phase, auto_date)])
print(dl[, .N, by=.(phase, auto_date)][order(phase, auto_date)])
