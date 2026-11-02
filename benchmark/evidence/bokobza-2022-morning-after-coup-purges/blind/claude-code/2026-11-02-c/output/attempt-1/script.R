suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-c/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
str(c, give.attr=FALSE, vec.len=3)
for (v in names(c)) { l <- attr(c[[v]],"label"); if(!is.null(l)) cat(v,":",l,"\n") }
print(table(c$coupattempt_whogov_br, useNA="a")); print(table(c$coupattempt_whogov, useNA="a"))
print(table(c$ldemocracy_br, useNA="a")); print(summary(c$YEAR_DATA))
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
str(i, give.attr=FALSE, vec.len=3)
for (v in c("party_group","experience_group","Group","classification","prestige_1","prestige_numeric","importance_numeric","portfolio_1","position")) {cat("==",v,"\n"); print(head(sort(table(i[[v]],useNA="a"),decreasing=TRUE),50))}
print(table(i$purged_y1,useNA="a")); print(table(i$coupattempt_presentyear_br,useNA="a"))
print(table(i$democracy_lag_br,useNA="a")); print(summary(i$year))
