## Independent reproduction: Dertwinkel-Kalt et al. (2022), Tables 2-3 (consumption experiment)
suppressMessages({library(dplyr); library(sandwich); library(lmtest); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-11-01-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read.csv(f)
e <- c(129,132,143,115,121,117,135,127)   # mandatory tasks per workday (paper fn. 3)

## balanced trade-offs: indifference points x_t (decision_number 1..8 = trade-off j = t)
bal <- d %>% filter(decision_number <= 8) %>% arrange(tn, decision_number)
xw <- bal %>% group_by(tn) %>% summarise(
  denom_inv = mean(1/(e[utility_point] + indifference_point)),   # utility_point = trade-off j (decision_number is presentation order)
  n_bal_corner = sum(corner != 0, na.rm = TRUE), .groups = "drop")

## final trade-off (decision 9): d~
fin <- d %>% filter(decision_number == 9) %>%
  select(tn, treatment, control, main, dispersed, pizza, pap_sample, corner,
         indifference_point, id_stage2, id_stage2_upper)
s <- fin %>% left_join(xw, by = "tn")

## condition labels
s <- s %>% mutate(cond = case_when(
  pizza == 1 & main == 1 & control == 0 ~ "MainT",
  pizza == 1 & main == 1 & control == 1 ~ "MainC",
  pizza == 1 & dispersed == 1 & control == 0 ~ "MechT",
  pizza == 1 & dispersed == 1 & control == 1 ~ "MechC",
  pizza == 0 & control == 0 ~ "DonT",
  pizza == 0 & control == 1 ~ "DonC"))

## main sample: preregistered exclusion of subjects with a corner choice in any balanced trade-off
## (the data's preregistered-sample flag pap_sample implements this; a pure corner-based filter keeps 0-3 extra subjects per condition)
cat("Corner-filter sizes:\n"); print(table(s$cond[s$n_bal_corner == 0 & !is.na(s$id_stage2)]))
s <- s %>% filter(pap_sample == 1)
stopifnot(all(s$n_bal_corner == 0))
cat("Sample sizes after exclusion:\n"); print(table(s$cond))
cat("Cross-check with pap_sample flag:\n"); print(table(s$cond, s$pap_sample, useNA = "ifany"))

## upper corner in final trade-off: lower bound 62, upper bound = manually stated, midpoint
upc <- s$corner == 1
cat("Upper-corner subjects:", sum(upc), " values of id_stage2 among them:", paste(unique(s$id_stage2[upc]), collapse=","), "\n")
s <- s %>% mutate(
  d_low = id_stage2,   # recorded lower bound (63 for upper-corner subjects in the data; paper text says 62)
  d_up  = ifelse(corner == 1, id_stage2_upper, indifference_point),
  d_mid = (d_low + d_up) / 2,
  drel_low = d_low * denom_inv, drel_mid = d_mid * denom_inv, drel_up = d_up * denom_inv)

## sanity: balanced means in Main-Treatment vs eq. (10)
mt <- s %>% filter(cond == "MainT")
cat("Mean x_t in Main-Treatment main sample:\n")
print(round(tapply(bal$indifference_point[bal$tn %in% mt$tn], bal$utility_point[bal$tn %in% mt$tn], mean), 1))
stopifnot(all(mt$d_low[mt$corner != 1] == mt$indifference_point[mt$corner != 1]))

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))
## Table 2
t2 <- lapply(c("d_low","d_mid","d_up","drel_low","drel_mid","drel_up"), function(v) rob(lm(as.formula(paste(v, "~ 1")), data = mt)))
names(t2) <- c("d_low","d_mid","d_up","drel_low","drel_mid","drel_up"); print(t2)
## Tobit on lower-bound measure, censored at the ends of the elicitation range (-63, and 63 as coded)
tb <- tobit(d_low ~ 1, left = -63, right = 63, data = mt); print(summary(tb))

## Table 3: OLS of drel_mid on constant + indicator, robust SE
t3 <- function(a, b) { dd <- s %>% filter(cond %in% c(a, b)) %>% mutate(ind = as.integer(cond == a))
  m <- lm(drel_mid ~ ind, data = dd); print(rob(m)); list(m = m, n = nrow(dd)) }
c1 <- t3("MainT", "MechT"); c2 <- t3("DonT", "DonC"); c3 <- t3("MainT", "MainC"); c4 <- t3("MechT", "MechC")
## Donation-Treatment level (col 2 row): mean in DonT
donT <- coef(lm(drel_mid ~ 1, data = s %>% filter(cond == "DonT")))[1]

cat("DEVIATION: upper-corner lower bound taken as recorded id_stage2 (=63) rather than 62 as in paper text; Tobit right-censoring at 63\n")
cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.4f\n", coef(t2$d_mid)[1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.4f\n", coef(tb)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.4f\n", t2$drel_low[1,1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.4f\n", t2$drel_mid[1,1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.4f\n", t2$drel_up[1,1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(mt)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.4f\n", coef(c1$m)[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.4f\n", coef(c1$m)[2]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.4f\n", donT))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.4f\n", coef(c2$m)[2]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.4f\n", coef(c3$m)[2]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.4f\n", coef(c4$m)[2]))
cat(sprintf("RESULT:n_obs_table3=%d\n", c1$n))
