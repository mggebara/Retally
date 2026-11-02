suppressMessages({library(haven); library(dplyr)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-b/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(M,"global_approval.dta"))
str(g, give.attr=FALSE)
for (v in names(g)) { l <- attr(g[[v]],"label"); cat(v, ":", if(is.null(l)) "" else l, "\n") }
print(summary(g))
cat("countries:", length(unique(g$country)), "\n")
print(table(g$pres_15death, useNA="a")); print(table(g$kill_16, useNA="a"))
print(table(g$female_pres, useNA="a")); print(table(g$execrlc, useNA="a")); print(table(g$election_qtr, useNA="a"))
print(head(as.data.frame(g[g$country==unique(g$country)[1], ]), 12))
print(class(g$qtr)); print(head(g$qtr))
print(with(g, table(pres_15death, female_pres)))
print(with(g, table(kill_16, female_pres)))
print(as.data.frame(g[g$pres_15death %in% 1 & g$female_pres %in% 1, c("country","qtr","kill_16","pres_15death","lag_approval")]))
d <- read_dta(file.path(M,"did_data.dta"), n_max=200000)
for (v in names(d)) { l <- attr(d[[v]],"label"); cat(v, ":", if(is.null(l)) "" else l, "\n") }
str(d, give.attr=FALSE)
