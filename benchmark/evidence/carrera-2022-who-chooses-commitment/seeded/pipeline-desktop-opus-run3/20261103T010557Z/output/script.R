suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})

set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")

df <- haven::read_dta(f)
df <- haven::zap_labels(df)
df <- as.data.frame(df)

num <- function(x) suppressWarnings(as.numeric(x))
chr <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; x }

df$id <- seq_len(nrow(df))

# Info treatment indicators
toi <- chr(df$type_of_info)
df$first_info <- as.numeric(toi == "1-onlygraph")
df$new_info <- as.numeric(toi == "2-graphplus")
df$control_info <- as.numeric(df$new_info == 0 & df$first_info == 0)

# Wave indicators
wv <- chr(df$wave)
df$wave1 <- as.numeric(wv == "fall")
df$wave2 <- as.numeric(wv == "winter")
df$wave3 <- as.numeric(wv == "spring")

# Commitment choices
q169 <- num(df$q169); q295 <- num(df$q295)
df$commit8 <- ifelse(is.na(q169), NA_real_, as.numeric(q169 == 2))
df$commit12 <- num(df$chose_commit12)
df$commit16 <- ifelse(is.na(q295), NA_real_, as.numeric(q295 == 2))

# Restrict to exogenously assigned incentives
df <- df[!is.na(num(df$flag_low_wtp)) & num(df$flag_low_wtp) == 0 &
         !is.na(num(df$flag_exclude_exog)) & num(df$flag_exclude_exog) == 0, ]

# Numeric conversions
for (v in c("incentive", "visits", "goal", "past4",
            "wtp1", "wtp2", "wtp3", "wtp5", "wtp7", "wtp12",
            "days_0", "days_1", "days_2", "days_3", "days_5", "days_7", "days_12")) {
  df[[v]] <- num(df[[v]])
}

# Expected attendance under assigned incentive
df$days_exp <- NA_real_
for (i in c(0, 1, 2, 3, 5, 7)) {
  sel <- !is.na(df$incentive) & df$incentive == i
  df$days_exp[sel] <- df[[paste0("days_", i)]][sel]
}

df$gap_goal_exp <- df$goal - df$days_0
df$gap_actual_exp <- df$visits - df$days_exp

# Behavior change premium (second-order approximation), excluding $0-$1
df$delta2 <- (df$wtp2 - df$wtp1) - (df$days_2 + df$days_1) / 2
df$delta3 <- (df$wtp3 - df$wtp2) - (df$days_3 + df$days_2) / 2
df$delta5 <- (df$wtp5 - df$wtp3) / (5 - 3) - (df$days_5 + df$days_3) / 2
df$delta7 <- (df$wtp7 - df$wtp5) / (7 - 5) - (df$days_7 + df$days_5) / 2
df$delta12 <- (df$wtp12 - df$wtp7) / (12 - 7) - (df$days_12 + df$days_7) / 2
df$avg_delta_ex1 <- (df$delta2 + df$delta3 + df$delta5 + df$delta7 + df$delta12) / 5

# Restriction: incentive non-missing
restrict <- !is.na(df$incentive)

# z-scores over restricted sample (Stata sum uses non-missing values)
for (v in c("gap_goal_exp", "gap_actual_exp", "avg_delta_ex1")) {
  x <- df[[v]][restrict]
  m <- mean(x, na.rm = TRUE); s <- sd(x, na.rm = TRUE)
  z <- rep(NA_real_, nrow(df))
  z[restrict] <- (df[[v]][restrict] - m) / s
  df[[paste0("z_", v)]] <- z
}

dfr <- df[restrict, ]

# Table 3
t3_1 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info, data = dfr, vcov = "hetero")
t3_2 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_goal_exp, data = dfr, vcov = "hetero")
t3_3 <- feols(avg_delta_ex1 ~ wave2 + wave3 + first_info + new_info + z_gap_actual_exp, data = dfr, vcov = "hetero")

# Table 4: reshape long over commit8, commit12, commit16
long <- dfr %>%
  dplyr::select(id, wave2, wave3, first_info, new_info, control_info,
                z_avg_delta_ex1, z_gap_goal_exp, z_gap_actual_exp,
                commit8, commit12, commit16) %>%
  tidyr::pivot_longer(cols = c(commit8, commit12, commit16),
                      names_to = "t", names_prefix = "commit",
                      values_to = "commit") %>%
  as.data.frame()
long$t <- factor(as.numeric(long$t))

t4_1 <- feols(commit ~ t + wave2 + wave3 + first_info + new_info, data = long, cluster = ~id)
t4_2 <- feols(commit ~ t + wave2 + wave3 + z_avg_delta_ex1 + first_info + new_info, data = long, cluster = ~id)
t4_3 <- feols(commit ~ t + wave2 + wave3 + z_gap_goal_exp + first_info + new_info, data = long, cluster = ~id)
t4_4 <- feols(commit ~ t + wave2 + wave3 + z_gap_actual_exp + first_info + new_info, data = long, cluster = ~id)

g <- function(m, v) unname(coef(m)[v])
s <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, val))

out("bcp_basic_info_treatment_col1", g(t3_1, "first_info"))
out("bcp_basic_info_treatment_col1_se", s(t3_1, "first_info"))
out("bcp_enhanced_info_treatment_col1", g(t3_1, "new_info"))
out("bcp_enhanced_info_treatment_col1_se", s(t3_1, "new_info"))
out("bcp_goal_minus_expected_attendance_col2", g(t3_2, "z_gap_goal_exp"))
out("bcp_goal_minus_expected_attendance_col2_se", s(t3_2, "z_gap_goal_exp"))
out("bcp_actual_minus_expected_attendance_col3", g(t3_3, "z_gap_actual_exp"))
out("bcp_actual_minus_expected_attendance_col3_se", s(t3_3, "z_gap_actual_exp"))
out("bcp_regression_observations", nobs(t3_1))

out("takeup_more_basic_info_treatment_col1", g(t4_1, "first_info"))
out("takeup_more_basic_info_treatment_col1_se", s(t4_1, "first_info"))
out("takeup_more_enhanced_info_treatment_col1", g(t4_1, "new_info"))
out("takeup_more_enhanced_info_treatment_col1_se", s(t4_1, "new_info"))
out("takeup_more_behavior_change_premium_col2", g(t4_2, "z_avg_delta_ex1"))
out("takeup_more_behavior_change_premium_col2_se", s(t4_2, "z_avg_delta_ex1"))
out("takeup_more_goal_minus_expected_attendance_col3", g(t4_3, "z_gap_goal_exp"))
out("takeup_more_goal_minus_expected_attendance_col3_se", s(t4_3, "z_gap_goal_exp"))
out("takeup_more_actual_minus_expected_attendance_col4", g(t4_4, "z_gap_actual_exp"))
out("takeup_more_actual_minus_expected_attendance_col4_se", s(t4_4, "z_gap_actual_exp"))
out("takeup_more_regression_observations", nobs(t4_1))