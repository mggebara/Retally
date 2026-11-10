# Retally reproduction: Ambuehl, Bernheim & Lusardi (2022), "Evaluating Deliberative
# Competence: A Simple Method with an Application to Financial Choice".
# Seeded mode: translates doFiles/dataManagementExpA.do, dataManagementExpB.do and the
# relevant parts of analysis.do (Table 4 "test scores", Table 7 "finComp") into R.
set.seed(42)
suppressPackageStartupMessages({
  library(readr); library(dplyr); library(tidyr); library(fixest)
})

ROOT <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/seeded/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice"
RAW  <- file.path(ROOT, "data", "raw")

num <- function(x) suppressWarnings(as.numeric(x))
# Stata equality with missing values: . == . is true, . == number is false
st_eq <- function(a, b) ifelse(is.na(a) & is.na(b), TRUE,
                        ifelse(is.na(a) | is.na(b), FALSE, a == b))
st_is <- function(a, v) !is.na(a) & a == v

# ---------------------------------------------------------------------------
# Switching-point logic of the do-files, for one price list.
# C: matrix (subjects x lines) of choices (0/1, possibly NA).
# Stata: line_left = line unless choice == 1; line_right = line unless choice == 0
# (missing choices keep the line in both).
# ---------------------------------------------------------------------------
switch_stats <- function(C) {
  L <- ncol(C)
  lines <- matrix(rep(seq_len(L), each = nrow(C)), nrow = nrow(C))
  left  <- ifelse(is.na(C) | C != 1, lines, NA)
  right <- ifelse(is.na(C) | C != 0, lines, NA)
  sl <- apply(left, 1, function(r) if (all(is.na(r))) NA_real_ else max(r, na.rm = TRUE))
  sh <- apply(right, 1, function(r) if (all(is.na(r))) NA_real_ else min(r, na.rm = TRUE))
  list(sl = sl, sh = sh)
}

coarse_list <- function(C) {         # first price list, 11 lines
  s <- switch_stats(C); sl <- s$sl; sh <- s$sh
  multi <- 1 - as.numeric(st_eq(sh, 1 + sl))
  multi[st_is(sh, 11) | is.na(sh) | st_is(sl, 1) | is.na(sl)] <- 0
  value <- sh
  value[multi == 1] <- NA
  value[st_is(sh, 1)] <- 0      # mlr == 1: all right selected
  value[st_is(sl, 11)] <- 12    # mll == 11: all left selected
  list(multi = multi, value = 20 - 2 * (value - 1))
}

fine_list <- function(C) {           # second price list, 10 lines
  s <- switch_stats(C); sl <- s$sl; sh <- s$sh
  multi <- 1 - as.numeric(st_eq(sh, 1 + sl))
  multi[(st_is(sh, 1) & is.na(sl)) | (is.na(sh) & st_is(sl, 10))] <- 0
  value <- sl
  value[multi == 1] <- NA
  value[st_is(sh, 1)] <- 0
  value[st_is(sl, 10)] <- 10
  vf <- 1.8 - 0.2 * value
  vf[!is.na(vf) & vf < 0] <- 0
  list(multi = multi, value = vf)
}

# Build the subject x task valuations and multi-switch flag.
# coarse_name(i, k), fine_name(i, k): column names of task i, line k.
build_values <- function(d, coarse_name, fine_name) {
  n <- nrow(d)
  vals <- matrix(NA_real_, n, 20)
  fine_multi <- matrix(0, n, 20)
  sum1 <- numeric(n); sum2 <- numeric(n)
  for (i in 1:20) {
    Cc <- sapply(1:11, function(k) num(d[[coarse_name(i, k)]]))
    Cf <- sapply(1:10, function(k) num(d[[fine_name(i, k + 2)]]))
    if (n == 1) { Cc <- matrix(Cc, 1); Cf <- matrix(Cf, 1) }
    cl <- coarse_list(Cc); fl <- fine_list(Cf)
    sum1 <- sum1 + cl$multi
    sum2 <- sum2 + fl$multi
    fine_multi[, i] <- fl$multi
    vals[, i] <- cl$value + fl$value
  }
  # merge 1:1 keeps the master's (fine list) multi_switch_impl* variables;
  # multi = 1 if any of them is 1 or if sum_multi_switch_1 == 1 or sum_multi_switch_2 == 1
  multi <- as.numeric(rowSums(fine_multi == 1) > 0 | sum1 == 1 | sum2 == 1)
  list(vals = vals, multi = multi)
}

