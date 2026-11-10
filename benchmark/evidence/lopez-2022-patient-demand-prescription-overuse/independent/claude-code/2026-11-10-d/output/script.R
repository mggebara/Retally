# Lopez, Sautmann & Schaner (2022) -- Table 3, independent reproduction
# Spec: y = bP*PV + bD*DV + date FE + controls chosen by post-double-selection lasso
#       (Belloni, Chernozhukov & Hansen 2014), SEs clustered by clinic.
# Lasso: "rigorous" plug-in lasso (heteroskedastic penalty loadings, c=1.1,
#        gamma=0.1/log(n)), date FE + constant partialled out (always included).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

f <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/independent/2026-11-10-d/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/LSS_analysis_datasets_20201108.dta"
d0 <- read_dta(f)
d <- d0[d0$dropme == 0, ]
d <- as.data.frame(zap_labels(d))
cat("Analysis sample (dropme==0):", nrow(d), "\n")
cat("Clinics:", length(unique(d$cscomnum_OS)), " Dates:", length(unique(d$date_morning_survey)), "\n")

# ---- candidate controls (pre-built in the analysis file) ----
nm <- names(d)
cc_main <- grep("^CC[0-9]+$", nm, value = TRUE)
cc_int  <- grep("^CC[0-9]+xCC[0-9]+$", nm, value = TRUE)
cl      <- grep("^CL[0-9]+$", nm, value = TRUE)
cand <- c(cc_main, cc_int, cl)
cat("Candidates: main", length(cc_main), " interactions", length(cc_int), " clinic", length(cl), "\n")

d$datefe <- as.integer(as.numeric(d$date_morning_survey))
d$PV <- as.numeric(d$patient_voucher)
d$DV <- as.numeric(d$doctor_voucher)

# within-date demeaning (partials out date FE and constant)
dm <- function(v, g) v - ave(v, g, FUN = mean)

cd_lasso <- function(y, X, lam, psi, b = rep(0, ncol(X)), tol = 1e-9, maxit = 10000) {
  xx <- colSums(X^2)
  r <- y - X %*% b
  thr <- lam * psi / 2
  for (it in 1:maxit) {
    maxd <- 0
    for (j in seq_len(ncol(X))) {
      if (xx[j] <= 0) next
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- if (z > thr[j]) (z - thr[j]) / xx[j] else if (z < -thr[j]) (z + thr[j]) / xx[j] else 0
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

post_resid <- function(y, X, sel) {
  if (!any(sel)) return(y)
  as.numeric(lm.fit(X[, sel, drop = FALSE], y)$residuals)
}

rlasso <- function(y, X, c = 1.1, maxiter = 15, tol = 1e-4) {
  n <- length(y); p <- ncol(X)
  gamma <- 0.1 / log(n)
  lam <- 2 * c * sqrt(n) * qnorm(1 - gamma / (2 * p))
  # initial residuals: OLS on 5 most correlated regressors
  cr <- abs(suppressWarnings(cor(X, y))); cr[is.na(cr)] <- 0
  top <- order(-cr)[1:min(5, p)]
  e <- post_resid(y, X, seq_len(p) %in% top)
  psi_old <- rep(Inf, p); b <- rep(0, p)
  for (k in 1:maxiter) {
    psi <- sqrt(colMeans(X^2 * e^2))
    psi[psi == 0] <- 1e10
    b <- cd_lasso(y, X, lam, psi, b)
    sel <- b != 0
    e <- post_resid(y, X, sel)
    if (max(abs(psi - psi_old)) < tol) break
    psi_old <- psi
  }
  colnames(X)[sel]
}

pds <- function(yname, data) {
  dd <- data[!is.na(data[[yname]]), ]
  g <- dd$datefe
  X <- as.matrix(dd[, cand])
  X <- apply(X, 2, dm, g = g)
  keep <- apply(X, 2, function(v) sd(v) > 1e-10)
  X <- X[, keep, drop = FALSE]
  sy <- rlasso(dm(dd[[yname]], g), X)
  sP <- rlasso(dm(dd$PV, g), X)
  sD <- rlasso(dm(dd$DV, g), X)
  sel <- union(union(sy, sP), sD)
  cat(sprintf("%s: n=%d, sel y=%d PV=%d DV=%d union=%d: %s\n", yname, nrow(dd),
              length(sy), length(sP), length(sD), length(sel), paste(sel, collapse = " ")))
  fml <- if (length(sel)) as.formula(paste(yname, "~ PV + DV +", paste(sel, collapse = "+"), "| datefe"))
         else as.formula(paste(yname, "~ PV + DV | datefe"))
  m <- feols(fml, data = dd, cluster = ~cscomnum_OS)
  ctrl_mean <- mean(dd[[yname]][dd$PV == 0 & dd$DV == 0])
  cat(sprintf("   bP=%.4f (%.4f)  bD=%.4f (%.4f)  N=%d  ctrl mean=%.3f\n", coef(m)["PV"], se(m)["PV"],
              coef(m)["DV"], se(m)["DV"], nobs(m), ctrl_mean))
  m
}

outs <- c(voucher_used = "used_vouchers_admin",
          any_malaria_treatment_prescribed = "RXtreat_sev_simple_mal",
          any_malaria_treatment_purchased = "treat_sev_simple_mal",
          severe_malaria_treatment_prescribed = "RXtreat_severe_mal",
          severe_malaria_treatment_purchased = "treat_severe_mal")
cols <- c("table3_col1", "table3_col2", "table3_col3", "table3_col4", "table3_col5")

res <- list()
for (i in seq_along(outs)) res[[i]] <- pds(outs[i], d)

for (i in seq_along(outs)) {
  m <- res[[i]]
  cat(sprintf("RESULT:%s_patient_voucher_%s=%.6f\n", names(outs)[i], cols[i], coef(m)["PV"]))
  cat(sprintf("RESULT:%s_doctor_voucher_%s=%.6f\n", names(outs)[i], cols[i], coef(m)["DV"]))
}
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", nobs(res[[1]])))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", nobs(res[[2]])))
