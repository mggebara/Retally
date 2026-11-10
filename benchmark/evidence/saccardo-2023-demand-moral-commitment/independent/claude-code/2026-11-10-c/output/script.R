# Independent reproduction: Saccardo & Serra-Garcia (2023, AER), Tables 2 and 3
# Linear probability models with HC3 robust standard errors.
suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

f <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-c/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta"
d <- as.data.frame(zap_labels(read_dta(f)))

# ---- Sample: the four main Choice treatments --------------------------------
# Drop the High Stakes robustness treatments (10-fold, 100-fold).
d <- d[d$Highx10 == 0 & d$Highx100 == 0, ]
# Among AMT advisors keep attentive advisors with consistent MPL responses
# (selfishness measure non-missing); professionals had no MPL.
d <- d[d$professionals == 1 | !is.na(d$stdalpha), ]
cat("Main-treatment advisors by condition:\n")
print(table(d$condition))

# ---- Variables ---------------------------------------------------------------
d$prefer_inc_first <- d$choicebefore            # prefers to see incentive first
d$prof            <- d$professionalsfree        # Choice Free - Professionals
d$inc_costly      <- d$seeincentivecostly       # See Incentive First Costly
d$qual_costly     <- d$seequalitycostly         # Assess Quality First Costly
d$selfishness     <- d$stdalpha                 # standardized MPL selfishness
d$not_assigned    <- 1 - d$getyourchoice        # not assigned preferred order
# Design-variation controls: the probabilistic-incentive and product-position
# randomization was run within AMT wave 2 only (paper fn. 14), so we use the
# dataset's wave-2 design indicators (incentiveshigh, incentiveshigh_incentiveleft,
# zero for professionals) rather than probabilistic_incentive, which is also 1 for
# every professional and would partial the professional contrast out.
controls <- "female + age + wave2 + wave3 + incentiveshigh + incentiveleft + incentiveshigh_incentiveleft"

hc3 <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC3"))

# ---- Table 2 -----------------------------------------------------------------
t2c1 <- lm(as.formula(paste("prefer_inc_first ~ prof + inc_costly + qual_costly +", controls)), data = d)
amt <- d[d$professionals == 0, ]
t2c2 <- lm(as.formula(paste("prefer_inc_first ~ inc_costly + qual_costly + selfishness +", controls)), data = amt)
t2c3 <- lm(as.formula(paste("prefer_inc_first ~ inc_costly + qual_costly + selfishness + inc_costly:selfishness + qual_costly:selfishness +", controls)), data = amt)
cat("\nTable 2 col 1\n"); print(hc3(t2c1)); cat("N =", nobs(t2c1), " R2 =", summary(t2c1)$r.squared, "\n")
cat("\nTable 2 col 2\n"); print(hc3(t2c2)); cat("N =", nobs(t2c2), " R2 =", summary(t2c2)$r.squared, "\n")
cat("\nTable 2 col 3\n"); print(hc3(t2c3)); cat("N =", nobs(t2c3), " R2 =", summary(t2c3)$r.squared, "\n")

# ---- Table 3 -----------------------------------------------------------------
rhs3 <- paste("recommendincentive ~ prefer_inc_first + noconflict + prefer_inc_first:noconflict +",
              "prof + inc_costly + qual_costly + incentiveB +", controls)
t3c1 <- lm(as.formula(rhs3), data = d[d$getyourchoice == 1, ])
t3c2 <- lm(as.formula(rhs3), data = d[d$getyourchoice == 0, ])
t3c3 <- lm(as.formula(paste(rhs3, "+ not_assigned + prefer_inc_first:not_assigned + noconflict:not_assigned")), data = d)
cat("\nTable 3 col 1\n"); print(hc3(t3c1)); cat("N =", nobs(t3c1), " R2 =", summary(t3c1)$r.squared, "\n")
cat("\nTable 3 col 2\n"); print(hc3(t3c2)); cat("N =", nobs(t3c2), " R2 =", summary(t3c2)$r.squared, "\n")
cat("\nTable 3 col 3\n"); print(hc3(t3c3)); cat("N =", nobs(t3c3), " R2 =", summary(t3c3)$r.squared, "\n")

# ---- Results -----------------------------------------------------------------
r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
cat("\n")
r("see_incentive_first_costly_table2_col1", coef(t2c1)[["inc_costly"]])
r("assess_quality_first_costly_table2_col1", coef(t2c1)[["qual_costly"]])
r("choice_free_professionals_table2_col1", coef(t2c1)[["prof"]])
r("selfishness_table2_col2", coef(t2c2)[["selfishness"]])
r("selfishness_table2_col3", coef(t2c3)[["selfishness"]])
r("see_incentive_first_costly_x_selfishness_table2_col3", coef(t2c3)[["inc_costly:selfishness"]])
r("see_quality_first_costly_x_selfishness_table2_col3", coef(t2c3)[["qual_costly:selfishness"]])
r("n_obs_table2_col1", nobs(t2c1))
r("n_obs_table2_cols2_3", nobs(t2c2))
r("prefer_see_incentive_first_assigned_table3_col1", coef(t3c1)[["prefer_inc_first"]])
r("prefer_see_incentive_first_not_assigned_table3_col2", coef(t3c2)[["prefer_inc_first"]])
r("prefer_see_incentive_first_x_not_assigned_table3_col3", coef(t3c3)[["prefer_inc_first:not_assigned"]])
r("n_obs_table3_col1", nobs(t3c1))
