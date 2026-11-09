suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(sandwich)
  library(lmtest)
  library(AER)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/dertwinkel_kalt_2022_concentration_bias.script-free"
f <- file.path(base_dir, "Consumption Experiment", "Stata", "Consumption_Experiment.csv")
raw <- readr::read_csv(f, show_col_types = FALSE, guess_max = 100000)
raw <- as.data.frame(raw)

cat("Columns:\n"); print(names(raw))
cat("Dimensions:", dim(raw), "\n")
print(head(raw, 12))

show_tab <- function(v) {
  if (v %in% names(raw)) {
    cat("---- table of", v, "----\n")
    x <- raw[[v]]
    if (length(unique(x)) <= 40) print(table(x, useNA = "ifany")) else print(summary(x))
  }
}
for (v in c("dispersed", "session", "treatment", "decision_number", "utility_point",
            "corner", "chose_corner", "pizza", "control", "main")) show_tab(v)

num <- function(x) suppressWarnings(as.numeric(x))

# ------------------------------------------------------------------
# Subject identifier
# ------------------------------------------------------------------
raw$tn_n <- raw$tn
rows_per_tn <- table(raw$tn)
cat("Rows per tn (distribution):\n"); print(table(rows_per_tn))
if (max(rows_per_tn) > 9 && "session" %in% names(raw)) {
  raw$sid <- paste(raw$session, raw$tn, sep = "_")
  cat("tn not unique: using session_tn as subject id\n")
} else {
  raw$sid <- as.character(raw$tn)
}
cat("Rows per subject id:\n"); print(table(table(raw$sid)))

# ------------------------------------------------------------------
# Identify final (unbalanced / placebo) decision vs balanced decisions
# ------------------------------------------------------------------
raw$dec <- num(raw$decision_number)
raw <- raw %>% group_by(sid) %>% mutate(maxdec = max(dec, na.rm = TRUE)) %>% ungroup() %>% as.data.frame()
raw$is_final <- raw$dec == raw$maxdec & raw$maxdec >= 9
if (sum(raw$is_final) == 0 && "dispersed" %in% names(raw)) {
  raw$is_final <- num(raw$dispersed) == 1
}
cat("Final rows:", sum(raw$is_final), " balanced rows:", sum(!raw$is_final), "\n")
raw$ip <- num(raw$indifference_point)
cat("Balanced ip summary:\n"); print(summary(raw$ip[!raw$is_final]))
cat("Final ip summary:\n"); print(summary(raw$ip[raw$is_final]))
cat("Final ip table:\n"); print(table(raw$ip[raw$is_final], useNA = "ifany"))

# workday index for balanced trade-offs
tcol <- intersect(c("workday", "day", "tradeoff", "j", "date_number"), names(raw))
if (length(tcol) > 0) {
  raw$tday <- num(raw[[tcol[1]]])
  cat("Using", tcol[1], "as workday index\n")
} else {
  raw$tday <- raw$dec
  cat("Using decision_number as workday index\n")
}
cat("Workday index among balanced rows:\n"); print(table(raw$tday[!raw$is_final], useNA = "ifany"))

e_vec <- c(129, 132, 143, 115, 121, 117, 135, 127)

# ------------------------------------------------------------------
# Manual (unincentivised) stated indifference point
# ------------------------------------------------------------------
known <- c("tn", "dispersed", "age", "study", "mathgrade", "disposable_income",
           "raven_correct_answers", "math_answers_correct", "crt_answers_correct",
           "session", "treatment", "average_ip", "decision_number", "utility_point",
           "corner", "chose_corner", "indifference_point", "pizza", "control", "main", "id_stage2")
cat("Other columns:\n"); print(setdiff(names(raw), c(known, "tn_n", "sid", "dec", "maxdec", "is_final", "ip", "tday")))
man_cands <- grep("manual|stated|hypo|open|free|self|upper|wtw|text", names(raw), ignore.case = TRUE, value = TRUE)
man_cands <- setdiff(man_cands, c("sid"))
cat("Manual IP candidates:\n"); print(man_cands)
man_col <- NULL
for (m in man_cands) {
  if (sum(!is.na(num(raw[[m]]))) > 0) { man_col <- m; break }
}
cat("Using manual IP column:", ifelse(is.null(man_col), "<none>", man_col), "\n")

