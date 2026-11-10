suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice"

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
read_raw <- function(f) {
  d <- readr::read_csv(file.path(base, f),
                       col_types = readr::cols(.default = readr::col_character()),
                       name_repair = "minimal", progress = FALSE)
  nm <- tolower(names(d))
  nm <- gsub("[^a-z0-9_]", "", nm)   # mimic Stata insheet name munging (drops BOM, spaces, parens)
  nm[nm == ""] <- paste0("blank", seq_len(sum(nm == "")))
  nm <- make.unique(nm, sep = "_dup")
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  names(d) <- nm
  d
}
num <- function(x) suppressWarnings(as.numeric(x))
getcol <- function(d, nm) {
  if (nm %in% names(d)) num(d[[nm]]) else {
    rep(NA_real_, nrow(d))
  }
}
rowmax_na <- function(M) {
  r <- suppressWarnings(apply(M, 1, function(z) if (all(is.na(z))) NA_real_ else max(z, na.rm = TRUE)))
  as.numeric(r)
}
rowmin_na <- function(M) {
  r <- suppressWarnings(apply(M, 1, function(z) if (all(is.na(z))) NA_real_ else min(z, na.rm = TRUE)))
  as.numeric(r)
}
nn <- function(x) !is.na(x)

# Lines where the left option was chosen (choice != 1) / right option chosen (choice != 0),
# replicating Stata: missing choices count for both.
switch_points <- function(M) {
  n <- nrow(M); L <- ncol(M)
  lines <- matrix(rep(seq_len(L), each = n), nrow = n)
  left <- lines;  left[nn(M) & M == 1] <- NA
  right <- lines; right[nn(M) & M == 0] <- NA
  list(low = rowmax_na(left), high = rowmin_na(right))
}

# First (coarse) price list, 11 lines
coarse_list <- function(M) {
  sp <- switch_points(M); low <- sp$low; high <- sp$high
  multi <- ifelse(is.na(high) | is.na(low) | high == 11 | low == 1, 0,
                  as.numeric(high != low + 1))
  value <- high
  value[multi == 1] <- NA
  value[nn(high) & high == 1] <- 0     # mlr == 1
  value[nn(low) & low == 11] <- 12     # mll == 11
  list(multi = multi, val = 20 - 2 * (value - 1))
}

# Second (fine) price list, 10 lines
fine_list <- function(M) {
  sp <- switch_points(M); low <- sp$low; high <- sp$high
  steq <- (is.na(high) & is.na(low)) | (nn(high) & nn(low) & high == low + 1)
  multi <- 1 - as.numeric(steq)
  multi[(nn(high) & high == 1 & is.na(low)) | (is.na(high) & nn(low) & low == 10)] <- 0
  value <- low
  value[multi == 1] <- NA
  value[nn(high) & high == 1] <- 0     # mlr == 1
  value[nn(low) & low == 10] <- 10     # mll == 10
  v <- 1.8 - 0.2 * value
  v[nn(v) & v < 0] <- 0
  list(multi = multi, val = v)
}

missing_cols <- character(0)
build_matrix <- function(d, cols) {
  miss <- setdiff(cols, names(d))
  if (length(miss) > 0) missing_cols <<- c(missing_cols, miss)
  sapply(cols, function(cn) getcol(d, cn))
}

# Process one batch: returns subject-level values for 20 tasks and multi flag
process_mpl <- function(d, coarse_names, fine_names) {
  n <- nrow(d)
  V <- matrix(NA_real_, n, 20)
  fineMulti <- matrix(0, n, 20)
  sum1 <- rep(0, n)
  for (i in 1:20) {
    Mc <- build_matrix(d, coarse_names(i)); if (n == 1) Mc <- matrix(Mc, nrow = 1)
    Mf <- build_matrix(d, fine_names(i));   if (n == 1) Mf <- matrix(Mf, nrow = 1)
    cl <- coarse_list(Mc)
    fl <- fine_list(Mf)
    V[, i] <- cl$val + fl$val
    fineMulti[, i] <- fl$multi
    sum1 <- sum1 + cl$multi
  }
  # merge precedence: fine-list multi_switch_impl* kept; plus sum_multi_switch_1 == 1
  multi <- as.integer(rowSums(fineMulti == 1) > 0 | sum1 == 1)
  list(V = V, multi = multi)
}

