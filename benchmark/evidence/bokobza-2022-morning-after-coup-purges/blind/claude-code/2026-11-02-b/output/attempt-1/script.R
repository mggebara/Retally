suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(D, "morning_after_dataset_countrylevel.dta"))
cat("== country names\n"); print(names(c))
for (v in names(c)) { x <- c[[v]]; lab <- attr(x, "label"); cat(v, "|", class(x)[1], "|", if(!is.null(lab)) lab else "", "| NA:", sum(is.na(x)), "\n"); if (is.numeric(x)) print(summary(as.numeric(x))) }
cat("tab coupattempt_whogov_br\n"); print(table(c$coupattempt_whogov_br, useNA="a"))
cat("tab coupattempt_whogov\n"); print(table(c$coupattempt_whogov, useNA="a"))
cat("tab ldemocracy_br\n"); print(table(c$ldemocracy_br, useNA="a"))
cat("tab democracy_br\n"); print(table(c$democracy_br, useNA="a"))
print(head(as.data.frame(c[c$COUNTRY_DATA %in% c("Argentina"), intersect(names(c), c("YEAR_DATA","COUNTRY_DATA","democracy_br","ldemocracy_br","coupattempt_whogov","coupattempt_month_whogov","coupattempt_whogov_br","replacement_rateadj_minister","leader_cab_id","gdp_cap_pwt_ln","military_c"))]), 60))
i <- readRDS(file.path(D, "morning_after_dataset_individuallevel.rds"))
cat("== indiv\n"); print(dim(i)); str(i, list.len=60)
for (v in c("party_group","Group","experience_group","classification","prestige_1","importance_numeric","prestige_numeric","purged_y1","coupattempt_presentyear","coupattempt_presentyear_br","democracy_lag_br","position")) { cat("--", v, "\n"); print(head(sort(table(i[[v]], useNA="a"), decreasing=TRUE), 30)) }
print(summary(i$experience)); print(summary(i$year))
