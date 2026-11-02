## Holman, Merolla & Zechmeister (2022) -- Table 2 (DiD, xtreg RE) and Table 4 (xtpcse psar1)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/holman-2022-theresa-may-rally/seeded/2026-10-22-a/mount/holman_2022_theresa_may_rally"

############################ Table 2 ############################
## Stata: xtset id wave; xtreg y i.treatment1##i.time i.wave $demographics
## xtreg without options = random-effects GLS (Swamy-Arora), conventional SEs.
demog <- c("white","gender","labour","party_other","income","ideology2")
d <- read_dta(file.path(D, "did_data.dta"),
              col_select = c(id, wave, likeMayW, bestPMW, treatment1, time, all_of(demog)))
d <- zap_labels(d)

xtreg_re <- function(df, y) {
  vars <- c(y, "treatment1", "time", "wave", demog, "id")
  s <- df[complete.cases(df[, vars]), vars]
  s <- as.data.frame(s)
  s$wave <- factor(s$wave)
  s$tt <- s$treatment1 * s$time
  ## regressor order mirrors Stata: treatment1, time, interaction, wave dummies, controls
  f <- as.formula(paste(y, "~ treatment1 + time + tt + wave +", paste(demog, collapse = " + ")))
  X <- model.matrix(f, s)
  ## drop collinear columns in order (as Stata does: later collinear dummy omitted)
  q <- qr(X); keep <- q$pivot[seq_len(q$rank)]; X <- X[, sort(keep), drop = FALSE]
  Y <- s[[y]]
  id <- s$id
  N <- nrow(X); K <- ncol(X)
  Ti <- ave(rep(1, N), id, FUN = sum)
  n <- length(unique(id))
  gm <- function(M) apply(as.matrix(M), 2, function(v) ave(v, id))
  Xbar <- gm(X); Ybar <- ave(Y, id)
  ## within regression
  Xw <- X[, -1, drop = FALSE] - Xbar[, -1, drop = FALSE]; Yw <- Y - Ybar
  qw <- qr(Xw); kw <- qw$rank
  ew <- qr.resid(qw, Yw)
  s2e <- sum(ew^2) / (N - n - kw)
  ## between regression (one obs per panel)
  first <- !duplicated(id)
  Xb <- Xbar[first, , drop = FALSE]; Yb <- Ybar[first]
  qb <- qr(Xb); eb <- qr.resid(qb, Yb)
  Tbar <- n / sum(1 / Ti[first])
  s2u <- max(0, sum(eb^2) / (n - qb$rank) - s2e / Tbar)
  theta <- 1 - sqrt(s2e / (Ti * s2u + s2e))
  Xs <- X - theta * Xbar; Ys <- Y - theta * Ybar
  fit <- lm.fit(Xs, Ys)
  b <- fit$coefficients
  cat(sprintf("[%s] N=%d n=%d sigma_e=%.4f sigma_u=%.4f\n", y, N, n, sqrt(s2e), sqrt(s2u)))
  print(round(b, 4))
  list(b = b, N = N)
}

r1 <- xtreg_re(d, "likeMayW")
r2 <- xtreg_re(d, "bestPMW")
rm(d); invisible(gc())

############################ Table 4 ############################
## Stata: xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth l(0/1).log_inflation
##        l(0/4).election_qtr i.execrlc i.country_code, cor(psar1) i
## Prais-Winsten FGLS with panel-specific AR(1) (rho from OLS residuals, rhotype regress).
g <- read_dta(file.path(D, "global_approval.dta")) %>% zap_labels() %>% as.data.frame()
g <- g[order(g$country_code, g$qtr), ]
tlag <- function(v, k) {
  # time-series lag by k quarters within country_code (respecting gaps)
  key <- paste(g$country_code, g$qtr)
  m <- match(paste(g$country_code, g$qtr - k), key)
  v[m]
}
g$growth_l1 <- tlag(g$growth, 1)
g$loginf_l1 <- tlag(g$log_inflation, 1)
for (k in 1:4) g[[paste0("elec_l", k)]] <- tlag(g$election_qtr, k)
g$kxf <- g$kill_16 * g$female_pres
xv <- c("kill_16","female_pres","kxf","growth","growth_l1","log_inflation","loginf_l1",
        "election_qtr", paste0("elec_l",1:4), "execrlc", "country_code")
