# Ambuehl, Bernheim & Lusardi (2022), "Evaluating Deliberative Competence"
# Independent, blind reproduction of Table 4 (cols 1-4) and Table 7 (cols 1-2) quantities.
set.seed(42)
suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f, skip_rows) {
  x <- suppressMessages(read_csv(file.path(D, f), col_types = cols(.default = col_character()),
                                 show_col_types = FALSE, progress = FALSE))
  x <- x[-seq_len(skip_rows), ]               # Qualtrics label / import-id rows
  names(x) <- sub("^﻿", "", names(x))
  x$batch <- sub("\\.csv$", "", f)
  x
}

## ---------------- Load ----------------
A <- bind_rows(lapply(paste0("expAbatch", 1:8, ".csv"), rd, skip_rows = 1))
B <- bind_rows(rd("expBbatch1.csv", 2), rd("expBbatch2.csv", 2))

# Completed the study = reached and answered the final incentivized test
A <- A[!is.na(A$test1) & A$test1 != "", ]
B <- B[!is.na(B$test1) & B$test1 != "", ]
# Experiment B: one worker ID appears twice; drop the earlier, unfinished record (Progress < 100)
dupB <- B$amt_id[duplicated(B$amt_id)]
B <- B[!(B$amt_id %in% dupB & B$Progress != "100"), ]
cat("Completed: A =", nrow(A), " B =", nrow(B), "\n")

## ---------------- Conditions ----------------
# Experiment A: the embedded `treatment` field only splits the survey flow in two.
# Sessions (batches) 1,2,4,5 ran full Treatment (long compound-interest video, ~665 s) vs Control
# (index-fund video); sessions 3,6,7,8 ran Substance-Only (treatment path, ~265 s video) vs
# Rhetoric-Only (other path, ~505 s video).  Identified from video durations, the slide code words,
# and Q1 (rule-of-72 answer given in the video) correctness.
bA <- as.integer(sub("expAbatch", "", A$batch))
A$cond <- ifelse(bA %in% c(1, 2, 4, 5),
                 ifelse(A$treatment == "1", "Treatment", "Control"),
                 ifelse(A$treatment == "1", "SubstanceOnly", "RhetoricOnly"))
B$cond <- ifelse(B$treatment == "1", "Treatment", "Control")
print(table(A$batch, A$cond))
print(table(B$cond))

## ---------------- Test scores ----------------
ans <- function(d, k) d[[paste0("test", k)]]
# Compound-interest questions (same coding in both experiments; matches the Qualtrics score key):
# test1 10%->7.2 yrs (code 2), test2 double in 4 yrs->18% (4), test3 x4 at 7%->20 yrs (4),
# test4 8% for 4 yrs->36% (7), test5 Paul $500 after 8 yrs at 9%->$250 (6)
keyC <- c("2", "4", "4", "7", "6")
# Control module A (index funds): Franklin -> "Money makes money" (3), professional investors 90% (4),
# Upton Sinclair -> salary quote (2), mutual funds outperformed 50-70% (3), indexing -> market portfolio (3)
keyA <- c("3", "4", "2", "3", "3")
# Control module B (diversification), options in display order (Table C.2):
# GM & Microsoft (4), Coke-Pepsi correlation 0.7 (5), stocks highest return (5), stocks most volatile (5), 1 (1)
keyB <- c("4", "5", "5", "5", "1")
score <- function(d, idx, key) rowSums(sapply(seq_along(idx), function(j) { a <- ans(d, idx[j]); !is.na(a) & a == key[j] }))
A$score_ci <- score(A, 1:5, keyC); A$score_ctl <- score(A, 6:10, keyA)
B$score_ci <- score(B, 1:5, keyC); B$score_ctl <- score(B, 6:10, keyB)

## ---------------- Valuation tasks ----------------
# Task k (iMPLk) is the prospect stored in embedded field Tk (identical for all subjects).
parseT <- function(txt) {
  txt <- tolower(txt)
  if (grepl("pay you \\$", txt) && !grepl("invest", txt)) {
    R <- as.numeric(sub(".*pay you \\$([0-9.]+) in.*", "\\1", txt))
    t <- as.numeric(sub(".* in ([0-9]+) days.*", "\\1", txt))
    return(c(frame = 0, R = R, t = t))
  }
  a <- as.numeric(sub(".*invest \\$([0-9.]+) in.*", "\\1", txt))
  X <- as.numeric(sub(".*with ([0-9.]+)% interest.*", "\\1", txt))
  t <- as.numeric(sub(".*proceeds in ([0-9]+) days.*", "\\1", txt))
  dbl <- X * t / 72
  R <- if (a == 10) 20 else if (a == 4.5) 18 else if (a == 0.9) 14 else if (a == 2 && abs(dbl - 3) < 1e-9) 16 else if (a == 2 && abs(dbl - 2.5) < 1e-9) 12 else NA
  c(frame = 1, R = R, t = t)
}
taskinfo <- function(d) {
  t(sapply(1:20, function(k) { v <- unique(d[[paste0("T", k)]]); stopifnot(length(v) == 1); parseT(v) }))
}
TA <- taskinfo(A); TB <- taskinfo(B)
stopifnot(identical(TA, TB), !anyNA(TA))
print(cbind(task = 1:20, TA))

