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
A$done <- !is.na(A$test1) & A$test1 != ""
Ad <- A[A$done, ]
Ad$cell <- paste(Ad$batch, Ad$treatment)
print(table(Ad$batch, Ad$treatment))
print(table(Ad$batch, tolower(substr(Ad$`code treat`, 1, 15)), useNA = "ifany"))
# columns whose non-missingness varies across batch x treatment cells
nm <- sapply(Ad, function(v) tapply(!is.na(v) & v != "", Ad$cell, mean))
keep <- apply(nm, 2, function(z) max(z) - min(z) > 0.5)
keep <- keep & !grepl("^iMPL|^time[0-9]|^T[0-9]", colnames(nm))
print(round(t(nm[, keep, drop = FALSE]), 2))
for (v in c("TimeTreat_3", "TimeContro_3")) {
  cat(v, "\n")
  z <- suppressWarnings(as.numeric(Ad[[v]]))
  print(do.call(rbind, tapply(z, Ad$cell, function(q) round(c(n = sum(!is.na(q)), quantile(q, c(0, .05, .1, .25, .5), na.rm = TRUE)), 1))))
}
# scoring key via regression of the Qualtrics score on answer dummies
key <- function(d, sc) {
  y <- suppressWarnings(as.numeric(d[[sc]]))
  for (k in 1:10) {
    a <- d[[paste0("test", k)]]
    codes <- sort(unique(a[!is.na(a)]))
    r <- sapply(codes, function(cd) { x <- as.numeric(!is.na(a) & a == cd); coef(lm(y ~ x))[2] })
    cat(sc, "test", k, ":", paste0(codes, "=", round(r, 2), collapse = " "), "\n")
  }
}
key(Ad, "SC0_0")
B <- bind_rows(rd("expBbatch1.csv", 2), rd("expBbatch2.csv", 2))
B$done <- !is.na(B$test1) & B$test1 != ""
Bd <- B[B$done, ]
key(Bd, "SC0")
cat("B dup ids\n"); dd <- Bd$amt_id[duplicated(Bd$amt_id)]; print(Bd[Bd$amt_id %in% dd, c("amt_id", "treatment", "Finished", "Progress", "StartDate", "batch")])
cat("A dup ids\n"); dd <- Ad$amt_id[duplicated(Ad$amt_id)]; print(Ad[Ad$amt_id %in% dd, c("amt_id", "treatment", "V10", "V8", "batch")])
print(table(Bd$Finished, Bd$treatment))
