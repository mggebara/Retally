suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-a/mount/goni_2022_assortative_matching_london_season/data/final-data.dta"
d <- read_dta(D)
cat(dim(d), "\n")
for (v in names(d)) { l <- attr(d[[v]], "label"); cat(v, ":", class(d[[v]])[1], ":", ifelse(is.null(l), "", l), "\n") }
vars <- c("base_sample","marital_rates_sample","syntheticT","cOut","mheir","fdown","nmarriages","nthismarriage","distlondon","biorder","peerage","title","heir","myear","mage","fmissmatch","fmissmatch2","fatotal")
for (v in intersect(vars, names(d))) { cat("----", v, "\n"); x <- zap_labels(d[[v]]); if (length(unique(x)) < 30) print(table(x, useNA="a")) else print(summary(as.numeric(x))) }
b <- d[!is.na(d$base_sample) & d$base_sample == 1, ]
cat("base_sample==1 rows:", nrow(b), "\n")
for (v in intersect(vars, names(d))) { cat("---- base:", v, "\n"); x <- zap_labels(b[[v]]); if (length(unique(x)) < 30) print(table(x, useNA="a")) else print(summary(as.numeric(x))) }
