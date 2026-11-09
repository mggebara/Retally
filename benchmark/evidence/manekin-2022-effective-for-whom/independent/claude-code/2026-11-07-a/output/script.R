# Manekin & Mitts (2022), independent reproduction of Tables 1-2 main effects
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-11-07-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(d, "us_survey_wave1.rdata"))
load(paste0(d, "isr_survey_wave1.rdata"))
load(paste0(d, "us_survey_wave2.rdata"))
load(paste0(d, "isr_survey_wave2.rdata"))

# Study 1 US: identity (0 white, 1 Black) and tactic (0 march, 1 traffic, 2 destroy police cars); weighted OLS
u1 <- us_survey_wave1
u1$identity_protesters <- relevel(factor(u1$identity_protesters), ref = "0")
u1$tactic <- relevel(factor(u1$tactic), ref = "0")
m_u1_v <- lm(degree_violence ~ identity_protesters + tactic, data = u1, weights = weight)
m_u1_p <- lm(police_action_required ~ identity_protesters + tactic, data = u1, weights = weight)
print(summary(m_u1_v)); print(summary(m_u1_p))

# Study 1 Israel: identity (0 white Jews, 1 Ethiopian, 2 Arab), tactic (0 march, 1 traffic, 2 garbage cans); weighted OLS
i1 <- isr_survey_wave1
i1$identity_protesters <- relevel(factor(i1$identity_protesters), ref = "0")
i1$tactic <- relevel(factor(i1$tactic), ref = "0")
m_i1_v <- lm(degree_violence ~ identity_protesters + tactic, data = i1, weights = weight)
m_i1_p <- lm(police_action_required ~ identity_protesters + tactic, data = i1, weights = weight)
print(summary(m_i1_v)); print(summary(m_i1_p))

# Study 2 US: black, group_goal, commitment indicators; no weight variable supplied -> unweighted OLS
u2 <- us_survey_wave2
m_u2_v <- lm(degree_violence ~ black + group_goal + commitment, data = u2)
m_u2_p <- lm(police_action_required ~ black + group_goal + commitment, data = u2)
print(summary(m_u2_v)); print(summary(m_u2_p))

i2 <- isr_survey_wave2
i2$identity_protesters <- relevel(factor(i2$identity_protesters), ref = "0")
m_i2_v <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = i2)
print(summary(m_i2_v))

cf <- function(m, n) unname(coef(m)[n])
out <- c(
  study1_us_black_perceived_violence = cf(m_u1_v, "identity_protesters1"),
  study1_us_black_police_action = cf(m_u1_p, "identity_protesters1"),
  study1_israel_ethiopian_perceived_violence = cf(m_i1_v, "identity_protesters1"),
  study1_israel_ethiopian_police_action = cf(m_i1_p, "identity_protesters1"),
  study1_israel_arab_perceived_violence = cf(m_i1_v, "identity_protesters2"),
  study1_israel_arab_police_action = cf(m_i1_p, "identity_protesters2"),
  study2_us_black_perceived_violence = cf(m_u2_v, "black"),
  study2_us_black_police_action = cf(m_u2_p, "black"),
  respondents_study1_us = nobs(m_u1_v),
  respondents_study1_israel = nobs(m_i1_v),
  respondents_study2_us = nobs(m_u2_v),
  respondents_study2_israel = nobs(m_i2_v)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
