suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
tc <- sapply(L, function(x) x$totalcont)
colnames(tc) <- c("base","it1","it2")
print(summary(tc))
for (cg in c(113,115)) { s <- d$cong==cg; cat("cong",cg,"sums:", colSums(tc[s,]), " sugcont sum:", sum(d$sugcont[s],na.rm=T), "\n")
  cat(" nonint share:", colMeans(tc[s,] != round(tc[s,])), " sugcont nonint:", mean(d$sugcont[s]!=round(d$sugcont[s]),na.rm=T), "\n") }
cat("base>=it1:", mean(tc[,1]>=tc[,2]), " base>=it2:", mean(tc[,1]>=tc[,3]), " it1>=it2:", mean(tc[,2]>=tc[,3]), "\n")
cat("sugcont>=base:", mean(d$sugcont>=tc[,1],na.rm=T), " cor:", cor(cbind(tc, sug=d$sugcont), use="pair")[4,], "\n")
print(head(cbind(as.data.frame(d[,c("cong","name","id")]), tc, sug=d$sugcont)[tc[,1]!=0,], 25))
# ratios for 115 sugcont/base
s <- d$cong==115 & tc[,1]>0; print(summary(d$sugcont[s]/tc[s,1]))
s <- d$cong==113 & tc[,1]>0; print(summary(d$sugcont[s]/tc[s,1]))
# switching
v <- d %>% filter(vote %in% c("Aye","No")) %>% mutate(aye = as.integer(vote=="Aye"))
cat("rows with aye/no:", nrow(v), "\n")
dd <- v %>% group_by(id) %>% summarise(n=n(), nc=n_distinct(cong), m=mean(aye), ncid=n_distinct(cid))
print(table(dd$n, dd$nc))
sw <- dd %>% filter(nc==2, m==0.5)
cat("switch districts:", nrow(sw), " same cid among them:", sum(sw$ncid==1), "\n")
cat("dup id-cong:", sum(duplicated(v[,c("id","cong")])), "\n")
print(v %>% group_by(id,cong) %>% filter(n()>1) %>% select(id,cong,name,cid,vote,both) %>% as.data.frame())
# incumbents
ii <- v %>% group_by(cid) %>% summarise(n=n(), nc=n_distinct(cong), m=mean(aye), nid=n_distinct(id), both=mean(both))
cat("incumbents both votes:", sum(ii$nc==2), " switched:", sum(ii$nc==2 & ii$m==0.5), "\n")
print(table(both=v$both, cong=v$cong, useNA="a"))
sw2 <- v %>% filter(id %in% sw$id)
cat("NA in covariates among switch rows:\n"); print(colSums(is.na(sw2[,c("totalcont","ncu","tenure","poverty","bach","medincome","over65","agcom")])))
print(table(sw2$agcom, sw2$aye))
