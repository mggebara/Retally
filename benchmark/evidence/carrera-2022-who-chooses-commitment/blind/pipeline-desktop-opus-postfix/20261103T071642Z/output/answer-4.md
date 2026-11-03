suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(tidyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- read_dta(f)
nm <- names(raw)

# ---------- helpers ----------
to_num <- function(x) {
  if (inherits(x, "haven_labelled")) x <- zap_labels(x)
  suppressWarnings(as.numeric(x))
}
to_chr <- function(x) {
  if (inherits(x, "haven_labelled")) return(tolower(as.character(as_factor(x, levels = "both"))))
  tolower(as.character(x))
}
first_match <- function(cands) {
  for (cc in cands) if (cc %in% nm) return(cc)
  NA_character_
}
zscore <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
# robust numeric parse: handles labelled numerics and strings like "Wave 1" / "$12"
parse_num <- function(x) {
  n <- to_num(x)
  if (all(is.na(n[!is.na(x)])) || all(is.na(n))) {
    ch <- if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "labels")) else as.character(x)
    out <- rep(NA_real_, length(ch))
    has <- grepl("[0-9]", ch) & !is.na(ch)
    if (any(has)) {
      d <- regmatches(ch[has], regexpr("[0-9]+(\\.[0-9]+)?", ch[has]))
      out[has] <- as.numeric(d)
    }
    if (inherits(x, "haven_labelled") && all(is.na(out))) out <- as.numeric(unclass(zap_labels(x)))
    n <- out
  }
  n
}
# wave parse: numbers, number words, ordinals, else factor codes
parse_wave <- function(x) {
  n <- parse_num(x)
  if (all(is.na(n))) {
    ch <- tolower(trimws(if (inherits(x, "haven_labelled")) as.character(as_factor(x, levels = "labels")) else as.character(x)))
    ch[ch == ""] <- NA
    words <- c(one = 1, first = 1, i = 1, two = 2, second = 2, ii = 2, three = 3, third = 3, iii = 3)
    out <- rep(NA_real_, length(ch))
    for (w in names(words)) {
      hit <- is.na(out) & !is.na(ch) & grepl(paste0("(^|[^a-z])", w, "([^a-z]|$)"), ch)
      out[hit] <- words[[w]]
    }
    if (all(is.na(out)) && any(!is.na(ch))) out <- as.numeric(factor(ch, levels = sort(unique(ch[!is.na(ch)]))))
    n <- out
  }
  n
}

df <- raw
wave_src <- if ("wave" %in% nm) "wave" else first_match(c("Wave", "wave_n", "study_wave", "round", "session"))
cat("INFO: wave column:", wave_src, " class:", paste(class(df[[wave_src]]), collapse = "/"), "\n")
cat("INFO: raw wave values:", paste(head(unique(as.character(df[[wave_src]])), 10), collapse = ","), "\n")
df$wave_n <- parse_wave(df[[wave_src]])
if (all(is.na(df$wave_n))) {
  # fall back to wave indicator dummies, e.g. wave1/wave2/wave3
  wd <- grep("^wave_?[123]$", nm, value = TRUE, ignore.case = TRUE)
  if (length(wd) > 0) {
    df$wave_n <- NA_real_
    for (v in wd) {
      k <- as.numeric(sub("^wave_?", "", tolower(v)))
      sel <- !is.na(to_num(df[[v]])) & to_num(df[[v]]) == 1
      df$wave_n[sel] <- k
    }
  }
}
cat("INFO: wave values:", paste(sort(unique(df$wave_n)), collapse = ","), "\n")
df$incentive_n <- parse_num(df$incentive)
df$flag_ex <- to_num(df$flag_exclude_exog)
df$flag_ex[is.na(df$flag_ex)] <- 0

# ---------- subject id ----------
id_col <- first_match(c("id", "subject_id", "subjectid", "participant_id", "participant", "subject", "pid", "ID", "responseid", "ResponseId", "uid"))
if (is.na(id_col)) {
  g <- grep("(^|_)id$|^id_|subject|participant", nm, value = TRUE, ignore.case = TRUE)
  if (length(g) > 0) id_col <- g[1]
}
if (is.na(id_col)) df$sid <- seq_len(nrow(df)) else df$sid <- as.character(df[[id_col]])

