suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns"
df <- haven::read_dta(file.path(data_dir, "ICPSR_183165-V1.1/konda_data_for_analysis.dta"))
df <- as.data.frame(df)

# Strip Stata labels so that all columns are plain numeric/character
for (v in names(df)) {
  if (inherits(df[[v]], "haven_labelled") || inherits(df[[v]], "haven_labelled_spss")) {
    df[[v]] <- as.vector(haven::zap_labels(df[[v]]))
  } else {
    attributes(df[[v]]) <- attributes(df[[v]])[intersect(names(attributes(df[[v]])), c("names", "class", "levels", "tzone"))]
    if (inherits(df[[v]], "haven_labelled")) df[[v]] <- as.vector(df[[v]])
  }
}

# keep if non_response==0
df <- df[!is.na(df$non_response) & df$non_response == 0, ]

# ---------------------------------------------------------------------------
# Anderson (2008) inverse-covariance weighted indices, normalised by control group
# (controldummy = 1 if before1955 == 0).
# As in the standard make_index_gr implementation, respondents with some
# missing items get a weighted average over their non-missing items
# (weights renormalised over the available items), rather than being dropped.
# ---------------------------------------------------------------------------
list1 <- c("head_ache", "mal_appetite", "sleeplessness", "scared", "shaking", "nervous",
           "indigestion", "unfocused", "unhappy", "weepy", "unwillingness", "undecisiveness",
           "disrupted", "useless", "uninterest", "worthless", "suicidal", "usually_tired",
           "stomach_discomfort", "quickly_tired")
list2 <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
list3 <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused",
           "unhappy", "weepy", "unwillingness", "undecisiveness", "disrupted", "useless",
           "uninterest", "worthless", "suicidal", "usually_tired", "quickly_tired")

for (v in list1) df[[v]] <- as.numeric(df[[v]])
df$before1955 <- as.numeric(df$before1955)
ctrl <- !is.na(df$before1955) & df$before1955 == 0

make_index <- function(d, items, ctrl) {
  zmat <- sapply(items, function(v) {
    x <- d[[v]]
    m <- mean(x[ctrl], na.rm = TRUE)
    s <- sd(x[ctrl], na.rm = TRUE)
    (x - m) / s
  })
  if (is.null(dim(zmat))) zmat <- matrix(zmat, ncol = length(items))
  anymiss <- apply(zmat, 1, function(r) any(is.na(r)))
  allmiss <- apply(zmat, 1, function(r) all(is.na(r)))
  # Anderson (2008) GLS weights: row sums of the inverse covariance matrix
  S <- cov(zmat[!anymiss, , drop = FALSE])
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  w <- rowSums(Sinv)
  nonmiss <- !is.na(zmat)
  zfill <- zmat
  zfill[is.na(zfill)] <- 0
  num <- as.vector(zfill %*% w)
  den <- as.vector(nonmiss %*% w)
  avg <- num / den
  avg[allmiss] <- NA
  m2 <- mean(avg[ctrl], na.rm = TRUE)
  s2 <- sd(avg[ctrl], na.rm = TRUE)
  idx <- (avg - m2) / s2
  idx
}

df$z_depression <- make_index(df, list1, ctrl)
df$z_somatic    <- make_index(df, list2, ctrl)
df$z_nonsomatic <- make_index(df, list3, ctrl)

srq_mat <- as.matrix(df[, list1])
df$sum_srq <- rowSums(srq_mat, na.rm = TRUE)
df$sum_srq[apply(srq_mat, 1, function(r) any(is.na(r)))] <- NA

# ---------------------------------------------------------------------------
# Regressors: before1955 di1* month_* province_n_* i.ethnicity i.education female i.survey_taker_id
# ---------------------------------------------------------------------------
di_vars   <- grep("^di1", names(df), value = TRUE)
month_vars <- grep("^month_", names(df), value = TRUE)
prov_vars <- grep("^province_n_", names(df), value = TRUE)

for (v in c(di_vars, month_vars, prov_vars, "female", "dif", "modate")) {
  if (v %in% names(df)) df[[v]] <- suppressWarnings(as.numeric(df[[v]]))
}

df$ethnicity_f <- factor(df$ethnicity)
df$education_f <- factor(df$education)
df$surveyor_f  <- factor(df$survey_taker_id)

bt <- function(x) paste0("`", x, "`")
rhs <- paste(c("before1955", bt(di_vars), bt(month_vars), bt(prov_vars), "female"), collapse = " + ")

run_rd <- function(y, bw) {
  d <- df[!is.na(df$dif) & df$dif >= -bw & df$dif <= bw, ]
  fml <- as.formula(paste0(y, " ~ ", rhs, " | ethnicity_f + education_f + surveyor_f"))
  m <- feols(fml, data = d, cluster = ~modate, fixef.rm = "none", warn = FALSE, notes = FALSE)
  list(b = unname(coef(m)["before1955"]), n = nobs(m))
}

bw <- 45
r_out  <- run_rd("outside_week", bw)
r_cur  <- run_rd("under_curfew", bw)
r_nev  <- run_rd("never_out", bw)
r_dep  <- run_rd("z_depression", bw)
r_som  <- run_rd("z_somatic", bw)
r_non  <- run_rd("z_nonsomatic", bw)
r_srq  <- run_rd("sum_srq", bw)

cat("DEVIATION: Anderson indices average over each respondent's non-missing items (GLS weights renormalised over available items) instead of dropping respondents with any missing item; the paper does not state its missing-item handling\n")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_nev$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_out$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_cur$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_dep$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_srq$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_dep$n)))