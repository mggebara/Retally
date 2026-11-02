suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-01-a/mount/holman_2022_theresa_may_rally"
g <- read_dta(file.path(D, "global_approval.dta"))
cat("kill_16 x female_pres\n"); print(table(g$kill_16, g$female_pres, useNA="a"))
print(as.data.frame(g[g$kill_16==1 & g$female_pres %in% 1, c("country","qtr","country_code")]))
cat("execrlc labels\n"); print(attr(g$execrlc, "labels"))
cat("dup country-qtr:", sum(duplicated(g[,c("country","qtr")])), " dup code-qtr:", sum(duplicated(g[,c("country_code","qtr")])), "\n")
print(table(tapply(g$country, g$country_code, function(x) x[1])))

d <- read_dta(file.path(D, "did_data.dta"))
cat("did rows", nrow(d), "\n")
for (v in names(d)) { x <- d[[v]]; cat(v, "|", attr(x, "label"), "|", class(x)[1], "| NA:", sum(is.na(x)), "\n"); if (is.numeric(x) && length(unique(x)) < 30) print(table(x, useNA="a")) else if (is.numeric(x)) print(summary(as.numeric(x))) }
cat("labels\n"); for (v in names(d)) { l <- attr(d[[v]], "labels"); if (!is.null(l)) { cat(v, ":\n"); print(l) } }
cat("wave x time\n"); print(table(d$wave, d$time, useNA="a"))
cat("wave x treatment1\n"); print(table(d$wave, d$treatment1, useNA="a"))
cat("wave x treatment2\n"); print(table(d$wave, d$treatment2, useNA="a"))
cat("wave x post_attack\n"); print(table(d$wave, d$post_attack, useNA="a"))
cat("wave x nonmissing likeMayW\n"); print(table(d$wave, !is.na(d$likeMayW)))
cat("wave x nonmissing may_bestpm\n"); print(table(d$wave, !is.na(d$may_bestpm)))
cat("wave x nonmissing bestPMW\n"); print(table(d$wave, !is.na(d$bestPMW)))
cat("bestPMW x may_bestpm\n"); print(table(d$bestPMW, d$may_bestpm, useNA="a"))
cat("ids", length(unique(d$id)), "\n")
cat("treatment1 constant within id? ", all(tapply(d$treatment1, d$id, function(z) length(unique(z[!is.na(z)])) <= 1)), "\n")
cat("treatment2 constant within id? ", all(tapply(d$treatment2, d$id, function(z) length(unique(z[!is.na(z)])) <= 1)), "\n")
b <- read_dta(file.path(D, "BES_data.dta"))
cat("BES names\n"); print(names(b))
for (v in c("white","gender","labour","party_other","income","ideology","ideology2","ideo3","post_attack","may_bestpm")) { x <- b[[v]]; cat(v, "|", attr(x,"label"), "| NA:", sum(is.na(x)), "\n"); if (length(unique(x)) < 30) print(table(x, useNA="a")) else print(summary(as.numeric(x))) }
