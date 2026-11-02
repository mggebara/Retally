# Labandeira, Labeaga & Teixido (2022) -- Table 2, independent reproduction.
# ln(q) = a + b ln(p) + c1 ln(y) + c2 ln(y)^2 + g X + d T + months-since-reform + quarter + year FE (+ household FE)
# IV: ln(p) instrumented by effective prices of potatoes, water and fuel, LIML (k-class) estimation.
# SEs clustered by household.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/independent/2026-11-02-c/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
d <- read_dta(f, col_select = c(T2,id,year,trim,dist,lnc_ele,lng_ele,lnp_kwh,lny,lny2,
  NMIEMB,NHABIT,SUPERF,mayores,ESTUDREDSP,SITUACTHOG_j,alqui,edif25,TAMAMU,urban,CAPROV,CCAA,
  lnPRE_papas_,lnPRE_aguav_,lnPRE_gascar_))
d <- zap_labels(d)
# Sample: households of the Aug 2011 - Apr 2014 panel (T2 defined), complete cases on regression variables
s <- d %>% filter(!is.na(T2))
s <- s[complete.cases(s), ]
s <- s %>% mutate(educ = factor(ESTUDREDSP), econ = factor(SITUACTHOG_j), tam = factor(TAMAMU),
                  ccaa = factor(CCAA), quarter = factor(trim), fyear = factor(year))
cat("N =", nrow(s), " households =", n_distinct(s$id), "\n")

ctrl <- "lny + lny2 + dist + NMIEMB + NHABIT + SUPERF + mayores + educ + econ + alqui + edif25 + tam + urban + CAPROV + ccaa + quarter"
Z <- c("lnPRE_papas_", "lnPRE_aguav_", "lnPRE_gascar_")

ols <- function(dep, fe) {
  fml <- if (fe) as.formula(paste(dep, "~ T2 + lnp_kwh +", ctrl, "| id + fyear"))
         else as.formula(paste(dep, "~ T2 + lnp_kwh +", ctrl, "| fyear"))
  feols(fml, data = s, cluster = ~id)
}

# LIML via k-class: kappa = min eigenvalue of (W'M_full W)^-1 (W'M_X W), W = [y, p]
# then IV with the single constructed instrument p - kappa * M_full p (just-identified => k-class estimate)
liml <- function(dep, fe) {
  fes <- if (fe) "| id + fyear" else "| fyear"
  fX <- as.formula(paste("c(", dep, ", lnp_kwh) ~ T2 +", ctrl, fes))
  fXZ <- as.formula(paste("c(", dep, ", lnp_kwh) ~ T2 +", ctrl, "+", paste(Z, collapse = "+"), fes))
  mX <- feols(fX, data = s); mXZ <- feols(fXZ, data = s)
  WX <- cbind(resid(mX[[1]]), resid(mX[[2]])); WZ <- cbind(resid(mXZ[[1]]), resid(mXZ[[2]]))
  kappa <- min(Re(eigen(solve(crossprod(WZ)) %*% crossprod(WX))$values))
  s$pk <- s$lnp_kwh - kappa * WZ[, 2]
  fml <- as.formula(paste(dep, "~ T2 +", ctrl, fes, "| lnp_kwh ~ pk"))
  m <- feols(fml, data = s, cluster = ~id)
  # first-stage strength (2SLS first stage with the 3 instruments) for information
  fs <- feols(as.formula(paste("lnp_kwh ~ T2 +", ctrl, "+", paste(Z, collapse = "+"), fes)), data = s, cluster = ~id)
  ft <- wald(fs, keep = paste0("^", Z, "$"), print = FALSE)
  cat(sprintf("  [%s, fe=%s] kappa = %.5f, first-stage cluster-robust F(3) = %.2f\n", dep, fe, kappa, ft$stat))
  m
}

m1 <- ols("lnc_ele", FALSE); m2 <- liml("lnc_ele", FALSE); m3 <- ols("lnc_ele", TRUE); m4 <- liml("lnc_ele", TRUE)
m5 <- ols("lng_ele", FALSE); m6 <- liml("lng_ele", FALSE); m7 <- ols("lng_ele", TRUE); m8 <- liml("lng_ele", TRUE)
ms <- list(m1, m2, m3, m4, m5, m6, m7, m8)
tab <- t(sapply(ms, function(m) {
  cf <- coef(m); se <- se(m)
  pn <- if ("fit_lnp_kwh" %in% names(cf)) "fit_lnp_kwh" else "lnp_kwh"
  c(T = cf[["T2"]], seT = se[["T2"]], lnp = cf[[pn]], selnp = se[[pn]], lny = cf[["lny"]], lny2 = cf[["lny2"]], dist = cf[["dist"]], N = nobs(m))
}))
print(round(tab, 4))

nm <- c("reform_consumption_ols_col1", "reform_consumption_iv_col2", "reform_consumption_fe_col3", "reform_consumption_fe_iv_col4",
        "reform_expenditure_ols_col5", "reform_expenditure_iv_col6", "reform_expenditure_fe_col7", "reform_expenditure_fe_iv_col8")
for (i in 1:8) cat(sprintf("RESULT:%s=%.6f\n", nm[i], tab[i, "T"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", tab[1, "lnp"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", tab[3, "lnp"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(s)))
cat(sprintf("RESULT:n_households_table2=%d\n", n_distinct(s$id)))