# Reshape to task pairs (one row per subject x pair) as in the do-files.
make_pairs <- function(ids, vals) {
  long <- data.frame(id = rep(ids, times = 20), tr_old = rep(1:20, each = length(ids)),
                     value = as.vector(vals))
  long <- long %>% mutate(
    framed = as.integer(tr_old > 10),
    delay = ifelse((tr_old >= 6 & tr_old <= 10) | tr_old %in% c(11, 13, 15, 17, 19), 36, 72),
    amount = case_when(tr_old %in% c(2, 7, 14, 13) ~ 18, tr_old %in% c(3, 8, 16, 15) ~ 16,
                       tr_old %in% c(4, 9, 18, 17) ~ 14, tr_old %in% c(5, 10, 20, 19) ~ 12,
                       TRUE ~ 20))
  map <- c(`6` = 1, `1` = 2, `7` = 3, `2` = 4, `8` = 5, `3` = 6, `9` = 7, `4` = 8, `10` = 9, `5` = 10)
  long$treatment <- ifelse(long$tr_old <= 10, map[as.character(long$tr_old)], long$tr_old - 10)
  prec <- c(20.40, 20.47, 18.47, 18.73, 16.29, 16.80, 14.37, 15.16, 11.58, 11.83)
  long$amount_precise <- prec[long$treatment]
  w <- long %>% select(id, treatment, delay, amount, amount_precise, framed, value) %>%
    pivot_wider(names_from = framed, values_from = value, names_prefix = "v")
  stopifnot(nrow(w) == 10 * length(ids))
  w %>% rename(v_unframed = v0, v_framed = v1) %>%
    mutate(v_framed = v_framed + 0.1, v_unframed = v_unframed + 0.1,
           v_framed = ifelse(!is.na(v_framed) & v_framed <= 0, 0, v_framed),
           v_unframed = ifelse(!is.na(v_unframed) & v_unframed <= 0, 0, v_unframed),
           discount_unframed = v_unframed / amount * 100,
           discount_framed = v_framed / amount_precise * 100,
           absDiff = abs(discount_framed - discount_unframed))
}

score_comp <- function(d) {
  t1 <- st_is(num(d$test1), 2); t2 <- st_is(num(d$test2), 4); t3 <- st_is(num(d$test3), 4)
  t4 <- st_is(num(d$test4), 7); t5 <- st_is(num(d$test5), 6)
  t1 + t2 + t3 + t4 + t5
}

# ============================ Experiment A =================================
A <- list()
for (b in 1:8) {
  d <- read_csv(file.path(RAW, sprintf("expAbatch%d.csv", b)), col_types = cols(.default = "c"),
                name_repair = "minimal", progress = FALSE)
  d <- d[-1, , drop = FALSE]                        # drop Qualtrics description row (id == 1)
  d$id <- b * 1000 + seq_len(nrow(d))
  d$fined <- num(d$treatment)
  if (b %in% c(3, 6, 7, 8)) d$fined <- ifelse(st_is(d$fined, 1), 2, ifelse(st_is(d$fined, 0), 3, d$fined))
  A[[b]] <- d
}
keepA <- function(d) {
  cn <- c("id", "fined", "help_test", "SC0_0", paste0("test", 1:10),
          grep("^iMPL[0-9]+_[12]_[0-9]+: 1$", names(d), value = TRUE))
  d[, cn]
}
A <- bind_rows(lapply(A, keepA))
A <- A[!is.na(num(A$help_test)), ]                 # attrition: drop if help_test == .
bvA <- build_values(A, function(i, k) sprintf("iMPL%d_1_%d: 1", i, k),
                       function(i, k) sprintf("iMPL%d_2_%d: 1", i, k))
subjA <- data.frame(id = A$id, fined = A$fined, multi = bvA$multi,
                    score_compounding = score_comp(A))
subjA$score_indexing <- num(A$SC0_0) - subjA$score_compounding
pairsA <- make_pairs(A$id, bvA$vals) %>% left_join(subjA, by = "id")

