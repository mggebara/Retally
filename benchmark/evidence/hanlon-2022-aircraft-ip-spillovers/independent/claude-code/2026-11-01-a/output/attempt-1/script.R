library(haven); library(dplyr)
d <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-01-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d,"airframe_data.dta")); e <- read_dta(paste0(d,"engine_data.dta"))
str(a); str(e)
print(table(a$country, useNA="a")); print(table(a$type, useNA="a")); print(table(a$year))
print(table(e$country, useNA="a")); print(table(e$year)); print(summary(a$count)); print(table(e$count,useNA="a"))
print(a %>% group_by(country,type) %>% summarise(n=n(), nwl=sum(!is.na(ln_wingload)), nms=sum(!is.na(ln_maxspeed)), ymin=min(year),ymax=max(year)), n=100)
print(e %>% group_by(country) %>% summarise(n=n(), nhp=sum(!is.na(ln_hp_per_lbs)), ymin=min(year),ymax=max(year)))
print(head(as.data.frame(a),10))
