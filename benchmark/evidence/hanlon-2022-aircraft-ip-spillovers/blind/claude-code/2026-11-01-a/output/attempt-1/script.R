library(haven); library(dplyr)
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-11-01-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d,"airframe_data.dta")); e <- read_dta(paste0(d,"engine_data.dta"))
str(a); str(e)
print(table(a$country, useNA="a")); print(table(a$type, useNA="a")); print(table(a$year, a$country))
print(summary(a$ln_wingload)); print(all.equal(a$ln_wingload, log(a$wingload)))
print(summary(a$count))
print(table(e$country)); print(table(e$year, e$country)); print(summary(e)); print(table(e$count, useNA="a"))
print(with(a, table(type, country, is.na(ln_wingload))))
