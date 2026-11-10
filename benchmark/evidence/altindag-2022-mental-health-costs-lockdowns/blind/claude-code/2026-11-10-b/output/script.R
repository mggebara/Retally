# Altindag, Erten & Keskin (2022) -- independent blind reproduction
# Tables 3 and 4, column (3): RD, bandwidth +/-45 months, uniform kernel,
# local linear in running variable separately on each side,
# month-of-birth, province and surveyor FE, education/ethnicity/gender indicators,
# SEs clustered by month-year of birth.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-b/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- zap_labels(d)

# survey respondents only (non-respondents have no data)
d <- d %>% filter(non_response == 0, !is.na(dif))

# treatment: born in or before December 1955 (dif >= 0); dif = months older than Dec 1955
d <- d %>% mutate(z = as.numeric(dif >= 0),
                  x = dif,
                  x_z = dif * z,
                  cohort = modate)
stopifnot(all(d$z == d$before1955))

# ---- SRQ-20 items ----
somatic <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
nonsomatic <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused",
                "unhappy", "weepy", "unwillingness", "undecisiveness", "disrupted",
                "useless", "uninterest", "worthless", "suicidal", "usually_tired",
                "quickly_tired")
allsrq <- c(somatic, nonsomatic)
stopifnot(length(allsrq) == 20)

complete_srq <- complete.cases(d[, allsrq])
ctrl <- d$z == 0

# Anderson (2008) index: standardize each item by control-group (born Jan 1956
# or later) mean/SD, weight by row sums of the inverse covariance matrix of the
# standardized items, then rescale the index to control-group mean 0 / SD 1.
anderson <- function(df, items, use) {
  Z <- sapply(items, function(v) {
    y <- df[[v]]
    (y - mean(y[ctrl & use])) / sd(y[ctrl & use])
  })
  S <- cov(Z[use, , drop = FALSE])
  w <- rowSums(solve(S))
  idx <- as.numeric(Z %*% w) / sum(w)
  idx[!use] <- NA
  (idx - mean(idx[ctrl & use])) / sd(idx[ctrl & use])
}
d$mdi <- anderson(d, allsrq, complete_srq)
d$somatic_idx <- anderson(d, somatic, complete_srq)
d$nonsomatic_idx <- anderson(d, nonsomatic, complete_srq)
d$srq_sum <- ifelse(complete_srq, rowSums(d[, allsrq]), NA)

# ---- estimation ----
bw <- 45
s <- d %>% filter(abs(dif) <= bw)

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ z + x + x_z + i(education) + i(ethnicity) + female",
                         " | month + province_n + survey_taker_id"))
  m <- feols(f, data = s, cluster = ~cohort)
  list(b = unname(coef(m)["z"]), se = unname(se(m)["z"]), n = nobs(m),
       cm = mean(s[[y]][s$z == 0], na.rm = TRUE))
}

outs <- c(days = "outside_week", curfew = "under_curfew", never = "never_out",
          mdi = "mdi", som = "somatic_idx", nonsom = "nonsomatic_idx", sum = "srq_sum")
res <- lapply(outs, rd)
for (k in names(res)) {
  cat(sprintf("%-16s b=%.4f se=%.4f N=%d ctrl_mean=%.3f\n", outs[[k]],
              res[[k]]$b, res[[k]]$se, res[[k]]$n, res[[k]]$cm))
}

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", res$days$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", res$curfew$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", res$never$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", res$days$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", res$curfew$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", res$mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", res$som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", res$nonsom$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", res$sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", res$mdi$n))
