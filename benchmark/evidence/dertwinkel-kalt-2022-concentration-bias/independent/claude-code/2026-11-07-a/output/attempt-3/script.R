## Dertwinkel-Kalt et al. (2022) "Concentration Bias in Intertemporal Choice"
## Independent reproduction of Table 2 and Table 3 (consumption experiment).
suppressMessages({library(dplyr); library(estimatr); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-07-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read.csv(f, stringsAsFactors = FALSE)
e <- c(129,132,143,115,121,117,135,127)   # mandatory tasks per workday (fn. 3)
# condition: pizza==1 voucher (main==1 Main, main==0 Mechanism); pizza==0 Donation
d$cond <- with(d, ifelse(pizza == 0, "Don", ifelse(main == 1, "Main", "Mech")))

## Balanced trade-offs (decisions 1-8): x~_t indexed by workday t = utility_point
b <- d[d$decision_number <= 8, ]
bal <- b %>% group_by(tn) %>%
  summarise(anycorner = any(corner != 0),
            sinv = mean(1 / (e[utility_point] + indifference_point)), .groups = "drop")
xj <- b %>% select(tn, utility_point, xj = indifference_point)

## Final trade-off (decision 9)
s <- d[d$decision_number == 9, ] %>% left_join(bal, by = "tn") %>%
  left_join(xj, by = c("tn", "utility_point"))
# preregistered exclusion: any corner choice in the balanced trade-offs
s <- s[!s$anycorner, ]
cat("Subjects after exclusion by condition/control:\n"); print(table(s$cond, s$control))
cat("Agreement of own exclusion with pap_sample flag:\n"); print(table(s$pap_sample, useNA = "a"))
# upper corner: d observed only as >= upper end of range; the data code that bound as 63
UB <- 63
up <- s$corner == 1
s$d_low <- ifelse(up, UB, s$indifference_point)                      # lower bound
s$d_up  <- s$indifference_point                                       # stated (upper bound)
s$d_mid <- ifelse(up, (UB + s$indifference_point) / 2, s$indifference_point)
# relative measure, eq. (12): (1/8) sum_t d/(e_t + x_t)
for (k in c("low","mid","up")) s[[paste0("rel_", k)]] <- s[[paste0("d_", k)]] * s$sinv
# Control conditions: deviation applies to the repeated trade-off j only -> d/(e_j + x_j)
ctl <- s$control == 1
s$rel_mid[ctl] <- s$d_mid[ctl] / (e[s$utility_point[ctl]] + s$xj[ctl])

mt <- s[s$cond == "Main" & s$control == 0, ]
ols <- function(y, data) lm_robust(as.formula(paste(y, "~ 1")), data = data, se_type = "HC1")
vs <- c("d_low","d_mid","d_up","rel_low","rel_mid","rel_up")
t2 <- lapply(vs, function(v) ols(v, mt)); names(t2) <- vs
for (n in vs) cat(sprintf("Table2 %s: %.4f (%.4f)\n", n, coef(t2[[n]]), t2[[n]]$std.error))
# Tobit on lower-bound d, censored at ends of the elicitation range [-63, 63]
tob <- tobit(d_low ~ 1, left = -63, right = UB, data = mt)
cat(sprintf("Tobit: %.4f (%.4f)\n", coef(tob)[1], sqrt(diag(vcov(tob)))[1]))

## Table 3
reg2 <- function(data, ind) { data$ind <- ind; lm_robust(rel_mid ~ ind, data = data, se_type = "HC1") }
p1 <- s[s$control == 0 & s$cond %in% c("Main","Mech"), ];  r1 <- reg2(p1, as.numeric(p1$cond == "Main"))
p2 <- s[s$cond == "Don", ];  r2 <- reg2(p2, as.numeric(p2$control == 0))
p3 <- s[s$cond == "Main", ]; r3 <- reg2(p3, as.numeric(p3$control == 0))
p4 <- s[s$cond == "Mech", ]; r4 <- reg2(p4, as.numeric(p4$control == 0))
for (r in list(r1, r2, r3, r4)) print(summary(r)$coefficients[, 1:2])
# Donation-Treatment level: constant with Donation-Treatment as base category
r2b <- reg2(p2, as.numeric(p2$control == 1))
cat("Diagnostic: control means with eq.(12) 8-day denominator:\n")
print(s %>% filter(control == 1) %>% group_by(cond) %>% summarise(m = mean(d_mid * sinv)))

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.4f\n", coef(t2$d_mid)))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.4f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.4f\n", coef(t2$rel_low)))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.4f\n", coef(t2$rel_mid)))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.4f\n", coef(t2$rel_up)))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(mt)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.4f\n", coef(r1)[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.4f\n", coef(r1)[2]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.4f\n", coef(r2b)[1]))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.4f\n", coef(r2)[2]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.4f\n", coef(r3)[2]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.4f\n", coef(r4)[2]))
cat(sprintf("RESULT:n_obs_table3=%d\n", nobs(r1)))
