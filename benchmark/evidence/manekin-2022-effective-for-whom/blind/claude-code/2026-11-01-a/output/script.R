set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-01-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(d, "us_survey_wave1.rdata"))
load(paste0(d, "isr_survey_wave1.rdata"))
load(paste0(d, "us_survey_wave2.rdata"))
load(paste0(d, "isr_survey_wave2.rdata"))

out <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))

# ---- Study 1, US: OLS on Black indicator + tactic indicators (base: white, march), weighted
u1 <- us_survey_wave1
u1$black <- as.numeric(as.character(u1$identity_protesters) == "1")
u1$traffic <- as.numeric(as.character(u1$tactic) == "1")
u1$destroy <- as.numeric(as.character(u1$tactic) == "2")
m_u1_v <- lm(degree_violence ~ black + traffic + destroy, data = u1, weights = weight)
m_u1_p <- lm(police_action_required ~ black + traffic + destroy, data = u1, weights = weight)
print(summary(m_u1_v)); print(summary(m_u1_p))

# ---- Study 1, Israel: identity 0=white Jews, 1=Ethiopian, 2=Arab (paper's ordering); weighted
i1 <- isr_survey_wave1
i1$ethiopian <- as.numeric(as.character(i1$identity_protesters) == "1")
i1$arab <- as.numeric(as.character(i1$identity_protesters) == "2")
i1$traffic <- as.numeric(as.character(i1$tactic) == "1")
i1$garbage <- as.numeric(as.character(i1$tactic) == "2")
m_i1_v <- lm(degree_violence ~ ethiopian + arab + traffic + garbage, data = i1, weights = weight)
m_i1_p <- lm(police_action_required ~ ethiopian + arab + traffic + garbage, data = i1, weights = weight)
print(summary(m_i1_v)); print(summary(m_i1_p))

# ---- Study 2, US: OLS on Black, group goal, commitment (no weights in data)
u2 <- us_survey_wave2
m_u2_v <- lm(degree_violence ~ black + group_goal + commitment, data = u2)
m_u2_p <- lm(police_action_required ~ black + group_goal + commitment, data = u2)
print(summary(m_u2_v)); print(summary(m_u2_p))

# ---- Study 2, Israel: sample size of Table 2 Panel B regressions
i2 <- isr_survey_wave2
i2$ethiopian <- as.numeric(as.character(i2$identity_protesters) == "1")
i2$arab <- as.numeric(as.character(i2$identity_protesters) == "2")
m_i2_v <- lm(degree_violence ~ ethiopian + arab + group_goal + commitment, data = i2)
print(summary(m_i2_v))

out("study1_us_black_perceived_violence", coef(m_u1_v)[["black"]])
out("study1_us_black_police_action", coef(m_u1_p)[["black"]])
out("study1_israel_ethiopian_perceived_violence", coef(m_i1_v)[["ethiopian"]])
out("study1_israel_ethiopian_police_action", coef(m_i1_p)[["ethiopian"]])
out("study1_israel_arab_perceived_violence", coef(m_i1_v)[["arab"]])
out("study1_israel_arab_police_action", coef(m_i1_p)[["arab"]])
out("study2_us_black_perceived_violence", coef(m_u2_v)[["black"]])
out("study2_us_black_police_action", coef(m_u2_p)[["black"]])
cat(sprintf("RESULT:respondents_study1_us=%d\n", nobs(m_u1_v)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nobs(m_i1_v)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nobs(m_u2_v)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", nobs(m_i2_v)))
