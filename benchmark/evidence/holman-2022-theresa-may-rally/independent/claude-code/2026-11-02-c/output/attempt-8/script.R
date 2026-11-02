# Independent reproduction: Holman, Merolla & Zechmeister (2022), Table 2 and Table 4
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich)})
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/independent/2026-11-02-c/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4: global executive approval ----------------
# DV: executive approval in the quarter following the attack (lag_approval, aligned to the
# attack quarter in the posted file); attack = international attack with 16+ deaths (kill_16);
# woman executive = female_pres; controls: GDP (growth), logged inflation, DPI executive
# left-center-right (execrlc), election; country fixed effects; OLS coefficients with
# Beck-Katz panel-corrected SEs (xtpcse default, independent errors within panel).
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels()
vars <- c("lag_approval", "kill_16", "female_pres", "growth", "log_inflation", "execrlc", "election_qtr", "country_code", "qtr")
s <- g[complete.cases(g[, vars]), vars] %>% arrange(country_code, qtr)
s$attack_x_woman <- s$kill_16 * s$female_pres
s$growth <- s$growth / 1e6  # rescale GDP for numerical conditioning (coefficient scale only)
m4 <- lm(lag_approval ~ kill_16 + female_pres + attack_x_woman + growth + log_inflation + execrlc + election_qtr + factor(country_code), data = s)
# Panel-corrected SEs (pairwise contemporaneous covariance)
pcse <- function(m, unit, time) {
  X <- model.matrix(m); X <- X[, !is.na(coef(m)), drop = FALSE]; e <- resid(m)
  units <- sort(unique(unit)); times <- sort(unique(time))
  E <- matrix(NA, length(times), length(units))
  E[cbind(match(time, times), match(unit, units))] <- e
  S <- matrix(0, length(units), length(units))
  for (i in seq_along(units)) for (j in i:length(units)) {
    ok <- !is.na(E[, i]) & !is.na(E[, j])
    if (sum(ok) > 0) S[i, j] <- S[j, i] <- sum(E[ok, i] * E[ok, j]) / sum(ok)
  }
  meat <- matrix(0, ncol(X), ncol(X))
  ui <- match(unit, units)
  for (t in times) {
    idx <- which(time == t)
    Xt <- X[idx, , drop = FALSE]; St <- S[ui[idx], ui[idx], drop = FALSE]
    meat <- meat + t(Xt) %*% St %*% Xt
  }
  B <- solve(crossprod(X))
  B %*% meat %*% B
}
V4 <- pcse(m4, s$country_code, s$qtr)
se4 <- sqrt(diag(V4))
cat("Table 4 (OLS, country FE, PCSE)\n")
print(round(cbind(b = coef(m4)[c("kill_16", "female_pres", "attack_x_woman")], se = se4[c("kill_16", "female_pres", "attack_x_woman")]), 3))
cat("N =", nobs(m4), " R2 =", summary(m4)$r.squared, " countries =", length(unique(s$country_code)), "\n")

## ---------------- Table 2: BES panel difference-in-differences ----------------
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c("id", "wave", "likeMayW", "bestPMW", "treatment1", "time", "white", "gender", "labour", "party_other", "income", "ideology2")) %>% zap_labels()
ctrl <- c("white", "gender", "labour", "party_other", "income", "ideology2")
did <- function(y) {
  dd <- d[complete.cases(d[, c(y, "treatment1", "time", "wave", ctrl)]), ]
  dd$attack_x_time <- dd$treatment1 * dd$time
  # wave dummies listed after time so that, as in Stata, the collinear (last) wave dummy is omitted
  W <- model.matrix(~ factor(wave), dd)[, -1, drop = FALSE]
  colnames(W) <- paste0("w", sort(unique(dd$wave))[-1])
  dd <- cbind(as.data.frame(dd), W)
  f <- as.formula(paste(y, "~ attack_x_time + treatment1 + time +", paste(colnames(W), collapse = " + "), "+", paste(ctrl, collapse = " + ")))
  m <- lm(f, data = dd)
  V <- vcovCL(m, cluster = ~id, type = "HC1")
  b <- coef(m); se <- rep(NA, length(b)); names(se) <- names(b); se[!is.na(b)] <- sqrt(diag(V))
  cat("\nTable 2,", y, "(OLS, wave dummies, controls; SE clustered by respondent)\n")
  print(round(cbind(b = b, se = se), 4))
  cat("N =", nobs(m), "\n")
  list(b = b, n = nobs(m))
}
r_like <- did("likeMayW")
r_best <- did("bestPMW")

cat("\n")
cat(sprintf("RESULT:intl_attack_table4=%.6f\n", coef(m4)["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", coef(m4)["attack_x_woman"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", r_like$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", r_like$b["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", r_like$b["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", r_best$b["attack_x_time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", r_best$b["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", r_best$b["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", r_like$n))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", r_best$n))
