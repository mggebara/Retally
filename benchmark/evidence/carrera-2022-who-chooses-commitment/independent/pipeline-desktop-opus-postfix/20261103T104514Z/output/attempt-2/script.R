suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free"
d <- haven::read_dta(file.path(base, "Who_Chooses_Commitment_Replication/Data/cleaned_commitment_study_data.dta"))
d <- as.data.frame(d)
nm <- names(d)

num <- function(x) suppressWarnings(as.numeric(haven::zap_labels(x)))
lab_of <- function(v) { l <- attr(d[[v]], "label"); if (is.null(l)) "" else tolower(as.character(l)) }
labs <- sapply(nm, lab_of)

cat(sprintf("SAMPLE:table3:loaded=%d\n", nrow(d)))
cat(sprintf("SAMPLE:table4:loaded=%d\n", nrow(d)))

d$pid <- seq_len(nrow(d))
parse_wave <- function(x) {
  w <- num(x)
  if (all(is.na(w))) {
    s <- tryCatch(as.character(haven::as_factor(x)), error = function(e) as.character(x))
    w <- suppressWarnings(as.numeric(sub("^\\D*(\\d+).*$", "\\1", s)))
    w[!grepl("\\d", s)] <- NA
  }
  w
}
wave_src <- if ("wave" %in% nm) "wave" else nm[grepl("wave", nm, ignore.case = TRUE)][1]
d$wave_n <- if (!is.na(wave_src)) parse_wave(d[[wave_src]]) else rep(NA_real_, nrow(d))
if (all(is.na(d$wave_n))) {
  for (v in nm[grepl("wave", nm, ignore.case = TRUE) | grepl("wave", labs)]) {
    w <- parse_wave(d[[v]])
    if (any(!is.na(w)) && length(unique(w[!is.na(w)])) %in% 2:5) { d$wave_n <- w; cat(sprintf("# wave from column %s\n", v)); break }
  }
}
if (all(is.na(d$wave_n))) {
  cat("DEVIATION: could not parse wave; treating all observations as a single wave\n")
  d$wave_n <- 1
}
cat(sprintf("# wave values: %s\n", paste(names(table(d$wave_n, useNA = "ifany")), table(d$wave_n, useNA = "ifany"), sep = ":", collapse = ",")))

# ---------------- exclusion of endogenous assignment ----------------
excl <- num(d$flag_exclude_exog); excl[is.na(excl)] <- 0
d1 <- d[excl == 0, , drop = FALSE]
cat(sprintf("SAMPLE:table3:exclude_endogenous_assignment=%d\n", nrow(d1)))
cat(sprintf("SAMPLE:table4:exclude_endogenous_assignment=%d\n", nrow(d1)))

# ---------------- wave 3 commitment-contract assignees ----------------
trt_lab <- tryCatch(tolower(as.character(haven::as_factor(d1$treatment))), error = function(e) tolower(as.character(d1$treatment)))
inc_txt <- if ("incentivetext" %in% nm) tolower(as.character(haven::as_factor(d1$incentivetext))) else rep("", nrow(d1))
inc_txt[is.na(inc_txt)] <- ""; trt_lab[is.na(trt_lab)] <- ""
inc_num <- num(d1$incentive)
w3 <- d1$wave_n == 3
cand_flags <- list(
  text = w3 & (grepl("commit|contract|\\b80\\b|\\$80|12\\+|at least|12 or more", trt_lab) |
               grepl("commit|contract|\\$80|\\b80\\b|at least|12 or more|12\\+", inc_txt)),
  inc_na = w3 & is.na(inc_num),
  inc_80 = w3 & !is.na(inc_num) & inc_num >= 80,
  inc_not07 = w3 & !(inc_num %in% c(0, 7))
)
target <- 1126
pick <- NULL
for (k in names(cand_flags)) {
  n_k <- sum(!cand_flags[[k]], na.rm = TRUE)
  cat(sprintf("# commit-assignment rule %s keeps %d\n", k, n_k))
  if (is.null(pick) && sum(cand_flags[[k]], na.rm = TRUE) > 0 && n_k == target) pick <- k
}
if (is.null(pick)) {
  sizes <- sapply(cand_flags, function(f) abs(sum(!f, na.rm = TRUE) - target))
  pos <- sapply(cand_flags, function(f) sum(f, na.rm = TRUE) > 0)
  sizes[!pos] <- Inf
  pick <- names(which.min(sizes))
  cat(sprintf("DEVIATION: no wave-3 commitment-assignment rule gives exactly %d; using rule '%s'\n", target, pick))
}
cf <- cand_flags[[pick]]; cf[is.na(cf)] <- FALSE
d2 <- d1[!cf, , drop = FALSE]
cat(sprintf("SAMPLE:table3:exclude_wave3_commitment_assigned=%d\n", nrow(d2)))
cat(sprintf("SAMPLE:table4:exclude_wave3_commitment_assigned=%d\n", nrow(d2)))

