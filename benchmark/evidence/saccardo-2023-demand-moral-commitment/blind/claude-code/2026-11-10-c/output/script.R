# Saccardo & Serra-Garcia (2023, AER) -- independent blind reproduction of
# Table 2 (preference for information order) and Table 3 (recommendations).
suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
})
set.seed(42)

p <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-c/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/choice_experiments.dta"
d <- as.data.frame(zap_labels(read_dta(p)))

# ---- Sample: the four main Choice treatments --------------------------------
# * Drop the High Stakes (10-fold, 100-fold) robustness treatments.
# * AMT advisors: keep attentive advisors with a consistent MPL (non-missing
#   moral-cost measure), following the paper's preregistered exclusion.
# * Professionals: MPL not elicited, all kept.
d <- d[d$Highx10 == 0 & d$Highx100 == 0, ]
d <- d[d$professionalsfree == 1 | !is.na(d$alphavaluefinal), ]
cat("Main-treatment sample by condition:\n"); print(table(d$condition))

# ---- Variables ----------------------------------------------------------------
d$prof        <- d$professionalsfree          # Choice Free -- Professionals
d$inc_costly  <- d$seeincentivecostly         # See Incentive First Costly
d$qual_costly <- d$seequalitycostly           # Assess Quality First Costly
d$wave_amt2   <- as.numeric(d$wave == "AMT-2")
d$wave_amt3   <- as.numeric(d$wave == "AMT-3")
d$wave_prof   <- as.numeric(d$wave == "Prolific/CloudResearch")  # collinear with prof
d$prob        <- d$probabilistic_incentive    # probabilistic incentives
d$left        <- d$incentiveleft              # position of products on screen
d$prob_left   <- d$prob * d$left              # probabilistic x position
d$selfish_z   <- d$stdalpha                   # standardized MPL selfishness
d$inc_costly_x_self  <- d$inc_costly * d$selfish_z
d$qual_costly_x_self <- d$qual_costly * d$selfish_z
d$prefer_inc  <- d$choicebefore               # Prefer to See Incentive First
d$not_assigned <- d$notgetyourchoice          # Not Assigned Preference
d$pref_x_notassigned <- d$prefer_inc * d$not_assigned
d$nocon_x_pref <- d$noconflict * d$prefer_inc
d$nocon_x_notassigned <- d$noconflict * d$not_assigned

controls <- "female + age + wave_amt2 + wave_amt3 + wave_prof + prob + left + prob_left"

fit <- function(f, data) {
  m <- lm(as.formula(f), data = data)
  V <- vcovHC(m, type = "HC3")
  ct <- coeftest(m, vcov. = V)
  print(ct)
  cat("N =", nobs(m), " R2 =", summary(m)$r.squared, "\n\n")
  list(m = m, ct = ct)
}

# ---- Table 2 --------------------------------------------------------------------
cat("== Table 2 col 1 ==\n")
t2c1 <- fit(paste("prefer_inc ~ prof + inc_costly + qual_costly +", controls), d)
amt <- d[d$prof == 0, ]
cat("== Table 2 col 2 ==\n")
t2c2 <- fit(paste("prefer_inc ~ inc_costly + qual_costly + selfish_z +", controls), amt)
cat("== Table 2 col 3 ==\n")
t2c3 <- fit(paste("prefer_inc ~ inc_costly + qual_costly + selfish_z + inc_costly_x_self + qual_costly_x_self +",
                  controls), amt)

# ---- Table 3 --------------------------------------------------------------------
rhs3 <- paste("prefer_inc + noconflict + nocon_x_pref + prof + inc_costly + qual_costly + incentiveB +", controls)
cat("== Table 3 col 1 (assigned preference) ==\n")
t3c1 <- fit(paste("recommendincentive ~", rhs3), d[d$getyourchoice == 1, ])
cat("== Table 3 col 2 (not assigned preference) ==\n")
t3c2 <- fit(paste("recommendincentive ~", rhs3), d[d$getyourchoice == 0, ])
cat("== Table 3 col 3 (both) ==\n")
t3c3 <- fit(paste("recommendincentive ~", rhs3,
                  "+ not_assigned + pref_x_notassigned + nocon_x_notassigned"), d)

cf <- function(x, v) unname(coef(x$m)[v])
res <- c(
  see_incentive_first_costly_table2_col1 = cf(t2c1, "inc_costly"),
  assess_quality_first_costly_table2_col1 = cf(t2c1, "qual_costly"),
  choice_free_professionals_table2_col1 = cf(t2c1, "prof"),
  selfishness_table2_col2 = cf(t2c2, "selfish_z"),
  selfishness_table2_col3 = cf(t2c3, "selfish_z"),
  see_incentive_first_costly_x_selfishness_table2_col3 = cf(t2c3, "inc_costly_x_self"),
  see_quality_first_costly_x_selfishness_table2_col3 = cf(t2c3, "qual_costly_x_self"),
  n_obs_table2_col1 = nobs(t2c1$m),
  n_obs_table2_cols2_3 = nobs(t2c2$m),
  prefer_see_incentive_first_assigned_table3_col1 = cf(t3c1, "prefer_inc"),
  prefer_see_incentive_first_not_assigned_table3_col2 = cf(t3c2, "prefer_inc"),
  prefer_see_incentive_first_x_not_assigned_table3_col3 = cf(t3c3, "pref_x_notassigned"),
  n_obs_table3_col1 = nobs(t3c1$m)
)
for (n in names(res)) cat(sprintf("RESULT:%s=%.6f\n", n, res[[n]]))
