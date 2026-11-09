suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/independent/2026-11-07-a/mount/grier_2023_sugar_roll_call_voting"
a <- read_dta(file.path(D,"SugarReplicate.dta")); b <- read_dta(file.path(D,"SugarReplicate_iter1.dta")); c2 <- read_dta(file.path(D,"SugarReplicate_iter2.dta"))
str(a); print(sapply(a, function(x) attr(x,"label")))
print(summary(a))
for (v in names(a)) { cat(v, " iter1 same:", isTRUE(all.equal(zap_labels(a[[v]]),zap_labels(b[[v]]))), " iter2 same:", isTRUE(all.equal(zap_labels(a[[v]]),zap_labels(c2[[v]]))), "\n") }
print(table(a$cong, a$vote, useNA="a")); print(table(a$both, a$cong, useNA="a"))
print(head(as.data.frame(a),10))
print(tapply(a$sugcont, a$cong, summary)); print(tapply(b$sugcont, b$cong, summary)); print(tapply(c2$sugcont, c2$cong, summary))
print(table(a$agcom, a$cong)); print(length(unique(a$id))); print(length(unique(a$district)))
print(table(table(a$id))); print(table(table(a$cid)))
