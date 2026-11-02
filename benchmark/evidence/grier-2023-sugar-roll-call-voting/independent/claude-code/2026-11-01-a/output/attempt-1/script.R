suppressMessages({library(haven); library(dplyr)})
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
str(as.data.frame(d))
print(head(as.data.frame(d), 10))
for (v in names(d)) { lab <- attr(d[[v]],"label"); if(!is.null(lab)) cat(v, ":", lab, "\n") }
print(table(d$cong, useNA="a")); print(table(d$vote, d$cong, useNA="a")); print(table(d$both, d$cong, useNA="a"))
print(summary(as.data.frame(d)))
for (i in 2:3) { cat("file", fs[i], "\n"); for (v in names(d)) if (!isTRUE(all.equal(as.vector(L[[1]][[v]]), as.vector(L[[i]][[v]])))) cat(" differs:", v, "\n") }
cat("sugcont summaries by file/cong\n")
for (i in 1:3) print(tapply(L[[i]]$sugcont, L[[i]]$cong, function(x) c(mean=mean(x,na.rm=T), sum=sum(x,na.rm=T), na=sum(is.na(x)))))
