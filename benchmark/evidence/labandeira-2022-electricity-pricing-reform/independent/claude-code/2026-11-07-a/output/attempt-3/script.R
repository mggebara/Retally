# Independent reproduction of Labandeira et al. (2022) Table 2.
set.seed(42)
suppressMessages({library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-07-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/Data_to run_DOFILE3.csv"
v <- c("T2","id","year","lnc_ele","lng_ele","lnPRE","lny","dist","trim",
       "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_",
       "NMIEMB","NHABIT","SUPERF","mayores","ESTUDREDSP","SITUACTHOG_j","alqui",
       "edif25","TAMAMU","urban","CAPROV","CCAA")
d <- fread(f, select = v)
# 2011-2014 panel (households interviewed Aug 2011 - Apr 2014): rows with the treatment dummy defined
d <- d[!is.na(T2)]
d <- d[complete.cases(d)]
d[, lny2 := lny^2]
cat("N =", nrow(d), " households =", uniqueN(d$id), "\n")

# exogenous regressors (besides log price): T, months since reform, income, income^2,
# controls, quarter, region, year dummies
d[, `:=`(fyear = factor(year), ftrim = factor(trim), fest = factor(ESTUDREDSP),
         fsit = factor(SITUACTHOG_j), ftam = factor(TAMAMU), fccaa = factor(CCAA))]
exo_f <- ~ T2 + dist + lny + lny2 + NMIEMB + NHABIT + SUPERF + mayores + alqui + edif25 +
  urban + CAPROV + fest + fsit + ftam + fccaa + ftrim + fyear
W <- model.matrix(exo_f, d)               # includes intercept
W <- W[, qr(W)$pivot[seq_len(qr(W)$rank)], drop = FALSE]
Z <- as.matrix(d[, .(lnPRE_papas_, lnPRE_aguav_, lnPRE_gascar_)])
x <- d$lnPRE

resid_on <- function(A, B) qr.resid(qr(B), A)

liml <- function(y, x, W, Z) {
  WZ <- cbind(W, Z)
  Y <- cbind(y, x)
  e1 <- resid_on(Y, W); e2 <- resid_on(Y, WZ)
  kappa <- min(Re(eigen(solve(crossprod(e1)) %*% crossprod(e2))$values))
  X <- cbind(x, W)
  MX <- resid_on(X, WZ)                   # M_{WZ} X
  A <- crossprod(X) - kappa * crossprod(X, MX)
  b <- crossprod(X, y) - kappa * crossprod(MX, y)
  beta <- solve(A, b)
  rownames(beta) <- c("lnPRE", colnames(W))
  list(beta = beta[, 1], kappa = kappa)
}

fe_demean <- function(M, id) {
  M <- as.matrix(M)
  M - apply(M, 2, function(col) ave(col, id))
}

res <- list()
for (dep in c("lnc_ele", "lng_ele")) {
  y <- d[[dep]]
  # OLS (cols 1/5)
  fo <- as.formula(paste(dep, "~ lnPRE + T2 + dist + lny + lny2 + NMIEMB + NHABIT + SUPERF + mayores + alqui + edif25 + urban + CAPROV + fest + fsit + ftam + fccaa + ftrim + fyear"))
  ols <- feols(fo, d, cluster = ~id)
  # LSDV / within (cols 3/7)
  fofe <- as.formula(paste(dep, "~ lnPRE + T2 + dist + lny + lny2 + NMIEMB + NHABIT + SUPERF + mayores + alqui + edif25 + urban + CAPROV + fest + fsit + ftam + fccaa + ftrim + fyear | id"))
  fe <- feols(fofe, d, cluster = ~id)
  # LIML IV (cols 2/6)
  iv <- liml(y, x, W, Z)
  # FE LIML IV (cols 4/8): within transform then LIML (no intercept)
  Wd <- fe_demean(W[, -1, drop = FALSE], d$id)
  keep <- apply(Wd, 2, function(c) sum(c^2) > 1e-8)
  Wd <- Wd[, keep, drop = FALSE]
  Wd <- Wd[, qr(Wd)$pivot[seq_len(qr(Wd)$rank)], drop = FALSE]
  ivfe <- liml(fe_demean(y, d$id)[, 1], fe_demean(x, d$id)[, 1], Wd, fe_demean(Z, d$id))
  res[[dep]] <- list(ols = ols, fe = fe, iv = iv, ivfe = ivfe)
  cat("\n====", dep, "\n")
  print(coeftable(ols)[c("lnPRE", "T2", "dist", "lny", "lny2"), ])
  print(coeftable(fe)[c("lnPRE", "T2", "dist", "lny", "lny2"), ])
  cat("LIML:", round(iv$beta[c("lnPRE", "T2", "dist", "lny", "lny2")], 4), " kappa", iv$kappa, "\n")
  cat("FE LIML:", round(ivfe$beta[c("lnPRE", "T2", "dist", "lny", "lny2")], 4), " kappa", ivfe$kappa, "\n")
}

rc <- res$lnc_ele; re <- res$lng_ele
cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(rc$ols)["T2"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", rc$iv$beta["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(rc$fe)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", rc$ivfe$beta["T2"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(re$ols)["T2"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", re$iv$beta["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(re$fe)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", re$ivfe$beta["T2"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(rc$ols)["lnPRE"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(rc$fe)["lnPRE"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(rc$ols)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(d$id)))
