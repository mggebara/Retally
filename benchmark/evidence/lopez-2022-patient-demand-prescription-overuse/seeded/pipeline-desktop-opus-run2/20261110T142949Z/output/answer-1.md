suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

f <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(f)
d <- as.data.frame(zap_labels(d))

# drop if dropme==1
keep <- is.na(d$dropme) | d$dropme != 1
d <- d[keep, , drop = FALSE]

nms <- names(d)
varrange <- function(nms, a, b, pattern) {
  ia <- match(a, nms); ib <- match(b, nms)
  if (!is.na(ia) && !is.na(ib) && ib >= ia) nms[ia:ib] else grep(pattern, nms, value = TRUE)
}
datev <- varrange(nms, "DD1", "DD35", "^DD[0-9]+$")
clinv <- varrange(nms, "CL1", "CL59", "^CL[0-9]+$")
patv  <- grep("^CC", nms, value = TRUE)
controls <- setdiff(unique(c(clinv, patv)), datev)
isnum <- vapply(d[controls], function(z) is.numeric(z) || is.logical(z), logical(1))
controls <- controls[isnum]
for (v in c(datev, controls)) d[[v]] <- as.numeric(d[[v]])

cat("Date dummies:", length(datev), " Clinic dummies:", length(clinv), " Patient controls:", length(patv), "\n")

# ---------------- weighted lasso via coordinate descent (active set) ----------------
# minimizes (1/2)||y - Xb||^2 + sum_j pen_j |b_j|
lasso_cd <- function(X, y, pen, xx, b) {
  p <- ncol(X)
  nz <- which(b != 0)
  r <- if (length(nz)) as.vector(y - X[, nz, drop = FALSE] %*% b[nz]) else y
  active <- nz
  ytol <- 1e-9 * sqrt(sum(y^2)) + 1e-14
  for (outer in 1:500) {
    g <- as.vector(crossprod(X, r))
    inact <- rep(TRUE, p); inact[active] <- FALSE
    viol <- which(inact & abs(g) > pen * (1 + 1e-9))
    if (outer > 1 && length(viol) == 0) break
    active <- c(active, viol)
    if (length(active) == 0) break
    for (inner in 1:20000) {
      maxd <- 0
      for (j in active) {
        old <- b[j]
        xj <- X[, j]
        z <- sum(xj * r) + xx[j] * old
        az <- abs(z) - pen[j]
        new <- if (az > 0) sign(z) * az / xx[j] else 0
        if (new != old) {
          r <- r - xj * (new - old)
          b[j] <- new
          dd <- abs(new - old) * sqrt(xx[j])
          if (dd > maxd) maxd <- dd
        }
      }
      if (maxd < ytol) break
    }
    active <- active[b[active] != 0]
  }
  b
}

ols_resid <- function(X, y, sel) {
  if (length(sel) == 0) return(y)
  as.vector(qr.resid(qr(X[, sel, drop = FALSE]), y))
}

# rlasso with cluster-robust penalty loadings (Belloni, Chernozhukov, Hansen, Kozbur 2016)
rlasso_sel <- function(X, y, cl, c0 = 1.1, maxpsiiter = 15, tol = 1e-5) {
  N <- nrow(X); p <- ncol(X); G <- length(unique(cl))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c0 * sqrt(N) * qnorm(1 - gamma / (2 * p))
  xx <- colSums(X^2)
  cors <- as.vector(crossprod(X, y)) / sqrt(xx * sum(y^2))
  cors[!is.finite(cors)] <- 0
  top <- order(-abs(cors))[seq_len(min(5, p))]
  e <- ols_resid(X, y, top)
  b <- rep(0, p)
  psi_old <- NULL
  sel <- integer(0)
  for (it in seq_len(maxpsiiter)) {
    S <- rowsum(X * e, cl)
    psi <- sqrt(colSums(S^2) / N)
    psi[psi < 1e-12] <- 1e-12
    if (!is.null(psi_old) && max(abs(psi - psi_old)) < tol) break
    pen <- lambda * psi / 2
    b <- lasso_cd(X, y, pen, xx, b)
    sel <- which(b != 0)
    e <- ols_resid(X, y, sel)
    psi_old <- psi
  }
  sel
}

# ---------------- PDS lasso for each outcome ----------------
run_pds <- function(yname) {
  need <- c(yname, "patient_voucher", "doctor_voucher", "cscomnum", datev)
  ok <- complete.cases(d[, need])
  sub <- d[ok, , drop = FALSE]
  N <- nrow(sub)
  Xc <- as.matrix(sub[, controls, drop = FALSE])
  goodc <- colSums(is.na(Xc)) == 0
  Xc <- Xc[, goodc, drop = FALSE]
  Z <- cbind(1, as.matrix(sub[, datev, drop = FALSE]))
  qz <- qr(Z)
  yt  <- as.vector(qr.resid(qz, sub[[yname]]))
  pvt <- as.vector(qr.resid(qz, sub$patient_voucher))
  dvt <- as.vector(qr.resid(qz, sub$doctor_voucher))
  Xt <- qr.resid(qz, Xc)
  colnames(Xt) <- colnames(Xc)
  ss <- colSums(Xt^2)
  Xt <- Xt[, ss > 1e-8, drop = FALSE]
  cl <- sub$cscomnum
  s_y  <- rlasso_sel(Xt, yt, cl)
  s_pv <- rlasso_sel(Xt, pvt, cl)
  s_dv <- rlasso_sel(Xt, dvt, cl)
  selnames <- colnames(Xt)[sort(unique(c(s_y, s_pv, s_dv)))]
  cat(yname, ": N =", N, " candidate controls =", ncol(Xt),
      " selected (y/PV/DV/union) =", length(s_y), length(s_pv), length(s_dv), length(selnames), "\n")
  if (length(selnames)) cat("  selected:", paste(selnames, collapse = " "), "\n")
  rhs <- c("patient_voucher", "doctor_voucher", datev, selnames)
  fml <- as.formula(paste0("`", yname, "` ~ ", paste0("`", rhs, "`", collapse = " + ")))
  m <- feols(fml, data = sub, cluster = ~cscomnum, warn = FALSE, notes = FALSE)
  cf <- coef(m); se <- sqrt(diag(vcov(m)))
  cat(sprintf("  PV = %.4f (%.4f)  DV = %.4f (%.4f)  N = %d\n",
              cf["patient_voucher"], se["patient_voucher"],
              cf["doctor_voucher"], se["doctor_voucher"], nobs(m)))
  list(pv = unname(cf["patient_voucher"]), dv = unname(cf["doctor_voucher"]), n = nobs(m))
}

outs <- c("used_vouchers_admin", "RXtreat_sev_simple_mal", "treat_sev_simple_mal",
          "RXtreat_severe_mal", "treat_severe_mal")
res <- lapply(outs, run_pds)
names(res) <- outs

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", res$used_vouchers_admin$pv))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", res$used_vouchers_admin$dv))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", res$RXtreat_sev_simple_mal$pv))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", res$RXtreat_sev_simple_mal$dv))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", res$treat_sev_simple_mal$pv))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", res$treat_sev_simple_mal$dv))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", res$RXtreat_severe_mal$pv))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", res$RXtreat_severe_mal$dv))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", res$treat_severe_mal$pv))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", res$treat_severe_mal$dv))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", as.integer(res$used_vouchers_admin$n)))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", as.integer(res$RXtreat_sev_simple_mal$n)))
