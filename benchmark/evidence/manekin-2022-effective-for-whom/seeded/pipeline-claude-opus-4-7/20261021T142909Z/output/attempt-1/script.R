# Reproduce Table 1 and Table 2 coefficients from Manekin & Mitts (2022)

suppressPackageStartupMessages({
  library(estimatr)
  library(dplyr)
})

set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom/Replication/Data"

load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

# ---- Table 1 Panel A: US Study 1 ----
us1 <- us_survey_wave1
us1$identity_protesters <- relevel(factor(us1$identity_protesters), ref = "white")
us1$tactic <- relevel(factor(us1$tactic), ref = "march")

# Try common base levels; identify by looking at levels
# Fit perceived violence
m_us_pv <- lm(degree_violence ~ identity_protesters + tactic, data = us1, weights = weight)
m_us_pa <- lm(police_action_required ~ identity_protesters + tactic, data = us1, weights = weight)

# Find black coefficient
coefs_us_pv <- coef(m_us_pv)
coefs_us_pa <- coef(m_us_pa)
black_name_pv <- grep("identity_protesters", names(coefs_us_pv), value = TRUE)[1]
black_name_pa <- grep("identity_protesters", names(coefs_us_pa), value = TRUE)[1]

n_us1 <- nobs(m_us_pv)

# ---- Table 1 Panel B: Israel Study 1 ----
isr1 <- isr_survey_wave1
isr1$identity_protesters <- factor(isr1$identity_protesters)
# Set white as base
if ("white" %in% levels(isr1$identity_protesters)) {
  isr1$identity_protesters <- relevel(isr1$identity_protesters, ref = "white")
}
isr1$tactic <- factor(isr1$tactic)
if ("march" %in% levels(isr1$tactic)) {
  isr1$tactic <- relevel(isr1$tactic, ref = "march")
}

m_isr_pv <- lm(degree_violence ~ identity_protesters + tactic, data = isr1, weights = weight)
m_isr_pa <- lm(police_action_required ~ identity_protesters + tactic, data = isr1, weights = weight)

coefs_isr_pv <- coef(m_isr_pv)
coefs_isr_pa <- coef(m_isr_pa)

# Find ethiopian / arab
eth_pv <- grep("ethiop", names(coefs_isr_pv), ignore.case = TRUE, value = TRUE)[1]
arab_pv <- grep("arab", names(coefs_isr_pv), ignore.case = TRUE, value = TRUE)[1]
eth_pa <- grep("ethiop", names(coefs_isr_pa), ignore.case = TRUE, value = TRUE)[1]
arab_pa <- grep("arab", names(coefs_isr_pa), ignore.case = TRUE, value = TRUE)[1]

n_isr1 <- nobs(m_isr_pv)

# ---- Table 2 Panel A: US Study 2 ----
us2 <- us_survey_wave2
# black is already 0/1 indicator
m_us2_pv <- lm(degree_violence ~ black + group_goal + commitment, data = us2)
m_us2_pa <- lm(police_action_required ~ black + group_goal + commitment, data = us2)

n_us2 <- nobs(m_us2_pv)

# ---- Study 2 Israel sample size ----
n_isr2 <- nrow(isr_survey_wave2)

# ---- Emit results ----
cat(sprintf("RESULT:study1_us_black_perceived_violence=%.4f\n", coefs_us_pv[black_name_pv]))
cat(sprintf("RESULT:study1_us_black_police_action=%.4f\n", coefs_us_pa[black_name_pa]))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.4f\n", coefs_isr_pv[eth_pv]))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.4f\n", coefs_isr_pa[eth_pa]))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.4f\n", coefs_isr_pv[arab_pv]))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.4f\n", coefs_isr_pa[arab_pa]))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.4f\n", coef(m_us2_pv)["black"]))
cat(sprintf("RESULT:study2_us_black_police_action=%.4f\n", coef(m_us2_pa)["black"]))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nrow(us_survey_wave1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nrow(isr_survey_wave1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nrow(us_survey_wave2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", n_isr2))