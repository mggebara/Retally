# Altindag, Erten & Keskin (2022) -- Mental health costs of lockdowns
# Independent, blind reproduction of Table 3 and Table 4, column (3) (+/-45 months).
#
# Specification (paper Sec. 2.2, eq. 1, Table 3/4 notes):
#   y_i = a + b*z_i + f(x_i) + controls + e_i,  |x_i| <= h, h = 45
#   z_i = born in or before December 1955 (before1955); x_i = months older than Dec 1955 (dif)
#   f() linear, slopes allowed to differ on each side; uniform kernel (unweighted OLS)
#   controls: birth-month FE, province FE, surveyor FE, education, ethnicity, gender indicators
#   SEs clustered by month-year of birth.
# Mental distress indices: Anderson (2008) inverse-covariance weighted indices of
# control-group-standardized SRQ-20 items, re-standardized to control mean 0 / sd 1.

suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)

path <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-d/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d <- read_dta(path) %>% zap_labels() %>% as.data.frame()

# survey respondents only (non-respondents have no survey answers)
d <- d[d$non_response == 0, ]
cat("Respondents:", nrow(d), "\n")

# ---------- SRQ-20 items ----------
somatic <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
nonsomatic <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused",
                "unhappy", "weepy", "unwillingness", "undecisiveness", "disrupted",
                "useless", "uninterest", "worthless", "suicidal", "usually_tired",
                "quickly_tired")
allitems <- c(somatic, nonsomatic)
stopifnot(length(allitems) == 20)

control <- d$before1955 == 0

# Anderson (2008) index: standardize each item by control-group mean/sd, weight by
# row sums of the inverse covariance matrix of the standardized items, then
# re-standardize the weighted average by the control group's mean/sd.
# Computed on respondents answering all 20 SRQ-20 items (full survey sample).
complete20 <- complete.cases(d[, allitems])
anderson_index <- function(items, use) {
  Z <- sapply(items, function(v) {
    x <- d[[v]]
    mu <- mean(x[use & control]); s <- sd(x[use & control])
    (x - mu) / s
  })
  Zu <- Z[use, , drop = FALSE]
  Sig <- cov(Zu)
  w <- rowSums(solve(Sig))
  idx <- rep(NA_real_, nrow(d))
  idx[use] <- as.vector(Zu %*% w) / sum(w)
  mu <- mean(idx[use & control]); s <- sd(idx[use & control])
  (idx - mu) / s
}
d$mental_index    <- anderson_index(allitems, complete20)
d$somatic_index   <- anderson_index(somatic, complete20)
d$nonsomatic_index <- anderson_index(nonsomatic, complete20)
d$srq_sum <- ifelse(complete20, rowSums(d[, allitems]), NA_real_)
cat("Respondents with all 20 SRQ items:", sum(complete20), "\n")

# ---------- RD regressions ----------
h <- 45
rd <- function(y) {
  s <- d[!is.na(d$dif) & abs(d$dif) <= h, ]
  vars <- c(y, "before1955", "dif", "month", "province_n", "survey_taker_id",
            "education", "ethnicity", "female")
  s <- s[complete.cases(s[, vars]), ]
  f <- as.formula(paste0(y, " ~ before1955 + dif + dif:before1955 + factor(month) +",
                         " factor(province_n) + factor(survey_taker_id) + factor(education) +",
                         " factor(ethnicity) + factor(female)"))
  m <- feols(f, data = s, cluster = ~dif)
  ct <- coeftable(m)
  cat(sprintf("%-18s b=%9.4f se=%8.4f N=%d  control mean=%.3f\n", y,
              ct["before1955", 1], ct["before1955", 2], nobs(m),
              mean(s[[y]][s$before1955 == 0])))
  list(b = unname(coef(m)["before1955"]), n = nobs(m))
}

r_out   <- rd("outside_week")
r_cur   <- rd("under_curfew")
r_never <- rd("never_out")
r_mdi   <- rd("mental_index")
r_som   <- rd("somatic_index")
r_non   <- rd("nonsomatic_index")
r_sum   <- rd("srq_sum")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", r_out$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", r_cur$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", r_mdi$n))
