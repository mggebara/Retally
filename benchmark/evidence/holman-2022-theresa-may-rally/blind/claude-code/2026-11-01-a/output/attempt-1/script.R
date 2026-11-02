suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta"))
for (v in names(g)) { cat(v, "|", attr(g[[v]], "label"), "|", class(g[[v]])[1], "| NA:", sum(is.na(g[[v]])), "\n"); if (is.numeric(g[[v]])) print(summary(as.numeric(g[[v]]))) }
print(head(as.data.frame(g), 5))
cat("pres_15death table\n"); print(table(g$pres_15death, useNA="a"))
cat("female_pres\n"); print(table(g$female_pres, useNA="a"))
print(table(g$pres_15death, g$female_pres))
cat("execrlc\n"); print(table(g$execrlc, useNA="a"))
cat("election_qtr\n"); print(table(g$election_qtr, useNA="a"))
print(head(g$qtr, 20)); cat("n countries", length(unique(g$country)), "\n")
cc <- complete.cases(g[,c("lag_approval","pres_15death","female_pres","growth","log_inflation","execrlc","election_qtr")])
cat("complete:", sum(cc), " countries:", length(unique(g$country[cc])), "\n")
print(table(g$pres_15death[cc], g$female_pres[cc]))
uk <- g[grepl("King|UK|Brit", g$country),]
print(tail(as.data.frame(uk[,c("country","qtr","lag_approval","pres_15death","female_pres","manchester","rally_events","rally_kill","kill_16")]),25))
print(as.data.frame(g[which(g$pres_15death==1 & g$female_pres==1), c("country","qtr","lag_approval","pres_15death","female_pres","execrlc","growth","log_inflation")]))
EOF_PLACEHOLDER <- NULL
