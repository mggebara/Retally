# Saccardo & Serra-Garcia (2023 AER), Tables 2 and 3 -- independent, blind reproduction
suppressPackageStartupMessages({library(haven); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-a/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- as.data.frame(zap_labels(read_dta(paste0(D, "choice_experiments.dta"))))

# Main Choice treatments (Table 1): Choice Free (AMT), Choice Free--Professionals,
# Incentive First Costly, Quality First Costly.  Drop the High Stakes robustness
# treatments (10-fold, 100-fold).  For AMT advisors keep only those with a consistent
# MPL (moral cost) measure (multiple switchers have a missing selfishness score), as
# the paper's preregistered main-analysis restriction; professionals had no MPL.
d$highstakes <- d$Highx10 == 1 | d$Highx100 == 1
m <- d[!d$highstakes & (d$professionalsfree == 1 | !is.na(d$alphavaluefinal)), ]
cat("Main sample rows:", nrow(m), "\n"); print(table(m$condition))

# Controls: gender, age, wave dummies (AMT-1 omitted; the professionals' wave is
# collinear with the Professionals indicator), probabilistic incentives, position of
# products (incentivized product on the left), and probabilistic x position.
m$prob_x_left <- m$probabilistic_incentive * m$incentiveleft
ctrl <- "female + age + wave2 + wave3 + probabilistic_incentive + incentiveleft + prob_x_left"
m$selfishness <- m$stdalpha
m$sic_x_self <- m$seeincentivecostly * m$selfishness
m$sqc_x_self <- m$seequalitycostly * m$selfishness

hc3 <- function(f) { ct <- coeftest(f, vcov. = vcovHC(f, type = "HC3")); print(ct); ct }

# ---- Table 2 ----
f1 <- lm(as.formula(paste("choicebefore ~ professionalsfree + seeincentivecostly + seequalitycostly +", ctrl)), data = m)
cat("\nTable 2 col 1\n"); t1 <- hc3(f1); cat("N =", nobs(f1), "R2 =", summary(f1)$r.squared, "\n")
amt <- m[m$professionalsfree == 0, ]
f2 <- lm(as.formula(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness +", ctrl)), data = amt)
cat("\nTable 2 col 2\n"); t2 <- hc3(f2); cat("N =", nobs(f2), "R2 =", summary(f2)$r.squared, "\n")
f3 <- lm(as.formula(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness + sic_x_self + sqc_x_self +", ctrl)), data = amt)
cat("\nTable 2 col 3\n"); t3 <- hc3(f3); cat("N =", nobs(f3), "R2 =", summary(f3)$r.squared, "\n")

# ---- Table 3 ----
rhs3 <- paste("choicebefore + noconflict + choicebeforenoconflict + professionalsfree + seeincentivecostly + seequalitycostly + incentiveB +", ctrl)
g1 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = m[m$getyourchoice == 1, ])
cat("\nTable 3 col 1\n"); s1 <- hc3(g1); cat("N =", nobs(g1), "R2 =", summary(g1)$r.squared, "\n")
g2 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = m[m$getyourchoice == 0, ])
cat("\nTable 3 col 2\n"); s2 <- hc3(g2); cat("N =", nobs(g2), "R2 =", summary(g2)$r.squared, "\n")
g3 <- lm(as.formula(paste("recommendincentive ~", rhs3, "+ notgetyourchoice + choicebeforenotgetyourchoice + notgetyourchoicenoconflict")), data = m)
cat("\nTable 3 col 3\n"); s3 <- hc3(g3); cat("N =", nobs(g3), "R2 =", summary(g3)$r.squared, "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("see_incentive_first_costly_table2_col1", coef(f1)["seeincentivecostly"])
r("assess_quality_first_costly_table2_col1", coef(f1)["seequalitycostly"])
r("choice_free_professionals_table2_col1", coef(f1)["professionalsfree"])
r("selfishness_table2_col2", coef(f2)["selfishness"])
r("selfishness_table2_col3", coef(f3)["selfishness"])
r("see_incentive_first_costly_x_selfishness_table2_col3", coef(f3)["sic_x_self"])
r("see_quality_first_costly_x_selfishness_table2_col3", coef(f3)["sqc_x_self"])
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", nobs(f1)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", nobs(f2)))
r("prefer_see_incentive_first_assigned_table3_col1", coef(g1)["choicebefore"])
r("prefer_see_incentive_first_not_assigned_table3_col2", coef(g2)["choicebefore"])
r("prefer_see_incentive_first_x_not_assigned_table3_col3", coef(g3)["choicebeforenotgetyourchoice"])
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(g1)))
