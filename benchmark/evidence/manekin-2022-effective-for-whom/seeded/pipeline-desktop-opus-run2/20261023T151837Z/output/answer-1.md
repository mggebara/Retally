set.seed(42)

base_dir <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom"
load(file.path(base_dir, "Replication/Data/us_survey_wave1.rdata"))
load(file.path(base_dir, "Replication/Data/isr_survey_wave1.rdata"))
load(file.path(base_dir, "Replication/Data/us_survey_wave2.rdata"))
load(file.path(base_dir, "Replication/Data/isr_survey_wave2.rdata"))

us1 <- as.data.frame(us_survey_wave1)
isr1 <- as.data.frame(isr_survey_wave1)
us2 <- as.data.frame(us_survey_wave2)
isr2 <- as.data.frame(isr_survey_wave2)

to_fac <- function(x) {
  if (is.factor(x)) return(droplevels(x))
  if (inherits(x, "haven_labelled")) x <- as.numeric(x)
  factor(x)
}

us1$id_f <- to_fac(us1$identity_protesters)
us1$tac_f <- to_fac(us1$tactic)
isr1$id_f <- to_fac(isr1$identity_protesters)
isr1$tac_f <- to_fac(isr1$tactic)
isr2$id_f <- to_fac(isr2$identity_protesters)

num <- function(x) {
  if (is.factor(x)) return(as.numeric(as.character(x)))
  as.numeric(x)
}
for (v in c("degree_violence", "police_action_required", "recall_violence2")) {
  us1[[v]] <- num(us1[[v]]); isr1[[v]] <- num(isr1[[v]])
  us2[[v]] <- num(us2[[v]]); isr2[[v]] <- num(isr2[[v]])
}
us1$weight <- as.numeric(us1$weight)
isr1$weight <- as.numeric(isr1$weight)

## Table 1, Panel A (US, weighted OLS)
us_degv <- lm(degree_violence ~ id_f + tac_f, data = us1, weights = weight)
us_police <- lm(police_action_required ~ id_f + tac_f, data = us1, weights = weight)

## Table 1, Panel B (Israel, weighted OLS)
isr_degv <- lm(degree_violence ~ id_f + tac_f, data = isr1, weights = weight)
isr_police <- lm(police_action_required ~ id_f + tac_f, data = isr1, weights = weight)

## Table 2 (study 2), Panel A (US, unweighted OLS)
us2$black_n <- num(us2$black)
us2$group_goal_n <- num(us2$group_goal)
us2$commitment_n <- num(us2$commitment)
us2_degv <- lm(degree_violence ~ black_n + group_goal_n + commitment_n, data = us2)
us2_police <- lm(police_action_required ~ black_n + group_goal_n + commitment_n, data = us2)

## Table 2, Panel B (Israel)
isr2$group_goal_n <- num(isr2$group_goal)
isr2$commitment_n <- num(isr2$commitment)
isr2_degv <- lm(degree_violence ~ id_f + group_goal_n + commitment_n, data = isr2)

cf <- function(m, i) unname(coef(m)[i])
se <- function(m, i) unname(sqrt(diag(vcov(m)))[i])

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", cf(us_degv, 2)))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", cf(us_police, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", cf(isr_degv, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", cf(isr_police, 2)))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", cf(isr_degv, 3)))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", cf(isr_police, 3)))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", cf(us2_degv, "black_n")))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", cf(us2_police, "black_n")))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nrow(us1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nrow(isr1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nrow(us2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", nrow(isr2)))

## Supplementary diagnostics (SEs and model N)
cat(sprintf("RESULT:study1_us_black_perceived_violence_se=%.6f\n", se(us_degv, 2)))
cat(sprintf("RESULT:study1_us_black_police_action_se=%.6f\n", se(us_police, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence_se=%.6f\n", se(isr_degv, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action_se=%.6f\n", se(isr_police, 2)))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence_se=%.6f\n", se(isr_degv, 3)))
cat(sprintf("RESULT:study1_israel_arab_police_action_se=%.6f\n", se(isr_police, 3)))
cat(sprintf("RESULT:study2_us_black_perceived_violence_se=%.6f\n", se(us2_degv, "black_n")))
cat(sprintf("RESULT:study2_us_black_police_action_se=%.6f\n", se(us2_police, "black_n")))
cat(sprintf("RESULT:study1_us_nobs_perceived_violence=%d\n", nobs(us_degv)))
cat(sprintf("RESULT:study1_israel_nobs_perceived_violence=%d\n", nobs(isr_degv)))
cat(sprintf("RESULT:study2_us_nobs_perceived_violence=%d\n", nobs(us2_degv)))
cat(sprintf("RESULT:study2_us_nobs_police_action=%d\n", nobs(us2_police)))
cat(sprintf("RESULT:study2_israel_nobs_perceived_violence=%d\n", nobs(isr2_degv)))
