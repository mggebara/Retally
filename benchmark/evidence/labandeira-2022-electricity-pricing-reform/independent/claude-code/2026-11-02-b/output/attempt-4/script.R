# Independent reproduction of Labandeira et al. (2022), Table 2
# ln(q_it) = a + b ln(p_it) + ln(y) + ln(y)^2 + gX + d T + months-since-reform + quarter + year FE (+ household FE)
# IV: ln price instrumented with effective prices of potatoes, water, fuel; LIML.
set.seed(42)
suppressMessages({library(haven); library(data.table); library(fixest); library(ivreg); library(sandwich)})

f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- as.data.table(read_dta(f))

# Sample: 2011-2014 panel (Aug 2011 - Apr 2014 interviews), T defined (T2 non-missing)
s <- d[!is.na(T2)]
s[, `:=`(lnq = lnc_ele, lng = lng_ele, lnp = lnPRE,       # deflated household price per kWh
         z1 = lnPRE_papas_, z2 = lnPRE_aguav_, z3 = lnPRE_gascar_,
         T = T2, months = dist)]
s[, `:=`(educ = factor(ESTUDREDSP), situ = factor(SITUACTHOG_j), tam = factor(TAMAMU),
         ccaa = factor(CCAA), quarter = factor(trim), yr = factor(year))]
need <- c("lnq","lng","lnp","lny","lny2","T","months","NMIEMB","NHABIT","SUPERF","mayores",
          "educ","situ","alqui","edif25","tam","urban","CAPROV","ccaa","quarter","yr","z1","z2","z3","id")
s <- s[complete.cases(s[, ..need])]
cat("N =", nrow(s), " households =", uniqueN(s$id), "\n")

ctrl <- "lny + lny2 + months + NMIEMB + NHABIT + SUPERF + mayores + educ + situ + alqui + edif25 + tam + urban + CAPROV + ccaa + quarter + yr"

# --- OLS and FE-OLS (fixest, household-clustered SE)
ols <- function(dep, fe) {
  fml <- as.formula(paste(dep, "~ T + lnp +", ctrl, if (fe) "| id" else ""))
  feols(fml, data = s, cluster = ~id)
}
m1 <- ols("lnq", FALSE); m3 <- ols("lnq", TRUE); m5 <- ols("lng", FALSE); m7 <- ols("lng", TRUE)

# --- LIML (ivreg), pooled and within-household
Xexo <- model.matrix(as.formula(paste("~ T +", ctrl)), data = s)
liml <- function(dep, fe) {
  y <- s[[dep]]; p <- s$lnp; Z <- as.matrix(s[, .(z1, z2, z3)]); X <- Xexo
  if (fe) {
    X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
    dm <- demean(cbind(y = y, p = p, Z, X), f = list(id = s$id))
    y <- dm[, "y"]; p <- dm[, "p"]; Z <- dm[, c("z1","z2","z3")]; X <- dm[, colnames(X), drop = FALSE]
    keep <- apply(X, 2, function(v) sd(v) > 1e-8); X <- X[, keep, drop = FALSE]
  }
  q <- qr(X); X <- X[, q$pivot[seq_len(q$rank)], drop = FALSE]
  # LIML as k-class estimator; installed ivreg has no LIML method
  ZZ <- cbind(X, Z)
  resid_on <- function(A, B) qr.resid(qr(B), A)
  Y <- cbind(y, p)
  S1 <- crossprod(resid_on(Y, X)); S2 <- crossprod(resid_on(Y, ZZ))
  k <- min(Re(eigen(solve(S2, S1), only.values = TRUE)$values))  # min eig of (Y'M_Z Y)^-1 Y'M_X Y
  Xa <- cbind(lnp = p, X)
  MXa <- resid_on(Xa, ZZ)
  Xt <- Xa - k * MXa                      # (I - k M_Z) Xa
  A <- crossprod(Xt, Xa)
  b <- drop(solve(A, crossprod(Xt, y)))
  u <- drop(y - Xa %*% b)
  sc <- rowsum(Xt * u, s$id)
  G <- nrow(sc); N <- length(y); K <- ncol(Xa)
  Ai <- solve(A)
  V <- Ai %*% crossprod(sc) %*% t(Ai) * (G / (G - 1)) * ((N - 1) / (N - K))
  names(b) <- colnames(Xa)
  list(b = b, se = setNames(sqrt(diag(V)), colnames(Xa)), k = k)
}
m2 <- liml("lnq", FALSE); m4 <- liml("lnq", TRUE); m6 <- liml("lng", FALSE); m8 <- liml("lng", TRUE)

pr <- function(lab, m) {
  if (inherits(m, "fixest")) { b <- coef(m); se <- se(m) } else { b <- m$b; se <- m$se }
  cat(sprintf("%-6s T = %.4f (%.4f)   lnp = %.4f (%.4f)\n", lab, b["T"], se["T"], b["lnp"], se["lnp"]))
}
pr("(1)", m1); pr("(2)", m2); pr("(3)", m3); pr("(4)", m4)
pr("(5)", m5); pr("(6)", m6); pr("(7)", m7); pr("(8)", m8)

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", m2$b["T"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", m4$b["T"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", m6$b["T"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", m8$b["T"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnp"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnp"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(s)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(s$id)))
