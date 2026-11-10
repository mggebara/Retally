# Saccardo & Serra-Garcia (2023, AER) "Enabling or Limiting Cognitive Flexibility?
# Evidence of Demand for Moral Commitment" -- independent, blind reproduction of
# Table 2 (preference for information order) and Table 3 (advisor recommendations).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})

base <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/blind/2026-11-10-b/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(base, "choice_experiments.dta"))
d <- zap_labels(d)

# ---- Sample: four main Choice treatments ------------------------------------
# * drop the High Stakes (10-fold, 100-fold) robustness arms of Choice Free
# * AMT advisors: keep attentive advisors with consistent MPL responses
#   (selfishness measure non-missing; inconsistent switchers have it missing).
#   This reproduces the Table 1 Ns exactly (Choice Free 2,574; Incentive First
#   Costly 1,562; Quality First Costly 1,067; Professionals 712).
# * professionals: MPL not elicited, all kept.
m <- d %>%
  filter(Highx10 == 0, Highx100 == 0) %>%
  filter(professionals == 1 | (!is.na(selfish) & attentionpassed == 1))
cat("Sample counts by condition:\n"); print(table(m$condition))

# Variables
m <- m %>% mutate(
  prefer_inc_first = choicebefore,             # prefers to see incentive first
  prof        = professionalsfree,             # Choice Free -- Professionals
  inc_costly  = seeincentivecostly,            # See Incentive First Costly
  qual_costly = seequalitycostly,              # Assess Quality First Costly
  selfishness = stdalpha,                      # standardized MPL selfishness
  w2 = as.numeric(wave == "AMT-2"),            # wave dummies (AMT wave 1 = base;
  w3 = as.numeric(wave == "AMT-3"),            #  professionals have own indicator)
  prob = probabilistic_incentive,              # probabilistic incentives
  left = incentiveleft,                        # position of products on screen
  prob_left = probabilistic_incentive * incentiveleft,
  noconf = noconflict,
  notassigned = notgetyourchoice,
  pref_x_noconf = choicebefore * noconflict,
  pref_x_notass = choicebefore * notgetyourchoice,
  noconf_x_notass = noconflict * notgetyourchoice
)

ctrl <- "female + age + w2 + w3 + prob + left + prob_left"
hc3 <- function(fit) coeftest(fit, vcov = vcovHC(fit, type = "HC3"))

# ---- Table 2 -----------------------------------------------------------------
f1 <- as.formula(paste("prefer_inc_first ~ prof + inc_costly + qual_costly +", ctrl))
t2c1 <- lm(f1, data = m)
amt <- m %>% filter(prof == 0)
f2 <- as.formula(paste("prefer_inc_first ~ inc_costly + qual_costly + selfishness +", ctrl))
t2c2 <- lm(f2, data = amt)
f3 <- as.formula(paste("prefer_inc_first ~ inc_costly + qual_costly + selfishness +",
                       "inc_costly:selfishness + qual_costly:selfishness +", ctrl))
t2c3 <- lm(f3, data = amt)
cat("\nTable 2 col 1\n"); print(hc3(t2c1))
cat("\nTable 2 col 2\n"); print(hc3(t2c2))
cat("\nTable 2 col 3\n"); print(hc3(t2c3))

# ---- Table 3 -----------------------------------------------------------------
rhs3 <- paste("prefer_inc_first + noconf + pref_x_noconf + prof + inc_costly + qual_costly + incentiveB +", ctrl)
t3c1 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = m %>% filter(getyourchoice == 1))
t3c2 <- lm(as.formula(paste("recommendincentive ~", rhs3)), data = m %>% filter(getyourchoice == 0))
t3c3 <- lm(as.formula(paste("recommendincentive ~", rhs3,
                            "+ notassigned + pref_x_notass + noconf_x_notass")), data = m)
cat("\nTable 3 col 1\n"); print(hc3(t3c1))
cat("\nTable 3 col 2\n"); print(hc3(t3c2)); cat("N col2 =", nobs(t3c2), "\n")
cat("\nTable 3 col 3\n"); print(hc3(t3c3)); cat("N col3 =", nobs(t3c3), "\n")

# ---- Results -----------------------------------------------------------------
r <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
r("see_incentive_first_costly_table2_col1", coef(t2c1)[["inc_costly"]])
r("assess_quality_first_costly_table2_col1", coef(t2c1)[["qual_costly"]])
r("choice_free_professionals_table2_col1", coef(t2c1)[["prof"]])
r("selfishness_table2_col2", coef(t2c2)[["selfishness"]])
r("selfishness_table2_col3", coef(t2c3)[["selfishness"]])
r("see_incentive_first_costly_x_selfishness_table2_col3", coef(t2c3)[["inc_costly:selfishness"]])
r("see_quality_first_costly_x_selfishness_table2_col3", coef(t2c3)[["qual_costly:selfishness"]])
cat(sprintf("RESULT:n_obs_table2_col1=%d\n", nobs(t2c1)))
cat(sprintf("RESULT:n_obs_table2_cols2_3=%d\n", nobs(t2c2)))
r("prefer_see_incentive_first_assigned_table3_col1", coef(t3c1)[["prefer_inc_first"]])
r("prefer_see_incentive_first_not_assigned_table3_col2", coef(t3c2)[["prefer_inc_first"]])
r("prefer_see_incentive_first_x_not_assigned_table3_col3", coef(t3c3)[["pref_x_notass"]])
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(t3c1)))
