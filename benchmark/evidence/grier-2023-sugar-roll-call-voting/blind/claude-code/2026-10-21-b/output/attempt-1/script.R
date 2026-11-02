suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
str(d)
for (v in names(d)) { lab <- attr(d[[v]],"label"); cat(v, ":", if(is.null(lab)) "" else lab, "\n") }
print(summary(as.data.frame(zap_labels(d))))
print(table(d$cong, d$vote, useNA="ifany"))
print(table(d$both, d$cong, useNA="ifany"))
print(head(as.data.frame(d), 10))
for (i in 2:3) { cat("file", fs[i], "\n"); for (v in names(d)) if (!isTRUE(all.equal(zap_labels(L[[i]][[v]]), zap_labels(d[[v]])))) cat("  differs:", v, "\n") }
s <- data.frame(s0=d$sugcont, s1=L[[2]]$sugcont, s2=L[[3]]$sugcont, cong=d$cong)
print(aggregate(cbind(s0,s1,s2)~cong, data=s, FUN=function(x) c(sum=sum(x), mean=mean(x), nz=sum(x>0))))
print(head(s, 20))
print(table(table(d$district)))
print(head(sort(unique(d$district)), 20))
print(class(d$district))
print(table(d$agcom, d$cong))
print(summary(d$medincome)); print(summary(d$tenure)); print(summary(d$ncu))
