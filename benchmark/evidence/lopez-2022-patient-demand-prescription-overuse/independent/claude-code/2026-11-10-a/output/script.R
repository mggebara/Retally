# Independent reproduction of Lopez, Sautmann & Schaner (2022), Table 3.
# y_ict = b0 + bP PV_ct + bD DV_ct + gamma_t + x_ict'a + e_ict
# Date FE (DD dummies) partialled out; additional controls chosen by
# post-double-selection lasso (Belloni, Chernozhukov & Hansen 2014) with a
# rigorous (plug-in) penalty and clinic-cluster-robust penalty loadings,
# implemented here by hand (no glmnet/hdm in the sandbox).
# Final OLS of y on PV, DV, date FE and the union of selected controls,
# SE clustered by clinic.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

path <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(path)
d <- zap_labels(d)
d <- as.data.frame(d[!is.na(d$dropme) & d$dropme == 0, ])
cat("Analysis sample (dropme==0):", nrow(d), "\n")

nm <- names(d)
dd_vars <- grep("^DD[0-9]+$", nm, value = TRUE)                      # date dummies (partialled out)
cc_main <- grep("^CC[0-9]+$", nm, value = TRUE)                      # individual controls (missings mean-coded + dummies)
cc_int  <- grep("^CC[0-9]+xCC[0-9]+$", nm, value = TRUE)             # pairwise interactions
cl_vars <- grep("^CL[0-9]+$", nm, value = TRUE)                      # clinic dummies
cand <- c(cc_main, cc_int, cl_vars)
cat("Candidate controls:", length(cand), "(main", length(cc_main), ", interactions", length(cc_int), ", clinic", length(cl_vars), ")\n")

clus_all <- d$cscomnum_OS

# ---------------- rigorous lasso (rlasso-style) ----------------
partial_out <- function(M, Z) {
  # residualise columns of M on Z (Z includes constant)
  qrZ <- qr(Z)
  qr.resid(qrZ, M)
}

lasso_cd <- function(G, b_xy, pen, beta0 = NULL, maxit = 10000, tol = 1e-10) {
  # minimise ||y - X b||^2 + sum(pen_j |b_j|), using Gram matrix G = X'X, b_xy = X'y
  p <- length(b_xy)
  beta <- if (is.null(beta0)) rep(0, p) else beta0
  diagG <- diag(G)
  grad <- b_xy - as.vector(G %*% beta)   # X'r
  for (it in 1:maxit) {
    maxch <- 0
    for (j in 1:p) {
      if (diagG[j] <= 0) next
      rho <- grad[j] + diagG[j] * beta[j]
      thr <- pen[j] / 2
      nb <- if (rho > thr) (rho - thr) / diagG[j] else if (rho < -thr) (rho + thr) / diagG[j] else 0
      delta <- nb - beta[j]
      if (delta != 0) {
        grad <- grad - G[, j] * delta
        beta[j] <- nb
        maxch <- max(maxch, abs(delta) * sqrt(diagG[j]))
      }
    }
    if (maxch < tol) break
  }
  beta
}

rlasso_select <- function(y, X, clus, c0 = 1.1, maxpsiiter = 15, psitol = 1e-5) {
  n <- nrow(X); p <- ncol(X)
  ng <- length(unique(clus))
  gamma <- 0.1 / log(ng)
  lambda <- 2 * c0 * sqrt(n) * qnorm(1 - gamma / (2 * p))
  G <- crossprod(X); b_xy <- as.vector(crossprod(X, y))
  cl_index <- split(seq_len(n), clus)
  loadings <- function(e) {
    S <- rowsum(X * e, clus)               # ng x p : sum_i in g of x_ij e_i
    sqrt(colSums(S^2) / n)
  }
  # initial residuals: OLS on the 5 regressors most correlated with y
  cors <- abs(suppressWarnings(cor(X, y)))
  cors[is.na(cors)] <- 0
  top <- order(cors, decreasing = TRUE)[1:min(5, p)]
  e <- as.vector(lm.fit(X[, top, drop = FALSE], y)$residuals)
  psi <- loadings(e)
  beta <- rep(0, p)
  for (k in 1:maxpsiiter) {
    beta <- lasso_cd(G, b_xy, lambda * psi, beta0 = beta)
    sel <- which(beta != 0)
    if (length(sel) > 0) {
      e <- as.vector(lm.fit(X[, sel, drop = FALSE], y)$residuals)   # post-lasso residuals
    } else e <- y
    psi_new <- loadings(e)
    if (max(abs(psi_new - psi)) < psitol) { psi <- psi_new; break }
    psi <- psi_new
  }
  beta <- lasso_cd(G, b_xy, lambda * psi, beta0 = beta)
  which(beta != 0)
}

