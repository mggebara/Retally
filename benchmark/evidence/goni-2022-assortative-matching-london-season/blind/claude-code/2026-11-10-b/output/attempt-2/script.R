suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-b/mount/goni_2022_assortative_matching_london_season"
d <- read_dta(file.path(D, "data/final-data.dta"))
cat("dim", dim(d), "\n")
for (v in names(d)) {
  lab <- attr(d[[v]], "label"); if (is.null(lab)) lab <- ""
  x <- d[[v]]
  nn <- if (is.character(x)) sum(!is.na(x) & x != "") else sum(!is.na(x))
  cat(sprintf("%-22s %-10s nn=%6d  %s\n", v, class(x)[1], nn, lab))
}
key <- intersect(c("base_sample","marital_rates_sample","syntheticT","cOut","mheir","fdown","distlondon","nthismarriage","nmarriages","myear","mage","biorder","age1861","byear","prank","pr4","hengpee","fmissmatch","fmissmatch2","fatotal","heir","peerage","entryflag"), names(d))
for (v in key) { cat("----", v, "\n"); x <- d[[v]]; if (length(unique(x))<30) print(table(x, useNA="ifany")) else print(summary(as.numeric(x))) }
