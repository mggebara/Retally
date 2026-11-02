library(haven); library(dplyr)
d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"
a <- read_dta(paste0(d,"SugarReplicate.dta")); b <- read_dta(paste0(d,"SugarReplicate_iter1.dta")); c <- read_dta(paste0(d,"SugarReplicate_iter2.dta"))
str(a); print(summary(a))
for (v in names(a)) cat(v, "label:", attr(a[[v]],"label"), "\n")
for (v in names(a)) { da <- !isTRUE(all.equal(as.numeric(a[[v]]), as.numeric(b[[v]]))); dc <- !isTRUE(all.equal(as.numeric(a[[v]]), as.numeric(c[[v]]))); if (da|dc) cat("differs:", v, da, dc, "\n") }
cat("rows equal order id:", all(a$id==b$id), all(a$id==c$id), "\n")
cat("a>=b share:", mean(a$sugcont>=b$sugcont, na.rm=T), " a>=c:", mean(a$sugcont>=c$sugcont, na.rm=T), " b>=c:", mean(b$sugcont>=c$sugcont,na.rm=T), "\n")
print(tapply(a$sugcont, a$cong, mean, na.rm=T)); print(tapply(b$sugcont, b$cong, mean, na.rm=T)); print(tapply(c$sugcont, c$cong, mean, na.rm=T))
print(table(a$cong, a$vote, useNA="a")); print(table(a$both, a$cong, useNA="a"))
print(head(as.data.frame(a[order(a$district,a$cong),]), 20))
sw <- a %>% filter(!is.na(vote)) %>% group_by(district) %>% summarise(n=n(), nv=n_distinct(vote), nid=n_distinct(cid), b=mean(both))
print(table(sw$n, sw$nv)); print(table(sw$nv, sw$nid)); print(table(sw$nv, sw$b))
print(table(table(a$district)))
