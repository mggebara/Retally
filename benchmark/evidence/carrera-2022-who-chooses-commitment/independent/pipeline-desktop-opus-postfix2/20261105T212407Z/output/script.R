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

labs <- sapply(names(raw), function(n) {
  l <- attr(raw[[n]], "label"); if (is.null(l)) "" else as.character(l)
})
names(labs) <- names(raw)
# keep treatment value labels as text
treat_txt <- if (inherits(raw$treatment, "haven_labelled")) as.character(haven::as_factor(raw$treatment)) else as.character(raw$treatment)
df <- haven::zap_labels(raw)
df <- as.data.frame(df)
df$treat_txt <- treat_txt
df$pid <- seq_len(nrow(df))

num <- function(x) suppressWarnings(as.numeric(x))

# ---------- locate incentive-indexed variable families via name templates ----------
rates <- c(1, 2, 3, 5, 7, 12)
allr <- c(0, rates)
# vectorised over r (sub() only uses the first replacement element)
vn <- function(tpl, r) vapply(r, function(ri) sub("{R}", as.character(ri), tpl, fixed = TRUE), character(1))
tpl_rows <- lapply(names(df), function(nm) {
  m <- gregexpr("[0-9]+", nm)[[1]]
  if (m[1] == -1) return(NULL)
  ln <- attr(m, "match.length")
  out <- list()
  for (i in seq_along(m)) {
    val <- as.numeric(substr(nm, m[i], m[i] + ln[i] - 1))
    if (val %in% allr) {
      tpl <- paste0(substr(nm, 1, m[i] - 1), "{R}", substr(nm, m[i] + ln[i], nchar(nm)))
      out[[length(out) + 1]] <- data.frame(tpl = tpl, rate = val, stringsAsFactors = FALSE)
    }
  }
  if (length(out)) do.call(rbind, out) else NULL
})
tpl_df <- do.call(rbind, tpl_rows)
if (is.null(tpl_df) || nrow(tpl_df) == 0) stop("No rate-indexed variables found. Names: ", paste(names(df), collapse = ","))
full_tpls <- unique(tpl_df$tpl)
full_tpls <- full_tpls[vapply(full_tpls, function(t) all(vn(t, rates) %in% names(df)), logical(1))]
cat(sprintf("NOTE: full rate templates = %s\n", paste(full_tpls, collapse = ",")))

# WTP template
wtp_cands <- full_tpls[grepl("wtp", full_tpls, ignore.case = TRUE) & !grepl("slider|intro", full_tpls, ignore.case = TRUE)]
if (length(wtp_cands) == 0) wtp_cands <- full_tpls[grepl("wtp|willing|pay", full_tpls, ignore.case = TRUE)]
if (length(wtp_cands) == 0) stop("Could not locate WTP variables. Templates: ", paste(full_tpls, collapse = ","))
wtpl <- if ("wtp{R}" %in% wtp_cands) "wtp{R}" else wtp_cands[1]
cat(sprintf("NOTE: wtp template = '%s'\n", wtpl))

# forecast template
cands <- full_tpls[!grepl("wtp|slider|previsit|^days|^day\\{|chose|commit|contract|incentive|treat|week|passed|try|risk", full_tpls, ignore.case = TRUE)]
if (length(cands) == 0) {
  stop("Could not locate forecast variables. Full templates: ", paste(full_tpls, collapse = ","),
       " | All names: ", paste(names(df), collapse = ","))
}
score <- vapply(cands, function(p) {
  l <- labs[vn(p, 1)]; if (is.na(l)) l <- ""
  s <- 0
  if (grepl("expect|forecast|predict|think|believe|estimat|anticipat|belief", l, ignore.case = TRUE)) s <- s + 2
  if (grepl("exp|forecast|pred|^e_|att|belief|visit", p, ignore.case = TRUE)) s <- s + 1
  v <- num(df[[vn(p, 1)]])
  if (all(is.na(v) | (v >= 0 & v <= 28))) s <- s + 1
  if (all(is.na(v))) s <- s - 5
  s
}, numeric(1))
ftpl <- cands[which.max(score)]
cat(sprintf("NOTE: forecast template = '%s' (label: %s)\n", ftpl, labs[vn(ftpl, 1)]))

