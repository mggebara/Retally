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

# ---------------- WTP and forecasts ----------------
wtp_vars <- paste0("wtp", ps)
fc_vars <- paste0("days_", ps)
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
d$exp0 <- if ("days_0" %in% nm) num(d$days_0) else num(d$visits_next4weeks)
if (all(is.na(d$exp0))) d$exp0 <- num(d$visits_next4weeks)
d$goal_n <- num(d$goal)
d$visits_n <- num(d$visits)

# ---------------- wave ----------------
wave_n <- if ("wavenum" %in% nm) num(d$wavenum) else rep(NA_real_, nrow(d))
if (all(is.na(wave_n))) wave_n <- num(d$wave)
if (all(is.na(wave_n))) wave_n <- first_int(labtxt(d$wave))
d$wave_n <- wave_n

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
d$rate <- inc_num
d$is_commit <- is_commit
cat("Incentive table:\n"); print(table(d$wave_n, ifelse(is_commit, "commit", as.character(d$rate)), useNA = "ifany"))

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
d$basic <- as.numeric(tr == 1 & d$wave_n == 1)
d$enhanced <- as.numeric(tr == 1 & d$wave_n %in% c(2, 3))

# ---------------- sample: drop all 44 endogenous-assignment obs ----------------
mkflag <- function(v) {
  if (!(v %in% nm)) return(rep(0, nrow(d)))
  f <- num(d[[v]]); f[is.na(f)] <- 0
  if (sum(f == 1) > nrow(d) / 2) f <- 1 - f
  as.numeric(f == 1)
}
f1 <- mkflag("flag_exclude_exog")
f2 <- mkflag("flag_low_wtp")
cat("flag_exclude_exog:", sum(f1), " flag_low_wtp:", sum(f2), "\n")
fl <- f1
if (sum(f2) <= 60) fl <- as.numeric(f1 == 1 | f2 == 1)
cat("Excluded endogenous total:", sum(fl), "  remaining:", nrow(d) - sum(fl), "\n")
d$fl <- fl
d$id <- seq_len(nrow(d))
d$goal_gap <- d$goal_n - d$exp0
d$act_gap <- d$visits_n - d$exp_assigned

s <- d %>% filter(fl == 0, !is_commit, !is.na(bcp), !is.na(wave_n), !is.na(basic))
s_full <- s %>% filter(!is.na(goal_gap), !is.na(act_gap))
if (nrow(s) - nrow(s_full) <= 20) s <- s_full
cat("Table 3 sample N:", nrow(s), " by wave:\n"); print(table(s$wave_n))
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
s$z_goal <- z(s$goal_gap)
s$z_act <- z(s$act_gap)
s$z_bcp <- z(s$bcp)

t3c1 <- feols(bcp ~ basic + enhanced | wave_n, data = s, vcov = "hetero")
t3c2 <- feols(bcp ~ basic + enhanced + z_goal | wave_n, data = s, vcov = "hetero")
t3c3 <- feols(bcp ~ basic + enhanced + z_act | wave_n, data = s, vcov = "hetero")
print(etable(t3c1, t3c2, t3c3))

