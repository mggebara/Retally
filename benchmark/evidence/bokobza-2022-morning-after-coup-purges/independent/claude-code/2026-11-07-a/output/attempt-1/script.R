D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-07-a/mount/bokobza_2022_morning_after_coup_purges"
library(haven)
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
print(names(c)); print(summary(as.data.frame(zap_labels(c))))
for (v in names(c)) { l <- attr(c[[v]],"label"); if(!is.null(l)) cat(v,":",l,"\n") }
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
str(i, list.len=60)
for (v in c("party_group","experience_group","Group","classification","portfolio_1","prestige_1","prestige_numeric","importance_numeric","purged_y1","coupattempt_presentyear","coupattempt_presentyear_br","democracy_lag_br","leader","leader_party","position")) { cat("==",v,"\n"); print(head(sort(table(i[[v]],useNA="ifany"),decreasing=TRUE),30)) }
