# Reproduction of Ambuehl, Bernheim & Ockenfels-style "Evaluating Deliberative Competence"
# Table 4 (exam-style test scores) and Table 7 col (1)-(2) (deliberative competence levels).
# Translates doFiles/dataManagementExpA.do, dataManagementExpB.do and analysis.do into R.
suppressPackageStartupMessages({
  library(fixest)
})
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/seeded/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"

rd <- function(f) read.csv(file.path(D, f), colClasses = "character", check.names = FALSE,
                           na.strings = character(0), fileEncoding = "UTF-8-BOM")
num <- function(x) suppressWarnings(as.numeric(x))

# Stata-style equality (missing == missing is TRUE; missing never equals a number)
seq_st <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & a == b)
eq0 <- function(a, k) !is.na(a) & a == k

# ---- switching-point logic (identical for both experiments) -----------------
# M: n x L matrix of choices (lines 1..L), possibly NA
coarse_list <- function(M) {
  L <- ncol(M)
  lines <- matrix(rep(seq_len(L), each = nrow(M)), nrow(M))
  left <- ifelse(eq0(M, 1), NA, lines)   # line_left missing if choice == 1
  right <- ifelse(eq0(M, 0), NA, lines)  # line_right missing if choice == 0
  sl <- suppressWarnings(apply(left, 1, function(z) if (all(is.na(z))) NA else max(z, na.rm = TRUE)))
  sh <- suppressWarnings(apply(right, 1, function(z) if (all(is.na(z))) NA else min(z, na.rm = TRUE)))
  multi <- 1 - as.numeric(seq_st(sh, sl + 1))
  multi[eq0(sh, 11) | is.na(sh) | eq0(sl, 1) | is.na(sl)] <- 0
  value <- sh
  value[multi == 1] <- NA
  value[eq0(sh, 1)] <- 0      # mlr == 1: all right selected
  value[eq0(sl, 11)] <- 12    # mll == 11: all left selected
  list(multi = multi, value = 20 - 2 * (value - 1))
}
fine_list <- function(M) {
  L <- ncol(M)
  lines <- matrix(rep(seq_len(L), each = nrow(M)), nrow(M))
  left <- ifelse(eq0(M, 1), NA, lines)
  right <- ifelse(eq0(M, 0), NA, lines)
  sl <- suppressWarnings(apply(left, 1, function(z) if (all(is.na(z))) NA else max(z, na.rm = TRUE)))
  sh <- suppressWarnings(apply(right, 1, function(z) if (all(is.na(z))) NA else min(z, na.rm = TRUE)))
  multi <- 1 - as.numeric(seq_st(sh, sl + 1))
  multi[(eq0(sh, 1) & is.na(sl)) | (is.na(sh) & eq0(sl, 10))] <- 0
  value <- sl
  value[multi == 1] <- NA
  value[eq0(sh, 1)] <- 0
  value[eq0(sl, 10)] <- 10
  vf <- 1.8 - 0.2 * value
  vf[!is.na(vf) & vf < 0] <- 0
  list(multi = multi, value = vf)
}

# Build the subject x (treatment 1..20) valuation matrix plus multi flag
build_values <- function(x, coarse_name, fine_name) {
  n <- nrow(x)
  vals <- matrix(NA_real_, n, 20)
  sum1 <- rep(0, n); sum2 <- rep(0, n); fmulti <- matrix(0, n, 20)
  for (i in 1:20) {
    Mc <- sapply(1:11, function(k) num(x[[coarse_name(i, k)]]))
    Mf <- sapply(3:12, function(k) num(x[[fine_name(i, k)]]))
    if (n == 1) { Mc <- matrix(Mc, 1); Mf <- matrix(Mf, 1) }
    cl <- coarse_list(Mc); fl <- fine_list(Mf)
    sum1 <- sum1 + cl$multi
    sum2 <- sum2 + fl$multi
    fmulti[, i] <- fl$multi
    vals[, i] <- cl$value + fl$value
  }
  # merge keeps the master (fine list) multi_switch_impl* variables
  multi <- as.numeric(rowSums(fmulti == 1) > 0 | sum1 == 1 | sum2 == 1)
  list(vals = vals, multi = multi)
}

