suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) zap_labels(read_dta(file.path(D,f))))
for (i in 1:3) { x <- L[[i]]; cat(fs[i], "\n")
  print(tapply(x$totalcont, x$cong, function(z) c(sum=sum(z,na.rm=T), mean=mean(z,na.rm=T), nonint=sum(z!=round(z),na.rm=T), non100=sum(z %% 100 != 0, na.rm=T), na=sum(is.na(z)))))
  print(tapply(x$sugcont, x$cong, function(z) c(non100=sum(z %% 100 != 0, na.rm=T), nonint=sum(z!=round(z),na.rm=T))))
}
cat("SR==iter2 totalcont:", isTRUE(all.equal(L[[1]]$totalcont, L[[3]]$totalcont)), "\n")
cat("cor matrix totalcont/sugcont\n"); print(cor(cbind(t0=L[[1]]$totalcont, t1=L[[2]]$totalcont, t2=L[[3]]$totalcont, s=L[[1]]$sugcont), use="pair"))
# ordering t1 >= t0 ?
cat("t1>=t0:", mean(L[[2]]$totalcont >= L[[1]]$totalcont, na.rm=T), " t0>=t1:", mean(L[[1]]$totalcont >= L[[2]]$totalcont, na.rm=T), "\n")
cat("s>=t0:", mean(L[[1]]$sugcont >= L[[1]]$totalcont, na.rm=T), " s>=t1:", mean(L[[1]]$sugcont >= L[[2]]$totalcont, na.rm=T), "\n")
d <- L[[1]]
d$y <- as.integer(d$vote == "Aye")
sw <- d %>% group_by(id) %>% summarise(n=n(), ncong=n_distinct(cong), m=mean(y), .groups="drop")
print(table(sw$n)); cat("switching district (both congs, mean in (0,1)):", sum(sw$ncong==2 & sw$m>0 & sw$m<1), "\n")
print(as.data.frame(d %>% filter(id %in% sw$id[sw$n>2]) %>% arrange(id,cong) %>% select(id,cong,name,cid,vote,both,totalcont)) |> head(40))
inc <- d %>% filter(both==1) %>% group_by(cid) %>% summarise(n=n(), m=mean(y), nid=n_distinct(id), vv=paste(vote,collapse="/"), .groups="drop")
print(table(inc$n)); print(table(inc$nid)); cat("switching incumbents:", sum(inc$n==2 & inc$m>0 & inc$m<1), "\n")
print(table(inc$vv))
cat("non-voting rows by both:\n"); print(table(d$vote, d$both, useNA="a"))
print(sum(is.na(d$ncu))); print(d[is.na(d$tenure)|is.na(d$ncu)|is.na(d$both)|is.na(d$sugcont), c("id","cong","name","vote","both","tenure","ncu")])
print(summary(d$medincome)); print(summary(d$poverty)); print(summary(d$bach))
