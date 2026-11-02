## Independent reproduction: Carrera et al. (2022) "Who Chooses Commitment?" Tables 3 and 4
suppressPackageStartupMessages({ library(haven); library(dplyr); library(tidyr); library(fixest) })
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/carrera-2022-who-chooses-commitment/independent/2026-11-02-a/mount/carrera_2022_who_chooses_commitment/Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
d <- zap_labels(d)
d$pid <- seq_len(nrow(d))
cat("All participants:", nrow(d), "\n")

## Sample: drop 44 endogenous incentive assignments (two flags), and wave 3 commitment-contract assignees
d <- d %>% filter(flag_exclude_exog == 0, flag_low_wtp == 0)
cat("After excluding endogenous assignment flags:", nrow(d), "\n")
d <- d %>% filter(treatment != "threshold80_12")
cat("After excluding threshold80_12 assignees:", nrow(d), "\n")

## Info treatment dummies
d <- d %>% mutate(info_basic = as.numeric(substr(type_of_info, 1, 1) == "1"),
                  info_enh   = as.numeric(substr(type_of_info, 1, 1) == "2"),
                  wavef = factor(wavenum))

## Conservative behavior change premium: pairs of adjacent positive piece rates
pr <- c(1, 2, 3, 5, 7, 12)
bcp_mat <- sapply(1:5, function(k) {
  p0 <- pr[k]; p1 <- pr[k + 1]; D <- p1 - p0
  (d[[paste0("wtp", p1)]] - d[[paste0("wtp", p0)]]) / D -
    (d[[paste0("days_", p1)]] + d[[paste0("days_", p0)]]) / 2
})
d$bcp <- rowMeans(bcp_mat)

## Proxies
d$goal_exp <- d$goal - d$days_0
exp_assigned <- sapply(seq_len(nrow(d)), function(i) d[[paste0("days_", d$incentive[i])]][i])
d$act_exp <- d$visits - exp_assigned
cat("goal-exp mean/sd:", mean(d$goal_exp), sd(d$goal_exp), "\n")
cat("act-exp mean/sd:", mean(d$act_exp), sd(d$act_exp), "\n")
cat("BCP mean:", mean(d$bcp), " control-group mean:", mean(d$bcp[d$info_basic == 0 & d$info_enh == 0]), "\n")
z <- function(x) (x - mean(x)) / sd(x)
d <- d %>% mutate(z_goal = z(goal_exp), z_act = z(act_exp), z_bcp = z(bcp))

## Table 3: OLS, wave FE, HC1 robust SEs
t3a <- feols(bcp ~ info_basic + info_enh | wavef, data = d, vcov = "hetero")
t3b <- feols(bcp ~ info_basic + info_enh + z_goal | wavef, data = d, vcov = "hetero")
t3c <- feols(bcp ~ info_basic + info_enh + z_act | wavef, data = d, vcov = "hetero")
etable(t3a, t3b, t3c)

## Table 4: long data of "more" contract choices
long <- bind_rows(
  d %>% filter(wavenum %in% c(1, 2)) %>% transmute(pid, wavef, info_basic, info_enh, z_bcp, z_goal, z_act,
                                                   thr = 8, more = as.numeric(q169 == 2)),
  d %>% transmute(pid, wavef, info_basic, info_enh, z_bcp, z_goal, z_act,
                  thr = 12, more = chose_commit12),
  d %>% filter(wavenum %in% c(1, 2)) %>% transmute(pid, wavef, info_basic, info_enh, z_bcp, z_goal, z_act,
                                                   thr = 16, more = as.numeric(q295 == 2))
) %>% filter(!is.na(more))
cat("Take-up by threshold:\n"); print(tapply(long$more, long$thr, mean))
t4a <- feols(more ~ info_basic + info_enh | wavef + thr, data = long, cluster = ~pid)
t4b <- feols(more ~ info_basic + info_enh + z_bcp | wavef + thr, data = long, cluster = ~pid)
t4c <- feols(more ~ info_basic + info_enh + z_goal | wavef + thr, data = long, cluster = ~pid)
t4d <- feols(more ~ info_basic + info_enh + z_act | wavef + thr, data = long, cluster = ~pid)
etable(t4a, t4b, t4c, t4d)

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("bcp_basic_info_treatment_col1", coef(t3a)["info_basic"])
r("bcp_enhanced_info_treatment_col1", coef(t3a)["info_enh"])
r("bcp_goal_minus_expected_attendance_col2", coef(t3b)["z_goal"])
r("bcp_actual_minus_expected_attendance_col3", coef(t3c)["z_act"])
r("bcp_regression_observations", nobs(t3a))
r("takeup_more_basic_info_treatment_col1", coef(t4a)["info_basic"])
r("takeup_more_enhanced_info_treatment_col1", coef(t4a)["info_enh"])
r("takeup_more_behavior_change_premium_col2", coef(t4b)["z_bcp"])
r("takeup_more_goal_minus_expected_attendance_col3", coef(t4c)["z_goal"])
r("takeup_more_actual_minus_expected_attendance_col4", coef(t4d)["z_act"])
r("takeup_more_regression_observations", nobs(t4a))