# ---------------- estimation ----------------
run_col <- function(yvar) {
  ok <- !is.na(d[[yvar]])
  s <- d[ok, ]
  Z <- cbind(1, as.matrix(s[, dd_vars]))
  X <- as.matrix(s[, cand]); storage.mode(X) <- "double"
  Xr <- partial_out(X, Z)
  keep <- apply(Xr, 2, function(v) sd(v) > 1e-8)
  Xr <- Xr[, keep, drop = FALSE]
  cn <- colnames(Xr)
  yr  <- as.vector(partial_out(as.matrix(as.numeric(s[[yvar]])), Z))
  pvr <- as.vector(partial_out(as.matrix(as.numeric(s$patient_voucher)), Z))
  dvr <- as.vector(partial_out(as.matrix(as.numeric(s$doctor_voucher)), Z))
  cl <- s$cscomnum_OS
  sel_y  <- cn[rlasso_select(yr,  Xr, cl)]
  sel_pv <- cn[rlasso_select(pvr, Xr, cl)]
  sel_dv <- cn[rlasso_select(dvr, Xr, cl)]
  sel <- unique(c(sel_y, sel_pv, sel_dv))
  cat(sprintf("%s: N=%d; selected y=%d PV=%d DV=%d union=%d: %s\n", yvar, nrow(s),
              length(sel_y), length(sel_pv), length(sel_dv), length(sel), paste(sel, collapse = " ")))
  rhs <- paste(c("patient_voucher", "doctor_voucher", dd_vars, sel), collapse = " + ")
  m <- feols(as.formula(paste(yvar, "~", rhs)), data = s, cluster = ~cscomnum_OS)
  ct <- coeftable(m)
  cat(sprintf("  bP=%.4f (%.4f)  bD=%.4f (%.4f)  control mean=%.3f  nobs=%d\n",
              ct["patient_voucher", 1], ct["patient_voucher", 2],
              ct["doctor_voucher", 1], ct["doctor_voucher", 2],
              mean(s[[yvar]][s$patient_voucher == 0 & s$doctor_voucher == 0]), nobs(m)))
  # no-control check
  m0 <- feols(as.formula(paste(yvar, "~ patient_voucher + doctor_voucher +", paste(dd_vars, collapse = "+"))),
              data = s, cluster = ~cscomnum_OS)
  cat(sprintf("  (no extra controls: bP=%.4f bD=%.4f)\n", coef(m0)["patient_voucher"], coef(m0)["doctor_voucher"]))
  list(bP = unname(ct["patient_voucher", 1]), bD = unname(ct["doctor_voucher", 1]), n = nobs(m))
}

cols <- list(
  c("voucher_used",                        "used_vouchers_admin",     "table3_col1"),
  c("any_malaria_treatment_prescribed",    "RXtreat_sev_simple_mal",  "table3_col2"),
  c("any_malaria_treatment_purchased",     "treat_sev_simple_mal",    "table3_col3"),
  c("severe_malaria_treatment_prescribed", "RXtreat_severe_mal",      "table3_col4"),
  c("severe_malaria_treatment_purchased",  "treat_severe_mal",        "table3_col5")
)
res <- list()
for (cc in cols) res[[cc[1]]] <- run_col(cc[2])

out <- c()
for (cc in cols) {
  r <- res[[cc[1]]]
  out <- c(out,
           sprintf("RESULT:%s_patient_voucher_%s=%.6f\n", cc[1], cc[3], r$bP),
           sprintf("RESULT:%s_doctor_voucher_%s=%.6f\n",  cc[1], cc[3], r$bD))
}
out <- c(out,
         sprintf("RESULT:n_obs_table3_col1=%d\n", res[["voucher_used"]]$n),
         sprintf("RESULT:n_obs_table3_cols2_5=%d\n", res[["any_malaria_treatment_prescribed"]]$n))
cat(out, sep = "")
