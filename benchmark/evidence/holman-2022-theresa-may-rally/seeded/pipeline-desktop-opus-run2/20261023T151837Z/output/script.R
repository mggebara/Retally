suppressPackageStartupMessages({
  library(haven)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally"
num <- function(x) as.numeric(haven::zap_labels(x))

emit <- function(name, val) {
  if (is.null(val) || length(val) == 0 || is.na(val)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

results <- list()

##############################################################################
## Table 4: xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth
##   l(0/1).log_inflation l(0/4).election_qtr i.execrlc i.country_code,
##   cor(psar1) independent
## Prais-Winsten with panel-specific AR(1); coefficients from the transformed OLS
##############################################################################
tab4 <- tryCatch({
  ga <- as.data.table(read_dta(file.path(base, "global_approval.dta")))
  qv <- ga[["qtr"]]
  if (is.character(qv)) {
    yr <- as.numeric(substr(qv, 1, 4)); qq <- as.numeric(sub(".*[qQ]", "", qv))
    tq <- (yr - 1960) * 4 + qq - 1
  } else {
    tq <- num(qv)
  }
  g <- data.table(
    cc = num(ga[["country_code"]]), t = tq,
    y = num(ga[["lag_approval"]]), k = num(ga[["kill_16"]]),
    f = num(ga[["female_pres"]]), gr = num(ga[["growth"]]),
    li = num(ga[["log_inflation"]]), el = num(ga[["election_qtr"]]),
    ex = num(ga[["execrlc"]])
  )
  g <- g[!is.na(cc) & !is.na(t)]
  keyv <- paste(g$cc, g$t)
  lagf <- function(v, k) v[match(paste(g$cc, g$t - k), keyv)]
  g[, gr1 := lagf(gr, 1)]
  g[, li1 := lagf(li, 1)]
  g[, el1 := lagf(el, 1)]
  g[, el2 := lagf(el, 2)]
  g[, el3 := lagf(el, 3)]
  g[, el4 := lagf(el, 4)]
  vars <- c("y", "k", "f", "gr", "gr1", "li", "li1", "el", "el1", "el2", "el3", "el4", "ex", "cc")
  d <- g[complete.cases(g[, ..vars])]
  setorder(d, cc, t)
  d[, kf := k * f]
  X <- model.matrix(~ k + f + kf + gr + gr1 + li + li1 + el + el1 + el2 + el3 + el4 +
                      factor(ex) + factor(cc), data = d)
  y <- d$y
  f0 <- lm.fit(X, y)
  keep <- !is.na(f0$coefficients)
  X <- X[, keep, drop = FALSE]
  f0 <- lm.fit(X, y)
  e <- f0$residuals
  dkey <- paste(d$cc, d$t)
  prev <- match(paste(d$cc, d$t - 1), dkey)
  has <- !is.na(prev)
  num_r <- tapply(ifelse(has, e * e[ifelse(has, prev, 1)], 0), d$cc, sum)
  den_r <- tapply(ifelse(has, e[ifelse(has, prev, 1)]^2, 0), d$cc, sum)
  rho_p <- ifelse(den_r > 0, num_r / den_r, 0)
  rho_p <- pmax(pmin(rho_p, 0.9999), -0.9999)
  rho <- as.numeric(rho_p[as.character(d$cc)])
  Z <- X; yz <- y
  idx <- which(has)
  Z[idx, ] <- X[idx, , drop = FALSE] - rho[idx] * X[prev[idx], , drop = FALSE]
  yz[idx] <- y[idx] - rho[idx] * y[prev[idx]]
  idx0 <- which(!has)
  sc <- sqrt(1 - rho[idx0]^2)
  Z[idx0, ] <- X[idx0, , drop = FALSE] * sc
  yz[idx0] <- y[idx0] * sc
  f1 <- lm.fit(Z, yz)
  cf <- f1$coefficients
  list(attack = cf[["k"]], inter = cf[["kf"]], n = nrow(d))
}, error = function(err) { message("Table 4 error: ", conditionMessage(err)); NULL })

if (!is.null(tab4)) {
  results$intl_attack_table4 <- tab4$attack
  results$intl_attack_x_woman_exec_table4 <- tab4$inter
  results$n_obs_table4 <- tab4$n
}

##############################################################################
## Table 2: xtreg y i.treatment1##i.time i.wave $demographics  (random effects,
## Swamy-Arora GLS as in Stata's default xtreg, re)
##############################################################################
dem <- c("white", "gender", "labour", "party_other", "income", "ideology2")
dd <- tryCatch({
  x <- as.data.table(read_dta(file.path(base, "did_data.dta"),
    col_select = c("id", "wave", "likeMayW", "bestPMW", "treatment1", "time",
                   "white", "gender", "labour", "party_other", "income", "ideology2")))
  for (v in names(x)) set(x, j = v, value = num(x[[v]]))
  x
}, error = function(err) { message("did_data error: ", conditionMessage(err)); NULL })

re_fit <- function(dd, yv) {
  cols <- c(yv, "id", "wave", "treatment1", "time", dem)
  s <- dd[complete.cases(dd[, ..cols])]
  setorder(s, id, wave)
  y <- s[[yv]]
  trl <- sort(unique(s$treatment1)); tml <- sort(unique(s$time))
  tr <- as.numeric(s$treatment1 != trl[1])
  tm <- as.numeric(s$time != tml[1])
  waves <- sort(unique(s$wave))
  W <- sapply(waves[-1], function(w) as.numeric(s$wave == w))
  W <- matrix(W, nrow = nrow(s))
  colnames(W) <- paste0("wave", waves[-1])
  D <- as.matrix(s[, ..dem])
  X <- cbind(`(Intercept)` = 1, treatment1 = tr, time = tm, `treatment1:time` = tr * tm, W, D)
  f0 <- lm.fit(X, y)
  X <- X[, !is.na(f0$coefficients), drop = FALSE]
  K <- ncol(X)
  N <- nrow(X)
  ids <- sort(unique(s$id))
  gi <- match(s$id, ids)
  Ti <- as.numeric(tabulate(gi, nbins = length(ids)))
  n <- length(ids)
  gmX <- rowsum(X, gi, reorder = TRUE) / Ti
  gmy <- as.numeric(rowsum(y, gi, reorder = TRUE)) / Ti
  # within
  Xw <- X[, -1, drop = FALSE] - gmX[gi, -1, drop = FALSE]
  yw <- y - gmy[gi]
  fw <- lm.fit(Xw, yw)
  ssr_w <- sum(fw$residuals^2)
  # between
  fb <- lm.fit(gmX, gmy)
  ssr_b <- sum(fb$residuals^2)
  Tbar <- n / sum(1 / Ti)
  s2e <- ssr_w / (N - n - K + 1)
  s2u <- ssr_b / (n - K) - s2e / Tbar
  if (!is.finite(s2u) || s2u < 0) s2u <- 0
  theta <- 1 - sqrt(s2e / (Ti * s2u + s2e))
  th <- theta[gi]
  Xs <- X - th * gmX[gi, , drop = FALSE]
  ys <- y - th * gmy[gi]
  fg <- lm.fit(Xs, ys)
  cf <- fg$coefficients
  list(cf = cf, n = N)
}

if (!is.null(dd)) {
  # best PM: ensure 1 = May, 0 = Corbyn
  bp <- dd$bestPMW
  ub <- sort(unique(bp[!is.na(bp)]))
  if (!all(ub %in% c(0, 1))) {
    if (all(c(1, 2) %in% ub)) {
      dd[, bestPMW := ifelse(bestPMW == 1, 1, ifelse(bestPMW == 2, 0, NA_real_))]
    }
  }
  r1 <- tryCatch(re_fit(dd, "likeMayW"), error = function(err) { message("RE like: ", conditionMessage(err)); NULL })
  if (!is.null(r1)) {
    results$did_attack_x_time_like_may_table2 <- r1$cf[["treatment1:time"]]
    results$did_attack_like_may_table2 <- r1$cf[["treatment1"]]
    results$did_time_like_may_table2 <- r1$cf[["time"]]
    results$n_obs_did_like_may_table2 <- r1$n
  }
  r2 <- tryCatch(re_fit(dd, "bestPMW"), error = function(err) { message("RE bestpm: ", conditionMessage(err)); NULL })
  if (!is.null(r2)) {
    results$did_attack_x_time_may_best_pm_table2 <- r2$cf[["treatment1:time"]]
    results$did_attack_may_best_pm_table2 <- r2$cf[["treatment1"]]
    results$did_time_may_best_pm_table2 <- r2$cf[["time"]]
    results$n_obs_did_may_best_pm_table2 <- r2$n
  }
}

nm <- c("intl_attack_table4", "intl_attack_x_woman_exec_table4", "n_obs_table4",
        "did_attack_x_time_like_may_table2", "did_attack_like_may_table2",
        "did_time_like_may_table2", "did_attack_x_time_may_best_pm_table2",
        "did_attack_may_best_pm_table2", "did_time_may_best_pm_table2",
        "n_obs_did_like_may_table2", "n_obs_did_may_best_pm_table2")
for (k in nm) emit(k, results[[k]])