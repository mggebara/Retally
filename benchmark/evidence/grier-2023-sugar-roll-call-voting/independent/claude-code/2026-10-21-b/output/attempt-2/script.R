suppressMessages({library(haven); library(dplyr)})
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) zap_labels(read_dta(file.path(D,f))))
d <- L[[1]]
d$tc1 <- L[[2]]$totalcont; d$tc2 <- L[[3]]$totalcont
for (cg in c(113,115)) { s <- d[d$cong==cg,]; cat("cong", cg, "sums sugcont/tc0/tc1/tc2:", sum(s$sugcont,na.rm=T), sum(s$totalcont,na.rm=T), sum(s$tc1,na.rm=T), sum(s$tc2,na.rm=T), "\n")
  print(cor(s[,c("sugcont","totalcont","tc1","tc2")], use="pair")) }
print(head(as.data.frame(d[d$sugcont>0, c("cong","id","name","sugcont","totalcont","tc1","tc2")]), 20))
cat("ratio sugcont/totalcont by cong\n"); print(tapply(d$sugcont/d$totalcont, d$cong, function(x) summary(x[is.finite(x)])))
d$y <- as.numeric(d$vote=="Aye")
print(table(d$vote, d$cong))
sw <- d %>% group_by(id) %>% summarise(n=n(), s=sum(y), nb=sum(both,na.rm=T), nn=n_distinct(name), ncid=n_distinct(cid))
print(table(n=sw$n, s=sw$s))
cat("switch districts:", sum(sw$n==2 & sw$s==1), "\n")
swid <- sw$id[sw$n==2 & sw$s==1]
ds <- d[d$id %in% swid,]
print(table(both=ds$both, cong=ds$cong, useNA="a"))
print(table(sw$nn[sw$id %in% swid], sw$ncid[sw$id %in% swid]))
print(table(ds$both, ds$vote))
print(as.data.frame(ds %>% filter(both==1) %>% arrange(id, cong) %>% select(id, cong, name, cid, vote, sugcont, totalcont, tc1, tc2, ncu, tenure, agcom)) %>% head(30))
# missing values in switch sample
print(colSums(is.na(ds)))
# non-Aye non-No in switch sample
print(ds[!ds$vote %in% c("Aye","No"), c("id","cong","name","vote","both")])
