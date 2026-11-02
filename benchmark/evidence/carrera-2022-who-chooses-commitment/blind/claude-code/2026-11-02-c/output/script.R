# Carrera et al. (2022) "Who Chooses Commitment?" -- Tables 3 and 4 (independent, blind reproduction)
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-c/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$pid <- seq_len(nrow(d))

# --- Sample: exogenously assigned incentive (drop the 44 endogenous-assignment cases),
#     and drop wave 3 participants assigned the $80-for-12-visits commitment contract.
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0, treatment != "threshold80_12")

# --- Behavior change premium (conservative: positive piece-rates only, excludes $0->$1)
#     BCP(p,D) = [w(p+D) - w(p)]/D - [alpha(p+D) + alpha(p)]/2, averaged over pairs
pr <- c(1, 2, 3, 5, 7, 12)
bcp_mat <- sapply(1:(length(pr) - 1), function(k) {
  p0 <- pr[k]; p1 <- pr[k + 1]
  (s[[paste0("wtp", p1)]] - s[[paste0("wtp", p0)]]) / (p1 - p0) -
    (s[[paste0("days_", p1)]] + s[[paste0("days_", p0)]]) / 2
})
s$bcp <- rowMeans(bcp_mat)

# --- Proxies
s$basic_info    <- as.numeric(s$type_of_info == "1-onlygraph")
s$enhanced_info <- as.numeric(s$type_of_info == "2-graphplus")
s$goal_gap <- s$goal - s$days_0
exp_assigned <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
s$actual_gap <- s$visits - exp_assigned

s <- s %>% filter(!is.na(bcp), !is.na(goal_gap), !is.na(actual_gap))
z <- function(x) (x - mean(x)) / sd(x)
s$goal_gap_z   <- z(s$goal_gap)
s$actual_gap_z <- z(s$actual_gap)
s$bcp_z        <- z(s$bcp)

cat("Participants in sample:", nrow(s), "\n")
cat("Mean BCP:", mean(s$bcp), " info control mean:", mean(s$bcp[s$basic_info == 0 & s$enhanced_info == 0]), "\n")
cat("goal gap mean/sd:", mean(s$goal_gap), sd(s$goal_gap), " actual gap mean/sd:", mean(s$actual_gap), sd(s$actual_gap), "\n")

# --- Table 3: OLS, wave FE, heteroskedasticity-robust SEs
t3_1 <- feols(bcp ~ basic_info + enhanced_info | wave, data = s, vcov = "hetero")
t3_2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave, data = s, vcov = "hetero")
t3_3 <- feols(bcp ~ basic_info + enhanced_info + actual_gap_z | wave, data = s, vcov = "hetero")
etable(t3_1, t3_2, t3_3)

# --- Table 4: stacked "more" contract choices (q169: >=8, chose_commit12: >=12, q295: >=16;
#     q169/q295 coded 1/2 with 2 = chose the contract; asked only in waves 1-2)
long <- s %>%
  mutate(more_8 = ifelse(is.na(q169), NA, as.numeric(q169 == 2)),
         more_12 = chose_commit12,
         more_16 = ifelse(is.na(q295), NA, as.numeric(q295 == 2))) %>%
  select(pid, wave, basic_info, enhanced_info, goal_gap_z, actual_gap_z, bcp_z, more_8, more_12, more_16) %>%
  pivot_longer(c(more_8, more_12, more_16), names_to = "threshold", values_to = "takeup") %>%
  filter(!is.na(takeup))
cat("Take-up by threshold:\n"); print(tapply(long$takeup, long$threshold, mean))

t4_1 <- feols(takeup ~ basic_info + enhanced_info | wave + threshold, data = long, cluster = ~pid)
t4_2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wave + threshold, data = long, cluster = ~pid)
t4_3 <- feols(takeup ~ basic_info + enhanced_info + goal_gap_z | wave + threshold, data = long, cluster = ~pid)
t4_4 <- feols(takeup ~ basic_info + enhanced_info + actual_gap_z | wave + threshold, data = long, cluster = ~pid)
etable(t4_1, t4_2, t4_3, t4_4)
cat("Clusters:", length(unique(long$pid)), "\n")

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", coef(t3_1)["basic_info"]))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", coef(t3_1)["enhanced_info"]))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", coef(t3_2)["goal_gap_z"]))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", coef(t3_3)["actual_gap_z"]))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(t3_1)))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", coef(t4_1)["basic_info"]))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", coef(t4_1)["enhanced_info"]))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", coef(t4_2)["bcp_z"]))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", coef(t4_3)["goal_gap_z"]))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", coef(t4_4)["actual_gap_z"]))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t4_1)))
