suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-d/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
for (f in c("station_list","city_info","search_sale","aod_month","mask_filter_search","pm10_corrected_reference","pollution_1116","weather_1116")) {
  x <- as.data.table(read_dta(paste0(D,f,".dta")))
  cat("=====", f, nrow(x), "\n"); str(x); print(summary(x)); print(head(x, 4))
  if (f=="station_list") { st <- x; print(table(x$phase)); print(length(unique(x$code_city))); print(length(unique(x$pm10_n)))}
  if (f=="city_info") print(table(x$phase))
  if (f=="pollution_1116") { po <- x; print(range(x$date)); print(length(unique(x$station_n))); print(sum(!is.na(x$pm10))) }
  if (f=="weather_1116") { print(length(unique(x$station_n))); print(colSums(is.na(x))) }
  if (f=="mask_filter_search") { print(range(x$date)); print(length(unique(x$code_city))); print(colSums(is.na(x))) }
  if (f=="search_sale") { print(table(x$year, x$month)); print(length(unique(x$code_city))); print(colSums(is.na(x))) }
  if (f=="aod_month") { print(table(x$year)); print(length(unique(x$pm10_n))); print(colSums(is.na(x))) }
}
print(head(sort(unique(po$station_n)))); print(head(sort(unique(st$pm10_n))))
print(sum(unique(po$station_n) %in% st$pm10_n))
print(table(as.character(st$auto_date), st$phase))
cat("done\n")
