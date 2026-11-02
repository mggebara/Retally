suppressMessages({library(haven); library(dplyr)})
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-10-22-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
for (i in 1:3) print(attr(L[[i]],"label"))
for (v in names(d)) cat(v, ":", attr(d[[v]],"label"), "/", class(d[[v]]), "\n")
print(summary(as.data.frame(zap_labels(d))))
print(table(d$cong, useNA="a")); print(table(d$vote, d$cong, useNA="a")); print(table(d$both, d$cong, useNA="a"))
print(head(as.data.frame(d), 20))
for (i in 2:3) { cat("file", fs[i], "\n"); for (v in names(d)) { if (!isTRUE(all.equal(zap_labels(d[[v]]), zap_labels(L[[i]][[v]])))) cat(" differs:", v, "\n") } }
s <- data.frame(id=d$id, cong=d$cong, base=d$sugcont, it1=L[[2]]$sugcont, it2=L[[3]]$sugcont)
print(summary(s)); print(sapply(split(s[,3:5], s$cong), colSums, na.rm=TRUE))
cat("it1<=base", mean(s$it1<=s$base+1e-6, na.rm=T), " it2<=base", mean(s$it2<=s$base+1e-6, na.rm=T), "\n")
print(head(s[order(-s$base),],30))
print(table(table(d$district)))
print(head(sort(unique(d$district)),20))
