library(haven)
D <- "<repo>/benchmark/.cache/claude-code/dancygier-2022-hate-crimes-gender-imbalances/blind/2026-11-02-c/mount/dancygier_2022_hate_crimes_gender_imbalances"
s <- read_dta(file.path(D, "survey.dta"))
print(table(s$wave))
s4 <- s[as.numeric(s$wave) == 4, ]
cat("n wave4:", nrow(s4), "\n")
for (v in names(s)) {
  x <- s4[[v]]
  cat("----", v, class(x)[1], " NA:", sum(is.na(x)), " nuniq:", length(unique(x)), "\n")
  if (length(unique(x)) <= 20) print(table(as_factor(x), useNA = "ifany")) else print(summary(as.numeric(zap_labels(x))))
}
cx <- read_dta(file.path(D, "context.dta"))
cat("context dims", dim(cx), "\n")
str(cx, give.attr = FALSE)
print(table(cx$year))
print(summary(cx))
