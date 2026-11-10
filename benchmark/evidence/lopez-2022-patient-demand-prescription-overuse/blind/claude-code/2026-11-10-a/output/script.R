# Lopez, Sautmann & Schaner (2022), Table 3: impacts on voucher use and malaria treatment.
# Spec (paper eq. 1 + Sec. 4.1, Table 3 notes):
#   y_ict = b0 + bP*PV_ct + bD*DV_ct + date FE + x'a + e,  SEs clustered by clinic,
#   x chosen by post-double-selection lasso (Belloni, Chernozhukov, Hansen 2014) from
#   clinic dummies + patient/respondent controls (with squares, missing dummies, pairwise
#   interactions); date FE partialled out (always included).
# Lasso: rigorous/plug-in lasso (lassopack rlasso style) with cluster-robust penalty loadings,
#   c = 1.1, gamma = 0.1/log(#clusters), iterated penalty loadings from post-lasso residuals.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-a/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
d <- as.data.frame(zap_labels(d))
d <- d[!is.na(d$patient) & d$patient == 1, ]          # in-clinic survey patients
cat("in-clinic survey patients:", nrow(d), "\n")

nm <- names(d)
ctrl <- c(grep("^CC", nm, value = TRUE), grep("^CL[0-9]+$", nm, value = TRUE))
d$date_fe <- factor(as.numeric(d$date_morning_survey))
d$clinic <- d$cscomnum_OS
d$PV <- as.numeric(d$patient_voucher); d$DV <- as.numeric(d$doctor_voucher)

# ---- partial out date FE (and constant) ----
partial_out <- function(M, f) {
  M <- as.matrix(M)
  apply(M, 2, function(v) v - ave(v, f))
}

# ---- lasso with penalty loadings: min (1/n)||y-Xb||^2 + (lambda/n) sum psi_j |b_j| ----
lasso_cd <- function(XtX, Xty, pen, b0 = NULL, tol = 1e-10, maxit = 100000) {
  p <- length(Xty); b <- if (is.null(b0)) rep(0, p) else b0
  dg <- diag(XtX)
  g <- Xty - as.vector(XtX %*% b)            # X'(y - Xb)
  for (it in 1:maxit) {
    maxd <- 0
    for (j in 1:p) {
      z <- g[j] + dg[j] * b[j]
      bn <- if (z > pen[j]) (z - pen[j]) / dg[j] else if (z < -pen[j]) (z + pen[j]) / dg[j] else 0
      dlt <- bn - b[j]
      if (dlt != 0) {
        g <- g - XtX[, j] * dlt
        b[j] <- bn
        maxd <- max(maxd, abs(dlt) * sqrt(dg[j]))
      }
    }
    if (maxd < tol) break
  }
  b
}

cluster_loadings <- function(X, e, cl) {
  S <- rowsum(X * e, cl)                       # G x p cluster sums
  sqrt(colSums(S^2) / nrow(X))
}

rlasso_select <- function(y, X, cl, c = 1.1, maxpsiiter = 15, psitol = 1e-5) {
  n <- nrow(X); p <- ncol(X); G <- length(unique(cl))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  XtX <- crossprod(X); Xty <- as.vector(crossprod(X, y))
  # initial residuals: OLS of y on the 5 regressors most correlated with y
  cr <- abs(suppressWarnings(cor(X, y))); cr[is.na(cr)] <- 0
  top <- order(cr, decreasing = TRUE)[1:5]
  e <- as.vector(lm.fit(cbind(1, X[, top]), y)$residuals)
  psi <- cluster_loadings(X, e, cl)
  b <- NULL; sel_old <- integer(0)
  for (k in 1:maxpsiiter) {
    b <- lasso_cd(XtX, Xty, lambda * psi / 2, b0 = b)
    sel <- which(b != 0)
    if (length(sel) > 0) {
      e <- as.vector(lm.fit(cbind(1, X[, sel, drop = FALSE]), y)$residuals)
    } else e <- y - mean(y)
    psi_new <- cluster_loadings(X, e, cl)
    conv <- max(abs(psi_new - psi) / pmax(psi, 1e-12)) < psitol
    psi <- psi_new
    if (conv) break
  }
  colnames(X)[sel]
}