# ---------- information treatment indicator ----------
info_col <- first_match(c("info", "info_treatment", "infotreatment", "information", "info_treat", "treat_info", "information_treatment", "infotreat"))
if (is.na(info_col)) {
  g <- grep("info", nm, value = TRUE, ignore.case = TRUE)
  g <- setdiff(g, c("type_of_info"))
  if (length(g) > 0) {
    keep <- vapply(g, function(v) {
      x <- to_num(df[[v]]); u <- unique(x[!is.na(x)]); length(u) == 2 && all(u %in% c(0, 1))
    }, logical(1))
    g <- g[keep]
  }
  if (length(g) > 0) info_col <- g[1]
}
if (!is.na(info_col)) {
  df$info <- to_num(df[[info_col]])
} else if ("type_of_info" %in% nm) {
  ti <- to_chr(df$type_of_info)
  tn <- to_num(df$type_of_info)
  if (all(is.na(tn)) || length(unique(tn[!is.na(tn)])) > 3) {
    df$info <- as.numeric(!(grepl("no|none|control", ti) | is.na(ti) | ti == ""))
  } else {
    df$info <- as.numeric(tn > 0)
  }
} else {
  stop("No information treatment column found")
}
df$info[is.na(df$info)] <- 0
df$basic_info <- as.numeric(df$info == 1 & !is.na(df$wave_n) & df$wave_n == 1)
df$enhanced_info <- as.numeric(df$info == 1 & !is.na(df$wave_n) & df$wave_n %in% c(2, 3))

# ---------- forecasts at each piece rate ----------
rates <- c(1, 2, 3, 5, 7, 12)
wtp_cols <- paste0("wtp", rates)
excl_prefix <- "^(wtp|sliderintro_wtp|previsits|chose_commit|chose_anticommit|percent_meet|past|commit|anticommit)"
prefixes <- list()
for (r in rates) {
  m <- grep(paste0("\\D", r, "$"), nm, value = TRUE)
  for (v in m) {
    p <- sub(paste0(r, "$"), "", v)
    if (grepl(excl_prefix, p, ignore.case = TRUE)) next
    prefixes[[p]] <- c(prefixes[[p]], r)
  }
}
full <- character(0)
if (length(prefixes) > 0) {
  full <- names(prefixes)[vapply(prefixes, function(z) all(rates %in% z), logical(1))]
}
if (length(full) == 0) stop("No forecast columns found")
pref_score <- vapply(full, function(p) {
  s <- 0
  if (grepl("exp|forecast|predict|guess|belief|est", p, ignore.case = TRUE)) s <- s + 2
  if (grepl("visit|att", p, ignore.case = TRUE)) s <- s + 1
  if (grepl("prob|percent|sd|var", p, ignore.case = TRUE)) s <- s - 3
  s
}, numeric(1))
fprefix <- full[which.max(pref_score)]
fc_cols <- paste0(fprefix, rates)
cat("INFO: forecast columns:", paste(fc_cols, collapse = ","), "\n")

for (r in rates) {
  df[[paste0("W", r)]] <- to_num(df[[paste0("wtp", r)]])
  df[[paste0("F", r)]] <- to_num(df[[paste0(fprefix, r)]])
}

# ---------- behavior change premium (conservative, pairs from $1 upward) ----------
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bcp_mat <- sapply(pairs, function(pp) {
  p0 <- pp[1]; p1 <- pp[2]; d <- p1 - p0
  (df[[paste0("W", p1)]] - df[[paste0("W", p0)]]) / d -
    (df[[paste0("F", p1)]] + df[[paste0("F", p0)]]) / 2
})
df$bcp <- rowMeans(bcp_mat, na.rm = FALSE)

# ---------- expected attendance without incentive ----------
exp0_col <- first_match(c(paste0(fprefix, "0"), "visits_bestguess", "bestguess", "best_guess", "expected_visits",
                          "exp_visits", "expected", "guess", "forecast0", "exp_visits0", "expected_attendance"))
if (is.na(exp0_col)) {
  g <- grep("guess|expect|best|forecast", nm, value = TRUE, ignore.case = TRUE)
  g <- setdiff(g, fc_cols)
  g <- g[!grepl("prob|percent|goal|commit", g, ignore.case = TRUE)]
  if (length(g) > 0) exp0_col <- g[1]
}
if (is.na(exp0_col)) stop("No expected-attendance (no incentive) column found")
cat("INFO: expected attendance (no incentive) column:", exp0_col, "\n")
df$exp0 <- to_num(df[[exp0_col]])
df$goal_n <- to_num(df$goal)
df$visits_n <- to_num(df$visits)

# expected attendance under assigned incentive
df$exp_assigned <- NA_real_
df$exp_assigned[!is.na(df$incentive_n) & df$incentive_n == 0] <- df$exp0[!is.na(df$incentive_n) & df$incentive_n == 0]
for (r in rates) {
  sel <- !is.na(df$incentive_n) & df$incentive_n == r
  df$exp_assigned[sel] <- df[[paste0("F", r)]][sel]
}

