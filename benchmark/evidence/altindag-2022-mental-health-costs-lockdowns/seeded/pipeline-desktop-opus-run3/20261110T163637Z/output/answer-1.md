suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_dir <- "<repo>/.cache/datasets/altindag_2022_mental_health_costs_lockdowns"
df <- haven::read_dta(file.path(data_dir, "ICPSR_183165-V1.1", "konda_data_for_analysis.dta"))
df <- haven::zap_labels(df)
df <- as.data.frame(df)

# keep respondents only
if ("non_response" %in% names(df)) {
  df <- df[!is.na(df$non_response) & df$non_response == 0, ]
}

# ---------------------------------------------------------------
# Running variable / local-linear terms (di1*) and cluster variable
# ---------------------------------------------------------------
if (!("dif" %in% names(df))) {
  # months older than the Dec 1955 threshold (>= 0 means treated)
  df$dif <- (1955 * 12 + 12) - (df$year * 12 + df$month)
}
di1_vars <- grep("^di1", names(df), value = TRUE)
if (length(di1_vars) == 0) {
  df$di1a <- df$dif
  df$di1b <- df$dif * df$before1955
  di1_vars <- c("di1a", "di1b")
}
if (!("modate" %in% names(df))) {
  df$modate <- df$year * 100 + df$month
}

month_vars <- grep("^month_", names(df), value = TRUE)
prov_vars  <- grep("^province_n_", names(df), value = TRUE)

# ---------------------------------------------------------------
# Anderson (2008) / weightave2-style indices, normalized by control group
# ---------------------------------------------------------------
list1 <- c("head_ache", "mal_appetite", "sleeplessness", "scared", "shaking", "nervous",
           "indigestion", "unfocused", "unhappy", "weepy", "unwillingness", "undecisiveness",
           "disrupted", "useless", "uninterest", "worthless", "suicidal", "usually_tired",
           "stomach_discomfort", "quickly_tired")
list2 <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
list3 <- setdiff(list1, list2)

controldummy <- ifelse(!is.na(df$before1955) & df$before1955 == 0, 1, 0)

make_index <- function(vars) {
  Z <- sapply(vars, function(v) {
    x <- as.numeric(df[[v]])
    m <- mean(x[controldummy == 1], na.rm = TRUE)
    s <- sd(x[controldummy == 1], na.rm = TRUE)
    (x - m) / s
  })
  idx <- rowMeans(Z, na.rm = TRUE)
  idx[is.nan(idx)] <- NA
  m <- mean(idx[controldummy == 1], na.rm = TRUE)
  s <- sd(idx[controldummy == 1], na.rm = TRUE)
  idx <- (idx - m) / s
  anymiss <- apply(df[, vars, drop = FALSE], 1, function(r) any(is.na(r)))
  idx[anymiss] <- NA
  idx
}

df$z_depression <- make_index(list1)
df$z_somatic    <- make_index(list2)
df$z_nonsomatic <- make_index(list3)
srq_mat <- as.matrix(df[, list1])
df$sum_srq <- rowSums(srq_mat, na.rm = TRUE)
df$sum_srq[apply(srq_mat, 1, function(r) any(is.na(r)))] <- NA

# ---------------------------------------------------------------
# Regression: y ~ before1955 + di1* + month_* + province_n_* + female
#             | ethnicity + education + survey_taker_id, cluster modate
# ---------------------------------------------------------------
df$ethnicity_f <- factor(df$ethnicity)
df$education_f <- factor(df$education)
df$surveyor_f  <- factor(df$survey_taker_id)

bq <- function(v) paste0("`", v, "`")
rhs <- c("before1955", di1_vars, month_vars, prov_vars, "female")

run_rd <- function(y, bw = 45) {
  sub <- df[!is.na(df$dif) & df$dif >= -bw & df$dif <= bw, ]
  fml <- as.formula(paste0(bq(y), " ~ ", paste(bq(rhs), collapse = " + "),
                           " | ethnicity_f + education_f + surveyor_f"))
  m <- feols(fml, data = sub, cluster = ~modate, fixef.rm = "none", notes = FALSE, warn = FALSE)
  list(b = unname(coef(m)["before1955"]),
       se = unname(sqrt(diag(vcov(m)))["before1955"]),
       n = nobs(m))
}

r_out   <- run_rd("outside_week")
r_curf  <- run_rd("under_curfew")
r_never <- run_rd("never_out")
r_dep   <- run_rd("z_depression")
r_som   <- run_rd("z_somatic")
r_nsom  <- run_rd("z_nonsomatic")
r_sum   <- run_rd("sum_srq")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_curf$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", as.integer(r_out$n)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", as.integer(r_curf$n)))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_dep$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_nsom$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", as.integer(r_dep$n)))
