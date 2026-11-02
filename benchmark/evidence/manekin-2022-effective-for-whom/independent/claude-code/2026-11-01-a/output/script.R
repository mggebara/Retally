set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-11-01-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(d, "us_survey_wave1.rdata"))
load(paste0(d, "isr_survey_wave1.rdata"))
load(paste0(d, "us_survey_wave2.rdata"))
load(paste0(d, "isr_survey_wave2.rdata"))

res <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))

## Study 1 US: Black indicator + tactic indicators; base white/march; weighted OLS
us1 <- us_survey_wave1
us1$black <- as.numeric(as.character(us1$identity_protesters) == "1")
us1$traffic <- as.numeric(as.character(us1$tactic) == "1")
us1$destroy <- as.numeric(as.character(us1$tactic) == "2")
m_us1_v <- lm(degree_violence ~ black + traffic + destroy, data = us1, weights = weight)
m_us1_p <- lm(police_action_required ~ black + traffic + destroy, data = us1, weights = weight)
print(summary(m_us1_v)$coefficients); print(summary(m_us1_p)$coefficients)

## Study 1 Israel: identity 0 = white Jews, 1 = Ethiopian, 2 = Arab (paper's ordering)
is1 <- isr_survey_wave1
is1$eth <- as.numeric(as.character(is1$identity_protesters) == "1")
is1$arab <- as.numeric(as.character(is1$identity_protesters) == "2")
is1$traffic <- as.numeric(as.character(is1$tactic) == "1")
is1$destroy <- as.numeric(as.character(is1$tactic) == "2")
m_is1_v <- lm(degree_violence ~ eth + arab + traffic + destroy, data = is1, weights = weight)
m_is1_p <- lm(police_action_required ~ eth + arab + traffic + destroy, data = is1, weights = weight)
print(summary(m_is1_v)$coefficients); print(summary(m_is1_p)$coefficients)

## Study 2 US: black + group_goal + commitment; no weight variable in the data, unweighted OLS
m_us2_v <- lm(degree_violence ~ black + group_goal + commitment, data = us_survey_wave2)
m_us2_p <- lm(police_action_required ~ black + group_goal + commitment, data = us_survey_wave2)
print(summary(m_us2_v)$coefficients); print(summary(m_us2_p)$coefficients)

## Study 2 Israel sample size (regression observations)
is2 <- isr_survey_wave2
m_is2_v <- lm(degree_violence ~ factor(identity_protesters) + group_goal + commitment, data = is2)
print(summary(m_is2_v)$coefficients)

cat("DEVIATION: Study 2 US regressions are unweighted (no weight variable in us_survey_wave2).\n")
res("study1_us_black_perceived_violence", coef(m_us1_v)["black"])
res("study1_us_black_police_action", coef(m_us1_p)["black"])
res("study1_israel_ethiopian_perceived_violence", coef(m_is1_v)["eth"])
res("study1_israel_ethiopian_police_action", coef(m_is1_p)["eth"])
res("study1_israel_arab_perceived_violence", coef(m_is1_v)["arab"])
res("study1_israel_arab_police_action", coef(m_is1_p)["arab"])
res("study2_us_black_perceived_violence", coef(m_us2_v)["black"])
res("study2_us_black_police_action", coef(m_us2_p)["black"])
res("respondents_study1_us", nobs(m_us1_v))
res("respondents_study1_israel", nobs(m_is1_v))
res("respondents_study2_us", nobs(m_us2_v))
res("respondents_study2_israel", nobs(m_is2_v))
