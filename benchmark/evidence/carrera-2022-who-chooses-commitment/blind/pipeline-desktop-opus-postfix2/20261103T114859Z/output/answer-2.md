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
nms <- names(raw)
cat("COLUMNS:", paste(nms, collapse = ","), "\n")

# keep a text version of the treatment label before stripping labels
treat_txt <- if ("treatment" %in% nms) as.character(as_factor(raw$treatment)) else rep(NA_character_, nrow(raw))
info_txt  <- if ("type_of_info" %in% nms) as.character(as_factor(raw$type_of_info)) else rep(NA_character_, nrow(raw))
wave_txt  <- if ("wave" %in% nms) as.character(as_factor(raw$wave)) else rep(NA_character_, nrow(raw))
inc_txt   <- if ("incentivetext" %in% nms) as.character(as_factor(raw$incentivetext)) else rep(NA_character_, nrow(raw))
df <- zap_labels(raw)
df$treat_txt <- treat_txt
df$info_txt <- info_txt
num <- function(x) suppressWarnings(as.numeric(x))
digits_of <- function(x) num(sub("^[^0-9]*([0-9]+(\\.[0-9]+)?).*$", "\\1", ifelse(grepl("[0-9]", x), x, NA)))

# ---------- subject id ----------
id_cands <- c("id", "subject", "subject_id", "participant_id", "pid", "responseid", "ResponseId", "subjectid", "userid", "anon_id")
idv <- intersect(id_cands, nms)
df$sid <- if (length(idv)) as.character(df[[idv[1]]]) else as.character(seq_len(nrow(df)))

# ---------- information treatment ----------
info_cands <- c("info", "info_treatment", "infotreatment", "treat_info", "information", "info_treat",
                "got_info", "received_info", "infotreat", "info_arm", "treatment_info")
iv <- intersect(info_cands, nms)
if (length(iv)) {
  df$info <- as.numeric(num(df[[iv[1]]]) > 0)
  cat("NOTE: info variable =", iv[1], "\n")
} else {
  it <- tolower(df$info_txt)
  itn <- num(df$type_of_info)
  if (all(is.na(it)) || all(it == "" | is.na(it))) {
    df$info <- as.numeric(itn > 0)
  } else {
    df$info <- as.numeric(!grepl("^\\s*(no|none|control|0)", it) & !is.na(it) & it != "")
  }
  cat("NOTE: info derived from type_of_info; levels:", paste(unique(df$info_txt), collapse = "|"), "\n")
}

# ---------- wave (robust: raw wave may be a string label) ----------
wv <- num(df$wave)
if (all(is.na(wv)) && "wavenum" %in% nms) wv <- num(df$wavenum)
if (all(is.na(wv))) wv <- digits_of(wave_txt)
if (all(is.na(wv))) wv <- digits_of(as.character(df$wave))
if (all(is.na(wv))) {
  wv <- as.numeric(factor(as.character(df$wave)))
}
cat("NOTE: wave values:", paste(sort(unique(wv)), collapse = "|"), "; raw wave levels:",
    paste(head(unique(as.character(df$wave)), 10), collapse = "|"), "\n")
df$wave <- wv
df$basic_info <- as.numeric(df$info == 1 & df$wave == 1)
df$enhanced_info <- as.numeric(df$info == 1 & df$wave %in% c(2, 3))

# ---------- forecasts at each piece rate ----------
rates <- c(1, 2, 3, 5, 7, 12)
prefs <- unique(sub("12$", "", grep("12$", nms, value = TRUE)))
prefs <- prefs[sapply(prefs, function(p) all(paste0(p, rates) %in% nms))]
prefs <- setdiff(prefs, c("wtp", "previsits"))
prefs <- prefs[!grepl("wtp|slider|chose|commit|previsit", prefs, ignore.case = TRUE)]
pref_pri <- prefs[grepl("exp|fore|pred|guess|belief|est|days", prefs, ignore.case = TRUE)]
fpref <- if (length(pref_pri)) pref_pri[1] else prefs[1]
cat("NOTE: forecast prefix =", fpref, "\n")
for (r in rates) {
  df[[paste0("f", r)]] <- num(df[[paste0(fpref, r)]])
  df[[paste0("w", r)]] <- num(df[[paste0("wtp", r)]])
}

# expected attendance with no incentive
e0_cands <- c(paste0(fpref, "0"), "bestguess", "best_guess", "exp0", "expected", "exp_visits", "guess",
              "expected_visits", "visits_guess", "expvisits", "bestguess_visits")
e0v <- intersect(e0_cands, nms)
if (!length(e0v)) e0v <- grep("best.?guess|guess", nms, value = TRUE, ignore.case = TRUE)
cat("NOTE: expected-without-incentive var =", e0v[1], "\n")
df$exp0 <- num(df[[e0v[1]]])

# ---------- BCP (conservative: adjacent pairs from $1 upward) ----------
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bmat <- sapply(pairs, function(pr) {
  p1 <- pr[1]; p2 <- pr[2]
  (df[[paste0("w", p2)]] - df[[paste0("w", p1)]]) / (p2 - p1) -
    (df[[paste0("f", p2)]] + df[[paste0("f", p1)]]) / 2
})
df$bcp <- rowMeans(bmat, na.rm = TRUE)
df$bcp[is.nan(df$bcp)] <- NA

