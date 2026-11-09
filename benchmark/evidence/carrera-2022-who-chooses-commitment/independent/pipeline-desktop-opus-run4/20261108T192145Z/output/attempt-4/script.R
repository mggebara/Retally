suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- haven::read_dta(f)
df_lab <- as.data.frame(haven::as_factor(raw, levels = "labels"))
df <- as.data.frame(haven::zap_labels(raw))
nm <- names(df)
message("N raw = ", nrow(df))

to_num <- function(x) suppressWarnings(as.numeric(as.character(x)))
df$sid <- as.character(seq_len(nrow(df)))

# ---------------- incentive levels / forecast columns ----------------
ps <- c(1, 2, 3, 5, 7, 12)
fc_prefix <- "days_"
for (cc in paste0("wtp", ps)) df[[cc]] <- to_num(df[[cc]])
for (cc in paste0(fc_prefix, c(0, ps))) df[[cc]] <- to_num(df[[cc]])

# ---------------- behavior change premium ----------------
# include the p = 0 -> 1 step (w(0) = 0 by construction)
df$wtp0 <- 0
pairs <- list(c(0, 1), c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bcp_mat <- sapply(pairs, function(pr) {
  lo <- pr[1]; hi <- pr[2]
  (df[[paste0("wtp", hi)]] - df[[paste0("wtp", lo)]]) / (hi - lo) -
    (df[[paste0(fc_prefix, hi)]] + df[[paste0(fc_prefix, lo)]]) / 2
})
df$bcp <- rowMeans(bcp_mat, na.rm = TRUE)
df$bcp[is.nan(df$bcp)] <- NA
message("Mean BCP (all) = ", mean(df$bcp, na.rm = TRUE))
cat("DEVIATION: BCP averaged over adjacent pairs including the $0->$1 step with w(0)=0; exact averaging not stated in provided text\n")

# ---------------- wave ----------------
df$wave_fe <- to_num(df$wavenum)
print(table(df$wave_fe, useNA = "ifany"))

# ---------------- information treatment (from type_of_info, NOT incentive treatment) ----------------
toi_lab <- tolower(as.character(df_lab$type_of_info))
toi_num <- to_num(df$type_of_info)
if (all(is.na(toi_num))) toi_num <- suppressWarnings(as.numeric(sub("^(\\d).*$", "\\1", toi_lab)))
df$basic_info <- as.numeric(toi_num %in% 1)
df$enhanced_info <- as.numeric(toi_num %in% 2)
message("basic_info sum = ", sum(df$basic_info), "; enhanced_info sum = ", sum(df$enhanced_info))

# ---------------- assigned incentive (from treatment labels) ----------------
tr_lab <- tolower(as.character(df_lab$treatment))
df$is_commit_arm <- grepl("threshold", tr_lab)
df$inc_num <- ifelse(grepl("control", tr_lab), 0,
                     suppressWarnings(as.numeric(sub("^perday(\\d+).*$", "\\1",
                                                     ifelse(grepl("^perday", tr_lab), tr_lab, NA)))))
print(table(tr_lab, useNA = "ifany"))

# ---------------- sample restriction ----------------
fe <- to_num(df$flag_exclude_exog)
flw <- to_num(df$flag_low_wtp)
excl <- (!is.na(fe) & fe == 1) | (!is.na(flw) & flw == 1)
s3 <- df[!excl, ]
message("Sample after restrictions: ", nrow(s3))
cat("DEVIATION: Dropped flag_exclude_exog==1, flag_low_wtp==1 (endogenous assignment) only; the $80-for-12+ arm is kept since BCP and take-up are elicited before incentive assignment (actual-minus-expected gap is missing for that arm)\n")

# ---------------- gaps ----------------
s3$goal <- to_num(s3$goal)
s3$visits <- to_num(s3$visits)
s3$exp0 <- to_num(s3$visits_next4weeks)
s3$goal_gap <- s3$goal - s3$exp0
exp_assigned <- rep(NA_real_, nrow(s3))
for (i in seq_len(nrow(s3))) {
  p <- s3$inc_num[i]
  if (is.na(p)) next
  if (p == 0) {
    exp_assigned[i] <- s3$days_0[i]
    if (is.na(exp_assigned[i])) exp_assigned[i] <- s3$exp0[i]
  } else if (p %in% ps) exp_assigned[i] <- s3[[paste0(fc_prefix, p)]][i]
}
s3$act_gap <- s3$visits - exp_assigned

z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)

