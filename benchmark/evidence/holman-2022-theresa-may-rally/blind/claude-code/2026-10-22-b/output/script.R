# Retally independent/blind reproduction: Holman, Merolla & Zechmeister (2022), APSR
# Table 4 (global country-quarter approval model) and Table 2 (BES panel DiD).
set.seed(42)
suppressMessages({library(haven); library(data.table)})
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-10-22-b/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4 ----------------
# DV: executive approval in the quarter FOLLOWING the attack quarter.  In
# global_approval.dta the variable `lag_approval` is missing in the last
# quarter of every panel (and non-missing in the first), i.e. it is the
# next-quarter (lead) approval aligned to quarter t; it is used as the DV with
# the contemporaneous attack dummy.
# Attack: kill_16 = international attack with 16+ (i.e. more than 15) deaths
# (60 country-quarters, 9 under women executives, as described in the paper).
# Controls: female_pres, growth (GDP), log_inflation, execrlc (DPI exec
# left/center/right; entered as categories), election_qtr; country FE.
# Panel-corrected SEs (Beck-Katz, xtpcse default) do not change OLS point estimates.
g <- as.data.table(read_dta(file.path(M, "global_approval.dta")))
g[, execrlc := as.numeric(zap_labels(execrlc))]
vars4 <- c("lag_approval","kill_16","female_pres","growth","log_inflation","execrlc","election_qtr","country_code")
g4 <- na.omit(g[, ..vars4])
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + factor(execrlc) +
           election_qtr + factor(country_code), data = g4)
b4 <- coef(m4)

# Beck-Katz panel-corrected SEs (pairwise-balanced contemporaneous covariance) for information
pcse_se <- tryCatch({
  X <- model.matrix(m4); e <- residuals(m4)
  g4b <- na.omit(g[, c(vars4, "qtr"), with = FALSE])
  pan <- g4b$country_code; tim <- g4b$qtr
  P <- sort(unique(pan)); Tm <- sort(unique(tim))
  E <- matrix(NA, length(Tm), length(P)); E[cbind(match(tim, Tm), match(pan, P))] <- e
  Sig <- matrix(0, length(P), length(P))
  for (i in seq_along(P)) for (j in seq_along(P)) {
    ok <- !is.na(E[, i]) & !is.na(E[, j]); n <- sum(ok)
    Sig[i, j] <- if (n > 0) sum(E[ok, i] * E[ok, j]) / n else 0 }
  meat <- matrix(0, ncol(X), ncol(X))
  for (t in seq_along(Tm)) { idx <- which(tim == Tm[t]); if (!length(idx)) next
    pi <- match(pan[idx], P); Xt <- X[idx, , drop = FALSE]
    meat <- meat + t(Xt) %*% Sig[pi, pi, drop = FALSE] %*% Xt }
  XtXi <- solve(crossprod(X)); V <- XtXi %*% meat %*% XtXi
  sqrt(diag(V))
}, error = function(e) NULL)
cat("Table 4 OLS with country FE; N =", nobs(m4), "; countries =", length(unique(g4$country_code)), "\n")
cat("  attack quarters in sample:", sum(g4$kill_16), "; under women:", sum(g4$kill_16 * g4$female_pres), "\n")
print(round(b4[c("kill_16","female_pres","kill_16:female_pres","growth","log_inflation","election_qtr")], 4))
if (!is.null(pcse_se)) { cat("  PCSE:\n"); print(round(pcse_se[c("kill_16","female_pres","kill_16:female_pres")], 4)) }
cat("  R2 =", summary(m4)$r.squared, "\n")

## ---------------- Table 2 ----------------
# BES panel (did_data.dta, long respondent-wave file). treatment1 = surveyed
# after the Manchester bombing in wave 12 (constant within respondent);
# time = 1 for waves >= 12.  Wave FE are entered as dummies after `time`; the
# last wave dummy is aliased with `time` and dropped, so `time` is estimated.
# Controls: white (ethnically British), gender, labour, party_other, income,
# ideology2 (ideology with missing set to the scale midpoint, per footnote 8).
# May likeability: OLS.  May best PM (bestPMW: 1 = May, 0 = Corbyn): logit
# (table note); coefficients are log-odds.
d <- as.data.table(read_dta(file.path(M, "did_data.dta"),
       col_select = c("id","wave","likeMayW","bestPMW","treatment1","time","white","gender",
                      "labour","party_other","income","ideology2","starttimeW")))
d[, likeMayW := as.numeric(zap_labels(likeMayW))]
d[likeMayW > 10, likeMayW := NA]
d[, gender := as.numeric(zap_labels(gender))]
ctrl <- c("white","gender","labour","party_other","income","ideology2")
w12ids <- d[wave == 12 & !is.na(starttimeW), unique(id)]

fit_did <- function(y, dat, logit = FALSE) {
  dd <- na.omit(dat[, c(y, "treatment1","time","wave", ctrl), with = FALSE])
  f <- as.formula(paste(y, "~ treatment1 + time + factor(wave) +", paste(ctrl, collapse = " + "), "+ treatment1:time"))
  m <- if (logit) glm(f, data = dd, family = binomial()) else lm(f, data = dd)
  list(m = m, n = nrow(dd), waves = sort(unique(dd$wave)))
}
r_like <- fit_did("likeMayW", d)
r_bpm  <- fit_did("bestPMW", d, logit = TRUE)
show <- c("treatment1:time","treatment1","time","(Intercept)")
cat("\nTable 2 May likeability (OLS): N =", r_like$n, "waves", r_like$waves, "\n"); print(round(coef(r_like$m)[show], 4))
cat("  aliased:", names(which(is.na(coef(r_like$m)))), "\n")
cat("Table 2 May best PM (logit): N =", r_bpm$n, "waves", r_bpm$waves, "\n"); print(round(coef(r_bpm$m)[show], 4))
cat("  aliased:", names(which(is.na(coef(r_bpm$m)))), "\n")

# Information only (not scored): same models restricted to respondents who took wave 12,
# and a linear probability version of the best-PM model.
s_like <- fit_did("likeMayW", d[id %in% w12ids]); s_bpm <- fit_did("bestPMW", d[id %in% w12ids], logit = TRUE)
lpm <- fit_did("bestPMW", d)
cat("\n[info] wave-12-participants-only: like N =", s_like$n, ":", round(coef(s_like$m)[show[1:3]], 4),
    "| bestPM N =", s_bpm$n, ":", round(coef(s_bpm$m)[show[1:3]], 4), "\n")
cat("[info] best PM as LPM:", round(coef(lpm$m)[show[1:3]], 4), "\n\n")

cat(sprintf("RESULT:intl_attack_table4=%.6f\n", b4["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", b4["kill_16:female_pres"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", coef(r_like$m)["treatment1:time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", coef(r_like$m)["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", coef(r_like$m)["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", coef(r_bpm$m)["treatment1:time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", coef(r_bpm$m)["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", coef(r_bpm$m)["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", r_like$n))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", r_bpm$n))
