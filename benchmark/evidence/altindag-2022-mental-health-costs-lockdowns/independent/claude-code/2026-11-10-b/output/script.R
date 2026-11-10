# Independent reproduction: Altindag, Erten & Keskin (2022), Tables 3 and 4, column (3) (+/-45 months)
suppressMessages({library(haven); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- as.data.frame(zap_labels(d))
d <- d[d$non_response == 0 & !is.na(d$dif), ]   # survey respondents only

# Treatment: born in or before December 1955 (dif >= 0); running variable dif = months older than Dec 1955
d$z <- as.numeric(d$dif >= 0)
stopifnot(all(d$z == d$before1955))

som <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
non <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused", "unhappy", "weepy", "unwillingness",
         "undecisiveness", "disrupted", "useless", "uninterest", "worthless", "suicidal", "usually_tired", "quickly_tired")

# Anderson (2008) inverse-covariance weighted index; items standardized by control-group (born 1956+) mean/sd;
# index defined for respondents answering every component item; final index re-standardized by control group.
anderson <- function(df, items, ctrl) {
  X <- as.matrix(df[, items])
  cc <- complete.cases(X)
  Z <- X
  for (j in seq_along(items)) {
    m <- mean(X[ctrl & cc, j]); s <- sd(X[ctrl & cc, j])
    Z[, j] <- (X[, j] - m) / s
  }
  S <- cov(Z[cc, , drop = FALSE])
  w <- rowSums(solve(S))
  idx <- rep(NA_real_, nrow(df))
  idx[cc] <- as.vector(Z[cc, , drop = FALSE] %*% w) / sum(w)
  idx <- (idx - mean(idx[ctrl & cc])) / sd(idx[ctrl & cc])
  idx
}
ctrl <- d$z == 0
d$mdi <- anderson(d, c(som, non), ctrl)
d$somi <- anderson(d, som, ctrl)
d$nsomi <- anderson(d, non, ctrl)
d$srq_sum <- rowSums(d[, c(som, non)])   # NA unless all 20 answered

h <- 45
s <- d[abs(d$dif) <= h, ]
fit <- function(y) {
  f <- as.formula(paste0(y, " ~ z + dif + z:dif + i(education) + i(ethnicity) + female | month + province_n + survey_taker_id"))
  # keep fixed-effect singletons (as Stata areg/xi would), so N counts all respondents with outcome and controls
  feols(f, data = s, cluster = ~dif, fixef.rm = "none")
}
outs <- c(days_outside_last_week = "outside_week", under_curfew = "under_curfew", never_goes_out = "never_out",
          mental_distress_index = "mdi", somatic_symptoms_index = "somi", nonsomatic_symptoms_index = "nsomi",
          sum_srq20_yes_answers = "srq_sum")
res <- list()
for (nm in names(outs)) {
  m <- fit(outs[[nm]])
  res[[nm]] <- list(b = unname(coef(m)["z"]), se = unname(se(m)["z"]), n = nobs(m))
  cat(sprintf("%-28s b=%8.4f se=%7.4f N=%d\n", nm, res[[nm]]$b, res[[nm]]$se, res[[nm]]$n))
}
tab <- c(days_outside_last_week = 3, under_curfew = 3, never_goes_out = 3, mental_distress_index = 4,
         somatic_symptoms_index = 4, nonsomatic_symptoms_index = 4, sum_srq20_yes_answers = 4)
for (nm in names(outs)) cat(sprintf("RESULT:%s_table%d_col3=%.6f\n", nm, tab[[nm]], res[[nm]]$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", res$days_outside_last_week$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", res$under_curfew$n))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", res$mental_distress_index$n))
