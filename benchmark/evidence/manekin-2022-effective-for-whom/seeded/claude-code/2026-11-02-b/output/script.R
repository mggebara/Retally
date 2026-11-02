# Manekin & Mitts (2022) -- Table 1 (Study 1) and Table 2 (Study 2; replication code's table 4)
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/seeded/2026-11-02-b/mount/manekin_2022_effective_for_whom/Replication/Data"
load(file.path(D, "us_survey_wave1.rdata"))
load(file.path(D, "isr_survey_wave1.rdata"))
load(file.path(D, "us_survey_wave2.rdata"))
load(file.path(D, "isr_survey_wave2.rdata"))

# Table 1, Panel A (US, weighted OLS)
degv_us   <- lm(degree_violence ~ identity_protesters + tactic, data = us_survey_wave1, weights = weight)
police_us <- lm(police_action_required ~ identity_protesters + tactic, data = us_survey_wave1, weights = weight)
# Table 1, Panel B (Israel, weighted OLS)
degv_isr   <- lm(degree_violence ~ identity_protesters + tactic, data = isr_survey_wave1, weights = weight)
police_isr <- lm(police_action_required ~ identity_protesters + tactic, data = isr_survey_wave1, weights = weight)
# Table 2 (Study 2; unweighted OLS)
mod1    <- lm(degree_violence ~ black + group_goal + commitment, data = us_survey_wave2)
mod3    <- lm(police_action_required ~ black + group_goal + commitment, data = us_survey_wave2)
mod1_il <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = isr_survey_wave2)

print(summary(degv_us)); print(summary(police_us))
print(summary(degv_isr)); print(summary(police_isr))
print(summary(mod1)); print(summary(mod3)); print(summary(mod1_il))
cat("class identity_protesters US1:", class(us_survey_wave1$identity_protesters), "ISR1:", class(isr_survey_wave1$identity_protesters), "\n")

gc1 <- function(m, pat) { cf <- coef(m); nm <- grep(pat, names(cf), value = TRUE); stopifnot(length(nm) >= 1); cf[nm] }
isr_d <- coef(degv_isr)[grep("identity_protesters", names(coef(degv_isr)))]
isr_p <- coef(police_isr)[grep("identity_protesters", names(coef(police_isr)))]
stopifnot(length(isr_d) == 2, length(isr_p) == 2)
cat("Israel identity terms:", names(isr_d), "\n")

res <- c(
  study1_us_black_perceived_violence = unname(gc1(degv_us, "identity_protesters")[1]),
  study1_us_black_police_action = unname(gc1(police_us, "identity_protesters")[1]),
  study1_israel_ethiopian_perceived_violence = unname(isr_d[1]),
  study1_israel_ethiopian_police_action = unname(isr_p[1]),
  study1_israel_arab_perceived_violence = unname(isr_d[2]),
  study1_israel_arab_police_action = unname(isr_p[2]),
  study2_us_black_perceived_violence = unname(coef(mod1)["black"]),
  study2_us_black_police_action = unname(coef(mod3)["black"]),
  respondents_study1_us = nobs(degv_us),
  respondents_study1_israel = nobs(degv_isr),
  respondents_study2_us = nobs(mod1),
  respondents_study2_israel = nobs(mod1_il)
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
