suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- haven::read_dta(f)
d <- as.data.frame(raw)
nm <- names(d)
cat("Rows:", nrow(d), " Cols:", ncol(d), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
lab_text <- function(x) {
  if (inherits(x, "haven_labelled")) as.character(haven::as_factor(x, levels = "labels")) else as.character(x)
}

results <- list(
  bcp_basic_info_treatment_col1 = NA, bcp_enhanced_info_treatment_col1 = NA,
  bcp_goal_minus_expected_attendance_col2 = NA, bcp_actual_minus_expected_attendance_col3 = NA,
  bcp_regression_observations = NA,
  takeup_more_basic_info_treatment_col1 = NA, takeup_more_enhanced_info_treatment_col1 = NA,
  takeup_more_behavior_change_premium_col2 = NA, takeup_more_goal_minus_expected_attendance_col3 = NA,
  takeup_more_actual_minus_expected_attendance_col4 = NA, takeup_more_regression_observations = NA
)

d$id_row <- seq_len(nrow(d))

# ---------- wave (FIX: 'wave' may be a string; prefer numeric 'wavenum', else parse digits) ----------
parse_wave <- function(x) {
  v <- num(x)
  if (all(is.na(v))) {
    txt <- lab_text(x)
    v <- suppressWarnings(as.numeric(sub("^[^0-9]*([0-9]+).*$", "\\1", txt)))
    v[!grepl("[0-9]", txt)] <- NA
  }
  v
}
wave_n <- if ("wavenum" %in% nm) parse_wave(d$wavenum) else rep(NA_real_, nrow(d))
if (all(is.na(wave_n))) wave_n <- parse_wave(d$wave)
if (all(is.na(wave_n))) {
  wt <- lab_text(d$wave)
  wave_n <- as.numeric(factor(wt))
}
d$wave_n <- wave_n
cat("Wave table:\n"); print(table(lab_text(d$wave), d$wave_n, useNA = "ifany"))

# ---------- exclusion of endogenous assignment ----------
if ("flag_exclude_exog" %in% nm) {
  fx <- num(d$flag_exclude_exog)
  cat("flag_exclude_exog table:\n"); print(table(fx, useNA = "ifany"))
  d <- d[is.na(fx) | fx == 0, ]
}
cat("After exog exclusion:", nrow(d), "\n")

# ---------- information treatment (FIX: use type_of_info; 'treatment' is the incentive arm) ----------
basic_info <- rep(0, nrow(d)); enh_info <- rep(0, nrow(d))
if ("type_of_info" %in% names(d)) {
  ti_num <- num(d$type_of_info)
  ti_txt <- tolower(lab_text(d$type_of_info))
  cat("type_of_info values:\n"); print(table(ti_txt, ti_num, useNA = "ifany"))
  print(table(ti_txt, d$wave_n, useNA = "ifany"))
  is_basic <- grepl("basic|simple|standard", ti_txt)
  is_enh <- grepl("enhanc|detail|extend|additional|rich", ti_txt)
  if (any(is_basic) || any(is_enh)) {
    basic_info <- as.numeric(is_basic & !is_enh)
    enh_info <- as.numeric(is_enh)
  } else {
    is_ctrl <- is.na(ti_txt) | ti_txt == "" | ti_txt == "na" |
      grepl("^\\s*no\\b|none|control|^\\s*0\\s*$|no info|no_info", ti_txt)
    if (!all(is.na(ti_num)) && all(is.na(ti_txt) | ti_txt == as.character(ti_num))) {
      is_ctrl <- is.na(ti_num) | ti_num == 0
    }
    info <- as.numeric(!is_ctrl)
    basic_info <- as.numeric(info == 1 & d$wave_n == min(d$wave_n, na.rm = TRUE))
    enh_info <- as.numeric(info == 1 & d$wave_n > min(d$wave_n, na.rm = TRUE))
  }
}
basic_info[is.na(basic_info)] <- 0; enh_info[is.na(enh_info)] <- 0
d$basic_info <- basic_info
d$enh_info <- enh_info
cat("Info x wave:\n"); print(table(basic = d$basic_info, enh = d$enh_info, wave = d$wave_n, useNA = "ifany"))

# ---------- forecast columns ----------
rates <- c(1, 2, 3, 5, 7, 12)
stems <- unique(unlist(lapply(nm, function(n) {
  m <- regmatches(n, regexec("^(.*?)(1|2|3|5|7|12)$", n))[[1]]
  if (length(m) == 3) m[2] else character(0)
})))
stems <- stems[sapply(stems, function(s) all(paste0(s, rates) %in% nm))]
stems <- setdiff(stems, c("wtp", ""))
stems <- stems[!grepl("wtp|slider", stems)]
cat("Candidate forecast stems:", paste(stems, collapse = ", "), "\n")
pref <- stems[grepl("exp|forecast|predict|guess|visit|att|days", stems, ignore.case = TRUE)]
fstem <- if (length(pref) > 0) pref[1] else if (length(stems) > 0) stems[1] else NA
cat("Using forecast stem:", fstem, "\n")

W <- sapply(rates, function(r) num(d[[paste0("wtp", r)]]))
Fm <- if (!is.na(fstem)) sapply(rates, function(r) num(d[[paste0(fstem, r)]])) else matrix(NA, nrow(d), 6)

# ---------- behavior change premium ----------
bcp_pairs <- sapply(1:5, function(k) {
  dp <- rates[k + 1] - rates[k]
  (W[, k + 1] - W[, k]) / dp - (Fm[, k + 1] + Fm[, k]) / 2
})
d$bcp <- rowMeans(bcp_pairs)
cat("BCP summary:\n"); print(summary(d$bcp))

# ---------- assigned incentive ----------
inc_num <- num(d$incentive)
inc_txt <- tolower(paste(lab_text(d$incentive),
                         if ("incentivetext" %in% nm) lab_text(d$incentivetext) else ""))
tr_txt <- tolower(lab_text(d$treatment))
cat("Incentive values:\n"); print(table(inc_txt, useNA = "ifany"))
is_commit <- grepl("80|commit|contingent|conditional|threshold", inc_txt) |
  grepl("threshold|commit|contingent", tr_txt) |
  (!is.na(inc_num) & !(inc_num %in% c(0, rates)))
# assigned rate from treatment arm label first (perdayX / control), then incentive
tr_rate <- suppressWarnings(as.numeric(sub("^perday([0-9]+).*$", "\\1", tr_txt)))
tr_rate[!grepl("^perday[0-9]+", tr_txt)] <- NA
tr_rate[grepl("^control", tr_txt)] <- 0
assigned_rate <- ifelse(!is.na(tr_rate) & tr_rate %in% c(0, rates), tr_rate,
                        ifelse(!is.na(inc_num) & inc_num %in% c(0, rates), inc_num, NA))
miss <- is.na(assigned_rate) & !is_commit
if (any(miss)) {
  parsed <- suppressWarnings(as.numeric(sub(".*?\\$?([0-9]+).*", "\\1", inc_txt[miss])))
  parsed[grepl("^\\s*(no|none|zero)", inc_txt[miss])] <- 0
  assigned_rate[miss] <- ifelse(parsed %in% c(0, rates), parsed, NA)
}
assigned_rate[is_commit] <- NA
d$is_commit <- is_commit
d$assigned_rate <- assigned_rate
cat("Assigned rate table:\n"); print(table(d$assigned_rate, d$is_commit, useNA = "ifany"))

exp_noinc <- num(d$visits_next4weeks)
exp_assigned <- rep(NA_real_, nrow(d))
for (k in seq_along(rates)) {
  sel <- which(d$assigned_rate == rates[k])
  exp_assigned[sel] <- Fm[sel, k]
}
sel0 <- which(d$assigned_rate == 0)
exp_assigned[sel0] <- if ("days_0" %in% names(d)) {
  e0 <- num(d$days_0)[sel0]; ifelse(is.na(e0), exp_noinc[sel0], e0)
} else exp_noinc[sel0]

d$goal_gap <- num(d$goal) - exp_noinc
d$act_gap <- num(d$visits) - exp_assigned
cat("NA counts: bcp", sum(is.na(d$bcp)), " goal_gap", sum(is.na(d$goal_gap)),
    " act_gap", sum(is.na(d$act_gap)), " wave_n", sum(is.na(d$wave_n)), "\n")

# ---------- Table 3 sample ----------
s3 <- d[!d$is_commit & !is.na(d$assigned_rate) &
          !is.na(d$bcp) & !is.na(d$goal_gap) & !is.na(d$act_gap) & !is.na(d$wave_n), ]
cat("Table 3 sample N:", nrow(s3), "\n")
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s3$goal_gap_z <- z(s3$goal_gap)
s3$act_gap_z <- z(s3$act_gap)
s3$bcp_z <- z(s3$bcp)

tryCatch({
  m1 <- feols(bcp ~ basic_info + enh_info | wave_n, data = s3, vcov = "hetero")
  m2 <- feols(bcp ~ basic_info + enh_info + goal_gap_z | wave_n, data = s3, vcov = "hetero")
  m3 <- feols(bcp ~ basic_info + enh_info + act_gap_z | wave_n, data = s3, vcov = "hetero")
  print(etable(m1, m2, m3))
  results$bcp_basic_info_treatment_col1 <- coef(m1)["basic_info"]
  results$bcp_enhanced_info_treatment_col1 <- coef(m1)["enh_info"]
  results$bcp_goal_minus_expected_attendance_col2 <- coef(m2)["goal_gap_z"]
  results$bcp_actual_minus_expected_attendance_col3 <- coef(m3)["act_gap_z"]
  results$bcp_regression_observations <- nobs(m1)
}, error = function(e) cat("Table 3 error:", conditionMessage(e), "\n"))

# ---------- Table 4: more contracts, long format ----------
tryCatch({
  cc <- grep("^chose_commit[0-9]+$", names(s3), value = TRUE)
  cat("More-contract columns:", paste(cc, collapse = ", "), "\n")
  if (nrow(s3) == 0 || length(cc) == 0) stop("no data for Table 4")
  long <- do.call(rbind, lapply(cc, function(v) {
    data.frame(id_row = s3$id_row, wave_n = s3$wave_n,
               basic_info = s3$basic_info, enh_info = s3$enh_info,
               bcp_z = s3$bcp_z, goal_gap_z = s3$goal_gap_z, act_gap_z = s3$act_gap_z,
               threshold = rep(as.numeric(sub("chose_commit", "", v)), nrow(s3)),
               chose = num(s3[[v]]))
  }))
  long <- long[!is.na(long$chose), ]
  if (max(long$chose, na.rm = TRUE) > 1) long$chose <- as.numeric(long$chose == max(long$chose))
  cat("Table 4 long N:", nrow(long), "\n")
  fe <- if (length(unique(long$threshold)) > 1) "wave_n + threshold" else "wave_n"
  mk <- function(rhs) as.formula(paste("chose ~", rhs, "|", fe))
  t1 <- feols(mk("basic_info + enh_info"), data = long, cluster = ~id_row)
  t2 <- feols(mk("basic_info + enh_info + bcp_z"), data = long, cluster = ~id_row)
  t3 <- feols(mk("basic_info + enh_info + goal_gap_z"), data = long, cluster = ~id_row)
  t4 <- feols(mk("basic_info + enh_info + act_gap_z"), data = long, cluster = ~id_row)
  print(etable(t1, t2, t3, t4))
  results$takeup_more_basic_info_treatment_col1 <- coef(t1)["basic_info"]
  results$takeup_more_enhanced_info_treatment_col1 <- coef(t1)["enh_info"]
  results$takeup_more_behavior_change_premium_col2 <- coef(t2)["bcp_z"]
  results$takeup_more_goal_minus_expected_attendance_col3 <- coef(t3)["goal_gap_z"]
  results$takeup_more_actual_minus_expected_attendance_col4 <- coef(t4)["act_gap_z"]
  results$takeup_more_regression_observations <- nobs(t1)
}, error = function(e) cat("Table 4 error:", conditionMessage(e), "\n"))

for (n in names(results)) {
  cat(sprintf("RESULT:%s=%s\n", n, format(unname(as.numeric(results[[n]])), digits = 10)))
}