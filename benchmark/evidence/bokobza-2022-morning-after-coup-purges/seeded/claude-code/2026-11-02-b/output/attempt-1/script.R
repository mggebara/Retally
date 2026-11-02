suppressMessages({library(dplyr); library(haven)})
M <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-b/mount/bokobza_2022_morning_after_coup_purges"
d <- readRDS(file.path(M,"morning_after_dataset_individuallevel.rds"))
str(d, list.len=60, vec.len=2)
for (v in c("experience_group","importance_factor","minister_type","party_group","democracy_lag","coupattempt_presentyear")) if (v %in% names(d)) print(table(d[[v]], useNA="ifany"))
cc <- read_dta(file.path(M,"morning_after_dataset_countrylevel.dta"))
str(cc, list.len=40, vec.len=2, give.attr=FALSE)
cat("dup country-year:", sum(duplicated(cc[,c("COUNTRY_ID","YEAR_DATA")])), "\n")
cat("dup leader-year:", sum(duplicated(cc[!is.na(cc$leader_cab_id),c("leader_cab_id","YEAR_DATA")])), "\n")
