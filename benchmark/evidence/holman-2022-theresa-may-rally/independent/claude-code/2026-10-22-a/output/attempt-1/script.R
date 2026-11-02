suppressMessages({library(haven); library(dplyr)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(M, "global_approval.dta"))
print(dim(g))
for (v in names(g)) { l <- attr(g[[v]], "label"); cat(v, ":", if (is.null(l)) "" else l, " class=", class(g[[v]])[1], "\n") }
print(summary(as.data.frame(zap_labels(g))))
print(table(g$pres_15death, g$female_pres, useNA="ifany"))
print(table(g$execrlc, useNA="ifany"))
print(head(as.data.frame(g[g$country_code==g$country_code[1], c("country","qtr","lag_approval","pres_15death","female_pres","growth","log_inflation","election_qtr","execrlc")]), 20))
d <- read_dta(file.path(M, "did_data.dta"))
print(dim(d))
for (v in names(d)) { l <- attr(d[[v]], "label"); cat(v, ":", if (is.null(l)) "" else l, " class=", class(d[[v]])[1], "\n") }
dd <- as.data.frame(zap_labels(d)); rm(d); invisible(gc())
print(summary(dd))
print(table(dd$wave, useNA="ifany"))
print(with(dd, table(wave, time, useNA="ifany")))
print(with(dd, table(wave, treatment1, useNA="ifany")))
print(with(dd, table(wave, treatment2, useNA="ifany")))
print(with(dd, table(wave, post_attack, useNA="ifany")))
print(with(dd, table(wave, !is.na(likeMayW))))
print(with(dd, table(wave, !is.na(may_bestpm))))
print(with(dd, table(wave, !is.na(bestPMW))))
print(table(dd$bestPMW, useNA="ifany")); print(table(dd$may_bestpm, useNA="ifany"))
for (v in c("white","gender","labour","party_other","income","ideology","ideology2","ideo3","conservative")) {cat(v,"\n"); print(table(dd[[v]], useNA="ifany"))}
