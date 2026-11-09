# Labandeira, Labeaga & Teixido -- Table 2 (2011-2014 panel), independent blind reproduction
suppressPackageStartupMessages({library(data.table); library(fixest)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-07-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/Data_to run_DOFILE3.csv"
cols <- c("T2","id","year","lnc_ele","lng_ele","lnp_kwh","lnp_papas","lnp_aguav","lnp_gascar",
          "lny","lny2","dist","trim","NMIEMB","NHABIT","SUPERF","mayores","ESTUDREDSP",
          "SITUACTHOG_j","alqui","edif25","urban","CAPROV","CCAA","TAMAMU")
d <- fread(f, select = cols)
# Analysis panel: households interviewed Aug 2011 - Apr 2014 (T2, the post-reform interview dummy, is
# defined exactly on this 25,775-observation panel)
x <- d[!is.na(T2)]
cat("Panel rows:", nrow(x), " households:", uniqueN(x$id), "\n")
# Common estimation sample: complete data on all regression variables incl. the three instruments
need <- setdiff(cols, character(0))
x <- x[complete.cases(x[, ..need])]
x <- x[is.finite(lnp_papas) & is.finite(lnp_aguav) & is.finite(lnp_gascar)]
cat("Estimation sample:", nrow(x), " households:", uniqueN(x$id),
    " singleton households:", sum(x[, .N, by = id]$N == 1), "\n")

ctrl <- "lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + urban + CAPROV + i(TAMAMU) + i(CCAA) + i(trim)"

# ---- OLS / LSDV via fixest ----
ols <- function(dep, fe) {
  fml <- as.formula(paste(dep, "~ T2 + lnp_kwh +", ctrl, "|", if (fe) "id + year" else "year"))
  feols(fml, data = x, cluster = ~id)
}
m1 <- ols("lnc_ele", FALSE); m3 <- ols("lnc_ele", TRUE)
m5 <- ols("lng_ele", FALSE); m7 <- ols("lng_ele", TRUE)

# ---- LIML (k-class) with optional household FE, household-clustered SEs ----
X_exog <- model.matrix(as.formula(paste("~ T2 +", gsub("i\\(([A-Za-z_]+)\\)", "factor(\\1)", ctrl), "+ factor(year)")), data = x)
liml <- function(dep, fe) {
  y <- x[[dep]]; p <- x$lnp_kwh
  Z <- as.matrix(x[, .(lnp_papas, lnp_aguav, lnp_gascar)])
  W <- X_exog
  if (fe) {
    W <- W[, colnames(W) != "(Intercept)", drop = FALSE]
    dm <- fixest::demean(cbind(y = y, p = p, Z, W), f = x[, .(id)])
    y <- dm[, "y"]; p <- dm[, "p"]; Z <- dm[, colnames(Z), drop = FALSE]; W <- dm[, colnames(W), drop = FALSE]
  }
  keep <- apply(W, 2, function(v) sd(v) > 1e-10 || all(v == 1))
  W <- W[, keep, drop = FALSE]
  q <- qr(W, tol = 1e-9); W <- W[, q$pivot[seq_len(q$rank)], drop = FALSE]
  Zall <- cbind(Z, W)
  res <- function(A, B) qr.resid(qr(B), A)
  Y <- cbind(y, p)
  e_x <- res(Y, W); e_z <- res(Y, Zall)
  kappa <- min(Re(eigen(solve(crossprod(e_z), crossprod(e_x)))$values))
  Xa <- cbind(lnp_kwh = p, W)
  Xh <- Xa - kappa * res(Xa, Zall)          # k-class "instruments"
  A <- crossprod(Xh, Xa)
  b <- solve(A, crossprod(Xh, y))
  u <- as.vector(y - Xa %*% b)
  S <- rowsum(Xh * u, x$id)
  G <- nrow(S); N <- length(y); K <- ncol(Xa) + if (fe) G else 0
  Ai <- solve(A)
  V <- Ai %*% crossprod(S) %*% t(Ai) * (G / (G - 1))
  # first-stage F (non-robust, excluded instruments) for diagnostics
  fs_r <- sum(res(p, W)^2); fs_u <- sum(res(p, Zall)^2)
  Ff <- ((fs_r - fs_u) / ncol(Z)) / (fs_u / (N - ncol(Zall) - if (fe) G else 0))
  list(b = setNames(as.vector(b), colnames(Xa)), se = setNames(sqrt(diag(V)), colnames(Xa)), kappa = kappa, F = Ff)
}
m2 <- liml("lnc_ele", FALSE); m4 <- liml("lnc_ele", TRUE)
m6 <- liml("lng_ele", FALSE); m8 <- liml("lng_ele", TRUE)

show <- function(lab, b, se) cat(sprintf("%-6s T: %8.4f (%6.4f)   lnp: %8.4f (%6.4f)\n", lab, b["T2"], se["T2"], b["lnp_kwh"], se["lnp_kwh"]))
for (nm in c("m1","m3","m5","m7")) { m <- get(nm); show(nm, coef(m), se(m)) }
for (nm in c("m2","m4","m6","m8")) { m <- get(nm); show(nm, m$b, m$se); cat(sprintf("       kappa=%.4f firststageF=%.2f\n", m$kappa, m$F)) }
cat("nobs fixest:", nobs(m1), nobs(m3), nobs(m5), nobs(m7), "\n")

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T2"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", m2$b["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", m4$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T2"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", m6$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", m8$b["T2"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnp_kwh"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnp_kwh"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(x)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(x$id)))
