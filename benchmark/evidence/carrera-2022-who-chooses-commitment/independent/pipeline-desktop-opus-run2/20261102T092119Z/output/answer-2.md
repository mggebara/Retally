suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
f <- file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta")
raw <- haven::read_dta(f)
d <- as.data.frame(haven::zap_labels(raw))
nm <- names(d)
cat("N rows:", nrow(d), "\n")
cat("Columns (", length(nm), "):\n")
for (v in nm) {
  x <- d[[v]]
  ex <- paste(head(unique(as.character(x[!is.na(x)])), 4), collapse = " | ")
  cat(sprintf("  %s [%s] nonNA=%d : %s\n", v, class(x)[1], sum(!is.na(x)), substr(ex, 1, 80)))
}

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(val), "NA", format(signif(val, 6), scientific = FALSE))))
}
tokre <- function(r) paste0("(^|[^0-9])", r, "([^0-9]|$)")

d$pid <- seq_len(nrow(d))

# ---------------- Wave ----------------
wave_raw <- d$wave
cat("Raw wave table:\n"); print(table(wave_raw, useNA = "ifany"))
parse_wave <- function(x) {
  xc <- as.character(x)
  v <- num(xc)
  if (mean(!is.na(v[!is.na(xc)])) > 0.9 && all(v[!is.na(v)] %in% 1:3)) return(v)
  dg <- num(gsub("[^0-9]", "", xc))
  if (sum(!is.na(dg)) > 0.9 * sum(!is.na(xc)) && all(dg[!is.na(dg)] %in% 1:3)) return(dg)
  # fallback: map by group size (wave1=350 smallest, wave2=528 largest, wave3=414 middle)
  tb <- sort(table(xc))
  out <- rep(NA_real_, length(xc))
  if (length(tb) == 3) {
    out[xc == names(tb)[1]] <- 1; out[xc == names(tb)[3]] <- 2; out[xc == names(tb)[2]] <- 3
    cat("DEVIATION: wave coded by group size (smallest=1, largest=2, middle=3) because wave values are not numeric\n")
  } else {
    out <- as.numeric(factor(xc))
  }
  out
}
d$wave <- parse_wave(wave_raw)
cat("Parsed wave:\n"); print(table(d$wave, useNA = "ifany"))

# ---------------- Sample restrictions ----------------
fl <- num(d$flag_exclude_exog); fl[is.na(fl)] <- 0
cat("flag_exclude_exog table:\n"); print(table(fl, useNA = "ifany"))
excl <- fl == 1
flagc <- nm[grepl("exclu|drop|endog", nm, ignore.case = TRUE)]
cat("Exclusion-type columns:", flagc, "\n")
uni <- excl
for (v in flagc) {
  x <- num(d[[v]])
  if (sum(!is.na(x)) == 0) next
  ux <- unique(x[!is.na(x)])
  if (all(ux %in% c(0, 1)) && sum(x == 1, na.rm = TRUE) < 100) {
    cat("  ", v, "ones:", sum(x == 1, na.rm = TRUE), "\n")
    uni <- uni | (!is.na(x) & x == 1)
  }
}
if (sum(uni) > sum(excl) && sum(uni) <= 50) excl <- uni
cat("Excluded (endogenous incentive):", sum(excl), "\n")

