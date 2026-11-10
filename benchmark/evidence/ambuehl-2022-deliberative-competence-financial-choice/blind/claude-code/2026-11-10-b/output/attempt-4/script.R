suppressPackageStartupMessages({library(readr); library(dplyr)})
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f, skip_rows) {
  x <- suppressMessages(read_csv(file.path(D, f), col_types = cols(.default = col_character()), show_col_types = FALSE, progress = FALSE))
  x <- x[-seq_len(skip_rows), ]
  names(x) <- sub("^﻿", "", names(x))
  x$batch <- f
  x
}
A <- bind_rows(lapply(paste0("expAbatch", 1:8, ".csv"), rd, skip_rows = 1))
A <- A[!is.na(A$test1) & A$test1 != "", ]
B <- bind_rows(rd("expBbatch1.csv", 2), rd("expBbatch2.csv", 2))
B <- B[!is.na(B$test1) & B$test1 != "", ]
getL <- function(d, exp) {
  lapply(1:20, function(k) {
    if (exp == "A") { c1 <- paste0("iMPL", k, "_1_", 1:11, ": 1"); c2 <- paste0("iMPL", k, "_2_", 3:12, ": 1") }
    else { c1 <- paste0("iMPL", k, "-1#1_iMPL", k, "-1_", 1:11); c2 <- paste0("iMPL", k, "-2#1_iMPL", k, "-2_", 3:12) }
    list(m1 = sapply(c1, function(cc) as.integer(d[[cc]])), m2 = sapply(c2, function(cc) as.integer(d[[cc]])))
  })
}
nchg <- function(m) apply(m, 1, function(r) sum(diff(r) != 0))
rev1 <- function(m) apply(m, 1, function(r) any(diff(r) < 0))
pat <- function(r) paste(r, collapse = "")
for (e in c("A", "B")) {
  d <- if (e == "A") A else B
  L <- getL(d, e)
  c1 <- sapply(L, function(z) nchg(z$m1)); c2 <- sapply(L, function(z) nchg(z$m2))
  r1 <- sapply(L, function(z) rev1(z$m1)); r2 <- sapply(L, function(z) rev1(z$m2))
  cat("==", e, "\n")
  cat("subjects with reversal in list1:", sum(rowSums(r1) > 0), " list2:", sum(rowSums(r2) > 0), "\n")
  cat("subjects with >=2 changes list1:", sum(rowSums(c1 >= 2) > 0), " list2:", sum(rowSums(c2 >= 2) > 0), "\n")
  cat("reversal-only-single-switch lists by task (list1):", colSums(r1 & c1 == 1), "\n")
  cat("reversal-only-single-switch lists by task (list2):", colSums(r2 & c2 == 1), "\n")
  cat("number of reversed lists per flagged subject:\n"); print(table(rowSums(r1) + rowSums(r2))[-1])
  # patterns of single reversed lists
  p1 <- unlist(lapply(L, function(z) apply(z$m1[rev1(z$m1) & nchg(z$m1) == 1, , drop = FALSE], 1, pat)))
  p2 <- unlist(lapply(L, function(z) apply(z$m2[rev1(z$m2) & nchg(z$m2) == 1, , drop = FALSE], 1, pat)))
  cat("single reversed list1 patterns:\n"); print(sort(table(p1), decreasing = TRUE))
  cat("single reversed list2 patterns:\n"); print(sort(table(p2), decreasing = TRUE))
  # list2 inconsistency with list1: immediate chosen at x (last line of list 2) while list1 chose future at x
  inc_low <- sapply(L, function(z) z$m2[, 10] == 0)  # immediate at x
  inc_high <- sapply(L, function(z) z$m2[, 1] == 1)  # future at x+1.8 although list1 immediate at x+2: consistent
  cat("lists with list2 all-immediate (k=0):", sum(sapply(L, function(z) rowSums(z$m2) == 0)), "\n")
  fl <- rowSums(r1 | r2) > 0
  cat("flag by batch:\n"); print(table(d$batch, fl))
  ids <- d$amt_id[duplicated(d$amt_id)]
  cat("dup flags:", fl[d$amt_id %in% ids], "\n")
  # subjects flagged where all reversals are of a specific mild type
  only_l2 <- rowSums(r1) == 0 & rowSums(r2) > 0
  cat("flagged only via list2:", sum(only_l2), " only via list1:", sum(rowSums(r1) > 0 & rowSums(r2) == 0), "\n")
  one_rev <- (rowSums(r1) + rowSums(r2)) == 1
  cat("flagged with exactly one reversed list:", sum(one_rev), "\n")
}
