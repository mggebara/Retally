# Dertwinkel-Kalt et al. (2022) "Concentration Bias in Intertemporal Choice": Tables 2 and 3
suppressMessages({library(tidyverse); library(sandwich); library(lmtest); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE)

# Mandatory tasks per workday t (paper, footnote 3)
e <- c(129, 132, 143, 115, 121, 117, 135, 127)

# Balanced trade-offs (decisions 1-8): indifference point x_t for workday t = utility_point
b <- d %>% filter(decision_number <= 8) %>%
  transmute(tn, t = utility_point, x = indifference_point, bcorner = corner != 0, et = e[utility_point])
bc <- b %>% group_by(tn) %>% summarise(any_bal_corner = any(bcorner), .groups = "drop")

# Final trade-off (decision 9): unbalanced (Treatment) or repeated balanced j in {1,4,8} (Control)
u <- d %>% filter(decision_number == 9) %>%
  transmute(tn, pizza, main, control, pap_sample, j = utility_point, ucorner = corner, ip = indifference_point) %>%
  left_join(bc, by = "tn")

# Lower bound for upper-corner choices: the dataset codes upper corners as 63 (one above the largest
# interior value 61 / the range end 62); we use the dataset's coding (see DEVIATION note).
LB <- 63; LOWC <- -63
u <- u %>% mutate(
  d_lower = case_when(ucorner == 1 ~ LB, ucorner == -1 ~ LOWC, TRUE ~ ip),
  d_upper = case_when(ucorner == 1 ~ ip, ucorner == -1 ~ LOWC, TRUE ~ ip),
  d_mid   = (d_lower + d_upper) / 2)

# Relative measure: Treatment: (1/8) sum_t d/(e_t + x_t); Control: deviation only on workday j -> d/(e_j + x_j)
rel <- u %>% select(tn, control, j, d_lower, d_mid, d_upper) %>% left_join(b, by = "tn") %>%
  group_by(tn) %>%
  summarise(
    rel_lower = if (control[1] == 0) mean(d_lower / (et + x)) else (d_lower / (et + x))[t == j][1],
    rel_mid   = if (control[1] == 0) mean(d_mid   / (et + x)) else (d_mid   / (et + x))[t == j][1],
    rel_upper = if (control[1] == 0) mean(d_upper / (et + x)) else (d_upper / (et + x))[t == j][1],
    .groups = "drop")
u <- u %>% left_join(rel, by = "tn")

# Main sample: preregistered sample (no corner choice in any balanced trade-off; first 100 per condition)
ms <- u %>% filter(pap_sample == 1)
stopifnot(all(!ms$any_bal_corner))
cat("Main sample sizes by condition:\n"); print(count(ms, pizza, main, control))

rob <- function(m, term) { ct <- coeftest(m, vcov = vcovHC(m, type = "HC1")); ct[term, ] }

# ---- Table 2: Main-Treatment
mt <- ms %>% filter(pizza == 1, main == 1, control == 0)
m_d_mid <- lm(d_mid ~ 1, data = mt)
m_r_low <- lm(rel_lower ~ 1, data = mt)
m_r_mid <- lm(rel_mid ~ 1, data = mt)
m_r_up  <- lm(rel_upper ~ 1, data = mt)
tob <- tobit(d_lower ~ 1, left = LOWC, right = LB, data = mt)
cat("Table 2 col2 d mid:\n"); print(rob(m_d_mid, "(Intercept)"))
cat("Table 2 col4 tobit:\n"); print(summary(tob)$coefficients)
cat("Table 2 rel lower/mid/upper SEs:\n"); print(rbind(rob(m_r_low, "(Intercept)"), rob(m_r_mid, "(Intercept)"), rob(m_r_up, "(Intercept)")))

# ---- Table 3
c1 <- ms %>% filter(pizza == 1, control == 0)                     # Main-T vs Mechanism-T
m1 <- lm(rel_mid ~ main, data = c1)
c2 <- ms %>% filter(pizza == 0) %>% mutate(treat = 1 - control)    # Donation-T vs Donation-C
m2 <- lm(rel_mid ~ control, data = c2)                             # constant = Donation-Treatment
m2b <- lm(rel_mid ~ treat, data = c2)
c3 <- ms %>% filter(pizza == 1, main == 1) %>% mutate(treat = 1 - control)
m3 <- lm(rel_mid ~ treat, data = c3)
c4 <- ms %>% filter(pizza == 1, main == 0) %>% mutate(treat = 1 - control)
m4 <- lm(rel_mid ~ treat, data = c4)
cat("Table 3 col1:\n"); print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))
cat("Table 3 col2:\n"); print(coeftest(m2, vcov = vcovHC(m2, type = "HC1"))); print(coeftest(m2b, vcov = vcovHC(m2b, type = "HC1")))
cat("Table 3 col3:\n"); print(coeftest(m3, vcov = vcovHC(m3, type = "HC1")))
cat("Table 3 col4:\n"); print(coeftest(m4, vcov = vcovHC(m4, type = "HC1")))
cat("Table 3 Ns:", nobs(m1), nobs(m2), nobs(m3), nobs(m4), "\n")

# Sensitivity (not scored): lower bound 62 as literally stated in the paper text
mt62 <- mt %>% mutate(dm = ifelse(ucorner == 1, (62 + d_upper) / 2, d_mid))
cat("DEVIATION: upper-corner lower bound taken as 63 (dataset coding of upper corners) rather than 62 (paper text); with 62 the Main-Treatment mean midpoint d would be",
    sprintf("%.4f", mean(mt62$dm)), "\n")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", coef(m_d_mid)[1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", coef(m_r_low)[1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", coef(m_r_mid)[1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", coef(m_r_up)[1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m_d_mid)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", coef(m1)[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", coef(m1)["main"]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", coef(m2)[1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", coef(m2b)["treat"]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", coef(m3)["treat"]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", coef(m4)["treat"]))
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(m1)))
