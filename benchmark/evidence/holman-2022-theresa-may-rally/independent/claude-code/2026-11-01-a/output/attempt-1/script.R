suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta"))
str(g, give.attr=FALSE)
for (v in names(g)) { l <- attr(g[[v]], "label"); cat(v, ":", if (is.null(l)) "" else l, "\n") }
print(summary(g))
cat("n countries", length(unique(g$country)), "\n")
print(table(g$pres_15death, useNA="a")); print(table(g$female_pres, useNA="a"))
print(table(g$kill_16, useNA="a")); print(table(g$execrlc, useNA="a")); print(table(g$election_qtr, useNA="a"))
print(head(as.data.frame(g[g$country==unique(g$country)[1], ]), 12))
print(class(g$qtr)); print(head(g$qtr))
dd <- read_dta(file.path(D, "did_data.dta"), n_max = 5)
str(dd, give.attr=FALSE)
for (v in names(dd)) { l <- attr(dd[[v]], "label"); cat(v, ":", if (is.null(l)) "" else l, "\n") }
