# Altindag, Erten & Keskin (2022) "Mental Health Costs of Lockdowns" -- independent, blind reproduction
# Table 3 and Table 4, column (3): RD with 45-month bandwidth.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})

p <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-c/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d <- zap_labels(read_dta(p))

# Survey respondents only (non-respondents have no birth date / outcomes)
d <- d %>% filter(!is.na(dif), !is.na(before1955))
cat("Respondents with birth date:", nrow(d), "\n")
cat("Check treatment == (dif >= 0):", all(d$before1955 == as.integer(d$dif >= 0)), "\n")

# ---- SRQ-20 items --------------------------------------------------------
somatic <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
nonsomatic <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused", "unhappy",
                "weepy", "unwillingness", "undecisiveness", "disrupted", "useless", "uninterest",
                "worthless", "suicidal", "usually_tired", "quickly_tired")
allitems <- c(somatic, nonsomatic)
stopifnot(length(allitems) == 20)

complete20 <- complete.cases(d[, allitems])
d$srq20_sum <- ifelse(complete20, rowSums(d[, allitems]), NA_real_)

# Anderson (2008) inverse-covariance weighted index.
# Each item is demeaned with the control-group (born Jan 1956 or later) mean and divided by the
# control-group SD; items are combined with weights = row sums of the inverse covariance matrix
# of the standardized items; the resulting index is re-standardized to mean 0 / SD 1 in the control group.
anderson_index <- function(df, items, ctrl, ok) {
  X <- as.matrix(df[ok, items])
  cg <- ctrl[ok] == 1
  mu <- colMeans(X[cg, , drop = FALSE]); sdv <- apply(X[cg, , drop = FALSE], 2, sd)
  Z <- sweep(sweep(X, 2, mu, "-"), 2, sdv, "/")
  S <- cov(Z)
  w <- rowSums(solve(S))
  idx <- as.vector(Z %*% w) / sum(w)
  idx <- (idx - mean(idx[cg])) / sd(idx[cg])
  out <- rep(NA_real_, nrow(df)); out[ok] <- idx
  out
}
ctrl <- as.integer(d$before1955 == 0)
d$mental_distress_index <- anderson_index(d, allitems, ctrl, complete20)
d$somatic_index <- anderson_index(d, somatic, ctrl, complete20)
d$nonsomatic_index <- anderson_index(d, nonsomatic, ctrl, complete20)

# ---- RD specification -----------------------------------------------------
# y = a + b*before1955 + linear in dif separately on each side + month-of-birth FE + province FE +
#     surveyor FE + education, ethnicity, gender indicators; uniform kernel; |dif| <= 45;
# SEs clustered by month-year of birth (dif identifies the cohort uniquely).
h <- 45
s <- d %>% filter(abs(dif) <= h)
s$dif_t <- s$dif * s$before1955
s$cohort <- s$dif

rd <- function(y) {
  f <- as.formula(paste0(y, " ~ before1955 + dif + dif_t + i(education) + i(ethnicity) + female",
                         " | month + province_n + survey_taker_id"))
  feols(f, data = s, cluster = ~cohort, fixef.rm = "none")  # keep FE singletons, as Stata reg/areg with dummies does
}

outs <- c(days = "outside_week", curfew = "under_curfew", never = "never_out",
          mdi = "mental_distress_index", som = "somatic_index", nonsom = "nonsomatic_index",
          srq = "srq20_sum")
fits <- lapply(outs, rd)
for (k in names(fits)) {
  ct <- coeftable(fits[[k]])["before1955", ]
  cat(sprintf("%-24s b=%.4f se=%.4f N=%d ctrl_mean=%.3f\n", outs[[k]], ct[1], ct[2], nobs(fits[[k]]),
              mean(s[[outs[[k]]]][s$before1955 == 0], na.rm = TRUE)))
}

b <- function(k) unname(coef(fits[[k]])["before1955"])
cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", b("days")))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", b("curfew")))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", b("never")))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", nobs(fits[["days"]])))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", nobs(fits[["curfew"]])))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", b("mdi")))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", b("som")))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", b("nonsom")))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", b("srq")))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", nobs(fits[["mdi"]])))
