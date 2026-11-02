suppressPackageStartupMessages({
  library(stats)
})
set.seed(42)

base <- "<repo>/.cache/datasets/manekin_2022_effective_for_whom/Replication/Data"
load(file.path(base, "us_survey_wave1.rdata"))
load(file.path(base, "isr_survey_wave1.rdata"))
load(file.path(base, "us_survey_wave2.rdata"))
load(file.path(base, "isr_survey_wave2.rdata"))

# Ensure categorical treatments are factors (keeping existing level order if already a factor)
to_fac <- function(x, pref = NULL) {
  if (is.factor(x)) return(x)
  if (is.numeric(x)) return(factor(x))
  lv <- unique(as.character(x))
  if (!is.null(pref)) {
    first <- lv[tolower(lv) %in% tolower(pref)]
    lv <- c(first, sort(setdiff(lv, first)))
  } else lv <- sort(lv)
  factor(x, levels = lv)
}

us1 <- us_survey_wave1
us1$identity_protesters <- to_fac(us1$identity_protesters, c("White", "0"))
us1$tactic <- to_fac(us1$tactic, c("March in streets", "march", "0"))

is1 <- isr_survey_wave1
if (!is.factor(is1$identity_protesters) && is.character(is1$identity_protesters)) {
  lv <- unique(is1$identity_protesters)
  ord <- c(lv[grepl("white|0", lv, ignore.case = TRUE)],
           lv[grepl("eth|1", lv, ignore.case = TRUE)],
           lv[grepl("arab|2", lv, ignore.case = TRUE)])
  ord <- unique(c(ord, lv))
  is1$identity_protesters <- factor(is1$identity_protesters, levels = ord)
} else {
  is1$identity_protesters <- to_fac(is1$identity_protesters)
}
is1$tactic <- to_fac(is1$tactic, c("March in streets", "march", "0"))

## Table 1 Panel A (US, weighted OLS)
degv_us <- lm(degree_violence ~ identity_protesters + tactic, data = us1, weights = weight)
police_us <- lm(police_action_required ~ identity_protesters + tactic, data = us1, weights = weight)

## Table 1 Panel B (Israel, weighted OLS)
degv_isr <- lm(degree_violence ~ identity_protesters + tactic, data = is1, weights = weight)
police_isr <- lm(police_action_required ~ identity_protesters + tactic, data = is1, weights = weight)

## Table 2 (Study 2), unweighted OLS
mod1_us2 <- lm(degree_violence ~ black + group_goal + commitment, data = us_survey_wave2)
mod3_us2 <- lm(police_action_required ~ black + group_goal + commitment, data = us_survey_wave2)
mod1_isr2 <- lm(degree_violence ~ identity_protesters + group_goal + commitment, data = isr_survey_wave2)

cat("Table 1 Panel A coefficients (perceived violence):\n"); print(coef(summary(degv_us)))
cat("Table 1 Panel B coefficients (perceived violence):\n"); print(coef(summary(degv_isr)))
cat("Table 2 Panel A coefficients (perceived violence):\n"); print(coef(summary(mod1_us2)))

cf <- function(m, i) unname(coef(m)[i])

cat(sprintf("RESULT:study1_us_black_perceived_violence=%.6f\n", cf(degv_us, 2)))
cat(sprintf("RESULT:study1_us_black_police_action=%.6f\n", cf(police_us, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_perceived_violence=%.6f\n", cf(degv_isr, 2)))
cat(sprintf("RESULT:study1_israel_ethiopian_police_action=%.6f\n", cf(police_isr, 2)))
cat(sprintf("RESULT:study1_israel_arab_perceived_violence=%.6f\n", cf(degv_isr, 3)))
cat(sprintf("RESULT:study1_israel_arab_police_action=%.6f\n", cf(police_isr, 3)))
cat(sprintf("RESULT:study2_us_black_perceived_violence=%.6f\n", unname(coef(mod1_us2)["black"])))
cat(sprintf("RESULT:study2_us_black_police_action=%.6f\n", unname(coef(mod3_us2)["black"])))
cat(sprintf("RESULT:respondents_study1_us=%d\n", nobs(degv_us)))
cat(sprintf("RESULT:respondents_study1_israel=%d\n", nobs(degv_isr)))
cat(sprintf("RESULT:respondents_study2_us=%d\n", nobs(mod1_us2)))
cat(sprintf("RESULT:respondents_study2_israel=%d\n", nobs(mod1_isr2)))