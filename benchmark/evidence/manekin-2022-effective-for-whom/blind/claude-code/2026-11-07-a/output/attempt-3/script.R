# Manekin & Mitts (2022), "Effective for Whom?" -- blind independent reproduction
# Table 1 (Study 1) and Table 2 (Study 2): OLS of outcomes on treatment indicators.
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-07-a/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(D, "us_survey_wave1.rdata"))
load(paste0(D, "isr_survey_wave1.rdata"))
load(paste0(D, "us_survey_wave2.rdata"))
load(paste0(D, "isr_survey_wave2.rdata"))

fit <- function(f, d, w = NULL) {
  m <- if (is.null(w)) lm(f, data = d) else lm(f, data = d, weights = d[[w]])
  print(summary(m)); m
}

# ---- Study 1, US: identity 0 = white, 1 = Black; tactic 0 = march, 1 = shut down traffic, 2 = destroy police cars
us1 <- us_survey_wave1
us1$black   <- as.numeric(as.character(us1$identity_protesters) == "1")
us1$traffic <- as.numeric(as.character(us1$tactic) == "1")
us1$destroy <- as.numeric(as.character(us1$tactic) == "2")
m_us1_v <- fit(degree_violence ~ black + traffic + destroy, us1, "weight")
m_us1_p <- fit(police_action_required ~ black + traffic + destroy, us1, "weight")

# ---- Study 1, Israel: identity 0 = white Jews, 1 = Ethiopian, 2 = Arab; tactic 0 march, 1 traffic, 2 garbage cans
is1 <- isr_survey_wave1
is1$eth     <- as.numeric(as.character(is1$identity_protesters) == "1")
is1$arab    <- as.numeric(as.character(is1$identity_protesters) == "2")
is1$traffic <- as.numeric(as.character(is1$tactic) == "1")
is1$destroy <- as.numeric(as.character(is1$tactic) == "2")
m_is1_v <- fit(degree_violence ~ eth + arab + traffic + destroy, is1, "weight")
m_is1_p <- fit(police_action_required ~ eth + arab + traffic + destroy, is1, "weight")

# ---- Study 2, US (no survey weight in the file: unweighted OLS)
us2 <- us_survey_wave2
m_us2_v <- fit(degree_violence ~ black + group_goal + commitment, us2)
m_us2_p <- fit(police_action_required ~ black + group_goal + commitment, us2)

# ---- Study 2, Israel (sample size only; unweighted)
is2 <- isr_survey_wave2
is2$eth  <- as.numeric(as.character(is2$identity_protesters) == "1")
is2$arab <- as.numeric(as.character(is2$identity_protesters) == "2")
m_is2_v <- fit(degree_violence ~ eth + arab + group_goal + commitment, is2)

out <- c(
  study1_us_black_perceived_violence        = unname(coef(m_us1_v)["black"]),
  study1_us_black_police_action             = unname(coef(m_us1_p)["black"]),
  study1_israel_ethiopian_perceived_violence = unname(coef(m_is1_v)["eth"]),
  study1_israel_ethiopian_police_action      = unname(coef(m_is1_p)["eth"]),
  study1_israel_arab_perceived_violence      = unname(coef(m_is1_v)["arab"]),
  study1_israel_arab_police_action           = unname(coef(m_is1_p)["arab"]),
  study2_us_black_perceived_violence        = unname(coef(m_us2_v)["black"]),
  study2_us_black_police_action             = unname(coef(m_us2_p)["black"]),
  respondents_study1_us     = nobs(m_us1_v),
  respondents_study1_israel = nobs(m_is1_v),
  respondents_study2_us     = nobs(m_us2_v),
  respondents_study2_israel = nobs(m_is2_v)
)
for (n in names(out)) cat(sprintf("RESULT:%s=%s\n", n, format(out[[n]], digits = 10)))
