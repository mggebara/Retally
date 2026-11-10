# Altindag, Erten & Keskin (2022) - Mental health costs of lockdowns
# Reproduces Table 3 col (3) and Table 4 col (3): RD at the Dec-1955 birth
# cohort threshold, +/-45 month bandwidth, following "1 Tables.do".
set.seed(42)
suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})

path <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d <- zap_labels(read_dta(path))
d <- as.data.frame(d)

# keep if non_response==0
d <- d[!is.na(d$non_response) & d$non_response == 0, ]

list1 <- c("head_ache", "mal_appetite", "sleeplessness", "scared", "shaking", "nervous",
           "indigestion", "unfocused", "unhappy", "weepy", "unwillingness", "undecisiveness",
           "disrupted", "useless", "uninterest", "worthless", "suicidal", "usually_tired",
           "stomach_discomfort", "quickly_tired")
list2 <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
list3 <- setdiff(list1, list2)

ctrl <- !is.na(d$before1955) & d$before1955 == 0   # controldummy == 1

# Anderson (2008) index as in Asher & Novosad's weightave2, normby(controldummy):
# standardize each item by the control-group mean/sd, weight by the row sums of the
# inverse covariance matrix of the standardized items, take the weighted average.
anderson <- function(vars, restd = FALSE, equal = FALSE) {
  Z <- sapply(vars, function(v) {
    x <- d[[v]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  cc <- complete.cases(Z)
  if (equal) {
    w <- rep(1, length(vars))
  } else {
    S <- cov(Z[cc, , drop = FALSE])
    w <- rowSums(solve(S))
  }
  idx <- as.vector(Z %*% w) / sum(w)
  idx[!cc] <- NA                         # replace z = . if any item missing
  if (restd) idx <- (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
  idx
}

d$z_depression <- anderson(list1)
d$z_somatic    <- anderson(list2)
d$z_nonsomatic <- anderson(list3)
d$sum_srq <- rowSums(d[, list1])              # NA if any item missing

# controls: month_* province_n_* i.ethnicity i.education female i.survey_taker_id
mvars <- grep("^month_[0-9]+$", names(d), value = TRUE)
pvars <- grep("^province_n_[0-9]+$", names(d), value = TRUE)
rhs <- paste(c("before1955", "di1", "di1_i", mvars, pvars, "female",
               "i(ethnicity)", "i(education)", "i(survey_taker_id)"), collapse = " + ")

rd <- function(y, bw = 45, data = d) {
  sub <- data[!is.na(data$dif) & data$dif >= -bw & data$dif <= bw, ]
  f <- as.formula(paste(y, "~", rhs))
  m <- feols(f, data = sub, cluster = ~modate, notes = FALSE)
  list(b = unname(coef(m)["before1955"]), se = unname(se(m)["before1955"]), n = nobs(m))
}

r_out <- rd("outside_week")
r_cur <- rd("under_curfew")
r_nev <- rd("never_out")
r_dep <- rd("z_depression")
r_som <- rd("z_somatic")
r_non <- rd("z_nonsomatic")
r_sum <- rd("sum_srq")

show <- function(nm, r) cat(sprintf("%-14s b=%8.4f se=%7.4f N=%d\n", nm, r$b, r$se, r$n))
show("outside_week", r_out); show("under_curfew", r_cur); show("never_out", r_nev)
show("z_depression", r_dep); show("z_somatic", r_som); show("z_nonsomatic", r_non)
show("sum_srq", r_sum)

# Diagnostics (not scored): alternative index normalizations
for (alt in list(list(restd = TRUE, equal = FALSE), list(restd = FALSE, equal = TRUE),
                 list(restd = TRUE, equal = TRUE))) {
  d2 <- d
  d2$z_depression <- do.call(anderson, c(list(list1), alt))
  d2$z_somatic    <- do.call(anderson, c(list(list2), alt))
  d2$z_nonsomatic <- do.call(anderson, c(list(list3), alt))
  cat(sprintf("diag restd=%s equal=%s: dep=%.4f som=%.4f non=%.4f\n", alt$restd, alt$equal,
              rd("z_depression", data = d2)$b, rd("z_somatic", data = d2)$b,
              rd("z_nonsomatic", data = d2)$b))
}

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_nev$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", r_out$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", r_cur$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_dep$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", r_dep$n))
