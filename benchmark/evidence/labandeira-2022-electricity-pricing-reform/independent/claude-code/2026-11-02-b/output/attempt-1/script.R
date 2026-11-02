suppressMessages({library(haven); library(data.table)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))
cat(dim(d), "\n")
for (v in names(d)) { x <- d[[v]]; lab <- attr(x,"label"); cat(v, "|", class(x)[1], "|", if(is.null(lab)) "" else lab, "| NA=", sum(is.na(x)), "| ", paste(head(unique(as.vector(x)),6), collapse=","), "\n") }
print(table(d$year, d$T2, useNA="ifany"))
print(table(d$year, d$dup, useNA="ifany"))
