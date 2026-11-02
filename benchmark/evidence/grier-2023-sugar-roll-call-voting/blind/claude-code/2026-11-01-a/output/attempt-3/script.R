suppressMessages({library(haven); library(dplyr)})
d <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
a <- read_dta(file.path(d,"SugarReplicate.dta")); b <- read_dta(file.path(d,"SugarReplicate_iter1.dta")); c2 <- read_dta(file.path(d,"SugarReplicate_iter2.dta"))
m <- data.frame(cong=a$cong, id=a$id, cid=a$cid, both=a$both, vote=a$vote, t0=a$totalcont, t1=b$totalcont, t2=c2$totalcont)
for (cg in c(113,115)) { x <- m[m$cong==cg & !is.na(m$t1),]
  cat("cong", cg, " mean t0-t1", mean(x$t0-x$t1), " mean t0-t2", mean(x$t0-x$t2), " share t0==t1", mean(x$t0==x$t1), " share t0==t2", mean(x$t0==x$t2),
      " share t0>=t1", mean(x$t0>=x$t1), " median t0-t1", median(x$t0-x$t1), " median t0-t2", median(x$t0-x$t2), "\n")
  cat("  sum t1+t2-t0 <0 share:", mean(x$t1+x$t2-x$t0 < 0), "\n") }
a$y <- as.integer(a$vote == "Aye")
w <- a %>% arrange(id, cong) %>% group_by(id) %>% summarise(n=n(), pat=paste(vote, collapse="|"), same=n_distinct(cid)==1, both=paste(both,collapse=","), sw = n()==2 & n_distinct(y)==2,
   nav = any(!vote %in% c("Aye","No")), miss=any(is.na(ncu)|is.na(tenure)|is.na(totalcont)|is.na(poverty)|is.na(bach)|is.na(medincome)|is.na(over65)|is.na(agcom)))
print(table(w$pat))
cat("switch districts (aye vs other):", sum(w$sw), " with no missing covars:", sum(w$sw & !w$miss), "\n")
cat("switch, both votes cast Aye/No:", sum(w$sw & !w$nav), "\n")
print(table(sw=w$sw, same=w$same, nav=w$nav))
print(table(w$both[w$sw], w$same[w$sw]))
print(as.data.frame(w[w$sw & (w$miss | w$nav | (w$same & !grepl("1,1", w$both))),]))
print(as.data.frame(w[w$sw & !w$same & grepl("1,1", w$both),]))
cat("same-incumbent switchers: Aye->No", sum(w$sw & w$same & !w$nav & w$pat=="Aye|No"), " No->Aye", sum(w$sw & w$same & !w$nav & w$pat=="No|Aye"), "\n")
cat("diff-incumbent switchers:", sum(w$sw & !w$same), "\n")