# ---------------- Incentive / commitment assignment ----------------
inc_raw <- d$incentive
cat("Raw incentive table (wave 3):\n"); print(table(inc_raw[d$wave == 3], useNA = "ifany"))
inc <- num(inc_raw)
itext <- tolower(as.character(inc_raw)); itext[is.na(itext)] <- ""
if ("incentivetext" %in% nm) {
  it2 <- tolower(as.character(d$incentivetext)); it2[is.na(it2)] <- ""
  itext <- paste(itext, it2)
}
if (all(is.na(inc))) {
  inc <- num(sub("^[^0-9]*([0-9]+\\.?[0-9]*).*$", "\\1", itext))
  inc[!grepl("[0-9]", itext)] <- 0
}
commit_assigned <- d$wave == 3 & (
  grepl("commit|at least|or more|12\\+|\\$80|\\b80\\b|contract", itext) |
    (!is.na(inc) & inc >= 80)
)
commit_assigned[is.na(commit_assigned)] <- FALSE
if (sum(commit_assigned & !excl) < 50) {
  cat("Fallback commitment detection via incentive values\n")
  commit_assigned <- d$wave == 3 & !is.na(inc) & !(inc %in% c(0, 1, 2, 3, 5, 7, 12))
  commit_assigned[is.na(commit_assigned)] <- FALSE
}
cat("Wave 3 commitment-assigned (non-excluded):", sum(commit_assigned & !excl), "\n")
d$inc_num <- inc

s <- d[!excl & !commit_assigned, ]
cat("Analysis sample N:", nrow(s), "\n")

# ---------------- Information treatment ----------------
to_binary <- function(x) {
  v <- num(x)
  if (sum(!is.na(v)) > 0.5 * sum(!is.na(x))) {
    u <- sort(unique(v[!is.na(v)]))
    if (length(u) == 2) return(as.numeric(v == max(u)))
    if (length(u) > 2) return(as.numeric(v > min(u)))
    return(v)
  }
  xc <- tolower(trimws(as.character(x)))
  xc[xc == ""] <- NA
  u <- unique(xc[!is.na(xc)])
  ctrl <- grepl("control|^no|none|false|untreat", u)
  out <- rep(NA_real_, length(xc))
  if (any(ctrl) && !all(ctrl)) {
    out[!is.na(xc)] <- as.numeric(!(xc[!is.na(xc)] %in% u[ctrl]))
  } else {
    out[!is.na(xc)] <- as.numeric(xc[!is.na(xc)] != sort(u)[1])
  }
  out
}
cat("Raw treatment table:\n"); print(table(s$treatment, useNA = "ifany"))
s$info <- to_binary(s$treatment)
if (all(is.na(s$info)) && "type_of_info" %in% names(s)) s$info <- to_binary(s$type_of_info)
print(table(s$info, s$wave, useNA = "ifany"))
s$basic_info <- as.numeric(s$info == 1 & s$wave == 1)
s$enhanced_info <- as.numeric(s$info == 1 & s$wave %in% c(2, 3))

# ---------------- Forecasts under piece rates ----------------
rates <- c(1, 2, 3, 5, 7, 12)
s$exp0 <- num(s$visits_next4weeks)
excl_fam <- "wtp|percent|prob|chose|commit|days|previsit|week|slider|order|rank|position|seq|pct|date|time|incent"
numcols <- nm[sapply(nm, function(v) sum(!is.na(num(d[[v]]))) >= 100)]
fams <- list()
for (v in numcols) {
  for (r in c(rates, 4, 6)) {
    re <- tokre(r)
    if (grepl(re, v)) {
      key <- sub(re, "\\1#\\2", v)
      fams[[key]] <- unique(c(fams[[key]], r))
    }
  }
}
fc_key <- NA; best <- -Inf
for (key in names(fams)) {
  if (grepl(excl_fam, key, ignore.case = TRUE)) next
  if (!all(rates %in% fams[[key]])) next
  if (any(c(4, 6) %in% fams[[key]])) next
  cols <- sapply(rates, function(r) sub("#", r, key, fixed = TRUE))
  vals <- sapply(cols, function(cn) num(d[[cn]]))
  v <- as.vector(vals); v <- v[!is.na(v)]
  if (length(v) < 100) next
  inr <- mean(v >= 0 & v <= 28)
  mu <- colMeans(vals, na.rm = TRUE)
  incr <- mean(diff(mu) >= -0.2)
  cr <- suppressWarnings(cor(vals[, 1], num(d$visits_next4weeks), use = "complete.obs"))
  if (is.na(cr)) cr <- 0
  bonus <- ifelse(grepl("exp|fore|guess|visit|att|pred|est|belief|fc", key, ignore.case = TRUE), 0.5, 0)
  sc <- inr + incr + max(cr, 0) + bonus + ifelse(mean(v) > 2 & mean(v) < 26, 0.5, -2)
  cat(sprintf("  forecast family %s score %.3f (inrange %.2f, incr %.2f, cor %.2f)\n", key, sc, inr, incr, cr))
  if (sc > best) { best <- sc; fc_key <- key }
}
cat("Using forecast family:", fc_key, "\n")

