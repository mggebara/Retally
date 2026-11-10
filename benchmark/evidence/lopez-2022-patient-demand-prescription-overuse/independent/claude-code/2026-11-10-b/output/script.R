# Independent reproduction: Lopez, Sautmann & Schaner (2022), Table 3
# y = b0 + bP*PV + bD*DV + date FE + post-double-selection-lasso controls,
# SEs clustered by clinic.
suppressMessages({library(haven); library(fixest)})
set.seed(42)
path <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- as.data.frame(zap_labels(read_dta(path)))

# analysis sample: patients included in main analysis
d <- d[!is.na(d$dropme) & d$dropme == 0, ]
cat("Analysis sample:", nrow(d), "\n")

d$clinic <- d$cscomnum_OS
d$datefe <- as.numeric(d$date_morning_survey)

# ---- candidate controls (pre-built in the analysis file) ----
nm <- names(d)
cc_main <- grep("^CC[0-9]+$", nm, value = TRUE)          # individual controls (+ missing dummies)
cc_int  <- grep("^CC[0-9]+xCC[0-9]+$", nm, value = TRUE)  # pairwise interactions
cl      <- grep("^CL[0-9]+$", nm, value = TRUE)           # clinic dummies
cands <- c(cl, cc_main, cc_int)
cat("Candidates: clinic", length(cl), " main", length(cc_main), " interactions", length(cc_int), "\n")

# ---- rigorous (BCH) lasso with cluster-robust penalty loadings ----
cd_lasso <- function(X, y, lam, psi, b0 = NULL, tol = 1e-9, maxit = 10000) {
  p <- ncol(X); b <- if (is.null(b0)) rep(0, p) else b0
  xx <- colSums(X^2); r <- y - X %*% b
  thr <- lam * psi / 2
  for (it in 1:maxit) {
    maxd <- 0
    for (j in 1:p) {
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- if (z > thr[j]) (z - thr[j]) / xx[j] else if (z < -thr[j]) (z + thr[j]) / xx[j] else 0
      if (nb != bj) { r <- r - X[, j] * (nb - bj); b[j] <- nb; maxd <- max(maxd, abs(nb - bj) * sqrt(xx[j])) }
    }
    if (maxd < tol) break
  }
  b
}
clpsi <- function(X, e, g) {
  S <- rowsum(X * as.vector(e), g)
  sqrt(colSums(S^2) / nrow(X))
}
rlasso_sel <- function(y, X, g, c = 1.1, maxiter = 15) {
  n <- nrow(X); p <- ncol(X); G <- length(unique(g))
  gamma <- 0.1 / log(G)
  lam <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  # initial residuals: OLS on 5 most correlated regressors
  cr <- abs(cor(X, y)); cr[is.na(cr)] <- 0
  top <- order(-cr)[1:5]
  e <- resid(lm.fit(X[, top, drop = FALSE], y))
  sel_old <- NULL; b <- NULL
  for (k in 1:maxiter) {
    psi <- clpsi(X, e, g)
    b <- cd_lasso(X, y, lam, psi, b0 = b)
    sel <- which(b != 0)
    if (length(sel) > 0) e <- resid(lm.fit(X[, sel, drop = FALSE], y)) else e <- y
    if (!is.null(sel_old) && identical(sel, sel_old)) break
    sel_old <- sel
  }
  sel
}
demean_by <- function(v, f) v - ave(v, f)

pds <- function(yvar, data) {
  dd <- data[!is.na(data[[yvar]]), ]
  f <- dd$datefe; g <- dd$clinic
  X <- as.matrix(dd[, cands]); X[is.na(X)] <- 0
  Xd <- apply(X, 2, demean_by, f = f)
  keep <- apply(Xd, 2, function(z) sd(z) > 1e-10)
  Xd <- Xd[, keep]
  # drop exactly duplicated columns
  Xd <- Xd[, !duplicated(round(t(Xd), 10))]
  yd <- demean_by(dd[[yvar]], f)
  pvd <- demean_by(dd$patient_voucher, f)
  dvd <- demean_by(dd$doctor_voucher, f)
  s1 <- rlasso_sel(yd, Xd, g); s2 <- rlasso_sel(pvd, Xd, g); s3 <- rlasso_sel(dvd, Xd, g)
  sel <- colnames(Xd)[sort(unique(c(s1, s2, s3)))]
  cat(yvar, ": selected", length(sel), "controls:", paste(sel, collapse = " "), "\n")
  fml <- if (length(sel) > 0) as.formula(paste(yvar, "~ patient_voucher + doctor_voucher +", paste(sel, collapse = "+"), "| datefe"))
         else as.formula(paste(yvar, "~ patient_voucher + doctor_voucher | datefe"))
  m <- feols(fml, data = dd, cluster = ~clinic)
  # no-controls benchmark (equation 1)
  m0 <- feols(as.formula(paste(yvar, "~ patient_voucher + doctor_voucher | datefe")), data = dd, cluster = ~clinic)
  cat(sprintf("  lasso: bP=%.4f (%.4f) bD=%.4f (%.4f) N=%d | no controls: bP=%.4f bD=%.4f\n",
              coef(m)[1], se(m)[1], coef(m)[2], se(m)[2], nobs(m), coef(m0)[1], coef(m0)[2]))
  m
}

outs <- c(voucher_used = "used_vouchers_admin",
          any_malaria_treatment_prescribed = "RXtreat_sev_simple_mal",
          any_malaria_treatment_purchased = "treat_sev_simple_mal",
          severe_malaria_treatment_prescribed = "RXtreat_severe_mal",
          severe_malaria_treatment_purchased = "treat_severe_mal")
cols <- c("col1", "col2", "col3", "col4", "col5")
res <- list()
for (i in seq_along(outs)) {
  cat("Control mean", outs[i], ":", mean(d[[outs[i]]][d$patient_voucher == 0 & d$doctor_voucher == 0], na.rm = TRUE), "\n")
  res[[i]] <- pds(outs[i], d)
}
for (i in seq_along(outs)) {
  m <- res[[i]]
  cat(sprintf("RESULT:%s_patient_voucher_table3_%s=%.6f\n", names(outs)[i], cols[i], coef(m)["patient_voucher"]))
  cat(sprintf("RESULT:%s_doctor_voucher_table3_%s=%.6f\n", names(outs)[i], cols[i], coef(m)["doctor_voucher"]))
}
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(res[[1]])))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", nobs(res[[2]])))