# forecast with no incentive
f0 <- NULL
if (vn(ftpl, 0) %in% names(df)) {
  f0 <- vn(ftpl, 0)
} else {
  pool <- names(df)[grepl("expect|forecast|predict|think|anticipat", labs, ignore.case = TRUE) &
                      !grepl("\\$|incentive|per.day|wtp|commit|percent|probab|risk|comprehension", labs, ignore.case = TRUE)]
  pool <- setdiff(pool, vn(ftpl, rates))
  if (length(pool) > 0) f0 <- pool[1]
  if (is.null(f0)) {
    pool2 <- grep("^(exp|forecast|pred)[a-z_]*$", names(df), value = TRUE, ignore.case = TRUE)
    if (length(pool2) > 0) f0 <- pool2[1]
  }
}
cat(sprintf("NOTE: no-incentive forecast variable = '%s'\n", ifelse(is.null(f0), "NONE", f0)))

# ---------- information treatment indicators ----------
toi <- num(df$type_of_info)
df$wave <- num(df$wave)
info_bin <- names(df)[grepl("info", names(df), ignore.case = TRUE) & names(df) != "type_of_info"]
if (length(info_bin) > 0) {
  info_bin <- info_bin[vapply(info_bin, function(n) {
    v <- num(df[[n]]); u <- unique(v[!is.na(v)]); length(u) == 2 && all(u %in% c(0, 1))
  }, logical(1))]
}
if (length(toi) > 0 && any(toi == 0, na.rm = TRUE)) {
  df$basic_info <- as.integer(!is.na(toi) & toi == 1)
  df$enh_info <- as.integer(!is.na(toi) & toi == 2)
} else if (length(toi) > 0 && !all(is.na(toi)) && any(is.na(toi))) {
  df$basic_info <- as.integer(!is.na(toi) & toi == 1)
  df$enh_info <- as.integer(!is.na(toi) & toi == 2)
} else if (length(info_bin) > 0) {
  iv <- num(df[[info_bin[1]]]); iv[is.na(iv)] <- 0
  cat(sprintf("NOTE: info indicator = '%s'\n", info_bin[1]))
  df$basic_info <- as.integer(iv == 1 & !is.na(df$wave) & df$wave == 1)
  df$enh_info <- as.integer(iv == 1 & !is.na(df$wave) & df$wave > 1)
} else {
  df$basic_info <- as.integer(!is.na(toi) & toi == 1)
  df$enh_info <- as.integer(!is.na(toi) & toi == 2)
}

# ---------- sample ----------
cat(sprintf("SAMPLE:bcp:loaded=%d\n", nrow(df)))
fx <- num(df$flag_exclude_exog); if (length(fx) == 0) fx <- rep(0, nrow(df)); fx[is.na(fx)] <- 0
s1 <- df[fx != 1, ]
cat(sprintf("SAMPLE:bcp:exclude_endogenous_assignment=%d\n", nrow(s1)))
w3 <- !is.na(s1$wave) & s1$wave == 3
tt <- s1$treat_txt; tt[is.na(tt)] <- ""
is_commit <- grepl("commit|contract|80|\\+", tt, ignore.case = TRUE)
if (!any(is_commit & w3)) {
  inc <- num(s1$incentive)
  is_commit <- w3 & (is.na(inc) | !(inc %in% c(0, 7)))
}
s2 <- s1[!(w3 & is_commit), ]
cat(sprintf("SAMPLE:bcp:exclude_wave3_commitment_assigned=%d\n", nrow(s2)))

# ---------- behavior change premium ----------
W <- sapply(rates, function(r) num(s2[[vn(wtpl, r)]]))
Fc <- sapply(rates, function(r) num(s2[[vn(ftpl, r)]]))
bcp_pairs <- sapply(1:5, function(k) {
  d <- rates[k + 1] - rates[k]
  (W[, k + 1] - W[, k]) / d - (Fc[, k + 1] + Fc[, k]) / 2
})
s2$bcp <- rowMeans(bcp_pairs, na.rm = FALSE)

s2$goal <- num(s2$goal)
s2$visits <- num(s2$visits)
s2$exp0 <- if (!is.null(f0)) num(s2[[f0]]) else NA_real_
inc <- num(s2$incentive)
s2$exp_assigned <- NA_real_
for (r in rates) {
  idx <- !is.na(inc) & inc == r
  s2$exp_assigned[idx] <- num(s2[[vn(ftpl, r)]])[idx]
}
idx0 <- !is.na(inc) & inc == 0
s2$exp_assigned[idx0] <- s2$exp0[idx0]
s2$goal_gap <- s2$goal - s2$exp0
s2$act_gap <- s2$visits - s2$exp_assigned

