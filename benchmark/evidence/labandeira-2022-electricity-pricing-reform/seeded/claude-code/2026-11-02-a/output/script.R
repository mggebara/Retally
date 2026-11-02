# Labandeira et al. (2022) Table 2 reproduction, following "3_ Results TABLES.do"
set.seed(42)
suppressMessages({library(data.table); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/seeded/2026-11-02-a/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/Data_to run_DOFILE3.csv"
# Stata's i.ESTUDRED resolves (unique abbreviation) to ESTUDREDSP in this dataset
need <- c("lnc_ele","lng_ele","TT202","lnPRE","lny","lny2","dist","TAMAMU","CCAA","CAPROV","NMIEMB","NHABIT","SUPERF","ESTUDREDSP","SITUACTHOG_j","mayores","alqui","urban","edif25","year","trim","id","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_")
dums <- c(paste0("itam",1:5), paste0("iccaa",1:19), paste0("iestud",1:4), paste0("isitu",1:3), paste0("iyear",6:9))
d <- fread(f, select = c(need, dums), showProgress = FALSE)

# sample1: e(sample) of the column-1 OLS regression
v1 <- c("lnc_ele","TT202","lnPRE","lny","dist","TAMAMU","CCAA","CAPROV","NMIEMB","NHABIT","SUPERF","ESTUDREDSP","SITUACTHOG_j","mayores","alqui","urban","edif25","year","trim","id")
s <- d[complete.cases(d[, ..v1])]
rm(d); invisible(gc())
cat("sample1 N =", nrow(s), " ids =", uniqueN(s$id), "\n")

rhs <- "TT202 + lnPRE + lny + I(lny^2) + dist + factor(TAMAMU) + factor(CCAA) + CAPROV + NMIEMB + NHABIT + SUPERF + factor(ESTUDREDSP) + factor(SITUACTHOG_j) + mayores + alqui + urban + edif25 + factor(year) + factor(trim)"

# LIML k-class estimator (no constant unless included in X1)
liml <- function(y, x2, X1, Zx) {
  q <- qr(X1); X1 <- X1[, q$pivot[seq_len(q$rank)], drop = FALSE]
  Z <- cbind(X1, Zx)
  W <- cbind(y, x2)
  eZ <- qr.resid(qr(Z), W); eX <- qr.resid(qr(X1), W)
  k <- min(Re(eigen(solve(crossprod(eZ)) %*% crossprod(eX))$values))
  X <- cbind(x2 = x2, X1)
  MzX <- cbind(eZ[, 2], matrix(0, nrow(X1), ncol(X1)))
  A <- crossprod(X) - k * crossprod(MzX)
  b <- crossprod(X, y) - k * crossprod(MzX, eZ[, 1])
  beta <- drop(solve(A, b)); names(beta) <- c("lnPRE", colnames(X1))
  attr(beta, "kappa") <- k
  beta
}

res <- list()
for (dv in c("lnc_ele", "lng_ele")) {
  # OLS (cols 1/5), clustered by id
  m_ols <- feols(as.formula(paste(dv, "~", rhs)), data = s, cluster = ~id)
  # LSDV / within (cols 3/7)
  m_fe <- feols(as.formula(paste(dv, "~", rhs, "| id")), data = s, cluster = ~id, fixef.rm = "none")
  # IV LIML no FE (cols 2/6): ivreg2 ... nocons
  ex <- c("TT202","lny","lny2","dist", paste0("itam",2:5), paste0("iccaa",2:19), "CAPROV","NMIEMB","NHABIT","SUPERF",
          paste0("iestud",2:4), "isitu2","isitu3","mayores","alqui","urban","edif25", paste0("iyear",7:9))
  zz <- c("lnPRE_aguav_","lnPRE_papas_","lnPRE_gascar_")
  ok <- complete.cases(s[, c(dv, "lnPRE", ex, zz), with = FALSE])
  b_iv <- liml(s[[dv]][ok], s$lnPRE[ok], as.matrix(s[ok, ..ex]), as.matrix(s[ok, ..zz]))
  # FE IV LIML (cols 4/8): within-demeaned variables (means over sample1 by id), nocons
  wv <- c(dv, "TT202","lnPRE","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_","lny","lny2","dist","NMIEMB",
          "iestud1","iestud2","iestud3","isitu2","isitu3","mayores","alqui","edif25","iyear7","iyear8","iyear9")
  w <- s[, lapply(.SD, function(z) z - mean(z)), by = id, .SDcols = wv]
  exw <- c("TT202","lny","lny2","dist","NMIEMB","iestud1","iestud2","iestud3","isitu2","isitu3","mayores","alqui","edif25","iyear7","iyear8","iyear9")
  okw <- complete.cases(w[, wv, with = FALSE])
  b_feiv <- liml(w[[dv]][okw], w$lnPRE[okw], as.matrix(w[okw, ..exw]), as.matrix(w[okw, ..zz]))
  res[[dv]] <- list(ols = coef(m_ols), fe = coef(m_fe), iv = b_iv, feiv = b_feiv,
                    n = c(nobs(m_ols), nobs(m_fe), sum(ok), sum(okw)), nid = uniqueN(s$id[obs(m_fe)]))
  cat(dv, ": N ols/fe/iv/feiv =", res[[dv]]$n, " kappa iv/feiv =", attr(b_iv, "kappa"), attr(b_feiv, "kappa"), "\n")
  cat("  lnPRE ols/iv/fe/feiv:", coef(m_ols)["lnPRE"], b_iv["lnPRE"], coef(m_fe)["lnPRE"], b_feiv["lnPRE"], "\n")
}

c_ <- res$lnc_ele; g_ <- res$lng_ele
out <- c(
  reform_consumption_ols_col1 = c_$ols[["TT202"]],
  reform_consumption_iv_col2 = c_$iv[["TT202"]],
  reform_consumption_fe_col3 = c_$fe[["TT202"]],
  reform_consumption_fe_iv_col4 = c_$feiv[["TT202"]],
  reform_expenditure_ols_col5 = g_$ols[["TT202"]],
  reform_expenditure_iv_col6 = g_$iv[["TT202"]],
  reform_expenditure_fe_col7 = g_$fe[["TT202"]],
  reform_expenditure_fe_iv_col8 = g_$feiv[["TT202"]],
  price_elasticity_consumption_ols_col1 = c_$ols[["lnPRE"]],
  price_elasticity_consumption_fe_col3 = c_$fe[["lnPRE"]],
  n_obs_table2 = c_$n[1],
  n_households_table2 = c_$nid
)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
