# Independent reproduction: Dertwinkel-Kalt et al., "Concentration Bias in Intertemporal Choice"
# Tables 2 and 3 (consumption experiment), built from the raw per-decision rows.
set.seed(42)
suppressMessages({library(dplyr); library(readr); library(estimatr); library(AER)})

f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-02-c/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE, guess_max = 10000)

# Mandatory tasks per workday t (paper, footnote 3)
e <- c(129, 132, 143, 115, 121, 117, 135, 127)

# Balanced trade-offs: decision_number 1..8; utility_point = trade-off / workday index j = t
bal <- d %>% filter(decision_number <= 8) %>%
  mutate(et = e[utility_point]) %>%
  select(tn, j = utility_point, et, x = indifference_point, corner)
subj_bal <- bal %>% group_by(tn) %>%
  summarise(any_corner = any(corner != 0),
            mean_ex = mean(et + x), .groups = "drop")

# Final trade-off: decision_number 9 (unbalanced in Treatment, repeated balanced j in Control)
fin <- d %>% filter(decision_number == 9) %>%
  left_join(subj_bal, by = "tn") %>%
  mutate(cond = case_when(pizza == 0 ~ "Donation",
                          dispersed == 1 ~ "Mechanism",
                          TRUE ~ "Main"),
         arm = ifelse(treatment == 1, "Treatment", "Control"),
         group = paste(cond, arm, sep = "-"))

# Indifference point d~ in the final trade-off.
# Interior choices: the elicited value (id_stage2 == indifference_point).
# Upper corner (corner == 1): lower bound = top of the elicited grid as coded in the data
# (id_stage2 = 63), upper bound = manually stated value (indifference_point), midpoint in between.
fin <- fin %>% mutate(
  d_lower = id_stage2,
  d_upper = ifelse(corner == 1, indifference_point, id_stage2),
  d_mid   = (d_lower + d_upper) / 2)

# Relative measure.
# Treatment: d~rel = (1/8) sum_t d~/(e_t + x~_t)  (eq. 12).
# Control: the final trade-off repeats balanced trade-off j, so d~rel = d~/(e_j + x~_j).
inv_mean <- bal %>% group_by(tn) %>% summarise(inv8 = mean(1 / (et + x)), .groups = "drop")
fin <- fin %>% left_join(inv_mean, by = "tn") %>%
  left_join(bal %>% select(tn, j, et_j = et, x_j = x), by = c("tn", "utility_point" = "j")) %>%
  mutate(w = ifelse(arm == "Treatment", inv8, 1 / (et_j + x_j)),
         rel_lower = d_lower * w, rel_upper = d_upper * w, rel_mid = d_mid * w)

# Main sample: preregistered exclusion of subjects with any corner choice in the balanced
# trade-offs, and the preregistered sample size of 100 subjects per condition
# (first 100 eligible subjects in order of participation, tn).
fin <- fin %>% filter(!any_corner, !is.na(id_stage2)) %>%
  arrange(group, tn) %>% group_by(group) %>%
  mutate(rank = row_number()) %>% ungroup()
cat("Eligible (no balanced corner) per group:\n"); print(table(fin$group))
ms <- fin %>% filter(rank <= 100)
cat("Main sample per group:\n"); print(table(ms$group))
if ("pap_sample" %in% names(ms)) {
  cat("Cross-check with data's pap_sample flag: kept subjects flagged 1 =", sum(ms$pap_sample == 1, na.rm = TRUE),
      "of", nrow(ms), "; dropped eligible flagged 1 =", sum(fin$pap_sample[fin$rank > 100] == 1, na.rm = TRUE), "\n")
}

# ---- Table 2: Main-Treatment ----
mt <- ms %>% filter(group == "Main-Treatment")
ols_c <- function(y) lm_robust(y ~ 1, se_type = "HC1")
t2 <- list(
  abs_lower = ols_c(mt$d_lower), abs_mid = ols_c(mt$d_mid), abs_upper = ols_c(mt$d_upper),
  rel_lower = ols_c(mt$rel_lower), rel_mid = ols_c(mt$rel_mid), rel_upper = ols_c(mt$rel_upper))
for (n in names(t2)) cat(sprintf("Table2 %-10s coef %.4f  se %.4f\n", n, coef(t2[[n]]), t2[[n]]$std.error))
# Tobit on lower-bound measure, censored at the ends of the elicitation range
lo <- min(fin$d_lower); hi <- max(fin$d_lower)
cat("Censoring points:", lo, hi, "\n")
tob <- tobit(d_lower ~ 1, left = lo, right = hi, data = mt)
cat(sprintf("Table2 tobit coef %.4f se %.4f\n", coef(tob)[1], sqrt(vcov(tob)[1, 1])))
# Sensitivity (diagnostic only): paper text states the lower bound as 62
alt <- ifelse(mt$corner == 1, 62, mt$d_lower)
cat(sprintf("Diagnostic: mean d~ with lower bound 62: lower %.3f mid %.3f\n",
            mean(alt), mean((alt + mt$d_upper) / 2)))

# ---- Table 3: midpoint-based d~rel, pooled two-condition OLS with robust SEs ----
t3 <- function(g1, g0) {
  x <- ms %>% filter(group %in% c(g1, g0)) %>% mutate(ind = as.numeric(group == g1))
  m <- lm_robust(rel_mid ~ ind, data = x, se_type = "HC1")
  cat(sprintf("Table3 %s vs %s: const %.4f (%.4f) diff %.4f (%.4f) N %d\n", g1, g0,
              coef(m)[1], m$std.error[1], coef(m)[2], m$std.error[2], nrow(x)))
  m
}
c1 <- t3("Main-Treatment", "Mechanism-Treatment")
c2 <- t3("Donation-Control", "Donation-Treatment")  # constant = Donation-Treatment; ind = Control
c3 <- t3("Main-Treatment", "Main-Control")
c4 <- t3("Mechanism-Treatment", "Mechanism-Control")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.4f\n", coef(t2$abs_mid)))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.4f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.4f\n", coef(t2$rel_lower)))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.4f\n", coef(t2$rel_mid)))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.4f\n", coef(t2$rel_upper)))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(mt)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.4f\n", coef(c1)[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.4f\n", coef(c1)[2]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.4f\n", coef(c2)[1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.4f\n", -coef(c2)[2]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.4f\n", coef(c3)[2]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.4f\n", coef(c4)[2]))
cat(sprintf("RESULT:n_obs_table3=%d\n", length(c1$fitted.values)))