# Mapping to analysis tasks 1..10
unf_idx <- c(6, 1, 7, 2, 8, 3, 9, 4, 10, 5)
fr_idx  <- 11:20
task_amount <- c(20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
task_delay  <- c(36, 72, 36, 72, 36, 72, 36, 72, 36, 72)
task_prec   <- c(20.40, 20.47, 18.47, 18.73, 16.29, 16.80, 14.37, 15.16, 11.58, 11.83)

make_long <- function(subj, V) {
  out <- vector("list", 10)
  for (k in 1:10) {
    vu <- V[, unf_idx[k]] + 0.1
    vf <- V[, fr_idx[k]] + 0.1
    vu[nn(vu) & vu <= 0] <- 0
    vf[nn(vf) & vf <= 0] <- 0
    out[[k]] <- data.frame(id = subj$id, fined = subj$fined, multi = subj$multi,
                           treatment = k, delay = task_delay[k],
                           amount = task_amount[k], amount_precise = task_prec[k],
                           v_unframed = vu, v_framed = vf)
  }
  L <- do.call(rbind, out)
  L$discount_unframed <- L$v_unframed / L$amount * 100
  L$discount_framed   <- L$v_framed / L$amount_precise * 100
  L$negAbsDiff <- -abs(L$discount_framed - L$discount_unframed)
  L
}

score_comp <- function(d) {
  t1 <- getcol(d, "test1"); t2 <- getcol(d, "test2"); t3 <- getcol(d, "test3")
  t4 <- getcol(d, "test4"); t5 <- getcol(d, "test5")
  (nn(t1) & t1 == 2) + (nn(t2) & t2 == 4) + (nn(t3) & t3 == 4) +
    (nn(t4) & t4 == 7) + (nn(t5) & t5 == 6)
}

# ------------------------------------------------------------------
# Experiment A
# ------------------------------------------------------------------
coarseA <- function(i) paste0("impl", i, "_1_", seq(11, 111, 10))
fineA   <- function(i) paste0("impl", i, "_2_", seq(31, 121, 10))

subjA_list <- list(); VA_list <- list()
for (b in 1:8) {
  d <- read_raw(sprintf("data/raw/expAbatch%d.csv", b))
  d <- d[-1, , drop = FALSE]                      # drop Qualtrics label row
  id <- b * 1000 + seq_len(nrow(d))
  fined <- getcol(d, "treatment")
  if (b %in% c(3, 6, 7, 8)) {
    f2 <- fined
    f2[nn(fined) & fined == 1] <- 2               # substance only
    f2[nn(fined) & fined == 0] <- 3               # rhetoric only
    fined <- f2
  }
  help <- getcol(d, "help_test")
  keep <- nn(help)                                # drop attriters
  d <- d[keep, , drop = FALSE]; id <- id[keep]; fined <- fined[keep]
  pr <- process_mpl(d, coarseA, fineA)
  sc <- score_comp(d)
  subjA_list[[b]] <- data.frame(id = id, fined = fined, multi = pr$multi,
                                score_compounding = sc,
                                score_indexing = getcol(d, "sc0_0") - sc)
  VA_list[[b]] <- pr$V
}
subjA <- do.call(rbind, subjA_list)
VA <- do.call(rbind, VA_list)
cat("ExpA subjects completed:", nrow(subjA), " multi:", sum(subjA$multi == 1, na.rm = TRUE), "\n")
print(table(subjA$fined, subjA$multi, useNA = "ifany"))

# ------------------------------------------------------------------
# Experiment B
# ------------------------------------------------------------------
coarseB <- function(i) paste0("impl", i, "11_impl", i, "1_", 1:11)
fineB   <- function(i) paste0("impl", i, "21_impl", i, "2_", 3:12)

readB <- function(b) {
  d <- read_raw(sprintf("data/raw/expBbatch%d.csv", b))
  if ("startdate" %in% names(d)) {
    hdr <- !grepl("^\\s*[0-9]{4}[-/]", d$startdate) & !grepl("^\\s*[0-9]{1,2}/", d$startdate)
    d <- d[!hdr, , drop = FALSE]
  } else {
    d <- d[-(1:2), , drop = FALSE]
  }
  d
}
rawB <- lapply(1:2, readB)
countComplete <- function(dl, extra) {
  sum(sapply(dl, function(d) {
    if (extra) d <- d[-1, , drop = FALSE]
    sum(nn(getcol(d, "test10")))
  }))
}
nNo <- countComplete(rawB, FALSE); nEx <- countComplete(rawB, TRUE)
cat("ExpB completed without extra drop:", nNo, " with extra row drop:", nEx, "\n")
extra_drop <- (nNo != 401 && nEx == 401)

subjB_list <- list(); VB_list <- list()
for (b in 1:2) {
  d <- rawB[[b]]
  if (extra_drop) d <- d[-1, , drop = FALSE]
  id <- b * 1000 + seq_len(nrow(d))
  fined <- getcol(d, "treatment")
  pr <- process_mpl(d, coarseB, fineB)
  sc <- score_comp(d)
  s <- sapply(1:10, function(k) getcol(d, paste0("test", k)))
  if (nrow(d) == 1) s <- matrix(s, nrow = 1)
  keys <- c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1)
  score <- rowSums(sapply(1:10, function(k) as.numeric(nn(s[, k]) & s[, k] == keys[k])))
  keep <- nn(getcol(d, "test10"))
  subjB_list[[b]] <- data.frame(id = id, fined = fined, multi = pr$multi,
                                score_compounding = sc,
                                score_indexing = score - sc)[keep, , drop = FALSE]
  VB_list[[b]] <- pr$V[keep, , drop = FALSE]
}
subjB <- do.call(rbind, subjB_list)
VB <- do.call(rbind, VB_list)
cat("ExpB subjects completed:", nrow(subjB), " multi:", sum(subjB$multi == 1, na.rm = TRUE), "\n")
print(table(subjB$fined, subjB$multi, useNA = "ifany"))

