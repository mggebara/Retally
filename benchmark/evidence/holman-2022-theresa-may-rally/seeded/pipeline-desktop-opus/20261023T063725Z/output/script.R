suppressPackageStartupMessages({
  library(haven)
  library(data.table)
})
set.seed(42)

dd <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally"

results <- list()
emit <- function(name, val) {
  results[[name]] <<- val
}

tonum <- function(x) as.numeric(haven::zap_labels(x))

## ---------------------------------------------------------------------
## Table 4: xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth
##   l(0/1).log_inflation l(0/4).election_qtr i.execrlc i.country_code,
##   cor(psar1) independent   (Prais-Winsten FGLS, panel-specific AR1)
## ---------------------------------------------------------------------
tryCatch({
  ga <- haven::read_dta(file.path(dd, "global_approval.dta"))
  qv <- ga$qtr
  if (inherits(qv, "Date")) {
    lt <- as.POSIXlt(qv)
    qv <- (lt$year + 1900) * 4 + lt$mon %/% 3
  } else {
    qv <- tonum(qv)
  }
  g <- data.frame(
    lag_approval = tonum(ga$lag_approval),
    kill = tonum(ga$kill_16),
    fem = tonum(ga$female_pres),
    growth = tonum(ga$growth),
    linf = tonum(ga$log_inflation),
    elec = tonum(ga$election_qtr),
    execrlc = tonum(ga$execrlc),
    country_code = tonum(ga$country_code),
    qtr = qv
  )
  # choose panel identifier that uniquely identifies panel-time
  pid <- g$country_code
  if (any(duplicated(paste(pid, g$qtr)[!is.na(pid) & !is.na(g$qtr)])) && "ccode" %in% names(ga)) {
    pid2 <- tonum(ga$ccode)
    if (!any(duplicated(paste(pid2, g$qtr)[!is.na(pid2) & !is.na(g$qtr)]))) pid <- pid2
  }
  g$pid <- pid
  key <- paste(g$pid, g$qtr)
  lagv <- function(v, k) {
    idx <- match(paste(g$pid, g$qtr - k), key)
    out <- v[idx]
    out[is.na(g$pid) | is.na(g$qtr)] <- NA
    out
  }
  g$growth1 <- lagv(g$growth, 1)
  g$linf1 <- lagv(g$linf, 1)
  g$el1 <- lagv(g$elec, 1)
  g$el2 <- lagv(g$elec, 2)
  g$el3 <- lagv(g$elec, 3)
  g$el4 <- lagv(g$elec, 4)
  g$kxf <- g$kill * g$fem
  vars <- c("lag_approval", "kill", "fem", "kxf", "growth", "growth1", "linf", "linf1",
            "elec", "el1", "el2", "el3", "el4", "execrlc", "country_code", "pid", "qtr")
  s <- g[complete.cases(g[, vars]), vars]
  s <- s[order(s$pid, s$qtr), ]
  X <- model.matrix(~ kill + fem + kxf + growth + growth1 + linf + linf1 +
                      elec + el1 + el2 + el3 + el4 + factor(execrlc) + factor(country_code),
                    data = s)
  y <- s$lag_approval
  q <- qr(X)
  keep <- q$pivot[seq_len(q$rank)]
  keep <- sort(keep)
  X <- X[, keep, drop = FALSE]
  ols <- lm.fit(X, y)
  e <- ols$residuals
  # panel-specific rho (rhotype regress) and Prais-Winsten transform
  n <- nrow(s)
  prev_ok <- c(FALSE, s$pid[-1] == s$pid[-n] & (s$qtr[-1] - s$qtr[-n]) == 1)
  rho <- rep(0, n)
  for (p in unique(s$pid)) {
    ii <- which(s$pid == p)
    jj <- ii[prev_ok[ii]]
    if (length(jj) > 0) {
      den <- sum(e[jj - 1]^2)
      r <- if (den > 0) sum(e[jj] * e[jj - 1]) / den else 0
      r <- max(min(r, 0.9999), -0.9999)
      rho[ii] <- r
    }
  }
  Xs <- X
  ys <- y
  firsts <- which(!prev_ok)
  lagged <- which(prev_ok)
  ys[lagged] <- y[lagged] - rho[lagged] * y[lagged - 1]
  ys[firsts] <- sqrt(1 - rho[firsts]^2) * y[firsts]
  Xs[lagged, ] <- X[lagged, ] - rho[lagged] * X[lagged - 1, ]
  Xs[firsts, ] <- sqrt(1 - rho[firsts]^2) * X[firsts, ]
  pw <- lm.fit(Xs, ys)
  b <- pw$coefficients
  emit("intl_attack_table4", unname(b["kill"]))
  emit("intl_attack_x_woman_exec_table4", unname(b["kxf"]))
  emit("n_obs_table4", n)
}, error = function(err) message("Table 4 error: ", conditionMessage(err)))

