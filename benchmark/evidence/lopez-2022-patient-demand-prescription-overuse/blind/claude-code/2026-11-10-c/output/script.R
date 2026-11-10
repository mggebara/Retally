# Retally independent/blind reproduction: Lopez, Sautmann & Schaner (2022), Table 3
# y_ict = b0 + bP PV_ct + bD DV_ct + gamma_t (date FE) + x_ict' a + e_ict,
# x selected by post-double-selection lasso (Belloni, Chernozhukov & Hansen 2014),
# date FE partialled out (always included), SEs clustered by clinic.
# The rigorous (plug-in) lasso is implemented here by hand (no glmnet/hdm in sandbox),
# following the lassopack `rlasso` defaults with cluster-robust penalty loadings.
set.seed(42)
suppressMessages({library(haven); library(fixest)})

D <- "<repo>/benchmark/.cache/claude-code/lopez-2022-patient-demand-prescription-overuse/blind/2026-11-10-c/mount/lopez_2022_patient_demand_prescription_overuse/Lopez_Sautmann_Schaner_2020/Data/"
d <- read_dta(paste0(D, "LSS_analysis_datasets_20201108.dta"))
d <- zap_labels(d)
nm <- names(d)

# ---- sample: patients interviewed in the in-clinic survey ----
d <- d[!is.na(d$patient) & d$patient == 1, ]
cat("In-clinic survey patients:", nrow(d), "\n")

# ---- candidate controls (prebuilt in the analysis file) ----
# CC*: individual-level controls (missings recoded to mean + missing dummies) and
#      their pairwise interactions; CL*: clinic dummies; DD*: date dummies (partialled).
cc <- grep("^CC", nm, value = TRUE)
cl <- grep("^CL[0-9]+$", nm, value = TRUE)
dd <- grep("^DD[0-9]+$", nm, value = TRUE)
cand <- c(cc, cl)
cat("Candidate controls:", length(cand), "(CC:", length(cc), " CL:", length(cl), "); date dummies partialled:", length(dd), "\n")

# ---- rigorous lasso (lassopack rlasso-style) ----
cd_lasso <- function(X, y, pen, beta0 = NULL, tol = 1e-10, maxit = 10000) {
  # minimise (1/N)||y - Xb||^2 + (1/N) sum_j pen_j |b_j|   (pen_j = lambda * psi_j)
  N <- nrow(X); p <- ncol(X)
  b <- if (is.null(beta0)) rep(0, p) else beta0
  r <- y - X %*% b
  xx <- colSums(X^2)
  for (it in 1:maxit) {
    maxd <- 0
    for (j in 1:p) {
      if (xx[j] <= 0) next
      bj <- b[j]
      z <- sum(X[, j] * r) + xx[j] * bj
      nb <- if (z > pen[j] / 2) (z - pen[j] / 2) / xx[j] else if (z < -pen[j] / 2) (z + pen[j] / 2) / xx[j] else 0
      if (nb != bj) {
        r <- r - X[, j] * (nb - bj)
        b[j] <- nb
        maxd <- max(maxd, abs(nb - bj) * sqrt(xx[j] / N))
      }
    }
    if (maxd < tol) break
  }
  b
}

post_ols_resid <- function(X, y, sel) {
  if (length(sel) == 0) return(y)
  as.vector(lm.fit(X[, sel, drop = FALSE], y)$residuals)
}

rlasso_cluster <- function(X, y, cl, c = 1.1, maxpsiiter = 2, corrnumber = 5) {
  N <- nrow(X); p <- ncol(X); G <- length(unique(cl))
  gamma <- 0.1 / log(G)
  lambda <- 2 * c * sqrt(N) * qnorm(1 - gamma / (2 * p))
  clf <- factor(cl)
  psi_fun <- function(e) {
    S <- rowsum(X * e, clf)            # G x p cluster score sums
    sqrt(colSums(S^2) / N)
  }
  # initial residuals: OLS on the corrnumber regressors most correlated with y
  cors <- abs(suppressWarnings(cor(X, y))); cors[is.na(cors)] <- 0
  init <- order(cors, decreasing = TRUE)[1:corrnumber]
  e <- post_ols_resid(X, y, init)
  b <- NULL
  for (k in 1:maxpsiiter) {
    psi <- psi_fun(e)
    pen <- lambda * psi
    pen[psi == 0] <- Inf
    b <- cd_lasso(X, y, pen, beta0 = b)
    sel <- which(b != 0)
    e <- post_ols_resid(X, y, sel)
  }
  list(sel = sel, lambda = lambda)
}

