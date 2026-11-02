suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
D <- "/Users/matthew/dev/Retally/benchmark/.cache/claude-code/grier-2023-sugar-roll-call-voting/seeded/2026-10-21-b/mount/grier_2023_sugar_roll_call_voting"
prep <- function(f) {
  d <- as.data.frame(read_dta(file.path(D, f)))
  d$yesvote <- as.integer(d$vote == "Aye")
  d$rsugcont <- ifelse(d$cong == 115, d$totalcont / 1.103, d$totalcont)
  d$id <- as.numeric(d$id)
  d
}
fml <- yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome + over65 + agcom | id
# Stata logit with i.id dummies: districts with no outcome variation are perfectly
# predicted and dropped; feglm drops the same FE groups. Robust SEs.
est <- function(d) feglm(fml, data = d, family = binomial("logit"), vcov = "hetero",
                         glm.iter = 200)
run <- function(f) {
  d <- prep(f)
  m1 <- est(d)
  m2 <- est(d[!is.na(d$both) & d$both == 1, ])
  print(summary(m1)); print(summary(m2))
  list(m1 = m1, m2 = m2)
}
r0 <- run("SugarReplicate.dta")
r1 <- run("SugarReplicate_iter1.dta")
r2 <- run("SugarReplicate_iter2.dta")
out <- function(n, v) cat(sprintf("RESULT:%s=%.10g\n", n, v))
out("sugar_contributions_district_fe", coef(r0$m1)["rsugcont"])
out("sugar_contributions_incumbent_fe", coef(r0$m2)["rsugcont"])
out("acu_ideology_district_fe", coef(r0$m1)["ncu"])
out("tenure_district_fe", coef(r0$m1)["tenure"])
out("tenure_incumbent_fe", coef(r0$m2)["tenure"])
out("sugar_contributions_calendar_year_district_fe", coef(r1$m1)["rsugcont"])
out("sugar_contributions_calendar_year_incumbent_fe", coef(r1$m2)["rsugcont"])
out("sugar_contributions_12_months_district_fe", coef(r2$m1)["rsugcont"])
out("sugar_contributions_12_months_incumbent_fe", coef(r2$m2)["rsugcont"])
out("observations_district_fe", nobs(r0$m1))
out("observations_incumbent_fe", nobs(r0$m2))
