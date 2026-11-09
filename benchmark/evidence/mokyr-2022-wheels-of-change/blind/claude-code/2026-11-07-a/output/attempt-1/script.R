library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-07-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
print(dim(d))
for (v in names(d)) { lab <- attr(d[[v]], "label"); x <- d[[v]]
 if (is.numeric(x)) cat(sprintf("%-28s %-50s n=%d mean=%.4g sd=%.4g min=%.4g max=%.4g\n", v, substr(ifelse(is.null(lab),"",lab),1,50), sum(!is.na(x)), mean(x,na.rm=T), sd(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T)))
 else cat(v, "char", length(unique(x)), "\n") }
print(table(is.na(d$mills)))
print(head(as.data.frame(d[,c("local_government_area","district_id","wrights","mills","pcmean","GAZ_CNTY")]),15))
print(length(unique(d$GAZ_CNTY[!is.na(d$mills)])))
print(summary(d$wheat_tmean)); print(table(d$wheat_tmean<=5, useNA="a"))
