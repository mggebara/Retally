suppressMessages({library(haven); library(dplyr); library(tidyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-c/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$pid <- seq_len(nrow(d))

# Sample: drop endogenous incentive assignment (n=12 + n=32), and wave-3 commitment-contract group
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0) %>%
  filter(treatment != "threshold80_12")
cat("N after exclusions:", nrow(s), "\n")
print(table(s$wave))

# Behavior change premium, conservative (pairs of positive piece rates, excluding $0->$1)
inc <- c(1, 2, 3, 5, 7, 12)
bcp_mat <- sapply(1:(length(inc) - 1), function(k) {
  p0 <- inc[k]; p1 <- inc[k + 1]
  (s[[paste0("wtp", p1)]] - s[[paste0("wtp", p0)]]) / (p1 - p0) -
    (s[[paste0("days_", p0)]] + s[[paste0("days_", p1)]]) / 2
})
s$bcp <- rowMeans(bcp_mat)

s$basic <- as.numeric(s$type_of_info == "1-onlygraph")
s$enh <- as.numeric(s$type_of_info == "2-graphplus")
s$gap_goal <- s$goal - s$days_0
exp_assigned <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
s$gap_actual <- s$visits - exp_assigned
z <- function(x) (x - mean(x)) / sd(x)
s$z_goal <- z(s$gap_goal); s$z_actual <- z(s$gap_actual); s$z_bcp <- z(s$bcp)
cat(sprintf("BCP mean %.3f; info-control mean %.3f\n", mean(s$bcp), mean(s$bcp[s$type_of_info == "0-none"])))
cat(sprintf("goal gap mean %.2f sd %.2f; actual gap mean %.2f sd %.2f\n",
            mean(s$gap_goal), sd(s$gap_goal), mean(s$gap_actual), sd(s$gap_actual)))

t3_1 <- feols(bcp ~ basic + enh | wave, data = s, vcov = "hetero")
t3_2 <- feols(bcp ~ basic + enh + z_goal | wave, data = s, vcov = "hetero")
t3_3 <- feols(bcp ~ basic + enh + z_actual | wave, data = s, vcov = "hetero")
etable(t3_1, t3_2, t3_3)

# Table 4: stack "more" contract choices (value 2 = chose the contract in q169/q295)
long <- bind_rows(
  s %>% filter(wavenum != 3 | is.na(q169) == FALSE) %>% filter(!is.na(q169)) %>% mutate(threshold = 8, more = as.numeric(q169 == 2)),
  s %>% mutate(threshold = 12, more = chose_commit12),
  s %>% filter(!is.na(q295)) %>% mutate(threshold = 16, more = as.numeric(q295 == 2))
)
cat("Long N:", nrow(long), "; take-up by threshold:\n"); print(tapply(long$more, long$threshold, mean))
cat("Take-up mean", mean(long$more), "control", mean(long$more[long$type_of_info == "0-none"]), "\n")
t4_1 <- feols(more ~ basic + enh | wave + threshold, data = long, cluster = ~pid)
t4_2 <- feols(more ~ basic + enh + z_bcp | wave + threshold, data = long, cluster = ~pid)
t4_3 <- feols(more ~ basic + enh + z_goal | wave + threshold, data = long, cluster = ~pid)
t4_4 <- feols(more ~ basic + enh + z_actual | wave + threshold, data = long, cluster = ~pid)
etable(t4_1, t4_2, t4_3, t4_4)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("bcp_basic_info_treatment_col1", coef(t3_1)["basic"])
r("bcp_enhanced_info_treatment_col1", coef(t3_1)["enh"])
r("bcp_goal_minus_expected_attendance_col2", coef(t3_2)["z_goal"])
r("bcp_actual_minus_expected_attendance_col3", coef(t3_3)["z_actual"])
r("bcp_regression_observations", nobs(t3_1))
r("takeup_more_basic_info_treatment_col1", coef(t4_1)["basic"])
r("takeup_more_enhanced_info_treatment_col1", coef(t4_1)["enh"])
r("takeup_more_behavior_change_premium_col2", coef(t4_2)["z_bcp"])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4_3)["z_goal"])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4_4)["z_actual"])
r("takeup_more_regression_observations", nobs(t4_1))
