# Carrera et al. (2022) "Who Chooses Commitment?" -- independent, blind reproduction
# Tables 3 and 4: behavior change premium (BCP) and "more" contract take-up on
# information treatments and proxies for sophistication.
suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)

d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-07-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$pid <- seq_len(nrow(d))

# --- Sample ---------------------------------------------------------------
# Drop the 44 participants with endogenously assigned incentives (12 fixed-payment
# draws > $7, 32 WTP within $0-$7 range), and wave-3 participants assigned the
# $80-for-12-visits commitment contract (122 after the flag exclusion).
s <- d %>%
  filter(flag_exclude_exog == 0, flag_low_wtp == 0) %>%
  filter(treatment != "threshold80_12")

# --- Variables ------------------------------------------------------------
s <- s %>% mutate(
  basic_info    = as.numeric(type_of_info == "1-onlygraph"),
  enhanced_info = as.numeric(type_of_info == "2-graphplus"),
  wave_f = factor(wavenum),
  # conservative BCP: adjacent positive piece rates (excluding $0->$1 pair)
  bcp_12  = (wtp2  - wtp1) / 1 - (days_1 + days_2)  / 2,
  bcp_23  = (wtp3  - wtp2) / 1 - (days_2 + days_3)  / 2,
  bcp_35  = (wtp5  - wtp3) / 2 - (days_3 + days_5)  / 2,
  bcp_57  = (wtp7  - wtp5) / 2 - (days_5 + days_7)  / 2,
  bcp_712 = (wtp12 - wtp7) / 5 - (days_7 + days_12) / 2,
  bcp = (bcp_12 + bcp_23 + bcp_35 + bcp_57 + bcp_712) / 5,
  exp_assigned = case_when(incentive == 0 ~ days_0, incentive == 1 ~ days_1,
                           incentive == 2 ~ days_2, incentive == 3 ~ days_3,
                           incentive == 5 ~ days_5, incentive == 7 ~ days_7),
  goal_gap   = goal - days_0,
  actual_gap = visits - exp_assigned
)
stopifnot(!any(is.na(s$exp_assigned)))
z <- function(x) (x - mean(x)) / sd(x)
s <- s %>% mutate(goal_gap_z = z(goal_gap), actual_gap_z = z(actual_gap), bcp_z = z(bcp))

cat("Participants:", nrow(s), " by wave:", table(s$wavenum), "\n")
cat("BCP mean:", mean(s$bcp), " info-control mean:", mean(s$bcp[s$type_of_info == "0-none"]), "\n")
cat("goal gap mean/sd:", mean(s$goal_gap), sd(s$goal_gap),
    " actual gap mean/sd:", mean(s$actual_gap), sd(s$actual_gap), "\n")

# --- Table 3 --------------------------------------------------------------
t3_1 <- feols(bcp ~ basic_info + enhanced_info | wave_f, data = s, vcov = "hetero")
t3_2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave_f, data = s, vcov = "hetero")
t3_3 <- feols(bcp ~ basic_info + enhanced_info + actual_gap_z | wave_f, data = s, vcov = "hetero")
etable(t3_1, t3_2, t3_3)

# --- Table 4 --------------------------------------------------------------
# "More" contracts: q169 (>=8) and q295 (>=16) coded 2 = chose (waves 1-2 only);
# chose_commit12 (>=12) coded 1 = chose (all waves).
long <- bind_rows(
  s %>% filter(wavenum < 3) %>% transmute(pid, wave_f, basic_info, enhanced_info, bcp_z,
        goal_gap_z, actual_gap_z, threshold = 8,  takeup = as.numeric(q169 == 2)),
  s %>% transmute(pid, wave_f, basic_info, enhanced_info, bcp_z,
        goal_gap_z, actual_gap_z, threshold = 12, takeup = as.numeric(chose_commit12 == 1)),
  s %>% filter(wavenum < 3) %>% transmute(pid, wave_f, basic_info, enhanced_info, bcp_z,
        goal_gap_z, actual_gap_z, threshold = 16, takeup = as.numeric(q295 == 2))
) %>% mutate(thr_f = factor(threshold))
stopifnot(!any(is.na(long$takeup)))
cat("Take-up by threshold:\n"); print(tapply(long$takeup, long$threshold, mean))
cat("Take-up mean:", mean(long$takeup), "\n")

t4_1 <- feols(takeup ~ basic_info + enhanced_info | wave_f + thr_f, data = long, cluster = ~pid)
t4_2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wave_f + thr_f, data = long, cluster = ~pid)
t4_3 <- feols(takeup ~ basic_info + enhanced_info + goal_gap_z | wave_f + thr_f, data = long, cluster = ~pid)
t4_4 <- feols(takeup ~ basic_info + enhanced_info + actual_gap_z | wave_f + thr_f, data = long, cluster = ~pid)
etable(t4_1, t4_2, t4_3, t4_4)

r <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))
r("bcp_basic_info_treatment_col1", coef(t3_1)["basic_info"])
r("bcp_enhanced_info_treatment_col1", coef(t3_1)["enhanced_info"])
r("bcp_goal_minus_expected_attendance_col2", coef(t3_2)["goal_gap_z"])
r("bcp_actual_minus_expected_attendance_col3", coef(t3_3)["actual_gap_z"])
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(t3_1)))
r("takeup_more_basic_info_treatment_col1", coef(t4_1)["basic_info"])
r("takeup_more_enhanced_info_treatment_col1", coef(t4_1)["enhanced_info"])
r("takeup_more_behavior_change_premium_col2", coef(t4_2)["bcp_z"])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4_3)["goal_gap_z"])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4_4)["actual_gap_z"])
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t4_1)))
