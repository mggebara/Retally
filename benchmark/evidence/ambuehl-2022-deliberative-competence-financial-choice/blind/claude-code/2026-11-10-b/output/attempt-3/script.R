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
A$cell <- paste(A$batch, A$treatment)
cat("test1==2 and test2==4 rate by cell\n")
print(do.call(rbind, tapply(seq_len(nrow(A)), A$cell, function(i) round(c(n = length(i), q1 = mean(A$test1[i] == "2"), q2 = mean(A$test2[i] == "4")), 2))))
print(table(A$cell, tolower(substr(A$codeWC, 1, 12)), useNA = "ifany"))
fullkey <- function(d, sc) {
  y <- suppressWarnings(as.numeric(d[[sc]]))
  X <- do.call(cbind, lapply(1:10, function(k) { a <- d[[paste0("test", k)]]; a[is.na(a)] <- "NA"; m <- model.matrix(~ factor(a) - 1); colnames(m) <- paste0("t", k, "_", sub("factor\\(a\\)", "", colnames(m))); m[, -1, drop = FALSE] }))
  f <- lm(y ~ X)
  cf <- coef(f)[-1]; names(cf) <- sub("^X", "", names(cf))
  cat(sc, "R2 =", summary(f)$r.squared, "\n")
  print(round(cf[abs(cf) > 0.2], 2))
}
fullkey(A, "SC0_0")
fullkey(B, "SC0")
# choices
getL <- function(d, exp) {
  out <- list()
  for (k in 1:20) {
    if (exp == "A") { c1 <- paste0("iMPL", k, "_1_", 1:11, ": 1"); c2 <- paste0("iMPL", k, "_2_", 3:12, ": 1") }
    else { c1 <- paste0("iMPL", k, "-1#1_iMPL", k, "-1_", 1:11); c2 <- paste0("iMPL", k, "-2#1_iMPL", k, "-2_", 3:12) }
    m1 <- sapply(c1, function(cc) as.integer(d[[cc]])); m2 <- sapply(c2, function(cc) as.integer(d[[cc]]))
    out[[k]] <- list(m1 = matrix(m1, nrow = nrow(d)), m2 = matrix(m2, nrow = nrow(d)))
  }
  out
}
nchg <- function(m) apply(m, 1, function(r) { r <- r[!is.na(r)]; if (length(r) < 2) 0 else sum(diff(r) != 0) })
rev1 <- function(m) apply(m, 1, function(r) { r <- r[!is.na(r)]; any(diff(r) < 0) })  # future (1) then immediate (0) going down
for (e in c("A", "B")) {
  d <- if (e == "A") A else B
  L <- getL(d, e)
  ch1 <- sapply(L, function(z) nchg(z$m1)); ch2 <- sapply(L, function(z) nchg(z$m2))
  na1 <- sapply(L, function(z) rowSums(is.na(z$m1))); na2 <- sapply(L, function(z) rowSums(is.na(z$m2)))
  rv1 <- sapply(L, function(z) rev1(z$m1)); rv2 <- sapply(L, function(z) rev1(z$m2))
  cat(e, "N =", nrow(d), "\n")
  cat(" any NA list1:", sum(rowSums(na1) > 0), " any NA list2:", sum(rowSums(na2) > 0), " table NA list2 counts:\n"); print(table(rowSums(na2)))
  ms1 <- rowSums(ch1 >= 2) > 0; ms2 <- rowSums(ch2 >= 2) > 0
  cat(" MS list1 only-def:", sum(ms1), " list2:", sum(ms2), " either:", sum(ms1 | ms2), "\n")
  cat(" reversed single switch any:", sum(rowSums(rv1 | rv2) > 0), " either MS or reversed:", sum(ms1 | ms2 | rowSums(rv1 | rv2) > 0), "\n")
  # embedded switch consistency with list-1 future count
  sw <- sapply(1:20, function(k) as.integer(d[[paste0("switch", k)]]))
  fut <- sapply(L, function(z) rowSums(z$m1, na.rm = TRUE))
  cat(" switch == #future in list1:", mean(sw == fut, na.rm = TRUE), " among non-MS:", mean((sw == fut)[!(ms1 | ms2), ], na.rm = TRUE), "\n")
  cat(" non-MS switch distribution:\n"); print(table(sw[!(ms1 | ms2), ]))
  if (e == "A") print(table(A$cell, ms1 | ms2))
  if (e == "B") { print(table(B$treatment, ms1 | ms2)); print(B[B$amt_id == "A3AY0315YWWNXY", "Progress"]); print((ms1 | ms2)[B$amt_id == "A3AY0315YWWNXY"]) }
  if (e == "A") print((ms1 | ms2)[A$amt_id == "A63759KWVJ94F"])
}
