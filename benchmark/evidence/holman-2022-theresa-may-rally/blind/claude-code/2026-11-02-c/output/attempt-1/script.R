suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-02-c/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D,"global_approval.dta"))
for (v in names(g)) { l <- attr(g[[v]],"label"); cat(v, ":", if(is.null(l)) "" else l, " class:", class(g[[v]])[1], "\n") }
print(summary(g))
for (v in grep("kill|rally|death",names(g),value=TRUE)) {cat(v,"\n"); print(table(g[[v]],useNA="a"))}
print(table(g$female_pres, useNA="a")); print(table(g$execrlc, useNA="a")); print(table(g$election_qtr,useNA="a"))
print(head(g$qtr)); print(length(unique(g$country)))
uk <- as.data.frame(g[g$country %in% c("United Kingdom","UK","Britain"),c("country","qtr","lag_approval","pres_15death","female_pres","growth","log_inflation","execrlc","election_qtr","manchester")])
print(tail(uk, 20))
cc <- complete.cases(g[,c("lag_approval","pres_15death","female_pres","growth","log_inflation","execrlc","election_qtr")])
cat("complete:", sum(cc), " countries:", length(unique(g$country[cc])), "\n")
print(as.data.frame(g[g$pres_15death==1 & !is.na(g$pres_15death), c("country","qtr","female_pres","lag_approval","kill_16")]))
d <- read_dta(file.path(D,"did_data.dta"), n_max=5)
for (v in names(d)) { l <- attr(d[[v]],"label"); cat(v, ":", if(is.null(l)) "" else l, " class:", class(d[[v]])[1], "\n") }
