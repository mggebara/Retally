suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/ambuehl_2022_deliberative_competence_financial_choice"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
norm_names <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9_]", "", x)   # Stata insheet drops invalid characters
  make.unique(x, sep = "_dup")
}

read_raw <- function(f) {
  df <- readr::read_csv(f, col_types = readr::cols(.default = readr::col_character()),
                        name_repair = "minimal", progress = FALSE,
                        show_col_types = FALSE)
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  names(df) <- norm_names(names(df))
  df
}

num <- function(x) suppressWarnings(as.numeric(x))

missing_cols <- character(0)
gc_ <- function(df, nm) {
  if (nm %in% names(df)) {
    num(df[[nm]])
  } else {
    missing_cols <<- c(missing_cols, nm)
    rep(NA_real_, nrow(df))
  }
}

row_max_line <- function(mask) {
  n <- nrow(mask); L <- ncol(mask)
  m <- matrix(rep(seq_len(L), each = n), n, L)
  m[!mask] <- NA
  as.numeric(apply(m, 1, function(z) if (all(is.na(z))) NA_real_ else max(z, na.rm = TRUE)))
}
row_min_line <- function(mask) {
  n <- nrow(mask); L <- ncol(mask)
  m <- matrix(rep(seq_len(L), each = n), n, L)
  m[!mask] <- NA
  as.numeric(apply(m, 1, function(z) if (all(is.na(z))) NA_real_ else min(z, na.rm = TRUE)))
}

# Stata equality "sh == 1 + sl" with missing semantics (. == . is true)
stata_eq_next <- function(sh, sl) {
  ifelse(is.na(sh) & is.na(sl), TRUE,
         ifelse(is.na(sh) | is.na(sl), FALSE, sh == sl + 1))
}

# First (coarse, 11-line) price list
coarse_fun <- function(X) {
  leftmask  <- is.na(X) | (X != 1)
  rightmask <- is.na(X) | (X != 0)
  leftmask[is.na(leftmask)] <- TRUE
  rightmask[is.na(rightmask)] <- TRUE
  sl <- row_max_line(leftmask)
  sh <- row_min_line(rightmask)
  multi <- as.numeric(!stata_eq_next(sh, sl))
  multi[is.na(sh) | is.na(sl) | (sh %in% 11) | (sl %in% 1)] <- 0
  value <- sh
  value[multi == 1] <- NA
  value[sh %in% 1] <- 0
  value[sl %in% 11] <- 12
  list(multi = multi, val = 20 - 2 * (value - 1))
}

# Second (fine, 10-line) price list
fine_fun <- function(X) {
  leftmask  <- is.na(X) | (X != 1)
  rightmask <- is.na(X) | (X != 0)
  leftmask[is.na(leftmask)] <- TRUE
  rightmask[is.na(rightmask)] <- TRUE
  sl <- row_max_line(leftmask)
  sh <- row_min_line(rightmask)
  multi <- as.numeric(!stata_eq_next(sh, sl))
  multi[((sh %in% 1) & is.na(sl)) | (is.na(sh) & (sl %in% 10))] <- 0
  value <- sl
  value[multi == 1] <- NA
  value[sh %in% 1] <- 0
  value[sl %in% 10] <- 10
  v <- 1.8 - 0.2 * value
  v[!is.na(v) & v < 0] <- 0
  list(multi = multi, val = v)
}

process_mpl <- function(df, cnames_fun, fnames_fun) {
  n <- nrow(df)
  valmat <- matrix(NA_real_, n, 20)
  mfa <- rep(FALSE, n)
  s1 <- rep(0, n); s2 <- rep(0, n)
  for (i in 1:20) {
    Xc <- do.call(cbind, lapply(cnames_fun(i), function(nm) gc_(df, nm)))
    Xf <- do.call(cbind, lapply(fnames_fun(i), function(nm) gc_(df, nm)))
    Xc <- matrix(Xc, nrow = n); Xf <- matrix(Xf, nrow = n)
    cr <- coarse_fun(Xc)
    fr <- fine_fun(Xf)
    valmat[, i] <- cr$val + fr$val
    s1 <- s1 + cr$multi
    s2 <- s2 + fr$multi
    mfa <- mfa | (fr$multi == 1)   # merge keeps master (fine) multi_switch vars
  }
  multi <- as.integer(mfa | s1 == 1 | s2 == 1)
  list(valmat = valmat, multi = multi)
}

amount_old <- rep(20, 20)
amount_old[c(2, 7, 14, 13)] <- 18
amount_old[c(3, 8, 16, 15)] <- 16
amount_old[c(4, 9, 18, 17)] <- 14
amount_old[c(5, 10, 20, 19)] <- 12
delay_old <- rep(72, 20)
delay_old[6:10] <- 36
delay_old[c(11, 13, 15, 17, 19)] <- 36
uidx <- c(6, 1, 7, 2, 8, 3, 9, 4, 10, 5)   # unframed old index for new treatment 1..10
amount_precise_new <- c(20.40, 20.47, 18.47, 18.73, 16.29, 16.80, 14.37, 15.16, 11.58, 11.83)

