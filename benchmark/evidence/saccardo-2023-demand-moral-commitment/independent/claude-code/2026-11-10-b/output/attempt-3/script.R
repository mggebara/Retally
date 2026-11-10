# Saccardo & Serra-Garcia (2023 AER), "Enabling or Limiting Cognitive Flexibility?
# Evidence of Demand for Moral Commitment" -- independent reproduction of Tables 2 and 3.
set.seed(42)
suppressPackageStartupMessages({
  library(haven); library(sandwich); library(lmtest)
})

base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment"
d <- read_dta(file.path(base, "Data/Clean Data/choice_experiments.dta"))
d <- zap_labels(d)

# ---- Sample: four main Choice treatments (Table 1) ---------------------------
# Drop the high-stakes (10x, 100x) robustness variants of Choice Free; among AMT
# advisors keep those with consistent MPL answers (non-missing selfishness),
# following the paper's main-analysis exclusion (multiple switchers dropped).
# Professionals did not do the MPL and are all kept.
d <- subset(d, Highx10 == 0 & Highx100 == 0)
d <- subset(d, professionals == 1 | !is.na(stdalpha))
cat("Advisors by treatment (before age missings):\n"); print(table(d$treatment))

d$wave <- factor(d$wave)
d$selfishness <- d$stdalpha                   # standardized MPL count of incentivized recs
d$sic_x_self  <- d$seeincentivecostly * d$selfishness
d$sqc_x_self  <- d$seequalitycostly  * d$selfishness
d$prob_x_left <- d$probabilistic_incentive * d$incentiveleft

ctrl <- "female + age + wave + probabilistic_incentive + incentiveleft + prob_x_left"

hc3 <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC3"))
show <- function(m, lab) { cat("\n====", lab, " N =", nobs(m), " R2 =", round(summary(m)$r.squared, 3), "\n"); print(round(hc3(m), 4)) }

# ---- Table 2 --------------------------------------------------------------------
f1 <- as.formula(paste("choicebefore ~ professionals + seeincentivecostly + seequalitycostly +", ctrl))
t2c1 <- lm(f1, data = d)
show(t2c1, "Table 2 col 1")

damt <- subset(d, professionals == 0)
f2 <- as.formula(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness +", ctrl))
t2c2 <- lm(f2, data = damt)
show(t2c2, "Table 2 col 2")

f3 <- as.formula(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness + sic_x_self + sqc_x_self +", ctrl))
t2c3 <- lm(f3, data = damt)
show(t2c3, "Table 2 col 3")

# ---- Table 3 --------------------------------------------------------------------
d$notassigned <- 1 - d$getyourchoice
d$pref_x_noconf <- d$choicebefore * d$noconflict
d$pref_x_notass <- d$choicebefore * d$notassigned
d$noconf_x_notass <- d$noconflict * d$notassigned
rhs3 <- paste("choicebefore + noconflict + pref_x_noconf + professionals + seeincentivecostly + seequalitycostly + incentiveB +", ctrl)
t3c1 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = subset(d, getyourchoice == 1))
show(t3c1, "Table 3 col 1")
t3c2 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = subset(d, getyourchoice == 0))
show(t3c2, "Table 3 col 2")
t3c3 <- lm(as.formula(paste("recommendincentive ~", rhs3, "+ notassigned + pref_x_notass + noconf_x_notass")), data = d)
show(t3c3, "Table 3 col 3")

# ---- Results ----------------------------------------------------------------------
r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("see_incentive_first_costly_table2_col1", coef(t2c1)[["seeincentivecostly"]])
r("assess_quality_first_costly_table2_col1", coef(t2c1)[["seequalitycostly"]])
r("choice_free_professionals_table2_col1", coef(t2c1)[["professionals"]])
r("selfishness_table2_col2", coef(t2c2)[["selfishness"]])
r("selfishness_table2_col3", coef(t2c3)[["selfishness"]])
r("see_incentive_first_costly_x_selfishness_table2_col3", coef(t2c3)[["sic_x_self"]])
r("see_quality_first_costly_x_selfishness_table2_col3", coef(t2c3)[["sqc_x_self"]])
r("n_obs_table2_col1", nobs(t2c1))
r("n_obs_table2_cols2_3", nobs(t2c2))
r("prefer_see_incentive_first_assigned_table3_col1", coef(t3c1)[["choicebefore"]])
r("prefer_see_incentive_first_not_assigned_table3_col2", coef(t3c2)[["choicebefore"]])
r("prefer_see_incentive_first_x_not_assigned_table3_col3", coef(t3c3)[["pref_x_notass"]])
r("n_obs_table3_col1", nobs(t3c1))