# ------------------------------------------------------------------
# Subject-level data
# ------------------------------------------------------------------
first_nonna <- function(x) { x <- x[!is.na(x)]; if (length(x)) x[1] else NA }
subj_ids <- unique(raw$sid)
rows <- lapply(subj_ids, function(s) {
  d <- raw[raw$sid == s, , drop = FALSE]
  b <- d[!d$is_final, , drop = FALSE]
  fr <- d[d$is_final, , drop = FALSE]
  b <- b[order(b$tday), , drop = FALSE]
  x <- rep(NA_real_, 8)
  ok <- !is.na(b$tday) & b$tday >= 1 & b$tday <= 8
  x[b$tday[ok]] <- b$ip[ok]
  corner_bal <- if ("corner" %in% names(d)) any(num(b$corner) == 1, na.rm = TRUE) else NA
  corner_bal2 <- any(b$ip <= 0 | b$ip >= 125, na.rm = TRUE)
  dfin <- if (nrow(fr)) fr$ip[1] else NA
  man <- if (!is.null(man_col)) first_nonna(num(d[[man_col]])) else NA
  data.frame(
    sid = s,
    treatment = first_nonna(as.character(d$treatment)),
    control = first_nonna(num(d$control)),
    main = first_nonna(num(d$main)),
    pizza = first_nonna(num(d$pizza)),
    dispersed = if ("dispersed" %in% names(d)) first_nonna(num(d$dispersed)) else NA,
    nbal = nrow(b),
    x1 = x[1], x2 = x[2], x3 = x[3], x4 = x[4], x5 = x[5], x6 = x[6], x7 = x[7], x8 = x[8],
    corner_bal = corner_bal, corner_bal2 = corner_bal2,
    chose_corner_final = if (nrow(fr) && "chose_corner" %in% names(fr)) num(fr$chose_corner[1]) else NA,
    d = dfin, manual = man,
    stringsAsFactors = FALSE
  )
})
S <- do.call(rbind, rows)
cat("Subjects:", nrow(S), "\n")
cat("Condition flags (treatment x control x main x pizza):\n")
print(with(S, table(treatment, control, useNA = "ifany")))
print(with(S, table(main, pizza, control, useNA = "ifany")))
if (!all(is.na(S$dispersed))) print(with(S, table(dispersed, main, useNA = "ifany")))
cat("Corner (column) vs corner (computed):\n"); print(with(S, table(corner_bal, corner_bal2, useNA = "ifany")))

# ------------------------------------------------------------------
# Condition assignment
# ------------------------------------------------------------------
tr <- tolower(S$treatment)
if (any(grepl("mech|don|main|contr", tr))) {
  S$is_control <- grepl("contr", tr)
  S$is_mech <- grepl("mech", tr)
  S$is_don <- grepl("don|char", tr)
  cat("Conditions parsed from treatment labels\n")
} else {
  S$is_control <- S$control == 1
  S$is_don <- S$pizza == 0
  S$is_mech <- (S$main == 0) & !S$is_don
  cat("Conditions from control/pizza/main flags\n")
}
S$cond <- with(S, ifelse(is_don, "Donation", ifelse(is_mech, "Mechanism", "Main")))
S$cond <- paste0(S$cond, ifelse(S$is_control, "-Control", "-Treatment"))
cat("Conditions (all subjects):\n"); print(table(S$cond, useNA = "ifany"))

# exclusion: corner choice in any balanced trade-off
if (!all(is.na(S$corner_bal))) S$excl <- S$corner_bal else S$excl <- S$corner_bal2
S$excl[is.na(S$excl)] <- FALSE
cat("Conditions x excluded:\n"); print(table(S$cond, S$excl))

M <- S[!S$excl, ]

# ------------------------------------------------------------------
# Measures
# ------------------------------------------------------------------
UB_D <- 62
M$upper_corner <- !is.na(M$d) & M$d >= UB_D
cat("Upper-corner subjects in final trade-off:", sum(M$upper_corner), "\n")
cat("Manual IPs for upper-corner subjects:\n"); print(M$manual[M$upper_corner])
M$d_lb <- ifelse(M$upper_corner, UB_D, M$d)
man_u <- ifelse(is.na(M$manual), UB_D, pmax(M$manual, UB_D))
M$d_ub <- ifelse(M$upper_corner, man_u, M$d)
M$d_mid <- ifelse(M$upper_corner, (UB_D + man_u) / 2, M$d)

