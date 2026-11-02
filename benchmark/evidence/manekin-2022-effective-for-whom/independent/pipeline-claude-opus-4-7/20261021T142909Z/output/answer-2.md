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

safe_relevel <- function(x, patterns) {
  x <- factor(x)
  for (p in patterns) {
    hits <- grep(p, levels(x), ignore.case = TRUE, value = TRUE)
    if (length(hits) > 0) {
      return(relevel(x, ref = hits[1]))
    }
  }
  x
}

# Study 1 US
us1 <- us_survey_wave1
cat("US1 identity levels:", unique(as.character(us1$identity_protesters)), "\n", file=stderr())
cat("US1 tactic levels:", unique(as.character(us1$tactic)), "\n", file=stderr())
us1$identity_protesters <- safe_relevel(us1$identity_protesters, c("white"))
us1$tactic <- safe_relevel(us1$tactic, c("march", "street"))

cat("US1 identity levels after:", levels(us1$identity_protesters), "\n", file=stderr())
cat("US1 tactic levels after:", levels(us1$tactic), "\n", file=stderr())

m_us1_pv <- tryCatch(
  lm(degree_violence ~ identity_protesters + tactic, data = us1, weights = weight),
  error = function(e) lm(degree_violence ~ identity_protesters + tactic, data = us1)
)
m_us1_pa <- tryCatch(
  lm(police_action_required ~ identity_protesters + tactic, data = us1, weights = weight),
  error = function(e) lm(police_action_required ~ identity_protesters + tactic, data = us1)
)

cat("US1 PV coefs:\n", file=stderr()); print(coef(m_us1_pv))
cat("US1 PA coefs:\n", file=stderr()); print(coef(m_us1_pa))

get_coef <- function(m, pattern) {
  cf <- coef(m)
  idx <- grep(pattern, names(cf), ignore.case = TRUE)
  if (length(idx) == 0) return(NA)
  cf[idx[1]]
}

us1_black_pv <- get_coef(m_us1_pv, "black")
us1_black_pa <- get_coef(m_us1_pa, "black")

# Study 1 Israel
isr1 <- isr_survey_wave1
cat("ISR1 identity levels:", unique(as.character(isr1$identity_protesters)), "\n", file=stderr())
cat("ISR1 tactic levels:", unique(as.character(isr1$tactic)), "\n", file=stderr())

isr1$identity_protesters <- safe_relevel(isr1$identity_protesters, c("white", "jewish", "jew"))
isr1$tactic <- safe_relevel(isr1$tactic, c("march", "street"))

m_isr1_pv <- tryCatch(
  lm(degree_violence ~ identity_protesters + tactic, data = isr1, weights = weight),
  error = function(e) lm(degree_violence ~ identity_protesters + tactic, data = isr1)
)
m_isr1_pa <- tryCatch(
  lm(police_action_required ~ identity_protesters + tactic, data = isr1, weights = weight),
  error = function(e) lm(police_action_required ~ identity_protesters + tactic, data = isr1)
)

cat("ISR1 PV coefs:\n", file=stderr()); print(coef(m_isr1_pv))
cat("ISR1 PA coefs:\n", file=stderr()); print(coef(m_isr1_pa))

isr1_eth_pv <- get_coef(m_isr1_pv, "ethiop")
isr1_eth_pa <- get_coef(m_isr1_pa, "ethiop")
isr1_arab_pv <- get_coef(m_isr1_pv, "arab")
isr1_arab_pa <- get_coef(m_isr1_pa, "arab")

# Study 2 US
us2 <- us_survey_wave2
cat("US2 names:\n", file=stderr()); print(names(us2))

m_us2_pv <- tryCatch(
  lm(degree_violence ~ black + group_goal + commitment, data = us2),
  error = function(e) { cat("US2 PV error:", conditionMessage(e), "\n", file=stderr()); NULL }
)
m_us2_pa <- tryCatch(
  lm(police_action_required ~ black + group_goal + commitment, data = us2),
  error = function(e) { cat("US2 PA error:", conditionMessage(e), "\n", file=stderr()); NULL }
)

us2_black_pv <- if (!is.null(m_us2_pv)) get_coef(m_us2_pv, "^black") else NA
us2_black_pa <- if (!is.null(m_us2_pa)) get_coef(m_us2_pa, "^black") else NA

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