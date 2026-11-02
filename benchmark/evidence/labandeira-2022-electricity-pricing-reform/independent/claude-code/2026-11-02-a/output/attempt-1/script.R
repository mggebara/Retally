library(haven)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f, n_max = 3000)
for (v in names(d)) { l <- attr(d[[v]], "label"); cat(v, "|", class(d[[v]])[1], "|", ifelse(is.null(l), "", l), "|", paste(head(unique(as.vector(d[[v]])), 6), collapse=","), "\n") }
