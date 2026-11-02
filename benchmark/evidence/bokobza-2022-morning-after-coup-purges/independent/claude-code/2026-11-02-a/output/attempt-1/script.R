library(haven); library(dplyr)
P <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/independent/2026-11-02-a/mount/bokobza_2022_morning_after_coup_purges"
c <- read_dta(file.path(P,"morning_after_dataset_countrylevel.dta"))
str(c, give.attr=FALSE)
for (v in names(c)) { l <- attr(c[[v]],"label"); if(!is.null(l)) cat(v,":",l,"\n") }
print(summary(c))
print(table(c$coupattempt_whogov, c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov_br, c$ldemocracy_br, useNA="a"))
i <- readRDS(file.path(P,"morning_after_dataset_individuallevel.rds"))
str(i, give.attr=FALSE)
for (v in names(i)) if (!is.numeric(i[[v]]) || length(unique(i[[v]]))<15) {cat("==",v,"\n"); print(head(sort(table(i[[v]],useNA="a"),decreasing=TRUE),20))}
print(summary(i[sapply(i,is.numeric)]))
