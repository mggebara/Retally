# Retally blind independent reproduction: holman-2022-theresa-may-rally
# Table 4 (global country-quarter approval regression) and Table 2 (BES panel DiD).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-01-a/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4 ----------------
# DV: approval in the quarter following the attack quarter. The file holds only
# `lag_approval`; its timing (UK drop recorded at the Manchester quarter, 2017q2)
# shows it is the next-quarter approval aligned to the attack quarter.
# Attack: kill_16 = international terrorist attack with 16+ (i.e. more than 15) deaths.
# Woman executive: female_pres. Controls: GDP growth, logged inflation,
# DPI left-center-right executive placement (execrlc), election. Country (panel) FE.
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels()
g4 <- g %>% filter(!is.na(lag_approval), !is.na(kill_16), !is.na(female_pres), !is.na(growth),
                   !is.na(log_inflation), !is.na(execrlc), !is.na(election_qtr))
m4 <- feols(lag_approval ~ kill_16 + female_pres + kill_16:female_pres + growth + log_inflation +
              execrlc + election_qtr | country_code, data = g4, cluster = ~country_code)
print(summary(m4))
cat("Table4 panels:", length(unique(g4$country_code)), " attack quarters:", sum(g4$kill_16),
    " attack x woman:", sum(g4$kill_16 * g4$female_pres), "\n")
# OLS with dummies (point estimates identical to xtpcse without AR terms)
m4b <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr +
            factor(country_code), data = g4)
cat("lm check R2:", summary(m4b)$r.squared, "\n")

## ---------------- Table 2 ----------------
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c(id, wave, time, treatment1, likeMayW, bestPMW, white, gender, labour,
                             party_other, income, ideology2)) %>% zap_labels()
d <- d %>% mutate(likeMayW = ifelse(likeMayW > 10, NA, likeMayW),
                  female = as.integer(gender == 2))
ctrl <- "white + female + labour + party_other + income + ideology2"

# May likeability: OLS, wave fixed effects (time collinear with wave dummies;
# as in Stata, the last aliased wave dummy is dropped and time is kept).
dl <- d %>% filter(!is.na(likeMayW), !is.na(white), !is.na(female), !is.na(labour),
                   !is.na(party_other), !is.na(income), !is.na(ideology2))
fl <- as.formula(paste("likeMayW ~ treatment1 + time + treatment1:time + factor(wave) +", ctrl))
ml <- lm(fl, data = dl)
cl <- coef(ml)
print(summary(ml)$coefficients)
cat("like waves:\n"); print(table(dl$wave))

# May best PM: logistic regression, same specification
dp <- d %>% filter(!is.na(bestPMW), !is.na(white), !is.na(female), !is.na(labour),
                   !is.na(party_other), !is.na(income), !is.na(ideology2))
fp <- as.formula(paste("bestPMW ~ treatment1 + time + treatment1:time + factor(wave) +", ctrl))
mp <- glm(fp, data = dp, family = binomial(link = "logit"))
cp <- coef(mp)
print(summary(mp)$coefficients)
cat("bestPM waves:\n"); print(table(dp$wave))

cat(sprintf("RESULT:intl_attack_table4=%.6f\n", coef(m4)[["kill_16"]]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", coef(m4)[["kill_16:female_pres"]]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", cl[["treatment1:time"]]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", cl[["treatment1"]]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", cl[["time"]]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", cp[["treatment1:time"]]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", cp[["treatment1"]]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", cp[["time"]]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", nobs(ml)))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", nobs(mp)))
