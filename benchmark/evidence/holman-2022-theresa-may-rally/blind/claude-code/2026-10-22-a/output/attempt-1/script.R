suppressPackageStartupMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D,"global_approval.dta"))
for (v in names(g)) { cat("\n==",v, class(g[[v]])[1], attr(g[[v]],"label"), "\n"); if (is.numeric(g[[v]])) print(summary(as.numeric(g[[v]]))) else print(head(unique(g[[v]]))) }
cat("\nqtr head:\n"); print(head(g$qtr,20))
cat("pres_15death table\n"); print(table(g$pres_15death, useNA="ifany"))
cat("female_pres x pres_15death\n"); print(table(g$female_pres, g$pres_15death, useNA="ifany"))
print(table(g$execrlc, useNA="ifany"))
print(table(g$election_qtr, useNA="ifany"))
cc <- complete.cases(g[,c("lag_approval","pres_15death","female_pres","growth","log_inflation","execrlc","election_qtr")])
cat("complete:", sum(cc), " countries:", length(unique(g$country[cc])), "\n")
print(head(as.data.frame(g[g$country==unique(g$country)[3], c("country","qtr","lag_approval","pres_15death","kill_16","rally_kill","growth","election_qtr")]), 16))
d <- read_dta(file.path(D,"did_data.dta"), n_max=5)
for (v in names(d)) cat(v, ":", class(d[[v]])[1], attr(d[[v]],"label"), "\n")
