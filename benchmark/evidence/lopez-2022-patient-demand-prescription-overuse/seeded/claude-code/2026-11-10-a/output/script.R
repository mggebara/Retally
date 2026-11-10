# Reproduction of Lopez, Sautmann & Schaner (2022), Table 3
# Follows LSS_master_data_analysis.do / docpat_theory_lso in LSS_TablePrograms.do:
#   pdslasso y patient_voucher doctor_voucher (DD1-DD35 CL1-CL59 CC*), clu(cscomnum) partial(DD1-DD35)
# pdslasso/rlasso (lassopack) is re-implemented here: rigorous (plug-in) cluster-robust lasso,
# date dummies + constant partialled out (unpenalized), post-double-selection OLS with
# date dummies and clinic-clustered SEs.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

p <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(p)
d <- as.data.frame(zap_labels(d))
d <- d[d$dropme != 1, ]
nm <- names(d)
DD <- paste0("DD", 1:35)
CL <- paste0("CL", 1:59)
CC <- grep("^CC", nm, value = TRUE)          # Stata CC* wildcard
pen <- c(CL, CC)                               # penalized candidate controls
clu_var <- "cscomnum_OS"                       # Stata abbreviation cscomnum -> cscomnum_OS

# ---------- rigorous lasso (lassopack rlasso defaults) ----------
cd_lasso <- function(G, xy, lam_j, b0 = NULL, tol = 1e-12, maxit = 100000) {
  # minimize ||y - Xb||^2 + sum_j lam_j |b_j|  using Gram matrix G = X'X, xy = X'y
  p <- length(xy); b <- if (is.null(b0)) rep(0, p) else b0
  dg <- diag(G)
  grad <- xy - G %*% b  # X'(y - Xb)
  grad <- as.vector(grad)
  for (it in 1:maxit) {
    maxd <- 0
    for (j in seq_len(p)) {
      if (dg[j] <= 0) next
      z <- grad[j] + dg[j] * b[j]
      t <- lam_j[j] / 2
      nb <- if (z > t) (z - t) / dg[j] else if (z < -t) (z + t) / dg[j] else 0
      delta <- nb - b[j]
      if (delta != 0) {
        grad <- grad - G[, j] * delta
        b[j] <- nb
        maxd <- max(maxd, abs(delta) * sqrt(dg[j]))
      }
    }
    if (maxd < tol) break
  }
  b
}

clu_psi <- function(X, e, cl, N) {
  S <- rowsum(X * e, cl)           # cluster sums of x_ij e_i
  sqrt(colSums(S^2) / N)
}

rlasso_sel <- function(y, X, cl, c = 1.1, maxpsiiter = 2) {
  # y, X already partialled (date FE + constant)
  N <- length(y); pp <- ncol(X); Ncl <- length(unique(cl))
  gamma <- 0.1 / log(Ncl)
  lambda <- 2 * c * sqrt(N) * qnorm(1 - gamma / (2 * pp))
  G <- crossprod(X); xy <- as.vector(crossprod(X, y))
  # initial residuals: OLS on 5 regressors most correlated with y
  cors <- suppressWarnings(abs(cor(X, y)))
  cors[is.na(cors)] <- 0
  top <- order(-cors)[1:5]
  e <- resid(lm.fit(X[, top, drop = FALSE], y))
  b <- NULL
  for (k in 1:maxpsiiter) {
    psi <- clu_psi(X, e, cl, N)
    b <- cd_lasso(G, xy, lambda * psi, b0 = b)
    sel <- which(b != 0)
    if (length(sel) > 0) e <- resid(lm.fit(X[, sel, drop = FALSE], y)) else e <- y
  }
  colnames(X)[which(b != 0)]
}

partial_out <- function(M, Z) {  # residualize columns of M on Z (incl. constant)
  qrZ <- qr(Z)
  M - qr.fitted(qrZ, M)
}

pdslasso <- function(dat, yv, dv = c("patient_voucher", "doctor_voucher")) {
  s <- dat[complete.cases(dat[, c(yv, dv, DD, pen, clu_var)]), ]
  Z <- cbind(1, as.matrix(s[, DD]))
  X <- partial_out(as.matrix(s[, pen]), Z)
  # drop controls that are constant after partialling
  keep <- colSums(X^2) > 1e-10
  X <- X[, keep, drop = FALSE]
  cl <- s[[clu_var]]
  sel <- character(0)
  for (v in c(yv, dv)) {
    yy <- as.vector(partial_out(matrix(as.numeric(s[[v]])), Z))
    sv <- rlasso_sel(yy, X, cl)
    sel <- union(sel, sv)
  }
  f <- as.formula(paste(yv, "~", paste(c(dv, DD, sel), collapse = " + ")))
  m <- feols(f, data = s, cluster = s[[clu_var]])
  list(m = m, sel = sel, N = nobs(m))
}

outs <- c(used_vouchers_admin = "voucher_used",
          RXtreat_sev_simple_mal = "any_malaria_treatment_prescribed",
          treat_sev_simple_mal = "any_malaria_treatment_purchased",
          RXtreat_severe_mal = "severe_malaria_treatment_prescribed",
          treat_severe_mal = "severe_malaria_treatment_purchased")
cols <- c("col1", "col2", "col3", "col4", "col5")
res <- list(); Ns <- c()
for (i in seq_along(outs)) {
  yv <- names(outs)[i]
  r <- pdslasso(d, yv)
  cf <- coef(r$m); se <- sqrt(diag(vcov(r$m)))
  cat(sprintf("%s: N=%d, selected=%d [%s]\n  PV=%.4f (%.4f)  DV=%.4f (%.4f)\n", yv, r$N, length(r$sel),
              paste(r$sel, collapse = " "), cf["patient_voucher"], se["patient_voucher"],
              cf["doctor_voucher"], se["doctor_voucher"]))
  res[[paste0(outs[i], "_patient_voucher_table3_", cols[i])]] <- cf["patient_voucher"]
  res[[paste0(outs[i], "_doctor_voucher_table3_", cols[i])]] <- cf["doctor_voucher"]
  Ns[i] <- r$N
}
for (k in names(res)) cat(sprintf("RESULT:%s=%.6f\n", k, res[[k]]))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", Ns[1]))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", Ns[2]))
