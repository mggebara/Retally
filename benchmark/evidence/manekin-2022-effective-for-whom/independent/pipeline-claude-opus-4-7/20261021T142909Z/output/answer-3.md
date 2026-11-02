#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(fixest)
})

set.seed(42)

base_path <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom.script-free/Replication/Data"

load(file.path(base_path, "us_survey_wave1.rdata"))
load(file.path(base_path, "isr_survey_wave1.rdata"))
load(file.path(base_path, "us_survey_wave2.rdata"))
load(file.path(base_path, "isr_survey_wave2.rdata"))

# Study 1 US - identity 0=white, 1=black; tactic 0=march, 1=traffic, 2=destroy
us1 <- us_survey_wave1
us1$identity_protesters <- factor(us1$identity_protesters)
us1$tactic <- factor(us1$tactic)

m_us1_pv <- lm(degree_violence ~ identity_protesters + tactic, data = us1)
m_us1_pa <- lm(police_action_required ~ identity_protesters + tactic, data = us1)

cat("US1 PV coefs:\n", file=stderr()); print(coef(m_us1_pv))
cat("US1 PA coefs:\n", file=stderr()); print(coef(m_us1_pa))

us1_black_pv <- coef(m_us1_pv)["identity_protesters1"]
us1_black_pa <- coef(m_us1_pa)["identity_protesters1"]

# Study 1 Israel - identity 0=jewish, 1=?, 2=?
isr1 <- isr_survey_wave1
isr1$identity_protesters <- factor(isr1$identity_protesters)
isr1$tactic <- factor(isr1$tactic)

m_isr1_pv <- lm(degree_violence ~ identity_protesters + tactic, data = isr1)
m_isr1_pa <- lm(police_action_required ~ identity_protesters + tactic, data = isr1)

cat("ISR1 PV coefs:\n", file=stderr()); print(coef(m_isr1_pv))
cat("ISR1 PA coefs:\n", file=stderr()); print(coef(m_isr1_pa))

# Paper: Ethiopian PV=0.425, Arab PV=0.623
# Our coefs: identity_protesters1=0.425, identity_protesters2=0.623
# So 1=Ethiopian, 2=Arab (reference 0=Jewish)
isr1_eth_pv <- coef(m_isr1_pv)["identity_protesters1"]
isr1_eth_pa <- coef(m_isr1_pa)["identity_protesters1"]
isr1_arab_pv <- coef(m_isr1_pv)["identity_protesters2"]
isr1_arab_pa <- coef(m_isr1_pa)["identity_protesters2"]

# Study 2 US
us2 <- us_survey_wave2
m_us2_pv <- lm(degree_violence ~ black + group_goal + commitment, data = us2)
m_us2_pa <- lm(police_action_required ~ black + group_goal + commitment, data = us2)

us2_black_pv <- coef(m_us2_pv)["black"]
us2_black_pa <- coef(m_us2_pa)["black"]

n_us1 <- nrow(us_survey_wave1)
n_isr1 <- nrow(isr_survey_wave1)
n_us2 <- nrow(us_survey_wave2)
n_isr2 <- nrow(isr_survey_wave2)

fmt <- function(x) if (is.na(x)) "NA" else sprintf("%.4f", x)

cat(sprintf("RESULT:study1_us_black_perceived_violence=%s\n", fmt(us1_black_pv)))
cat(sprintf("RESULT:study1_us_black_police_action=%s\n", fmt(us1_black_pa)))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%s\n", fmt(isr1_eth_pv)))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%s\n", fmt(isr1_eth_pa)))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%s\n", fmt(isr1_arab_pv)))
cat(sprintf("RESULT:study1_israel_arab_police_action=%s\n", fmt(isr1_arab_pa)))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%s\n", fmt(us2_black_pv)))
cat(sprintf("RESULT:study2_us_black_police_action=%s\n", fmt(us2_black_pa)))
cat(sprintf("RESULT:respondents_study1_us=%d\n", n_us1))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", n_isr1))
cat(sprintf("RESULT:respondents_study2_us=%d\n", n_us2))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", n_isr2))