## Holman, Merolla & Zechmeister (2022, APSR) -- independent reproduction
## Table 2 (BES panel difference-in-differences) and Table 4 (global executive approval)
suppressMessages({library(haven); library(fixest)})
set.seed(42)
M <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-10-22-a/mount/holman_2022_theresa_may_rally"

## ---------------------------------------------------------------- Table 4
g <- as.data.frame(zap_labels(read_dta(file.path(M, "global_approval.dta"))))
# lag_approval at row t holds executive approval in quarter t+1 (checked on the
# series: US 2001Q3 row = post-9/11 2001Q4 peak; UK 2017Q2 row = post-election 2017Q3),
# i.e. approval in the quarter following the attack quarter.
# kill_16: international terrorist attack with 16+ (i.e. more than 15) deaths.
g$attack <- g$kill_16
t4 <- feols(lag_approval ~ attack * female_pres + growth + log_inflation + execrlc + election_qtr | country_code,
            data = g, vcov = "iid")
print(summary(t4))
b4 <- coef(t4)
cat("Table 4 N =", nobs(t4), " countries =", length(unique(g$country_code[obs(t4)])), "\n")

## ---------------------------------------------------------------- Table 2
d <- as.data.frame(zap_labels(read_dta(file.path(M, "did_data.dta"))))
ctrl <- c("white", "gender", "labour", "party_other", "income", "ideology2")
d <- d[, c("id", "wave", "time", "treatment1", "likeMayW", "bestPMW", ctrl)]
invisible(gc())

## Random-effects GLS (Stata xtreg, re; Swamy-Arora, harmonic-mean T for unbalanced panels)
re_gls <- function(df, y, base_wave, drop_wave) {
  df <- df[complete.cases(df[, c(y, "id", "wave", "time", "treatment1", ctrl)]), ]
  waves <- sort(unique(df$wave))
  keepw <- setdiff(waves, c(base_wave, drop_wave))   # drop_wave: collinear with time, omitted as Stata does
  X <- cbind(const = 1, attack = df$treatment1, time = df$time,
             sapply(keepw, function(w) as.numeric(df$wave == w)),
             as.matrix(df[, ctrl]), attack_x_time = df$treatment1 * df$time)
  colnames(X)[4:(3 + length(keepw))] <- paste0("wave", keepw)
  yv <- df[[y]]; id <- df$id
  N <- length(yv); Ti <- as.vector(table(id)[as.character(id)])
  n <- length(unique(id))
  gm <- function(v) ave(v, id)
  Xm <- apply(X, 2, gm); ym <- gm(yv)
  # within
  Xw <- X - Xm; yw <- yv - ym
  vw <- apply(Xw, 2, function(z) sum(z^2) > 1e-8)
  fw <- lm.fit(Xw[, vw, drop = FALSE], yw)
  Kw <- fw$rank
  s2e <- sum(fw$residuals^2) / (N - n - Kw)
  # between (one row per id)
  first <- !duplicated(id)
  fb <- lm.fit(Xm[first, , drop = FALSE], ym[first])
  Tg <- Ti[first]
  Tbar <- n / sum(1 / Tg)
  s2u <- max(0, sum(fb$residuals^2) / (n - fb$rank) - s2e / Tbar)
  theta <- 1 - sqrt(s2e / (Ti * s2u + s2e))
  Xs <- X - theta * Xm; ys <- yv - theta * ym
  f <- lm.fit(Xs, ys)
  e <- f$residuals
  XtXi <- chol2inv(qr.R(f$qr))[order(f$qr$pivot), order(f$qr$pivot)]
  se <- sqrt(diag(XtXi) * sum(e^2) / (N - f$rank))
  b <- f$coefficients
  names(se) <- names(b)
  list(b = b, se = se, N = N, n = n, s2e = s2e, s2u = s2u)
}

r_like <- re_gls(d, "likeMayW", base_wave = 9, drop_wave = 16)
r_pm   <- re_gls(d, "bestPMW",  base_wave = 7, drop_wave = 12)
for (r in list(r_like, r_pm)) {
  print(round(cbind(b = r$b, se = r$se), 4)); cat("N =", r$N, " ids =", r$n, " sigma_e =", sqrt(r$s2e), " sigma_u =", sqrt(r$s2u), "\n")
}

## pooled OLS versions for reference (not scored)
for (y in c("likeMayW", "bestPMW")) {
  f <- feols(as.formula(paste(y, "~ treatment1 * time + i(wave) +", paste(ctrl, collapse = "+"))), data = d, vcov = "iid")
  cat("pooled OLS", y, ": ", paste(names(coef(f))[c(1:3, length(coef(f)))], round(coef(f)[c(1:3, length(coef(f)))], 4), collapse = "; "), "\n")
}

cat("DEVIATION: Table 4 sample is all complete country-quarters in global_approval.dta (", nobs(t4), "), not 4,328 as reported; SEs printed are iid, not panel-corrected (coefficients unaffected).\n")
cat("DEVIATION: Table 2 estimated as random-effects GLS (xtreg re style) with wave dummies; the May best PM column is a linear probability model (reported magnitudes are LPM-scale), not logit.\n")

cat(sprintf("RESULT:intl_attack_table4=%.6f\n", b4["attack"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", b4["attack:female_pres"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(t4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", r_like$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", r_like$b["attack"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", r_like$b["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", r_pm$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", r_pm$b["attack"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", r_pm$b["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", r_like$N))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", r_pm$N))
