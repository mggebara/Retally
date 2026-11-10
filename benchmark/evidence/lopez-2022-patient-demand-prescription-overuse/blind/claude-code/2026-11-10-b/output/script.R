# Retally reproduction: Lopez, Sautmann & Schaner (2022), Table 3
# Independent + blind reproduction. Post-double-selection lasso (Belloni, Chernozhukov
# & Hansen 2014) implemented from scratch (no glmnet/hdm available in the sandbox),
# following the rlasso/pdslasso defaults of Stata's lassopack:
#   - date fixed effects (and constant) partialled out of y, treatments and controls (FWL)
#   - rigorous penalty lambda = 2 c sqrt(N) qnorm(1 - gamma/(2p)), c = 1.1,
#     gamma = 0.1/log(N_clusters), cluster-robust penalty loadings (clinic clusters)
#   - initial residuals from OLS on the 5 controls most correlated with the outcome,
#     then up to 2 lasso-based loading updates using post-lasso residuals
#   - selection: lasso(y ~ X), lasso(PV ~ X), lasso(DV ~ X); final OLS of y on PV, DV,
#     union of selected controls and date FE; SE clustered by clinic.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-b/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
d <- zap_labels(d)
d <- as.data.frame(d)

# ---- candidate controls -------------------------------------------------------
nm <- names(d)
cc_main <- nm[grepl("^CC[0-9]+$", nm)]            # 23 patient/respondent controls (mean-imputed + missing dummies)
cc_int  <- nm[grepl("^CC[0-9]+xCC[0-9]+$", nm)]   # their pairwise interactions
cl      <- nm[grepl("^CL[0-9]+$", nm)]            # clinic dummies
controls <- c(cc_main, cc_int, cl)
cat("Candidate controls: main", length(cc_main), " interactions", length(cc_int),
    " clinic dummies", length(cl), " total", length(controls), "\n")

# ---- helpers ------------------------------------------------------------------
partial_out <- function(M, Fm) {           # residualize columns of M on matrix Fm (incl. constant)
  qrF <- qr(Fm)
  qr.resid(qrF, M)
}

lasso_cd <- function(X, y, pen, b0 = NULL, tol = 1e-10, maxit = 10000) {
  # minimise (1/N)||y - Xb||^2 + (1/N) sum pen_j |b_j|   (pen_j = lambda * psi_j)
  N <- nrow(X); p <- ncol(X)
  xx <- colSums(X^2)
  b <- if (is.null(b0)) rep(0, p) else b0
  r <- y - X %*% b
  for (it in 1:maxit) {
    maxd <- 0
    for (j in 1:p) {
      if (xx[j] <= 0) next
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- sign(z) * max(abs(z) - pen[j] / 2, 0) / xx[j]
      if (nb != bj) {
        r <- r - X[, j] * (nb - bj)
        b[j] <- nb
        maxd <- max(maxd, abs(nb - bj) * sqrt(xx[j]))
      }
    }
    if (maxd < tol) break
  }
  b
}

post_resid <- function(X, y, sel) {
  if (length(sel) == 0) return(y)
  as.numeric(lm.fit(X[, sel, drop = FALSE], y)$residuals)
}

rlasso_select <- function(X, y, cl, c = 1.1, maxpsiiter = 2, corrnumber = 5) {
  N <- nrow(X); p <- ncol(X)
  G <- length(unique(cl))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(N) * qnorm(1 - gamma / (2 * p))
  # initial residuals: OLS on the corrnumber regressors most correlated with y
  cors <- abs(suppressWarnings(cor(X, y)))
  cors[is.na(cors)] <- 0
  init <- order(cors, decreasing = TRUE)[1:min(corrnumber, p)]
  e <- post_resid(X, y, init)
  clf <- as.integer(factor(cl))
  psi_fun <- function(e) {
    S <- rowsum(X * e, clf)                # G x p cluster sums of scores
    sqrt(colSums(S^2) / N)
  }
  b <- NULL; sel <- integer(0); psi_old <- NULL
  for (k in 1:maxpsiiter) {
    psi <- psi_fun(e)
    b <- lasso_cd(X, y, lambda * psi, b0 = b)
    sel <- which(b != 0)
    e <- post_resid(X, y, sel)
    if (!is.null(psi_old) && max(abs(psi - psi_old)) < 1e-6) break
    psi_old <- psi
  }
  sel
}

