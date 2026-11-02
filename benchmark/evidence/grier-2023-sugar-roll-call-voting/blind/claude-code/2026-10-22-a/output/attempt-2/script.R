suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-22-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
s <- data.frame(id=d$id, cid=d$cid, cong=d$cong, sug=d$sugcont, t0=L[[1]]$totalcont, t1=L[[2]]$totalcont, t2=L[[3]]$totalcont)
print(sapply(split(s[,4:7], s$cong), colSums, na.rm=TRUE))
for (a in c("t0","t1","t2","sug")) for (b in c("t0","t1","t2","sug")) if (a<b) cat(a,">=",b, mean(s[[a]]>=s[[b]]-1e-6, na.rm=T), " cor", cor(s[[a]],s[[b]],use="c"), "\n")
print(head(s[order(-s$t0),],15))
print(table(d$vote, d$both, d$cong))
# switching districts
d$y <- ifelse(d$vote=="Aye",1,ifelse(d$vote=="No",0,NA))
w <- d %>% filter(!is.na(y)) %>% group_by(id) %>% summarise(n=n(), m=mean(y), ncid=n_distinct(cid))
cat("districts with 2 votes:", sum(w$n==2), " switching:", sum(w$n==2 & w$m==0.5), "\n")
cat("switching same cid:", sum(w$n==2 & w$m==0.5 & w$ncid==1), "\n")
print(table(w$n))
wi <- d %>% filter(!is.na(y)) %>% group_by(cid) %>% summarise(n=n(), m=mean(y), nid=n_distinct(id))
cat("cids with 2 votes:", sum(wi$n==2), " switching:", sum(wi$n==2 & wi$m==0.5), " multi-id:", sum(wi$nid>1), "\n")
print(table(d$both[d$id %in% w$id[w$n==2 & w$m==0.5]], d$cong[d$id %in% w$id[w$n==2 & w$m==0.5]]))
