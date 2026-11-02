# Retally: labandeira-2022-electricity-pricing-reform, blind, run 2026-11-02-c
# Table 2 of Labandeira, Labeaga & Teixido: effect of the Aug-2013 Spanish
# electricity pricing reform on log consumption and log expenditure.
# Spec (eq. 4): ln q = a + b ln p + c1 ln y + c2 (ln y)^2 + g X + d T + months-since-reform
#               + quarter dummies + region dummies + year FE (+ household FE) ; cluster by household
# IV: ln p instrumented by effective prices of potatoes, water, fuel; LIML (k-class, coded by hand).
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(data.table); library(fixest) })

f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
keep <- c("T2","id","year","trim","dist","lnc_ele","lng_ele","lnPRE","lny","lny2",
          "NMIEMB","NHABIT","SUPERF","mayores","ESTUDREDSP","SITUACTHOG_j","alqui","edif25",
          "TAMAMU","urban","CAPROV","CCAA","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_")
d <- as.data.table(read_dta(f, col_select = all_of(keep)))
d <- d[!is.na(T2)]                        # 2011-2014 panel (Aug 2011 - Apr 2014), 25,775 obs
cat("panel rows:", nrow(d), " households:", uniqueN(d$id), "\n")
d <- na.omit(d, cols = keep)              # complete data on regression variables
d <- as.data.frame(lapply(d, function(x) as.numeric(x)))
d$id <- as.integer(d$id)
N <- nrow(d); G <- length(unique(d$id))
cat("estimation rows:", N, " households:", G, "\n")

# exogenous regressors (included instruments)
exog_f <- ~ T2 + lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + factor(ESTUDREDSP) +
  factor(SITUACTHOG_j) + alqui + edif25 + factor(TAMAMU) + urban + CAPROV + factor(CCAA) +
  factor(trim) + factor(year)
W <- model.matrix(exog_f, data = d)         # includes intercept
Z <- as.matrix(d[, c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_")])
x <- d$lnPRE

# drop collinear columns of a matrix (keep order)
drop_coll <- function(M, tol = 1e-8) {
  q <- qr(M, tol = tol); keepc <- sort(q$pivot[seq_len(q$rank)]); M[, keepc, drop = FALSE]
}
resid_on <- function(A, B) { q <- qr(B); qr.resid(q, A) }

# k-class / LIML estimator with household-clustered (CR1-type) SEs
liml <- function(y, x, W, Z, cl, fe) {
  if (fe) {   # within transformation by household (LSDV-equivalent point estimates)
    dm <- fixest::demean(cbind(y = y, x = x, W[, -1, drop = FALSE], Z), f = list(id = cl))
    y <- dm[, 1]; x <- dm[, 2]; W <- dm[, 3:(2 + ncol(W) - 1), drop = FALSE]
    Z <- dm[, (3 + ncol(W)):ncol(dm), drop = FALSE]
    W <- W[, apply(W, 2, function(v) sd(v) > 1e-10), drop = FALSE]
  }
  W <- drop_coll(W)
  Zf <- cbind(W, Z)
  Y <- cbind(y, x)
  A <- crossprod(resid_on(Y, W)); B <- crossprod(resid_on(Y, Zf))
  kappa <- min(Re(eigen(solve(B) %*% A)$values))
  X <- cbind(lnp = x, W)
  MzX <- resid_on(X, Zf)
  Xt <- X - kappa * MzX                      # (I - k Mz) X
  b <- solve(crossprod(Xt, X), crossprod(Xt, y))
  u <- as.vector(y - X %*% b)
  bread <- solve(crossprod(Xt, X))
  S <- rowsum(Xt * u, cl)
  ng <- length(unique(cl)); n <- length(y); k <- ncol(X) + if (fe) ng else 0
  V <- bread %*% crossprod(S) %*% bread * (ng / (ng - 1)) * ((n - 1) / (n - k))
  if (fe) V <- bread %*% crossprod(S) %*% bread * (ng / (ng - 1)) * ((n - 1) / (n - ncol(X)))
  list(b = setNames(as.vector(b), colnames(X)), se = setNames(sqrt(diag(V)), colnames(X)), kappa = kappa)
}

rhs <- "T2 + lnPRE + lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA) + i(trim)"
res <- list()
for (dep in c("lnc_ele","lng_ele")) {
  ols <- feols(as.formula(paste(dep, "~", rhs, "| year")), data = d, cluster = ~id)
  fe  <- feols(as.formula(paste(dep, "~", rhs, "| id + year")), data = d, cluster = ~id)
  iv  <- liml(d[[dep]], x, W, Z, d$id, fe = FALSE)
  ivf <- liml(d[[dep]], x, W, Z, d$id, fe = TRUE)
  cat("\n==", dep, "==\n")
  cat(sprintf("OLS    : T=%.4f (%.4f)  lnp=%.4f (%.4f)  n=%d\n", coef(ols)["T2"], se(ols)["T2"], coef(ols)["lnPRE"], se(ols)["lnPRE"], nobs(ols)))
  cat(sprintf("LIML   : T=%.4f (%.4f)  lnp=%.4f (%.4f)  kappa=%.5f\n", iv$b["T2"], iv$se["T2"], iv$b["lnp"], iv$se["lnp"], iv$kappa))
  cat(sprintf("FE     : T=%.4f (%.4f)  lnp=%.4f (%.4f)  n=%d\n", coef(fe)["T2"], se(fe)["T2"], coef(fe)["lnPRE"], se(fe)["lnPRE"], nobs(fe)))
  cat(sprintf("FE-LIML: T=%.4f (%.4f)  lnp=%.4f (%.4f)  kappa=%.5f\n", ivf$b["T2"], ivf$se["T2"], ivf$b["lnp"], ivf$se["lnp"], ivf$kappa))
  res[[dep]] <- list(ols = ols, fe = fe, iv = iv, ivf = ivf)
}
# first stage strength (2SLS first stage, no FE / FE)
fs  <- feols(lnPRE ~ lnPRE_papas_ + lnPRE_aguav_ + lnPRE_gascar_ + T2 + lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA) + i(trim) | year, data = d, cluster = ~id)
fsf <- feols(lnPRE ~ lnPRE_papas_ + lnPRE_aguav_ + lnPRE_gascar_ + T2 + lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + CAPROV + i(CCAA) + i(trim) | id + year, data = d, cluster = ~id)
cat("\nFirst-stage cluster-robust Wald F (excluded instruments): no FE =",
    fitstat(fs, "wald", keep = "lnPRE_")[[1]]$stat, "; FE =", fitstat(fsf, "wald", keep = "lnPRE_")[[1]]$stat, "\n\n")

c_ <- res$lnc_ele; e_ <- res$lng_ele
cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(c_$ols)["T2"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", c_$iv$b["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(c_$fe)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", c_$ivf$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(e_$ols)["T2"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", e_$iv$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(e_$fe)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", e_$ivf$b["T2"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(c_$ols)["lnPRE"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(c_$fe)["lnPRE"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", N))
cat(sprintf("RESULT:n_households_table2=%d\n", G))
