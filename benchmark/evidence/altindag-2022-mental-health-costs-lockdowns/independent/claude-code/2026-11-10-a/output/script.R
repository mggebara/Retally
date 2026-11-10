# Independent reproduction: Altindag, Erten & Keskin (2022), Tables 3 and 4, column (3) (+/-45 months)
suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- as.data.frame(zap_labels(d))
d <- d[d$non_response == 0 & !is.na(d$dif), ]   # survey respondents only

som <- c("head_ache","shaking","indigestion","stomach_discomfort")
non <- c("mal_appetite","sleeplessness","scared","nervous","unfocused","unhappy","weepy",
         "unwillingness","undecisiveness","disrupted","useless","uninterest","worthless",
         "suicidal","usually_tired","quickly_tired")
ctl <- d$before1955 == 0   # control group: born January 1956 or later

# Anderson (2008) index: standardize each item by control-group mean/SD, weight by row sums of the
# inverse covariance matrix of the standardized items, then rescale to control mean 0 / SD 1.
# Index defined only when all component items are observed (matches the paper's sample sizes).
anderson <- function(items) {
  Z <- sapply(items, function(v) (d[[v]] - mean(d[[v]][ctl], na.rm=TRUE)) / sd(d[[v]][ctl], na.rm=TRUE))
  ok <- complete.cases(Z)
  S <- cov(Z[ok, ])
  w <- rowSums(solve(S))
  idx <- rep(NA_real_, nrow(d))
  idx[ok] <- as.vector(Z[ok, ] %*% w) / sum(w)
  (idx - mean(idx[ctl], na.rm=TRUE)) / sd(idx[ctl], na.rm=TRUE)
}
d$mdi  <- anderson(c(som, non))
d$sdi  <- anderson(som)
d$nsdi <- anderson(non)
d$srq_sum <- rowSums(d[, c(som, non)])          # NA unless all 20 answered

d$dif_t <- d$dif * d$before1955                  # slope allowed to differ on each side
b <- d[abs(d$dif) <= 45, ]

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ before1955 + dif + dif_t + female + i(education) + i(ethnicity) | month + province_n + survey_taker_id"))
  feols(f, data = b, cluster = ~dif)
}
outs <- c(days_outside_last_week = "outside_week", under_curfew = "under_curfew",
          never_goes_out = "never_out", mental_distress_index = "mdi",
          somatic_symptoms_index = "sdi", nonsomatic_symptoms_index = "nsdi",
          sum_srq20_yes_answers = "srq_sum")
res <- lapply(outs, rd)
for (nm in names(res)) {
  m <- res[[nm]]
  cat(sprintf("%-28s coef=%.4f se=%.4f N=%d\n", nm, coef(m)["before1955"], se(m)["before1955"], nobs(m)))
}
tab <- c(days_outside_last_week = 3, under_curfew = 3, never_goes_out = 3)
for (nm in names(tab)) cat(sprintf("RESULT:%s_table3_col3=%.4f\n", nm, coef(res[[nm]])["before1955"]))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", nobs(res$days_outside_last_week)))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", nobs(res$under_curfew)))
for (nm in c("mental_distress_index","somatic_symptoms_index","nonsomatic_symptoms_index","sum_srq20_yes_answers"))
  cat(sprintf("RESULT:%s_table4_col3=%.4f\n", nm, coef(res[[nm]])["before1955"]))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", nobs(res$mental_distress_index)))
