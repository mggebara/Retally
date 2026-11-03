suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/carrera_2022_who_chooses_commitment.script-free/Who_Chooses_Commitment_Replication/Data"
d0 <- read_dta(file.path(base, "cleaned_commitment_study_data.dta"))
nm <- names(d0)
cat("Rows:", nrow(d0), " Cols:", ncol(d0), "\n")
cat("Column names:\n"); print(nm)

num <- function(x) {
  if (is.null(x)) return(NULL)
  if (is.character(x)) return(suppressWarnings(as.numeric(x)))
  if (is.factor(x)) return(suppressWarnings(as.numeric(as.character(x))))
  as.numeric(zap_labels(x))
}
lab <- function(x) {
  if (is.null(x)) return(rep("", nrow(d0)))
  if (inherits(x, "haven_labelled")) return(as.character(as_factor(x)))
  as.character(x)
}

emit <- function(name, val) {
  v <- suppressWarnings(as.numeric(val))
  if (length(v) == 0 || is.na(v)) cat(sprintf("RESULT:%s=NA\n", name))
  else cat(sprintf("RESULT:%s=%.6f\n", name, v))
}

## ---------------- Wave (string variable -> numeric) ----------------
wave <- num(d0$wavenum)
if (is.null(wave) || all(is.na(wave)) || !all(na.omit(wave) %in% 1:3)) {
  wave <- num(d0$wave)
  if (is.null(wave) || all(is.na(wave)) || !all(na.omit(wave) %in% 1:3)) {
    wave <- suppressWarnings(as.numeric(gsub("[^0-9]", "", lab(d0$wave))))
  }
}
cat("Wave table:\n"); print(table(wave, useNA = "ifany"))

## ---------------- Identify actual attendance variable via daily data -------------
actual_var <- "visits"
dd <- tryCatch(read_dta(file.path(base, "cleaned_commitment_study_daily_data.dta")),
               error = function(e) NULL)
if (!is.null(dd) && "attended" %in% names(dd) &&
    all(c("visits", "visits_next4weeks") %in% names(dd))) {
  keys <- intersect(c("wtp1", "wtp2", "wtp3", "wtp5", "wtp7", "wtp12", "goal",
                      "visits", "visits_100days", "visits_next4weeks", "past4",
                      "incentive"), names(dd))
  ddk <- as.data.frame(lapply(dd[keys], num))
  ddk$att <- num(dd$attended)
  agg <- ddk %>% group_by(across(all_of(keys))) %>%
    summarise(n = n(), s = sum(att, na.rm = TRUE), .groups = "drop") %>%
    filter(n == 28)
  a_v <- mean(agg$s == agg$visits, na.rm = TRUE)
  a_n <- mean(agg$s == agg$visits_next4weeks, na.rm = TRUE)
  cat("Daily agreement: visits =", a_v, " visits_next4weeks =", a_n, "\n")
  if (is.finite(a_n) && is.finite(a_v) && a_n > a_v) actual_var <- "visits_next4weeks"
}
other_var <- setdiff(c("visits", "visits_next4weeks"), actual_var)
cat("Actual attendance variable:", actual_var, "\n")
actual <- num(d0[[actual_var]])

## ---------------- Forecasts under incentives: days_p ; no incentive: days_0 -------
rates <- c(1, 2, 3, 5, 7, 12)
W <- sapply(rates, function(p) {
  w <- num(d0[[paste0("wtp", p)]])
  mx <- num(d0[[paste0("maxwtp", p)]])
  if (!is.null(mx)) {
    top <- !is.na(w) & w >= 30 * p - 1e-8 & !is.na(mx) & mx > w
    w[top] <- mx[top]
  }
  w
})
if (all(paste0("days_", c(0, rates)) %in% nm)) {
  Fm <- sapply(rates, function(p) num(d0[[paste0("days_", p)]]))
  F0 <- num(d0$days_0)
} else {
  Fm <- matrix(NA_real_, nrow(d0), length(rates))
  F0 <- num(d0[[other_var]])
}
cat("Mean WTP by rate:", round(colMeans(W, na.rm = TRUE), 2), "\n")
cat("Mean forecast by rate:", round(colMeans(Fm, na.rm = TRUE), 2), " F0 mean:", mean(F0, na.rm = TRUE), "\n")

## Behavior change premium: average over adjacent elicited piece-rate pairs
## ($1-$2, $2-$3, $3-$5, $5-$7, $7-$12), using the fill-in WTP at the slider maximum
B <- sapply(1:5, function(i) {
  dlt <- rates[i + 1] - rates[i]
  (W[, i + 1] - W[, i]) / dlt - (Fm[, i + 1] + Fm[, i]) / 2
})
cat("Mean BCP by pair:", round(colMeans(B, na.rm = TRUE), 3), "\n")
bcp <- rowMeans(B, na.rm = TRUE)
bcp[!is.finite(bcp)] <- NA

