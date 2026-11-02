suppressMessages(library(haven))
d <- haven::read_dta("<repo>/benchmark/.cache/claude-code/mokyr-2022-wheels-of-change/independent/2026-11-02-a/mount/mokyr_2022_wheels_of_change/3 replication package/Replication files/Data/replication_data.dta")
cat(dim(d), "\n")
for (v in names(d)) {
  x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  if (is.numeric(x)) cat(sprintf("%-26s %-45s n=%d mean=%.4g sd=%.4g min=%.4g max=%.4g\n", v, substr(lab,1,45), sum(!is.na(x)), mean(x,na.rm=TRUE), sd(x,na.rm=TRUE), min(x,na.rm=TRUE), max(x,na.rm=TRUE)))
  else cat(v, class(x)[1], length(unique(x)), head(unique(x)), "\n")
}
