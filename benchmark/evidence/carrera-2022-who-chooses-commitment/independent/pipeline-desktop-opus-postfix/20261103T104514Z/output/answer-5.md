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
toi_raw <- d2$type_of_info
toi <- num(toi_raw)
toi_chr <- tryCatch(as.character(haven::as_factor(toi_raw)), error = function(e) as.character(toi_raw))
toi_chr <- tolower(trimws(toi_chr))
toi_chr[toi_chr %in% c("", "na", ".", "n/a")] <- NA
toi_labs <- attr(d2$type_of_info, "labels")
cat(sprintf("# type_of_info class: %s\n", paste(class(toi_raw), collapse = "/")))
cat(sprintf("# type_of_info (text) by wave: %s\n",
            paste(apply(as.data.frame(table(toi_chr, d2$wave_n, useNA = "ifany")), 1, function(r) paste(r, collapse = "/")), collapse = ",")))
if (!is.null(toi_labs)) cat(sprintf("# type_of_info labels: %s\n", paste(names(toi_labs), toi_labs, sep = "=", collapse = "; ")))

basic <- NULL; enhanced <- NULL
ctrl_re <- "^no$|^no |none|control|no info|without|^0$"
basic_re <- "basic|simple|standard|generic"
enh_re <- "enhanc|graph|detail|extend|full|personal|advanced|tailor|custom"

if (!is.null(toi_labs) && length(toi_labs) > 0 && any(!is.na(toi))) {
  ln <- tolower(names(toi_labs))
  b_code <- unname(toi_labs[grepl(basic_re, ln) & !grepl(ctrl_re, ln)])
  e_code <- unname(toi_labs[grepl(enh_re, ln) & !grepl(ctrl_re, ln)])
  if (length(b_code) > 0 && length(e_code) > 0) {
    basic <- as.numeric(toi %in% b_code)
    enhanced <- as.numeric(toi %in% e_code)
    cat(sprintf("# info codes from labels: basic=%s enhanced=%s\n", paste(b_code, collapse = "|"), paste(e_code, collapse = "|")))
  }
}
if (is.null(basic) && any(!is.na(toi_chr))) {
  tc <- ifelse(is.na(toi_chr), "", toi_chr)
  is_ctrl <- grepl(ctrl_re, tc)
  is_b <- grepl(basic_re, tc) & !is_ctrl
  is_e <- grepl(enh_re, tc) & !is_ctrl & !is_b
  if (sum(is_b) > 0 && sum(is_e) > 0) {
    basic <- as.numeric(is_b); enhanced <- as.numeric(is_e)
    cat(sprintf("# info from text: basic=[%s] enhanced=[%s] control/other=[%s]\n",
                paste(unique(tc[is_b]), collapse = "|"), paste(unique(tc[is_e]), collapse = "|"),
                paste(unique(tc[!is_b & !is_e]), collapse = "|")))
  } else if (all(is.na(toi))) {
    tn <- suppressWarnings(as.numeric(sub("^\\D*(\\d+).*$", "\\1", tc)))
    tn[!grepl("\\d", tc)] <- NA
    if (length(unique(tn[!is.na(tn)])) >= 2) {
      toi <- tn
      cat("# type_of_info: numeric codes parsed from text\n")
    } else {
      ux <- sort(unique(tc[tc != "" & !is_ctrl]))
      if (length(ux) >= 2) {
        basic <- as.numeric(tc == ux[1]); enhanced <- as.numeric(tc %in% ux[-1])
        cat(sprintf("DEVIATION: info text values not recognised; basic='%s', enhanced='%s'\n", ux[1], paste(ux[-1], collapse = "|")))
      } else if (length(ux) == 1) {
        info <- as.numeric(tc == ux[1])
        basic <- as.numeric(info == 1 & d2$wave_n == 1)
        enhanced <- as.numeric(info == 1 & d2$wave_n >= 2)
        cat(sprintf("DEVIATION: single info text value '%s'; basic in wave 1, enhanced in waves 2+\n", ux[1]))
      }
    }
  }
}
if (is.null(basic) && any(!is.na(toi))) {
  ux <- sort(unique(toi[!is.na(toi)]))
  if (length(ux) >= 3) {
    basic <- as.numeric(toi %in% ux[2])
    enhanced <- as.numeric(toi %in% ux[length(ux)])
    cat(sprintf("# info codes by order: control=%s basic=%s enhanced=%s\n", ux[1], ux[2], ux[length(ux)]))
  } else if (length(ux) == 2) {
    info <- as.numeric(toi %in% ux[2])
    basic <- as.numeric(info == 1 & d2$wave_n == 1)
    enhanced <- as.numeric(info == 1 & d2$wave_n >= 2)
    cat(sprintf("DEVIATION: type_of_info has two codes (%s); info=code %s, basic in wave 1, enhanced in waves 2+\n", paste(ux, collapse = ","), ux[2]))
  }
}
if (is.null(basic)) {
  bc <- nm[(grepl("basic", nm, ignore.case = TRUE) | grepl("basic", labs)) & (grepl("info", nm, ignore.case = TRUE) | grepl("info", labs))]
  ec <- nm[(grepl("enhanc", nm, ignore.case = TRUE) | grepl("enhanc", labs)) & (grepl("info", nm, ignore.case = TRUE) | grepl("info", labs))]
  bc <- bc[sapply(bc, function(v) length(unique(na.omit(num(d2[[v]])))) == 2)]
  ec <- ec[sapply(ec, function(v) length(unique(na.omit(num(d2[[v]])))) == 2)]
  if (length(bc) && length(ec)) {
    bb <- num(d2[[bc[1]]]); ee <- num(d2[[ec[1]]])
    basic <- as.numeric(bb == max(bb, na.rm = TRUE)); enhanced <- as.numeric(ee == max(ee, na.rm = TRUE))
    cat(sprintf("# info indicators from columns %s / %s\n", bc[1], ec[1]))
  }
}
if (is.null(basic)) {
  cat("DEVIATION: type_of_info has no usable variation; info indicators set to 0\n")
  basic <- rep(0, nrow(d2)); enhanced <- rep(0, nrow(d2))
}
basic[is.na(basic)] <- 0; enhanced[is.na(enhanced)] <- 0
d2$basic_info <- basic
d2$enhanced_info <- enhanced
cat(sprintf("# basic_info=%d enhanced_info=%d of %d\n", sum(basic), sum(enhanced), length(basic)))

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

