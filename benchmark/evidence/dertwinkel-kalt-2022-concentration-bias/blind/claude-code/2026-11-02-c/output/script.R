# Retally blind/independent reproduction: Dertwinkel-Kalt et al. (2022), Concentration Bias in Intertemporal Choice
# Tables 2 and 3 (consumption experiment), reconstructed from the paper's description.
set.seed(42)
suppressMessages({
  library(tidyverse)
  library(sandwich)
  library(lmtest)
  library(AER)
})

f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-02-c/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE)

# Mandatory tasks per workday t (paper, footnote 3)
e <- c(129, 132, 143, 115, 121, 117, 135, 127)
LB <- 62   # upper end of the elicitation range for d in {-63,...,62} (paper Sec. 2.3.5)
LOW <- -63 # lower end of the elicitation range

# Balanced trade-offs: decisions 1-8; utility_point = workday t of the balanced trade-off
bal <- d %>% filter(decision_number <= 8)
xw <- bal %>% select(tn, utility_point, indifference_point) %>%
  arrange(tn, utility_point) %>%
  pivot_wider(names_from = utility_point, values_from = indifference_point, names_prefix = "x")
bcorner <- bal %>% group_by(tn) %>% summarise(any_bal_corner = any(corner != 0), .groups = "drop")

# Final trade-off: decision 9 (unbalanced in Treatment, repeated balanced in Control)
fin <- d %>% filter(decision_number == 9) %>%
  select(tn, dispersed, pizza, control, main, pap_sample, corner, ip9 = indifference_point) %>%
  left_join(xw, by = "tn") %>% left_join(bcorner, by = "tn")

# Condition labels
fin <- fin %>% mutate(
  cond = case_when(
    pizza == 1 & dispersed == 0 & control == 0 ~ "Main-Treatment",
    pizza == 1 & dispersed == 0 & control == 1 ~ "Main-Control",
    pizza == 1 & dispersed == 1 & control == 0 ~ "Mechanism-Treatment",
    pizza == 1 & dispersed == 1 & control == 1 ~ "Mechanism-Control",
    pizza == 0 & control == 0 ~ "Donation-Treatment",
    pizza == 0 & control == 1 ~ "Donation-Control"
  )
)

# Absolute measure d~ : interior choices = elicited indifference point; lower corner = -63 (as coded);
# upper corner: lower bound 62, upper bound = manually stated indifference point, midpoint in between.
fin <- fin %>% mutate(
  d_low = ifelse(corner == 1, LB, ip9),
  d_up  = ifelse(corner == 1, ip9, ip9),
  d_mid = ifelse(corner == 1, (LB + ip9) / 2, ip9)
)

# Relative measure d~rel = (1/8) sum_t d~ / (e_t + x~_t)
X <- as.matrix(fin[, paste0("x", 1:8)])
inv_den <- rowMeans(1 / sweep(X, 2, e, "+"))
fin <- fin %>% mutate(rel_low = d_low * inv_den, rel_mid = d_mid * inv_den, rel_up = d_up * inv_den)

# Main sample: preregistered sample (pap_sample == 1), i.e. no corner choice in any balanced trade-off
cat("Check: pap_sample vs any balanced corner\n"); print(with(fin, table(pap_sample, any_bal_corner, useNA = "ifany")))
ms <- fin %>% filter(pap_sample == 1, !any_bal_corner)
print(ms %>% count(cond))

rob <- function(m) coeftest(m, vcov. = vcovHC(m, type = "HC1"))

# ---- Table 2 ----
mt <- ms %>% filter(cond == "Main-Treatment")
t2 <- list(
  d_low = rob(lm(d_low ~ 1, mt)), d_mid = rob(lm(d_mid ~ 1, mt)), d_up = rob(lm(d_up ~ 1, mt)),
  rel_low = rob(lm(rel_low ~ 1, mt)), rel_mid = rob(lm(rel_mid ~ 1, mt)), rel_up = rob(lm(rel_up ~ 1, mt))
)
for (nm in names(t2)) { cat("Table 2", nm, ": "); print(t2[[nm]]) }
tob <- tobit(d_low ~ 1, left = LOW, right = LB, data = mt)
print(summary(tob))
cat("Upper-corner subjects in Main-Treatment main sample:", sum(mt$corner == 1), "; lower-corner:", sum(mt$corner == -1), "\n")

# ---- Table 3 ----
pair_reg <- function(c_ref, c_ind) {
  dd <- ms %>% filter(cond %in% c(c_ref, c_ind)) %>% mutate(ind = as.numeric(cond == c_ind))
  m <- lm(rel_mid ~ ind, dd)
  list(ct = rob(m), n = nobs(m))
}
c1 <- pair_reg("Mechanism-Treatment", "Main-Treatment")       # const = Mech-T, ind = Main-T - Mech-T
c2 <- pair_reg("Donation-Treatment", "Donation-Control")      # const = Don-T, ind = Don-C - Don-T
c3 <- pair_reg("Main-Control", "Main-Treatment")              # const = Main-C, ind = Main-T - Main-C
c4 <- pair_reg("Mechanism-Control", "Mechanism-Treatment")    # const = Mech-C, ind = Mech-T - Mech-C
for (cc in list(c1, c2, c3, c4)) { print(cc$ct); cat("N =", cc$n, "\n") }

# ---- Results ----
cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", t2$d_mid[1, 1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", t2$rel_low[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", t2$rel_mid[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", t2$rel_up[1, 1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(mt)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", c1$ct[1, 1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", c1$ct[2, 1]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", c2$ct[1, 1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", -c2$ct[2, 1]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", c3$ct[2, 1]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", c4$ct[2, 1]))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))
cat(sprintf("NOTE: Table 3 N by column = %d, %d, %d, %d\n", c1$n, c2$n, c3$n, c4$n))
