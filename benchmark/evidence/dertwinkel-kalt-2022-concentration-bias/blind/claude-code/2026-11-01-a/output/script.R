# Reproduction of Tables 2 and 3, Dertwinkel-Kalt et al. "Concentration Bias in Intertemporal Choice"
# Consumption experiment. Independent + blind reproduction from the paper's description.
suppressMessages({ library(tidyverse); library(sandwich); library(lmtest); library(AER) })
set.seed(42)
p <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-01-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(p, show_col_types = FALSE)

# Mandatory tasks per workday (paper fn. 3)
e <- c(129, 132, 143, 115, 121, 117, 135, 127)
LB <- 62   # upper end of the d range [-63, 62] (paper Sec. 2.3.5)

# Balanced trade-offs: decisions 1-8; utility_point = workday t
bal <- d %>% filter(decision_number <= 8) %>% select(tn, t = utility_point, x = indifference_point, corner)
subj_bal <- bal %>% group_by(tn) %>%
  summarise(any_corner = any(corner != 0),
            # (1/8) sum_t 1/(e_t + x_t)
            inv_mean = mean(1 / (e[t] + x)), .groups = "drop")
xwide <- bal %>% select(tn, t, x)

# Final trade-off: decision 9
fin <- d %>% filter(decision_number == 9) %>%
  select(tn, treatment, pizza, main, j = utility_point, ip = indifference_point, corner_fin = corner, pap_sample) %>%
  left_join(subj_bal, by = "tn") %>%
  left_join(xwide %>% rename(j = t, x_j = x), by = c("tn", "j")) %>%
  mutate(cond = case_when(pizza == 0 ~ "Donation", main == 1 ~ "Main", TRUE ~ "Mechanism"),
         arm = ifelse(treatment == 1, "Treatment", "Control"),
         # absolute measure under three treatments of upper-corner subjects
         d_lower = ifelse(corner_fin == 1, LB, ip),
         d_upper = ifelse(corner_fin == 1, ip, ip),          # manual stated value stored in ip for upper corners
         d_mid   = ifelse(corner_fin == 1, (LB + ip) / 2, ip),
         # relative measure: Treatment = (1/8) sum_t d/(e_t + x_t); Control = d/(e_j + x_j) on the repeated workday j
         rel_w  = ifelse(arm == "Treatment", inv_mean, 1 / (e[j] + x_j)),
         drel_lower = d_lower * rel_w, drel_mid = d_mid * rel_w, drel_upper = d_upper * rel_w)

# Main sample: preregistered exclusion of subjects with any corner choice in the balanced trade-offs
# (pap_sample == 1 is the dataset's preregistered-sample flag; it is a subset of the no-corner subjects)
cat("Diagnostics: no-corner subjects by condition:\n"); print(fin %>% filter(!any_corner) %>% count(cond, arm))
ms <- fin %>% filter(pap_sample == 1, !any_corner)
cat("Main sample by condition:\n"); print(ms %>% count(cond, arm))

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

mt <- ms %>% filter(cond == "Main", arm == "Treatment")
# Table 2
t2 <- list(
  d_lower = rob(lm(d_lower ~ 1, mt)), d_mid = rob(lm(d_mid ~ 1, mt)), d_upper = rob(lm(d_upper ~ 1, mt)),
  r_lower = rob(lm(drel_lower ~ 1, mt)), r_mid = rob(lm(drel_mid ~ 1, mt)), r_upper = rob(lm(drel_upper ~ 1, mt)))
for (nm in names(t2)) { cat(nm, ": est", t2[[nm]][1, 1], " se", t2[[nm]][1, 2], "\n") }
# Tobit on lower-bound measure, censored at ends of elicitation range
tob <- tobit(d_lower ~ 1, left = -63, right = LB, data = mt)
tob_ct <- coeftest(tob)
cat("tobit: est", tob_ct[1, 1], " se", tob_ct[1, 2], "\n")
n_t2 <- nrow(mt)

# Table 3 (midpoint-based relative measure)
c1 <- ms %>% filter(arm == "Treatment", cond %in% c("Main", "Mechanism")) %>% mutate(D = as.numeric(cond == "Main"))
c2 <- ms %>% filter(cond == "Donation") %>% mutate(D = as.numeric(arm == "Treatment"))
c3 <- ms %>% filter(cond == "Main") %>% mutate(D = as.numeric(arm == "Treatment"))
c4 <- ms %>% filter(cond == "Mechanism") %>% mutate(D = as.numeric(arm == "Treatment"))
m1 <- lm(drel_mid ~ D, c1); m2 <- lm(drel_mid ~ D, c2); m3 <- lm(drel_mid ~ D, c3); m4 <- lm(drel_mid ~ D, c4)
r1 <- rob(m1); r2 <- rob(m2); r3 <- rob(m3); r4 <- rob(m4)
print(r1); print(r2); print(r3); print(r4)
# Donation-Treatment mean (= constant + coefficient), with robust SE
m2b <- lm(drel_mid ~ 1, c2 %>% filter(D == 1)); r2b <- rob(m2b)
cat("Donation-Treatment mean:", r2b[1, 1], " se", r2b[1, 2], "\n")
cat("N per Table 3 column:", nrow(c1), nrow(c2), nrow(c3), nrow(c4), "\n")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", t2$d_mid[1, 1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", tob_ct[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", t2$r_lower[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", t2$r_mid[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", t2$r_upper[1, 1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", n_t2))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", r1[1, 1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", r1[2, 1]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", r2b[1, 1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", r2[2, 1]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", r3[2, 1]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", r4[2, 1]))
cat(sprintf("RESULT:n_obs_table3=%d\n", nrow(c1)))
cat("DEVIATION: n_obs_table3 reports column 1's N; the per-column Ns are printed above.\n")