pds <- function(yname, data) {
  dat <- data[!is.na(data[[yname]]), ]
  N <- nrow(dat)
  # partial out constant + date dummies (always-included controls)
  Z <- cbind(1, as.matrix(dat[, dd]))
  qrZ <- qr(Z)
  res <- function(M) qr.resid(qrZ, M)
  X <- res(as.matrix(dat[, cand]))
  keep <- apply(X, 2, function(v) sum(v^2) > 1e-12)
  X <- X[, keep, drop = FALSE]
  candk <- cand[keep]
  ytil <- res(as.numeric(dat[[yname]]))
  sel_all <- integer(0)
  for (v in c(yname, "patient_voucher", "doctor_voucher")) {
    vv <- if (v == yname) ytil else res(as.numeric(dat[[v]]))
    fit <- rlasso_cluster(X, vv, dat$cscomnum_OS)
    cat(sprintf("  lasso for %-26s: %d selected [%s]\n", v, length(fit$sel), paste(candk[fit$sel], collapse = " ")))
    sel_all <- union(sel_all, fit$sel)
  }
  selv <- candk[sort(sel_all)]
  fml <- as.formula(paste(yname, "~ patient_voucher + doctor_voucher",
                          if (length(selv)) paste("+", paste(selv, collapse = " + ")) else "",
                          "| date_morning_survey"))
  m <- feols(fml, data = dat, cluster = ~cscomnum_OS)
  ct <- coeftable(m)
  cat(sprintf("  %s: N=%d, controls=%d; bP=%.5f (se %.5f), bD=%.5f (se %.5f); p(bP=bD)=%.3f\n",
              yname, nobs(m), length(selv),
              ct["patient_voucher", 1], ct["patient_voucher", 2],
              ct["doctor_voucher", 1], ct["doctor_voucher", 2],
              wald(m, keep = "^patient_voucher$|^doctor_voucher$", print = FALSE)$p))
  # explicit test of bP = bD
  V <- vcov(m); b <- coef(m)
  diff <- b["patient_voucher"] - b["doctor_voucher"]
  sed <- sqrt(V["patient_voucher", "patient_voucher"] + V["doctor_voucher", "doctor_voucher"] - 2 * V["patient_voucher", "doctor_voucher"])
  cat(sprintf("  t-test bP=bD: diff=%.5f, p=%.3f (t dist, G-1 df)\n", diff, 2 * pt(-abs(diff / sed), df = 59)))
  list(bP = unname(b["patient_voucher"]), bD = unname(b["doctor_voucher"]), N = nobs(m))
}

outs <- c(col1 = "used_vouchers_admin",
          col2 = "RXtreat_sev_simple_mal",
          col3 = "treat_sev_simple_mal",
          col4 = "RXtreat_severe_mal",
          col5 = "treat_severe_mal")
res <- list()
for (k in names(outs)) {
  cat("Table 3", k, "outcome", outs[k], "\n")
  res[[k]] <- pds(outs[k], d)
}

nm_out <- list(
  col1 = c("voucher_used_patient_voucher_table3_col1", "voucher_used_doctor_voucher_table3_col1"),
  col2 = c("any_malaria_treatment_prescribed_patient_voucher_table3_col2", "any_malaria_treatment_prescribed_doctor_voucher_table3_col2"),
  col3 = c("any_malaria_treatment_purchased_patient_voucher_table3_col3", "any_malaria_treatment_purchased_doctor_voucher_table3_col3"),
  col4 = c("severe_malaria_treatment_prescribed_patient_voucher_table3_col4", "severe_malaria_treatment_prescribed_doctor_voucher_table3_col4"),
  col5 = c("severe_malaria_treatment_purchased_patient_voucher_table3_col5", "severe_malaria_treatment_purchased_doctor_voucher_table3_col5"))
for (k in names(nm_out)) {
  cat(sprintf("RESULT:%s=%.6f\n", nm_out[[k]][1], res[[k]]$bP))
  cat(sprintf("RESULT:%s=%.6f\n", nm_out[[k]][2], res[[k]]$bD))
}
cat(sprintf("RESULT:n_obs_table3_col1=%d\n", res$col1$N))
cat(sprintf("RESULT:n_obs_table3_cols2_5=%d\n", res$col2$N))
