suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) zap_labels(read_dta(file.path(D,f))))
for (i in 1:3) { cat("==", fs[i], "\n"); print(tapply(L[[i]]$totalcont, L[[i]]$cong, summary))
  x <- L[[i]]$totalcont; cat("share multiple of 50:", mean(x %% 50 == 0, na.rm=TRUE), " non-integer:", mean(x != round(x), na.rm=TRUE), "\n")
  print(head(sort(unique(x[L[[i]]$cong==115])), 30)); print(head(sort(unique(x[L[[i]]$cong==113])), 30)) }
a <- L[[1]]
a$y <- ifelse(a$vote=="Aye",1,ifelse(a$vote=="No",0,NA))
s <- a %>% filter(!is.na(y)) %>% group_by(id) %>% summarise(n=n(), m=mean(y), ncid=n_distinct(cid), both=max(both))
cat("districts with 2 votes:", sum(s$n==2), " switching:", sum(s$n==2 & s$m==0.5), "\n")
print(table(switch= s$n==2 & s$m==0.5, samecid = s$ncid==1, s$both))
# check cid same within switching
sw <- s$id[s$n==2 & s$m==0.5]
d <- a %>% filter(id %in% sw)
print(summary(d[,c("totalcont","sugcont","ncu","tenure","poverty","bach","medincome","over65","agcom")]))
print(table(d$cong, d$agcom))
print(cor(L[[1]]$totalcont, L[[2]]$totalcont, use="c")); print(cor(L[[1]]$totalcont, L[[3]]$totalcont, use="c"))
for (i in 1:3) print(tapply(L[[i]]$totalcont[L[[i]]$id %in% sw], L[[i]]$cong[L[[i]]$id %in% sw], mean))
print(tapply(a$totalcont > a$sugcont, a$cong, mean, na.rm=TRUE))
print(head(a[a$cong==115, c("name","totalcont","sugcont")], 20))
print(head(L[[2]][L[[2]]$cong==115, c("name","totalcont","sugcont")], 20)); print(head(L[[3]][L[[3]]$cong==115, c("name","totalcont","sugcont")], 20))
