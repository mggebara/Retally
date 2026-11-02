library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-02-b/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
print(dim(d))
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(sprintf("%-28s %-10s NA=%3d %s | %s\n", v, class(x)[1], sum(is.na(x)), if(is.null(lab)) "" else lab, if(is.numeric(x)) paste(signif(summary(x)[c(1,3,4,6)],4),collapse=" ") else paste(head(unique(x),3),collapse=",")))}
cat("counties:", length(unique(d$GAZ_CNTY)), "\n")
