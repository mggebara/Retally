suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- read_dta(f)
d <- as.data.frame(raw)
nm <- names(d)
cat("Columns:\n"); print(nm)

num <- function(x) {
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  as.numeric(zap_labels(x))
}
txt <- function(x) {
  if (is.labelled(x)) return(as.character(as_factor(x)))
  as.character(x)
}

rates <- c(1, 2, 3, 5, 7, 12)

## ---- locate forecast columns for each piece rate ----
ends_num <- grepl("[^0-9][0-9]+$", nm)
pref <- sub("[0-9]+$", "", nm)
suf <- suppressWarnings(as.numeric(sub("^.*[^0-9]([0-9]+)$", "\\1", nm)))
cand <- data.frame(name = nm, pref = pref, suf = suf, stringsAsFactors = FALSE)[ends_num, ]
prefs <- unique(cand$pref)
good <- c()
for (p in prefs) {
  if (grepl("wtp|slider|previsit|commit|past|percent|prob|passed|check|flag", p, ignore.case = TRUE)) next
  s <- cand$suf[cand$pref == p]
  if (all(rates %in% s)) good <- c(good, p)
}
cat("Candidate forecast prefixes:", paste(good, collapse = ", "), "\n")
fc_pref <- NA
if (length(good) > 0) {
  score <- sapply(good, function(p) {
    sc <- 0
    if (grepl("exp|fore|pred|guess|belief|fc", p, ignore.case = TRUE)) sc <- sc + 10
    vals <- unlist(lapply(rates, function(r) num(d[[paste0(p, r)]])))
    vals <- vals[!is.na(vals)]
    if (length(vals) > 0 && max(vals) <= 28 && min(vals) >= 0) sc <- sc + 5
    if (length(vals) > 0) sc <- sc + length(vals) / 1e5
    sc
  })
  fc_pref <- good[which.max(score)]
}
cat("Using forecast prefix:", fc_pref, "\n")
fc <- function(r) num(d[[paste0(fc_pref, r)]])
wtp <- function(r) num(d[[paste0("wtp", r)]])

## ---- basic variables ----
## wave: the 'wave' column may be text; prefer numeric 'wavenum', else parse digits
cat("wave values:\n"); print(table(txt(raw$wave), useNA = "ifany"))
if ("wavenum" %in% nm) { cat("wavenum values:\n"); print(table(txt(raw$wavenum), useNA = "ifany")) }
wave_try <- function(x) {
  v <- num(x)
  if (all(is.na(v))) {
    tt <- txt(x)
    v <- suppressWarnings(as.numeric(sub("^\\D*(\\d+).*$", "\\1", tt)))
    v[!grepl("\\d", tt)] <- NA
  }
  v
}
d$wave_n <- if ("wavenum" %in% nm) wave_try(d$wavenum) else rep(NA_real_, nrow(d))
if (all(is.na(d$wave_n))) d$wave_n <- wave_try(d$wave)
if (all(is.na(d$wave_n))) d$wave_n <- as.numeric(factor(txt(d$wave)))
cat("wave_n:\n"); print(table(d$wave_n, useNA = "ifany"))

## treatment: may be text; map to 0/1
cat("treatment values:\n"); print(table(txt(raw$treatment), useNA = "ifany"))
if ("type_of_info" %in% nm) { cat("type_of_info values:\n"); print(table(txt(raw$type_of_info), useNA = "ifany")) }
d$treat_n <- num(d$treatment)
if (all(is.na(d$treat_n))) {
  tt <- tolower(txt(d$treatment))
  d$treat_n <- ifelse(is.na(tt) | tt == "", NA_real_,
                      as.numeric(!grepl("control|no info|none|^no$|untreated", tt)))
}
if (!all(d$treat_n %in% c(0, 1, NA))) d$treat_n <- as.numeric(d$treat_n == max(d$treat_n, na.rm = TRUE))
cat("treat_n:\n"); print(table(d$treat_n, d$wave_n, useNA = "ifany"))
d$basic <- as.numeric(d$treat_n == 1 & d$wave_n == 1)
d$enh <- as.numeric(d$treat_n == 1 & d$wave_n %in% c(2, 3))
d$inc <- num(d$incentive)

## ---- sample: exogenous incentive ----
fl <- num(d$flag_exclude_exog)
fl[is.na(fl)] <- 0
if (sum(fl == 1) <= sum(fl == 0)) keep <- fl == 0 else keep <- fl == 1
cat("Excluded (endogenous):", sum(!keep), "\n")

