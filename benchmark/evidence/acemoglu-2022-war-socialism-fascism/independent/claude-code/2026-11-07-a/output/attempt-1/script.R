suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-07-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
nm <- names(d)
pre <- sub("_?[0-9]+$","",nm)
tab <- sort(table(pre), decreasing=TRUE)
print(head(tab, 40))
singles <- nm[pre %in% names(tab)[tab<=3]]
for (v in singles) { lab <- attr(d[[v]],"label"); cat(v, "|", if(is.null(lab)) "" else lab, "| NA=", sum(is.na(d[[v]])), "| mean=", tryCatch(signif(mean(as.numeric(d[[v]]),na.rm=TRUE),4),error=function(e) NA), "\n") }
for (p in names(tab)[tab>3]) { v <- nm[pre==p][1]; lab <- attr(d[[v]],"label"); cat("GROUP", p, tab[p], "e.g.", v, "|", if(is.null(lab)) "" else lab, "\n") }
