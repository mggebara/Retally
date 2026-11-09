# Independent reproduction: Carrera et al. (2022) "Who Chooses Commitment?" Tables 3 and 4
suppressPackageStartupMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)

d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-07-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$id <- seq_len(nrow(d))

# Sample: drop the 44 endogenously assigned incentives (two flags) and the
# wave-3 participants assigned the $80-for-12-visits commitment contract.
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0, treatment != "threshold80_12")

# Information treatment dummies: basic (wave 1 graph), enhanced (waves 2-3)
s <- s %>% mutate(basic = as.numeric(type_of_info == "1-onlygraph"),
                  enhanced = as.numeric(type_of_info == "2-graphplus"),
                  wave = factor(wavenum))

# Conservative behavior change premium: adjacent positive piece-rate pairs
levs <- c(1, 2, 3, 5, 7, 12)
bcp_mat <- sapply(1:5, function(k) {
  p0 <- levs[k]; p1 <- levs[k + 1]
  (s[[paste0("wtp", p1)]] - s[[paste0("wtp", p0)]]) / (p1 - p0) -
    (s[[paste0("days_", p0)]] + s[[paste0("days_", p1)]]) / 2
})
s$bcp <- rowMeans(bcp_mat)

# Proxies
s$goal_gap <- s$goal - s$days_0
s$exp_assigned <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
s$act_gap <- s$visits - s$exp_assigned
z <- function(x) (x - mean(x)) / sd(x)
s$goal_z <- z(s$goal_gap); s$act_z <- z(s$act_gap); s$bcp_z <- z(s$bcp)

cat("BCP mean:", mean(s$bcp), " control mean:", mean(s$bcp[s$basic == 0 & s$enhanced == 0]), "\n")

# Table 3: OLS, robust SEs, wave FE
t3 <- list(
  feols(bcp ~ basic + enhanced | wave, s, vcov = "hetero"),
  feols(bcp ~ basic + enhanced + goal_z | wave, s, vcov = "hetero"),
  feols(bcp ~ basic + enhanced + act_z | wave, s, vcov = "hetero"))
print(etable(t3))

# Table 4: pooled participant x threshold "more" contract choices (2 = chose)
long <- s %>% transmute(id, wave, basic, enhanced, goal_z, act_z, bcp_z,
                        c8 = ifelse(is.na(q169), NA, as.numeric(q169 == 2)),
                        c12 = chose_commit12,
                        c16 = ifelse(is.na(q295), NA, as.numeric(q295 == 2))) %>%
  pivot_longer(c(c8, c12, c16), names_to = "threshold", values_to = "takeup") %>%
  filter(!is.na(takeup))
cat("Take-up by threshold:\n"); print(tapply(long$takeup, long$threshold, mean))
t4 <- list(
  feols(takeup ~ basic + enhanced | wave + threshold, long, cluster = ~id),
  feols(takeup ~ basic + enhanced + bcp_z | wave + threshold, long, cluster = ~id),
  feols(takeup ~ basic + enhanced + goal_z | wave + threshold, long, cluster = ~id),
  feols(takeup ~ basic + enhanced + act_z | wave + threshold, long, cluster = ~id))
print(etable(t4))

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("bcp_basic_info_treatment_col1", coef(t3[[1]])["basic"])
r("bcp_enhanced_info_treatment_col1", coef(t3[[1]])["enhanced"])
r("bcp_goal_minus_expected_attendance_col2", coef(t3[[2]])["goal_z"])
r("bcp_actual_minus_expected_attendance_col3", coef(t3[[3]])["act_z"])
r("bcp_regression_observations", nobs(t3[[1]]))
r("takeup_more_basic_info_treatment_col1", coef(t4[[1]])["basic"])
r("takeup_more_enhanced_info_treatment_col1", coef(t4[[1]])["enhanced"])
r("takeup_more_behavior_change_premium_col2", coef(t4[[2]])["bcp_z"])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4[[3]])["goal_z"])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4[[4]])["act_z"])
r("takeup_more_regression_observations", nobs(t4[[1]]))
