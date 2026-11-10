# Reproduction of Lopez, Sautmann & Schaner (2022), Table 3
# y = b0 + bP*PV + bD*DV + date FE + lasso-selected controls (post-double-selection,
# Belloni-Chernozhukov-Hansen 2014), SEs clustered by clinic.
# Lasso: rigorous (plug-in) penalty with cluster-robust penalty loadings, date FE
# partialled out (unpenalised), implemented by hand (no glmnet/hdm in sandbox).
suppressPackageStartupMessages({ library(haven); library(fixest) })
set.seed(42)

f <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-d/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d <- read_dta(f)
d <- zap_labels(d)
cat("Rows in file:", nrow(d), "\n")
d <- d[d$dropme == 0, ]
cat("Rows with dropme==0 (main analysis sample):", nrow(d), "\n")

nm <- names(d)
cc_main <- grep("^CC[0-9]+$", nm, value = TRUE)
cc_int  <- grep("^CC[0-9]+xCC[0-9]+$", nm, value = TRUE)
cl      <- grep("^CL[0-9]+$", nm, value = TRUE)
cands <- c(cl, cc_main, cc_int)
cat("Candidate controls: clinic dummies", length(cl), "| main", length(cc_main),
    "| interactions", length(cc_int), "| total", length(cands), "\n")
cat("Main CC vars:", paste(cc_main, collapse = " "), "\n")
cat("treatment table (patient_voucher, doctor_voucher):\n"); print(table(d$patient_voucher, d$doctor_voucher))
cat("clinics:", length(unique(d$cscomnum_OS)), " dates:", length(unique(d$date_morning_survey)), "\n")

# ---- helpers ---------------------------------------------------------------
demean_by <- function(M, g) {
  M <- as.matrix(M)
  idx <- as.integer(factor(g))
  mu <- rowsum(M, idx) / tabulate(idx)
  M - mu[idx, , drop = FALSE]
}

lasso_cd <- function(X, y, pen, tol = 1e-10, maxit = 10000) {
  # minimise ||y - Xb||^2 + sum(pen_j |b_j|)
  p <- ncol(X); b <- numeric(p)
  xx <- colSums(X^2); r <- y
  for (it in 1:maxit) {
    maxchg <- 0
    for (j in 1:p) {
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- if (z > pen[j] / 2) (z - pen[j] / 2) / xx[j] else if (z < -pen[j] / 2) (z + pen[j] / 2) / xx[j] else 0
      if (nb != bj) { r <- r - X[, j] * (nb - bj); b[j] <- nb
        maxchg <- max(maxchg, abs(nb - bj) * sqrt(xx[j])) }
    }
    if (maxchg < tol) break
  }
  b
}

rlasso_sel <- function(X, y, clus, c = 1.1, maxpsiiter = 15) {
  N <- nrow(X); p <- ncol(X); G <- length(unique(clus))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(N) * qnorm(1 - gamma / (2 * p))
  psi_fun <- function(e) {
    U <- rowsum(X * e, clus)          # G x p cluster scores
    sqrt(colSums(U^2) / N)
  }
  # initial residuals: OLS of y on the 5 regressors most correlated with y
  cr <- abs(cor(X, y)); cr[is.na(cr)] <- 0
  top <- order(cr, decreasing = TRUE)[1:5]
  e <- resid(lm.fit(X[, top, drop = FALSE], y))
  sel_old <- NULL; psi_old <- NULL
  for (k in 1:maxpsiiter) {
    psi <- psi_fun(e)
    b <- lasso_cd(X, y, lambda * psi)
    sel <- which(b != 0)
    e <- if (length(sel)) resid(lm.fit(X[, sel, drop = FALSE], y)) else y
    if (!is.null(psi_old) && max(abs(psi - psi_old)) < 1e-6 * max(psi)) break
    psi_old <- psi; sel_old <- sel
  }
  sel
}

pds <- function(yvar) {
  s <- d[!is.na(d[[yvar]]), ]
  N <- nrow(s)
  g <- s$date_morning_survey
  Xc <- as.matrix(s[, cands]); storage.mode(Xc) <- "double"
  # partial out date fixed effects (and constant)
  Xt <- demean_by(Xc, g)
  keep <- apply(Xt, 2, function(v) sd(v) > 1e-8)
  Xt <- Xt[, keep, drop = FALSE]
  yt <- as.vector(demean_by(s[[yvar]], g))
  pvt <- as.vector(demean_by(s$patient_voucher, g))
  dvt <- as.vector(demean_by(s$doctor_voucher, g))
  cl_ <- s$cscomnum_OS
  sy <- rlasso_sel(Xt, yt, cl_)
  sp <- rlasso_sel(Xt, pvt, cl_)
  sd_ <- rlasso_sel(Xt, dvt, cl_)
  selv <- colnames(Xt)[sort(unique(c(sy, sp, sd_)))]
  cat(sprintf("\n[%s] N=%d, candidates after partialling=%d; selected: y=%d PV=%d DV=%d union=%d\n",
              yvar, N, ncol(Xt), length(sy), length(sp), length(sd_), length(selv)))
  cat("  selected:", paste(selv, collapse = " "), "\n")
  s$date_fe <- factor(g)
  rhs <- paste(c("patient_voucher", "doctor_voucher", selv), collapse = " + ")
  m <- feols(as.formula(paste(yvar, "~", rhs, "| date_fe")), data = s, cluster = ~cscomnum_OS)
  ct <- coeftable(m)
  print(ct[c("patient_voucher", "doctor_voucher"), ])
  cat("  Control mean:", mean(s[[yvar]][s$patient_voucher == 0 & s$doctor_voucher == 0]), "\n")
  list(bP = unname(coef(m)["patient_voucher"]), bD = unname(coef(m)["doctor_voucher"]), N = nobs(m))
}

outs <- c(col1 = "used_vouchers_admin", col2 = "RXtreat_sev_simple_mal", col3 = "treat_sev_simple_mal",
          col4 = "RXtreat_severe_mal", col5 = "treat_severe_mal")
res <- lapply(outs, pds)

cat("\n")
cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", res$col1$bP))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", res$col1$bD))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", res$col2$bP))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", res$col2$bD))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", res$col3$bP))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", res$col3$bD))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", res$col4$bP))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", res$col4$bD))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", res$col5$bP))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", res$col5$bD))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", res$col1$N))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", res$col2$N))
