suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-22-a/mount/grier_2023_sugar_roll_call_voting"
d <- read_dta(file.path(D,"SugarReplicate.dta"))
d$y <- as.numeric(d$vote=="Aye")
vars <- c("totalcont","ncu","tenure","poverty","bach","medincome","over65","agcom")
cat("NA counts:\n"); print(colSums(is.na(d[,c(vars,"both","cid","id")])))
cc <- complete.cases(d[,vars])
for (useCC in c(FALSE,TRUE)) {
  dd <- if (useCC) d[cc,] else d
  w <- dd %>% group_by(id) %>% summarise(n=n(), m=mean(y), ncid=n_distinct(cid), b=min(both,na.rm=T))
  cat("CC=",useCC," district switch:", sum(w$m>0 & w$m<1), " same cid:", sum(w$m>0 & w$m<1 & w$ncid==1), " both==1:", sum(w$m>0 & w$m<1 & w$b==1),"\n")
  sw <- w$id[w$m>0 & w$m<1]
  x <- dd %>% filter(id %in% sw) %>% arrange(id,cong) %>% group_by(id) %>% summarise(same=n_distinct(cid)==1, dir=paste(vote,collapse=">"))
  print(table(x$same, x$dir))
}
# both variable meaning
print(table(both=d$both, samecid=ave(d$cid, d$id, FUN=function(z) length(unique(z)))==1 & ave(d$cid,d$id,FUN=length)==2))
w2 <- d %>% filter(both==1) %>% group_by(cid) %>% summarise(n=n(), m=mean(y))
cat("both==1 cids:", nrow(w2), " n2:", sum(w2$n==2), " switching:", sum(w2$n==2 & w2$m==0.5), "\n")
print(d %>% filter(vote %in% c("Not Voting","No Vote")) %>% select(cong,cid,name,id,vote,both) %>% as.data.frame())
