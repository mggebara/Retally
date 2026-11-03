suppressPackageStartupMessages({
  library(haven)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/holman_2022_theresa_may_rally"

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
  }
}

###########################################################################
# Table 4: xtpcse lag_approval c.kill_16##c.female_pres l(0/1).growth
#          l(0/1).log_inflation l(0/4).election_qtr i.execrlc i.country_code,
#          cor(psar1) independent
# Prais-Winsten with panel-specific AR(1); coefficients from the transformed OLS
###########################################################################
res4 <- tryCatch({
  g <- as.data.table(zap_labels(read_dta(file.path(base, "global_approval.dta"))))
  g[, cid := as.numeric(country_code)]
  g[, tt := as.numeric(qtr)]
  g <- g[!is.na(cid) & !is.na(tt)]
  keyall <- paste(g$cid, g$tt)
  lagv <- function(v, k) {
    idx <- match(paste(g$cid, g$tt - k), keyall)
    g[[v]][idx]
  }
  g[, growth_L1 := lagv("growth", 1)]
  g[, log_inflation_L1 := lagv("log_inflation", 1)]
  for (k in 1:4) g[, (paste0("election_qtr_L", k)) := lagv("election_qtr", k)]

  vars <- c("lag_approval", "kill_16", "female_pres", "growth", "growth_L1",
            "log_inflation", "log_inflation_L1", "election_qtr",
            paste0("election_qtr_L", 1:4), "execrlc", "cid", "tt")
  s <- g[complete.cases(g[, ..vars]), ..vars]
  setorder(s, cid, tt)
  s[, execrlcF := factor(execrlc)]
  s[, cidF := factor(cid)]

  fml <- ~ kill_16 * female_pres + growth + growth_L1 + log_inflation +
    log_inflation_L1 + election_qtr + election_qtr_L1 + election_qtr_L2 +
    election_qtr_L3 + election_qtr_L4 + execrlcF + cidF
  X <- model.matrix(fml, data = s)
  y <- s$lag_approval

  # Step 1: OLS residuals
  f0 <- lm.fit(X, y)
  e <- y - X[, !is.na(f0$coefficients), drop = FALSE] %*%
    f0$coefficients[!is.na(f0$coefficients)]
  e <- as.numeric(e)

  # previous period within the estimation sample
  skey <- paste(s$cid, s$tt)
  prev <- match(paste(s$cid, s$tt - 1), skey)

  # Step 2: panel-specific rho (regression of e_t on e_{t-1})
  rho_by <- tapply(seq_len(nrow(s)), s$cid, function(ii) {
    p <- prev[ii]
    ok <- !is.na(p)
    if (sum(ok) < 2) return(0)
    num <- sum(e[ii][ok] * e[p[ok]])
    den <- sum(e[p[ok]]^2)
    r <- if (den > 0) num / den else 0
    if (!is.finite(r)) r <- 0
    max(min(r, 0.9999), -0.9999)
  })
  rho <- as.numeric(rho_by[as.character(s$cid)])

  # Step 3: Prais-Winsten transform
  pw <- function(z) {
    z <- as.matrix(z)
    out <- z
    hasp <- !is.na(prev)
    out[hasp, ] <- z[hasp, , drop = FALSE] - rho[hasp] * z[prev[hasp], , drop = FALSE]
    out[!hasp, ] <- z[!hasp, , drop = FALSE] * sqrt(1 - rho[!hasp]^2)
    out
  }
  Xs <- pw(X)
  ys <- as.numeric(pw(y))
  f1 <- lm.fit(Xs, ys)
  cf <- f1$coefficients
  list(b_attack = cf["kill_16"], b_int = cf["kill_16:female_pres"],
       b_fem = cf["female_pres"], n = nrow(s))
}, error = function(err) { message("Table 4 error: ", conditionMessage(err)); NULL })

###########################################################################
# Table 2: xtreg y i.treatment1##i.time i.wave $demographics  (random effects,
# Swamy-Arora GLS, Stata default)
###########################################################################
demo <- c("white", "gender", "labour", "party_other", "income", "ideology2")

dd <- tryCatch({
  as.data.table(zap_labels(read_dta(file.path(base, "did_data.dta"),
    col_select = c("id", "wave", "treatment1", "time", "likeMayW", "bestPMW",
                   "white", "gender", "labour", "party_other", "income", "ideology2"))))
}, error = function(err) { message("DiD load error: ", conditionMessage(err)); NULL })

re_sa <- function(d, yv) {
  vars <- c(yv, "treatment1", "time", "wave", "id", demo)
  s <- d[complete.cases(d[, ..vars]), ..vars]
  s[, waveF := factor(wave)]
  fml <- as.formula(paste("~ treatment1 + time + waveF +",
                          paste(demo, collapse = " + "), "+ treatment1:time"))
  X <- model.matrix(fml, data = s)
  y <- s[[yv]]
  grp <- as.integer(factor(s$id))
  Ti <- tabulate(grp)
  n <- length(Ti)
  N <- nrow(s)
  Xm <- rowsum(X, grp, reorder = TRUE) / Ti
  ym <- as.numeric(rowsum(y, grp, reorder = TRUE)) / Ti

  # within regression
  Xw <- X[, -1, drop = FALSE] - Xm[grp, -1, drop = FALSE]
  yw <- y - ym[grp]
  fw <- lm.fit(Xw, yw)
  Kw <- fw$rank
  se2 <- sum(fw$residuals^2) / (N - n - Kw)

  # between regression
  fb <- lm.fit(Xm, ym)
  Kb <- fb$rank
  Tbar <- n / sum(1 / Ti)
  su2 <- sum(fb$residuals^2) / (n - Kb) - se2 / Tbar
  if (!is.finite(su2) || su2 < 0) su2 <- 0

  theta <- 1 - sqrt(se2 / (Ti * su2 + se2))
  Xr <- X - theta[grp] * Xm[grp, , drop = FALSE]
  yr <- y - theta[grp] * ym[grp]
  fr <- lm.fit(Xr, yr)
  cf <- fr$coefficients
  list(attack = cf["treatment1"], time = cf["time"],
       inter = cf["treatment1:time"], n = N)
}

did_like <- NULL; did_pm <- NULL
if (!is.null(dd)) {
  did_like <- tryCatch(re_sa(dd, "likeMayW"),
                       error = function(err) { message("DiD like error: ", conditionMessage(err)); NULL })
  did_pm <- tryCatch(re_sa(dd, "bestPMW"),
                     error = function(err) { message("DiD bestPM error: ", conditionMessage(err)); NULL })
}

###########################################################################
# Output
###########################################################################
if (!is.null(res4)) {
  emit("intl_attack_table4", res4$b_attack)
  emit("intl_attack_x_woman_exec_table4", res4$b_int)
  emit("n_obs_table4", res4$n)
}
if (!is.null(did_like)) {
  emit("did_attack_x_time_like_may_table2", did_like$inter)
  emit("did_attack_like_may_table2", did_like$attack)
  emit("did_time_like_may_table2", did_like$time)
  emit("n_obs_did_like_may_table2", did_like$n)
}
if (!is.null(did_pm)) {
  emit("did_attack_x_time_may_best_pm_table2", did_pm$inter)
  emit("did_attack_may_best_pm_table2", did_pm$attack)
  emit("did_time_may_best_pm_table2", did_pm$time)
  emit("n_obs_did_may_best_pm_table2", did_pm$n)
}