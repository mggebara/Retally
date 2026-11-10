# Saccardo & Serra-Garcia (2023 AER) -- independent blind reproduction of Table 2 and Table 3
# Linear probability models with HC3 robust standard errors.
suppressPackageStartupMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D, "choice_experiments.dta"))
d <- zap_labels(d)

# Main Choice treatments (Table 1): Choice Free (AMT), Choice Free--Professionals,
# Incentive First Costly, Quality First Costly. Drop the High-Stakes robustness arms.
# Following the preregistration, AMT advisors with inconsistent MPL responses
# (multiple switching -> missing selfishness measure) are excluded; professionals
# had no MPL and are kept.
m <- d %>% filter(Highx10 == 0, Highx100 == 0) %>%
  filter(professionals == 1 | !is.na(alphavaluefinal))
cat("Main sample by treatment (0=Free,1=Prof,2=IncCostly,3=QualCostly):\n"); print(table(m$treatment))

controls <- "female + age + wave2 + wave3 + probabilistic_incentive + incentiveleft + incentiveshigh_incentiveleft"

fit <- function(f, data) {
  mod <- lm(as.formula(f), data = data)
  V <- vcovHC(mod, type = "HC3")
  ct <- coeftest(mod, vcov. = V)
  list(mod = mod, ct = ct, n = nobs(mod), r2 = summary(mod)$r.squared)
}
show <- function(x, lab) { cat("\n==", lab, " N =", x$n, " R2 =", round(x$r2, 3), "\n"); print(round(x$ct, 4)) }

# ---- Table 2: preference to see incentive first ----
f1 <- paste("choicebefore ~ seeincentivecostly + seequalitycostly + professionalsfree +", controls)
t2c1 <- fit(f1, m)
amt <- m %>% filter(professionals == 0)
f2 <- paste("choicebefore ~ seeincentivecostly + seequalitycostly + stdalpha +", controls)
t2c2 <- fit(f2, amt)
f3 <- paste("choicebefore ~ seeincentivecostly + seequalitycostly + stdalpha + seeincentivecostly:stdalpha + seequalitycostly:stdalpha +", controls)
t2c3 <- fit(f3, amt)
show(t2c1, "Table 2 col 1"); show(t2c2, "Table 2 col 2"); show(t2c3, "Table 2 col 3")

# ---- Table 3: recommend incentivized product ----
base3 <- paste("recommendincentive ~ choicebefore + noconflict + choicebefore:noconflict + professionalsfree + seeincentivecostly + seequalitycostly + incentiveB +", controls)
t3c1 <- fit(base3, m %>% filter(getyourchoice == 1))
t3c2 <- fit(base3, m %>% filter(getyourchoice == 0))
f33 <- paste(base3, "+ notgetyourchoice + choicebefore:notgetyourchoice + noconflict:notgetyourchoice")
t3c3 <- fit(f33, m)
show(t3c1, "Table 3 col 1"); show(t3c2, "Table 3 col 2"); show(t3c3, "Table 3 col 3")

b <- function(x, nm) unname(coef(x$mod)[nm])
cat("\n")
cat(sprintf("RESULT:see_incentive_first_costly_table2_col1=%.6f\n", b(t2c1, "seeincentivecostly")))
cat(sprintf("RESULT:assess_quality_first_costly_table2_col1=%.6f\n", b(t2c1, "seequalitycostly")))
cat(sprintf("RESULT:choice_free_professionals_table2_col1=%.6f\n", b(t2c1, "professionalsfree")))
cat(sprintf("RESULT:selfishness_table2_col2=%.6f\n", b(t2c2, "stdalpha")))
cat(sprintf("RESULT:selfishness_table2_col3=%.6f\n", b(t2c3, "stdalpha")))
cat(sprintf("RESULT:see_incentive_first_costly_x_selfishness_table2_col3=%.6f\n", b(t2c3, "seeincentivecostly:stdalpha")))
cat(sprintf("RESULT:see_quality_first_costly_x_selfishness_table2_col3=%.6f\n", b(t2c3, "seequalitycostly:stdalpha")))
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", t2c1$n))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", t2c2$n))
cat(sprintf("RESULT:prefer_see_incentive_first_assigned_table3_col1=%.6f\n", b(t3c1, "choicebefore")))
cat(sprintf("RESULT:prefer_see_incentive_first_not_assigned_table3_col2=%.6f\n", b(t3c2, "choicebefore")))
cat(sprintf("RESULT:prefer_see_incentive_first_x_not_assigned_table3_col3=%.6f\n", b(t3c3, "choicebefore:notgetyourchoice")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", t3c1$n))