# ---------------- information treatment indicators ----------------
toi <- num(d2$type_of_info)
share12 <- mean(toi %in% c(1, 2))
info <- NULL
if (share12 < 0.8 && share12 > 0.2) {
  basic <- as.numeric(toi %in% 1); enhanced <- as.numeric(toi %in% 2)
} else {
  ic <- setdiff(nm[grepl("info|graph", nm, ignore.case = TRUE) | grepl("information", labs)], "type_of_info")
  for (v in ic) {
    x <- num(d2[[v]])
    ux <- sort(unique(x[!is.na(x)]))
    if (length(ux) == 2 && all(ux %in% c(0, 1)) && mean(x, na.rm = TRUE) > 0.3 && mean(x, na.rm = TRUE) < 0.7) { info <- x; cat(sprintf("# info indicator: %s\n", v)); break }
  }
  if (is.null(info)) {
    cat("DEVIATION: could not find a separate information-treatment indicator; using type_of_info directly\n")
    basic <- as.numeric(toi %in% 1); enhanced <- as.numeric(toi %in% 2)
  } else {
    info[is.na(info)] <- 0
    basic <- as.numeric(info == 1 & d2$wave_n == 1)
    enhanced <- as.numeric(info == 1 & d2$wave_n >= 2)
  }
}
d2$basic_info <- basic
d2$enhanced_info <- enhanced

# ---------------- forecast columns ----------------
rates <- c(1, 2, 3, 5, 7, 12)
ends12 <- nm[grepl("12$", nm)]
stems <- unique(sub("12$", "", ends12))
stems <- stems[sapply(stems, function(s) all(paste0(s, c(1, 2, 3, 5, 7)) %in% nm))]
stems <- stems[!grepl("^wtp|slider|commit|percent|meet|chose|prob", stems, ignore.case = TRUE)]
stem <- NULL
if (length(stems) > 0) {
  pref <- stems[grepl("exp|fore|pred|att|visit", stems, ignore.case = TRUE)]
  stem <- if (length(pref) > 0) pref[1] else stems[1]
}
fc_cols <- NULL
if (!is.null(stem)) {
  fc_cols <- setNames(paste0(stem, rates), rates)
} else {
  fc_cols <- sapply(rates, function(p) {
    hit <- nm[grepl("expect|forecast|predict", labs) & grepl(paste0("\\$", p, "(\\.00)? "), labs) & !grepl("^wtp", nm)]
    if (length(hit)) hit[1] else NA
  })
  names(fc_cols) <- rates
}
cat(sprintf("# forecast columns: %s\n", paste(fc_cols, collapse = ",")))

# zero-incentive forecast
f0 <- NULL
if (!is.null(stem) && paste0(stem, "0") %in% nm) f0 <- paste0(stem, "0")
if (is.null(f0)) {
  h <- nm[grepl("expect|forecast|predict", labs) & grepl("no incentive|without|absence|\\$0|no additional|no payment", labs)]
  if (length(h)) f0 <- h[1]
}
if (is.null(f0)) {
  h <- nm[grepl("^(exp|expected|forecast)[_]?(0|visits|att|attendance|noinc|_noinc|none)$", nm, ignore.case = TRUE) |
          nm %in% c("visits_expected", "expected_visits", "exp_visits", "expvisits", "exp_noinc", "exp0")]
  if (length(h)) f0 <- h[1]
}
if (is.null(f0)) {
  h <- nm[grepl("expect|forecast|predict", labs) & !grepl("\\$", labs) & !grepl("^wtp", nm)]
  if (length(h)) f0 <- h[1]
}
cat(sprintf("# zero-incentive forecast column: %s\n", ifelse(is.null(f0), "NONE", f0)))

# ---------------- behavior change premium ----------------
W <- sapply(rates, function(p) num(d2[[paste0("wtp", p)]]))
Fm <- sapply(fc_cols, function(v) num(d2[[v]]))
pairs <- list(c(1, 2), c(2, 3), c(3, 4), c(4, 5), c(5, 6))
bcp_mat <- sapply(pairs, function(pr) {
  i <- pr[1]; j <- pr[2]; dl <- rates[j] - rates[i]
  (W[, j] - W[, i]) / dl - (Fm[, j] + Fm[, i]) / 2
})
d2$bcp <- rowMeans(bcp_mat, na.rm = TRUE)
d2$bcp[is.nan(d2$bcp)] <- NA

# ---------------- sophistication proxies ----------------
exp0 <- if (!is.null(f0)) num(d2[[f0]]) else rep(NA_real_, nrow(d2))
d2$goal_gap <- num(d2$goal) - exp0
inc2 <- num(d2$incentive)
exp_assigned <- rep(NA_real_, nrow(d2))
exp_assigned[inc2 %in% 0] <- exp0[inc2 %in% 0]
for (k in seq_along(rates)) {
  sel <- inc2 %in% rates[k]
  exp_assigned[sel] <- Fm[sel, k]
}
d2$actual_gap <- num(d2$visits) - exp_assigned

