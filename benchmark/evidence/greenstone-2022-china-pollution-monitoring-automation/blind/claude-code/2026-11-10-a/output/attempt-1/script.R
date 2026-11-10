suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
for (f in c("station_list","city_info","search_sale","aod_month","mask_filter_search","weather_1116","pollution_1116")) {
  x <- as.data.table(read_dta(paste0(D,f,".dta")))
  cat("=====", f, nrow(x), "\n"); str(x); print(summary(x)); print(head(x,3))
  if (f=="station_list") { print(table(x$phase)); print(table(x$auto_date)); print(uniqueN(x$code_city)); st <- x }
  if (f=="city_info") { print(table(x$phase)) }
  if (f=="pollution_1116") { print(range(x$date)); print(uniqueN(x$station_n)); print(sum(!is.na(x$pm10)))
     print(table(year(x$date), !is.na(x$pm10)))
     m <- merge(x[!is.na(pm10)], st[,.(station_n=pm10_n, auto_date, phase)], by="station_n")
     m[, rv := as.integer(date - auto_date)]
     print(summary(m$rv)); print(m[, .(n=.N, pre=sum(rv<0), post=sum(rv>=0)), by=phase])
     print(nrow(m[abs(rv)<=1500]))
  }
  if (f=="mask_filter_search") print(range(x$date))
  if (f=="search_sale") print(table(x$year))
}
