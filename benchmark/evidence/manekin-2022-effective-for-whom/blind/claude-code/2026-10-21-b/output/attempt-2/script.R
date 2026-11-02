## Manekin & Mitts (2022) "Effective for Whom?" -- independent, blind reproduction
## Tables 1 and 2 main effects: OLS of 0-10 outcomes on randomized treatment indicators.
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/manekin-2022-effective-for-whom/blind/2026-10-21-b/mount/manekin_2022_effective_for_whom/Replication/Data/"
load(paste0(D, "us_survey_wave1.rdata"))
load(paste0(D, "isr_survey_wave1.rdata"))
load(paste0(D, "us_survey_wave2.rdata"))
load(paste0(D, "isr_survey_wave2.rdata"))

res <- list()
fit <- function(f, d, w = NULL) {
  m <- if (is.null(w)) lm(f, data = d) else lm(f, data = d, weights = d[[w]])
  print(summary(m)); m
}

## ---- Study 1, US: identity_protesters 0 = white, 1 = Black; tactic 0 march, 1 traffic, 2 police cars
us1 <- us_survey_wave1
us1$black <- as.numeric(us1$identity_protesters == "1")
us1$traffic <- as.numeric(us1$tactic == "1")
us1$destroy <- as.numeric(us1$tactic == "2")
m <- fit(degree_violence ~ black + traffic + destroy, us1, "weight")
res$study1_us_black_perceived_violence <- coef(m)[["black"]]
n_us1 <- nobs(m)
m <- fit(police_action_required ~ black + traffic + destroy, us1, "weight")
res$study1_us_black_police_action <- coef(m)[["black"]]
cat("US1 nobs police:", nobs(m), "\n")

## ---- Study 1, Israel: identity 0 = white Jews, 1 = Ethiopian, 2 = Arab (order as listed in paper)
is1 <- isr_survey_wave1
is1$ethiopian <- as.numeric(is1$identity_protesters == "1")
is1$arab <- as.numeric(is1$identity_protesters == "2")
is1$traffic <- as.numeric(is1$tactic == "1")
is1$destroy <- as.numeric(is1$tactic == "2")
m <- fit(degree_violence ~ ethiopian + arab + traffic + destroy, is1, "weight")
res$study1_israel_ethiopian_perceived_violence <- coef(m)[["ethiopian"]]
res$study1_israel_arab_perceived_violence <- coef(m)[["arab"]]
n_is1 <- nobs(m)
m <- fit(police_action_required ~ ethiopian + arab + traffic + destroy, is1, "weight")
res$study1_israel_ethiopian_police_action <- coef(m)[["ethiopian"]]
res$study1_israel_arab_police_action <- coef(m)[["arab"]]
cat("ISR1 nobs police:", nobs(m), "\n")

## ---- Study 2, US (no survey weights in the file -> unweighted OLS)
us2 <- us_survey_wave2
m <- fit(degree_violence ~ black + group_goal + commitment, us2)
res$study2_us_black_perceived_violence <- coef(m)[["black"]]
n_us2 <- nobs(m)
m <- fit(police_action_required ~ black + group_goal + commitment, us2)
res$study2_us_black_police_action <- coef(m)[["black"]]
cat("US2 nobs police:", nobs(m), "\n")

## ---- Study 2, Israel (sample size only)
is2 <- isr_survey_wave2
is2$ethiopian <- as.numeric(is2$identity_protesters == "1")
is2$arab <- as.numeric(is2$identity_protesters == "2")
m <- fit(degree_violence ~ ethiopian + arab + group_goal + commitment, is2)
n_is2 <- nobs(m)
cat("ISR2 nobs police:", nobs(lm(police_action_required ~ ethiopian + arab + group_goal + commitment, is2)), "\n")

res$respondents_study1_us <- n_us1
res$respondents_study1_israel <- n_is1
res$respondents_study2_us <- n_us2
res$respondents_study2_israel <- n_is2

cat("DEVIATION: Study 2 regressions are unweighted (no weight variable in the Study 2 files); Israeli identity codes assumed 0=white,1=Ethiopian,2=Arab.\n")
for (nm in names(res)) cat(sprintf("RESULT:%s=%s\n", nm, format(res[[nm]], digits = 10)))
