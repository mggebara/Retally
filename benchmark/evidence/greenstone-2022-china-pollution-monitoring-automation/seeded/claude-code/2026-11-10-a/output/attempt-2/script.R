suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/seeded/2026-11-10-a/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data"
src <- deparse(rdrobust::rdrobust)
idx <- grep("vce|crv|cluster", src)
cat(src[sort(unique(unlist(lapply(idx, function(i) i))))], sep="\n")
set.seed(42)
p <- as.data.table(read_dta(file.path(D,"pollution_1116.dta")))
s <- as.data.table(read_dta(file.path(D,"station_list.dta")))
p <- merge(p, s[, .(station_n=pm10_n, auto_date)], by="station_n")
p <- p[!is.na(pm10)]
p[, T := date - auto_date]
p[, ynoise := rnorm(.N)]
cat("N nonmissing pm10:", nrow(p), "\n")
t0 <- proc.time()
r <- rdrobust(p$ynoise, p$T, c=0, p=1, q=2, kernel="triangular", cluster=p$code_city, vce="hc1", masspoints="off")
print(proc.time()-t0)
cat("h", r$bws[1,], "N_h", r$N_h, "\n")