pds <- function(yvar) {
  s <- d[!is.na(d[[yvar]]), ]
  f <- s$date_fe
  X <- as.matrix(s[, ctrl]); X <- X[, apply(X, 2, sd) > 0, drop = FALSE]
  Xt <- partial_out(X, f)
  Xt <- Xt[, apply(Xt, 2, function(v) sd(v) > 1e-10), drop = FALSE]
  yt <- as.vector(partial_out(s[[yvar]], f))
  pvt <- as.vector(partial_out(s$PV, f)); dvt <- as.vector(partial_out(s$DV, f))
  sel <- union(rlasso_select(yt, Xt, s$clinic),
               union(rlasso_select(pvt, Xt, s$clinic), rlasso_select(dvt, Xt, s$clinic)))
  cat(yvar, ": N =", nrow(s), " candidate controls =", ncol(Xt), " selected =", length(sel), "\n")
  cat("  selected:", paste(sel, collapse = " "), "\n")
  fml <- if (length(sel) > 0) as.formula(paste(yvar, "~ PV + DV +", paste(sel, collapse = " + "), "| date_fe"))
         else as.formula(paste(yvar, "~ PV + DV | date_fe"))
  m <- feols(fml, data = s, cluster = ~clinic)
  ct <- coeftable(m)
  cat(sprintf("  PV = %.4f (%.4f)   DV = %.4f (%.4f)   p(PV=DV) = %.3f   ctrl mean = %.3f\n",
              ct["PV", 1], ct["PV", 2], ct["DV", 1], ct["DV", 2],
              wald(m, keep = "^PV$|^DV$", print = FALSE)$p * NA_real_ +
                tryCatch({ V <- vcov(m)[c("PV","DV"), c("PV","DV")]; dd <- coef(m)["PV"] - coef(m)["DV"]
                  2 * pt(-abs(dd / sqrt(V[1,1] + V[2,2] - 2 * V[1,2])), df = fitstat(m, "g")[[1]] - 1) }, error = function(e) NA),
              mean(s[[yvar]][s$PV == 0 & s$DV == 0])))
  list(PV = unname(coef(m)["PV"]), DV = unname(coef(m)["DV"]), N = nobs(m))
}

outs <- c(col1 = "used_vouchers_admin", col2 = "RXtreat_sev_simple_mal", col3 = "treat_sev_simple_mal",
          col4 = "RXtreat_severe_mal", col5 = "treat_severe_mal")
res <- lapply(outs, pds)

cat(sprintf("RESULT:voucher_used_patient_voucher_table3_col1=%.6f\n", res$col1$PV))
cat(sprintf("RESULT:voucher_used_doctor_voucher_table3_col1=%.6f\n", res$col1$DV))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_patient_voucher_table3_col2=%.6f\n", res$col2$PV))
cat(sprintf("RESULT:any_malaria_treatment_prescribed_doctor_voucher_table3_col2=%.6f\n", res$col2$DV))
cat(sprintf("RESULT:any_malaria_treatment_purchased_patient_voucher_table3_col3=%.6f\n", res$col3$PV))
cat(sprintf("RESULT:any_malaria_treatment_purchased_doctor_voucher_table3_col3=%.6f\n", res$col3$DV))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_patient_voucher_table3_col4=%.6f\n", res$col4$PV))
cat(sprintf("RESULT:severe_malaria_treatment_prescribed_doctor_voucher_table3_col4=%.6f\n", res$col4$DV))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_patient_voucher_table3_col5=%.6f\n", res$col5$PV))
cat(sprintf("RESULT:severe_malaria_treatment_purchased_doctor_voucher_table3_col5=%.6f\n", res$col5$DV))
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", res$col1$N))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", res$col2$N))
