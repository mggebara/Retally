suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
for (f in c("station_list","city_info","aod_month","search_sale","mask_filter_search","weather_1116","pollution_1116","pm10_corrected_reference")) {
  x <- as.data.table(read_dta(paste0(D, f, ".dta")))
  cat("=====", f, nrow(x), "\n"); str(x); print(summary(x)); print(head(x, 5))
  assign(f, x)
}
cat("phase table\n"); print(table(station_list$phase)); print(table(city_info$phase))
print(table(station_list$auto_date, station_list$phase))
print(station_list[, .(n=.N, nd=uniqueN(auto_date)), by=code_city][nd>1])
cat("cities in search:", uniqueN(mask_filter_search$code_city), "date range", format(range(mask_filter_search$date)), "\n")
print(pollution_1116[, .(nonmiss=sum(!is.na(pm10))), by=year(date)])
cat("pm10 nonmiss total", sum(!is.na(pollution_1116$pm10)), "\n")
print(aod_month[, .(n=.N, nonmiss=sum(!is.na(aod))), by=year])
print(head(search_sale, 20))
print(mask_filter_search[, .(n=.N, nm=sum(!is.na(pmmask)), nf=sum(!is.na(filter))), by=year(date)])
