# Manekin & Mitts (2022) -- blind independent reproduction of Tables 1-2 (selected cells)
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-11-02-c/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(d, "us_survey_wave1.rdata"))
load(paste0(d, "isr_survey_wave1.rdata"))
load(paste0(d, "us_survey_wave2.rdata"))
load(paste0(d, "isr_survey_wave2.rdata"))

res <- list()

# ---- Study 1, US: identity (0 white, 1 Black) + tactic (0 march, 1 traffic, 2 destroy); weighted OLS
u1 <- us_survey_wave1
u1$black   <- as.numeric(as.character(u1$identity_protesters) == "1")
u1$traffic <- as.numeric(as.character(u1$tactic) == "1")
u1$destroy <- as.numeric(as.character(u1$tactic) == "2")
m <- lm(degree_violence ~ black + traffic + destroy, data = u1, weights = weight)
res$study1_us_black_perceived_violence <- coef(m)["black"]
res$respondents_study1_us <- nobs(m)
m <- lm(police_action_required ~ black + traffic + destroy, data = u1, weights = weight)
res$study1_us_black_police_action <- coef(m)["black"]
cat("US S1 nobs police:", nobs(m), "\n")

# ---- Study 1, Israel: identity (0 white Jews, 1 Ethiopian, 2 Arab) + tactic; weighted OLS
i1 <- isr_survey_wave1
i1$eth     <- as.numeric(as.character(i1$identity_protesters) == "1")
i1$arab    <- as.numeric(as.character(i1$identity_protesters) == "2")
i1$traffic <- as.numeric(as.character(i1$tactic) == "1")
i1$destroy <- as.numeric(as.character(i1$tactic) == "2")
m <- lm(degree_violence ~ eth + arab + traffic + destroy, data = i1, weights = weight)
res$study1_israel_ethiopian_perceived_violence <- coef(m)["eth"]
res$study1_israel_arab_perceived_violence <- coef(m)["arab"]
res$respondents_study1_israel <- nobs(m)
m <- lm(police_action_required ~ eth + arab + traffic + destroy, data = i1, weights = weight)
res$study1_israel_ethiopian_police_action <- coef(m)["eth"]
res$study1_israel_arab_police_action <- coef(m)["arab"]
cat("ISR S1 nobs police:", nobs(m), "\n")

# ---- Study 2, US: black + group_goal + commitment; OLS (no weights in file)
u2 <- us_survey_wave2
m <- lm(degree_violence ~ black + group_goal + commitment, data = u2)
res$study2_us_black_perceived_violence <- coef(m)["black"]
res$respondents_study2_us <- nobs(m)
m <- lm(police_action_required ~ black + group_goal + commitment, data = u2)
res$study2_us_black_police_action <- coef(m)["black"]
cat("US S2 nobs police:", nobs(m), "\n")

# ---- Study 2, Israel: sample size of Table 2 Panel B regressions
i2 <- isr_survey_wave2
i2$eth  <- as.numeric(as.character(i2$identity_protesters) == "1")
i2$arab <- as.numeric(as.character(i2$identity_protesters) == "2")
m <- lm(degree_violence ~ eth + arab + group_goal + commitment, data = i2)
res$respondents_study2_israel <- nobs(m)

for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(res[[n]])))