df$goal_gap <- df$goal_n - df$exp0
df$actual_gap <- df$visits_n - df$exp_assigned

# ---------- commitment-contract assignment (wave 3) ----------
tr <- to_chr(df$treatment)
df$assigned_commit <- as.numeric(grepl("commit|contract|12\\+|80", tr) | (!is.na(df$incentive_n) & df$incentive_n >= 80))
df$assigned_commit[is.na(df$assigned_commit)] <- 0

# ---------- Table 3 sample ----------
cat(sprintf("SAMPLE:table3:loaded=%d\n", nrow(df)))
s3 <- df %>% filter(flag_ex == 0)
cat(sprintf("SAMPLE:table3:exclude_endogenous_incentive=%d\n", nrow(s3)))
s3 <- s3 %>% filter(!(!is.na(wave_n) & wave_n == 3 & assigned_commit == 1))
cat(sprintf("SAMPLE:table3:exclude_wave3_commitment_assigned=%d\n", nrow(s3)))

s3$goal_gap_z <- zscore(s3$goal_gap)
s3$actual_gap_z <- zscore(s3$actual_gap)

m3_1 <- feols(bcp ~ basic_info + enhanced_info | wave_n, data = s3, vcov = "hetero")
m3_2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave_n, data = s3, vcov = "hetero")
m3_3 <- feols(bcp ~ basic_info + enhanced_info + actual_gap_z | wave_n, data = s3, vcov = "hetero")
cat(sprintf("SAMPLE:table3:estimation=%d\n", nobs(m3_1)))

# ---------- Table 4: "more" commitment contracts ----------
more_cols <- grep("^chose_commit[0-9]+$", nm, value = TRUE)
if (length(more_cols) == 0) more_cols <- grep("^chose_commit", nm, value = TRUE)
cat("INFO: more-contract columns:", paste(more_cols, collapse = ","), "\n")

s3$bcp_z <- zscore(s3$bcp)
long <- s3 %>%
  select(sid, wave_n, basic_info, enhanced_info, bcp, bcp_z, goal_gap_z, actual_gap_z, all_of(more_cols)) %>%
  mutate(across(all_of(more_cols), to_num)) %>%
  pivot_longer(all_of(more_cols), names_to = "contract", values_to = "takeup") %>%
  mutate(threshold = as.numeric(sub("^chose_commit", "", contract)))

cat(sprintf("SAMPLE:table4:loaded=%d\n", nrow(df)))
cat(sprintf("SAMPLE:table4:exclude_endogenous_incentive=%d\n", sum(df$flag_ex == 0)))
cat(sprintf("SAMPLE:table4:exclude_wave3_commitment_assigned=%d\n", nrow(s3)))
cat(sprintf("SAMPLE:table4:stack_participant_by_threshold=%d\n", nrow(long)))
long <- long %>% filter(!is.na(takeup))
cat(sprintf("SAMPLE:table4:contracts_offered=%d\n", nrow(long)))

m4_1 <- feols(takeup ~ basic_info + enhanced_info | wave_n + threshold, data = long, cluster = ~sid)
m4_2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wave_n + threshold, data = long, cluster = ~sid)
m4_3 <- feols(takeup ~ basic_info + enhanced_info + goal_gap_z | wave_n + threshold, data = long, cluster = ~sid)
m4_4 <- feols(takeup ~ basic_info + enhanced_info + actual_gap_z | wave_n + threshold, data = long, cluster = ~sid)
cat(sprintf("SAMPLE:table4:estimation=%d\n", nobs(m4_1)))

# ---------- results ----------
out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("bcp_basic_info_treatment_col1", coef(m3_1)["basic_info"])
out("bcp_enhanced_info_treatment_col1", coef(m3_1)["enhanced_info"])
out("bcp_goal_minus_expected_attendance_col2", coef(m3_2)["goal_gap_z"])
out("bcp_actual_minus_expected_attendance_col3", coef(m3_3)["actual_gap_z"])
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m3_1)))
out("takeup_more_basic_info_treatment_col1", coef(m4_1)["basic_info"])
out("takeup_more_enhanced_info_treatment_col1", coef(m4_1)["enhanced_info"])
out("takeup_more_behavior_change_premium_col2", coef(m4_2)["bcp_z"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(m4_3)["goal_gap_z"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(m4_4)["actual_gap_z"])
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(m4_1)))