for (r in rates) {
  s[[paste0("W", r)]] <- num(s[[paste0("wtp", r)]])
  s[[paste0("F", r)]] <- if (!is.na(fc_key)) num(s[[sub("#", r, fc_key, fixed = TRUE)]]) else NA_real_
}

pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
bmat <- sapply(pairs, function(pr) {
  lo <- pr[1]; hi <- pr[2]
  (s[[paste0("W", hi)]] - s[[paste0("W", lo)]]) / (hi - lo) -
    (s[[paste0("F", hi)]] + s[[paste0("F", lo)]]) / 2
})
s$bcp <- rowMeans(bmat, na.rm = TRUE)
s$bcp[is.nan(s$bcp)] <- NA
cat("Mean BCP:", mean(s$bcp, na.rm = TRUE), " non-missing:", sum(!is.na(s$bcp)), "\n")

# Expected attendance without incentive, goal, actual
s$goalv <- num(s$goal)
s$actual <- num(s$visits)
s$inc <- s$inc_num
s$exp_assigned <- s$exp0
for (r in rates) {
  idx <- !is.na(s$inc) & s$inc == r
  s$exp_assigned[idx] <- s[[paste0("F", r)]][idx]
}
s$goal_gap <- s$goalv - s$exp0
s$act_gap <- s$actual - s$exp_assigned

z <- function(x, keep) { m <- mean(x[keep], na.rm = TRUE); sdv <- sd(x[keep], na.rm = TRUE); (x - m) / sdv }

# ---------------- Table 3 ----------------
t3keep <- !is.na(s$bcp) & !is.na(s$basic_info) & !is.na(s$wave)
cat("t3keep:", sum(t3keep), "\n")
s$goal_gap_z <- z(s$goal_gap, t3keep & !is.na(s$goal_gap))
s$act_gap_z <- z(s$act_gap, t3keep & !is.na(s$act_gap))

c1 <- c2 <- c3 <- NULL
try({
  m1 <- feols(bcp ~ basic_info + enhanced_info | wave, data = s[t3keep, ], vcov = "hetero")
  print(summary(m1)); c1 <- coef(m1); n3 <- nobs(m1)
}, silent = FALSE)
try({
  m2 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave, data = s[t3keep, ], vcov = "hetero")
  print(summary(m2)); c2 <- coef(m2)
}, silent = FALSE)
try({
  m3 <- feols(bcp ~ basic_info + enhanced_info + act_gap_z | wave, data = s[t3keep, ], vcov = "hetero")
  print(summary(m3)); c3 <- coef(m3)
}, silent = FALSE)

