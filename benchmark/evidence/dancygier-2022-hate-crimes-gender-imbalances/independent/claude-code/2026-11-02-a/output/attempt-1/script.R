suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/independent/2026-11-02-a/mount/dancygier_2022_hate_crimes_gender_imbalances"
cx <- read_dta(file.path(D, "context.dta"))
cat("context dims", dim(cx), "\n"); print(names(cx)); print(table(cx$year, useNA="a"))
str(cx[1:3,])
print(summary(cx$pop_15_44_muni_gendergap_2015))
for (y in sort(unique(cx$year))) { s <- cx[cx$year==y,]; cat(y, "n", nrow(s), "hate mean", mean(s$Hate_all_muni_bin, na.rm=TRUE), "nmuni", length(unique(s$ags_muni)), "\n") }
print(colSums(is.na(cx)))
sv <- read_dta(file.path(D, "survey.dta"))
cat("survey dims", dim(sv), "\n"); print(names(sv)); print(table(sv$wave))
w4 <- sv[sv$wave==4,]
print(colSums(is.na(w4)))
for (v in names(sv)) { x <- w4[[v]]; cat("==", v, class(x), "\n"); if (length(unique(x)) < 25) { print(table(as_factor(x), useNA="a")) } else { print(summary(as.numeric(x))) } }
