suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
d0 <- haven::read_dta(file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta"))
inc_lab <- NULL
if (!is.null(attr(d0$incentive, "labels"))) inc_lab <- attr(d0$incentive, "labels")
d <- as.data.frame(haven::zap_labels(d0))
nm <- names(d)
cat("Columns:\n"); print(nm)

num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- Identify forecast-at-piece-rate variables ----------------
rates <- c(1, 2, 3, 5, 7, 12)
cand_prefix <- unique(sub("(1|2|3|5|7|12)$", "", nm[grepl("(1|2|3|5|7|12)$", nm)]))
cand_prefix <- setdiff(cand_prefix, c("wtp", "previsits", "sliderintro_wtp", "days_", "chose_commit",
                                      "percent_meet_commit", "days"))
fc_prefix <- NULL
for (p in cand_prefix) {
  if (all(paste0(p, rates) %in% nm)) {
    vals <- unlist(d[, paste0(p, rates)])
    vals <- num(vals)
    if (all(is.na(vals))) next
    if (max(vals, na.rm = TRUE) <= 28.5 && min(vals, na.rm = TRUE) >= 0) {
      fc_prefix <- c(fc_prefix, p)
    }
  }
}
cat("Forecast prefix candidates:", paste(fc_prefix, collapse = ", "), "\n")
pref_order <- fc_prefix[order(-grepl("exp|fore|pred|guess|visit|est", fc_prefix, ignore.case = TRUE))]
fcp <- if (length(pref_order)) pref_order[1] else NA
cat("Using forecast prefix:", fcp, "\n")

W <- sapply(rates, function(r) num(d[[paste0("wtp", r)]]))
F <- sapply(rates, function(r) num(d[[paste0(fcp, r)]]))
colnames(W) <- colnames(F) <- rates

pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bcp_mat <- sapply(pairs, function(pr) {
  i <- which(rates == pr[1]); j <- which(rates == pr[2])
  (W[, j] - W[, i]) / (pr[2] - pr[1]) - (F[, j] + F[, i]) / 2
})
d$bcp <- rowMeans(bcp_mat, na.rm = FALSE)

# ---------------- Baseline expected attendance (no incentive) ----------------
exp0_var <- if ("visits_next4weeks" %in% nm) "visits_next4weeks" else {
  c(nm[grepl("exp|forecast|predict", nm, ignore.case = TRUE)])[1]
}
cat("Baseline expected attendance var:", exp0_var, "\n")
d$exp0 <- num(d[[exp0_var]])
d$goal_n <- num(d$goal)
d$visits_n <- num(d$visits)

# ---------------- Assigned incentive ----------------
d$wave_n <- num(d$wave)
inc_raw <- d$incentive
inc_txt <- if ("incentivetext" %in% nm) as.character(d$incentivetext) else rep(NA_character_, nrow(d))
cat("Incentive table:\n"); print(table(inc_raw, useNA = "ifany"))
cat("Incentive text table:\n"); print(table(inc_txt, useNA = "ifany"))
if (!is.null(inc_lab)) print(inc_lab)

is_commit <- rep(FALSE, nrow(d))
if (!all(is.na(inc_txt))) is_commit <- is_commit | grepl("commit|80|at least|>=", inc_txt, ignore.case = TRUE)
inc_num <- num(inc_raw)
if (!is.null(inc_lab)) {
  commit_codes <- inc_lab[grepl("commit|80", names(inc_lab), ignore.case = TRUE)]
  if (length(commit_codes)) is_commit <- is_commit | inc_num %in% commit_codes
}
if (all(!is.na(inc_num))) is_commit <- is_commit | inc_num %in% c(80)
# Piece rate assigned
pr_assigned <- inc_num
if (!is.null(inc_lab) && !all(names(inc_lab) == as.character(inc_lab))) {
  labtxt <- names(inc_lab)[match(inc_num, inc_lab)]
  prx <- num(gsub("[^0-9.]", "", labtxt))
  pr_assigned <- ifelse(!is.na(prx), prx, pr_assigned)
}
if (all(is.na(pr_assigned)) && !all(is.na(inc_txt))) {
  pr_assigned <- num(gsub("[^0-9.]", "", inc_txt))
  pr_assigned[grepl("no |none|\\$0|^0", inc_txt, ignore.case = TRUE) & is.na(pr_assigned)] <- 0
}
pr_assigned[is_commit] <- NA
d$is_commit <- is_commit
d$pr_assigned <- pr_assigned

exp_under <- rep(NA_real_, nrow(d))
for (k in seq_len(nrow(d))) {
  p <- pr_assigned[k]
  if (is.na(p)) next
  if (p == 0) exp_under[k] <- d$exp0[k]
  else if (p %in% rates) exp_under[k] <- F[k, which(rates == p)]
}
d$exp_under <- exp_under

# ---------------- Info treatment indicators ----------------
tr <- d$treatment
if (is.character(tr)) {
  trn <- as.numeric(grepl("treat|info", tr, ignore.case = TRUE) & !grepl("control|no", tr, ignore.case = TRUE))
} else trn <- as.numeric(num(tr) > 0)
d$basic_info <- as.numeric(trn == 1 & d$wave_n == 1)
d$enh_info <- as.numeric(trn == 1 & d$wave_n %in% c(2, 3))

# ---------------- Sample ----------------
excl <- if ("flag_exclude_exog" %in% nm) num(d$flag_exclude_exog) else rep(0, nrow(d))
excl[is.na(excl)] <- 0
id_var <- intersect(c("id", "subject", "subject_id", "participant_id", "responseid", "ResponseId", "pid", "ID"), nm)
d$sid <- if (length(id_var)) as.character(d[[id_var[1]]]) else as.character(seq_len(nrow(d)))

s <- d %>% filter(excl == 0, !(wave_n == 3 & is_commit))
cat("Sample after exclusions:", nrow(s), "\n")
s <- s %>% filter(!is.na(bcp))
cat("Sample with non-missing BCP:", nrow(s), "\n")

z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s$goal_gap_z <- z(s$goal_n - s$exp0)
s$act_gap_z <- z(s$visits_n - s$exp_under)
s$bcp_z <- z(s$bcp)
s$wave_f <- factor(s$wave_n)

m1 <- feols(bcp ~ basic_info + enh_info | wave_f, data = s, vcov = "hetero")
m2 <- feols(bcp ~ basic_info + enh_info + goal_gap_z | wave_f, data = s, vcov = "hetero")
m3 <- feols(bcp ~ basic_info + enh_info + act_gap_z | wave_f, data = s, vcov = "hetero")
print(summary(m1)); print(summary(m2)); print(summary(m3))

# ---------------- "More" contract take-up ----------------
more_vars <- nm[grepl("^chose_commit(8|12|16)$", nm)]
if (length(more_vars) == 0) more_vars <- nm[grepl("^chose.*(8|12|16)$", nm) & !grepl("less|fewer|_l", nm)]
cat("More-contract vars:", paste(more_vars, collapse = ", "), "\n")
long <- s %>%
  dplyr::select(sid, wave_f, basic_info, enh_info, bcp_z, goal_gap_z, act_gap_z, all_of(more_vars)) %>%
  pivot_longer(all_of(more_vars), names_to = "threshold", values_to = "takeup") %>%
  mutate(takeup = num(takeup), threshold = factor(gsub("[^0-9]", "", threshold))) %>%
  filter(!is.na(takeup))
cat("Long obs:", nrow(long), "\n")

t1 <- feols(takeup ~ basic_info + enh_info | wave_f + threshold, data = long, cluster = ~sid)
t2 <- feols(takeup ~ basic_info + enh_info + bcp_z | wave_f + threshold, data = long, cluster = ~sid)
t3 <- feols(takeup ~ basic_info + enh_info + goal_gap_z | wave_f + threshold, data = long, cluster = ~sid)
t4 <- feols(takeup ~ basic_info + enh_info + act_gap_z | wave_f + threshold, data = long, cluster = ~sid)
print(summary(t1)); print(summary(t2)); print(summary(t3)); print(summary(t4))

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, as.numeric(v)))
out("bcp_basic_info_treatment_col1", coef(m1)["basic_info"])
out("bcp_enhanced_info_treatment_col1", coef(m1)["enh_info"])
out("bcp_goal_minus_expected_attendance_col2", coef(m2)["goal_gap_z"])
out("bcp_actual_minus_expected_attendance_col3", coef(m3)["act_gap_z"])
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m1)))
out("takeup_more_basic_info_treatment_col1", coef(t1)["basic_info"])
out("takeup_more_enhanced_info_treatment_col1", coef(t1)["enh_info"])
out("takeup_more_behavior_change_premium_col2", coef(t2)["bcp_z"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(t3)["goal_gap_z"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(t4)["act_gap_z"])
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t1)))
