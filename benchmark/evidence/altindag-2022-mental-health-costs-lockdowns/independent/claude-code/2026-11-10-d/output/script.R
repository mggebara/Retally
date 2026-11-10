# Independent reproduction: Altindag, Erten & Keskin (2022), Tables 3 and 4, column (3) (+/-45 months)
# RD: y = a + b*before1955 + f(dif) + controls, f linear on each side of the threshold,
# uniform kernel, |dif| <= 45, FE for birth month, province, surveyor, education, ethnicity,
# plus a female indicator; SEs clustered by month-year of birth (modate).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-d/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)
d <- d %>% filter(non_response == 0)

srq <- c("head_ache","mal_appetite","sleeplessness","scared","shaking","nervous","indigestion",
         "unfocused","unhappy","weepy","unwillingness","undecisiveness","disrupted","useless",
         "uninterest","worthless","suicidal","usually_tired","stomach_discomfort","quickly_tired")
som <- c("head_ache","shaking","indigestion","stomach_discomfort")
nonsom <- setdiff(srq, som)

# Anderson (2008) inverse-covariance-weighted index: each item demeaned and divided by the
# control-group (born 1956 or later) SD; items combined with weights equal to the row sums of the
# inverse covariance matrix of the standardized items; final index re-standardized so the control
# group has mean 0 and SD 1. Computed on respondents with all component items observed.
anderson <- function(df, items, treat) {
  X <- as.matrix(df[, items])
  ok <- complete.cases(X)
  ctrl <- ok & treat == 0
  mu <- colMeans(X[ctrl, , drop = FALSE]); sdv <- apply(X[ctrl, , drop = FALSE], 2, sd)
  Z <- sweep(sweep(X, 2, mu, "-"), 2, sdv, "/")
  S <- cov(Z[ok, , drop = FALSE])
  w <- rowSums(solve(S))
  idx <- rep(NA_real_, nrow(df))
  idx[ok] <- as.vector(Z[ok, , drop = FALSE] %*% w) / sum(w)
  idx <- (idx - mean(idx[ctrl])) / sd(idx[ctrl])
  idx
}
d$mdi    <- anderson(d, srq, d$before1955)
d$somi   <- anderson(d, som, d$before1955)
d$nonsomi <- anderson(d, nonsom, d$before1955)
d$srqsum <- rowSums(as.matrix(d[, srq]))   # NA unless all 20 answered

bw <- 45
s <- d %>% filter(abs(dif) <= bw)

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ before1955 + dif + dif:before1955 + female | month + province_n + survey_taker_id + education + ethnicity"))
  # keep fixed-effect singletons (as a dummy-variable OLS in Stata would) so N counts every respondent
  m <- feols(f, data = s, cluster = ~modate, fixef.rm = "none")
  list(b = unname(coef(m)["before1955"]), se = unname(se(m)["before1955"]), n = nobs(m))
}

outs <- c(days = "outside_week", curfew = "under_curfew", never = "never_out",
          mdi = "mdi", somi = "somi", nonsomi = "nonsomi", srqsum = "srqsum")
res <- lapply(outs, rd)
for (k in names(res)) cat(sprintf("%-8s b=%.4f se=%.4f N=%d\n", k, res[[k]]$b, res[[k]]$se, res[[k]]$n))

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", res$days$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", res$curfew$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", res$never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", res$days$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", res$curfew$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", res$mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", res$somi$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", res$nonsomi$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", res$srqsum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", res$mdi$n))
