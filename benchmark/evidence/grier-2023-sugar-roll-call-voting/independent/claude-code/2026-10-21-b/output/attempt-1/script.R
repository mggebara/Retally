suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(file.path(D,f)))
d <- L[[1]]
str(d)
for (v in names(d)) { lab <- attr(d[[v]],"label"); cat(v, ":", if(is.null(lab)) "" else lab, "\n") }
print(summary(as.data.frame(zap_labels(d))))
for (i in 2:3) { cat("== file", fs[i], "\n"); for (v in names(d)) { a <- L[[1]][[v]]; b <- L[[i]][[v]]; if (!isTRUE(all.equal(as.vector(zap_labels(a)), as.vector(zap_labels(b))))) cat("differs:", v, "\n") } }
print(table(d$cong, d$vote, useNA="a"))
print(table(d$both, d$cong, useNA="a"))
print(head(as.data.frame(d), 10))
for (i in 1:3) { cat(fs[i], "\n"); print(tapply(L[[i]]$sugcont, L[[i]]$cong, function(x) c(sum(x,na.rm=T), mean(x,na.rm=T), sum(is.na(x))))) }
print(table(table(d$id)))
print(table(table(d$district)))
print(table(table(d$cid)))