cat(sprintf("SAMPLE:bcp:nonmissing_bcp=%d\n", sum(!is.na(s2$bcp))))
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)

reg <- s2[!is.na(s2$bcp), ]
reg$goal_gap_z <- z(reg$goal_gap)
reg$act_gap_z <- z(reg$act_gap)

m1 <- feols(bcp ~ basic_info + enh_info | wave, data = reg, vcov = "hetero")
m2 <- feols(bcp ~ basic_info + enh_info + goal_gap_z | wave, data = reg, vcov = "hetero")
m3 <- feols(bcp ~ basic_info + enh_info + act_gap_z | wave, data = reg, vcov = "hetero")
cat(sprintf("SAMPLE:bcp:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:bcp_goal:estimation=%d\n", nobs(m2)))
cat(sprintf("SAMPLE:bcp_actual:estimation=%d\n", nobs(m3)))

# ---------- Table 4: take-up of "more" contracts ----------
more_cols <- intersect(paste0("chose_commit", c(8, 12, 16)), names(df))
cat(sprintf("NOTE: more-contract columns = %s\n", paste(more_cols, collapse = ",")))
reg$bcp_z <- z(reg$bcp)
long <- reg %>%
  dplyr::select(pid, wave, basic_info, enh_info, bcp_z, goal_gap_z, act_gap_z, all_of(more_cols)) %>%
  mutate(across(all_of(more_cols), num)) %>%
  pivot_longer(all_of(more_cols), names_to = "contract", values_to = "chose") %>%
  mutate(threshold = as.integer(sub("chose_commit", "", contract)))
cat(sprintf("SAMPLE:takeup:loaded=%d\n", nrow(long)))
long <- long %>% filter(!(!is.na(wave) & wave == 3 & threshold != 12))
cat(sprintf("SAMPLE:takeup:wave3_only_12_offered=%d\n", nrow(long)))
long <- long %>% filter(!is.na(chose))
cat(sprintf("SAMPLE:takeup:nonmissing_choice=%d\n", nrow(long)))
long$chose <- as.numeric(long$chose > 0)

t1 <- feols(chose ~ basic_info + enh_info | wave + threshold, data = long, cluster = ~pid)
t2 <- feols(chose ~ basic_info + enh_info + bcp_z | wave + threshold, data = long, cluster = ~pid)
t3 <- feols(chose ~ basic_info + enh_info + goal_gap_z | wave + threshold, data = long, cluster = ~pid)
t4 <- feols(chose ~ basic_info + enh_info + act_gap_z | wave + threshold, data = long, cluster = ~pid)
cat(sprintf("SAMPLE:takeup:estimation=%d\n", nobs(t1)))

if (nobs(m1) != 1126) cat(sprintf("DEVIATION: Table 3 N is %d vs 1126 in paper\n", nobs(m1)))
if (nobs(t1) != 2824) cat(sprintf("DEVIATION: Table 4 N is %d vs 2824 in paper\n", nobs(t1)))

se <- function(m, v) sqrt(diag(vcov(m)))[v]
out <- function(name, m, v) {
  cat(sprintf("RESULT:%s=%.6f\n", name, coef(m)[v]))
  cat(sprintf("RESULT:%s_se=%.6f\n", name, se(m, v)))
}
out("bcp_basic_info_treatment_col1", m1, "basic_info")
out("bcp_enhanced_info_treatment_col1", m1, "enh_info")
out("bcp_goal_minus_expected_attendance_col2", m2, "goal_gap_z")
out("bcp_actual_minus_expected_attendance_col3", m3, "act_gap_z")
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m1)))
cat(sprintf("RESULT:bcp_mean=%.6f\n", mean(reg$bcp)))
out("takeup_more_basic_info_treatment_col1", t1, "basic_info")
out("takeup_more_enhanced_info_treatment_col1", t1, "enh_info")
out("takeup_more_behavior_change_premium_col2", t2, "bcp_z")
out("takeup_more_goal_minus_expected_attendance_col3", t3, "goal_gap_z")
out("takeup_more_actual_minus_expected_attendance_col4", t4, "act_gap_z")
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(t1)))