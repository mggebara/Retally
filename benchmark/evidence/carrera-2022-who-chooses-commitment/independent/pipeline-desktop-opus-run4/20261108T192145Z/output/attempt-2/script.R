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
# keep value labels as text for string-like decoding where useful
df_lab <- as.data.frame(haven::as_factor(raw, levels = "labels"))
df <- as.data.frame(haven::zap_labels(raw))
nm <- names(df)
message("Columns: ", paste(nm, collapse = ", "))
message("N raw = ", nrow(df))

to_num <- function(x) suppressWarnings(as.numeric(as.character(x)))
first_num <- function(x) {
  xs <- as.character(x)
  suppressWarnings(as.numeric(sub("^\\D*(\\d+).*$", "\\1", ifelse(grepl("\\d", xs), xs, NA))))
}

# ---------------- identify subject id ----------------
id_cands <- nm[grepl("^(id|subject|subjectid|subject_id|participant|participant_id|pid|responseid|response_id|uid|user_id|memberid|member_id)$", nm, ignore.case = TRUE)]
if (length(id_cands) > 0) {
  df$sid <- as.character(df[[id_cands[1]]])
  if (any(duplicated(df$sid)) || any(is.na(df$sid))) df$sid <- as.character(seq_len(nrow(df)))
} else {
  df$sid <- as.character(seq_len(nrow(df)))
}

# ---------------- incentive levels / forecast columns ----------------
ps <- c(1, 2, 3, 5, 7, 12)
wtp_cols <- paste0("wtp", ps)
for (cc in wtp_cols) df[[cc]] <- to_num(df[[cc]])

excl_prefix <- "^(wtp|sliderintro_wtp|previsits|chose_commit|percent_meet_commit|chose_fewer|chose_less|commit|areyousure|prefer)"
prefixes <- unique(unlist(lapply(nm, function(v) {
  m <- regmatches(v, regexec("^(.*?)(12|1|2|3|5|7)$", v))[[1]]
  if (length(m) == 3) m[2] else character(0)
})))
full <- prefixes[sapply(prefixes, function(pr) all(paste0(pr, ps) %in% nm))]
full <- full[!grepl(excl_prefix, full, ignore.case = TRUE)]
full <- full[!grepl("wtp", full, ignore.case = TRUE)]
message("Candidate forecast prefixes: ", paste(full, collapse = ", "))
pref_order <- c("forecast", "expect", "exp", "pred", "guess", "visit", "att", "days")
fc_prefix <- NA
for (po in pref_order) {
  hit <- full[grepl(po, full, ignore.case = TRUE)]
  if (length(hit) > 0) { fc_prefix <- hit[1]; break }
}
if (is.na(fc_prefix) && length(full) > 0) fc_prefix <- full[1]
message("Using forecast prefix: ", fc_prefix)
fc_cols <- paste0(fc_prefix, ps)
for (cc in fc_cols) df[[cc]] <- to_num(df[[cc]])

# ---------------- behavior change premium ----------------
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bcp_mat <- sapply(pairs, function(pr) {
  lo <- pr[1]; hi <- pr[2]
  (df[[paste0("wtp", hi)]] - df[[paste0("wtp", lo)]]) / (hi - lo) -
    (df[[paste0(fc_prefix, hi)]] + df[[paste0(fc_prefix, lo)]]) / 2
})
df$bcp <- rowMeans(bcp_mat, na.rm = TRUE)
df$bcp[is.nan(df$bcp)] <- NA
message("Mean BCP (all) = ", mean(df$bcp, na.rm = TRUE))

# ---------------- wave (FIX: 'wave' is not numeric; use wavenum or parse digits) ----------------
message("Raw wave values:"); print(table(df_lab$wave, useNA = "ifany"))
if ("wavenum" %in% nm) { message("Raw wavenum values:"); print(table(df$wavenum, useNA = "ifany")) }
wv <- rep(NA_real_, nrow(df))
if ("wavenum" %in% nm) wv <- to_num(df$wavenum)
if (all(is.na(wv))) wv <- to_num(df$wave)
if (all(is.na(wv))) wv <- first_num(df$wave)
if (all(is.na(wv))) wv <- first_num(df_lab$wave)
if (all(is.na(wv))) wv <- as.numeric(factor(as.character(df$wave)))
df$wave_fe <- wv
message("Wave (numeric) table:"); print(table(df$wave_fe, useNA = "ifany"))

