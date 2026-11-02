## Carrera et al. (2022) "Who Chooses Commitment?" -- Tables 3 and 4, independent reproduction
suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-b/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/"
d <- read_dta(paste0(base, "cleaned_commitment_study_data.dta"))
d <- zap_labels(d)

## Sample: exogenously assigned incentives (drop the 44 flagged endogenous assignments)
## and drop wave-3 participants assigned the $80-for-12-visits commitment contract.
cat("flag_exclude_exog:", sum(d$flag_exclude_exog), " flag_low_wtp:", sum(d$flag_low_wtp),
    " either:", sum(d$flag_exclude_exog == 1 | d$flag_low_wtp == 1), "\n")
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0, treatment != "threshold80_12")
cat("N sample:", nrow(s), "\n")

## Behavior change premium, conservative measure (pairs of positive piece rates)
p <- c(1, 2, 3, 5, 7, 12)
bcp_pairs <- sapply(1:5, function(k) {
  lo <- p[k]; hi <- p[k + 1]
  (s[[paste0("wtp", hi)]] - s[[paste0("wtp", lo)]]) / (hi - lo) -
    (s[[paste0("days_", lo)]] + s[[paste0("days_", hi)]]) / 2
})
s$bcp <- rowMeans(bcp_pairs)

s <- s %>% mutate(
  basic_info = as.numeric(type_of_info == "1-onlygraph"),
  enh_info = as.numeric(type_of_info == "2-graphplus"),
  exp_assigned = case_when(incentive == 0 ~ days_0, incentive == 1 ~ days_1, incentive == 2 ~ days_2,
                           incentive == 3 ~ days_3, incentive == 5 ~ days_5, incentive == 7 ~ days_7),
  goal_gap_raw = goal - days_0,
  act_gap_raw = visits - exp_assigned)
z <- function(x) (x - mean(x)) / sd(x)
s <- s %>% mutate(goal_gap = z(goal_gap_raw), act_gap = z(act_gap_raw), bcp_z = z(bcp))
cat(sprintf("goal gap raw mean %.2f sd %.2f; actual gap raw mean %.2f sd %.2f\n",
            mean(s$goal_gap_raw), sd(s$goal_gap_raw), mean(s$act_gap_raw), sd(s$act_gap_raw)))
cat(sprintf("BCP mean %.3f; info control mean %.3f\n", mean(s$bcp), mean(s$bcp[s$type_of_info == "0-none"])))

## Table 3
t3c1 <- feols(bcp ~ basic_info + enh_info | wavenum, s, vcov = "hetero")
t3c2 <- feols(bcp ~ basic_info + enh_info + goal_gap | wavenum, s, vcov = "hetero")
t3c3 <- feols(bcp ~ basic_info + enh_info + act_gap | wavenum, s, vcov = "hetero")
etable(t3c1, t3c2, t3c3)

## Table 4: long data of "more" contract choices (8, 12, 16 in waves 1-2; 12 in wave 3)
s$id_row <- seq_len(nrow(s))
## q169 / q295 are raw survey codes (1 = $80 fixed payment, 2 = $80 conditional contract);
## coding 2 as take-up gives the paper's 64% (8 visits) and 32% (16 visits) take-up rates.
s <- s %>% mutate(more8 = ifelse(is.na(q169), NA, as.numeric(q169 == 2)),
                  more12 = chose_commit12,
                  more16 = ifelse(is.na(q295), NA, as.numeric(q295 == 2)))
long <- s %>% select(id_row, wavenum, basic_info, enh_info, bcp_z, goal_gap, act_gap, more8, more12, more16) %>%
  pivot_longer(c(more8, more12, more16), names_to = "thr", values_to = "takeup") %>%
  filter(!is.na(takeup))
cat("Take-up by threshold:\n"); print(long %>% group_by(thr) %>% summarise(n = n(), m = mean(takeup)))
cat("N long:", nrow(long), " clusters:", length(unique(long$id_row)), "\n")
t4c1 <- feols(takeup ~ basic_info + enh_info | wavenum + thr, long, cluster = ~id_row)
t4c2 <- feols(takeup ~ basic_info + enh_info + bcp_z | wavenum + thr, long, cluster = ~id_row)
t4c3 <- feols(takeup ~ basic_info + enh_info + goal_gap | wavenum + thr, long, cluster = ~id_row)
t4c4 <- feols(takeup ~ basic_info + enh_info + act_gap | wavenum + thr, long, cluster = ~id_row)
etable(t4c1, t4c2, t4c3, t4c4)

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("bcp_basic_info_treatment_col1", coef(t3c1)["basic_info"])
r("bcp_enhanced_info_treatment_col1", coef(t3c1)["enh_info"])
r("bcp_goal_minus_expected_attendance_col2", coef(t3c2)["goal_gap"])
r("bcp_actual_minus_expected_attendance_col3", coef(t3c3)["act_gap"])
r("bcp_regression_observations", nobs(t3c1))
r("takeup_more_basic_info_treatment_col1", coef(t4c1)["basic_info"])
r("takeup_more_enhanced_info_treatment_col1", coef(t4c1)["enh_info"])
r("takeup_more_behavior_change_premium_col2", coef(t4c2)["bcp_z"])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4c3)["goal_gap"])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4c4)["act_gap"])
r("takeup_more_regression_observations", nobs(t4c1))
