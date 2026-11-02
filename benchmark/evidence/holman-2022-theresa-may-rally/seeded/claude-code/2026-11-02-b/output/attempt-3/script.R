suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-11-02-b/mount/holman_2022_theresa_may_rally"

## ---------------- Table 4: xtpcse ..., cor(psar1) independent ----------------
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% arrange(country_code, qtr)
# the raw panel has no internal gaps (checked in an exploratory run), so row lags = time-series lags
g <- g %>% group_by(country_code) %>% mutate(
  L1growth = lag(growth), L1linf = lag(log_inflation),
  L1el = lag(election_qtr, 1), L2el = lag(election_qtr, 2), L3el = lag(election_qtr, 3), L4el = lag(election_qtr, 4)) %>% ungroup()
g$execrlc <- factor(g$execrlc); g$country_code <- factor(g$country_code)
vars <- c("lag_approval","kill_16","female_pres","growth","L1growth","log_inflation","L1linf","election_qtr","L1el","L2el","L3el","L4el","execrlc","country_code","qtr")
e <- g[complete.cases(g[, vars]), ]
e$country_code <- droplevels(e$country_code); e$execrlc <- droplevels(e$execrlc)
cat("Table 4 N =", nrow(e), " countries =", nlevels(e$country_code), "\n")
f4 <- lag_approval ~ kill_16 * female_pres + growth + L1growth + log_inflation + L1linf + election_qtr + L1el + L2el + L3el + L4el + execrlc + country_code
X <- model.matrix(f4, e); y <- e$lag_approval
ols <- lm.fit(X, y); keep <- !is.na(ols$coefficients); X <- X[, keep]
res <- y - X %*% ols$coefficients[keep]
# panel-specific rho: regression of e_t on e_{t-1} (consecutive quarters within the estimation sample)
e$res <- as.numeric(res)
e <- e %>% group_by(country_code) %>% mutate(cons = c(FALSE, diff(qtr) == 1), rl = ifelse(cons, lag(res), NA)) %>% ungroup()
rho <- e %>% group_by(country_code) %>% summarise(rho = sum(res * rl, na.rm = TRUE) / sum(rl^2, na.rm = TRUE))
cat("internal gaps in estimation sample:", sum(!e$cons) - nlevels(e$country_code), "\n")
cat("rho range:", range(rho$rho), " panels with |rho|>1:", sum(abs(rho$rho) > 1), "\n")
rho$rho <- pmax(pmin(rho$rho, 1), -1)  # truncate to [-1, 1]
r <- rho$rho[match(e$country_code, rho$country_code)]
Xs <- X; ys <- y
idx <- split(seq_len(nrow(e)), e$country_code)
for (p in idx) {
  for (j in seq_along(p)) {
    i <- p[j]
    if (j > 1 && e$cons[i]) { ys[i] <- y[i] - r[i] * y[p[j-1]]; Xs[i, ] <- X[i, ] - r[i] * X[p[j-1], ] }
    else { s <- sqrt(1 - r[i]^2); ys[i] <- y[i] * s; Xs[i, ] <- X[i, ] * s }
  }
}
pw <- lm.fit(Xs, ys); b4 <- pw$coefficients
u <- ys - Xs %*% b4
# PCSE with independent panels (panel heteroskedasticity only)
s2 <- tapply(as.numeric(u)^2, e$country_code, mean)
w <- s2[as.character(e$country_code)]
XtXi <- solve(crossprod(Xs)); V4 <- XtXi %*% crossprod(Xs * sqrt(w)) %*% XtXi
se4 <- sqrt(diag(V4))
r2 <- 1 - sum(u^2) / sum((ys - mean(ys))^2)
for (nm in c("kill_16", "kill_16:female_pres", "female_pres", "(Intercept)")) cat(sprintf("T4 %-22s b=%.4f se=%.4f\n", nm, b4[nm], se4[nm]))
cat("T4 R2 (transformed) =", r2, "\n")

## ---------------- Table 2: xtreg (random effects GLS, Swamy-Arora), wave dummies ----------------
d <- read_dta(file.path(D, "did_data.dta"), col_select = c(id, wave, time, treatment1, likeMayW, bestPMW, white, gender, labour, party_other, income, ideology2)) %>% zap_labels()
re_swar <- function(dv) {
  dd <- d[complete.cases(d[, c(dv, "treatment1", "time", "wave", "white", "gender", "labour", "party_other", "income", "ideology2", "id")]), ]
  dd <- dd[order(dd$id, dd$wave), ]
  dd$wave <- factor(dd$wave)
  X0 <- model.matrix(~ treatment1 * time + wave + white + gender + labour + party_other + income + ideology2, dd)
  # Stata ordering: treatment1, time, treatment1#time, wave dummies, controls; later collinear columns are omitted
  X0 <- X0[, c("(Intercept)", "treatment1", "time", "treatment1:time", grep("^wave", colnames(X0), value = TRUE), "white", "gender", "labour", "party_other", "income", "ideology2")]
  q <- qr(X0); X <- X0[, sort(q$pivot[seq_len(q$rank)])]
  cat(dv, ": omitted collinear:", setdiff(colnames(X0), colnames(X)), "\n")
  id <- dd$id; y <- dd[[dv]]
  Ti <- as.numeric(table(id)[as.character(id)])
  gm <- function(v) ave(v, id)
  Xbar <- apply(X, 2, gm); ybar <- gm(y)
  Xw <- (X - Xbar)[, -1, drop = FALSE]; yw <- y - ybar
  qw <- qr(Xw); kw <- qw$rank
  ssrw <- sum(qr.resid(qw, yw)^2)
  N <- length(y); n <- length(unique(id))
  s2e <- ssrw / (N - n - kw)
  first <- !duplicated(id)
  Xb <- Xbar[first, , drop = FALSE]; yb <- ybar[first]
  qb <- qr(Xb); ssrb <- sum(qr.resid(qb, yb)^2)
  Tbar <- n / sum(1 / Ti[first])
  s2u <- max(0, ssrb / (n - qb$rank) - s2e / Tbar)
  theta <- 1 - sqrt(s2e / (Ti * s2u + s2e))
  Xs <- X - theta * Xbar; ys <- y - theta * ybar
  fit <- lm.fit(Xs, ys); b <- fit$coefficients
  V <- s2e * solve(crossprod(Xs))
  se <- sqrt(diag(V))
  cat(sprintf("%s: N=%d n=%d s_e=%.4f s_u=%.4f theta range %.3f-%.3f\n", dv, N, n, sqrt(s2e), sqrt(s2u), min(theta), max(theta)))
  for (nm in c("treatment1:time", "treatment1", "time", "(Intercept)")) cat(sprintf("  %-16s b=%.4f se=%.4f\n", nm, b[nm], se[nm]))
  list(b = b, N = N)
}
m1 <- re_swar("likeMayW")
m2 <- re_swar("bestPMW")

cat(sprintf("RESULT:intl_attack_table4=%.6f\n", b4["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.6f\n", b4["kill_16:female_pres"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nrow(e)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.6f\n", m1$b["treatment1:time"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.6f\n", m1$b["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.6f\n", m1$b["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.6f\n", m2$b["treatment1:time"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.6f\n", m2$b["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.6f\n", m2$b["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", m1$N))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", m2$N))
