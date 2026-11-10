# Independent reproduction: Altindag, Erten & Keskin (2022), Tables 3 and 4, column (3) (+/-45 months)
# RD: y = a + b*before1955 + f(dif) + controls, f linear on each side, uniform kernel,
# |dif| <= 45, FE: birth month, province, surveyor; indicators: education, ethnicity, gender;
# SEs clustered by month-year of birth.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/independent/2026-11-10-c/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)
d <- as.data.frame(d)
# survey respondents only
d <- d[d$non_response == 0 & !is.na(d$dif), ]
cat("respondents:", nrow(d), "\n")
cat("check treatment coding: dif range among before1955==1:", range(d$dif[d$before1955 == 1]),
    "; before1955==0:", range(d$dif[d$before1955 == 0]), "\n")

somatic <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
nonsomatic <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused", "unhappy",
                "weepy", "unwillingness", "undecisiveness", "disrupted", "useless", "uninterest",
                "worthless", "suicidal", "usually_tired", "quickly_tired")
allitems <- c(somatic, nonsomatic)

# Anderson (2008) inverse-covariance weighted index: z-score each item with the control
# group (born after 1955) mean and SD, weight by row sums of inverse covariance matrix of the
# z-scores, then re-standardize the index by control group mean/SD. Built on the full
# respondent sample; requires all component items observed.
anderson <- function(df, items, ctrl) {
  X <- as.matrix(df[, items])
  ok <- complete.cases(X)
  Z <- X
  for (j in seq_along(items)) {
    m <- mean(X[ctrl & ok, j]); s <- sd(X[ctrl & ok, j])
    Z[, j] <- (X[, j] - m) / s
  }
  S <- cov(Z[ok, , drop = FALSE])
  w <- rowSums(solve(S))
  idx <- rep(NA_real_, nrow(df))
  idx[ok] <- as.vector(Z[ok, , drop = FALSE] %*% w) / sum(w)
  mc <- mean(idx[ctrl & ok]); sc <- sd(idx[ctrl & ok])
  (idx - mc) / sc
}
ctrl <- d$before1955 == 0
d$mental_index <- anderson(d, allitems, ctrl)
d$somatic_index <- anderson(d, somatic, ctrl)
d$nonsomatic_index <- anderson(d, nonsomatic, ctrl)
d$srq_sum <- rowSums(d[, allitems])  # NA unless all 20 answered

h <- 45
s <- d[abs(d$dif) <= h, ]
cat("in bandwidth:", nrow(s), "\n")

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ before1955 + dif + dif:before1955 + i(education) + i(ethnicity) + female",
                         " | month + province_n + survey_taker_id"))
  m <- feols(f, data = s, cluster = ~modate)
  list(b = unname(coef(m)["before1955"]), se = unname(se(m)["before1955"]), n = nobs(m))
}
outs <- c(days = "outside_week", curfew = "under_curfew", never = "never_out",
          mental = "mental_index", somatic = "somatic_index", nonsomatic = "nonsomatic_index",
          srq = "srq_sum")
r <- lapply(outs, rd)
for (k in names(r)) cat(sprintf("%-12s b=%.4f se=%.4f n=%d\n", k, r[[k]]$b, r[[k]]$se, r[[k]]$n))

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.4f\n", r$days$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.4f\n", r$curfew$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.4f\n", r$never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", r$days$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", r$curfew$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.4f\n", r$mental$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.4f\n", r$somatic$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.4f\n", r$nonsomatic$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.4f\n", r$srq$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", r$mental$n))