# ============================ Experiment B =================================
B <- list()
for (b in 1:2) {
  d <- read_csv(file.path(RAW, sprintf("expBbatch%d.csv", b)), col_types = cols(.default = "c"),
                name_repair = "minimal", progress = FALSE)
  d <- d[-(1:2), , drop = FALSE]                    # drop if _n <= 2 (Qualtrics header lines)
  d$id <- seq_len(nrow(d)) + 1000 * b
  d <- d[-1, , drop = FALSE]                        # drop if _n == 1 (as in dataManagementExpB.do)
  B[[b]] <- d
}
keepB <- function(d) {
  cn <- c("id", "treatment", paste0("test", 1:10),
          grep("^iMPL[0-9]+-[12]#1_iMPL[0-9]+-[12]_[0-9]+$", names(d), value = TRUE))
  d[, cn]
}
B <- bind_rows(lapply(B, keepB))
B$fined <- num(B$treatment)
bvB <- build_values(B, function(i, k) sprintf("iMPL%d-1#1_iMPL%d-1_%d", i, i, k),
                       function(i, k) sprintf("iMPL%d-2#1_iMPL%d-2_%d", i, i, k))
sB <- with(B, st_is(num(test1), 2) + st_is(num(test2), 4) + st_is(num(test3), 4) +
              st_is(num(test4), 7) + st_is(num(test5), 6) + st_is(num(test6), 4) +
              st_is(num(test7), 5) + st_is(num(test8), 5) + st_is(num(test9), 5) +
              st_is(num(test10), 1))
subjB <- data.frame(id = B$id, fined = B$fined, multi = bvB$multi,
                    score_compounding = score_comp(B), test10 = num(B$test10))
subjB$score_indexing <- sB - subjB$score_compounding
subjB <- subjB[!is.na(subjB$test10), ]             # drop if test10 == .
pairsB <- make_pairs(B$id, bvB$vals) %>% inner_join(subjB, by = "id")

# ============================ Analysis =====================================
# keep single switchers only
sA <- subjA %>% filter(multi == 0)
sBk <- subjB %>% filter(multi == 0)
pA <- pairsA %>% filter(multi == 0) %>%
  mutate(Control = as.numeric(fined == 0), Full = as.numeric(fined == 1),
         Rule72 = as.numeric(fined == 2), Rhetoric = as.numeric(fined == 3),
         negAbsDiff = -absDiff, cid = id + 10000)
pB <- pairsB %>% filter(multi == 0) %>%
  mutate(Control = as.numeric(fined == 0), Full = as.numeric(fined == 1),
         negAbsDiff = -absDiff, cid = id + 20000)

cat("ExpA subjects (multi==0) by condition:\n"); print(table(sA$fined))
cat("ExpB subjects (multi==0) by condition:\n"); print(table(sBk$fined))

# Table 4: test scores, one obs per subject, Treatment vs Control, cluster(id)
t4A <- sA %>% filter(fined %in% c(0, 1)) %>% mutate(Full = as.numeric(fined == 1))
t4B <- sBk %>% mutate(Full = as.numeric(fined == 1))
m1 <- feols(score_compounding ~ Full, data = t4A, cluster = ~id)
m2 <- feols(score_compounding ~ Full, data = t4B, cluster = ~id)
m3 <- feols(score_indexing ~ Full, data = t4A, cluster = ~id)
m4 <- feols(score_indexing ~ Full, data = t4B, cluster = ~id)
for (m in list(m1, m2, m3, m4)) print(coeftable(m))

# Table 7: deliberative competence, no constant, cluster(id)
m7a <- feols(negAbsDiff ~ 0 + Control + Full + Rule72 + Rhetoric, data = pA, cluster = ~cid)
m7b <- feols(negAbsDiff ~ 0 + Control + Full, data = pB, cluster = ~cid)
print(coeftable(m7a)); print(coeftable(m7b))
cat("Table 7 col 1 N =", nobs(m7a), " clusters =", length(unique(pA$cid[!is.na(pA$negAbsDiff)])), "\n")
cat("Table 7 col 2 N =", nobs(m7b), "\n")

f <- function(x) formatC(x, digits = 6, format = "f")
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%s\n", f(coef(m1)["Full"])))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%s\n", f(coef(m2)["Full"])))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%s\n", f(coef(m3)["Full"])))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%s\n", f(coef(m4)["Full"])))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", nobs(m2)))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%s\n", f(coef(m7a)["Control"])))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%s\n", f(coef(m7a)["Full"])))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%s\n", f(coef(m7a)["Rule72"])))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%s\n", f(coef(m7a)["Rhetoric"])))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%s\n", f(coef(m7b)["Control"])))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%s\n", f(coef(m7b)["Full"])))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", nobs(m7a)))
