library(haven); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-c/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D,"survey.dta"))
str(s, give.attr=FALSE, list.len=60)
print(table(s$wave))
s4 <- s[s$wave==4,]
for (v in names(s4)) { x <- s4[[v]]; cat(v, class(x)[1], "NA:", sum(is.na(x)), "uniq:", length(unique(x)), "\n"); if (length(unique(x))<=20) print(table(as_factor(x), useNA="ifany")) }
cc <- read_dta(file.path(D,"context.dta"))
str(cc, give.attr=FALSE, list.len=60)
print(table(cc$year))
print(summary(cc))
