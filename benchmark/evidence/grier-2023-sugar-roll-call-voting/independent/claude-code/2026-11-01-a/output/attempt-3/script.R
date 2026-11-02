suppressMessages({library(haven); library(dplyr)})
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
d <- read_dta(file.path(D,"SugarReplicate.dta")) %>% mutate(aye = as.integer(vote=="Aye"))
cat("dup id-cong (all rows):", sum(duplicated(d[,c("id","cong")])), "\n")
print(d %>% group_by(id,cong) %>% filter(n()>1) %>% select(id,cong,name,cid,vote,both,tenure) %>% as.data.frame())
dd <- d %>% group_by(id) %>% summarise(n=n(), nc=n_distinct(cong), m=mean(aye), ncid=n_distinct(cid), sw=n_distinct(aye))
print(table(dd$n, dd$nc))
cat("districts with 2 congs & aye varies:", sum(dd$nc==2 & dd$sw==2), "\n")
cat("  of which n==2:", sum(dd$nc==2 & dd$sw==2 & dd$n==2), " same cid:", sum(dd$nc==2 & dd$sw==2 & dd$ncid==1), "\n")
ii <- d %>% group_by(cid) %>% summarise(n=n(), nc=n_distinct(cong), sw=n_distinct(aye), nid=n_distinct(id), both=mean(both))
cat("incumbents in both congs:", sum(ii$nc==2), " switched:", sum(ii$nc==2 & ii$sw==2), "\n")
# both==1 based
ib <- d %>% filter(both==1) %>% group_by(cid) %>% summarise(n=n(), sw=n_distinct(aye))
cat("both==1 cids:", nrow(ib), " switched:", sum(ib$sw==2), " n table:\n"); print(table(ib$n))
# switching w/ vote categories
sid <- dd$id[dd$nc==2 & dd$sw==2]
print(table(d$vote[d$id %in% sid], d$cong[d$id %in% sid]))
