library(haven); library(dplyr)
d <- "<repo>/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/blind/2026-11-02-c/mount/grier_2023_sugar_roll_call_voting/"
a <- read_dta(paste0(d,"SugarReplicate.dta")); b <- read_dta(paste0(d,"SugarReplicate_iter1.dta")); c <- read_dta(paste0(d,"SugarReplicate_iter2.dta"))
cat("totalcont a>=b:", mean(a$totalcont>=b$totalcont), " a>=c:", mean(a$totalcont>=c$totalcont), " b>=c:", mean(b$totalcont>=c$totalcont), " c>=b:", mean(c$totalcont>=b$totalcont), "\n")
cat("sugcont>=totalcont a:", mean(a$sugcont>=a$totalcont, na.rm=T), "\n")
for (x in list(a,b,c)) { print(tapply(x$totalcont, x$cong, mean)); print(tapply(x$totalcont, x$cong, sum)) }
cat("non-round totalcont (mod 1) a,b,c:", sum(a$totalcont %% 1 != 0), sum(b$totalcont %% 1 != 0), sum(c$totalcont %% 1 != 0), "\n")
cat("non-round sugcont:", sum(a$sugcont %% 1 != 0, na.rm=T), "\n")
print(cor(cbind(a=a$totalcont,b=b$totalcont,c=c$totalcont,s=a$sugcont), use="pairwise"))
cat("id == state_no+district:", all(a$id == a$state_no + a$district), "\n")
v <- a %>% filter(vote %in% c("Aye","No")) %>% mutate(y = as.integer(vote=="Aye"))
g <- v %>% group_by(id) %>% summarise(n=n(), ncong=n_distinct(cong), sw = n_distinct(y)>1, samecid = n_distinct(cid)==1, b=min(both))
print(table(g$n)); print(table(g$sw, g$ncong)); print(with(g[g$sw,], table(samecid, b)))
cat("switching districts:", sum(g$sw), " same-incumbent switchers:", sum(g$sw & g$samecid), "\n")
print(with(v, table(both, cong)))
sw <- g$id[g$sw]
vv <- v %>% filter(id %in% sw)
print(summary(vv[,c("ncu","tenure","poverty","bach","medincome","over65","agcom","totalcont")]))
# 2-obs per district?
print(table(table(vv$id)))
# check agcom variation within switchers
print(vv %>% group_by(id) %>% summarise(a=n_distinct(agcom)) %>% count(a))
print(table(a$vote, a$both))
