# Reproduction of Ambuehl, Bernheim & Lusardi (2022), Table 4 (cols 1-4) and Table 7 (cols 1-2).
# Independent, blind reproduction from the raw Qualtrics exports.
suppressMessages({library(readr); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tests <- paste0("test", 1:10)

## ---------------- Load Experiment A (8 batches, Qualtrics legacy export: 1 label row) ----------------
A <- list()
for (b in 1:8) {
  d <- suppressMessages(read_csv(file.path(D, sprintf("expAbatch%d.csv", b)), col_types = cols(.default = "c"),
                                 show_col_types = FALSE, name_repair = "minimal"))
  names(d)[1] <- "V1"; d <- d[, names(d) != ""]
  d <- d[-1, ]; d$batch <- b
  A[[b]] <- d
}
A <- bind_rows(A)
# completers: reached the valuation tasks and the final test
A <- A[!is.na(A[["iMPL1_1_1: 1"]]) & rowSums(!is.na(A[, tests])) >= 9, ]
# Conditions: batches 1,2,4,5 ran full Treatment (treatment==1) vs index-fund Control (treatment==0);
# batches 3,6,7,8 ran the two partial videos. Identified from the attention-check codes and video timers
# (treatment==1 there = video that teaches the rule of 72 -> Substance-Only; treatment==0 there = Rhetoric-Only).
A$cond <- ifelse(A$batch %in% c(1, 2, 4, 5),
                 ifelse(A$treatment == "1", "Treatment", "Control"),
                 ifelse(A$treatment == "1", "SubstanceOnly", "RhetoricOnly"))
A$id <- paste0("A", seq_len(nrow(A)))

## ---------------- Load Experiment B (2 batches, new Qualtrics export: 2 label rows) ----------------
B <- list()
for (b in 1:2) {
  d <- read_csv(file.path(D, sprintf("expBbatch%d.csv", b)), col_types = cols(.default = "c"), show_col_types = FALSE)
  d <- d[-(1:2), ]; d$batch <- b
  B[[b]] <- d
}
B <- bind_rows(B)
B <- B[!is.na(B[["iMPL1-1#1_iMPL1-1_1"]]) & rowSums(!is.na(B[, tests])) >= 9, ]
# one worker id appears twice among completers in B: keep the first participation only
B <- B[order(B$StartDate), ]
B <- B[!duplicated(B$amt_id), ]
B$cond <- ifelse(B$treatment == "1", "Treatment", "Control")
B$id <- paste0("B", seq_len(nrow(B)))
cat(sprintf("Completers: A rows=%d, B subjects=%d\n", nrow(A), nrow(B)))

## ---------------- Price lists: valuations and monotonicity ----------------
colA <- function(k, l, j) sprintf("iMPL%d_%d_%d: 1", k, l, j)
colB <- function(k, l, j) sprintf("iMPL%d-%d#1_iMPL%d-%d_%d", k, l, k, l, j)
# Task k: 1..10 simply framed, 11..20 complexly framed. (R, delay) from the task texts T1..T20.
taskR <- c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
taskT <- c(rep(72, 5), rep(36, 5), 36, 72, 36, 72, 36, 72, 36, 72, 36, 72)
mpl <- function(d, colf) {
  n <- nrow(d); val <- matrix(NA_real_, n, 20); viol <- matrix(FALSE, n, 20)
  for (k in 1:20) {
    # list 1: lines 1..11 = $20, $18, ..., $0 now vs. the future reward; 1 = future chosen
    L1 <- sapply(1:11, function(j) as.numeric(d[[colf(k, 1, j)]]))
    # list 2: lines 3..12 = x+1.8, x+1.6, ..., x+0, with x = 2*(#future choices in list 1) - 2
    L2 <- sapply(3:12, function(j) as.numeric(d[[colf(k, 2, j)]]))
    n1 <- rowSums(L1); m2 <- rowSums(L2 == 0)
    # interval midpoint: smallest amount chosen over the reward in list 2 is x+2-0.2*m2, the largest rejected is 0.2 lower
    val[, k] <- 2 * n1 - 0.1 - 0.2 * m2
    # monotonicity violated if the subject ever switches back from the future reward to the immediate payment
    viol[, k] <- (rowSums(L1[, -11] == 1 & L1[, -1] == 0) > 0) | (rowSums(L2[, -10] == 1 & L2[, -1] == 0) > 0)
  }
  list(val = val, multi = rowSums(viol) > 0)
}
pA <- mpl(A, colA); pB <- mpl(B, colB)
A$multi <- pA$multi; B$multi <- pB$multi
cat(sprintf("Multiple switchers: A %d of %d, B %d of %d\n", sum(A$multi), nrow(A), sum(B$multi), nrow(B)))

## ---------------- Test scores ----------------
keyC <- c(2, 4, 4, 7, 6)          # compound-interest questions (test1-test5), identical coding in A and B
keyA <- c(3, 4, 2, 3, 3)          # Exp A index-fund questions (test6-test10)
keyB <- c(4, 5, 5, 5, 1)          # Exp B diversification questions (test6-test10), answer order as in Table C.2
score <- function(d, qs, key) rowSums(sapply(seq_along(qs), function(i) as.numeric(d[[qs[i]]]) == key[i]), na.rm = TRUE)
A$score_ci <- score(A, tests[1:5], keyC); A$score_ctrl <- score(A, tests[6:10], keyA)
B$score_ci <- score(B, tests[1:5], keyC); B$score_ctrl <- score(B, tests[6:10], keyB)
# sanity: Qualtrics' own Score-sum in A equals our 10-question score
cat("A: share where own total score == Qualtrics SC0_0:", mean(A$score_ci + A$score_ctrl == as.numeric(A$SC0_0)), "\n")

Ak <- A[!A$multi, ]; Bk <- B[!B$multi, ]
pAk <- pA$val[!A$multi, , drop = FALSE]; pBk <- pB$val[!B$multi, , drop = FALSE]
cat("Retained: A", nrow(Ak), "B", nrow(Bk), "\n"); print(table(Ak$cond)); print(table(Bk$cond))

## ---------------- Table 4 ----------------
A4 <- Ak[Ak$cond %in% c("Control", "Treatment"), ]
A4$treat <- as.numeric(A4$cond == "Treatment"); Bk$treat <- as.numeric(Bk$cond == "Treatment")
m1 <- feols(score_ci ~ treat, data = A4, vcov = "iid")
m2 <- feols(score_ci ~ treat, data = Bk, vcov = "iid")
m3 <- feols(score_ctrl ~ treat, data = A4, vcov = "iid")
m4 <- feols(score_ctrl ~ treat, data = Bk, vcov = "iid")
etable(m1, m2, m3, m4)

## ---------------- Table 7: deliberative competence ----------------
pairs <- data.frame(simple = 1:10, R = taskR[1:10], t = taskT[1:10])
pairs$complex <- sapply(1:10, function(s) which(taskR == pairs$R[s] & taskT == pairs$t[s] & seq_along(taskR) > 10))
dc_long <- function(d, v) {
  out <- lapply(1:10, function(p) data.frame(id = d$id, cond = d$cond, R = pairs$R[p], t = pairs$t[p],
         dc = -abs(v[, pairs$complex[p]] / pairs$R[p] - v[, pairs$simple[p]] / pairs$R[p]) * 100))
  bind_rows(out)
}
LA <- dc_long(Ak, pAk); LB <- dc_long(Bk, pBk)
LA$cond <- factor(LA$cond, levels = c("Control", "Treatment", "SubstanceOnly", "RhetoricOnly"))
LB$cond <- factor(LB$cond, levels = c("Control", "Treatment"))
t7a <- feols(dc ~ 0 + cond, data = LA, cluster = ~id)
t7b <- feols(dc ~ 0 + cond, data = LB, cluster = ~id)
etable(t7a, t7b)

cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.6f\n", coef(m1)["treat"]))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.6f\n", coef(m2)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.6f\n", coef(m3)["treat"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.6f\n", coef(m4)["treat"]))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", nobs(m2)))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.6f\n", coef(t7a)["condControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.6f\n", coef(t7a)["condTreatment"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.6f\n", coef(t7a)["condSubstanceOnly"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.6f\n", coef(t7a)["condRhetoricOnly"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.6f\n", coef(t7b)["condControl"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.6f\n", coef(t7b)["condTreatment"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(t7a)))