## wave 3 commitment-contract assignment
itxt <- if ("incentivetext" %in% nm) as.character(as_factor(raw$incentivetext)) else rep("", nrow(d))
itxt[is.na(itxt)] <- ""
cat("Incentive values:\n"); print(table(d$inc, useNA = "ifany"))
cat("Incentive text:\n"); print(table(itxt, useNA = "ifany"))
commit <- grepl("commit|80|12 or more|at least|contract", itxt, ignore.case = TRUE) |
  (!is.na(d$inc) & !(d$inc %in% c(0, rates)))
commit[is.na(commit)] <- FALSE
cat("Commitment-assigned:", sum(commit & keep), "\n")

## ---- behavior change premium (conservative) ----
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bm <- sapply(pairs, function(pr) {
  p <- pr[1]; q <- pr[2]
  (wtp(q) - wtp(p)) / (q - p) - (fc(q) + fc(p)) / 2
})
d$bcp <- rowMeans(bm, na.rm = TRUE)
d$bcp[is.nan(d$bcp)] <- NA

## ---- expected attendance measures ----
d$actual <- num(d$visits)
bg_col <- nm[grepl("best|guess", nm, ignore.case = TRUE)]
d$expected0 <- if (length(bg_col) > 0) num(d[[bg_col[1]]]) else num(d$visits_next4weeks)
d$goal_n <- num(d$goal)
d$goal_gap <- d$goal_n - d$expected0
d$exp_assigned <- NA_real_
for (r in rates) {
  ii <- which(!is.na(d$inc) & d$inc == r)
  d$exp_assigned[ii] <- fc(r)[ii]
}
ii0 <- which(!is.na(d$inc) & d$inc == 0)
d$exp_assigned[ii0] <- d$expected0[ii0]
d$act_gap <- d$actual - d$exp_assigned

## ---- id ----
idc <- nm[tolower(nm) %in% c("id", "subject", "subject_id", "subjectid", "participant", "participant_id", "pid", "responseid", "uid", "studyid")]
d$sid <- if (length(idc) > 0) as.character(d[[idc[1]]]) else as.character(seq_len(nrow(d)))

s <- d[keep & !commit, ]
s <- s[!is.na(s$bcp) & !is.na(s$wave_n) & !is.na(s$basic) & !is.na(s$enh), ]
cat("Table 3 sample size:", nrow(s), "\n")
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s$goal_z <- z(s$goal_gap)
s$act_z <- z(s$act_gap)
s$bcp_z <- z(s$bcp)

m1 <- feols(bcp ~ basic + enh | wave_n, data = s, vcov = "hetero")
m2 <- feols(bcp ~ basic + enh + goal_z | wave_n, data = s, vcov = "hetero")
m3 <- feols(bcp ~ basic + enh + act_z | wave_n, data = s, vcov = "hetero")
print(etable(m1, m2, m3))

## ---- Table 4: "more" contracts long ----
more_cols <- nm[grepl("^chose_commit[0-9]+$", nm)]
cat("More-contract columns:", paste(more_cols, collapse = ", "), "\n")
L <- do.call(rbind, lapply(more_cols, function(cc) {
  th <- as.numeric(sub("^chose_commit", "", cc))
  data.frame(sid = s$sid, wave_n = s$wave_n, basic = s$basic, enh = s$enh,
             bcp_z = s$bcp_z, goal_z = s$goal_z, act_z = s$act_z,
             thr = th, take = num(s[[cc]]), stringsAsFactors = FALSE)
}))
L <- L[!is.na(L$take), ]
if (max(L$take, na.rm = TRUE) > 1) L$take <- as.numeric(L$take == max(L$take, na.rm = TRUE))
cat("Table 4 obs:", nrow(L), "\n")
fe4 <- if (length(unique(L$thr)) > 1) "wave_n + thr" else "wave_n"
t1 <- feols(as.formula(paste("take ~ basic + enh |", fe4)), data = L, cluster = ~sid)
t2 <- feols(as.formula(paste("take ~ basic + enh + bcp_z |", fe4)), data = L, cluster = ~sid)
t3 <- feols(as.formula(paste("take ~ basic + enh + goal_z |", fe4)), data = L, cluster = ~sid)
t4 <- feols(as.formula(paste("take ~ basic + enh + act_z |", fe4)), data = L, cluster = ~sid)
print(etable(t1, t2, t3, t4))

g <- function(m, v) { cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", g(m1, "basic")))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", g(m1, "enh")))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", g(m2, "goal_z")))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", g(m3, "act_z")))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m1)))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", g(t1, "basic")))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", g(t1, "enh")))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", g(t2, "bcp_z")))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", g(t3, "goal_z")))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", g(t4, "act_z")))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t1)))