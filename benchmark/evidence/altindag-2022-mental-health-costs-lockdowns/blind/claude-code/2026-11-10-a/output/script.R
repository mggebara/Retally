# Independent, blind reproduction: Altindag, Erten & Keskin (2022),
# "Mental Health Costs of Lockdowns: Evidence from Age-Specific Curfews in Turkey"
# Table 3 and Table 4, column (3): RD with 45-month bandwidth.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/blind/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta")
d <- as.data.frame(lapply(d, function(x) { attributes(x) <- NULL; x }))

# survey non-respondents excluded
d <- d[d$non_response == 0 & !is.na(d$dif), ]
cat("respondents with birth date:", nrow(d), "\n")

# document running variable / treatment mapping
cat("Treatment by running variable around 0:\n")
print(table(d$dif[abs(d$dif) <= 2], d$before1955[abs(d$dif) <= 2]))
chk <- unique(d[abs(d$dif) <= 1, c("year", "month", "dif", "before1955")])
print(chk[order(chk$dif), ])

# ---- SRQ-20 items ----
somatic <- c("head_ache", "shaking", "indigestion", "stomach_discomfort")
nonsomatic <- c("mal_appetite", "sleeplessness", "scared", "nervous", "unfocused",
                "unhappy", "weepy", "unwillingness", "undecisiveness", "disrupted",
                "useless", "uninterest", "worthless", "suicidal", "usually_tired",
                "quickly_tired")
allitems <- c(somatic, nonsomatic)
stopifnot(length(allitems) == 20)

ctrl <- d$before1955 == 0  # control group: born in January 1956 or later

# Anderson (2008) inverse-covariance-weighted index
anderson <- function(df, items, ctrl) {
  X <- as.matrix(df[, items])
  ok <- complete.cases(X)   # respondents with every item of the index answered
  Z <- X
  for (k in seq_along(items)) {
    m <- mean(X[ok & ctrl, k]); s <- sd(X[ok & ctrl, k])
    Z[, k] <- (X[, k] - m) / s
  }
  S <- cov(Z[ok, ])
  w <- rowSums(solve(S))
  idx <- rep(NA_real_, nrow(df))
  idx[ok] <- as.vector(Z[ok, ] %*% w) / sum(w)
  # rescale to mean 0, SD 1 in the control group
  idx <- (idx - mean(idx[ok & ctrl])) / sd(idx[ok & ctrl])
  idx
}
# indices built on respondents who answered all 20 items (same sample as the SRQ sum)
allok <- complete.cases(d[, allitems])
d$srq_sum <- ifelse(allok, rowSums(d[, allitems]), NA)
dd <- d; dd[!allok, allitems] <- NA
d$mdi <- anderson(dd, allitems, ctrl)
d$somatic_idx <- anderson(dd, somatic, ctrl)
d$nonsomatic_idx <- anderson(dd, nonsomatic, ctrl)

# ---- RD specification ----
d$z <- d$before1955
d$x <- d$dif
d$xz <- d$dif * d$before1955
h <- 45
s <- d[abs(d$dif) <= h, ]
cat("Bandwidth sample size (|dif|<=45):", nrow(s), "\n")
controls <- c("education", "ethnicity", "female", "month", "province_n", "survey_taker_id")

rd <- function(y) {
  ss <- s[complete.cases(s[, c(y, "z", "x", controls)]), ]
  f <- as.formula(paste(y, "~ z + x + xz + i(education) + i(ethnicity) + female | month + province_n + survey_taker_id"))
  m <- feols(f, data = ss, cluster = ~dif)
  cat(sprintf("%-16s b=%.4f se=%.4f N=%d (complete cases %d)\n", y, coef(m)["z"], se(m)["z"], nobs(m), nrow(ss)))
  list(b = unname(coef(m)["z"]), n = nrow(ss), nobs = nobs(m))
}

r_out  <- rd("outside_week")
r_cur  <- rd("under_curfew")
r_nev  <- rd("never_out")
r_mdi  <- rd("mdi")
r_som  <- rd("somatic_idx")
r_non  <- rd("nonsomatic_idx")
r_sum  <- rd("srq_sum")

cat(sprintf("RESULT:days_outside_last_week_table3_col3=%.6f\n", r_out$b))
cat(sprintf("RESULT:under_curfew_table3_col3=%.6f\n", r_cur$b))
cat(sprintf("RESULT:never_goes_out_table3_col3=%.6f\n", r_nev$b))
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", r_out$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", r_cur$n))
cat(sprintf("RESULT:mental_distress_index_table4_col3=%.6f\n", r_mdi$b))
cat(sprintf("RESULT:somatic_symptoms_index_table4_col3=%.6f\n", r_som$b))
cat(sprintf("RESULT:nonsomatic_symptoms_index_table4_col3=%.6f\n", r_non$b))
cat(sprintf("RESULT:sum_srq20_yes_answers_table4_col3=%.6f\n", r_sum$b))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", r_mdi$n))