pds <- function(yvar, data) {
  data <- data[!is.na(data[[yvar]]), ]
  N <- nrow(data)
  Fm <- model.matrix(~ factor(date_morning_survey), data = data)  # constant + date dummies
  Xraw <- as.matrix(data[, controls])
  # drop controls that are constant in this sample
  keep <- apply(Xraw, 2, function(v) sd(v) > 0)
  Xraw <- Xraw[, keep, drop = FALSE]
  Xt <- partial_out(Xraw, Fm)
  # drop columns made (numerically) zero by partialling out the date FE
  sdx <- sqrt(colSums(Xt^2) / N)
  ok <- sdx > 1e-8
  Xt <- Xt[, ok, drop = FALSE]; sdx <- sdx[ok]
  Xs <- sweep(Xt, 2, sdx, "/")             # standardised (lassopack prestd)
  yt  <- as.numeric(partial_out(as.matrix(data[[yvar]]), Fm))
  pvt <- as.numeric(partial_out(as.matrix(data$patient_voucher), Fm))
  dvt <- as.numeric(partial_out(as.matrix(data$doctor_voucher), Fm))
  clv <- data$cscomnum_OS
  s_y  <- rlasso_select(Xs, yt, clv)
  s_pv <- rlasso_select(Xs, pvt, clv)
  s_dv <- rlasso_select(Xs, dvt, clv)
  sel <- sort(unique(c(s_y, s_pv, s_dv)))
  selnames <- colnames(Xs)[sel]
  cat(sprintf("[%s] N=%d, p=%d; selected: y=%d, PV=%d, DV=%d, union=%d\n", yvar, N, ncol(Xs),
              length(s_y), length(s_pv), length(s_dv), length(sel)))
  cat("   selected controls:", if (length(selnames)) paste(selnames, collapse = " ") else "(none)", "\n")
  fml <- if (length(selnames)) {
    as.formula(paste(yvar, "~ patient_voucher + doctor_voucher +", paste(selnames, collapse = " + "),
                     "| date_morning_survey"))
  } else as.formula(paste(yvar, "~ patient_voucher + doctor_voucher | date_morning_survey"))
  m <- feols(fml, data = data, cluster = ~cscomnum_OS)
  ct <- coeftable(m)
  V <- vcov(m)
  dif <- ct["patient_voucher", 1] - ct["doctor_voucher", 1]
  sed <- sqrt(V["patient_voucher", "patient_voucher"] + V["doctor_voucher", "doctor_voucher"] -
              2 * V["patient_voucher", "doctor_voucher"])
  p_eq <- 2 * pt(-abs(dif / sed), df = length(unique(data$cscomnum_OS)) - 1)
  cat(sprintf("   beta_P = %.4f (se %.4f)   beta_D = %.4f (se %.4f)   p(bP=bD) = %.3f   N = %d\n",
              ct["patient_voucher", 1], ct["patient_voucher", 2],
              ct["doctor_voucher", 1], ct["doctor_voucher", 2],
              p_eq, nobs(m)))
  # also the no-control version (equation 1) for reference
  m0 <- feols(as.formula(paste(yvar, "~ patient_voucher + doctor_voucher | date_morning_survey")),
              data = data, cluster = ~cscomnum_OS)
  cat(sprintf("   (no-controls ref: beta_P = %.4f, beta_D = %.4f)\n",
              coef(m0)["patient_voucher"], coef(m0)["doctor_voucher"]))
  list(bP = unname(coef(m)["patient_voucher"]), bD = unname(coef(m)["doctor_voucher"]), N = nobs(m))
}

# ---- sample: all patients interviewed in the in-clinic survey --------------------
s <- d[!is.na(d$patient) & d$patient == 1, ]
cat("Clinic-survey patients:", nrow(s), " clinics:", length(unique(s$cscomnum_OS)),
    " dates:", length(unique(s$date_morning_survey)), "\n")

outs <- c(col1 = "used_vouchers_admin",      # used voucher (admin records)
          col2 = "RXtreat_sev_simple_mal",   # any malaria treatment prescribed
          col3 = "treat_sev_simple_mal",     # any malaria treatment purchased
          col4 = "RXtreat_severe_mal",       # severe malaria treatment prescribed
          col5 = "treat_severe_mal")         # severe malaria treatment purchased
res <- lapply(outs, pds, data = s)

for (k in names(outs)) {
  ctrl <- s[!is.na(s[[outs[k]]]) & s$patient_voucher == 0 & s$doctor_voucher == 0, outs[k]]
  cat(sprintf("Control mean %s (%s): %.4f\n", k, outs[k], mean(ctrl)))
}

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
