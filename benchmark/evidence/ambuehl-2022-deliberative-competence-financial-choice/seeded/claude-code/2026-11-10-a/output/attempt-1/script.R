suppressPackageStartupMessages({library(readr); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/seeded/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
for (b in 1:8) {
  d <- read_csv(file.path(R, sprintf("expAbatch%d.csv", b)), col_types = cols(.default = "c"))
  cat("A batch", b, "rows", nrow(d), "\n")
  print(as.data.frame(head(d[, c("treatment","SC0_0","help_test","test1","iMPL1_1_1: 1","iMPL1_2_3: 1")], 3)))
  print(table(d$treatment, useNA="ifany"))
  print(table(d$`iMPL1_1_1: 1`, useNA="ifany"))
}
for (b in 1:2) {
  d <- read_csv(file.path(R, sprintf("expBbatch%d.csv", b)), col_types = cols(.default = "c"))
  cat("B batch", b, "rows", nrow(d), "\n")
  print(as.data.frame(head(d[, c("treatment","test10","FinLit3","Q182","iMPL1-1#1_iMPL1-1_1","Finished")], 5)))
  print(table(d$treatment, useNA="ifany"))
  print(table(is.na(d$test10)))
}
