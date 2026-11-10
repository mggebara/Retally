suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/lopez_2022_patient_demand_prescription_overuse"
fpath <- file.path(base, "Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta")

d <- read_dta(fpath)
d <- as.data.frame(zap_labels(d))
# Stata: drop if dropme==1 (missing dropme is kept)
d <- d[is.na(d$dropme) | d$dropme != 1, , drop = FALSE]
cat("Rows after dropme filter:", nrow(d), "\n")

nm <- names(d)
isnum <- vapply(d, is.numeric, logical(1))

# $date = DD1-DD35 (partialled out), $clinic = CL1-CL59, $patient = CC*
dd_names <- paste0("DD", 1:35)
dd_names <- dd_names[dd_names %in% nm]
cl_names <- paste0("CL", 1:59)
cl_names <- cl_names[cl_names %in% nm]
cc_names <- grep("^CC", nm, value = TRUE)
cc_names <- cc_names[isnum[cc_names]]

if (length(dd_names) == 0) {
  # fallback: build date dummies from the visit date
  dfac <- factor(d$date)
  mm <- model.matrix(~ dfac)[, -1, drop = FALSE]
  colnames(mm) <- paste0("DDgen", seq_len(ncol(mm)))
  d <- cbind(d, mm)
  dd_names <- colnames(mm)
}
cat("Date dummies:", length(dd_names), " Clinic dummies:", length(cl_names),
    " Patient controls (CC*):", length(cc_names), "\n")

# ---------------------------------------------------------------------------
# Rigorous (cluster-robust) lasso a la lassopack::rlasso, used by pdslasso
# ---------------------------------------------------------------------------
lasso_cd <- function(X, y, pen, maxit = 100000, tol = 1e-9) {
  p <- ncol(X)
  xx <- colSums(X^2)
  b <- numeric(p)
  r <- y
  scale_ref <- sqrt(sum(y^2)) + 1e-12
  active <- integer(0)
  for (outer in 1:200) {
    g <- drop(crossprod(X, r))
    viol <- which(b == 0 & abs(g) > pen * (1 + 1e-10))
    if (length(viol) == 0) break
    active <- sort(unique(c(active, viol)))
    for (it in 1:maxit) {
      maxd <- 0
      for (j in active) {
        if (xx[j] <= 0) next
        xj <- X[, j]
        bo <- b[j]
        z <- sum(xj * r) + xx[j] * bo
        bn <- if (z > pen[j]) (z - pen[j]) / xx[j] else if (z < -pen[j]) (z + pen[j]) / xx[j] else 0
        if (bn != bo) {
          r <- r - xj * (bn - bo)
          b[j] <- bn
          dd <- abs(bn - bo) * sqrt(xx[j])
          if (dd > maxd) maxd <- dd
        }
      }
      if (maxd < tol * scale_ref) break
    }
  }
  b
}

rlasso_select <- function(y, X, clus, c = 1.1, maxpsiiter = 2) {
  n <- length(y)
  p <- ncol(X)
  G <- length(unique(clus))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  # initial residuals: regress y on the 5 most correlated regressors
  cr <- abs(suppressWarnings(cor(X, y)))
  cr[is.na(cr)] <- 0
  top <- order(-cr)[seq_len(min(5, p))]
  e <- y - X[, top, drop = FALSE] %*% qr.coef(qr(X[, top, drop = FALSE]), y)
  e <- drop(e)
  e[is.na(e)] <- 0
  sel <- integer(0)
  for (k in seq_len(maxpsiiter)) {
    S <- rowsum(X * e, clus)
    psi <- sqrt(colSums(S^2) / n)
    psi[psi <= 0] <- min(psi[psi > 0])
    b <- lasso_cd(X, y, lambda * psi / 2)
    sel <- which(b != 0)
    if (length(sel) > 0) {
      Xs <- X[, sel, drop = FALSE]
      cf <- qr.coef(qr(Xs), y)
      cf[is.na(cf)] <- 0
      e <- drop(y - Xs %*% cf)
    } else {
      e <- y
    }
  }
  colnames(X)[sel]
}

pds_reg <- function(yname, data) {
  need <- c(yname, "patient_voucher", "doctor_voucher", "cscomnum", dd_names)
  keep <- complete.cases(data[, need])
  dat <- data[keep, , drop = FALSE]
  xnames <- c(cl_names, cc_names)
  # drop candidate controls with missing values in this sample
  hasna <- vapply(xnames, function(v) anyNA(dat[[v]]), logical(1))
  if (any(hasna)) cat("  dropping", sum(hasna), "controls with missing values\n")
  xnames <- xnames[!hasna]

  Z <- cbind(1, as.matrix(dat[, dd_names]))
  qz <- qr(Z)
  y <- qr.resid(qz, as.numeric(dat[[yname]]))
  pv <- qr.resid(qz, as.numeric(dat$patient_voucher))
  dv <- qr.resid(qz, as.numeric(dat$doctor_voucher))
  X <- as.matrix(dat[, xnames])
  storage.mode(X) <- "double"
  X <- qr.resid(qz, X)
  colnames(X) <- xnames
  ss <- colSums(X^2)
  X <- X[, ss > 1e-8, drop = FALSE]
  clus <- dat$cscomnum

  s_y <- rlasso_select(y, X, clus)
  s_p <- rlasso_select(pv, X, clus)
  s_d <- rlasso_select(dv, X, clus)
  sel <- unique(c(s_y, s_p, s_d))
  cat(sprintf("  %s: selected %d (y) %d (PV) %d (DV) -> union %d\n",
              yname, length(s_y), length(s_p), length(s_d), length(sel)))

  rhs <- c("patient_voucher", "doctor_voucher", dd_names, sel)
  fml <- as.formula(paste0("`", yname, "` ~ ", paste0("`", rhs, "`", collapse = " + ")))
  m <- feols(fml, data = dat, cluster = ~cscomnum)
  m
}

outcomes <- c("used_vouchers_admin", "RXtreat_sev_simple_mal", "treat_sev_simple_mal",
              "RXtreat_severe_mal", "treat_severe_mal")
models <- list()
for (o in outcomes) {
  models[[o]] <- pds_reg(o, d)
  cf <- coef(models[[o]])[c("patient_voucher", "doctor_voucher")]
  se <- sqrt(diag(vcov(models[[o]])))[c("patient_voucher", "doctor_voucher")]
  cat(sprintf("  %s: PV=%.4f (%.4f) DV=%.4f (%.4f) N=%d\n", o, cf[1], se[1], cf[2], se[2],
              nobs(models[[o]])))
  w <- tryCatch(wald(models[[o]], keep = "^patient_voucher$|^doctor_voucher$", print = FALSE),
                error = function(e) NULL)
  if (!is.null(w)) cat(sprintf("  joint PV=DV=0 p-value: %.4f\n", w$p))
}

getb <- function(o, v) unname(coef(models[[o]])[v])

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", getb("used_vouchers_admin", "patient_voucher")))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", getb("used_vouchers_admin", "doctor_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", getb("RXtreat_sev_simple_mal", "patient_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", getb("RXtreat_sev_simple_mal", "doctor_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", getb("treat_sev_simple_mal", "patient_voucher")))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", getb("treat_sev_simple_mal", "doctor_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", getb("RXtreat_severe_mal", "patient_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", getb("RXtreat_severe_mal", "doctor_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", getb("treat_severe_mal", "patient_voucher")))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", getb("treat_severe_mal", "doctor_voucher")))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(models[["used_vouchers_admin"]])))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", nobs(models[["RXtreat_sev_simple_mal"]])))
