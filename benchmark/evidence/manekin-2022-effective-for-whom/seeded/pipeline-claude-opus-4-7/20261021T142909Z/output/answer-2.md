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

# Helper to safely relevel
safe_relevel <- function(f, ref) {
  f <- factor(f)
  if (ref %in% levels(f)) {
    f <- relevel(f, ref = ref)
  }
  f
}

# ---- Table 1 Panel A: US Study 1 ----
us1 <- us_survey_wave1
cat("US1 identity_protesters levels:", paste(levels(factor(us1$identity_protesters)), collapse=","), "\n")
cat("US1 tactic levels:", paste(levels(factor(us1$tactic)), collapse=","), "\n")

us1$identity_protesters <- factor(us1$identity_protesters)
# Try to find a white-ish baseline
white_candidates <- c("white", "White", "WHITE", "whites", "Whites")
ref_white_us <- intersect(white_candidates, levels(us1$identity_protesters))
if (length(ref_white_us) > 0) {
  us1$identity_protesters <- relevel(us1$identity_protesters, ref = ref_white_us[1])
}

us1$tactic <- factor(us1$tactic)
march_candidates <- c("march", "March", "MARCH")
ref_march_us <- intersect(march_candidates, levels(us1$tactic))
if (length(ref_march_us) > 0) {
  us1$tactic <- relevel(us1$tactic, ref = ref_march_us[1])
}

if ("weight" %in% names(us1)) {
  m_us_pv <- lm(degree_violence ~ identity_protesters + tactic, data = us1, weights = weight)
  m_us_pa <- lm(police_action_required ~ identity_protesters + tactic, data = us1, weights = weight)
} else {
  m_us_pv <- lm(degree_violence ~ identity_protesters + tactic, data = us1)
  m_us_pa <- lm(police_action_required ~ identity_protesters + tactic, data = us1)
}

coefs_us_pv <- coef(m_us_pv)
coefs_us_pa <- coef(m_us_pa)
black_name_pv <- grep("identity_protesters.*[Bb]lack|black", names(coefs_us_pv), value = TRUE)[1]
if (is.na(black_name_pv)) black_name_pv <- grep("identity_protesters", names(coefs_us_pv), value = TRUE)[1]
black_name_pa <- grep("identity_protesters.*[Bb]lack|black", names(coefs_us_pa), value = TRUE)[1]
if (is.na(black_name_pa)) black_name_pa <- grep("identity_protesters", names(coefs_us_pa), value = TRUE)[1]

n_us1 <- nobs(m_us_pv)

# ---- Table 1 Panel B: Israel Study 1 ----
isr1 <- isr_survey_wave1
cat("ISR1 identity_protesters levels:", paste(levels(factor(isr1$identity_protesters)), collapse=","), "\n")
cat("ISR1 tactic levels:", paste(levels(factor(isr1$tactic)), collapse=","), "\n")

isr1$identity_protesters <- factor(isr1$identity_protesters)
white_candidates_isr <- c("white", "White", "jewish", "Jewish", "ashkenazi", "Ashkenazi")
ref_white_isr <- intersect(white_candidates_isr, levels(isr1$identity_protesters))
if (length(ref_white_isr) > 0) {
  isr1$identity_protesters <- relevel(isr1$identity_protesters, ref = ref_white_isr[1])
}

isr1$tactic <- factor(isr1$tactic)
ref_march_isr <- intersect(march_candidates, levels(isr1$tactic))
if (length(ref_march_isr) > 0) {
  isr1$tactic <- relevel(isr1$tactic, ref = ref_march_isr[1])
}

if ("weight" %in% names(isr1)) {
  m_isr_pv <- lm(degree_violence ~ identity_protesters + tactic, data = isr1, weights = weight)
  m_isr_pa <- lm(police_action_required ~ identity_protesters + tactic, data = isr1, weights = weight)
} else {
  m_isr_pv <- lm(degree_violence ~ identity_protesters + tactic, data = isr1)
  m_isr_pa <- lm(police_action_required ~ identity_protesters + tactic, data = isr1)
}

coefs_isr_pv <- coef(m_isr_pv)
coefs_isr_pa <- coef(m_isr_pa)

eth_pv <- grep("ethiop", names(coefs_isr_pv), ignore.case = TRUE, value = TRUE)[1]
arab_pv <- grep("arab", names(coefs_isr_pv), ignore.case = TRUE, value = TRUE)[1]
eth_pa <- grep("ethiop", names(coefs_isr_pa), ignore.case = TRUE, value = TRUE)[1]
arab_pa <- grep("arab", names(coefs_isr_pa), ignore.case = TRUE, value = TRUE)[1]

n_isr1 <- nobs(m_isr_pv)

# ---- Table 2 Panel A: US Study 2 ----
us2 <- us_survey_wave2
m_us2_pv <- lm(degree_violence ~ black + group_goal + commitment, data = us2)
m_us2_pa <- lm(police_action_required ~ black + group_goal + commitment, data = us2)

n_us2 <- nobs(m_us2_pv)

# ---- Study 2 Israel sample size ----
n_isr2 <- nrow(isr_survey_wave2)

get_coef <- function(cf, nm) {
  if (is.null(nm) || is.na(nm)) return(NA_real_)
  as.numeric(cf[nm])
}

# ---- Emit results ----
cat(sprintf("RESULT:study1_us_black_perceived_violence=%.4f\n", get_coef(coefs_us_pv, black_name_pv)))
cat(sprintf("RESULT:study1_us_black_police_action=%.4f\n", get_coef(coefs_us_pa, black_name_pa)))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.4f\n", get_coef(coefs_isr_pv, eth_pv)))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.4f\n", get_coef(coefs_isr_pa, eth_pa)))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.4f\n", get_coef(coefs_isr_pv, arab_pv)))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.4f\n", get_coef(coefs_isr_pa, arab_pa)))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.4f\n", coef(m_us2_pv)["black"]))
cat(sprintf("RESULT:study2_us_black_police_action=%.4f\n", coef(m_us2_pa)["black"]))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nrow(us_survey_wave1)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nrow(isr_survey_wave1)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nrow(us_survey_wave2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", n_isr2))