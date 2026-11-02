## Labandeira, Labeaga & Teixido (2022) - Table 2, independent reproduction
suppressPackageStartupMessages({library(haven); library(data.table); library(fixest)})
set.seed(42)
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
cols <- c("T2","dist","Tm","id","year","lnc_ele","lng_ele","lnPRE","lny","lny2",
          "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_",
          "NMIEMB","NHABIT","SUPERF","mayores","edif25","alqui","urban","CAPROV",
          "TAMAMU","CCAA","ESTUDREDSP","SITUACTHOG_j","trim")
d <- as.data.table(read_dta(f, col_select = all_of(cols)))
d <- d[!is.na(T2)]                       # analysis panel Aug 2011 - Apr 2014 (25,775 obs)
cat("panel obs:", nrow(d), "\n")
setnames(d, c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_"), c("z_pap","z_agu","z_gas"))
d[, `:=`(fy=factor(year), fq=factor(trim), ftam=factor(TAMAMU), fccaa=factor(CCAA),
         fest=factor(ESTUDREDSP), fsit=factor(SITUACTHOG_j))]
need <- c("lnc_ele","lng_ele","lnPRE","lny","lny2","dist","NMIEMB","NHABIT","SUPERF","mayores",
          "edif25","alqui","urban","CAPROV","TAMAMU","CCAA","ESTUDREDSP","SITUACTHOG_j","trim",
          "z_pap","z_agu","z_gas","T2","year")
d <- d[complete.cases(d[, ..need])]
cat("estimation obs:", nrow(d), " households:", uniqueN(d$id), "\n")

ctrl <- "lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + edif25 + alqui + urban + CAPROV + fest + fsit + ftam + fccaa + fq + fy"
fols <- function(dep, fe) {
  fml <- as.formula(paste(dep, "~ T2 + lnPRE +", ctrl, if (fe) "| id" else ""))
  feols(fml, data = d, cluster = ~id)
}

## LIML (k-class) with one endogenous regressor; FE handled by within-household demeaning
liml <- function(dep, fe) {
  X <- model.matrix(as.formula(paste("~ T2 +", ctrl)), d)       # exogenous incl. constant
  y <- d[[dep]]; x <- d$lnPRE; Z <- as.matrix(d[, .(z_pap, z_agu, z_gas)])
  if (fe) {
    X <- X[, colnames(X) != "(Intercept)", drop = FALSE]
    dm <- demean(cbind(y = y, x = x, Z, X), f = d$id)
    y <- dm[, "y"]; x <- dm[, "x"]; Z <- dm[, colnames(Z)]; X <- dm[, colnames(X), drop = FALSE]
  }
  q <- qr(X); X <- X[, q$pivot[seq_len(q$rank)], drop = FALSE]   # drop collinear columns
  W <- cbind(X, Z)
  res <- function(A, B) qr.resid(qr(B), A)
  Y <- cbind(y, x)
  S1 <- crossprod(res(Y, X)); S2 <- crossprod(res(Y, W))
  k <- min(Re(eigen(solve(S2) %*% S1, only.values = TRUE)$values))
  R <- cbind(x = x, X)
  RW <- res(R, W)
  A <- crossprod(R) - k * crossprod(RW)
  b <- solve(A, crossprod(R, y) - k * crossprod(RW, y))
  # cluster-robust variance (household)
  e <- as.vector(y - R %*% b)
  Rt <- R - k * RW
  Ai <- solve(A)
  sc <- rowsum(Rt * e, d$id)
  V <- Ai %*% crossprod(sc) %*% Ai
  out <- setNames(as.vector(b), c("lnPRE", colnames(X)))
  list(b = out, se = sqrt(diag(V))[1:2], k = k)
}

m1 <- fols("lnc_ele", FALSE); m3 <- fols("lnc_ele", TRUE)
m5 <- fols("lng_ele", FALSE); m7 <- fols("lng_ele", TRUE)
m2 <- liml("lnc_ele", FALSE); m4 <- liml("lnc_ele", TRUE)
m6 <- liml("lng_ele", FALSE); m8 <- liml("lng_ele", TRUE)
for (m in list(m1, m3, m5, m7)) print(coeftable(m)[c("T2","lnPRE"), ])
for (m in list(m2, m4, m6, m8)) cat("LIML kappa", m$k, " T2", m$b["T2"], " lnPRE", m$b["lnPRE"], "\n")

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T2"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", m2$b["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T2"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", m4$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T2"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", m6$b["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T2"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", m8$b["T2"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnPRE"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnPRE"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", uniqueN(d$id)))
