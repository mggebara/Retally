suppressPackageStartupMessages({
  library(haven); library(dplyr); library(tidyr); library(fixest)
})
set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/seeded/2026-11-02-b/mount/carrera_2022_who_chooses_commitment"
d <- read_dta(file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta"))
d <- zap_labels(d)
d$id <- seq_len(nrow(d))

d <- d %>% mutate(
  first_info = as.integer(type_of_info == "1-onlygraph"),
  new_info   = as.integer(type_of_info == "2-graphplus"),
  control_info = as.integer(new_info == 0 & first_info == 0),
  wave2 = as.integer(wave == "winter"),
  wave3 = as.integer(wave == "spring"),
  commit8  = ifelse(is.na(q169), NA, as.integer(q169 == 2)),
  commit12 = chose_commit12,
  commit16 = ifelse(is.na(q295), NA, as.integer(q295 == 2))
)

# exogenously assigned incentive sample
d <- d %>% filter(flag_low_wtp == 0, flag_exclude_exog == 0)

# expected attendance under assigned incentive
d$days_exp <- NA_real_
for (i in c(0, 1, 2, 3, 5, 7)) {
  sel <- !is.na(d$incentive) & d$incentive == i
  d$days_exp[sel] <- d[[paste0("days_", i)]][sel]
}
d <- d %>% mutate(
  gap_goal_exp = goal - days_0,
  gap_actual_exp = visits - days_exp,
  delta2 = (wtp2 - wtp1) - (days_2 + days_1) / 2,
  delta3 = (wtp3 - wtp2) - (days_3 + days_2) / 2,
  delta5 = (wtp5 - wtp3) / (5 - 3) - (days_5 + days_3) / 2,
  delta7 = (wtp7 - wtp5) / (7 - 5) - (days_7 + days_5) / 2,
  delta12 = (wtp12 - wtp7) / (12 - 7) - (days_12 + days_7) / 2,
  avg_delta_ex1 = (delta2 + delta3 + delta5 + delta7 + delta12) / 5
)

restrict <- !is.na(d$incentive)
zs <- function(v) {
  m <- mean(v[restrict], na.rm = TRUE); s <- sd(v[restrict], na.rm = TRUE)
  ifelse(restrict, (v - m) / s, NA)
}
d$z_gap_goal_exp <- zs(d$gap_goal_exp)
d$z_gap_actual_exp <- zs(d$gap_actual_exp)
d$z_avg_delta_ex1 <- zs(d$avg_delta_ex1)

ds <- d[restrict, ]
t3 <- list(
  feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info, data = ds, vcov = "hetero"),
  feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_goal_exp, data = ds, vcov = "hetero"),
  feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_actual_exp, data = ds, vcov = "hetero")
)
for (m in t3) print(summary(m))

# pooled contract take-up
dl <- ds %>% select(id, wave2, wave3, first_info, new_info, z_avg_delta_ex1,
                    z_gap_goal_exp, z_gap_actual_exp, commit8, commit12, commit16) %>%
  pivot_longer(c(commit8, commit12, commit16), names_to = "t", names_prefix = "commit",
               values_to = "commit") %>%
  mutate(t = factor(as.integer(t)))
t4 <- list(
  feols(commit ~ i(t) + wave2 + wave3 + first_info + new_info, data = dl, cluster = ~id),
  feols(commit ~ i(t) + wave2 + wave3 + z_avg_delta_ex1 + first_info + new_info, data = dl, cluster = ~id),
  feols(commit ~ i(t) + wave2 + wave3 + z_gap_goal_exp + first_info + new_info, data = dl, cluster = ~id),
  feols(commit ~ i(t) + wave2 + wave3 + z_gap_actual_exp + first_info + new_info, data = dl, cluster = ~id)
)
for (m in t4) print(summary(m))
cat("Table3 N:", sapply(t3, nobs), "\nTable4 N:", sapply(t4, nobs), "\n")

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", coef(t3[[1]])["first_info"]))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", coef(t3[[1]])["new_info"]))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", coef(t3[[2]])["z_gap_goal_exp"]))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", coef(t3[[3]])["z_gap_actual_exp"]))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(t3[[1]])))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", coef(t4[[1]])["first_info"]))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", coef(t4[[1]])["new_info"]))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", coef(t4[[2]])["z_avg_delta_ex1"]))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", coef(t4[[3]])["z_gap_goal_exp"]))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", coef(t4[[4]])["z_gap_actual_exp"]))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t4[[1]])))
