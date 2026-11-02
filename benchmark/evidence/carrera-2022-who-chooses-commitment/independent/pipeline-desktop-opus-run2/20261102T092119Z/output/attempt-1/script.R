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

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) val <- NA
  cat(sprintf("RESULT:%s=%s\n", name, ifelse(is.na(val), "NA", format(signif(val, 6), scientific = FALSE))))
}

d$pid <- seq_len(nrow(d))
d$wave <- num(d$wave)

# ---------------- Sample restrictions ----------------
fl <- num(d$flag_exclude_exog)
fl[is.na(fl)] <- 0
cat("flag_exclude_exog table:\n"); print(table(fl, useNA = "ifany"))
if (sum(fl == 1) <= sum(fl == 0)) excl <- fl == 1 else excl <- fl == 0
cat("Excluded (endogenous incentive):", sum(excl), "\n")

inc <- num(d$incentive)
itext <- if ("incentivetext" %in% nm) tolower(as.character(d$incentivetext)) else rep("", nrow(d))
itext[is.na(itext)] <- ""
cat("Wave 3 incentive values:\n"); print(table(inc[d$wave == 3], useNA = "ifany"))
cat("Wave 3 incentive texts:\n"); print(head(sort(table(itext[d$wave == 3]), decreasing = TRUE), 20))

commit_assigned <- d$wave == 3 & (
  grepl("commit|at least|or more|\\$80|\\b80\\b", itext) |
  (!is.na(inc) & inc >= 80)
)
if (sum(commit_assigned & !excl, na.rm = TRUE) < 50) {
  cat("Fallback commitment detection via incentive values\n")
  commit_assigned <- d$wave == 3 & !(inc %in% c(0, 1, 2, 3, 5, 7, 12))
}
commit_assigned[is.na(commit_assigned)] <- FALSE
cat("Wave 3 commitment-assigned (non-excluded):", sum(commit_assigned & !excl), "\n")

s <- d[!excl & !commit_assigned, ]
cat("Analysis sample N:", nrow(s), "\n")

# ---------------- Information treatment ----------------
tr <- num(s$treatment)
ut <- sort(unique(tr[!is.na(tr)]))
cat("treatment values:", ut, "\n")
if (length(ut) == 2 && !all(ut %in% c(0, 1))) tr <- as.numeric(tr == max(ut))
if (length(ut) > 2 && "type_of_info" %in% names(s)) {
  ti <- num(s$type_of_info); tr <- as.numeric(!is.na(ti) & ti > 0)
}
s$info <- tr
s$basic_info <- as.numeric(s$info == 1 & s$wave == 1)
s$enhanced_info <- as.numeric(s$info == 1 & s$wave %in% c(2, 3))

# ---------------- Forecasts under piece rates ----------------
rates <- c(1, 2, 3, 5, 7, 12)
ends1 <- grep("^(.*[^0-9])1$", nm, value = TRUE)
prefixes <- unique(sub("1$", "", ends1))
bad <- "^(wtp|previsits|days_|sliderintro|percent|chose|q[0-9]|day)"
prefixes <- prefixes[!grepl(bad, prefixes)]
prefixes <- prefixes[sapply(prefixes, function(p) all(paste0(p, rates) %in% nm))]
cat("Candidate forecast prefixes:", prefixes, "\n")
score_prefix <- function(p) {
  v <- unlist(lapply(rates, function(r) num(d[[paste0(p, r)]])))
  v <- v[!is.na(v)]
  if (length(v) < 100) return(-Inf)
  inrange <- mean(v >= 0 & v <= 28)
  bonus <- ifelse(grepl("exp|fore|guess|visit|att|pred|est|belief", p, ignore.case = TRUE), 0.5, 0)
  inrange + bonus
}
fc_prefix <- NA
if (length(prefixes) > 0) {
  sc <- sapply(prefixes, score_prefix)
  print(sc)
  if (max(sc) > 0.8) fc_prefix <- prefixes[which.max(sc)]
}
cat("Using forecast prefix:", fc_prefix, "\n")

have_fc <- !is.na(fc_prefix)
for (r in rates) {
  s[[paste0("W", r)]] <- num(s[[paste0("wtp", r)]])
  s[[paste0("F", r)]] <- if (have_fc) num(s[[paste0(fc_prefix, r)]]) else NA_real_
}

# Behavior change premium (average over adjacent pairs)
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
s$exp0 <- num(s$visits_next4weeks)
s$goalv <- num(s$goal)
s$actual <- num(s$visits)
s$inc <- num(s$incentive)
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
cc <- grep("^chose_commit([0-9]+)$", nm, value = TRUE)
cat("Commit choice vars:", cc, "\n")
long <- do.call(rbind, lapply(cc, function(v) {
  data.frame(pid = s$pid, threshold = as.numeric(sub("chose_commit", "", v)),
             take = num(s[[v]]), stringsAsFactors = FALSE)
}))
# normalise coding to 0/1
uv <- sort(unique(long$take[!is.na(long$take)]))
cat("take-up raw values:", uv, "\n")
if (!all(uv %in% c(0, 1))) {
  a <- long$take == min(uv); b <- long$take == max(uv)
  ra <- tapply(a, long$threshold, mean, na.rm = TRUE)
  if (length(ra) > 1 && ra[1] < ra[length(ra)]) long$take <- as.numeric(b) else long$take <- as.numeric(a)
  long$take[is.na(a)] <- NA
}
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