# Reshape to subject x task-pair (10 pairs) and compute absDiff
pair_data <- function(subj, vals) {
  tr <- 1:20
  framed <- as.numeric(tr > 10)
  amount <- rep(20, 20)
  amount[tr %in% c(2, 7, 14, 13)] <- 18
  amount[tr %in% c(3, 8, 16, 15)] <- 16
  amount[tr %in% c(4, 9, 18, 17)] <- 14
  amount[tr %in% c(5, 10, 20, 19)] <- 12
  delay <- rep(72, 20)
  delay[tr >= 6 & tr <= 10] <- 36
  delay[tr %in% c(11, 13, 15, 17, 19)] <- 36
  newtr <- tr
  map <- c(`6` = 1, `1` = 2, `7` = 3, `2` = 4, `8` = 5, `3` = 6, `9` = 7, `4` = 8, `10` = 9, `5` = 10)
  newtr[1:10] <- map[as.character(1:10)]
  newtr[framed == 1] <- newtr[framed == 1] - 10
  prec <- c(20.40, 20.47, 18.47, 18.73, 16.29, 16.80, 14.37, 15.16, 11.58, 11.83)
  out <- list()
  for (p in 1:10) {
    iu <- which(framed == 0 & newtr == p); ifr <- which(framed == 1 & newtr == p)
    stopifnot(amount[iu] == amount[ifr], delay[iu] == delay[ifr])
    vu <- vals[, iu] + 0.1; vfr <- vals[, ifr] + 0.1
    vu[!is.na(vu) & vu <= 0] <- 0; vfr[!is.na(vfr) & vfr <= 0] <- 0
    du <- vu / amount[iu] * 100
    dfm <- vfr / prec[p] * 100
    out[[p]] <- data.frame(id = subj$id, treatment = p, delay = delay[iu],
                           absDiff = abs(dfm - du))
  }
  merge(do.call(rbind, out), subj, by = "id")
}

score_cols <- function(x, key) {
  t <- sapply(1:10, function(k) as.numeric(eq0(num(x[[paste0("test", k)]]), key[k])))
  t
}

# ---------------------------- Experiment A -----------------------------------
A_list <- list()
for (b in 1:8) {
  x <- rd(sprintf("expAbatch%d.csv", b))
  x <- x[-1, , drop = FALSE]                 # drop Qualtrics question-text row
  x$id <- seq_len(nrow(x)) + 1000 * b
  fined <- num(x$treatment)
  if (b %in% c(3, 6, 7, 8)) {
    f2 <- fined
    f2[eq0(fined, 1)] <- 2                  # substance only
    f2[eq0(fined, 0)] <- 3                  # rhetoric only
    fined <- f2
  }
  x$fined <- fined
  x <- x[!is.na(num(x$help_test)), , drop = FALSE]   # drop attriters
  bv <- build_values(x,
                     function(i, k) sprintf("iMPL%d_1_%d: 1", i, k),
                     function(i, k) sprintf("iMPL%d_2_%d: 1", i, k))
  t <- score_cols(x, c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3))
  subj <- data.frame(id = x$id, fined = x$fined, multi = bv$multi,
                     score = num(x$SC0_0))
  subj$score_compounding <- rowSums(t[, 1:5])
  subj$score_indexing <- subj$score - subj$score_compounding
  A_list[[b]] <- list(subj = subj, vals = bv$vals)
}
subjA <- do.call(rbind, lapply(A_list, `[[`, "subj"))
valsA <- do.call(rbind, lapply(A_list, `[[`, "vals"))
pA <- pair_data(subjA, valsA)

# ---------------------------- Experiment B -----------------------------------
B_list <- list()
for (b in 1:2) {
  x <- rd(sprintf("expBbatch%d.csv", b))
  x <- x[-(1:2), , drop = FALSE]             # drop the two Qualtrics header rows
  x$id <- seq_len(nrow(x)) + 1000 * b
  x <- x[-1, , drop = FALSE]                 # second "drop if _n == 1" in the do-file
  x$fined <- num(x$treatment)
  s <- score_cols(x, c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1))
  t <- score_cols(x, c(2, 4, 4, 7, 6, 4, 4, 5, 5, 5))
  bv <- build_values(x,
                     function(i, k) sprintf("iMPL%d-1#1_iMPL%d-1_%d", i, i, k),
                     function(i, k) sprintf("iMPL%d-2#1_iMPL%d-2_%d", i, i, k))
  subj <- data.frame(id = x$id, fined = x$fined, multi = bv$multi,
                     score = rowSums(s), test10 = num(x$test10))
  subj$score_compounding <- rowSums(t[, 1:5])
  subj$score_indexing <- subj$score - subj$score_compounding
  keep <- !is.na(subj$test10)                 # drop if test10 == .
  B_list[[b]] <- list(subj = subj[keep, ], vals = bv$vals[keep, , drop = FALSE])
}
subjB <- do.call(rbind, lapply(B_list, `[[`, "subj"))
valsB <- do.call(rbind, lapply(B_list, `[[`, "vals"))
pB <- pair_data(subjB, valsB)

