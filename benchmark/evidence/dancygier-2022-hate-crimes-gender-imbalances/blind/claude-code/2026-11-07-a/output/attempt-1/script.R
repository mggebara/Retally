# Exploratory: inspect survey.dta and context.dta (no estimates)
suppressMessages({library(haven); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-07-a/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D, "survey.dta"))
cat("survey dims", dim(s), "\n"); print(names(s))
print(table(s$wave, useNA="ifany"))
s4 <- s[as.numeric(s$wave) == 4, ]
cat("wave4 n", nrow(s4), "\n")
for (v in names(s)) {
  x <- s4[[v]]
  cat("----", v, class(x)[1], "NA:", sum(is.na(x)), "unique:", length(unique(x)), "\n")
  if (length(unique(x)) <= 20) print(table(as_factor(x), useNA="ifany")) else print(summary(as.numeric(x)))
}
cx <- read_dta(file.path(D, "context.dta"))
cat("context dims", dim(cx), "\n"); print(names(cx))
print(table(cx$year, useNA="ifany"))
str(cx[1:3,])
print(summary(as.data.frame(cx)))
cat("unique muni", length(unique(cx$ags_muni)), "\n")