# ---------------- treatment indicators (FIX: robust decoding) ----------------
message("Raw treatment values:"); print(table(df_lab$treatment, useNA = "ifany"))
message("Raw type_of_info values:"); print(table(df_lab$type_of_info, useNA = "ifany"))
decode_treat <- function(tr_raw, tr_lab) {
  trn <- to_num(tr_raw)
  if (!all(is.na(trn))) {
    u <- sort(unique(na.omit(trn)))
    if (all(u %in% c(0, 1))) return(trn)
    if (all(u %in% c(1, 2))) return(as.numeric(trn == 2))
  }
  trs <- tolower(trimws(as.character(tr_lab)))
  out <- ifelse(is.na(trs) | trs == "", NA,
                as.numeric(!grepl("control|^no|none|no info|no_info", trs)))
  out
}
df$treat <- decode_treat(df$treatment, df_lab$treatment)
if (all(is.na(df$treat)) || length(unique(na.omit(df$treat))) < 2) {
  if ("type_of_info" %in% nm) df$treat <- decode_treat(df$type_of_info, df_lab$type_of_info)
}
message("Wave x treat table: "); print(table(df$wave_fe, df$treat, useNA = "ifany"))

# basic vs enhanced: use type_of_info labels if informative, else by wave
toi <- if ("type_of_info" %in% nm) tolower(as.character(df_lab$type_of_info)) else rep(NA_character_, nrow(df))
has_basic <- any(grepl("basic", toi), na.rm = TRUE)
has_enh <- any(grepl("enhanc", toi), na.rm = TRUE)
min_wave <- suppressWarnings(min(df$wave_fe, na.rm = TRUE))
if (has_basic && has_enh) {
  df$basic_info <- as.numeric(df$treat %in% 1 & grepl("basic", toi))
  df$enhanced_info <- as.numeric(df$treat %in% 1 & grepl("enhanc", toi))
} else {
  df$basic_info <- as.numeric(df$treat %in% 1 & df$wave_fe %in% min_wave)
  df$enhanced_info <- as.numeric(df$treat %in% 1 & !(df$wave_fe %in% min_wave) & !is.na(df$wave_fe))
}
message("basic_info sum = ", sum(df$basic_info), "; enhanced_info sum = ", sum(df$enhanced_info))

# ---------------- sample restriction ----------------
df$flag_exclude_exog <- to_num(df$flag_exclude_exog)
df$inc_num <- to_num(df$incentive)
inctext <- if ("incentivetext" %in% nm) tolower(as.character(df$incentivetext)) else rep("", nrow(df))
is_commit <- (!is.na(df$inc_num) & df$inc_num >= 80) |
  grepl("commit|12\\+|80|at least", inctext)
is_commit[is.na(is_commit)] <- FALSE
excl <- !is.na(df$flag_exclude_exog) & df$flag_exclude_exog == 1
s3 <- df[!excl & !is_commit, ]
message("Sample after restrictions: ", nrow(s3))

# ---------------- gaps ----------------
s3$goal <- to_num(s3$goal)
s3$visits <- to_num(s3$visits)
s3$exp0 <- to_num(s3$visits_next4weeks)
if (all(is.na(s3$exp0)) && "days_0" %in% names(s3)) s3$exp0 <- to_num(s3$days_0)
s3$goal_gap <- s3$goal - s3$exp0
exp_assigned <- rep(NA_real_, nrow(s3))
for (i in seq_len(nrow(s3))) {
  p <- s3$inc_num[i]
  if (is.na(p)) next
  if (p == 0) {
    exp_assigned[i] <- if ("days_0" %in% names(s3)) to_num(s3$days_0[i]) else s3$exp0[i]
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
thr <- c(8, 12, 16)
long_list <- list()
for (k in thr) {
  cn <- paste0("chose_commit", k)
  if (!cn %in% names(s3)) { message("Missing column ", cn); next }
  long_list[[length(long_list) + 1]] <- data.frame(
    sid = s3$sid, wave = s3$wave, basic_info = s3$basic_info,
    enhanced_info = s3$enhanced_info, bcp_z = s3$bcp_z, goal_z = s3$goal_z,
    act_z = s3$act_z, threshold = k, takeup = norm_choice(s3[[cn]]),
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