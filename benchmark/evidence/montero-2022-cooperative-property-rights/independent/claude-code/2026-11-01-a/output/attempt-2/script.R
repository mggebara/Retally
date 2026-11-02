suppressMessages({library(haven); library(dplyr)})
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-01-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
for (v in names(d)[28:119]) { x <- d[[v]]; lab <- attr(x,"label"); s <- iconv(paste(head(unique(x),6), collapse=","), "", "ASCII", sub="?"); cat(v, "|", class(x)[1], "| nNA=", sum(is.na(x)), "| nuniq=", length(unique(x)), "| ex:", substr(s,1,80), "\n") }
cat("\n---- key tabs\n")
print(table(d$Matched, useNA="a")); print(table(d$reform, useNA="a")); print(table(d$Above500, useNA="a"))
print(table(d$survey_year, d$year, useNA="a"))
print(summary(d$norm_dist_Above)); print(summary(d$own_amt))
print(table(is.na(d$Reform_Coop_id), is.na(d$Hacienda_id)))
print(length(unique(d$match_id)))
