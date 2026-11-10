# Saccardo & Serra-Garcia (2023, AER) -- independent reproduction of Table 2 and Table 3 (selected entries)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/saccardo-2023-demand-moral-commitment/independent/2026-11-10-d/mount/saccardo_2023_demand_moral_commitment/Data/Clean Data/"
d <- read_dta(paste0(D, "choice_experiments.dta"))
d <- zap_labels(d)

# Main Choice treatments (Table 1): drop the Choice Free High Stakes (10-fold, 100-fold) robustness arms;
# AMT advisors must have a consistent MPL (selfishness measure non-missing; not elicited for professionals).
m <- d %>%
  filter(!(incentivedesign %in% c("1.50", "15 (to everyone)"))) %>%
  filter(professionals == 1 | !is.na(stdalpha)) %>%
  filter(!is.na(age), !is.na(female))
cat("Main sample by treatment (incl. age NA drop):\n"); print(table(m$treatment))

# Controls: gender, age, wave dummies (AMT-1 baseline; professionals captured by their treatment indicator),
# probabilistic incentives, product position, and probabilistic x position.
m <- m %>% mutate(
  w2 = as.numeric(wave == "AMT-2"), w3 = as.numeric(wave == "AMT-3"),
  selfishness = stdalpha,
  sic_x_self = seeincentivecostly * stdalpha,
  sqc_x_self = seequalitycostly * stdalpha,
  pos = incentiveleft,
  prob_x_pos = probabilistic_incentive * incentiveleft
)
ctrl <- "female + age + w2 + w3 + probabilistic_incentive + pos + prob_x_pos"

fit <- function(f, data) {
  r <- lm(as.formula(f), data = data)
  V <- vcovHC(r, type = "HC3")
  list(m = r, ct = coeftest(r, vcov. = V))
}
show <- function(x, lab) { cat("\n====", lab, " N =", nobs(x$m), " R2 =", round(summary(x$m)$r.squared, 3), "\n"); print(round(x$ct[, 1:2], 4)) }

# Table 2
t2c1 <- fit(paste("choicebefore ~ professionalsfree + seeincentivecostly + seequalitycostly +", ctrl), m)
amt <- m %>% filter(professionals == 0)
t2c2 <- fit(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness +", ctrl), amt)
t2c3 <- fit(paste("choicebefore ~ seeincentivecostly + seequalitycostly + selfishness + sic_x_self + sqc_x_self +", ctrl), amt)
show(t2c1, "Table 2 col 1"); show(t2c2, "Table 2 col 2"); show(t2c3, "Table 2 col 3")

# Table 3
f3 <- paste("recommendincentive ~ choicebefore + noconflict + choicebeforenoconflict + professionalsfree + seeincentivecostly + seequalitycostly + incentiveB +", ctrl)
t3c1 <- fit(f3, m %>% filter(getyourchoice == 1))
t3c2 <- fit(f3, m %>% filter(getyourchoice == 0))
t3c3 <- fit(paste(f3, "+ notgetyourchoice + choicebeforenotgetyourchoice + notgetyourchoicenoconflict"), m)
show(t3c1, "Table 3 col 1"); show(t3c2, "Table 3 col 2"); show(t3c3, "Table 3 col 3")

b <- function(x, v) unname(coef(x$m)[v])
out <- c(
  see_incentive_first_costly_table2_col1 = b(t2c1, "seeincentivecostly"),
  assess_quality_first_costly_table2_col1 = b(t2c1, "seequalitycostly"),
  choice_free_professionals_table2_col1 = b(t2c1, "professionalsfree"),
  selfishness_table2_col2 = b(t2c2, "selfishness"),
  selfishness_table2_col3 = b(t2c3, "selfishness"),
  see_incentive_first_costly_x_selfishness_table2_col3 = b(t2c3, "sic_x_self"),
  see_quality_first_costly_x_selfishness_table2_col3 = b(t2c3, "sqc_x_self"),
  n_obs_table2_col1 = nobs(t2c1$m),
  n_obs_table2_cols2_3 = nobs(t2c2$m),
  prefer_see_incentive_first_assigned_table3_col1 = b(t3c1, "choicebefore"),
  prefer_see_incentive_first_not_assigned_table3_col2 = b(t3c2, "choicebefore"),
  prefer_see_incentive_first_x_not_assigned_table3_col3 = b(t3c3, "choicebeforenotgetyourchoice"),
  n_obs_table3_col1 = nobs(t3c1$m)
)
cat("\n")
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
