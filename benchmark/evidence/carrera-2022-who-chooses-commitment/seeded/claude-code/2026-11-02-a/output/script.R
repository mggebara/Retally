# Carrera et al. (2022) "Who Chooses Commitment?" -- Tables 3 and 4
# Translation of Code/Stata/Tables.do (regs_avg_delta_ex1_all / regs_commit_pooled_all)
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/seeded/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$id <- seq_len(nrow(d))

d <- d %>% mutate(
  first_info = as.numeric(type_of_info == "1-onlygraph"),
  new_info   = as.numeric(type_of_info == "2-graphplus"),
  wave2 = as.numeric(wave == "winter"),
  wave3 = as.numeric(wave == "spring"),
  commit8  = ifelse(is.na(q169), NA, as.numeric(q169 == 2)),
  commit12 = chose_commit12,
  commit16 = ifelse(is.na(q295), NA, as.numeric(q295 == 2))
)

# Restrict to exogenously assigned incentives
d <- d %>% filter(flag_low_wtp == 0 & flag_exclude_exog == 0)

# Expected attendance under assigned incentive
d$days_exp <- NA_real_
for (i in c(0, 1, 2, 3, 5, 7)) {
  sel <- !is.na(d$incentive) & d$incentive == i
  d$days_exp[sel] <- d[[paste0("days_", i)]][sel]
}
d <- d %>% mutate(
  gap_goal_exp   = goal - days_0,
  gap_actual_exp = visits - days_exp,
  delta2  = (wtp2 - wtp1) - (days_2 + days_1) / 2,
  delta3  = (wtp3 - wtp2) - (days_3 + days_2) / 2,
  delta5  = (wtp5 - wtp3) / (5 - 3) - (days_5 + days_3) / 2,
  delta7  = (wtp7 - wtp5) / (7 - 5) - (days_7 + days_5) / 2,
  delta12 = (wtp12 - wtp7) / (12 - 7) - (days_12 + days_7) / 2,
  avg_delta_ex1 = (delta2 + delta3 + delta5 + delta7 + delta12) / 5
)

restrict <- !is.na(d$incentive)
for (v in c("gap_goal_exp", "gap_actual_exp", "avg_delta_ex1")) {
  x <- d[[v]][restrict]
  m <- mean(x, na.rm = TRUE); s <- sd(x, na.rm = TRUE)
  z <- (d[[v]] - m) / s
  z[!restrict] <- NA
  d[[paste0("z_", v)]] <- z
}

ds <- d[restrict, ]

# Table 3: OLS with wave dummies, robust (HC1) SEs
t3_1 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info, data = ds, vcov = "hetero")
t3_2 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_goal_exp, data = ds, vcov = "hetero")
t3_3 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_actual_exp, data = ds, vcov = "hetero")
print(etable(t3_1, t3_2, t3_3))

# Table 4: pooled LPM over thresholds, threshold FE + wave dummies, clustered by id
dl <- ds %>%
  select(id, wave2, wave3, first_info, new_info, z_avg_delta_ex1, z_gap_goal_exp, z_gap_actual_exp,
         commit8, commit12, commit16) %>%
  pivot_longer(c(commit8, commit12, commit16), names_to = "t", names_prefix = "commit", values_to = "commit") %>%
  mutate(t = as.integer(t))

t4_1 <- feols(commit ~ wave2 + wave3 + first_info + new_info | t, data = dl, cluster = ~id, fixef.rm = "none")
t4_2 <- feols(commit ~ wave2 + wave3 + z_avg_delta_ex1 + first_info + new_info | t, data = dl, cluster = ~id, fixef.rm = "none")
t4_3 <- feols(commit ~ wave2 + wave3 + z_gap_goal_exp + first_info + new_info | t, data = dl, cluster = ~id, fixef.rm = "none")
t4_4 <- feols(commit ~ wave2 + wave3 + z_gap_actual_exp + first_info + new_info | t, data = dl, cluster = ~id, fixef.rm = "none")
print(etable(t4_1, t4_2, t4_3, t4_4))

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", coef(t3_1)[["first_info"]]))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", coef(t3_1)[["new_info"]]))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", coef(t3_2)[["z_gap_goal_exp"]]))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", coef(t3_3)[["z_gap_actual_exp"]]))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(t3_1)))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", coef(t4_1)[["first_info"]]))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", coef(t4_1)[["new_info"]]))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", coef(t4_2)[["z_avg_delta_ex1"]]))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", coef(t4_3)[["z_gap_goal_exp"]]))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", coef(t4_4)[["z_gap_actual_exp"]]))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t4_1)))
