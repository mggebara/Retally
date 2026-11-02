suppressMessages({library(haven); library(dplyr)})
d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-01-a/mount/grier_2023_sugar_roll_call_voting"
a <- read_dta(file.path(d,"SugarReplicate.dta")); b <- read_dta(file.path(d,"SugarReplicate_iter1.dta")); c2 <- read_dta(file.path(d,"SugarReplicate_iter2.dta"))
str(as.data.frame(a)); print(summary(as.data.frame(a)))
for (v in names(a)) { lab <- attr(a[[v]],"label"); if(!is.null(lab)) cat(v, ":", lab, "\n") }
print(table(a$cong, a$vote, useNA="a")); print(table(a$both, a$cong, useNA="a"))
cat("identical a vs iter2:", isTRUE(all.equal(as.data.frame(a), as.data.frame(c2))), "\n")
for (v in names(a)) { if (!isTRUE(all.equal(a[[v]], b[[v]]))) cat("a vs iter1 differs:", v, "\n"); if (!isTRUE(all.equal(a[[v]], c2[[v]]))) cat("a vs iter2 differs:", v, "\n") }
cat("same row order id:", all(a$id==b$id, na.rm=T), all(a$id==c2$id, na.rm=T), "\n")
m <- data.frame(a=a$sugcont, b=b$sugcont, c=c2$sugcont, cong=a$cong)
print(summary(m)); cat("a>=b", mean(m$a>=m$b,na.rm=T), " a>=c", mean(m$a>=m$c,na.rm=T), " b>=a", mean(m$b>=m$a,na.rm=T), "\n")
print(head(as.data.frame(a), 10))
print(table(table(a$district)))
print(table(table(a$id)))
