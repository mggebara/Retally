D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
library(haven); library(dplyr)
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
str(c, give.attr=FALSE, list.len=60)
for (v in names(c)) { lab <- attr(c[[v]],"label"); cat(v, ":", if(is.null(lab)) "" else lab, "\n") }
print(table(c$ldemocracy_br, useNA="a")); print(table(c$coupattempt_whogov, useNA="a")); print(table(c$coupattempt_whogov_br, useNA="a"))
print(summary(c$YEAR_DATA))
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
str(i, list.len=60)
for (v in c("Group","experience_group","party_group","classification","prestige_1","importance_numeric","prestige_numeric","purged_y1","coupattempt_presentyear","coupattempt_presentyear_br","democracy_lag_br","leader","position")) { cat("==",v,"\n"); print(head(sort(table(i[[v]],useNA="a"),decreasing=TRUE),30)) }
tp <- sort(table(i$portfolio_1), decreasing=TRUE); print(head(tp, 60))