cat("ExpA subjects (completers):", nrow(subjA), " multi==0:", sum(subjA$multi == 0), "\n")
print(table(subjA$fined, subjA$multi, useNA = "ifany"))
cat("ExpB subjects (completers):", nrow(subjB), " multi==0:", sum(subjB$multi == 0), "\n")
print(table(subjB$fined, subjB$multi, useNA = "ifany"))

# keep single switchers only
sA <- subjA[subjA$multi == 0, ]
sB <- subjB[subjB$multi == 0, ]
pA <- pA[pA$multi == 0, ]
pB <- pB[pB$multi == 0, ]

# ---------------------------- Table 4 ----------------------------------------
sA_tc <- sA[sA$fined %in% c(0, 1), ]
sA_tc$Full <- as.numeric(sA_tc$fined == 1)
sB_tc <- sB[sB$fined %in% c(0, 1), ]
sB_tc$Full <- as.numeric(sB_tc$fined == 1)

t4_1 <- feols(score_compounding ~ Full, data = sA_tc, cluster = ~id)
t4_2 <- feols(score_compounding ~ Full, data = sB_tc, cluster = ~id)
t4_3 <- feols(score_indexing ~ Full, data = sA_tc, cluster = ~id)
t4_4 <- feols(score_indexing ~ Full, data = sB_tc, cluster = ~id)
etable(t4_1, t4_2, t4_3, t4_4)

# ---------------------------- Table 7 ----------------------------------------
pA$negAbsDiff <- -pA$absDiff
pB$negAbsDiff <- -pB$absDiff
pA$Control <- as.numeric(eq0(pA$fined, 0)); pA$Full <- as.numeric(eq0(pA$fined, 1))
pA$Rule72 <- as.numeric(eq0(pA$fined, 2)); pA$Rhetoric <- as.numeric(eq0(pA$fined, 3))
pB$Control <- as.numeric(eq0(pB$fined, 0)); pB$Full <- as.numeric(eq0(pB$fined, 1))

t7_1 <- feols(negAbsDiff ~ 0 + Control + Full + Rule72 + Rhetoric, data = pA, cluster = ~id)
t7_2 <- feols(negAbsDiff ~ 0 + Control + Full, data = pB, cluster = ~id)
etable(t7_1, t7_2)
cat("Table 7 col1 subjects:", length(unique(pA$id[!is.na(pA$absDiff)])), "\n")
cat("Table 7 col2 N:", nobs(t7_2), " subjects:", length(unique(pB$id[!is.na(pB$absDiff)])), "\n")

out <- c(
  test_score_compounding_treatment_minus_control_expA_table4_col1 = unname(coef(t4_1)["Full"]),
  test_score_compounding_treatment_minus_control_expB_table4_col2 = unname(coef(t4_2)["Full"]),
  test_score_control_module_treatment_minus_control_expA_table4_col3 = unname(coef(t4_3)["Full"]),
  test_score_control_module_treatment_minus_control_expB_table4_col4 = unname(coef(t4_4)["Full"]),
  n_obs_table4_expA_cols1_3 = nobs(t4_1),
  n_obs_table4_expB_cols2_4 = nobs(t4_2),
  deliberative_competence_control_expA_table7_col1 = unname(coef(t7_1)["Control"]),
  deliberative_competence_treatment_expA_table7_col1 = unname(coef(t7_1)["Full"]),
  deliberative_competence_substance_only_expA_table7_col1 = unname(coef(t7_1)["Rule72"]),
  deliberative_competence_rhetoric_only_expA_table7_col1 = unname(coef(t7_1)["Rhetoric"]),
  deliberative_competence_control_expB_table7_col2 = unname(coef(t7_2)["Control"]),
  deliberative_competence_treatment_expB_table7_col2 = unname(coef(t7_2)["Full"]),
  n_obs_table7_expA_col1 = nobs(t7_1)
)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
