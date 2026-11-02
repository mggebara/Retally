suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(dplyr)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free/Who_Chooses_Commitment_Replication/Data"
d <- read_dta(file.path(base, "cleaned_commitment_study_data.dta"))
nm <- names(d)
cat("N raw:", nrow(d), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

num <- function(x) suppressWarnings(as.numeric(zap_labels(x)))
labtxt <- function(x) {
  if (is.labelled(x)) as.character(as_factor(x, levels = "both")) else as.character(x)
}
first_int <- function(s) {
  s <- as.character(s)
  out <- rep(NA_real_, length(s))
  ok <- !is.na(s) & grepl("[0-9]+", s)
  out[ok] <- as.numeric(regmatches(s[ok], regexpr("[0-9]+", s[ok])))
  out
}

ps <- c(1, 2, 3, 5, 7, 12)

# ---------------- discover per-incentive variable templates ----------------
tmpl <- list()
for (n in nm) {
  m <- gregexpr("(?<![0-9])(12|1|2|3|5|7)(?![0-9])", n, perl = TRUE)[[1]]
  if (m[1] == -1) next
  for (k in seq_along(m)) {
    st <- m[k]; ln <- attr(m, "match.length")[k]
    val <- substr(n, st, st + ln - 1)
    t <- paste0(substr(n, 1, st - 1), "#", substr(n, st + ln, nchar(n)))
    cur <- tmpl[[t]]
    if (is.null(cur)) cur <- character(0)
    if (!(val %in% names(cur))) cur <- c(cur, setNames(n, val))
    tmpl[[t]] <- cur
  }
}
full <- Filter(function(v) all(as.character(ps) %in% names(v)), tmpl)
cat("Full templates:", paste(names(full), collapse = " | "), "\n")

# WTP
if (all(paste0("wtp", ps) %in% nm)) {
  wtp_vars <- paste0("wtp", ps)
} else {
  wt <- names(full)[grepl("wtp", names(full), ignore.case = TRUE) & !grepl("slider|intro", names(full), ignore.case = TRUE)]
  wtp_vars <- unname(full[[wt[1]]][as.character(ps)])
}
cat("WTP vars:", paste(wtp_vars, collapse = ","), "\n")

# Forecast variables
cand <- names(full)[!grepl("wtp|previsit|slider|commit|percent|prob|sure|meet|intro|flag|prefer", names(full), ignore.case = TRUE)]
best <- NA; best_score <- -Inf
for (t in cand) {
  vs <- unname(full[[t]][as.character(ps)])
  M <- sapply(vs, function(v) num(d[[v]]))
  if (!is.matrix(M)) next
  nonmiss <- mean(!is.na(M))
  vals <- M[!is.na(M)]
  if (length(vals) == 0) next
  fin <- mean(vals >= 0 & vals <= 28)
  mu <- colMeans(M, na.rm = TRUE)
  incr <- as.numeric(mu[6] > mu[1])
  sc <- fin * 2 + nonmiss + incr + as.numeric(grepl("visit|forecast|exp|guess|pred", t, ignore.case = TRUE)) * 0.5
  cat(sprintf("Template %s score %.3f means %s\n", t, sc, paste(round(mu, 2), collapse = ",")))
  if (sc > best_score) { best_score <- sc; best <- t }
}
fc_vars <- unname(full[[best]][as.character(ps)])
cat("Forecast vars:", paste(fc_vars, collapse = ","), "\n")

W <- sapply(wtp_vars, function(v) num(d[[v]]))
A <- sapply(fc_vars, function(v) num(d[[v]]))
colnames(W) <- colnames(A) <- as.character(ps)

# ---------------- behavior change premium ----------------
pairs <- list(c(1, 2), c(2, 3), c(3, 5), c(5, 7), c(7, 12))
B <- sapply(pairs, function(pr) {
  a <- as.character(pr[1]); b <- as.character(pr[2])
  (W[, b] - W[, a]) / (pr[2] - pr[1]) - (A[, b] + A[, a]) / 2
})
d$bcp <- rowMeans(B, na.rm = TRUE)
d$bcp[is.nan(d$bcp)] <- NA

# ---------------- expected attendance w/o incentive ----------------
if ("visits_next4weeks" %in% nm) {
  exp0 <- num(d$visits_next4weeks)
} else {
  ev <- nm[grepl("expect|bestguess|best_guess|guess", nm, ignore.case = TRUE)][1]
  exp0 <- num(d[[ev]])
}
d$exp0 <- exp0
d$goal_n <- num(d$goal)
d$visits_n <- num(d$visits)

# ---------------- wave (robust: 'wave' may be a string) ----------------
wave_n <- if ("wavenum" %in% nm) num(d$wavenum) else rep(NA_real_, nrow(d))
if (all(is.na(wave_n))) wave_n <- num(d$wave)
if (all(is.na(wave_n))) wave_n <- first_int(labtxt(d$wave))
if (all(is.na(wave_n))) wave_n <- as.numeric(factor(labtxt(d$wave)))
d$wave_n <- wave_n
cat("Wave table:\n"); print(table(labtxt(d$wave), d$wave_n, useNA = "ifany"))

# ---------------- incentive assignment ----------------
inc_num <- num(d$incentive)
if (all(is.na(inc_num))) inc_num <- first_int(labtxt(d$incentive))
lab <- labtxt(d$incentive)
txt <- if ("incentivetext" %in% nm) labtxt(d$incentivetext) else rep("", nrow(d))
txt[is.na(txt)] <- ""; lab[is.na(lab)] <- ""
is_commit <- grepl("commit|12\\+|at least|conditional|\\$80|80 if", paste(lab, txt), ignore.case = TRUE)
if (sum(is_commit & d$wave_n == 3, na.rm = TRUE) == 0) {
  if (sum(d$wave_n == 3 & is.na(inc_num), na.rm = TRUE) > 0) {
    is_commit <- d$wave_n == 3 & is.na(inc_num)
  } else {
    is_commit <- d$wave_n == 3 & !(inc_num %in% c(0, 7))
  }
}
is_commit[is.na(is_commit)] <- FALSE
rate <- inc_num
if (!all(rate[!is_commit] %in% c(0, 1, 2, 3, 5, 7, 12, NA))) {
  parse_rate <- function(s) {
    m <- regmatches(s, regexpr("\\$\\s*[0-9.]+", s))
    if (length(m) == 0) {
      if (grepl("no |none|zero|\\b0\\b", s, ignore.case = TRUE)) return(0)
      return(NA_real_)
    }
    as.numeric(gsub("[^0-9.]", "", m))
  }
  r2 <- sapply(paste(txt, lab), parse_rate)
  rate <- ifelse(!is.na(r2), r2, rate)
}
d$rate <- rate
d$is_commit <- is_commit
cat("Incentive table:\n"); print(table(d$wave_n, ifelse(is_commit, "commit", as.character(rate)), useNA = "ifany"))

exp_assigned <- rep(NA_real_, nrow(d))
for (i in seq_len(nrow(d))) {
  r <- d$rate[i]
  if (is.na(r) || d$is_commit[i]) next
  if (r == 0) exp_assigned[i] <- d$exp0[i]
  else if (as.character(r) %in% colnames(A)) exp_assigned[i] <- A[i, as.character(r)]
}
d$exp_assigned <- exp_assigned

# ---------------- treatment ----------------
tr <- num(d$treatment)
if (all(is.na(tr))) {
  tt <- labtxt(d$treatment)
  tr <- ifelse(is.na(tt), NA_real_, as.numeric(!grepl("control|no info|none", tt, ignore.case = TRUE)))
}
if (!all(tr %in% c(0, 1, NA))) tr <- as.numeric(tr == max(tr, na.rm = TRUE))
cat("Treatment by wave:\n"); print(table(d$wave_n, tr, useNA = "ifany"))
d$basic <- as.numeric(tr == 1 & d$wave_n == 1)
d$enhanced <- as.numeric(tr == 1 & d$wave_n %in% c(2, 3))

# ---------------- sample ----------------
fl <- num(d$flag_exclude_exog); fl[is.na(fl)] <- 0
if (sum(fl == 1) > nrow(d) / 2) fl <- 1 - fl
cat("Excluded endogenous:", sum(fl == 1), "\n")
d$fl <- fl
d$id <- seq_len(nrow(d))
d$goal_gap <- d$goal_n - d$exp0
d$act_gap <- d$visits_n - d$exp_assigned

s <- d %>% filter(fl == 0, !is_commit, !is.na(bcp), !is.na(wave_n), !is.na(basic))
s_full <- s %>% filter(!is.na(goal_gap), !is.na(act_gap))
if (nrow(s) - nrow(s_full) <= 20) s <- s_full
cat("Table 3 sample N:", nrow(s), "\n")
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s$z_goal <- z(s$goal_gap)
s$z_act <- z(s$act_gap)
s$z_bcp <- z(s$bcp)

t3c1 <- feols(bcp ~ basic + enhanced | wave_n, data = s, vcov = "hetero")
t3c2 <- feols(bcp ~ basic + enhanced + z_goal | wave_n, data = s, vcov = "hetero")
t3c3 <- feols(bcp ~ basic + enhanced + z_act | wave_n, data = s, vcov = "hetero")
print(etable(t3c1, t3c2, t3c3))

# ---------------- take-up of "more" contracts ----------------
cc <- nm[grepl("^chose", nm, ignore.case = TRUE) & grepl("commit", nm, ignore.case = TRUE) &
           !grepl("less|fewer|few|under|max|lt|le_|sure|percent|meet|anti", nm, ignore.case = TRUE)]
thr_of <- function(n) { m <- regmatches(n, regexpr("[0-9]+$", n)); if (length(m) == 0) NA else as.numeric(m) }
cc8 <- cc[sapply(cc, thr_of) %in% c(8, 12, 16)]
if (length(cc8) > 0) cc <- cc8
cc <- cc[!duplicated(sapply(cc, thr_of))]
cat("More-commitment vars:", paste(cc, collapse = ","), "\n")

to01 <- function(x) {
  v <- num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (all(u %in% c(0, 1))) return(v)
  if (is.labelled(x)) {
    labs <- attr(x, "labels")
    hit <- labs[grepl("conditional|commit|only if|at least|\\+", names(labs), ignore.case = TRUE)]
    if (length(hit) >= 1) return(as.numeric(v == hit[1]))
  }
  as.numeric(v == min(u))
}
long <- bind_rows(lapply(cc, function(v) {
  data.frame(id = s$id, wave_n = s$wave_n, basic = s$basic, enhanced = s$enhanced,
             z_bcp = s$z_bcp, z_goal = s$z_goal, z_act = s$z_act,
             thr = thr_of(v), take = to01(s[[v]]))
})) %>% filter(!is.na(take))
rates <- tapply(long$take[long$wave_n %in% c(1, 2)], long$thr[long$wave_n %in% c(1, 2)], mean)
print(rates)
if (all(c("8", "16") %in% names(rates)) && rates["8"] < rates["16"]) long$take <- 1 - long$take
cat("Table 4 N:", nrow(long), "\n")

fe4 <- if (length(unique(long$thr)) > 1) "wave_n + thr" else "wave_n"
f4 <- function(rhs) as.formula(paste("take ~", rhs, "|", fe4))
t4c1 <- feols(f4("basic + enhanced"), data = long, cluster = ~id)
t4c2 <- feols(f4("basic + enhanced + z_bcp"), data = long, cluster = ~id)
t4c3 <- feols(f4("basic + enhanced + z_goal"), data = long, cluster = ~id)
t4c4 <- feols(f4("basic + enhanced + z_act"), data = long, cluster = ~id)
print(etable(t4c1, t4c2, t4c3, t4c4))

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("bcp_basic_info_treatment_col1", coef(t3c1)["basic"])
out("bcp_enhanced_info_treatment_col1", coef(t3c1)["enhanced"])
out("bcp_goal_minus_expected_attendance_col2", coef(t3c2)["z_goal"])
out("bcp_actual_minus_expected_attendance_col3", coef(t3c3)["z_act"])
out("bcp_regression_observations", nobs(t3c1))
out("takeup_more_basic_info_treatment_col1", coef(t4c1)["basic"])
out("takeup_more_enhanced_info_treatment_col1", coef(t4c1)["enhanced"])
out("takeup_more_behavior_change_premium_col2", coef(t4c2)["z_bcp"])
out("takeup_more_goal_minus_expected_attendance_col3", coef(t4c3)["z_goal"])
out("takeup_more_actual_minus_expected_attendance_col4", coef(t4c4)["z_act"])
out("takeup_more_regression_observations", nobs(t4c1))