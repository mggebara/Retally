library(haven)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f, n_max = 2000)
cat(names(d), sep=" ", fill=150)
cat("\n")
for (v in names(d)) { l <- attr(d[[v]], "label"); if (!is.null(l)) cat(v, ":", l, "\n") }
