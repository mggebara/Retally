# Retally reproduction: Altindag, Erten & Keskin (2022), "Mental Health Costs of Lockdowns"
# Seeded mode: follows "1 Tables.do" (Tables 3 and 4, column (3): linear RD, bandwidth 45).
#   xi: reg y before1955 di1* $contr if inrange(dif,-45,45), vce(cluster modate)
#   $contr = month_* province_n_* i.ethnicity i.education female i.survey_taker_id
set.seed(42)
suppressPackageStartupMessages({library(haven); library(fixest)})

path <- "<repo>/benchmark/.cache/claude-code/altindag-2022-mental-health-costs-lockdowns/seeded/2026-11-10-a/mount/altindag_2022_mental_health_costs_lockdowns/ICPSR_183165-V1.1/konda_data_for_analysis.dta"
d <- as.data.frame(zap_labels(read_dta(path)))
d <- d[d$non_response == 0, ]                       # keep if non_response==0

list1 <- c("head_ache","mal_appetite","sleeplessness","scared","shaking","nervous",
           "indigestion","unfocused","unhappy","weepy","unwillingness","undecisiveness",
           "disrupted","useless","uninterest","worthless","suicidal","usually_tired",
           "stomach_discomfort","quickly_tired")
list2 <- c("head_ache","shaking","indigestion","stomach_discomfort")
list3 <- setdiff(list1, list2)

ctrl <- d$before1955 == 0                           # controldummy == 1

# Anderson (2008) / Asher-Novosad weightave2 with normby(controldummy).
# The .ado itself is not in the package.  Primary version (cov_on = "raw"):
# z-score each item with the control-group mean and SD, weight the z-scores by
# the row sums of the inverse covariance matrix of the RAW items (as a
# `mat accum, dev`-style implementation would), average, then standardise the
# index by the control group (mean 0, SD 1 per the paper).
# Variants are printed as '#' diagnostic lines only.
anderson_index <- function(vars, cov_on = "raw", final_std = TRUE, equal = FALSE) {
  X <- as.matrix(d[, vars, drop = FALSE])
  Z <- sapply(vars, function(v) {
    x <- d[[v]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  cc <- complete.cases(Z)
  S <- switch(cov_on,
              raw    = cov(X[cc, , drop = FALSE]),
              z      = cov(Z[cc, , drop = FALSE]),
              ctrl_z = cov(Z[cc & ctrl, , drop = FALSE]))
  w <- if (equal) rep(1, length(vars)) else rowSums(solve(S))
  idx <- as.vector(Z %*% w) / sum(w)
  idx[!cc] <- NA                                   # replace z_* = . if any item missing
  if (final_std) idx <- (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
  idx
}
d$z_depression <- anderson_index(list1)
d$z_somatic    <- anderson_index(list2)
d$z_nonsomatic <- anderson_index(list3)
variants <- list(zcov_std = list(cov_on = "z", final_std = TRUE),
                 zcov_nostd = list(cov_on = "z", final_std = FALSE),
                 rawcov_nostd = list(cov_on = "raw", final_std = FALSE),
                 ctrlzcov_std = list(cov_on = "ctrl_z", final_std = TRUE),
                 equal_std = list(cov_on = "z", final_std = TRUE, equal = TRUE),
                 equal_nostd = list(cov_on = "z", final_std = FALSE, equal = TRUE))
for (vn in names(variants)) for (L in list(list("dep", list1), list("som", list2), list("non", list3)))
  d[[paste0("v_", vn, "_", L[[1]])]] <- do.call(anderson_index, c(list(L[[2]]), variants[[vn]]))
d$sum_srq <- rowSums(d[, list1])                    # NA if any item missing

bw <- 45
s <- d[abs(d$dif) <= bw, ]

rhs <- paste("before1955 + di1 + di1_i +",
             paste(grep("^month_[0-9]+$", names(d), value = TRUE), collapse = " + "), "+",
             paste(grep("^province_n_[0-9]+$", names(d), value = TRUE), collapse = " + "),
             "+ factor(ethnicity) + factor(education) + female + factor(survey_taker_id)")

est <- function(y) {
  m <- feols(as.formula(paste(y, "~", rhs)), data = s, cluster = ~modate)
  list(b = unname(coef(m)["before1955"]), se = unname(se(m)["before1955"]), n = nobs(m))
}

outs <- c(outside_week = "days_outside_last_week", under_curfew = "under_curfew",
          never_out = "never_goes_out", z_depression = "mental_distress_index",
          z_somatic = "somatic_symptoms_index", z_nonsomatic = "nonsomatic_symptoms_index",
          sum_srq = "sum_srq20_yes_answers")
res <- lapply(names(outs), est); names(res) <- names(outs)
for (v in grep("^v_", names(s), value = TRUE)) {
  r <- est(v); cat(sprintf("# variant %s: b=%.4f se=%.4f N=%d\n", v, r$b, r$se, r$n))
}

for (v in names(outs)) {
  tab <- if (v %in% c("outside_week", "under_curfew", "never_out")) "table3" else "table4"
  cat(sprintf("# %s: b=%.4f se=%.4f N=%d\n", v, res[[v]]$b, res[[v]]$se, res[[v]]$n))
}
for (v in names(outs)) {
  tab <- if (v %in% c("outside_week", "under_curfew", "never_out")) "table3" else "table4"
  cat(sprintf("RESULT:%s_%s_col3=%.6f\n", outs[[v]], tab, res[[v]]$b))
}
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", res$outside_week$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", res$under_curfew$n))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", res$z_depression$n))