make_long <- function(ids, valmat) {
  out <- lapply(1:10, function(t) {
    data.frame(id = ids, treatment = t,
               delay = delay_old[uidx[t]],
               amount = amount_old[uidx[t]],
               amount_precise = amount_precise_new[t],
               v_unframed = valmat[, uidx[t]],
               v_framed = valmat[, 10 + t],
               stringsAsFactors = FALSE)
  })
  d <- do.call(rbind, out)
  d$v_unframed <- d$v_unframed + 0.1
  d$v_framed <- d$v_framed + 0.1
  d$v_unframed[!is.na(d$v_unframed) & d$v_unframed <= 0] <- 0
  d$v_framed[!is.na(d$v_framed) & d$v_framed <= 0] <- 0
  d$discount_unframed <- d$v_unframed / d$amount * 100
  d$discount_framed <- d$v_framed / d$amount_precise * 100
  d$absDiff <- abs(d$discount_framed - d$discount_unframed)
  d$negAbsDiff <- -d$absDiff
  d
}

# ---------------------------------------------------------------------------
# Experiment A
# ---------------------------------------------------------------------------
subjA_list <- list(); valA_list <- list()
for (b in 1:8) {
  df <- read_raw(file.path(base, "data", "raw", sprintf("expAbatch%d.csv", b)))
  keep <- rep(TRUE, nrow(df))
  if ("v1" %in% names(df) && any(grepl("^R_", df$v1))) {
    keep <- grepl("^R_", df$v1)
  } else {
    keep[1] <- FALSE
  }
  df <- df[keep, , drop = FALSE]
  df$id_num <- 1000 * b + seq_len(nrow(df))
  fined <- gc_(df, "treatment")
  if (b %in% c(3, 6, 7, 8)) {
    f2 <- fined
    f2[fined %in% 1] <- 2
    f2[fined %in% 0] <- 3
    fined <- f2
  }
  help <- gc_(df, "help_test")
  sel <- !is.na(help)
  df <- df[sel, , drop = FALSE]
  fined <- fined[sel]
  tests <- sapply(1:10, function(k) gc_(df, paste0("test", k)))
  tests <- matrix(tests, nrow = nrow(df))
  score <- gc_(df, "sc0_0")
  t1 <- tests[, 1] %in% 2; t2 <- tests[, 2] %in% 4; t3 <- tests[, 3] %in% 4
  t4 <- tests[, 4] %in% 7; t5 <- tests[, 5] %in% 6
  sc_comp <- t1 + t2 + t3 + t4 + t5
  mp <- process_mpl(df,
                    function(i) sprintf("impl%d_1_%d1", i, 1:11),
                    function(i) sprintf("impl%d_2_%d1", i, 3:12))
  subjA_list[[b]] <- data.frame(id = df$id_num, fined = fined,
                                score_compounding = sc_comp,
                                score_indexing = score - sc_comp,
                                multi = mp$multi, stringsAsFactors = FALSE)
  valA_list[[b]] <- mp$valmat
}
subjA <- do.call(rbind, subjA_list)
valA <- do.call(rbind, valA_list)

if (length(missing_cols) > 0) {
  cat("WARNING: missing columns (first 10):", head(unique(missing_cols), 10), "\n")
}
missing_cols <- character(0)

cat("Exp A subjects (completed):", nrow(subjA), " multi-switchers:", sum(subjA$multi == 1), "\n")
longA <- make_long(subjA$id, valA)
longA <- merge(longA, subjA[, c("id", "fined", "multi")], by = "id")

subjA0 <- subjA[subjA$multi == 0, ]
longA0 <- longA[longA$multi == 0 & longA$fined %in% 0:3, ]
longA0$Control <- as.numeric(longA0$fined == 0)
longA0$Full <- as.numeric(longA0$fined == 1)
longA0$Rule72 <- as.numeric(longA0$fined == 2)
longA0$Rhetoric <- as.numeric(longA0$fined == 3)
cat("Exp A subjects after multi filter:", nrow(subjA0), "\n")
print(table(subjA0$fined, useNA = "ifany"))

