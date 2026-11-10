suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/seeded/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
cat("rdrobust", as.character(packageVersion("rdrobust")), "fixest", as.character(packageVersion("fixest")), "\n")
for (f in c("pollution_1116","weather_1116","station_list","mask_filter_search","aod_month","city_info")) {
  x <- read_dta(file.path(D, paste0(f, ".dta")))
  cat("==", f, nrow(x), "\n"); print(names(x)); print(head(as.data.frame(x),3))
}
w <- as.data.table(read_dta(file.path(D,"weather_1116.dta")))
p <- as.data.table(read_dta(file.path(D,"pollution_1116.dta")))
s <- as.data.table(read_dta(file.path(D,"station_list.dta")))
cat("pollution stations", uniqueN(p$station_n), " dates range", format(range(p$date)), "\n")
m <- merge(p, w, by=c("station_n","date"))
v <- m[, .(sdt=sd(temp,na.rm=TRUE), sdr=sd(rain,na.rm=TRUE), sdw=sd(wind_speed,na.rm=TRUE)), by=.(code_city,date)]
print(summary(v))
print(table(s$auto_date %in% c(19359,19724), s$phase))
print(table(s$phase, useNA="a"))
print(summary(s))
print(rdrobust:::rdrobust_vce)
print(args(rdrobust::rdrobust))