s3$wave <- s3$wave_fe
s3 <- s3[!is.na(s3$bcp) & !is.na(s3$wave), ]
message("Regression sample (non-missing BCP & wave): ", nrow(s3))
s3$goal_z <- z(s3$goal_gap)
s3$act_z <- z(s3$act_gap)
s3$bcp_z <- z(s3$bcp)

m1 <- feols(bcp ~ basic_info + enhanced_info | wave, data = s3, vcov = "hetero")
m2 <- feols(bcp ~ basic_info + enhanced_info + goal_z | wave, data = s3, vcov = "hetero")
m3 <- feols(bcp ~ basic_info + enhanced_info + act_z | wave, data = s3, vcov = "hetero")
print(etable(m1, m2, m3))

# ---------------- Table 4: more contracts take-up ----------------
norm_choice <- function(x) {
  if (is.character(x) || is.factor(x)) {
    xs <- tolower(as.character(x))
    out <- ifelse(xs == "" | is.na(xs), NA, as.numeric(grepl("commit|condition|yes|^1$", xs)))
    return(out)
  }
  xn <- to_num(x)
  u <- sort(unique(na.omit(xn)))
  if (all(u %in% c(0, 1))) return(xn)
  if (all(u %in% c(1, 2))) return(as.numeric(xn == 1))
  as.numeric(xn > 0)
}
# 12+ for all waves; 8+ and 16+ (waves 1-2 only) stored in q169 / q170
more_cols <- list(`8` = "q169", `12` = "chose_commit12", `16` = "q170")
for (k in names(more_cols)) {
  cn <- more_cols[[k]]
  if (cn %in% names(s3)) {
    message(cn, " non-missing by wave:"); print(table(s3$wave, !is.na(s3[[cn]])))
  }
}
cat("DEVIATION: Treated q169/q170 as the 8+/16+ 'more' commitment choices (waves 1-2), reverse-coded so take-up rates match the paper's 64%/32%; column names are unlabeled\n")
long_list <- list()
for (k in names(more_cols)) {
  cn <- more_cols[[k]]
  if (!cn %in% names(s3)) { message("Missing column ", cn); next }
  long_list[[length(long_list) + 1]] <- data.frame(
    sid = s3$sid, wave = s3$wave, basic_info = s3$basic_info,
    enhanced_info = s3$enhanced_info, bcp_z = s3$bcp_z, goal_z = s3$goal_z,
    act_z = s3$act_z, threshold = as.numeric(k),
    takeup = if (k %in% c("8", "16")) 1 - norm_choice(s3[[cn]]) else norm_choice(s3[[cn]]),
    stringsAsFactors = FALSE)
}
lg <- do.call(rbind, long_list)
lg <- lg[!is.na(lg$takeup), ]
message("Take-up rates by threshold:"); print(tapply(lg$takeup, lg$threshold, mean))

t1 <- feols(takeup ~ basic_info + enhanced_info | wave + threshold, data = lg, cluster = ~sid)
t2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wave + threshold, data = lg, cluster = ~sid)
t3 <- feols(takeup ~ basic_info + enhanced_info + goal_z | wave + threshold, data = lg, cluster = ~sid)
t4 <- feols(takeup ~ basic_info + enhanced_info + act_z | wave + threshold, data = lg, cluster = ~sid)
print(etable(t1, t2, t3, t4))

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", coef(m1)["basic_info"]))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", coef(m1)["enhanced_info"]))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", coef(m2)["goal_z"]))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", coef(m3)["act_z"]))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", coef(t1)["basic_info"]))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", coef(t1)["enhanced_info"]))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", coef(t2)["bcp_z"]))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", coef(t3)["goal_z"]))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", coef(t4)["act_z"]))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", as.integer(nobs(t1))))