# ---------------- Table 4 ----------------
less_words <- "less|fewer|under|below|most|prob|belief|pct|percent|wtp|lt|le_"
ccands <- c()
for (v in nm) {
  x <- num(d[[v]])
  if (sum(!is.na(x)) < 100) next
  if (!all(unique(x[!is.na(x)]) %in% c(0, 1))) next
  if (grepl(less_words, v, ignore.case = TRUE)) next
  if (!grepl("commit|contract|chose|choice|take|more|ge", v, ignore.case = TRUE)) next
  thr <- NA
  for (t in c(8, 12, 16)) if (grepl(tokre(t), v)) thr <- t
  if (is.na(thr)) next
  if (any(sapply(c(7, 11, 15), function(t) grepl(tokre(t), v)))) next
  ccands <- c(ccands, v)
  cat(sprintf("  commit cand %s thr=%d nonNA=%d mean=%.3f\n", v, thr, sum(!is.na(x)), mean(x, na.rm = TRUE)))
}
cc <- grep("^chose_commit([0-9]+)$", nm, value = TRUE)
thr_of <- function(v) { th <- NA; for (t in c(8, 12, 16)) if (grepl(tokre(t), v)) th <- t; th }
# choose, for each threshold, the candidate family that best covers the sample
sel <- list()
for (t in c(8, 12, 16)) {
  cv <- ccands[sapply(ccands, thr_of) == t]
  if (length(cv) == 0) next
  prefer <- cv[grepl("chose|commit", cv, ignore.case = TRUE)]
  if (length(prefer) > 0) cv <- prefer
  nn <- sapply(cv, function(v) sum(!is.na(num(d[[v]]))))
  sel[[as.character(t)]] <- cv[which.max(nn)]
}
cat("Selected commit vars:", unlist(sel), "\n")
if (length(sel) == 0) sel <- setNames(as.list(cc), sub("chose_commit", "", cc))
long <- do.call(rbind, lapply(names(sel), function(t) {
  data.frame(pid = s$pid, threshold = as.numeric(t),
             take = num(s[[sel[[t]]]]), stringsAsFactors = FALSE)
}))
long <- long[!is.na(long$take), ]
print(tapply(long$take, long$threshold, mean))

s$bcp_z <- z(s$bcp, t3keep)
L <- merge(long, s[t3keep, c("pid", "wave", "basic_info", "enhanced_info", "bcp_z", "goal_gap_z", "act_gap_z")], by = "pid")
cat("Table 4 N:", nrow(L), "\n")

k1 <- k2 <- k3 <- k4 <- NULL; n4 <- NA
try({
  t1 <- feols(take ~ basic_info + enhanced_info | wave + threshold, data = L, cluster = ~pid)
  print(summary(t1)); k1 <- coef(t1); n4 <- nobs(t1)
}, silent = FALSE)
try({
  t2 <- feols(take ~ basic_info + enhanced_info + bcp_z | wave + threshold, data = L, cluster = ~pid)
  print(summary(t2)); k2 <- coef(t2)
}, silent = FALSE)
try({
  t3 <- feols(take ~ basic_info + enhanced_info + goal_gap_z | wave + threshold, data = L, cluster = ~pid)
  print(summary(t3)); k3 <- coef(t3)
}, silent = FALSE)
try({
  t4 <- feols(take ~ basic_info + enhanced_info + act_gap_z | wave + threshold, data = L, cluster = ~pid)
  print(summary(t4)); k4 <- coef(t4)
}, silent = FALSE)

g <- function(cf, n) if (!is.null(cf) && n %in% names(cf)) unname(cf[n]) else NA
emit("bcp_basic_info_treatment_col1", g(c1, "basic_info"))
emit("bcp_enhanced_info_treatment_col1", g(c1, "enhanced_info"))
emit("bcp_goal_minus_expected_attendance_col2", g(c2, "goal_gap_z"))
emit("bcp_actual_minus_expected_attendance_col3", g(c3, "act_gap_z"))
emit("bcp_regression_observations", if (exists("n3")) n3 else sum(t3keep))
emit("takeup_more_basic_info_treatment_col1", g(k1, "basic_info"))
emit("takeup_more_enhanced_info_treatment_col1", g(k1, "enhanced_info"))
emit("takeup_more_behavior_change_premium_col2", g(k2, "bcp_z"))
emit("takeup_more_goal_minus_expected_attendance_col3", g(k3, "goal_gap_z"))
emit("takeup_more_actual_minus_expected_attendance_col4", g(k4, "act_gap_z"))
emit("takeup_more_regression_observations", n4)
