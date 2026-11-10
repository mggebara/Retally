suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-a/mount/goni_2022_assortative_matching_london_season"
d <- read_dta(file.path(D, "data/final-data.dta"))
cat(dim(d), "\n")
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
for (n in names(d)) cat(n, "|", class(d[[n]])[1], "|", lab[n], "| nNA=", sum(is.na(d[[n]])), "\n")
for (v in c("base_sample","marital_rates_sample")) { print(table(d[[v]], useNA="a")) }
s <- read_dta(file.path(D, "data/final-data-sec4.dta"))
cat("sec4", dim(s), "\n")
