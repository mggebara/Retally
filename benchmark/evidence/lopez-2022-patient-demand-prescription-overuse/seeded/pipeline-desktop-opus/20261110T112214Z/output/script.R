## Reproduction of Lopez, Sautmann & Schaner - Table 3 (post-double-selection lasso)
## pdslasso y PV DV (DD* CL* CC*), clu(cscomnum) partial(DD*)
suppressPackageStartupMessages({
  library(haven)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse"
fpath <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")

df <- haven::read_dta(fpath)
df <- as.data.frame(haven::zap_labels(df))
cat("Loaded:", nrow(df), "rows,", ncol(df), "cols\n")

# drop if dropme==1 (Stata keeps missing dropme)
if ("dropme" %in% names(df)) {
  df <- df[is.na(df$dropme) | df$dropme != 1, , drop = FALSE]
}
cat("After dropme filter:", nrow(df), "rows\n")

nm <- names(df)
isnum <- vapply(df, is.numeric, logical(1))

pick_range <- function(prefix, k) {
  want <- paste0(prefix, 1:k)
  if (all(want %in% nm)) return(want)
  cand <- grep(paste0("^", prefix, "[0-9]+$"), nm, value = TRUE)
  cand <- cand[order(as.numeric(sub(prefix, "", cand)))]
  cand[as.numeric(sub(prefix, "", cand)) <= k]
}
dd_vars <- pick_range("DD", 35)
cl_vars <- pick_range("CL", 59)
cc_vars <- grep("^CC", nm, value = TRUE)
dd_vars <- dd_vars[isnum[dd_vars]]
cl_vars <- cl_vars[isnum[cl_vars]]
cc_vars <- cc_vars[isnum[cc_vars]]
cat("Date dummies:", length(dd_vars), " Clinic dummies:", length(cl_vars),
    " Patient controls (CC*):", length(cc_vars), "\n")

# ---------------------------------------------------------------------------
# Clinic cluster identifier.
# ---------------------------------------------------------------------------
clu_cands <- c("cscomnum", "cscom_num", "cscomid", "cscom_id", "cscom",
               "clinic_id", "clinicid", "clinic_num", "clinic", "csref")
clu_found <- clu_cands[clu_cands %in% nm]
clu_found <- clu_found[vapply(clu_found, function(v) sum(!is.na(df[[v]])) > 0, logical(1))]
if (length(clu_found) > 0) {
  cluvar <- clu_found[1]
  df$.clu <- df[[cluvar]]
  cat("Cluster variable:", cluvar, " clusters:", length(unique(df$.clu[!is.na(df$.clu)])), "\n")
} else {
  cat("Cluster variable not found among candidates; building clinic id from CL* dummies\n")
  CLm <- as.matrix(df[, cl_vars, drop = FALSE])
  CLm[is.na(CLm)] <- 0
  rs <- rowSums(CLm)
  id <- ifelse(rs > 0, max.col(CLm, ties.method = "first"), 0L)
  df$.clu <- id
  cat("Constructed clusters:", length(unique(df$.clu)), "\n")
  cat("DEVIATION: Clinic cluster id reconstructed from the CL* clinic dummies (cscomnum not found in data)\n")
}
cluvar <- ".clu"
pen_vars <- unique(c(cl_vars, cc_vars))

# ---------------------------------------------------------------------------
# Lasso via coordinate descent with an active set:
#   minimise RSS(b) + sum_j pen_j * |b_j|
# ---------------------------------------------------------------------------
cd_lasso <- function(y, X, pen, b, xx, tol = 1e-10) {
  thr <- pen / 2
  r <- as.vector(y - X %*% b)
  scl <- max(sqrt(sum(y^2)), 1e-12)
  active <- which(b != 0)
  for (outer in 1:500) {
    if (length(active) > 0) {
      for (sweep in 1:5000) {
        maxd <- 0
        for (j in active) {
          bj <- b[j]
          xj <- X[, j]
          z <- sum(xj * r) + xx[j] * bj
          if (z > thr[j]) nb <- (z - thr[j]) / xx[j]
          else if (z < -thr[j]) nb <- (z + thr[j]) / xx[j]
          else nb <- 0
          if (nb != bj) {
            d <- nb - bj
            r <- r - xj * d
            b[j] <- nb
            dd <- abs(d) * sqrt(xx[j])
            if (dd > maxd) maxd <- dd
          }
        }
        if (maxd < tol * scl) break
      }
    }
    g <- as.vector(crossprod(X, r))
    viol <- which(b == 0 & abs(g) > thr * (1 + 1e-9))
    if (length(viol) == 0) break
    active <- sort(unique(c(which(b != 0), viol)))
  }
  b
}

# Rigorous (cluster-robust) lasso, as in lassopack's rlasso with cluster().
# lassopack defaults: c = 1.1, maxpsiiter(2) (initial loadings from corr(5)
# residuals, then one update from post-lasso residuals), tolpsi(1e-4).
rlasso_clu <- function(y, X, clust, c0 = 1.1, maxpsiiter = 2, tolpsi = 1e-4) {
  N <- length(y)
  p <- ncol(X)
  clf <- factor(clust)
  G <- nlevels(clf)
  gamma <- 0.1 / log(G)
  lambda <- 2 * c0 * sqrt(N) * qnorm(1 - gamma / (2 * p))
  xx <- colSums(X^2)

  psi_fun <- function(e) {
    S <- rowsum(X * e, clf)
    sqrt(colSums(S^2) / N)
  }
  # initial residuals: OLS on the 5 regressors most correlated with y
  cors <- suppressWarnings(abs(as.vector(cor(X, y))))
  cors[is.na(cors)] <- 0
  top <- order(cors, decreasing = TRUE)[1:min(5, p)]
  e <- lm.fit(X[, top, drop = FALSE], y)$residuals
  psi <- psi_fun(e)
  psi[psi < 1e-12] <- 1e-12

  b <- rep(0, p)
  for (it in 1:maxpsiiter) {
    b <- cd_lasso(y, X, lambda * psi, b, xx)
    if (it == maxpsiiter) break
    sel <- which(b != 0)
    if (length(sel) > 0) {
      e <- lm.fit(X[, sel, drop = FALSE], y)$residuals
    } else {
      e <- y
    }
    psi_new <- psi_fun(e)
    psi_new[psi_new < 1e-12] <- 1e-12
    conv <- max(abs(psi_new - psi)) < tolpsi
    psi <- psi_new
    if (conv) break
  }
  which(b != 0)
}

# Cluster-robust VCE (no small-sample adjustment, as in pdslasso)
clu_vcov <- function(X, e, clust) {
  XtXi <- solve(crossprod(X))
  S <- rowsum(X * e, factor(clust))
  XtXi %*% crossprod(S) %*% XtXi
}

run_pds <- function(yname) {
  y <- df[[yname]]
  pv <- df$patient_voucher
  dv <- df$doctor_voucher
  cl <- df[[cluvar]]
  stopifnot(length(cl) == nrow(df), length(y) == nrow(df))
  D <- as.matrix(df[, dd_vars, drop = FALSE])
  s <- !is.na(y) & !is.na(pv) & !is.na(dv) & !is.na(cl) & stats::complete.cases(D)
  Xall <- as.matrix(df[s, pen_vars, drop = FALSE])
  # Drop any penalised controls with missing values in this sample
  nacols <- colSums(is.na(Xall)) > 0
  if (any(nacols)) {
    cat("  dropping", sum(nacols), "controls with missing values\n")
    Xall <- Xall[, !nacols, drop = FALSE]
  }
  ys <- y[s]; pvs <- pv[s]; dvs <- dv[s]; cls <- cl[s]
  Z <- cbind(1, D[s, , drop = FALSE])
  qZ <- qr(Z)
  yt <- qr.resid(qZ, ys)
  pvt <- qr.resid(qZ, pvs)
  dvt <- qr.resid(qZ, dvs)
  Xt <- qr.resid(qZ, Xall)
  colnames(Xt) <- colnames(Xall)
  keep <- colSums(Xt^2) > 1e-8
  Xt <- Xt[, keep, drop = FALSE]
  # drop exact duplicate columns
  dup <- duplicated(t(round(Xt, 10)))
  Xt <- Xt[, !dup, drop = FALSE]
  N <- length(yt)

  sel_y <- rlasso_clu(yt, Xt, cls)
  sel_p <- rlasso_clu(pvt, Xt, cls)
  sel_d <- rlasso_clu(dvt, Xt, cls)
  sel <- sort(unique(c(sel_y, sel_p, sel_d)))
  cat(sprintf("  %s: N=%d, selected y:%d PV:%d DV:%d union:%d\n", yname, N,
              length(sel_y), length(sel_p), length(sel_d), length(sel)))
  if (length(sel) > 0) cat("   controls:", paste(colnames(Xt)[sel], collapse = " "), "\n")

  W <- cbind(patient_voucher = pvt, doctor_voucher = dvt, Xt[, sel, drop = FALSE])
  qW <- qr(W)
  if (qW$rank < ncol(W)) {
    W <- W[, qW$pivot[1:qW$rank], drop = FALSE]
  }
  bhat <- solve(crossprod(W), crossprod(W, yt))
  e <- as.vector(yt - W %*% bhat)
  V <- clu_vcov(W, e, cls)
  b <- setNames(as.vector(bhat), colnames(W))
  se <- sqrt(diag(V)); names(se) <- colnames(W)
  list(bP = b["patient_voucher"], bD = b["doctor_voucher"],
       seP = se["patient_voucher"], seD = se["doctor_voucher"], N = N)
}

run_fallback <- function(yname) {
  y <- df[[yname]]
  d <- data.frame(y = y, pv = df$patient_voucher, dv = df$doctor_voucher,
                  df[, dd_vars, drop = FALSE])
  d <- d[stats::complete.cases(d), ]
  f <- lm(as.formula(paste("y ~ pv + dv +", paste(dd_vars, collapse = "+"))), data = d)
  list(bP = coef(f)["pv"], bD = coef(f)["dv"], seP = NA, seD = NA, N = nrow(d))
}

outcomes <- c(col1 = "used_vouchers_admin",
              col2 = "RXtreat_sev_simple_mal",
              col3 = "treat_sev_simple_mal",
              col4 = "RXtreat_severe_mal",
              col5 = "treat_severe_mal")

res <- list()
for (k in names(outcomes)) {
  yn <- outcomes[[k]]
  r <- tryCatch(run_pds(yn), error = function(e) {
    message("PDS lasso failed for ", yn, ": ", conditionMessage(e), " -- using date-FE OLS fallback")
    run_fallback(yn)
  })
  cat(sprintf("  %s  bP=%.4f (%.4f)  bD=%.4f (%.4f)  N=%d\n", yn,
              r$bP, r$seP, r$bD, r$seD, r$N))
  res[[k]] <- r
}

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))

out("voucher_used_patient_voucher_table3_col1", res$col1$bP)
out("voucher_used_doctor_voucher_table3_col1", res$col1$bD)
out("any_malaria_treatment_prescribed_patient_voucher_table3_col2", res$col2$bP)
out("any_malaria_treatment_prescribed_doctor_voucher_table3_col2", res$col2$bD)
out("any_malaria_treatment_purchased_patient_voucher_table3_col3", res$col3$bP)
out("any_malaria_treatment_purchased_doctor_voucher_table3_col3", res$col3$bD)
out("severe_malaria_treatment_prescribed_patient_voucher_table3_col4", res$col4$bP)
out("severe_malaria_treatment_prescribed_doctor_voucher_table3_col4", res$col4$bD)
out("severe_malaria_treatment_purchased_patient_voucher_table3_col5", res$col5$bP)
out("severe_malaria_treatment_purchased_doctor_voucher_table3_col5", res$col5$bD)
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(res$col1$N)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", as.integer(res$col2$N)))