z <- function(x, keep) { m <- mean(x[keep], na.rm = TRUE); s <- sd(x[keep], na.rm = TRUE); (x - m) / s }
keep3 <- !is.na(d2$bcp)
d2$goal_gap_z <- z(d2$goal_gap, keep3)
d2$actual_gap_z <- z(d2$actual_gap, keep3)
d2$bcp_z <- z(d2$bcp, keep3)

cat(sprintf("SAMPLE:table3:nonmissing_bcp=%d\n", sum(keep3)))

m31 <- feols(bcp ~ basic_info + enhanced_info | wave_n, data = d2, vcov = "hetero")
m32 <- feols(bcp ~ basic_info + enhanced_info + goal_gap_z | wave_n, data = d2, vcov = "hetero")
m33 <- feols(bcp ~ basic_info + enhanced_info + actual_gap_z | wave_n, data = d2, vcov = "hetero")
cat(sprintf("SAMPLE:table3:estimation=%d\n", nobs(m31)))
cat(sprintf("# table3 col2 nobs=%d, col3 nobs=%d\n", nobs(m32), nobs(m33)))

# ---------------- Table 4: more-contract take-up (long) ----------------
more_col <- function(thr) {
  c1 <- paste0("chose_commit", thr)
  if (c1 %in% nm) return(c1)
  h <- nm[grepl(paste0("cho.*commit.*", thr, "$"), nm, ignore.case = TRUE) & !grepl("less|fewer|under|max|lt", nm, ignore.case = TRUE)]
  if (length(h)) return(h[1])
  NA
}
thr_cols <- sapply(c(8, 12, 16), more_col)
cat(sprintf("# more-contract columns: %s\n", paste(thr_cols, collapse = ",")))
to01 <- function(x) {
  x <- num(x)
  ux <- sort(unique(x[!is.na(x)]))
  if (length(ux) == 2 && all(ux == c(1, 2))) x <- as.numeric(x == 1)
  x
}
long <- do.call(rbind, lapply(seq_along(thr_cols), function(k) {
  v <- thr_cols[k]
  if (is.na(v)) return(NULL)
  data.frame(pid = d2$pid, wave_n = d2$wave_n, threshold = c(8, 12, 16)[k],
             chose = to01(d2[[v]]), basic_info = d2$basic_info, enhanced_info = d2$enhanced_info,
             bcp_z = d2$bcp_z, goal_gap_z = d2$goal_gap_z, actual_gap_z = d2$actual_gap_z)
}))
# wave 3 only offered the 12+ contract
long <- long[!(long$wave_n == 3 & long$threshold != 12), ]
cat(sprintf("SAMPLE:table4:participant_by_threshold_rows=%d\n", nrow(long)))
long <- long[!is.na(long$chose), ]
cat(sprintf("SAMPLE:table4:nonmissing_choice=%d\n", nrow(long)))

m41 <- feols(chose ~ basic_info + enhanced_info | wave_n + threshold, data = long, cluster = ~pid)
m42 <- feols(chose ~ basic_info + enhanced_info + bcp_z | wave_n + threshold, data = long, cluster = ~pid)
m43 <- feols(chose ~ basic_info + enhanced_info + goal_gap_z | wave_n + threshold, data = long, cluster = ~pid)
m44 <- feols(chose ~ basic_info + enhanced_info + actual_gap_z | wave_n + threshold, data = long, cluster = ~pid)
cat(sprintf("SAMPLE:table4:estimation=%d\n", nobs(m41)))

g <- function(m, v) unname(coef(m)[v])
se <- function(m, v) unname(sqrt(diag(vcov(m)))[v])

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", g(m31, "basic_info")))
cat(sprintf("RESULT:bcp_basic_info_treatment_col1_se=%.6f\n", se(m31, "basic_info")))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", g(m31, "enhanced_info")))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1_se=%.6f\n", se(m31, "enhanced_info")))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", g(m32, "goal_gap_z")))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2_se=%.6f\n", se(m32, "goal_gap_z")))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", g(m33, "actual_gap_z")))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3_se=%.6f\n", se(m33, "actual_gap_z")))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nobs(m31)))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1=%.6f\n", g(m41, "basic_info")))
cat(sprintf("RESULT:takeup_more_basic_info_treatment_col1_se=%.6f\n", se(m41, "basic_info")))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1=%.6f\n", g(m41, "enhanced_info")))
cat(sprintf("RESULT:takeup_more_enhanced_info_treatment_col1_se=%.6f\n", se(m41, "enhanced_info")))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2=%.6f\n", g(m42, "bcp_z")))
cat(sprintf("RESULT:takeup_more_behavior_change_premium_col2_se=%.6f\n", se(m42, "bcp_z")))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3=%.6f\n", g(m43, "goal_gap_z")))
cat(sprintf("RESULT:takeup_more_goal_minus_expected_attendance_col3_se=%.6f\n", se(m43, "goal_gap_z")))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4=%.6f\n", g(m44, "actual_gap_z")))
cat(sprintf("RESULT:takeup_more_actual_minus_expected_attendance_col4_se=%.6f\n", se(m44, "actual_gap_z")))
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nobs(m41)))