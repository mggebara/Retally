suppressPackageStartupMessages({library(haven); library(data.table); library(rdrobust)})
D <- "<repo>/benchmark/.cache/claude-code/greenstone-2022-china-pollution-monitoring-automation/blind/2026-11-10-b/mount/greenstone_2022_china_pollution_monitoring_automation/China_Pollution_Monitoring/Data/"
sd <- function(x) as.Date(x, origin = "1960-01-01")
st <- as.data.table(read_dta(paste0(D,"station_list.dta")))
st[, ad := sd(auto_date)]
print(table(format(st$ad, "%Y-%m-%d"), st$phase))
st[, deadline := (phase==1 & ad==as.Date("2013-01-01")) | (phase==2 & ad==as.Date("2014-01-01"))]
print(st[, .(n=.N, ncity=uniqueN(code_city)), by=.(phase, deadline)])
p <- as.data.table(read_dta(paste0(D,"pollution_1116.dta")))[, .(station_n, code_city, date, pm10)]
w <- as.data.table(read_dta(paste0(D,"weather_1116.dta")))
p <- cbind(p, w[, .(wind_speed, rain, temp, rh)])
p[, d := sd(date)]
print(range(p$d))
p <- merge(p, st[, .(station_n=pm10_n, city2=code_city, phase, ad, deadline)], by="station_n")
cat("city mismatch:", sum(p$code_city != p$city2), "\n")
pp <- p[!is.na(pm10)]
pp[, r := as.numeric(d - ad)]
print(pp[, .(pre=sum(r<0), post=sum(r>=0)), by=.(yr=year(d))][order(yr)])
cat("N pm10:", nrow(pp), " pm10==0:", sum(pp$pm10==0), " >=1000:", sum(pp$pm10>=1000), " pm10>600:", sum(pp$pm10>600), "\n")
cat("N with all weather:", nrow(pp[!is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed)]), "\n")
# stations with any pre data and any post data
sp <- pp[, .(pre=sum(r<0), post=sum(r>=0)), by=station_n]
cat("stations no pre:", sum(sp$pre==0), " no post:", sum(sp$post==0), "\n")
print(quantile(pp$r, c(0,.01,.5,.99,1)))
# deadline event sample
ev <- pp[deadline==TRUE & d>=as.Date("2012-01-01") & d<=as.Date("2013-12-31")]
cat("event N:", nrow(ev), " w/ weather:", nrow(ev[!is.na(temp)&!is.na(rh)&!is.na(rain)&!is.na(wind_speed)]), " stations by phase:\n"); print(ev[, uniqueN(station_n), by=phase])
print(st[deadline==TRUE, .N, by=phase])
# timing test rdrobust raw on full data (no output of estimates)
t0 <- Sys.time()
rr <- rdrobust(pp$pm10, pp$r, c=0, kernel="triangular", p=1, bwselect="mserd", cluster=pp$code_city, vce="hc1")
cat("rdrobust full time:", format(Sys.time()-t0), " h=", rr$bws[1,1], " N_h=", sum(rr$N_h), "\n")
t0 <- Sys.time()
rr2 <- rdrobust(pp$pm10, pp$r, c=0, kernel="triangular", p=1, bwselect="mserd", cluster=pp$code_city, vce="hc1", masspoints="off")
cat("rdrobust full time (mp off):", format(Sys.time()-t0), " h=", rr2$bws[1,1], " N_h=", sum(rr2$N_h), "\n")
