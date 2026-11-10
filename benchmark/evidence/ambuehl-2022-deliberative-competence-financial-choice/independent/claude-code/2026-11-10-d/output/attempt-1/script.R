suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=250)
for (i in 1:8) {
  x <- read_csv(file.path(D, sprintf("expAbatch%d.csv", i)), col_types=cols(.default="c"), show_col_types=FALSE)
  cat("== A", i, nrow(x), ncol(x), "\n")
  if (i %in% c(1,2)) {
    print(as.data.frame(t(x[1:4, c(1:60)])))
    tc <- grep("^test|^iMPL1_|^time1-1|treat|excluded|code|Q117|Q122", names(x))
    print(as.data.frame(t(x[1:4, tc])))
  }
  cat("treatment:"); print(table(x$treatment, useNA="a")); if ("excluded" %in% names(x)) print(table(x$excluded, useNA="a"))
  if ("treat" %in% names(x)) print(table(x$treat, useNA="a"))
}
b <- read_csv(file.path(D, "expBbatch1.csv"), col_types=cols(.default="c"), show_col_types=FALSE)
cat("== B1", nrow(b), ncol(b), "\n"); print(names(b))
print(as.data.frame(t(b[1:3, ])))
b2 <- read_csv(file.path(D, "expBbatch2.csv"), col_types=cols(.default="c"), show_col_types=FALSE)
cat("== B2", nrow(b2), ncol(b2), "\n"); print(setdiff(names(b2), names(b))); print(setdiff(names(b), names(b2)))