fit <- function(fml, data, ...) {
  tryCatch(feols(fml, data = data, ...), error = function(e) {
    cat(sprintf("DEVIATION: model %s failed: %s\n", deparse(fml), gsub("\n", " ", conditionMessage(e))))
    NULL
  })
}
nob <- function(m) if (is.null(m)) NA_integer_ else as.integer(nobs(m))

m31 <- fit(bcp ~ basic_info + enhanced_info | wave_n, d2, vcov = "hetero")
m32 <- fit(bcp ~ basic_info + enhanced_info + goal_gap_z | wave_n, d2, vcov = "hetero")
m33 <- fit(bcp ~ basic_info + enhanced_info + actual_gap_z | wave_n, d2, vcov = "hetero")
cat(sprintf("SAMPLE:table3:estimation=%d\n", nob(m31)))
cat(sprintf("# table3 col2 nobs=%d, col3 nobs=%d\n", nob(m32), nob(m33)))

# ---------------- Table 4: more-contract take-up (long) ----------------
# Diagnostics: list every commitment/contract-related column so the 8+ and 16+
# choice variables (absent under the name chose_commit8/16) can be located.
commit_like <- nm[grepl("commit|contract|chose|choice|more|atleast|least", nm, ignore.case = TRUE) |
                  grepl("commit|contract|at least|or more|\\$80|80 dollars", labs)]
cat(sprintf("# commitment-related columns: %s\n",
            paste(sprintf("%s[%s]", commit_like, substr(labs[commit_like], 1, 60)), collapse = " ; ")))

