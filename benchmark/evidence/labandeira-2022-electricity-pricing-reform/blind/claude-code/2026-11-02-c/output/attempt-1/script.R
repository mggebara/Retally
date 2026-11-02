library(haven); library(data.table)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f)
cat(dim(d), "\n")
nm <- names(d)
for (v in nm) { x <- d[[v]]; lab <- attr(x, "label"); if (is.null(lab)) lab <- "";
  if (is.numeric(x)) cat(sprintf("%-14s | %-50s | NA=%d mean=%.4g min=%.4g max=%.4g nuniq=%d\n", v, substr(lab,1,50), sum(is.na(x)), mean(x,na.rm=T), suppressWarnings(min(x,na.rm=T)), suppressWarnings(max(x,na.rm=T)), length(unique(x))))
  else cat(sprintf("%-14s | %-50s | class=%s nuniq=%d\n", v, substr(lab,1,50), class(x)[1], length(unique(x)))) }
