## Independent reproduction: Dertwinkel-Kalt et al. (2022), Concentration Bias in Intertemporal Choice
## Tables 2 and 3 (consumption experiment), built from the raw per-decision data.
suppressMessages({library(dplyr); library(sandwich); library(lmtest); library(AER)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/independent/2026-10-22-a/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read.csv(f, stringsAsFactors = FALSE)

## Parameters from the paper (footnote 3): mandatory tasks per workday
e <- c(129, 132, 143, 115, 121, 117, 135, 127)

## Condition labels: main=1 & dispersed=0 -> Main; dispersed=1 -> Mechanism; pizza=0 -> Donation
d$cond <- with(d, ifelse(pizza == 0, "Donation", ifelse(dispersed == 1, "Mechanism", "Main")))
d$arm  <- ifelse(d$treatment == 1, "Treatment", "Control")

## Balanced trade-offs: decisions 1-8, utility_point = workday j, indifference_point = x~_j
bal <- d %>% filter(decision_number <= 8)
xw <- bal %>% group_by(tn) %>%
  summarise(any_corner = any(corner != 0),
            x1 = indifference_point[utility_point == 1], x2 = indifference_point[utility_point == 2],
            x3 = indifference_point[utility_point == 3], x4 = indifference_point[utility_point == 4],
            x5 = indifference_point[utility_point == 5], x6 = indifference_point[utility_point == 6],
            x7 = indifference_point[utility_point == 7], x8 = indifference_point[utility_point == 8],
            .groups = "drop")
fin <- d %>% filter(decision_number == 9) %>%
  select(tn, cond, arm, corner, ip9 = indifference_point, j9 = utility_point, id_stage2, pap_sample)
s <- inner_join(fin, xw, by = "tn")

## Final-trade-off deviation d~: interior choices directly; upper corner -> lower bound = top of range;
## upper bound = manually stated indifference point; midpoint = average of the two.
## Lower-corner choices take the bottom of the range.
cat("Range of interior final-choice d (corner==0):", range(s$ip9[s$corner == 0]), "\n")
cat("Coded value of id_stage2 for upper-corner subjects:", unique(s$id_stage2[s$corner == 1]), "\n")
cat("Coded value of id_stage2 for lower-corner subjects:", unique(s$id_stage2[s$corner == -1]), "\n")
TOP <- 63; BOT <- -63      # coding used in the data for the ends of the elicitation range
s <- s %>% mutate(
  d_low = ifelse(corner == 1, TOP, ifelse(corner == -1, BOT, ip9)),
  d_up  = ifelse(corner == 1, ip9, d_low),
  d_mid = (d_low + d_up) / 2)

## Relative measure: Treatment = (1/8) sum_t d/(e_t + x_t); Control = d/(e_j + x_j) for the repeated day j
X <- as.matrix(s[, paste0("x", 1:8)])
inv_mean <- rowMeans(1 / sweep(X, 2, e, "+"))
inv_j <- 1 / (e[s$j9] + X[cbind(seq_len(nrow(s)), s$j9)])
s$w <- ifelse(s$arm == "Treatment", inv_mean, inv_j)
s <- s %>% mutate(rel_low = d_low * w, rel_mid = d_mid * w, rel_up = d_up * w)

## Main sample: preregistered exclusion of any corner choice in the balanced trade-offs
s$keep <- !s$any_corner
cat("Agreement of own exclusion with pap_sample:\n"); print(table(own = s$keep, pap = s$pap_sample, useNA = "a"))
## Seven subjects pass the corner exclusion but are not flagged pap_sample (the data's preregistered
## main-sample indicator); the paper reports exactly 100 subjects per condition (the preregistered
## sample size), so the main sample is the pap_sample flag, which is a subset of the corner exclusion.
print(s %>% filter(keep, pap_sample %in% 0) %>% select(tn, cond, arm, corner, ip9))
ms <- s %>% filter(keep, pap_sample %in% 1)
print(table(ms$cond, ms$arm))

rob <- function(m) coeftest(m, vcov = vcovHC(m, type = "HC1"))

## Table 2
mt <- ms %>% filter(cond == "Main", arm == "Treatment")
t2 <- list()
for (v in c("d_low", "d_mid", "d_up", "rel_low", "rel_mid", "rel_up")) {
  m <- lm(as.formula(paste(v, "~ 1")), data = mt); t2[[v]] <- rob(m); print(v); print(t2[[v]])
}
tob <- tobit(d_low ~ 1, left = BOT, right = TOP, data = mt)
print(summary(tob))

## Table 3: OLS of rel_mid on constant + indicator, robust SE
reg2 <- function(dat, ref_cond, ref_arm) {
  dat$ind <- as.numeric(!(dat$cond == ref_cond & dat$arm == ref_arm))
  m <- lm(rel_mid ~ ind, data = dat); r <- rob(m); print(r); list(coef = coef(m), n = nobs(m))
}
c1 <- reg2(ms %>% filter(arm == "Treatment", cond %in% c("Main", "Mechanism")), "Mechanism", "Treatment")
c2 <- reg2(ms %>% filter(cond == "Donation"), "Donation", "Control")
c3 <- reg2(ms %>% filter(cond == "Main"), "Main", "Control")
c4 <- reg2(ms %>% filter(cond == "Mechanism"), "Mechanism", "Control")
don_tr <- mean(ms$rel_mid[ms$cond == "Donation" & ms$arm == "Treatment"])

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.4f\n", t2$d_mid[1, 1]))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.4f\n", coef(tob)[1]))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.4f\n", t2$rel_low[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.4f\n", t2$rel_mid[1, 1]))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.4f\n", t2$rel_up[1, 1]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(mt)))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.4f\n", c1$coef[1]))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.4f\n", c1$coef[2]))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.4f\n", don_tr))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.4f\n", c2$coef[2]))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.4f\n", c3$coef[2]))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.4f\n", c4$coef[2]))
cat(sprintf("RESULT:n_obs_table3=%d\n", c3$n))
cat("N per Table 3 column:", c1$n, c2$n, c3$n, c4$n, "\n")