s <- g[complete.cases(g[, c("lag_approval", xv)]), c("lag_approval", xv, "qtr")]
s$execrlc <- factor(s$execrlc); s$country_code <- factor(s$country_code)
cat("Table4 N =", nrow(s), " panels =", nlevels(droplevels(s$country_code)), "\n")
s <- droplevels(s)
f4 <- lag_approval ~ kill_16 + female_pres + kxf + growth + growth_l1 + log_inflation + loginf_l1 +
  election_qtr + elec_l1 + elec_l2 + elec_l3 + elec_l4 + execrlc + country_code
X <- model.matrix(f4, s); Y <- s$lag_approval
q <- qr(X); X <- X[, sort(q$pivot[seq_len(q$rank)]), drop = FALSE]
ols <- lm.fit(X, Y); e <- ols$residuals
pid <- s$country_code; tq <- s$qtr
## panel-specific rho: sum e_t e_{t-1} / sum e_{t-1}^2 over consecutive-quarter pairs
prev <- c(NA, head(seq_len(nrow(s)), -1))
consec <- c(FALSE, pid[-1] == pid[-nrow(s)] & tq[-1] == tq[-nrow(s)] + 1)
ngap <- sum(c(FALSE, pid[-1] == pid[-nrow(s)]) & !consec); cat("within-panel gaps in sample:", ngap, "\n")
rho <- tapply(seq_len(nrow(s)), pid, function(ix) {
  ix <- ix[consec[ix]]
  if (length(ix) == 0) return(0)
  sum(e[ix] * e[ix - 1]) / sum(e[ix - 1]^2)
})
cat("rho summary:\n"); print(summary(as.numeric(rho)))
rho <- pmax(pmin(rho, 1), -1)  # bound rho to [-1, 1]
cat("panels with |rho| bounded:", sum(abs(rho) >= 1), "\n")
r <- as.numeric(rho[as.character(pid)])
Xs <- X; Ys <- Y
for (i in seq_len(nrow(s))) {
  if (consec[i]) {
    Xs[i, ] <- X[i, ] - r[i] * X[i - 1, ]; Ys[i] <- Y[i] - r[i] * Y[i - 1]
  } else {
    w <- sqrt(1 - r[i]^2); Xs[i, ] <- w * X[i, ]; Ys[i] <- w * Y[i]
  }
}
pw <- lm.fit(Xs, Ys); b4 <- pw$coefficients
print(round(b4[c("(Intercept)","kill_16","female_pres","kxf")], 4))
cat("OLS for reference:\n"); print(round(ols$coefficients[c("kill_16","female_pres","kxf")], 4))

cat(sprintf("RESULT:intl_attack_table4=%.4f\n", b4["kill_16"]))
cat(sprintf("RESULT:intl_attack_x_woman_exec_table4=%.4f\n", b4["kxf"]))
cat(sprintf("RESULT:n_obs_table4=%d\n", nrow(s)))
cat(sprintf("RESULT:did_attack_x_time_like_may_table2=%.4f\n", r1$b["tt"]))
cat(sprintf("RESULT:did_attack_like_may_table2=%.4f\n", r1$b["treatment1"]))
cat(sprintf("RESULT:did_time_like_may_table2=%.4f\n", r1$b["time"]))
cat(sprintf("RESULT:did_attack_x_time_may_best_pm_table2=%.4f\n", r2$b["tt"]))
cat(sprintf("RESULT:did_attack_may_best_pm_table2=%.4f\n", r2$b["treatment1"]))
cat(sprintf("RESULT:did_time_may_best_pm_table2=%.4f\n", r2$b["time"]))
cat(sprintf("RESULT:n_obs_did_like_may_table2=%d\n", r1$N))
cat(sprintf("RESULT:n_obs_did_may_best_pm_table2=%d\n", r2$N))
