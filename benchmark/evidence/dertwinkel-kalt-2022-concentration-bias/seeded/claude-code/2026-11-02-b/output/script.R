suppressPackageStartupMessages({library(readr); library(dplyr); library(fixest); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/seeded/2026-11-02-b/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE, guess_max = 10000)
# Stata `if x == 1` is false for missing x
is1 <- function(x) !is.na(x) & x == 1
is0 <- function(x) !is.na(x) & x == 0
olsc <- function(y, sub) { s <- d[sub & !is.na(d[[y]]), ]; m <- feols(as.formula(paste(y, "~ 1")), s, vcov = "hetero"); list(b = coef(m)[1], n = nobs(m)) }
olsx <- function(y, x, sub) { s <- d[sub & !is.na(d[[y]]) & !is.na(d[[x]]), ]; m <- feols(as.formula(paste(y, "~", x)), s, vcov = "hetero"); list(b = coef(m), n = nobs(m)) }

# Main-Treatment main sample (pap_sample == 1 & dispersed == 0 & treatment == 1)
mt <- is1(d$pap_sample) & is0(d$dispersed) & is1(d$treatment)
# Table 2
a_mid <- olsc("avg_id_stage2", mt)
r_low <- olsc("qe_ard_lower", mt); r_mid <- olsc("qe_ard", mt); r_up <- olsc("qe_ard_upper", mt)
st <- d[mt & !is.na(d$id_stage2), ]
tb <- tobit(id_stage2 ~ 1, left = -63, right = 63, data = st)
cat("Table2 N:", a_mid$n, r_low$n, r_mid$n, r_up$n, nrow(st), "\n")

# Table 3
c1 <- olsx("qe_ard", "main", is1(d$pap_sample) & is1(d$treatment))
c2 <- olsx("qe_ard", "control", is1(d$pap_sample) & is0(d$pizza))
c3 <- olsx("qe_ard", "treatment", is1(d$pap_sample) & is1(d$pizza) & is0(d$dispersed))
c4 <- olsx("qe_ard", "treatment", is1(d$pap_sample) & is1(d$pizza) & is1(d$dispersed))
cat("Table3 N:", c1$n, c2$n, c3$n, c4$n, "\n")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", a_mid$b))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", coef(tb)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", r_low$b))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", r_mid$b))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", r_up$b))
cat(sprintf("RESULT:n_obs_table2=%d\n", r_mid$n))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", c1$b[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", c1$b[2]))
# Donation-Treatment is control == 0, i.e. the constant; the difference is -coef(control)
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", c2$b[1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", -c2$b[2]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", c3$b[2]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", c4$b[2]))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))