is_binaryish <- function(v) {
  x <- num(d2[[v]]); ux <- unique(x[!is.na(x)])
  length(ux) >= 1 && length(ux) <= 2 && all(ux %in% c(0, 1, 2))
}
less_re <- "less|fewer|under|max|lt|atmost|at_most|most|below"
more_col <- function(thr) {
  c1 <- paste0("chose_commit", thr)
  if (c1 %in% nm) return(c1)
  tpat <- paste0("(^|[^0-9])0?", thr, "([^0-9]|$)")
  # (1) name-based: commitment / choice name containing the threshold number
  h <- nm[grepl(tpat, nm) & grepl("commit|contract|chose|choice|more|atleast|least|take", nm, ignore.case = TRUE) &
          !grepl(less_re, nm, ignore.case = TRUE) &
          !grepl("prob|percent|meet|belief|wtp|slider|days|exp|fore", nm, ignore.case = TRUE)]
  h <- h[sapply(h, is_binaryish)]
  if (length(h)) { cat(sprintf("# %d+ contract column (name match): %s\n", thr, h[1])); return(h[1]) }
  # (2) label-based: label mentions the threshold and an at-least / commitment contract
  h <- nm[grepl(tpat, labs) & grepl("commit|contract|at least|or more|\\$80|choose|chose|choice", labs) &
          !grepl("less|fewer|at most|or fewer|no more", labs) &
          !grepl("prob|percent|belief|likel|wtp", labs)]
  h <- h[sapply(h, is_binaryish)]
  if (length(h)) { cat(sprintf("# %d+ contract column (label match): %s\n", thr, h[1])); return(h[1]) }
  # (3) sibling of the 12 column: same name with 12 replaced by thr
  if ("chose_commit12" %in% nm) {
    alt <- nm[grepl("^chose_?commit", nm, ignore.case = TRUE) & grepl(tpat, nm) & !grepl(less_re, nm, ignore.case = TRUE)]
    if (length(alt)) return(alt[1])
  }
  NA
}
thr_cols <- sapply(c(8, 12, 16), more_col)
cat(sprintf("# more-contract columns: %s\n", paste(thr_cols, collapse = ",")))
if (any(is.na(thr_cols))) cat("DEVIATION: could not locate all more-contract choice columns; missing thresholds dropped from Table 4\n")
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
cat(sprintf("# table4 rows by threshold: %s\n", paste(names(table(long$threshold)), table(long$threshold), sep = ":", collapse = ",")))

m41 <- fit(chose ~ basic_info + enhanced_info | wave_n + threshold, long, cluster = ~pid)
m42 <- fit(chose ~ basic_info + enhanced_info + bcp_z | wave_n + threshold, long, cluster = ~pid)
m43 <- fit(chose ~ basic_info + enhanced_info + goal_gap_z | wave_n + threshold, long, cluster = ~pid)
m44 <- fit(chose ~ basic_info + enhanced_info + actual_gap_z | wave_n + threshold, long, cluster = ~pid)
cat(sprintf("SAMPLE:table4:estimation=%d\n", nob(m41)))

g <- function(m, v) { if (is.null(m)) return(NA_real_); cf <- coef(m); if (v %in% names(cf)) unname(cf[v]) else NA_real_ }
se <- function(m, v) { if (is.null(m)) return(NA_real_); s <- sqrt(diag(vcov(m))); if (v %in% names(s)) unname(s[v]) else NA_real_ }

cat(sprintf("RESULT:bcp_basic_info_treatment_col1=%.6f\n", g(m31, "basic_info")))
cat(sprintf("RESULT:bcp_basic_info_treatment_col1_se=%.6f\n", se(m31, "basic_info")))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1=%.6f\n", g(m31, "enhanced_info")))
cat(sprintf("RESULT:bcp_enhanced_info_treatment_col1_se=%.6f\n", se(m31, "enhanced_info")))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2=%.6f\n", g(m32, "goal_gap_z")))
cat(sprintf("RESULT:bcp_goal_minus_expected_attendance_col2_se=%.6f\n", se(m32, "goal_gap_z")))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3=%.6f\n", g(m33, "actual_gap_z")))
cat(sprintf("RESULT:bcp_actual_minus_expected_attendance_col3_se=%.6f\n", se(m33, "actual_gap_z")))
cat(sprintf("RESULT:bcp_regression_observations=%d\n", nob(m31)))
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
cat(sprintf("RESULT:takeup_more_regression_observations=%d\n", nob(m41)))
