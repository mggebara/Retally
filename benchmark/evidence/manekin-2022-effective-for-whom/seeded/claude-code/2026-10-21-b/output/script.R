# Reproduction of Manekin & Mitts (2022), Tables 1 and 2 (package replicate_table_1.R and replicate_table_4.R)
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-10-21-b/mount/manekin_2022_effective_for_whom/Replication/Data"
load(file.path(d, "us_survey_wave1.rdata"))
load(file.path(d, "isr_survey_wave1.rdata"))
load(file.path(d, "us_survey_wave2.rdata"))
load(file.path(d, "isr_survey_wave2.rdata"))
pick <- function(m, pat) {
  cf <- coef(m)
  nm <- grep(pat, names(cf), value = TRUE, ignore.case = TRUE)
  cat("# ", deparse(formula(m)), " coef", nm, "=", cf[nm], "\n")
  stopifnot(length(nm) == 1)
  unname(cf[nm])
}
print(levels(factor(us_survey_wave1$identity_protesters)))
print(levels(factor(isr_survey_wave1$identity_protesters)))
# Table 1 Panel A (weighted OLS, as in replicate_table_1.R)
degv_us <- lm(degree_violence ~ identity_protesters + tactic, data = us_survey_wave1, weights = weight)
pol_us  <- lm(police_action_required ~ identity_protesters + tactic, data = us_survey_wave1, weights = weight)
# Table 1 Panel B
degv_is <- lm(degree_violence ~ identity_protesters + tactic, data = isr_survey_wave1, weights = weight)
pol_is  <- lm(police_action_required ~ identity_protesters + tactic, data = isr_survey_wave1, weights = weight)
# Paper Table 2 = package table 4 (unweighted OLS, as in replicate_table_4.R)
m1  <- lm(degree_violence ~ black + group_goal + commitment, data = us_survey_wave2)
m3  <- lm(police_action_required ~ black + group_goal + commitment, data = us_survey_wave2)
m1i <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = isr_survey_wave2)
print(summary(degv_is)$coefficients)
print(summary(m1)$coefficients)
r <- c(
  study1_us_black_perceived_violence = pick(degv_us, "^identity_protesters"),
  study1_us_black_police_action = pick(pol_us, "^identity_protesters"),
  study1_israel_ethiopian_perceived_violence = pick(degv_is, "^identity_protesters1$"),
  study1_israel_ethiopian_police_action = pick(pol_is, "^identity_protesters1$"),
  study1_israel_arab_perceived_violence = pick(degv_is, "^identity_protesters2$"),
  study1_israel_arab_police_action = pick(pol_is, "^identity_protesters2$"),
  study2_us_black_perceived_violence = pick(m1, "^black"),
  study2_us_black_police_action = pick(m3, "^black"),
  respondents_study1_us = nobs(degv_us),
  respondents_study1_israel = nobs(degv_is),
  respondents_study2_us = nobs(m1),
  respondents_study2_israel = nobs(m1i))
for (n in names(r)) cat(sprintf("RESULT:%s=%.6f\n", n, r[[n]]))