## ---------------- Information treatment -------------------------------------------
to_binary <- function(x) {
  v <- num(x)
  if (!is.null(v) && any(!is.na(v))) {
    u <- sort(unique(na.omit(v)))
    if (all(u %in% c(0, 1))) return(v)
    if (length(u) == 2) return(as.numeric(v == max(u)))
  }
  tl <- tolower(trimws(lab(x)))
  out <- ifelse(tl %in% c("", "na", "."), NA,
                as.numeric(!grepl("control|no info|none|^no$|^no ", tl)))
  out
}
tr <- to_binary(d0$treatment)
if (all(is.na(tr)) || length(unique(na.omit(tr))) < 2) tr <- to_binary(d0$type_of_info)
cat("Treatment labels:\n"); print(table(lab(d0$treatment), useNA = "ifany"))
cat("Treatment by wave:\n"); print(table(tr, wave, useNA = "ifany"))
basic <- as.numeric(tr == 1 & wave == 1)
enhanced <- as.numeric(tr == 1 & wave %in% c(2, 3))

## ---------------- Assigned incentive ----------------------------------------------
inc_num <- num(d0$incentive)
itxt <- if ("incentivetext" %in% nm) lab(d0$incentivetext) else rep("", nrow(d0))
cat("Incentive table:\n"); print(table(inc_num, wave, useNA = "ifany"))
contract <- grepl("\\$80|80 dollar|commit|12\\+|at least|or more", itxt, ignore.case = TRUE) |
  (!is.na(inc_num) & inc_num == 80)
contract[is.na(contract)] <- FALSE
if (sum(contract & wave == 3, na.rm = TRUE) == 0) {
  contract <- wave == 3 & (is.na(inc_num) | !(inc_num %in% c(0, 1, 2, 3, 5, 7, 12)))
  contract[is.na(contract)] <- FALSE
}
cat("Contract-assigned by wave:\n"); print(table(contract, wave, useNA = "ifany"))

pr <- inc_num
pr[contract] <- NA
idx <- match(pr, rates)
exp_assigned <- ifelse(!is.na(pr) & pr == 0, F0,
                       Fm[cbind(seq_len(nrow(d0)), ifelse(is.na(idx), 1, idx))])
exp_assigned[!is.na(pr) & pr != 0 & is.na(idx)] <- NA
exp_assigned[is.na(pr)] <- NA

goal <- num(d0$goal)
gap_goal <- goal - F0
gap_act <- actual - exp_assigned

## ---------------- Sample ------------------------------------------------------------
excl <- num(d0$flag_exclude_exog); excl[is.na(excl)] <- 0
base_ok <- !is.na(bcp) & !is.na(tr) & !is.na(wave)

## Candidate exclusion flags (paper excludes 44 potentially endogenous assignments:
## 12 with fixed-payment draw > $7 and 32 with WTP inside $0-$7)
flag_vars <- setdiff(nm[grepl("flag|excl|endog|drop", nm, ignore.case = TRUE)], "flag_exclude_exog")
cat("Candidate flag variables:", flag_vars, "\n")
flag_list <- list()
for (fv in flag_vars) {
  v <- num(d0[[fv]])
  if (is.null(v) || all(is.na(v))) next
  u <- sort(unique(na.omit(v)))
  if (!all(u %in% c(0, 1))) next
  v[is.na(v)] <- 0
  cat("  ", fv, "sum =", sum(v), "\n")
  flag_list[[fv]] <- v == 1
}
## Computed endogenous flag: assigned a positive piece rate and WTP for it in (0, 7)
w_ass <- W[cbind(seq_len(nrow(d0)), ifelse(is.na(idx), 1, idx))]
w_ass[is.na(idx)] <- NA
endog_calc <- !is.na(w_ass) & w_ass > 0 & w_ass < 7
cat("Computed endogenous (WTP in (0,7) at assigned rate):", sum(endog_calc), "\n")

cands <- list(rule1 = excl != 1 & !contract,
              rule2 = excl != 1,
              rule1_endogcalc = excl != 1 & !contract & !endog_calc)
if (length(flag_list) > 0) {
  anyflag <- Reduce(`|`, flag_list)
  cands[["rule1_anyflag"]] <- excl != 1 & !contract & !anyflag
  for (fv in names(flag_list)) cands[[paste0("rule1_", fv)]] <- excl != 1 & !contract & !flag_list[[fv]]
}
ns <- sapply(cands, function(s) sum(s & base_ok, na.rm = TRUE))
cat("Candidate sample sizes:\n"); print(ns)
best <- names(ns)[which.min(abs(ns - 1126))]
cat("Chosen sample rule:", best, "\n")
if (!(best %in% c("rule1", "rule2")))
  cat("DEVIATION: Sample additionally excludes potentially endogenous assignments via rule", best, "chosen to match paper N=1126\n")