## ---------------------------------------------------------------------
## Table 2: xtreg y i.treatment1##i.time i.wave $demographics  (RE, Swamy-Arora)
## ---------------------------------------------------------------------
ctrl <- c("white", "gender", "labour", "party_other", "income", "ideology2")
did <- NULL
tryCatch({
  did <- haven::read_dta(file.path(dd, "did_data.dta"),
                         col_select = c("id", "wave", "likeMayW", "bestPMW", "treatment1", "time",
                                        "white", "gender", "labour", "party_other", "income", "ideology2"))
}, error = function(err) {
  did <<- tryCatch(haven::read_dta(file.path(dd, "did_data.dta")), error = function(e2) NULL)
})

re_fit <- function(yvar) {
  d <- data.table(id = tonum(did$id), wave = tonum(did$wave), y = tonum(did[[yvar]]),
                  treatment1 = tonum(did$treatment1), time = tonum(did$time))
  for (v in ctrl) d[[v]] <- tonum(did[[v]])
  d <- d[complete.cases(d)]
  d[, tx := treatment1 * time]
  waves <- sort(unique(d$wave))
  wn <- character(0)
  for (w in waves[-1]) {
    nm <- paste0("w_", w)
    d[[nm]] <- as.numeric(d$wave == w)
    wn <- c(wn, nm)
  }
  xn <- c("treatment1", "time", "tx", ctrl, wn)
  X <- as.matrix(d[, ..xn])
  q <- qr(cbind(1, X))
  keep <- sort(q$pivot[seq_len(q$rank)])
  keep <- keep[keep > 1] - 1
  xn <- xn[keep]
  X <- X[, keep, drop = FALSE]
  y <- d$y
  id <- d$id
  N <- length(y)
  grp <- as.integer(factor(id))
  ng <- max(grp)
  Ti <- tabulate(grp, ng)
  gmean <- function(v) (rowsum(v, grp, reorder = TRUE)[, 1] / Ti)
  ybar <- gmean(y)
  Xbar <- apply(X, 2, gmean)
  if (is.null(dim(Xbar))) Xbar <- matrix(Xbar, nrow = ng)
  # within
  yw <- y - ybar[grp]
  Xw <- X - Xbar[grp, , drop = FALSE]
  wfit <- lm.fit(Xw, yw)
  ssr_w <- sum(wfit$residuals^2)
  K <- ncol(X) + 1
  sig_e2 <- ssr_w / (N - ng - K + 1)
  # between
  bfit <- lm.fit(cbind(1, Xbar), ybar)
  ssr_b <- sum(bfit$residuals^2)
  Tbar <- ng / sum(1 / Ti)
  sig_u2 <- max(0, ssr_b / (ng - K) - sig_e2 / Tbar)
  theta <- 1 - sqrt(sig_e2 / (Ti * sig_u2 + sig_e2))
  th <- theta[grp]
  ys <- y - th * ybar[grp]
  Xs <- cbind(`(Intercept)` = 1 - th, X - th * Xbar[grp, , drop = FALSE])
  fit <- lm.fit(Xs, ys)
  b <- fit$coefficients
  names(b) <- c("(Intercept)", xn)
  list(b = b, N = N)
}

if (!is.null(did)) {
  tryCatch({
    r1 <- re_fit("likeMayW")
    emit("did_attack_x_time_like_may_table2", unname(r1$b["tx"]))
    emit("did_attack_like_may_table2", unname(r1$b["treatment1"]))
    emit("did_time_like_may_table2", unname(r1$b["time"]))
    emit("n_obs_did_like_may_table2", r1$N)
  }, error = function(err) message("Table 2 like error: ", conditionMessage(err)))
  tryCatch({
    r2 <- re_fit("bestPMW")
    emit("did_attack_x_time_may_best_pm_table2", unname(r2$b["tx"]))
    emit("did_attack_may_best_pm_table2", unname(r2$b["treatment1"]))
    emit("did_time_may_best_pm_table2", unname(r2$b["time"]))
    emit("n_obs_did_may_best_pm_table2", r2$N)
  }, error = function(err) message("Table 2 bestPM error: ", conditionMessage(err)))
}

for (nm in names(results)) {
  v <- results[[nm]]
  if (!is.null(v) && length(v) == 1 && is.finite(v)) {
    cat(sprintf("RESULT:%s=%.6f\n", nm, v))
  }
}