# Lopez, Sautmann & Schaner (2022) -- Table 3: impacts on malaria treatment outcomes
# Independent reproduction: y = bP*PV + bD*DV + date FE + controls chosen by
# post-double-selection lasso (Belloni, Chernozhukov & Hansen 2014), date FE partialled
# out before the lasso; SEs clustered by clinic.
# Lasso: rigorous (plug-in) lasso, lassopack/rlasso style, with cluster-robust penalty
# loadings (clinic), c = 1.1, gamma = 0.1/log(N_clusters), post-lasso residuals for loadings.
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
P <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-c/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(P)
d <- as.data.frame(d[d$dropme == 0, ])   # analysis sample: 2055 in-clinic interviews

nm <- names(d)
cand <- c(grep("^CC[0-9]+$", nm, value = TRUE),            # patient/respondent controls (missings mean-coded + missing dummies)
          grep("^CC[0-9]+xCC[0-9]+$", nm, value = TRUE),   # pairwise interactions
          grep("^CL[0-9]+$", nm, value = TRUE))            # clinic dummies
cat("candidate controls:", length(cand), "\n")

# ---- rigorous lasso -------------------------------------------------------
cd_lasso <- function(X, y, pen, b0 = NULL, tol = 1e-10, maxit = 10000) {
  # minimise 0.5*||y - Xb||^2 + sum(pen_j |b_j|)
  p <- ncol(X); b <- if (is.null(b0)) rep(0, p) else b0
  xx <- colSums(X^2); r <- y - X %*% b
  for (it in 1:maxit) {
    maxd <- 0
    for (j in 1:p) {
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- sign(z) * max(abs(z) - pen[j], 0) / xx[j]
      if (nb != bj) { r <- r - X[, j] * (nb - bj); b[j] <- nb; maxd <- max(maxd, abs(nb - bj) * sqrt(xx[j])) }
    }
    if (maxd < tol) break
  }
  b
}
post_resid <- function(X, y, sel) {
  if (length(sel) == 0) return(y)
  as.numeric(lm.fit(X[, sel, drop = FALSE], y)$residuals)
}
loadings <- function(X, e, cl) {
  # cluster-robust: psi_j = sqrt( (1/n) sum_c (sum_{i in c} x_ij e_i)^2 )
  S <- rowsum(X * e, cl)
  sqrt(colSums(S^2) / nrow(X))
}
rlasso <- function(X, y, cl, c = 1.1, maxiter = 15, tol = 1e-8) {
  n <- nrow(X); p <- ncol(X); nclust <- length(unique(cl))
  gamma <- 0.1 / log(nclust)
  lambda <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  # initial residuals: OLS on the 5 regressors most correlated with y
  cr <- abs(cor(X, y)); cr[is.na(cr)] <- 0
  e <- post_resid(X, y, order(cr, decreasing = TRUE)[1:5])
  psi <- loadings(X, e, cl); b <- NULL
  for (k in 1:maxiter) {
    b <- cd_lasso(X, y, pen = lambda * psi / 2, b0 = b)
    sel <- which(b != 0)
    e <- post_resid(X, y, sel)
    psi_new <- loadings(X, e, cl)
    if (max(abs(psi_new - psi)) < tol) { psi <- psi_new; break }
    psi <- psi_new
  }
  b <- cd_lasso(X, y, pen = lambda * psi / 2, b0 = b)
  which(b != 0)
}
# partial out date fixed effects (and constant)
demean_by <- function(v, g) v - ave(v, g)

pds <- function(yvar, dat) {
  dat <- dat[!is.na(dat[[yvar]]), ]
  g <- dat$date_morning_survey; cl <- dat$cscomnum_OS
  X <- as.matrix(dat[, cand]); storage.mode(X) <- "double"
  Xt <- apply(X, 2, demean_by, g = g)
  keep <- apply(Xt, 2, function(v) var(v) > 1e-12)   # drop columns with no within-date variation
  Xt <- Xt[, keep, drop = FALSE]; cn <- colnames(Xt)
  yt <- demean_by(as.numeric(dat[[yvar]]), g)
  pt <- demean_by(as.numeric(dat$patient_voucher), g)
  dt <- demean_by(as.numeric(dat$doctor_voucher), g)
  s_y <- rlasso(Xt, yt, cl); s_p <- rlasso(Xt, pt, cl); s_d <- rlasso(Xt, dt, cl)
  sel <- cn[sort(unique(c(s_y, s_p, s_d)))]
  cat(yvar, ": selected", length(s_y), "(y)", length(s_p), "(PV)", length(s_d), "(DV); union", length(sel), ":", sel, "\n")
  rhs <- paste(c("patient_voucher", "doctor_voucher", sel), collapse = " + ")
  m <- feols(as.formula(paste(yvar, "~", rhs, "| date_morning_survey")), data = dat, cluster = ~cscomnum_OS)
  ct <- coeftable(m)
  cat(sprintf("  PV %.4f (%.4f)  DV %.4f (%.4f)  N=%d\n", ct["patient_voucher", 1], ct["patient_voucher", 2],
              ct["doctor_voucher", 1], ct["doctor_voucher", 2], nobs(m)))
  list(bP = unname(coef(m)["patient_voucher"]), bD = unname(coef(m)["doctor_voucher"]), n = nobs(m))
}

outs <- list(
  voucher_used = "used_vouchers_admin",
  any_malaria_treatment_prescribed = "RXtreat_sev_simple_mal",
  any_malaria_treatment_purchased = "treat_sev_simple_mal",
  severe_malaria_treatment_prescribed = "RXtreat_severe_mal",
  severe_malaria_treatment_purchased = "treat_severe_mal")
cols <- c(voucher_used = "col1", any_malaria_treatment_prescribed = "col2", any_malaria_treatment_purchased = "col3",
          severe_malaria_treatment_prescribed = "col4", severe_malaria_treatment_purchased = "col5")
res <- lapply(outs, pds, dat = d)

for (k in names(outs)) {
  cat(sprintf("RESULT:%s_patient_voucher_table3_%s=%.6f\n", k, cols[k], res[[k]]$bP))
  cat(sprintf("RESULT:%s_doctor_voucher_table3_%s=%.6f\n", k, cols[k], res[[k]]$bD))
}
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", res$voucher_used$n))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", res$any_malaria_treatment_prescribed$n))
