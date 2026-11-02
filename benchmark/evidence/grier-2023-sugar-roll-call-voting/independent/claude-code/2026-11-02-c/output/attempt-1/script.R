library(haven)
p <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"
fs <- c("SugarReplicate.dta","SugarReplicate_iter1.dta","SugarReplicate_iter2.dta")
L <- lapply(fs, function(f) read_dta(paste0(p,f)))
d <- L[[1]]
str(d)
print(summary(as.data.frame(zap_labels(d))))
for (v in names(d)) { lab <- attr(d[[v]],"label"); if(!is.null(lab)) cat(v, ":", lab, "\n") }
print(table(d$cong, d$vote, useNA="ifany"))
print(table(d$both, d$cong, useNA="ifany"))
print(head(as.data.frame(d[order(d$district),c("district","id","cid","name","cong","vote","both","sugcont","tenure","ncu","agcom","party")]),30))
for (i in 2:3) { cat("file",i,"\n"); for (v in names(d)) if(!isTRUE(all.equal(zap_labels(d[[v]]), zap_labels(L[[i]][[v]])))) cat(" differs:", v, "\n") }
print(cor(cbind(L[[1]]$sugcont, L[[2]]$sugcont, L[[3]]$sugcont), use="pair"))
print(sapply(L, function(x) tapply(x$sugcont, x$cong, sum, na.rm=TRUE)))
