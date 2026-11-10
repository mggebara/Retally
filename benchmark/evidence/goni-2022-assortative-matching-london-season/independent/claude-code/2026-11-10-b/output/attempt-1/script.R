suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-b/mount/goni_2022_assortative_matching_london_season/data/final-data.dta"
d <- read_dta(D)
cat("dim", dim(d), "\n")
for (v in names(d)) { l <- attr(d[[v]], "label"); cat(v, "|", class(d[[v]])[1], "|", ifelse(is.null(l), "", l), "\n") }
key <- c("base_sample","marital_rates_sample","cOut","mheir","fdown","syntheticT","distlondon","biorder","nthismarriage","fmissmatch","fmissmatch2","heir","peerage")
for (v in intersect(key, names(d))) { cat("==", v, "\n"); print(summary(as.numeric(d[[v]]))) }
cat("base_sample tab\n"); print(table(d$base_sample, useNA="ifany"))
cat("marital tab\n"); print(table(d$marital_rates_sample, useNA="ifany"))