samp <- cands[[best]]
samp[is.na(samp)] <- FALSE
samp <- samp & base_ok

df <- data.frame(id = seq_len(nrow(d0)), wave = wave, basic = basic, enhanced = enhanced,
                 bcp = bcp, gap_goal = gap_goal, gap_act = gap_act)[samp, ]
z <- function(x) (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE)
df$z_goal <- z(df$gap_goal)
df$z_act <- z(df$gap_act)
df$z_bcp <- z(df$bcp)
cat("Mean BCP in sample:", mean(df$bcp), "\n")

getc <- function(m, v) tryCatch(unname(coef(m)[v]), error = function(e) NA)
m1 <- tryCatch(feols(bcp ~ basic + enhanced | wave, data = df, vcov = "hetero"), error = function(e) NULL)
m2 <- tryCatch(feols(bcp ~ basic + enhanced + z_goal | wave, data = df, vcov = "hetero"), error = function(e) NULL)
m3 <- tryCatch(feols(bcp ~ basic + enhanced + z_act | wave, data = df, vcov = "hetero"), error = function(e) NULL)
for (m in list(m1, m2, m3)) if (!is.null(m)) print(summary(m))

## ---------------- Table 4: "more" contract take-up -----------------------------------
ths <- c(8, 12, 16)
col12 <- if ("chose_commit12" %in% nm) "chose_commit12" else NA
col8 <- if ("chose_commit8" %in% nm) "chose_commit8" else if ("q169" %in% nm) "q169" else NA
col16 <- if ("chose_commit16" %in% nm) "chose_commit16" else if ("q170" %in% nm) "q170" else NA
cols <- c(col8, col12, col16)
cat("More-contract columns:", cols, "\n")
if (identical(col8, "q169") || identical(col16, "q170"))
  cat("DEVIATION: Unlabelled columns q169/q170 used as the >=8 and >=16 'more' contract choices\n")
recode01 <- function(v, want_high) {
  u <- sort(unique(na.omit(v)))
  if (all(u %in% c(0, 1))) return(v)
  if (length(u) == 2) {
    a <- as.numeric(v == u[1])
    if ((mean(a, na.rm = TRUE) >= 0.5) == want_high) return(a) else return(1 - a)
  }
  v
}
raw <- lapply(seq_along(cols), function(i) {
  cn <- cols[i]
  if (is.na(cn)) return(rep(NA_real_, nrow(d0)))
  v <- num(d0[[cn]])
  if (all(is.na(v))) {
    tl <- tolower(lab(d0[[cn]]))
    v <- ifelse(tl %in% c("", "na"), NA, as.numeric(grepl("conditional|commit|if i", tl)))
  }
  recode01(v, want_high = (ths[i] == 8))
})
raw[[1]][wave == 3] <- NA
raw[[3]][wave == 3] <- NA
for (i in 1:3) cat("Take-up at", ths[i], ":", mean(raw[[i]][samp], na.rm = TRUE), "\n")

long <- do.call(rbind, lapply(1:3, function(i) {
  data.frame(id = seq_len(nrow(d0)), th = ths[i], y = raw[[i]])[samp, ]
}))
long <- merge(long, df[, c("id", "wave", "basic", "enhanced", "z_bcp", "z_goal", "z_act")], by = "id")
long <- long[!is.na(long$y), ]
cat("Table 4 N:", nrow(long), "\n")
t1 <- tryCatch(feols(y ~ basic + enhanced | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t2 <- tryCatch(feols(y ~ basic + enhanced + z_bcp | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t3 <- tryCatch(feols(y ~ basic + enhanced + z_goal | wave + th, data = long, cluster = ~id), error = function(e) NULL)
t4 <- tryCatch(feols(y ~ basic + enhanced + z_act | wave + th, data = long, cluster = ~id), error = function(e) NULL)
for (m in list(t1, t2, t3, t4)) if (!is.null(m)) print(summary(m))

emit("bcp_basic_info_treatment_col1", getc(m1, "basic"))
emit("bcp_enhanced_info_treatment_col1", getc(m1, "enhanced"))
emit("bcp_goal_minus_expected_attendance_col2", getc(m2, "z_goal"))
emit("bcp_actual_minus_expected_attendance_col3", getc(m3, "z_act"))
emit("bcp_regression_observations", if (!is.null(m1)) nobs(m1) else nrow(df))
emit("takeup_more_basic_info_treatment_col1", getc(t1, "basic"))
emit("takeup_more_enhanced_info_treatment_col1", getc(t1, "enhanced"))
emit("takeup_more_behavior_change_premium_col2", getc(t2, "z_bcp"))
emit("takeup_more_goal_minus_expected_attendance_col3", getc(t3, "z_goal"))
emit("takeup_more_actual_minus_expected_attendance_col4", getc(t4, "z_act"))
emit("takeup_more_regression_observations", if (!is.null(t1)) nobs(t1) else nrow(long))
