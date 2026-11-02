suppressMessages({library(haven); library(dplyr)})
d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
a <- read_dta(file.path(d,"SugarReplicate.dta")); b <- read_dta(file.path(d,"SugarReplicate_iter1.dta")); c2 <- read_dta(file.path(d,"SugarReplicate_iter2.dta"))
m <- data.frame(cong=a$cong, id=a$id, cid=a$cid, both=a$both, vote=a$vote, sug=a$sugcont, t0=a$totalcont, t1=b$totalcont, t2=c2$totalcont)
for (cg in c(113,115)) { x <- m[m$cong==cg,]; cat("cong", cg, "\n"); print(summary(x[,c("sug","t0","t1","t2")]))
  cat(" t0>=t1", mean(x$t0>=x$t1), " t0>=t2", mean(x$t0>=x$t2), " t1>=t0", mean(x$t1>=x$t0), " t2>=t0", mean(x$t2>=x$t0), " t1>=t2", mean(x$t1>=x$t2), " t2>=t1", mean(x$t2>=x$t1), "\n")
  cat(" frac non-integer t0/t1/t2/sug:", mean(x$t0 != round(x$t0)), mean(x$t1 != round(x$t1)), mean(x$t2 != round(x$t2)), mean(x$sug != round(x$sug), na.rm=T), "\n")
  cat(" frac multiple of 500 t0/t1/t2/sug:", mean(x$t0 %% 500 == 0), mean(x$t1 %% 500 == 0), mean(x$t2 %% 500 == 0), mean(x$sug %% 500 == 0, na.rm=T), "\n")
  cat(" cor:\n"); print(round(cor(x[,c("sug","t0","t1","t2")], use="pair"),3)) }
print(head(m[m$t0>0,], 15))
# district id structure
cat("id == state_no+district:", all(a$id == a$state_no + a$district), "\n")
# both & cid consistency
p <- m %>% group_by(id) %>% summarise(n=n(), ncid=n_distinct(cid), both=paste(sort(unique(both)),collapse=","), votes=paste(vote,collapse="|"))
print(table(p$n, p$ncid)); print(table(p$both, p$ncid))
print(table(p$votes))
