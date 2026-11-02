suppressPackageStartupMessages({library(haven); library(dplyr)})
dir <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(dir, "morning_after_dataset_countrylevel.dta"))
str(c, give.attr=FALSE, list.len=60)
for (v in names(c)) { l <- attr(c[[v]], "label"); if (!is.null(l)) cat(v, ":", l, "\n") }
print(summary(c$YEAR_DATA)); print(table(c$democracy_br, useNA="a")); print(table(c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov_br, useNA="a")); print(table(c$coupattempt_whogov, useNA="a"))
i <- readRDS(file.path(dir, "morning_after_dataset_individuallevel.rds"))
str(i, give.attr=FALSE, list.len=60)
for (v in c("experience_group","Group","party_group","classification","importance_numeric","prestige_numeric","purged_y1","coupattempt_presentyear_br","coupattempt_whogov_type_br","democracy_lag_br","leader","portfolio_1")) { cat("==", v, "\n"); print(head(sort(table(i[[v]], useNA="a"), decreasing=TRUE), 45)) }
print(summary(i$year)); print(summary(i$experience))
