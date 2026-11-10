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
    list(m1 = sapply(c1, function(cc) as.integer(d[[cc]])), m2 = sapply(c2, function(cc) as.integer(d[[cc]])),
         s = as.integer(d[[paste0("switch", k)]]))
  })
}
nch <- function(r) sum(diff(r) != 0)
for (e in c("A", "B")) {
  d <- if (e == "A") A else B
  L <- getL(d, e)
  n <- nrow(d)
  res <- matrix(0L, n, 6, dimnames = list(NULL, c("perlist_ge2", "perlist_rev", "comb_ge2", "comb_prefix0_ge2", "comb_rev", "list1rev_or_comb_ge2")))
  for (k in 1:20) {
    z <- L[[k]]
    for (i in 1:n) {
      r1 <- z$m1[i, ]; r2 <- z$m2[i, ]; s <- z$s[i]
      hi <- if (s >= 11) integer(0) else r1[1:(11 - s)]
      lo <- if (s <= 0) integer(0) else r1[(12 - s):11]
      if (s >= 11) hi <- integer(0)
      comb <- c(hi, r2, lo)
      res[i, 1] <- max(res[i, 1], as.integer(nch(r1) >= 2 || nch(r2) >= 2))
      res[i, 2] <- max(res[i, 2], as.integer(any(diff(r1) < 0) || any(diff(r2) < 0)))
      res[i, 3] <- max(res[i, 3], as.integer(nch(comb) >= 2))
      res[i, 4] <- max(res[i, 4], as.integer(nch(c(0L, comb)) >= 2))
      res[i, 5] <- max(res[i, 5], as.integer(any(diff(comb) < 0)))
      res[i, 6] <- max(res[i, 6], as.integer(any(diff(r1) < 0) || nch(comb) >= 2))
    }
  }
  cat("==", e, "n =", n, "\n"); print(colSums(res))
  ids <- d$amt_id[duplicated(d$amt_id)]
  cat("dups:\n"); print(res[d$amt_id %in% ids, ])
  if (e == "B") { cat("excluding Progress<100 dup:\n"); keep <- !(d$amt_id %in% ids & d$Progress != "100"); print(colSums(res[keep, ])) }
}
