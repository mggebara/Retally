suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/seeded/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
t0 <- Sys.time()
for (f in c("pollution_1116","weather_1116","station_list","mask_filter_search","aod_month","city_info")) {
  x <- read_dta(file.path(D, paste0(f, ".dta")))
  cat(f, nrow(x), ":", paste(names(x), collapse=" "), "\n"); print(head(as.data.frame(x),3))
  assign(f, as.data.table(x))
}
cat("read time", format(Sys.time()-t0), "\n")
cat("rdrobust version", as.character(packageVersion("rdrobust")), "\n")
src <- deparse(rdrobust::rdrobust)
i <- grep("vce_type|cluster", src); cat(src[i][1:min(60,length(i))], sep="\n")
w <- merge(pollution_1116, weather_1116, by=c("station_n","date"))
w <- merge(w, station_list, by.x="station_n", by.y="pm10_n")
v <- w[, .(sdt=sd(temp,na.rm=TRUE), sdr=sd(rain,na.rm=TRUE)), by=.(code_city.x, date)]
print(summary(v))
print(summary(w))
print(table(station_list$phase, station_list$auto_date %in% as.Date(c("2013-01-01","2014-01-01"))))
print(class(station_list$auto_date)); print(range(mask_filter_search$date))
w[, T := as.numeric(date - auto_date)]
w[, month := month(date)]
t1 <- Sys.time()
m <- feols(pm10 ~ wind_speed + rain + temp + rh | station_n + month, data=w)
cat("feols time", format(Sys.time()-t1), nobs(m), "\n")
w[, res := NA_real_]; w[obs(m), res := resid(m)]
t1 <- Sys.time()
r <- rdrobust(w$res, w$T, c=0, p=1, q=2, kernel="triangular", vce="hc1", cluster=w$code_city.x, masspoints="off")
cat("rd time", format(Sys.time()-t1), "\n"); cat(r$coef[1], r$bws[1,1], r$N_h, "\n")
