# Dertwinkel-Kalt et al. (2022) "Concentration Bias in Intertemporal Choice"
# Independent, blind reproduction of Table 2 and Table 3 (consumption experiment).
suppressMessages({library(tidyverse); library(sandwich); library(lmtest); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-07-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE)

# Mandatory tasks per workday t (paper footnote 3); utility_point indexes the workday t / trade-off j
e <- c(129, 132, 143, 115, 121, 117, 135, 127)

# Balanced trade-offs (decisions 1-8): indifference point x~_t per subject and workday
bal <- d %>% filter(decision_number <= 8) %>%
  transmute(tn, t = utility_point, x = indifference_point, corner)
# Subject-level: sum_t 1/(e_t + x~_t), and corner in any balanced trade-off
balsum <- bal %>% group_by(tn) %>%
  summarise(inv_sum = sum(1 / (e[t] + x)), any_bal_corner = any(corner != 0), .groups = "drop")

# Final trade-off (decision 9): d~ elicited in [-63, 62]; upper-corner subjects stated d~ manually.
# The data code the censored lower bound of upper-corner subjects as 63 (variable id_stage2; interior
# values run up to 61), i.e. the bound is one above the largest interior value; we use the data's coding.
LB <- 63
fin <- d %>% filter(decision_number == 9) %>%
  transmute(tn, treatment, pizza, dispersed, pap_sample, corner9 = corner,
            j = utility_point, manual = indifference_point) %>%
  mutate(d_lower = ifelse(corner9 == 1, LB, manual),
         d_upper = manual,
         d_mid   = ifelse(corner9 == 1, (LB + manual) / 2, manual),
         cond = case_when(pizza == 1 & dispersed == 0 ~ "Main",
                          pizza == 1 & dispersed == 1 ~ "Mechanism",
                          pizza == 0 ~ "Donation"),
         arm = ifelse(treatment == 1, "Treatment", "Control")) %>%
  left_join(balsum, by = "tn") %>%
  left_join(bal %>% select(tn, j = t, x_j = x), by = c("tn", "j"))

# Relative measure: Treatment = (1/8) sum_t d~/(e_t + x~_t); Control (repeated balanced trade-off j) = d~/(e_j + x~_j)
rel <- function(dd, df) ifelse(df$arm == "Treatment", dd * df$inv_sum / 8, dd / (e[df$j] + df$x_j))
fin <- fin %>% mutate(rel_lower = rel(d_lower, fin), rel_mid = rel(d_mid, fin), rel_upper = rel(d_upper, fin))

# Main sample: preregistered exclusion (no corner in any balanced trade-off), as flagged by pap_sample
main <- fin %>% filter(pap_sample == 1)
cat("Check: any balanced corner in main sample:", any(main$any_bal_corner), "\n")
print(main %>% count(cond, arm))
# Diagnostic: compare own relative midpoint measure with the dataset's constructed qe_ard column
chk <- d %>% filter(decision_number == 9) %>% select(tn, qe_ard) %>% right_join(main, by = "tn")
cat("Max |own rel_mid - qe_ard| in main sample:", max(abs(chk$rel_mid - chk$qe_ard), na.rm = TRUE), "\n")

ols_const <- function(y) { m <- lm(y ~ 1); ct <- coeftest(m, vcov = vcovHC(m, type = "HC1")); ct }

# ---- Table 2: Main-Treatment
mt <- main %>% filter(cond == "Main", arm == "Treatment")
t2 <- list(
  d_lower = ols_const(mt$d_lower), d_mid = ols_const(mt$d_mid), d_upper = ols_const(mt$d_upper),
  r_lower = ols_const(mt$rel_lower), r_mid = ols_const(mt$rel_mid), r_upper = ols_const(mt$rel_upper))
for (nm in names(t2)) cat(sprintf("Table2 %-8s coef=%.4f robust se=%.4f\n", nm, t2[[nm]][1, 1], t2[[nm]][1, 2]))
tob <- tobit(d_lower ~ 1, left = -63, right = LB, data = mt)
cat(sprintf("Table2 Tobit coef=%.4f se=%.4f\n", coef(tob)[1], sqrt(vcov(tob)[1, 1])))
n2 <- nrow(mt)

# ---- Table 3: pairwise between-subject OLS of d~rel (midpoint) with robust SE
reg2 <- function(df, ind) {
  m <- lm(rel_mid ~ ind, data = df %>% mutate(ind = ind))
  list(ct = coeftest(m, vcov = vcovHC(m, type = "HC1")), n = nobs(m))
}
c1d <- main %>% filter(arm == "Treatment", cond %in% c("Main", "Mechanism"))
c1 <- reg2(c1d, as.numeric(c1d$cond == "Main"))
c2d <- main %>% filter(cond == "Donation")
c2 <- reg2(c2d, as.numeric(c2d$arm == "Control"))   # constant = Donation-Treatment
c3d <- main %>% filter(cond == "Main")
c3 <- reg2(c3d, as.numeric(c3d$arm == "Treatment"))
c4d <- main %>% filter(cond == "Mechanism")
c4 <- reg2(c4d, as.numeric(c4d$arm == "Treatment"))
for (x in list(c1, c2, c3, c4)) { print(x$ct); cat("N =", x$n, "\n") }

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", t2$d_mid[1, 1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", t2$r_lower[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", t2$r_mid[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", t2$r_upper[1, 1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", n2))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", c1$ct[1, 1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", c1$ct[2, 1]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", c2$ct[1, 1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", -c2$ct[2, 1]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", c3$ct[2, 1]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", c4$ct[2, 1]))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))
