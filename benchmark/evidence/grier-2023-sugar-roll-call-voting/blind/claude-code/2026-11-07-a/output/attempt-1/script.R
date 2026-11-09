suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
for (v in names(d)) { cat(v, ":", attr(d[[v]],"label"), " class=", class(d[[v]])[1], "\n") }
print(summary(as.data.frame(zap_labels(d))))
print(table(d$cong, d$vote, useNA="a"))
print(table(d$both, d$cong, useNA="a"))
print(head(as.data.frame(d[order(d$district),c("district","cong","name","id","cid","vote","sugcont","totalcont","ncu","tenure","agcom","both","party")]),20))
for (i in 2:3) { cat(fs[i], "\n"); for (v in names(d)) if (!isTRUE(all.equal(as.numeric(zap_labels(d[[v]])), as.numeric(zap_labels(L[[i]][[v]]))))) cat(" differs:", v, "\n") }
for (i in 1:3) print(tapply(L[[i]]$sugcont, L[[i]]$cong, function(x) c(mean=mean(x,na.rm=T), sum=sum(x,na.rm=T), na=sum(is.na(x)))))
cat("district type:\n"); print(head(unique(d$district),20)); print(length(unique(d$district)))
print(table(table(d$district)))
