# Carrera et al. (2022) "Who Chooses Commitment?" -- Tables 3 and 4, independent blind reproduction
set.seed(42)
suppressMessages(library(haven)); suppressMessages(library(dplyr)); suppressMessages(library(fixest))
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/blind/2026-11-02-b/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$pid <- seq_len(nrow(d))

# Sample: exogenously assigned incentives (drop the 44 endogenous-assignment cases),
# excluding wave-3 participants assigned the $80-for-12-visits commitment contract.
s <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0, treatment != "threshold80_12")

# Conservative behavior change premium: mean over adjacent positive incentive pairs
# BCP(p,D) = [w(p+D) - w(p)]/D - [a(p) + a(p+D)]/2
pairs <- list(c(1,2), c(2,3), c(3,5), c(5,7), c(7,12))
bcp_mat <- sapply(pairs, function(pr) {
  p0 <- pr[1]; p1 <- pr[2]
  (s[[paste0("wtp", p1)]] - s[[paste0("wtp", p0)]]) / (p1 - p0) -
    (s[[paste0("days_", p0)]] + s[[paste0("days_", p1)]]) / 2
})
s$bcp <- rowMeans(bcp_mat)

s$basic_info    <- as.integer(s$type_of_info == "1-onlygraph")
s$enhanced_info <- as.integer(s$type_of_info == "2-graphplus")
s$goal_gap_raw  <- s$goal - s$days_0
exp_assigned    <- sapply(seq_len(nrow(s)), function(i) s[[paste0("days_", s$incentive[i])]][i])
s$act_gap_raw   <- s$visits - exp_assigned
z <- function(x) (x - mean(x)) / sd(x)
s$goal_gap_z <- z(s$goal_gap_raw)
s$act_gap_z  <- z(s$act_gap_raw)
s$bcp_z      <- z(s$bcp)

cat("N participants:", nrow(s), "\n")
cat(sprintf("goal-exp mean %.3f sd %.3f; actual-exp mean %.3f sd %.3f; bcp mean %.3f\n",
            mean(s$goal_gap_raw), sd(s$goal_gap_raw), mean(s$act_gap_raw), sd(s$act_gap_raw), mean(s$bcp)))

# Table 3: OLS, wave FE, heteroskedasticity-robust SEs
t3c1 <- feols(bcp ~ basic_info + enhanced_info | wavenum, data = s, vcov = "hetero")
t3c2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wavenum, data = s, vcov = "hetero")
t3c3 <- feols(bcp ~ basic_info + enhanced_info + act_gap_z | wavenum, data = s, vcov = "hetero")
etable(t3c1, t3c2, t3c3)

# Table 4: stack "more" contract choices (8/12/16 in waves 1-2; 12 only in wave 3)
long <- bind_rows(
  s %>% filter(wavenum %in% 1:2) %>% mutate(threshold = 8,  takeup = as.integer(q169 == 2)),
  s %>% mutate(threshold = 12, takeup = as.integer(chose_commit12 == 1)),
  s %>% filter(wavenum %in% 1:2) %>% mutate(threshold = 16, takeup = as.integer(q295 == 2))
)
cat("Stacked rows:", nrow(long), " NA takeup:", sum(is.na(long$takeup)), "\n")
long <- long %>% filter(!is.na(takeup))
t4c1 <- feols(takeup ~ basic_info + enhanced_info | wavenum + threshold, data = long, cluster = ~pid)
t4c2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wavenum + threshold, data = long, cluster = ~pid)
t4c3 <- feols(takeup ~ basic_info + enhanced_info + goal_gap_z | wavenum + threshold, data = long, cluster = ~pid)
t4c4 <- feols(takeup ~ basic_info + enhanced_info + act_gap_z | wavenum + threshold, data = long, cluster = ~pid)
etable(t4c1, t4c2, t4c3, t4c4)

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("bcp_basic_info_treatment_col1", coef(t3c1)[["basic_info"]])
r("bcp_enhanced_info_treatment_col1", coef(t3c1)[["enhanced_info"]])
r("bcp_goal_minus_expected_attendance_col2", coef(t3c2)[["goal_gap_z"]])
r("bcp_actual_minus_expected_attendance_col3", coef(t3c3)[["act_gap_z"]])
r("bcp_regression_observations", nobs(t3c1))
r("takeup_more_basic_info_treatment_col1", coef(t4c1)[["basic_info"]])
r("takeup_more_enhanced_info_treatment_col1", coef(t4c1)[["enhanced_info"]])
r("takeup_more_behavior_change_premium_col2", coef(t4c2)[["bcp_z"]])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4c3)[["goal_gap_z"]])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4c4)[["act_gap_z"]])
r("takeup_more_regression_observations", nobs(t4c1))
