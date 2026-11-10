suppressMessages({library(haven); library(dplyr)})
P <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-d/mount/goni_2022_assortative_matching_london_season"
d <- read_dta(file.path(P, "data/final-data.dta"))
cat("dims", dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
for (i in seq_along(nm)) cat(nm[i], ":", lab[i], "|", class(d[[i]])[1], "\n")
keyv <- c("base_sample","marital_rates_sample","syntheticT","cOut","mheir","fdown","distlondon","biorder","nthismarriage","myear","mage","byear","age1861","hengpee","pr4","prank","fmissmatch","fmissmatch2","cs")
for (v in intersect(keyv, nm)) { cat("----", v, "\n"); print(summary(as.numeric(d[[v]]))) }
for (v in intersect(c("base_sample","marital_rates_sample","nthismarriage","hengpee","pr4","prank","fmissmatch","fmissmatch2"), nm)) {cat("tab", v, "\n"); print(table(as.numeric(d[[v]]), useNA="ifany"))}
