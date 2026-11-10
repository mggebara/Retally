# Lopez, Sautmann & Schaner (2022 AEJ Applied), Table 3 "Impacts on Malaria Treatment Outcomes".
# Translation of the authors' docpat_theory_lso program (LSS_TablePrograms.do):
#   pdslasso y patient_voucher doctor_voucher (DD1-DD35 CL1-CL59 CC*), clu(cscomnum) partial(DD1-DD35)
# i.e. post-double-selection lasso (Belloni, Chernozhukov & Hansen 2014) with lassopack's
# rlasso (cluster-robust penalty loadings, clustered by clinic) for the selection steps,
# date dummies partialled out (unpenalised, always kept), then OLS of y on the two voucher
# dummies + date dummies + the union of selected controls, SEs clustered by clinic.
# Stata's "cscomnum" is an unambiguous abbreviation of the variable cscomnum_OS.
suppressMessages({library(haven); library(fixest)})
set.seed(42)
p <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/seeded/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- as.data.frame(zap_labels(read_dta(p)))
d <- d[d$dropme != 1, ]                         # drop if dropme==1
nm <- names(d)
date_vars <- nm[match("DD1", nm):match("DD35", nm)]   # $date  = DD1-DD35
clin_vars <- nm[match("CL1", nm):match("CL59", nm)]   # $clinic = CL1-CL59
cc_vars   <- grep("^CC", nm, value = TRUE)            # $patient = CC*
pen_vars  <- unique(c(clin_vars, cc_vars))            # penalised controls (dates are partialled)
d$cluster <- d$cscomnum_OS

# ---------------- rlasso (lassopack defaults) ----------------
partial_out <- function(M, Z) { q <- qr(Z); M - qr.fitted(q, M) }
soft <- function(z, t) sign(z) * max(abs(z) - t, 0)
# minimise  sum_i (y_i - x_i'b)^2 + sum_j pen_j |b_j|   (lassopack objective times N)
lasso_cd <- function(XtX, Xty, pen, b, tol = 1e-9, maxit = 5000) {
  dg <- diag(XtX)
  g <- Xty - as.vector(XtX %*% b)
  sweep_set <- function(idx) {
    md <- 0
    for (j in idx) {
      nb <- soft(g[j] + dg[j] * b[j], pen[j] / 2) / dg[j]
      dl <- nb - b[j]
      if (dl != 0) { g <<- g - XtX[, j] * dl; b[j] <<- nb; md <- max(md, abs(dl) * sqrt(dg[j])) }
    }
    md
  }
  for (it in 1:maxit) {
    md <- sweep_set(seq_along(b))
    if (md < tol) break
    act <- which(b != 0)
    for (it2 in 1:maxit) if (sweep_set(act) < tol) break
  }
  b
}
psi_clu <- function(X, e, cl) sqrt(colSums(rowsum(X * e, cl)^2) / nrow(X))
rlasso_sel <- function(y, X, cl, c = 1.1, maxpsiiter = 15, tolpsi = 1e-5) {
  n <- nrow(X); p <- ncol(X); G <- length(unique(cl))
  gamma  <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  XtX <- crossprod(X); Xty <- as.vector(crossprod(X, y))
  top <- order(abs(as.vector(cor(X, y))), decreasing = TRUE)[1:5]   # corrnumber(5)
  e <- as.vector(y - qr.fitted(qr(X[, top, drop = FALSE]), y))
  psi <- psi_clu(X, e, cl)
  b <- rep(0, p)
  for (k in 1:maxpsiiter) {
    b <- lasso_cd(XtX, Xty, lambda * psi, b)
    sel <- which(b != 0)
    e <- if (length(sel)) as.vector(y - qr.fitted(qr(X[, sel, drop = FALSE]), y)) else y  # post-lasso residuals
    psi_new <- psi_clu(X, e, cl)
    conv <- max(abs(psi_new - psi)) < tolpsi
    psi <- psi_new
    if (conv) break
  }
  b <- lasso_cd(XtX, Xty, lambda * psi, b)
  which(b != 0)
}

treat <- c("patient_voucher", "doctor_voucher")
outcomes <- c(used_vouchers_admin    = "voucher_used",
              RXtreat_sev_simple_mal = "any_malaria_treatment_prescribed",
              treat_sev_simple_mal   = "any_malaria_treatment_purchased",
              RXtreat_severe_mal     = "severe_malaria_treatment_prescribed",
              treat_severe_mal       = "severe_malaria_treatment_purchased")
res <- list(); Ns <- c()
for (k in seq_along(outcomes)) {
  out <- names(outcomes)[k]
  s <- d[complete.cases(d[, c(out, treat, date_vars, pen_vars, "cluster")]), ]
  Z  <- cbind(1, as.matrix(s[, date_vars]))
  Xp <- partial_out(as.matrix(s[, pen_vars]), Z)
  Xp <- Xp[, colSums(Xp^2) > 1e-8, drop = FALSE]
  sel <- integer(0)
  for (v in c(out, treat)) {
    yv <- as.vector(partial_out(matrix(as.numeric(s[[v]])), Z))
    sv <- rlasso_sel(yv, Xp, s$cluster)
    cat(sprintf("  [%s] lasso of %s selected %d: %s\n", out, v, length(sv), paste(colnames(Xp)[sv], collapse = " ")))
    sel <- union(sel, sv)
  }
  selnames <- colnames(Xp)[sel]
  fml <- as.formula(paste(out, "~", paste(c(treat, date_vars, selnames), collapse = " + ")))
  m  <- feols(fml, data = s, cluster = ~cluster)
  ct <- coeftable(m)
  cat(sprintf("%s: N=%d  PV=%.4f (%.4f)  DV=%.4f (%.4f)  controls=%d  controlmean=%.3f\n", out, nobs(m),
              ct["patient_voucher", 1], ct["patient_voucher", 2], ct["doctor_voucher", 1], ct["doctor_voucher", 2],
              length(selnames), mean(s[[out]][s$patient_voucher == 0 & s$doctor_voucher == 0])))
  res[[sprintf("%s_patient_voucher_table3_col%d", outcomes[k], k)]] <- ct["patient_voucher", 1]
  res[[sprintf("%s_doctor_voucher_table3_col%d",  outcomes[k], k)]] <- ct["doctor_voucher", 1]
  Ns[out] <- nobs(m)
}
for (nmr in names(res)) cat(sprintf("RESULT:%s=%.6f\n", nmr, res[[nmr]]))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", Ns[["used_vouchers_admin"]]))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", Ns[["RXtreat_sev_simple_mal"]]))
