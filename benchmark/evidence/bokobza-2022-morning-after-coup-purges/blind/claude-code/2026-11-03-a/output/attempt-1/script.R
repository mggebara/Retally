D <- "<repo>/benchmark/.cache/claude-code/bokobza-2022-morning-after-coup-purges/blind/2026-11-03-a/mount/bokobza_2022_morning_after_coup_purges"
library(haven)
c <- read_dta(file.path(D,"morning_after_dataset_countrylevel.dta"))
str(as.data.frame(c), give.attr=FALSE, list.len=100)
for (v in names(c)) { l <- attr(c[[v]],"label"); if(!is.null(l)) cat(v,":",l,"\n") }
print(summary(as.data.frame(c)))
cat("dem_br tab\n"); print(table(c$democracy_br, useNA="a")); print(table(c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov_br, c$ldemocracy_br, useNA="a"))
print(table(c$coupattempt_whogov, useNA="a")); print(table(c$coupattempt_whogov_type_br, useNA="a"))
i <- readRDS(file.path(D,"morning_after_dataset_individuallevel.rds"))
str(i, give.attr=FALSE, list.len=100)
for (v in names(i)) if (is.character(i[[v]]) || is.factor(i[[v]])) { t<-table(i[[v]],useNA="a"); if(length(t)<60){cat("==",v,"\n");print(t)} else cat("==",v,"levels",length(t),"\n") }
print(summary(i[sapply(i,is.numeric)]))
