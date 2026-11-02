suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- haven::read_dta(f)

to_chr <- function(x) {
  if (haven::is.labelled(x)) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
}
to_num <- function(x) as.numeric(haven::zap_labels(x))

d <- as.data.frame(d)
d$id <- seq_len(nrow(d))
wave_chr <- to_chr(d$wave)
info_chr <- to_chr(d$type_of_info)
info_chr[is.na(info_chr)] <- ""
wave_chr[is.na(wave_chr)] <- ""

d$first_info <- as.numeric(info_chr == "1-onlygraph")
d$new_info <- as.numeric(info_chr == "2-graphplus")
d$control_info <- as.numeric(d$first_info == 0 & d$new_info == 0)
d$wave1 <- as.numeric(wave_chr == "fall")
d$wave2 <- as.numeric(wave_chr == "winter")
d$wave3 <- as.numeric(wave_chr == "spring")

q169 <- to_num(d$q169); q295 <- to_num(d$q295)
d$commit8 <- ifelse(is.na(q169), NA_real_, as.numeric(q169 == 2))
d$commit12 <- to_num(d$chose_commit12)
d$commit16 <- ifelse(is.na(q295), NA_real_, as.numeric(q295 == 2))

numvars <- c("flag_low_wtp", "flag_exclude_exog", "incentive", "visits", "goal", "past4",
             paste0("days_", c(0, 1, 2, 3, 5, 7, 12)),
             paste0("wtp", c(1, 2, 3, 5, 7, 12)))
for (v in numvars) d[[v]] <- to_num(d[[v]])

# Restrict to exogenously assigned incentives
d <- d[!is.na(d$flag_low_wtp) & !is.na(d$flag_exclude_exog) &
         d$flag_low_wtp == 0 & d$flag_exclude_exog == 0, ]

# Expected attendance under assigned incentive
d$days_exp <- NA_real_
for (i in c(0, 1, 2, 3, 5, 7)) {
  sel <- !is.na(d$incentive) & d$incentive == i
  d$days_exp[sel] <- d[[paste0("days_", i)]][sel]
}
d$gap_goal_exp <- d$goal - d$days_0
d$gap_actual_exp <- d$visits - d$days_exp

d$delta2 <- (d$wtp2 - d$wtp1) - (d$days_2 + d$days_1) / 2
d$delta3 <- (d$wtp3 - d$wtp2) - (d$days_3 + d$days_2) / 2
d$delta5 <- (d$wtp5 - d$wtp3) / 2 - (d$days_5 + d$days_3) / 2
d$delta7 <- (d$wtp7 - d$wtp5) / 2 - (d$days_7 + d$days_5) / 2
d$delta12 <- (d$wtp12 - d$wtp7) / 5 - (d$days_12 + d$days_7) / 2
d$avg_delta_ex1 <- (d$delta2 + d$delta3 + d$delta5 + d$delta7 + d$delta12) / 5

restrict <- !is.na(d$incentive)

zscore <- function(x, r) {
  m <- mean(x[r], na.rm = TRUE); s <- sd(x[r], na.rm = TRUE)
  out <- (x - m) / s
  out[!r] <- NA
  out
}
d$z_gap_goal_exp <- zscore(d$gap_goal_exp, restrict)
d$z_gap_actual_exp <- zscore(d$gap_actual_exp, restrict)
d$z_avg_delta_ex1 <- zscore(d$avg_delta_ex1, restrict)

ds <- d[restrict, ]

# Table 3
t3_1 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info, data = ds, vcov = "hetero")
t3_2 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_goal_exp, data = ds, vcov = "hetero")
t3_3 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_actual_exp, data = ds, vcov = "hetero")

# Table 4: pool contracts
dl <- ds %>%
  dplyr::select(id, wave2, wave3, first_info, new_info, z_avg_delta_ex1, z_gap_goal_exp,
                z_gap_actual_exp, commit8, commit12, commit16) %>%
  tidyr::pivot_longer(cols = c(commit8, commit12, commit16), names_to = "t",
                      names_prefix = "commit", values_to = "commit") %>%
  as.data.frame()
dl$t <- factor(as.integer(dl$t))

t4_1 <- feols(commit ~ t + wave2 + wave3 + first_info + new_info, data = dl, cluster = ~id)
t4_2 <- feols(commit ~ t + wave2 + wave3 + z_avg_delta_ex1 + first_info + new_info, data = dl, cluster = ~id)
t4_3 <- feols(commit ~ t + wave2 + wave3 + z_gap_goal_exp + first_info + new_info, data = dl, cluster = ~id)
t4_4 <- feols(commit ~ t + wave2 + wave3 + z_gap_actual_exp + first_info + new_info, data = dl, cluster = ~id)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("bcp_basic_info_treatment_col1", coef(t3_1)["first_info"])
out("bcp_enhanced_info_treatment_col1", coef(t3_1)["new_info"])
out("bcp_goal_minus_expected_attendance_col2", coef(t3_2)["z_gap_goal_exp"])
out("bcp_actual_minus_expected_attendance_col3", coef(t3_3)["z_gap_actual_exp"])
out("bcp_regression_observations", nobs(t3_1))
out("takeup_more_basic_info_treatment_col1", coef(t4_1)["first_info"])
out("takeup_more_enhanced_info_treatment_col1", coef(t4_1)["new_info"])
out("takeup_more_behavior_change_premium_col2", coef(t4_2)["z_avg_delta_ex1"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(t4_3)["z_gap_goal_exp"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(t4_4)["z_gap_actual_exp"])
out("takeup_more_regression_observations", nobs(t4_1))