# List 1: 11 lines, $20 (line 1) down to $0 (line 11). List 2: lines 3..12 = x+1.8 down to x, where
# x = 2*switch - 2 and `switch` = number of future choices in list 1.  Coding: 0 = immediate (left),
# 1 = future reward (right).
build <- function(d, exp) {
  n <- nrow(d)
  V <- matrix(NA_real_, n, 20); MS <- matrix(FALSE, n, 20)
  nch <- function(r) sum(diff(r) != 0)
  for (k in 1:20) {
    if (exp == "A") { c1 <- paste0("iMPL", k, "_1_", 1:11, ": 1"); c2 <- paste0("iMPL", k, "_2_", 3:12, ": 1") }
    else { c1 <- paste0("iMPL", k, "-1#1_iMPL", k, "-1_", 1:11); c2 <- paste0("iMPL", k, "-2#1_iMPL", k, "-2_", 3:12) }
    m1 <- sapply(c1, function(cc) as.integer(d[[cc]])); m2 <- sapply(c2, function(cc) as.integer(d[[cc]]))
    s <- as.integer(d[[paste0("switch", k)]])
    stopifnot(!anyNA(m1), !anyNA(m2), all(s == rowSums(m1)))
    for (i in 1:n) {
      r1 <- m1[i, ]; r2 <- m2[i, ]; si <- s[i]
      hi <- if (si >= 11) integer(0) else r1[seq_len(11 - si)]
      lo <- if (si <= 0) integer(0) else r1[(12 - si):11]
      comb <- c(hi, r2, lo)             # the full iterated price list, ordered by immediate amount
      MS[i, k] <- nch(comb) >= 2
    }
    m_imm <- rowSums(m2 == 0)            # immediate choices in list 2
    V[, k] <- 2 * s - 0.1 - 0.2 * m_imm  # midpoint of the $0.20 interval
  }
  list(V = V, MS = rowSums(MS) > 0)
}
vA <- build(A, "A"); vB <- build(B, "B")
cat("Multiple switchers: A =", sum(vA$MS), "of", nrow(A), "; B =", sum(vB$MS), "of", nrow(B), "\n")

# Deliberative competence per subject x (R, t) pair
dcomp <- function(d, V) {
  out <- list()
  cpx <- which(TA[, "frame"] == 1)
  for (k in cpx) {
    ks <- which(TA[, "frame"] == 0 & TA[, "R"] == TA[k, "R"] & TA[, "t"] == TA[k, "t"])
    stopifnot(length(ks) == 1)
    R <- TA[k, "R"]
    out[[length(out) + 1]] <- data.frame(id = d$ResponseKey, cond = d$cond, R = R, t = TA[k, "t"],
                                         rc = 100 * V[, k] / R, rs = 100 * V[, ks] / R)
  }
  x <- bind_rows(out); x$dm <- -abs(x$rc - x$rs); x
}
A$ResponseKey <- paste0("A", seq_len(nrow(A))); B$ResponseKey <- paste0("B", seq_len(nrow(B)))
Ak <- A[!vA$MS, ]; Bk <- B[!vB$MS, ]
dA <- dcomp(Ak, vA$V[!vA$MS, ]); dB <- dcomp(Bk, vB$V[!vB$MS, ])
cat("Analysis sample: A =", nrow(Ak), " B =", nrow(Bk), " total =", nrow(Ak) + nrow(Bk), "\n")
print(table(Ak$cond)); print(table(Bk$cond))

## ---------------- Table 4 ----------------
t4A <- Ak[Ak$cond %in% c("Treatment", "Control"), ]; t4A$treat <- as.integer(t4A$cond == "Treatment")
Bk$treat <- as.integer(Bk$cond == "Treatment")
m1 <- feols(score_ci ~ treat, data = t4A, vcov = "iid")
m2 <- feols(score_ci ~ treat, data = Bk, vcov = "iid")
m3 <- feols(score_ctl ~ treat, data = t4A, vcov = "iid")
m4 <- feols(score_ctl ~ treat, data = Bk, vcov = "iid")
for (m in list(m1, m2, m3, m4)) print(coeftable(m))

## ---------------- Table 7 ----------------
dA$cond <- factor(dA$cond, levels = c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly"))
dB$cond <- factor(dB$cond, levels = c("Control", "Treatment"))
t7A <- feols(dm ~ 0 + cond, data = dA, cluster = ~id)
t7B <- feols(dm ~ 0 + cond, data = dB, cluster = ~id)
print(coeftable(t7A)); print(coeftable(t7B))
cat("Table 7 obs: A =", nobs(t7A), " B =", nobs(t7B), "\n")

f <- function(x) formatC(x, digits = 10, format = "g")
cA <- coef(t7A); cB <- coef(t7B)
cat("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=", f(coef(m1)["treat"]), "\n", sep = "")
cat("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=", f(coef(m2)["treat"]), "\n", sep = "")
cat("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=", f(coef(m3)["treat"]), "\n", sep = "")
cat("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=", f(coef(m4)["treat"]), "\n", sep = "")
cat("RESULT:n_obs_table4_expA_cols1_3=", nobs(m1), "\n", sep = "")
cat("RESULT:n_obs_table4_expB_cols2_4=", nobs(m2), "\n", sep = "")
cat("RESULT:deliberative_competence_control_expA_table7_col1=", f(cA["condControl"]), "\n", sep = "")
cat("RESULT:deliberative_competence_treatment_expA_table7_col1=", f(cA["condTreatment"]), "\n", sep = "")
cat("RESULT:deliberative_competence_substance_only_expA_table7_col1=", f(cA["condSubstanceOnly"]), "\n", sep = "")
cat("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=", f(cA["condRhetoricOnly"]), "\n", sep = "")
cat("RESULT:deliberative_competence_control_expB_table7_col2=", f(cB["condControl"]), "\n", sep = "")
cat("RESULT:deliberative_competence_treatment_expB_table7_col2=", f(cB["condTreatment"]), "\n", sep = "")
cat("RESULT:n_obs_table7_expA_col1=", nobs(t7A), "\n", sep = "")
