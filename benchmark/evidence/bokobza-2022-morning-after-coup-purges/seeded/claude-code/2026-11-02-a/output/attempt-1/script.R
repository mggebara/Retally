suppressPackageStartupMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/seeded/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
cl <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
str(cl[,1:37], give.attr=FALSE)
cat("dup country-year:", sum(duplicated(cl[,c("COUNTRY_ID","YEAR_DATA")])), "\n")
x <- cl %>% filter(!is.na(leader_cab_id))
cat("dup leader-year:", sum(duplicated(x[,c("leader_cab_id","YEAR_DATA")])), "\n")
ind <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
str(ind, give.attr=FALSE)
for (v in c("minister_type","importance_factor","experience_group","party_group","democracy_lag")) if (v %in% names(ind)) {cat(v,"\n"); print(table(ind[[v]], useNA="ifany"))}
