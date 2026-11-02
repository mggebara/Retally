suppressMessages({library(haven); library(dplyr)})
d <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(d,"morning_after_dataset_countrylevel.dta"))
str(as.data.frame(c), give.attr=FALSE, list.len=60)
for (v in names(c)) { l <- attr(c[[v]],"label"); if(!is.null(l)) cat(v, ":", l, "\n") }
print(summary(as.data.frame(c)))
cat("dem lag tab\n"); print(table(c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov, useNA="a")); print(table(c$coupattempt_whogov_br, useNA="a"))
print(with(c, table(coupattempt_whogov, ldemocracy_br, useNA="a")))
print(range(c$YEAR_DATA))
i <- readRDS(file.path(d,"morning_after_dataset_individuallevel.rds"))
str(i, give.attr=FALSE, list.len=60)
for (v in c("party_group","experience_group","Group","classification","prestige_1","prestige_numeric","importance_numeric","purged_y1","coupattempt_presentyear","coup_presentyear","coupattempt_presentyear_br","leader","democracy_lag_br")) { cat("==",v,"\n"); print(head(sort(table(i[[v]],useNA="a"),decreasing=TRUE),40)) }
print(table(i$portfolio_1, i$prestige_1, useNA="a"))
print(summary(i$experience)); print(range(i$year))
print(with(i, table(importance_numeric, classification, useNA="a")))