# ---------------------------------------------------------------------------
# Experiment B
# ---------------------------------------------------------------------------
subjB_list <- list(); valB_list <- list()
for (b in 1:2) {
  df <- read_raw(file.path(base, "data", "raw", sprintf("expBbatch%d.csv", b)))
  if ("responseid" %in% names(df) && any(grepl("^R_", df$responseid))) {
    df <- df[grepl("^R_", df$responseid), , drop = FALSE]
  } else {
    df <- df[-(1:2), , drop = FALSE]
  }
  df$id_num <- 1000 * b + seq_len(nrow(df))
  fined <- gc_(df, "treatment")
  tests <- sapply(1:10, function(k) gc_(df, paste0("test", k)))
  tests <- matrix(tests, nrow = nrow(df))
  t1 <- tests[, 1] %in% 2; t2 <- tests[, 2] %in% 4; t3 <- tests[, 3] %in% 4
  t4 <- tests[, 4] %in% 7; t5 <- tests[, 5] %in% 6
  s6 <- tests[, 6] %in% 4; s7 <- tests[, 7] %in% 5; s8 <- tests[, 8] %in% 5
  s9 <- tests[, 9] %in% 5; s10 <- tests[, 10] %in% 1
  sc_comp <- t1 + t2 + t3 + t4 + t5
  score <- sc_comp + s6 + s7 + s8 + s9 + s10
  mp <- process_mpl(df,
                    function(i) sprintf("impl%d11_impl%d1_%d", i, i, 1:11),
                    function(i) sprintf("impl%d21_impl%d2_%d", i, i, 3:12))
  sel <- !is.na(tests[, 10])
  subjB_list[[b]] <- data.frame(id = df$id_num, fined = fined,
                                score_compounding = sc_comp,
                                score_indexing = score - sc_comp,
                                multi = mp$multi, stringsAsFactors = FALSE)[sel, ]
  valB_list[[b]] <- mp$valmat[sel, , drop = FALSE]
}
subjB <- do.call(rbind, subjB_list)
valB <- do.call(rbind, valB_list)

if (length(missing_cols) > 0) {
  cat("WARNING: missing columns B (first 10):", head(unique(missing_cols), 10), "\n")
}

cat("Exp B subjects (completed):", nrow(subjB), " multi-switchers:", sum(subjB$multi == 1), "\n")
longB <- make_long(subjB$id, valB)
longB <- merge(longB, subjB[, c("id", "fined", "multi")], by = "id")

subjB0 <- subjB[subjB$multi == 0 & subjB$fined %in% c(0, 1), ]
longB0 <- longB[longB$multi == 0 & longB$fined %in% c(0, 1), ]
longB0$Control <- as.numeric(longB0$fined == 0)
longB0$Full <- as.numeric(longB0$fined == 1)
cat("Exp B subjects after multi filter:", nrow(subjB0), "\n")
print(table(subjB0$fined, useNA = "ifany"))

# ---------------------------------------------------------------------------
# Table 4: test scores
# ---------------------------------------------------------------------------
tA <- subjA0[subjA0$fined %in% c(0, 1), ]
tA$Full <- as.numeric(tA$fined == 1)
tB <- subjB0
tB$Full <- as.numeric(tB$fined == 1)

m1 <- feols(score_compounding ~ Full, data = tA, vcov = "hetero")
m2 <- feols(score_compounding ~ Full, data = tB, vcov = "hetero")
m3 <- feols(score_indexing ~ Full, data = tA, vcov = "hetero")
m4 <- feols(score_indexing ~ Full, data = tB, vcov = "hetero")

# ---------------------------------------------------------------------------
# Table 7: deliberative competence (levels, no constant, clustered by subject)
# ---------------------------------------------------------------------------
m7a <- feols(negAbsDiff ~ 0 + Control + Full + Rule72 + Rhetoric, data = longA0, cluster = ~id)
m7b <- feols(negAbsDiff ~ 0 + Control + Full, data = longB0, cluster = ~id)

print(summary(m7a))
print(summary(m7b))

res <- c(
  test_score_compounding_treatment_minus_control_expA_table4_col1 = unname(coef(m1)["Full"]),
  test_score_compounding_treatment_minus_control_expB_table4_col2 = unname(coef(m2)["Full"]),
  test_score_control_module_treatment_minus_control_expA_table4_col3 = unname(coef(m3)["Full"]),
  test_score_control_module_treatment_minus_control_expB_table4_col4 = unname(coef(m4)["Full"]),
  n_obs_table4_expA_cols1_3 = nobs(m1),
  n_obs_table4_expB_cols2_4 = nobs(m2),
  deliberative_competence_control_expA_table7_col1 = unname(coef(m7a)["Control"]),
  deliberative_competence_treatment_expA_table7_col1 = unname(coef(m7a)["Full"]),
  deliberative_competence_substance_only_expA_table7_col1 = unname(coef(m7a)["Rule72"]),
  deliberative_competence_rhetoric_only_expA_table7_col1 = unname(coef(m7a)["Rhetoric"]),
  deliberative_competence_control_expB_table7_col2 = unname(coef(m7b)["Control"]),
  deliberative_competence_treatment_expB_table7_col2 = unname(coef(m7b)["Full"]),
  n_obs_table7_expA_col1 = nobs(m7a)
)

for (nm in names(res)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm, res[[nm]]))
}
