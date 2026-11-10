suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-d/mount/goni_2022_assortative_matching_london_season/data/"
d <- read_dta(paste0(D,"final-data.dta"))
cat(names(d), "\n")
for (v in names(d)) { l <- attr(d[[v]],"label"); if(!is.null(l)) cat(v, ":", l, "\n") }
cat("base_sample\n"); print(table(d$base_sample, useNA="a"))
cat("marital_rates_sample\n"); print(table(d$marital_rates_sample, useNA="a"))
b <- d[d$base_sample %in% 1,]
cand <- c("syntheticT","cOut","mheir","fdown","distlondon","biorder","byear","hengpee","pr4","prank","fmissmatch","fmissmatch2","fatotal","nthismarriage","sample0","sample01")
for (v in intersect(cand,names(d))) { cat("==",v,"\n"); print(summary(b[[v]])) }
g <- grep("rank|diff|perc|acre|pct|land|dist|seat|eng|duke|dmar|heir|byear|age|sample", names(d), value=TRUE); cat(g,"\n")
m <- d[d$marital_rates_sample %in% 1,]
cat("nrow marital", nrow(m), "\n")
for (v in intersect(cand,names(d))) { cat("== mr",v,"\n"); print(summary(m[[v]])) }
