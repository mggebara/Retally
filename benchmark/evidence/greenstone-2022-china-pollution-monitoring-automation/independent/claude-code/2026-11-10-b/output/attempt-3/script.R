## Exploratory: deadline definitions and rdrobust bandwidth variants (no estimates printed as results)
suppressPackageStartupMessages({ library(haven); library(data.table); library(fixest); library(rdrobust) })
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/independent/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
rd <- function(nm) as.data.table(zap_labels(zap_formats(read_dta(paste0(D, nm)))))
S <- function(x) as.Date(x, origin = "1960-01-01")
st <- rd("station_list.dta"); st[, auto := S(auto_date)]
print(st[, .N, by = .(phase, auto)][order(phase, auto)])
st[, dl := auto %in% as.Date(c("2013-01-01", "2014-01-01"))]
cat("deadline (any phase) cities:", uniqueN(st[dl == TRUE]$code_city), " stations:", sum(st$dl), "\n")
po <- rd("pollution_1116.dta"); we <- rd("weather_1116.dta")
dd <- merge(po[, .(station_n, date, pm10)], we, by = c("station_n", "date")); rm(po, we)
dd <- merge(dd, st[, .(station_n = pm10_n, code_city, phase, auto)], by = "station_n")
dd[, r := as.numeric(S(date) - auto)][, month := as.integer(format(S(date), "%m"))]
wx <- c("temp", "rh", "rain", "wind_speed")
daily <- dd[!is.na(pm10) & complete.cases(dd[, ..wx])]
m <- feols(pm10 ~ temp + rh + rain + wind_speed | station_n + month, data = daily)
daily[, res := NA_real_]; daily[obs(m), res := resid(m)]
bw <- function(y, x, cl, ...) { b <- rdbwselect(y, x, c = 0, kernel = "triangular", bwselect = "mserd", cluster = cl, ...); round(b$bws[1, 1], 1) }
for (mp in c("adjust", "off")) {
  cat("masspoints", mp, ": raw h=", bw(daily$pm10, daily$r, daily$code_city, masspoints = mp),
      " resid h=", bw(daily$res, daily$r, daily$code_city, masspoints = mp), "\n")
}
cat("no cluster (hc1), mp off: raw h=", round(rdbwselect(daily$pm10, daily$r, c = 0, kernel = "triangular", vce = "hc1", masspoints = "off")$bws[1, 1], 1),
    " resid h=", round(rdbwselect(daily$res, daily$r, c = 0, kernel = "triangular", vce = "hc1", masspoints = "off")$bws[1, 1], 1), "\n")
cat("nn default no cluster: raw h=", round(rdbwselect(daily$pm10, daily$r, c = 0, kernel = "triangular", masspoints = "off")$bws[1, 1], 1), "\n")
cat("paper: raw h=109, resid h=263\n")