# ---------- assigned incentive and commitment-contract group ----------
tt <- tolower(df$treat_txt)
inc <- num(df$incentive)
if (all(is.na(inc))) inc <- digits_of(as.character(df$incentive))
# fill from treatment label (perdayN -> N, control -> 0) where missing
inc_tt <- ifelse(grepl("^\\s*perday", tt), digits_of(tt), ifelse(grepl("control", tt), 0, NA))
inc[is.na(inc)] <- inc_tt[is.na(inc)]
df$incentive <- inc
df$commit_assigned <- as.numeric(df$wave == 3 & (grepl("commit|threshold|80|12\\+|12 or more|at least", tt) ))
df$commit_assigned[is.na(df$commit_assigned)] <- 0
cat("NOTE: treatment levels:", paste(unique(df$treat_txt), collapse = "|"), "\n")
cat("NOTE: incentive values:", paste(sort(unique(df$incentive)), collapse = "|"), "\n")

# expected attendance under assigned incentive
df$exp_assigned <- NA_real_
for (r in rates) {
  sel <- !is.na(df$incentive) & df$incentive == r
  df$exp_assigned[sel] <- df[[paste0("f", r)]][sel]
}
sel0 <- !is.na(df$incentive) & df$incentive == 0
df$exp_assigned[sel0] <- df$exp0[sel0]

df$visits <- num(df$visits)
df$goal <- num(df$goal)
df$goal_gap <- df$goal - df$exp0
df$act_gap <- df$visits - df$exp_assigned

cat(sprintf("NOTE: nonmissing counts: bcp=%d goal_gap=%d act_gap=%d info=%d wave=%d\n",
            sum(!is.na(df$bcp)), sum(!is.na(df$goal_gap)), sum(!is.na(df$act_gap)),
            sum(!is.na(df$info)), sum(!is.na(df$wave))))

# ---------- Sample accounting ----------
cat(sprintf("SAMPLE:table3:loaded=%d\n", nrow(df)))
s <- df %>% filter(is.na(num(flag_exclude_exog)) | num(flag_exclude_exog) != 1)
cat(sprintf("SAMPLE:table3:exclude_endogenous_incentive=%d\n", nrow(s)))
s <- s %>% filter(commit_assigned != 1)
cat(sprintf("SAMPLE:table3:exclude_wave3_commitment_assigned=%d\n", nrow(s)))
s <- s %>% filter(!is.na(bcp), !is.na(goal_gap), !is.na(act_gap), !is.na(info), !is.na(wave))
cat(sprintf("SAMPLE:table3:nonmissing_measures=%d\n", nrow(s)))

z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s$goal_gap_z <- z(s$goal_gap)
s$act_gap_z <- z(s$act_gap)
s$bcp_z <- z(s$bcp)

m1 <- feols(bcp ~ basic_info + enhanced_info | wave, data = s, vcov = "hetero")
m2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave, data = s, vcov = "hetero")
m3 <- feols(bcp ~ basic_info + enhanced_info + act_gap_z | wave, data = s, vcov = "hetero")
cat(sprintf("SAMPLE:table3:estimation=%d\n", nobs(m1)))

# ---------- Table 4: long "more" contract choices ----------
cc <- grep("^chose_commit[0-9]+$", nms, value = TRUE)
cat("NOTE: commitment choice vars =", paste(cc, collapse = ","), "\n")
long <- s %>%
  select(sid, wave, basic_info, enhanced_info, bcp_z, goal_gap_z, act_gap_z, all_of(cc)) %>%
  mutate(across(all_of(cc), num)) %>%
  pivot_longer(all_of(cc), names_to = "contract", values_to = "takeup") %>%
  mutate(threshold = as.numeric(sub("chose_commit", "", contract)))
cat(sprintf("SAMPLE:table4:loaded=%d\n", nrow(long)))
long <- long %>% filter(!(wave == 3 & threshold != 12))
cat(sprintf("SAMPLE:table4:thresholds_offered=%d\n", nrow(long)))
long <- long %>% filter(!is.na(takeup))
cat(sprintf("SAMPLE:table4:nonmissing_choice=%d\n", nrow(long)))

t1 <- feols(takeup ~ basic_info + enhanced_info | wave + threshold, data = long, cluster = ~sid)
t2 <- feols(takeup ~ basic_info + enhanced_info + bcp_z | wave + threshold, data = long, cluster = ~sid)
t3 <- feols(takeup ~ basic_info + enhanced_info + goal_gap_z | wave + threshold, data = long, cluster = ~sid)
t4 <- feols(takeup ~ basic_info + enhanced_info + act_gap_z | wave + threshold, data = long, cluster = ~sid)
cat(sprintf("SAMPLE:table4:estimation=%d\n", nobs(t1)))

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("bcp_basic_info_treatment_col1", coef(m1)["basic_info"])
out("bcp_enhanced_info_treatment_col1", coef(m1)["enhanced_info"])
out("bcp_goal_minus_expected_attendance_col2", coef(m2)["goal_gap_z"])
out("bcp_actual_minus_expected_attendance_col3", coef(m3)["act_gap_z"])
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m1)))
out("takeup_more_basic_info_treatment_col1", coef(t1)["basic_info"])
out("takeup_more_enhanced_info_treatment_col1", coef(t1)["enhanced_info"])
out("takeup_more_behavior_change_premium_col2", coef(t2)["bcp_z"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(t3)["goal_gap_z"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(t4)["act_gap_z"])
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t1)))
