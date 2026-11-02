# Carrera et al. (2022) "Who Chooses Commitment?" -- Tables 3 and 4 (independent, blind)
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$sid <- seq_len(nrow(d))
cat("Raw participants:", nrow(d), "\n")

# Sample: exogenously assigned incentives (drop the 44 endogenous-assignment cases,
# Section 3) and drop wave-3 participants assigned the $80/12-visit commitment contract.
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0, treatment != "threshold80_12")
cat("Regression sample:", nrow(s), "\n")

# Information treatment indicators
s <- s %>% mutate(
  basic    = as.numeric(type_of_info == "1-onlygraph"),
  enhanced = as.numeric(type_of_info == "2-graphplus"),
  wavef    = factor(wavenum))

# Conservative behavior change premium (excludes $0->$1 pair):
# BCP(p,D) = [w(p+D)-w(p)]/D - [a(p)+a(p+D)]/2, averaged over pairs
pairs <- list(c(1,2), c(2,3), c(3,5), c(5,7), c(7,12))
bcpmat <- sapply(pairs, function(pp) {
  p <- pp[1]; q <- pp[2]; D <- q - p
  (s[[paste0("wtp", q)]] - s[[paste0("wtp", p)]]) / D -
    (s[[paste0("days_", p)]] + s[[paste0("days_", q)]]) / 2
})
s$bcp <- rowMeans(bcpmat)

# Proxies
s$goal_gap <- s$goal - s$days_0
exp_assigned <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
s$act_gap <- s$visits - exp_assigned
stopifnot(!anyNA(s$bcp), !anyNA(s$goal_gap), !anyNA(s$act_gap))
z <- function(x) (x - mean(x)) / sd(x)
s <- s %>% mutate(goal_gap_z = z(goal_gap), act_gap_z = z(act_gap), bcp_z = z(bcp))
cat(sprintf("Goal-exp mean %.3f sd %.3f; Actual-exp mean %.3f sd %.3f; BCP mean %.3f\n",
            mean(s$goal_gap), sd(s$goal_gap), mean(s$act_gap), sd(s$act_gap), mean(s$bcp)))
cat(sprintf("BCP mean info control: %.3f\n", mean(s$bcp[s$basic == 0 & s$enhanced == 0])))

# Table 3: OLS, wave FE, heteroskedasticity-robust (HC1) SEs
t3_1 <- feols(bcp ~ basic + enhanced | wavef, data = s, vcov = "hetero")
t3_2 <- feols(bcp ~ basic + enhanced + goal_gap_z | wavef, data = s, vcov = "hetero")
t3_3 <- feols(bcp ~ basic + enhanced + act_gap_z | wavef, data = s, vcov = "hetero")
print(etable(t3_1, t3_2, t3_3))

# Table 4: stacked "more" contract choices; waves 1-2: thresholds 8,12,16; wave 3: 12 only
long <- bind_rows(
  s %>% filter(wavenum %in% c(1, 2)) %>% mutate(thr = 8,  takeup = as.numeric(q169 == 2)),
  s %>% mutate(thr = 12, takeup = as.numeric(chose_commit12 == 1)),
  s %>% filter(wavenum %in% c(1, 2)) %>% mutate(thr = 16, takeup = as.numeric(q295 == 2))
) %>% filter(!is.na(takeup)) %>% mutate(thrf = factor(thr))
cat("Take-up rates by threshold:\n"); print(tapply(long$takeup, long$thr, mean))
cat("Stacked N:", nrow(long), " clusters:", length(unique(long$sid)), "\n")

t4_1 <- feols(takeup ~ basic + enhanced | wavef + thrf, data = long, cluster = ~sid)
t4_2 <- feols(takeup ~ basic + enhanced + bcp_z | wavef + thrf, data = long, cluster = ~sid)
t4_3 <- feols(takeup ~ basic + enhanced + goal_gap_z | wavef + thrf, data = long, cluster = ~sid)
t4_4 <- feols(takeup ~ basic + enhanced + act_gap_z | wavef + thrf, data = long, cluster = ~sid)
print(etable(t4_1, t4_2, t4_3, t4_4))

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("bcp_basic_info_treatment_col1", coef(t3_1)["basic"])
out("bcp_enhanced_info_treatment_col1", coef(t3_1)["enhanced"])
out("bcp_goal_minus_expected_attendance_col2", coef(t3_2)["goal_gap_z"])
out("bcp_actual_minus_expected_attendance_col3", coef(t3_3)["act_gap_z"])
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(t3_1)))
out("takeup_more_basic_info_treatment_col1", coef(t4_1)["basic"])
out("takeup_more_enhanced_info_treatment_col1", coef(t4_1)["enhanced"])
out("takeup_more_behavior_change_premium_col2", coef(t4_2)["bcp_z"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(t4_3)["goal_gap_z"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(t4_4)["act_gap_z"])
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t4_1)))
