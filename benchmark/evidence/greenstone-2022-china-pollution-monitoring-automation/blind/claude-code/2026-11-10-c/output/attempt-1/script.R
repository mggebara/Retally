suppressPackageStartupMessages({library(haven); library(data.table)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-c/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
for (f in c("station_list","city_info","search_sale","aod_month","pm10_corrected_reference","mask_filter_search","pollution_1116","weather_1116")) {
  x <- as.data.table(read_dta(file.path(D, paste0(f, ".dta"))))
  cat("=====", f, nrow(x), "\n"); str(x); print(summary(x)); print(head(x, 4))
  if (f=="station_list") { print(table(x$phase)); print(table(format(as.Date(x$auto_date), "%Y-%m-%d"), x$phase)); print(length(unique(x$code_city))); sl <- x }
  if (f=="city_info") print(table(x$phase))
  if (f=="search_sale") { print(table(x$year, x$month)); print(length(unique(x$code_city))) }
  if (f=="mask_filter_search") { print(range(x$date)); print(length(unique(x$code_city))); print(table(year(x$date))) }
  if (f=="pollution_1116") { print(range(x$date)); print(length(unique(x$station_n))); print(sum(!is.na(x$pm10))); print(table(year(x$date), !is.na(x$pm10))); print(setdiff(unique(x$station_n), sl$pm10_n)[1:5]) }
  if (f=="weather_1116") { print(range(x$date)); print(colSums(is.na(x))) }
  if (f=="aod_month") { print(table(x$year)); print(sum(!is.na(x$aod))) }
  rm(x); gc()
}
cat("rdrobust version:", as.character(packageVersion("rdrobust")), "\n")
