suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"
d <- zap_labels(read_dta(file.path(D,"SugarReplicate.dta")))
d$y <- as.integer(d$vote == "Aye")
cc <- complete.cases(d[,c("y","totalcont","ncu","tenure","poverty","bach","medincome","over65","agcom")])
cat("complete:", sum(cc), "\n")
dd <- d[cc,]
sw <- dd %>% group_by(id) %>% summarise(n=n(), m=mean(y), vv=paste(vote,collapse="/"), sameinc=n_distinct(cid)==1, .groups="drop")
cat("switching districts complete cases:", sum(sw$n==2 & sw$m>0 & sw$m<1), "\n")
print(table(sw$vv[sw$n==2 & sw$m>0 & sw$m<1], sw$sameinc[sw$n==2 & sw$m>0 & sw$m<1]))
# incumbents by cid across congs
ic <- dd %>% group_by(cid) %>% summarise(n=n(), nc=n_distinct(cong), m=mean(y), vv=paste(vote,collapse="/"), b=paste(both,collapse="/"), nid=n_distinct(id), .groups="drop")
print(table(ic$nc)); print(table(ic$vv[ic$nc==2]))
print(table(ic$b[ic$nc==2]))
print(as.data.frame(ic %>% filter(nid==2 | (nc==2 & !grepl("^1/1$", b)))))
x <- dd %>% filter(cid %in% ic$cid[ic$nid==2]) %>% select(cid,name,id,cong,vote,both)
print(as.data.frame(x))
# switching districts with both==1 in both rows
s2 <- dd %>% group_by(id) %>% filter(n()==2) %>% summarise(m=mean(y), b=all(both==1), samecid=n_distinct(cid)==1, .groups="drop")
print(table(switch=s2$m>0&s2$m<1, both=s2$b, samecid=s2$samecid))