if (length(missing_cols) > 0) {
  cat("WARNING: missing columns (first 10):", head(unique(missing_cols), 10), "\n")
}

# ------------------------------------------------------------------
# Keep single switchers
# ------------------------------------------------------------------
A <- subjA[nn(subjA$multi) & subjA$multi == 0, ]
B <- subjB[nn(subjB$multi) & subjB$multi == 0, ]

# ------------------------------------------------------------------
# Table 4: test scores (one obs per subject)
# ------------------------------------------------------------------
A4 <- A[nn(A$fined) & A$fined %in% c(0, 1), ]
A4$Full <- as.numeric(A4$fined == 1)
B4 <- B[nn(B$fined) & B$fined %in% c(0, 1), ]
B4$Full <- as.numeric(B4$fined == 1)

m1 <- feols(score_compounding ~ Full, data = A4, cluster = ~id)
m2 <- feols(score_compounding ~ Full, data = B4, cluster = ~id)
m3 <- feols(score_indexing ~ Full, data = A4, cluster = ~id)
m4 <- feols(score_indexing ~ Full, data = B4, cluster = ~id)
cat("Table 4 SEs:", se(m1)["Full"], se(m2)["Full"], se(m3)["Full"], se(m4)["Full"], "\n")
cat("Table 4 N:", nobs(m1), nobs(m2), nobs(m3), nobs(m4), "\n")

# ------------------------------------------------------------------
# Table 7: deliberative competence (levels, no constant)
# ------------------------------------------------------------------
LA <- make_long(subjA, VA)
LA <- LA[nn(LA$multi) & LA$multi == 0, ]
LA$Control  <- as.numeric(LA$fined == 0)
LA$Full     <- as.numeric(LA$fined == 1)
LA$Rule72   <- as.numeric(LA$fined == 2)
LA$Rhetoric <- as.numeric(LA$fined == 3)
m7a <- feols(negAbsDiff ~ 0 + Control + Full + Rule72 + Rhetoric, data = LA, cluster = ~id)

LB <- make_long(subjB, VB)
LB <- LB[nn(LB$multi) & LB$multi == 0, ]
LB$Control <- as.numeric(LB$fined == 0)
LB$Full    <- as.numeric(LB$fined == 1)
m7b <- feols(negAbsDiff ~ 0 + Control + Full, data = LB, cluster = ~id)
print(summary(m7a)); print(summary(m7b))

# ------------------------------------------------------------------
# Results
# ------------------------------------------------------------------
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expA_table4_col1=%.6f\n", coef(m1)["Full"]))
cat(sprintf("RESULT:test_score_compounding_treatment_minus_control_expB_table4_col2=%.6f\n", coef(m2)["Full"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expA_table4_col3=%.6f\n", coef(m3)["Full"]))
cat(sprintf("RESULT:test_score_control_module_treatment_minus_control_expB_table4_col4=%.6f\n", coef(m4)["Full"]))
cat(sprintf("RESULT:n_obs_table4_expA_cols1_3=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:n_obs_table4_expB_cols2_4=%d\n", as.integer(nobs(m2))))
cat(sprintf("RESULT:deliberative_competence_control_expA_table7_col1=%.6f\n", coef(m7a)["Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expA_table7_col1=%.6f\n", coef(m7a)["Full"]))
cat(sprintf("RESULT:deliberative_competence_substance_only_expA_table7_col1=%.6f\n", coef(m7a)["Rule72"]))
cat(sprintf("RESULT:deliberative_competence_rhetoric_only_expA_table7_col1=%.6f\n", coef(m7a)["Rhetoric"]))
cat(sprintf("RESULT:deliberative_competence_control_expB_table7_col2=%.6f\n", coef(m7b)["Control"]))
cat(sprintf("RESULT:deliberative_competence_treatment_expB_table7_col2=%.6f\n", coef(m7b)["Full"]))
cat(sprintf("RESULT:n_obs_table7_expA_col1=%d\n", as.integer(nobs(m7a))))
