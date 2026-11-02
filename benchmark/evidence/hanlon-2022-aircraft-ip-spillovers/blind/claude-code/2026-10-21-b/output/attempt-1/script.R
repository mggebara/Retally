library(haven)
d <- "<repo>/benchmark/.cache/claude-code/hanlon-2022-aircraft-ip-spillovers/blind/2026-10-21-b/mount/hanlon_2022_aircraft_ip_spillovers/3 replication files/data/dta/"
a <- read_dta(paste0(d,"airframe_data.dta")); e <- read_dta(paste0(d,"engine_data.dta"))
str(a); print(table(a$country, useNA="a")); print(table(a$type, useNA="a")); print(table(a$year,a$country))
print(summary(a$count)); print(table(is.na(a$ln_wingload), a$country)); print(table(is.na(a$ln_maxspeed), a$country))
print(head(as.data.frame(a),10))
print(table(a$type, a$country))
str(e); print(table(e$country)); print(table(e$year,e$country)); print(summary(e$count)); print(table(is.na(e$ln_hp_per_lbs),e$country)); print(head(as.data.frame(e),10))
for (v in names(a)) if (!is.null(attr(a[[v]],"labels"))) {cat(v,"\n"); print(attr(a[[v]],"labels"))}
for (v in names(e)) if (!is.null(attr(e[[v]],"labels"))) {cat(v,"\n"); print(attr(e[[v]],"labels"))}
EOF_MARKER <- NULL
