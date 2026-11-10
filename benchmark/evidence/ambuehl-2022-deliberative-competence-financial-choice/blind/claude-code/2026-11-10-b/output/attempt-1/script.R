suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f, skip_rows) {
  x <- read_csv(file.path(D, f), col_types = cols(.default = col_character()), show_col_types = FALSE, progress = FALSE)
  x <- x[-seq_len(skip_rows), ]
  names(x) <- sub("^﻿", "", names(x))
  x$batch <- f
  x
}
A <- bind_rows(lapply(paste0("expAbatch", 1:8, ".csv"), rd, skip_rows = 1))
cat("A rows", nrow(A), "\n")
print(table(A$batch, A$V10, useNA = "ifany"))
A$done <- !is.na(A$test1) & A$test1 != ""
print(table(A$batch, A$done))
print(table(A$treatment, A$done, useNA = "ifany"))
Ad <- A[A$done, ]
print(table(Ad$treatment, tolower(trimws(Ad$`code treat`)), useNA = "ifany"))
for (k in 1:10) { cat("test", k, "\n"); print(table(Ad$treatment, Ad[[paste0("test", k)]], useNA = "ifany")) }
cat("SC0_0\n"); print(table(Ad$treatment, Ad$SC0_0, useNA="ifany"))
cat("T1 values\n"); print(table(Ad$T1)); print(table(Ad$T11))
cat("dup amt_id among done:", sum(duplicated(Ad$amt_id)), "\n")
B1 <- rd("expBbatch1.csv", 2); B2 <- rd("expBbatch2.csv", 2)
cat("B cols identical:", identical(names(B1), names(B2)), "\n")
B <- bind_rows(B1, B2)
cat("B rows", nrow(B), "\n")
print(table(B$batch, B$Finished, useNA="ifany"))
print(table(B$Progress))
B$done <- !is.na(B$test1) & B$test1 != ""
print(table(B$treatment, B$done, useNA="ifany"))
print(table(B$Finished, B$done, useNA="ifany"))
Bd <- B[B$done, ]
for (k in 1:10) { cat("Btest", k, "\n"); print(table(Bd$treatment, Bd[[paste0("test", k)]], useNA = "ifany")) }
cat("SC0\n"); print(table(Bd$treatment, Bd$SC0, useNA="ifany"))
for (v in c("exclude2","exclude3","exclude4","exclude5")) { cat(v, "\n"); print(head(sort(table(Bd[[v]], useNA="ifany"), decreasing=TRUE), 5)) }
print(table(Bd$T1)); print(table(Bd$T11))
cat("dup amt_id B:", sum(duplicated(Bd$amt_id)), " overlap A-B:", length(intersect(Ad$amt_id, Bd$amt_id)), "\n")
cat("A list1 values\n"); print(table(unlist(Ad[, grep("^iMPL[0-9]+_1_", names(Ad))]), useNA="ifany"))
cat("A list2 values\n"); print(table(unlist(Ad[, grep("^iMPL[0-9]+_2_", names(Ad))]), useNA="ifany"))
cat("B list1 values\n"); print(table(unlist(Bd[, grep("^iMPL[0-9]+-1#", names(Bd))]), useNA="ifany"))
cat("B list2 values\n"); print(table(unlist(Bd[, grep("^iMPL[0-9]+-2#", names(Bd))]), useNA="ifany"))
cat("A switch vals\n"); print(table(unlist(Ad[, paste0("switch", 1:20)]), useNA="ifany"))
cat("B switch vals\n"); print(table(unlist(Bd[, paste0("switch", 1:20)]), useNA="ifany"))