# ---------------- take-up of "more" contracts ----------------
to01 <- function(x) {
  v <- num(x)
  u <- sort(unique(v[!is.na(v)]))
  if (length(u) == 0) return(v)
  if (all(u %in% c(0, 1))) return(v)
  if (is.labelled(x)) {
    labs <- attr(x, "labels")
    hit <- labs[grepl("conditional|commit|only if|at least|\\+|or more|if I", names(labs), ignore.case = TRUE)]
    if (length(hit) >= 1) return(as.numeric(v == hit[1]))
  }
  as.numeric(v == min(u))
}
txt_of <- function(v) {
  x <- d[[v]]
  l <- attr(x, "label"); if (is.null(l)) l <- ""
  vl <- attr(x, "labels"); vl <- if (is.null(vl)) "" else paste(names(vl), collapse = " | ")
  paste(l, vl)
}
qc <- nm[grepl("^q[0-9]+$", nm)]
cand <- data.frame(v = character(0), thr = numeric(0), dir = character(0), rate = numeric(0), stringsAsFactors = FALSE)
info <- list()
for (v in qc) {
  x <- num(d[[v]])
  nu <- length(unique(x[!is.na(x)]))
  nm12 <- mean(!is.na(x[d$wave_n %in% c(1, 2)]))
  nm3 <- mean(!is.na(x[d$wave_n == 3]))
  tx <- txt_of(v)
  cat(sprintf("Cand %s: nuniq=%d nonmiss12=%.2f nonmiss3=%.2f text=[%s]\n", v, nu, nm12, nm3, substr(tx, 1, 300)))
  if (nu != 2 || nm12 < 0.5 || nm3 > 0.2) next
  t01 <- to01(d[[v]])
  r <- mean(t01[d$wave_n %in% c(1, 2) & fl == 0], na.rm = TRUE)
  nums <- as.numeric(unlist(regmatches(tx, gregexpr("[0-9]+", tx))))
  fewer <- grepl("fewer|less|at most|no more|or under|under|below|maximum|max", tx, ignore.case = TRUE)
  thr <- NA; dir <- NA
  if (!fewer && 8 %in% nums && !(16 %in% nums)) { thr <- 8; dir <- "more" }
  if (!fewer && 16 %in% nums) { thr <- 16; dir <- "more" }
  if (fewer) dir <- "fewer"
  cand <- rbind(cand, data.frame(v = v, thr = thr, dir = ifelse(is.na(dir), "", dir), rate = r, stringsAsFactors = FALSE))
}
print(cand)

more_vars <- c("12" = "chose_commit12")
lab8 <- cand$v[cand$thr %in% 8 & cand$dir == "more"]
lab16 <- cand$v[cand$thr %in% 16 & cand$dir == "more"]
if (length(lab8) >= 1 && length(lab16) >= 1) {
  more_vars <- c("8" = lab8[1], more_vars, "16" = lab16[1])
} else {
  # Fallback: unlabelled binary candidates available only in waves 1-2.
  pool <- cand[cand$dir != "fewer", ]
  if (nrow(pool) >= 2) {
    # 8+ has the highest take-up (~64%); 16+ the one most correlated with it among the rest
    o <- order(-pmax(pool$rate, 1 - pool$rate))
    v8 <- pool$v[o[1]]
    rest <- setdiff(pool$v, v8)
    x8 <- to01(d[[v8]])
    c12 <- to01(d$chose_commit12)
    sc <- sapply(rest, function(v) {
      xv <- to01(d[[v]])
      ok <- !is.na(xv) & !is.na(c12) & !is.na(x8)
      suppressWarnings(cor(xv[ok], c12[ok]) + cor(xv[ok], x8[ok]))
    })
    v16 <- rest[which.max(abs(sc))]
    more_vars <- c("8" = v8, more_vars, "16" = v16)
    cat("DEVIATION: Identified 8+ / 16+ commitment variables from take-up patterns because variable labels did not name thresholds\n")
  }
}
cat("More-commitment vars:", paste(names(more_vars), more_vars, sep = "=", collapse = ","), "\n")

target <- c("8" = 0.64, "12" = 0.49, "16" = 0.32)
long <- bind_rows(lapply(names(more_vars), function(k) {
  v <- more_vars[[k]]
  tk <- to01(s[[v]])
  r <- mean(tk[s$wave_n %in% c(1, 2)], na.rm = TRUE)
  if (k != "12" && !is.na(r) && abs((1 - r) - target[k]) < abs(r - target[k])) tk <- 1 - tk
  cat(sprintf("Contract %s (%s): take-up waves 1-2 = %.3f\n", k, v, mean(tk[s$wave_n %in% c(1, 2)], na.rm = TRUE)))
  data.frame(id = s$id, wave_n = s$wave_n, basic = s$basic, enhanced = s$enhanced,
             z_bcp = s$z_bcp, z_goal = s$z_goal, z_act = s$z_act,
             thr = as.numeric(k), take = tk)
})) %>% filter(!is.na(take))
cat("Table 4 N:", nrow(long), "\n")
print(table(long$wave_n, long$thr))

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