X <- as.matrix(M[, paste0("x", 1:8)])
inv_sum <- rowMeans(1 / sweep(X, 2, e_vec, "+"))
M$drel_lb <- M$d_lb * inv_sum
M$drel_mid <- M$d_mid * inv_sum
M$drel_ub <- M$d_ub * inv_sum

ols_const <- function(y) {
  y <- y[!is.na(y)]
  fit <- lm(y ~ 1)
  se <- sqrt(diag(vcovHC(fit, type = "HC1")))
  list(b = unname(coef(fit)[1]), se = unname(se[1]), n = length(y))
}

MT <- M[M$cond == "Main-Treatment", ]
cat("Main-Treatment main sample N:", nrow(MT), "\n")
r_dmid <- ols_const(MT$d_mid)
r_rlb <- ols_const(MT$drel_lb)
r_rmid <- ols_const(MT$drel_mid)
r_rub <- ols_const(MT$drel_ub)
cat(sprintf("d_mid: %.4f (%.4f); drel lb %.4f (%.4f), mid %.4f (%.4f), ub %.4f (%.4f)\n",
            r_dmid$b, r_dmid$se, r_rlb$b, r_rlb$se, r_rmid$b, r_rmid$se, r_rub$b, r_rub$se))
cat("d_lb mean:", mean(MT$d_lb, na.rm = TRUE), " d_ub mean:", mean(MT$d_ub, na.rm = TRUE), "\n")

# Tobit on lower-bound measure, censored at ends of elicitation range
lowest <- min(MT$d_lb, na.rm = TRUE)
left_c <- if (lowest <= -63) lowest else -Inf
tob <- AER::tobit(d_lb ~ 1, left = left_c, right = UB_D, data = MT)
print(summary(tob))
tobit_b <- unname(coef(tob)[1])

# ------------------------------------------------------------------
# Table 3
# ------------------------------------------------------------------
two_group <- function(dat, gA, gB, label) {
  dd <- dat[dat$cond %in% c(gA, gB) & !is.na(dat$drel_mid), ]
  dd$ind <- as.numeric(dd$cond == gA)
  fit <- lm(drel_mid ~ ind, data = dd)
  V <- vcovHC(fit, type = "HC1")
  cat("----", label, "----  N =", nrow(dd), "\n")
  print(coeftest(fit, vcov. = V))
  list(const = unname(coef(fit)[1]), diff = unname(coef(fit)[2]), n = nrow(dd))
}
t3c1 <- two_group(M, "Main-Treatment", "Mechanism-Treatment", "Col1 Main vs Mechanism")
t3c2 <- two_group(M, "Donation-Treatment", "Donation-Control", "Col2 Donation T vs C")
t3c3 <- two_group(M, "Main-Treatment", "Main-Control", "Col3 Main T vs C")
t3c4 <- two_group(M, "Mechanism-Treatment", "Mechanism-Control", "Col4 Mechanism T vs C")

cat(sprintf("RESULT:abs_concentration_bias_midpoint_table2_col2=%.6f\n", r_dmid$b))
cat(sprintf("RESULT:abs_concentration_bias_tobit_table2_col4=%.6f\n", tobit_b))
cat(sprintf("RESULT:rel_concentration_bias_lower_table2_col1=%.6f\n", r_rlb$b))
cat(sprintf("RESULT:rel_concentration_bias_midpoint_table2_col2=%.6f\n", r_rmid$b))
cat(sprintf("RESULT:rel_concentration_bias_upper_table2_col3=%.6f\n", r_rub$b))
cat(sprintf("RESULT:n_obs_table2=%d\n", r_rmid$n))
cat(sprintf("RESULT:rel_cb_mechanism_treatment_table3_col1=%.6f\n", t3c1$const))
cat(sprintf("RESULT:diff_main_minus_mechanism_table3_col1=%.6f\n", t3c1$diff))
cat(sprintf("RESULT:rel_cb_donation_treatment_table3_col2=%.6f\n", t3c2$const + t3c2$diff))
cat(sprintf("RESULT:diff_donation_treatment_minus_control_table3_col2=%.6f\n", t3c2$diff))
cat(sprintf("RESULT:diff_main_treatment_minus_control_table3_col3=%.6f\n", t3c3$diff))
cat(sprintf("RESULT:diff_mechanism_treatment_minus_control_table3_col4=%.6f\n", t3c4$diff))
cat(sprintf("RESULT:n_obs_table3=%d\n", t3c1$n))
