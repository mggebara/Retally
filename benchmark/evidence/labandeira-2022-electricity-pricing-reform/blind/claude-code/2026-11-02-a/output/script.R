# Labandeira, Labeaga & Teixido (2022) -- Table 2, independent blind reproduction
set.seed(42)
suppressPackageStartupMessages({library(haven); library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
vars <- c("T2","id","year","trim","dist","lnp_kwh","lnc_ele","lng_ele","lny","lny2","IP",
          "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_",
          "NMIEMB","NHABIT","SUPERF","mayores","alqui","edif25","urban","CAPROP","TAMAMU",
          "ESTUDREDSP","SITUACTHOG_j","CCAA")
d <- as.data.table(read_dta(f, col_select = all_of(vars)))
d <- d[!is.na(T2)]                       # Aug 2011 - Apr 2014 panel (two interviews per household)
for (v in names(d)) d[[v]] <- as.numeric(d[[v]])
# instruments: households' effective (expenditure/quantity) prices of potatoes, water and fuel, in
# nominal logs (deflated filled-in series + log price index; equals lnp_* where purchased)
d[, z_pap := lnPRE_papas_ + IP]; d[, z_agu := lnPRE_aguav_ + IP]; d[, z_gas := lnPRE_gascar_ + IP]
need <- c("lnc_ele","lng_ele","lnp_kwh","T2","dist","lny","lny2","z_pap","z_agu","z_gas",
          "NMIEMB","NHABIT","SUPERF","mayores","alqui","edif25","urban","CAPROP","TAMAMU",
          "ESTUDREDSP","SITUACTHOG_j","CCAA","trim","year","id")
d <- d[complete.cases(d[, ..need])]
cat("estimation sample:", nrow(d), "obs,", uniqueN(d$id), "households\n")

ctrl <- "NMIEMB + NHABIT + SUPERF + mayores + i(ESTUDREDSP) + i(SITUACTHOG_j) + alqui + edif25 + i(TAMAMU) + urban + i(CAPROP) + i(CCAA) + i(trim) + i(year)"
exo  <- paste("T2 + dist + lny + lny2 +", ctrl)

ols <- function(y, fe) {
  fml <- as.formula(paste(y, "~ lnp_kwh +", exo, if (fe) "| id" else ""))
  feols(fml, data = d, cluster = ~id)
}

# LIML via k-class on variables with exogenous regressors (and FE) partialled out (FWL)
liml <- function(y, fe) {
  fml <- as.formula(paste("c(", y, ", lnp_kwh, z_pap, z_agu, z_gas) ~", exo, if (fe) "| id" else ""))
  m <- feols(fml, data = d)
  R <- sapply(m, resid)                 # columns: y, p, z1, z2, z3 (residualised)
  yt <- R[,1]; pt <- R[,2]; Z <- R[,3:5]
  Y <- cbind(yt, pt)
  QZ <- qr(Z)
  MZY <- Y - qr.fitted(QZ, Y)
  A <- crossprod(Y); B <- crossprod(MZY)
  kappa <- min(Re(eigen(solve(B) %*% A, only.values = TRUE)$values))
  Mzp <- pt - qr.fitted(QZ, pt)
  # (I - k M_Z) applied: p'(I-kM)p, p'(I-kM)y
  num <- sum(pt * yt) - kappa * sum(Mzp * (yt - qr.fitted(QZ, yt)))
  den <- sum(pt * pt) - kappa * sum(Mzp * Mzp)
  beta <- num / den
  # exogenous coefficients given beta: OLS of (y - beta p) on exogenous set
  d[, ystar := get(y) - beta * lnp_kwh]
  m2 <- feols(as.formula(paste("ystar ~", exo, if (fe) "| id" else "")), data = d)
  list(beta = beta, delta = unname(coef(m2)["T2"]), kappa = kappa, n = nobs(m2))
}

m1 <- ols("lnc_ele", FALSE); m3 <- ols("lnc_ele", TRUE)
m5 <- ols("lng_ele", FALSE); m7 <- ols("lng_ele", TRUE)
i2 <- liml("lnc_ele", FALSE); i4 <- liml("lnc_ele", TRUE)
i6 <- liml("lng_ele", FALSE); i8 <- liml("lng_ele", TRUE)

show <- function(lab, m) cat(sprintf("%-6s T=%.4f (se %.4f)  lnp=%.4f (se %.4f)  N=%d\n", lab,
  coef(m)["T2"], se(m)["T2"], coef(m)["lnp_kwh"], se(m)["lnp_kwh"], nobs(m)))
show("col1", m1); show("col3", m3); show("col5", m5); show("col7", m7)
for (nm in c("i2","i4","i6","i8")) { r <- get(nm); cat(sprintf("%-6s T=%.4f lnp=%.4f kappa=%.5f N=%d\n", nm, r$delta, r$beta, r$kappa, r$n)) }

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T2"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", i2$delta))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", i4$delta))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T2"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", i6$delta))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", i8$delta))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnp_kwh"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnp_kwh"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(d$id)))
