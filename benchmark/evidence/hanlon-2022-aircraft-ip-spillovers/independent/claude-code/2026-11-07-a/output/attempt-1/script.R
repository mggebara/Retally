library(haven); library(dplyr)
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/independent/2026-11-07-a/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d,"airframe_data.dta")); e <- read_dta(paste0(d,"engine_data.dta"))
str(a); print(table(a$country, a$type, useNA="ifany")); print(table(a$year))
print(summary(a$count)); print(table(a$country, !is.na(a$ln_wingload), useNA="ifany"))
str(e); print(table(e$country, useNA="ifany")); print(table(e$year)); print(summary(e$count))
print(table(e$country, !is.na(e$ln_hp_per_lbs)))
for (cn in unique(a$country)) for (ty in unique(a$type)) {
  s <- a[a$country == cn & a$type == ty, ]
  cat(cn, ty, nrow(s), sum(!is.na(s$ln_wingload)), sum(!is.na(s$ln_maxspeed)), range(s$year), "\n")
}
print(head(as.data.frame(a), 5))
