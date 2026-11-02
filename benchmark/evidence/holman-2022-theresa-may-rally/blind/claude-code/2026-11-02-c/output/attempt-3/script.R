# Retally independent, blind reproduction: holman-2022-theresa-may-rally
# Table 4 (global TSCS with panel-corrected SEs) and Table 2 (BES panel DiD with wave FE)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/blind/2026-11-02-c/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4 ----------------
# DV: lag_approval (labelled "Lagged approval"; it is missing in each panel's LAST quarter,
#     i.e. it is approval in the quarter following t, as the paper describes).
# Attack: kill_16 = international attack with 16+ (i.e. more than 15) deaths (60 country-quarters).
# Woman executive: female_pres. Controls: growth, log_inflation, execrlc, election_qtr.
# Country FE: country_code (panel id: country x office type). PCSE (Beck-Katz, Stata xtpcse default).
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels()
vars4 <- c("lag_approval","kill_16","female_pres","growth","log_inflation","execrlc","election_qtr","country_code","qtr")
g4 <- g[complete.cases(g[, vars4]), vars4] %>% arrange(country_code, qtr)
m4 <- lm(lag_approval ~ kill_16 * female_pres + growth + log_inflation + execrlc + election_qtr + factor(country_code), data = g4)

pcse_vcov <- function(model, panel, time) {
  X <- model.matrix(model); keep <- !is.na(coef(model)); X <- X[, keep, drop = FALSE]
  e <- residuals(model)
  P <- as.character(panel); Tm <- time
  ups <- sort(unique(P)); np <- length(ups)
  E <- matrix(NA_real_, nrow = length(unique(Tm)), ncol = np, dimnames = list(sort(unique(Tm)), ups))
  E[cbind(match(Tm, rownames(E)), match(P, ups))] <- e
  S <- matrix(0, np, np)
  for (i in 1:np) for (j in i:np) {
    ok <- !is.na(E[, i]) & !is.na(E[, j])
    if (sum(ok) > 0) { S[i, j] <- S[j, i] <- sum(E[ok, i] * E[ok, j]) / sum(ok) }
  }
  meat <- matrix(0, ncol(X), ncol(X))
  for (t in unique(Tm)) {
    idx <- which(Tm == t); pi <- match(P[idx], ups)
    Xt <- X[idx, , drop = FALSE]
    meat <- meat + t(Xt) %*% S[pi, pi, drop = FALSE] %*% Xt
  }
  bread <- solve(crossprod(X))
  bread %*% meat %*% bread
}
V4 <- pcse_vcov(m4, g4$country_code, g4$qtr)
se4 <- sqrt(diag(V4))
cat("Table 4 (PCSE):\n")
for (k in c("kill_16","female_pres","kill_16:female_pres","(Intercept)"))
  cat(sprintf("  %-22s b=%.4f se=%.4f\n", k, coef(m4)[k], se4[k]))
cat("  N =", nobs(m4), " panels =", length(unique(g4$country_code)), " R2 =", round(summary(m4)$r.squared, 5), "\n")

## ---------------- Table 2 ----------------
# BES panel (did_data, long by respondent-wave). Treatment: treatment1 (= surveyed after the
# Manchester attack in wave 12; time-invariant per respondent). time = 1 for waves >= 12.
# Wave FE; since time is a linear combination of wave dummies, the last collinear wave dummy is
# omitted (as Stata's collinearity rule would do when time precedes i.wave), so Time is identified.
# Controls: white, gender, labour, party_other, income, ideology2 (ideology with missing set to
# the scale midpoint, per footnote 8).  Like May: OLS; May best PM: logit on bestPMW (1 May, 0 Corbyn).
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c("id","wave","time","treatment1","likeMayW","bestPMW",
                             "white","gender","labour","party_other","income","ideology2")) %>% zap_labels()
ctrl <- c("white","gender","labour","party_other","income","ideology2")

run_did <- function(dv, logit = FALSE) {
  dd <- d %>% filter(!is.na(.data[[dv]]))
  dd <- dd[complete.cases(dd[, c(dv, "treatment1", "time", "wave", ctrl)]), ]
  if (dv == "likeMayW") dd <- dd %>% filter(.data[[dv]] <= 10)
  waves <- sort(unique(dd$wave))
  # wave dummies: base = first wave; drop the last wave dummy (collinear with time)
  wd <- waves[-c(1, length(waves))]
  for (w in wd) dd[[paste0("w", w)]] <- as.numeric(dd$wave == w)
  f <- as.formula(paste(dv, "~ treatment1 * time +", paste(paste0("w", wd), collapse = " + "),
                        "+", paste(ctrl, collapse = " + ")))
  m <- if (logit) glm(f, data = dd, family = binomial()) else lm(f, data = dd)
  V <- vcovCL(m, cluster = ~id)
  cat(sprintf("Table 2 %s (%s), waves %s\n", dv, if (logit) "logit" else "OLS", paste(waves, collapse = ",")))
  print(coeftest(m, vcov. = V)[c("treatment1:time","treatment1","time","(Intercept)"), ])
  cat("  N =", nobs(m), "\n")
  list(m = m, n = nobs(m))
}
r_like <- run_did("likeMayW")
r_pm   <- run_did("bestPMW", logit = TRUE)

cat(sprintf("RESULT:intl_attack_table4=%.6f\n", coef(m4)["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", coef(m4)["kill_16:female_pres"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nobs(m4)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", coef(r_like$m)["treatment1:time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", coef(r_like$m)["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", coef(r_like$m)["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", coef(r_pm$m)["treatment1:time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", coef(r_pm$m)["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", coef(r_pm$m)["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", r_like$n))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", r_pm$n))
