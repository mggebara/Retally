suppressMessages({library(haven); library(dplyr)})
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P, "morning_after_dataset_countrylevel.dta"))
str(c, give.attr=FALSE)
for (v in names(c)) { l <- attr(c[[v]], "label"); if(!is.null(l)) cat(v, ":", l, "\n") }
print(summary(c))
cat("table ldemocracy_br\n"); print(table(c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov_br, useNA="a")); print(table(c$coupattempt_whogov, useNA="a"))
print(table(c$coupattempt_whogov_br[c$ldemocracy_br==0], useNA="a"))
print(range(c$YEAR_DATA))
d <- readRDS(file.path(P, "morning_after_dataset_individuallevel.rds"))
str(d, give.attr=FALSE)
for (v in c("party_group","experience_group","Group","classification","prestige_1","prestige_numeric","importance_numeric","leader","purged_y1","purged_y2","coupattempt_presentyear","coup_presentyear","coupattempt_presentyear_br","democracy_lag_br","position","leader_party","party")) {cat("==",v,"\n"); print(head(sort(table(d[[v]], useNA="a"),decreasing=TRUE),45))}
print(head(as.data.frame(d),5))
