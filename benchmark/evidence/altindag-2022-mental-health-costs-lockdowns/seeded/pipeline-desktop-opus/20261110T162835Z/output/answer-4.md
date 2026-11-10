suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns"
dta_path <- file.path(data_dir, "ICPSR_183165-V1.1", "konda_data_for_analysis.dta")

raw <- haven::read_dta(dta_path)
df <- as.data.frame(raw)

# Convert labelled columns to plain numeric (keep character as is)
for (v in names(df)) {
  x <- df[[v]]
  if (inherits(x, "haven_labelled") || inherits(x, "labelled")) {
    df[[v]] <- as.numeric(haven::zap_labels(x))
  } else if (inherits(x, "haven_labelled_spss")) {
    df[[v]] <- as.numeric(haven::zap_labels(x))
  }
}

# keep if non_response==0
if ("non_response" %in% names(df)) {
  df <- df[!is.na(df$non_response) & df$non_response == 0, , drop = FALSE]
}

# ---------------------------------------------------------------
# Indices following Anderson (2008): items standardized relative to the
# control group (born 1956 or later), combined with inverse-covariance
# (GLS) weights, index re-standardized relative to the control group.
# Index is defined only for respondents answering all SRQ-20 items.
# ---------------------------------------------------------------
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

srq_mat <- as.matrix(df[, list1, drop = FALSE])
complete_srq <- apply(srq_mat, 1, function(r) all(!is.na(r)))
ctrl <- !is.na(df$before1955) & df$before1955 == 0

anderson_index <- function(d, vars) {
  X <- as.matrix(d[, vars, drop = FALSE])
  ok <- complete_srq
  Z <- X
  for (j in seq_along(vars)) {
    mu <- mean(X[ok & ctrl, j], na.rm = TRUE)
    s <- sd(X[ok & ctrl, j], na.rm = TRUE)
    Z[, j] <- (X[, j] - mu) / s
  }
  S <- cov(Z[ok, , drop = FALSE])
  Sinv <- tryCatch(solve(S), error = function(e) MASS::ginv(S))
  w <- rowSums(Sinv)
  idx <- as.numeric(Z %*% w) / sum(w)
  idx[!ok] <- NA
  mu <- mean(idx[ok & ctrl], na.rm = TRUE)
  s <- sd(idx[ok & ctrl], na.rm = TRUE)
  (idx - mu) / s
}

df$z_depression <- anderson_index(df, list1)
df$z_somatic <- anderson_index(df, list2)
df$z_nonsomatic <- anderson_index(df, list3)

df$sum_srq <- rowSums(srq_mat, na.rm = TRUE)
df$sum_srq[!complete_srq] <- NA

# ---------------------------------------------------------------
# Controls: di1* month_* province_n_* i.ethnicity i.education female i.survey_taker_id
# ---------------------------------------------------------------
nm <- names(df)
di1_vars <- grep("^di1", nm, value = TRUE)
if (length(di1_vars) == 0) {
  df$di1_left <- as.numeric(df$dif)
  df$di1_right <- as.numeric(df$dif) * df$before1955
  di1_vars <- c("di1_left", "di1_right")
}
month_vars <- grep("^month_", nm, value = TRUE)
prov_vars <- grep("^province_n_", nm, value = TRUE)

for (v in c(di1_vars, month_vars, prov_vars, "female", "dif")) {
  df[[v]] <- as.numeric(df[[v]])
}

df$eth_f <- factor(df$ethnicity)
df$edu_f <- factor(df$education)
df$surv_f <- factor(df$survey_taker_id)

bt <- function(x) paste0("`", x, "`")
rhs_terms <- c("before1955", bt(di1_vars), bt(month_vars), bt(prov_vars),
               "eth_f", "edu_f", "female", "surv_f")

run_rd <- function(y, bw = 45) {
  sub <- df[!is.na(df$dif) & df$dif >= -bw & df$dif <= bw, , drop = FALSE]
  if ("modate" %in% names(sub)) sub <- sub[!is.na(sub$modate), , drop = FALSE]
  fml <- as.formula(paste(y, "~", paste(rhs_terms, collapse = " + ")))
  m <- tryCatch(
    feols(fml, data = sub, vcov = ~modate, warn = FALSE, notes = FALSE),
    error = function(e) {
      message("Error in ", y, ": ", conditionMessage(e))
      NULL
    }
  )
  if (is.null(m)) return(list(b = NA, se = NA, n = NA))
  b <- unname(coef(m)["before1955"])
  se <- unname(sqrt(diag(vcov(m)))["before1955"])
  list(b = b, se = se, n = nobs(m))
}

r_out <- run_rd("outside_week")
r_cur <- run_rd("under_curfew")
r_nev <- run_rd("never_out")
r_dep <- run_rd("z_depression")
r_som <- run_rd("z_somatic")
r_non <- run_rd("z_nonsomatic")
r_sum <- run_rd("sum_srq")

cat('DEVIATION: Mental health indices built with Anderson (2008) inverse-covariance weighting of control-group-standardized items (control group = born 1956 or later, full analysis sample), index re-standardized to control-group mean 0 / SD 1, and defined only for respondents answering all 20 SRQ items; the paper cites Anderson (2008) but does not spell out weighting, reference group or missing-item rule\n')
cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_nev$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_out$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_cur$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_dep$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_dep$n)))
