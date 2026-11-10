# Retally reproduction: Altindag, Erten & Keskin (2022), "Mental Health Costs of Lockdowns"
# Seeded mode: follows "1 Tables.do" (Tables 3 and 4, column (3): linear RD, bandwidth 45).
#   xi: reg y before1955 di1* $contr if inrange(dif,-45,45), vce(cluster modate)
#   $contr = month_* province_n_* i.ethnicity i.education female i.survey_taker_id
#   di1* = di1 (running variable dif) and di1_i (its interaction with the treated side)
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

# Anderson (2008) index as in weightave2(..., normby(controldummy)); the .ado is
# not shipped, so it is reconstructed: z-score each item with the control-group
# mean and SD; weight the z-scores by the row sums of the inverse covariance
# matrix of the z-scores, estimated in the control (normby) group on complete
# cases; take the weighted average; standardise the index by the control group
# (mean 0, SD 1, as the paper states).  Index missing if any item is missing.
anderson_index <- function(vars) {
  Z <- sapply(vars, function(v) {
    x <- d[[v]]
    (x - mean(x[ctrl], na.rm = TRUE)) / sd(x[ctrl], na.rm = TRUE)
  })
  cc <- complete.cases(Z)
  S <- cov(Z[cc & ctrl, , drop = FALSE])
  w <- rowSums(solve(S))
  idx <- as.vector(Z %*% w) / sum(w)
  idx[!cc] <- NA
  (idx - mean(idx[ctrl], na.rm = TRUE)) / sd(idx[ctrl], na.rm = TRUE)
}
d$z_depression <- anderson_index(list1)
d$z_somatic    <- anderson_index(list2)
d$z_nonsomatic <- anderson_index(list3)
d$sum_srq <- rowSums(d[, list1])                    # NA if any item missing

bw <- 45
s <- d[abs(d$dif) <= bw, ]                          # inrange(dif,-45,45)

rhs <- paste("before1955 + di1 + di1_i +",
             paste(grep("^month_[0-9]+$", names(d), value = TRUE), collapse = " + "), "+",
             paste(grep("^province_n_[0-9]+$", names(d), value = TRUE), collapse = " + "),
             "+ factor(ethnicity) + factor(education) + female + factor(survey_taker_id)")

est <- function(y) {
  m <- feols(as.formula(paste(y, "~", rhs)), data = s, cluster = ~modate, notes = FALSE)
  list(b = unname(coef(m)["before1955"]), se = unname(se(m)["before1955"]), n = nobs(m))
}

outs <- c(outside_week = "days_outside_last_week", under_curfew = "under_curfew",
          never_out = "never_goes_out", z_depression = "mental_distress_index",
          z_somatic = "somatic_symptoms_index", z_nonsomatic = "nonsomatic_symptoms_index",
          sum_srq = "sum_srq20_yes_answers")
res <- lapply(names(outs), est); names(res) <- names(outs)

for (v in names(outs))
  cat(sprintf("# %s: b=%.4f se=%.4f N=%d\n", v, res[[v]]$b, res[[v]]$se, res[[v]]$n))
for (v in names(outs)) {
  tab <- if (v %in% c("outside_week", "under_curfew", "never_out")) "table3" else "table4"
  cat(sprintf("RESULT:%s_%s_col3=%.6f\n", outs[[v]], tab, res[[v]]$b))
}
cat(sprintf("RESULT:n_obs_days_outside_table3_col3=%d\n", res$outside_week$n))
cat(sprintf("RESULT:n_obs_under_curfew_table3_col3=%d\n", res$under_curfew$n))
cat(sprintf("RESULT:n_obs_mental_distress_index_table4_col3=%d\n", res$z_depression$n))
