library(haven); library(dplyr)
p <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) zap_labels(read_dta(paste0(p,f))))
for (i in 1:3) { x <- L[[i]]; cat(fs[i], "\n"); print(tapply(x$totalcont, x$cong, sum, na.rm=TRUE)); print(tapply(x$totalcont, x$cong, function(z) mean(z>0,na.rm=TRUE))) }
print(cor(cbind(L[[1]]$totalcont, L[[2]]$totalcont, L[[3]]$totalcont, L[[1]]$sugcont)))
d <- L[[1]]
d$aye <- as.integer(d$vote == "Aye")
print(table(table(d$id)))
sw <- d %>% group_by(id) %>% summarise(n=n(), s=sum(aye), ncid=n_distinct(cid))
print(table(n=sw$n, s=sw$s))
swd <- sw$id[sw$n==2 & sw$s==1]
cat("switching districts:", length(swd), "\n")
same <- sw$id[sw$n==2 & sw$s==1 & sw$ncid==1]
cat("same cid switching:", length(same), "\n")
ds <- d[d$id %in% swd,]
print(table(ds$both, ds$cong))
print(table(vote=ds$vote, cong=ds$cong))
# by both
sw2 <- d %>% filter(both==1) %>% group_by(id) %>% summarise(n=n(), s=sum(aye), ncid=n_distinct(cid))
print(table(n=sw2$n, s=sw2$s))
print(summary(ds[,c("totalcont","sugcont","ncu","tenure","poverty","bach","medincome","over65","agcom")]))
