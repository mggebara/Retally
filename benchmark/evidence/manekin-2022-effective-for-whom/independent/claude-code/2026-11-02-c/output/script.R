# Independent reproduction: Manekin & Mitts (2022), Tables 1 and 2 (main effects)
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/independent/2026-11-02-c/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(d, "us_survey_wave1.rdata"))
load(paste0(d, "isr_survey_wave1.rdata"))
load(paste0(d, "us_survey_wave2.rdata"))
load(paste0(d, "isr_survey_wave2.rdata"))

res <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))

# ---- Study 1, US: outcome ~ Black + tactic dummies (base: white, march), survey weights, OLS
us1 <- us_survey_wave1
us1$black <- as.numeric(as.character(us1$identity_protesters) == "1")
us1$traffic <- as.numeric(as.character(us1$tactic) == "1")
us1$destroy <- as.numeric(as.character(us1$tactic) == "2")
m_us1_v <- lm(degree_violence ~ black + traffic + destroy, data = us1, weights = weight)
m_us1_p <- lm(police_action_required ~ black + traffic + destroy, data = us1, weights = weight)
print(summary(m_us1_v)); print(summary(m_us1_p))

# ---- Study 1, Israel: identity 0 white Jews, 1 Ethiopian, 2 Arab; tactic 0 march, 1 traffic, 2 garbage cans
is1 <- isr_survey_wave1
is1$eth <- as.numeric(as.character(is1$identity_protesters) == "1")
is1$arab <- as.numeric(as.character(is1$identity_protesters) == "2")
is1$traffic <- as.numeric(as.character(is1$tactic) == "1")
is1$destroy <- as.numeric(as.character(is1$tactic) == "2")
m_is1_v <- lm(degree_violence ~ eth + arab + traffic + destroy, data = is1, weights = weight)
m_is1_p <- lm(police_action_required ~ eth + arab + traffic + destroy, data = is1, weights = weight)
print(summary(m_is1_v)); print(summary(m_is1_p))

# ---- Study 2, US: outcome ~ black + group_goal + commitment (no weight variable in the data -> unweighted OLS)
us2 <- us_survey_wave2
m_us2_v <- lm(degree_violence ~ black + group_goal + commitment, data = us2)
m_us2_p <- lm(police_action_required ~ black + group_goal + commitment, data = us2)
print(summary(m_us2_v)); print(summary(m_us2_p))

# ---- Study 2, Israel (sample size only)
is2 <- isr_survey_wave2
is2$eth <- as.numeric(as.character(is2$identity_protesters) == "1")
is2$arab <- as.numeric(as.character(is2$identity_protesters) == "2")
m_is2_v <- lm(degree_violence ~ eth + arab + group_goal + commitment, data = is2)
print(summary(m_is2_v))

res("study1_us_black_perceived_violence", coef(m_us1_v)[["black"]])
res("study1_us_black_police_action", coef(m_us1_p)[["black"]])
res("study1_israel_ethiopian_perceived_violence", coef(m_is1_v)[["eth"]])
res("study1_israel_ethiopian_police_action", coef(m_is1_p)[["eth"]])
res("study1_israel_arab_perceived_violence", coef(m_is1_v)[["arab"]])
res("study1_israel_arab_police_action", coef(m_is1_p)[["arab"]])
res("study2_us_black_perceived_violence", coef(m_us2_v)[["black"]])
res("study2_us_black_police_action", coef(m_us2_p)[["black"]])
res("respondents_study1_us", nobs(m_us1_v))
res("respondents_study1_israel", nobs(m_is1_v))
res("respondents_study2_us", nobs(m_us2_v))
res("respondents_study2_israel", nobs(m_is2_v))
