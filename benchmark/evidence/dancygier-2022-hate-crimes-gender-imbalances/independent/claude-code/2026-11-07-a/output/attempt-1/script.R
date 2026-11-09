suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-07-a/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D,"survey.dta"))
str(s, give.attr=FALSE, list.len=100)
print(table(s$wave))
w4 <- s[s$wave==4,]
for (v in names(w4)) { x <- w4[[v]]; cat(v, class(x)[1], "NA:", sum(is.na(x)), " uniq:", length(unique(x)), "\n"); if (length(unique(x))<20) print(table(as_factor(x), useNA="ifany")) }
cc <- complete.cases(w4[,c("hate_violence_means","MateComp.cont","JobComp.cont","LifeSatis.cont")]); cat("cc12", sum(cc), "\n")
c <- read_dta(file.path(D,"context.dta"))
str(c, give.attr=FALSE, list.len=100)
print(table(c$year))
print(summary(c))
