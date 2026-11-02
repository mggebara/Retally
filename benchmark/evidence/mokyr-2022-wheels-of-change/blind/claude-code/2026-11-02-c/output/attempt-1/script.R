library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/blind/2026-11-02-c/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
print(dim(d)); print(names(d))
for (v in names(d)) { x <- d[[v]]; if (is.numeric(x)) cat(sprintf("%-25s n=%d na=%d mean=%.4g sd=%.4g min=%.4g max=%.4g lab=%s\n", v, sum(!is.na(x)), sum(is.na(x)), mean(x,na.rm=T), sd(x,na.rm=T), min(x,na.rm=T), max(x,na.rm=T), paste(attr(x,"label"),collapse=""))) else cat(v, class(x), "\n") }
cat("mills NA:", sum(is.na(d$mills)), " zero:", sum(d$mills==0,na.rm=T), "\n")
print(table(d$GAZ_CNTY[is.na(d$mills)]))
print(length(unique(d$GAZ_CNTY)))
print(summary(d$wheat_tmean)); print(table(round(d$wheat_tmean)))
cat("mills pc mean:", mean(1e4*d$mills/d$pcmean, na.rm=T), " wrights pc mean:", mean(1e4*d$wrights/d$pcmean), "\n")
