# Labandeira et al. (2022) -- Table 2 reproduction (seeded mode)
# Follows "3_ Results TABLES.do" (Table 2 block) on the analysis dataset
# data_to_run_DOFILE3.dta (the "data.dta" produced by 2_Dataset.do).
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)

f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/seeded/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
cols <- c("lnc_ele","lng_ele","TT202","lnPRE","lny","lny2","dist","TAMAMU","CCAA","CAPROV",
          "NMIEMB","NHABIT","SUPERF","SITUACTHOG_j","mayores","alqui","urban","edif25",
          "year","trim","id","lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_",
          paste0("iyear",1:10), paste0("itam",1:5), paste0("iccaa",1:19),
          paste0("iestud",1:4), paste0("isitu",1:3))
d <- zap_labels(read_dta(f, col_select = all_of(cols)))

# ESTUDRED itself is not in the shipped dataset; i.ESTUDRED is represented by its
# dummies iestud1-4 (created in 2_Dataset.do by `tabulate ESTUDRED, generate(iestud)`).
# Sample = e(sample) of the column-1 regression.
s1vars <- c("lnc_ele","TT202","lnPRE","lny","dist","TAMAMU","CCAA","CAPROV","NMIEMB","NHABIT",
            "SUPERF","iestud1","SITUACTHOG_j","mayores","alqui","urban","edif25","year","trim","id")
d <- d[complete.cases(d[, s1vars]), ]
cat("Sample1 N =", nrow(d), " households =", length(unique(d$id)), "\n")

ctrl <- "lny + I(lny^2) + dist + factor(TAMAMU) + factor(CCAA) + CAPROV + NMIEMB + NHABIT + SUPERF + iestud2 + iestud3 + iestud4 + factor(SITUACTHOG_j) + mayores + alqui + urban + edif25 + factor(year) + factor(trim)"

# ---- OLS (cols 1, 5) and household FE (cols 3, 7), clustered by id
m1 <- feols(as.formula(paste("lnc_ele ~ TT202 + lnPRE +", ctrl)), d, cluster = ~id)
m5 <- feols(as.formula(paste("lng_ele ~ TT202 + lnPRE +", ctrl)), d, cluster = ~id)
m3 <- feols(as.formula(paste("lnc_ele ~ TT202 + lnPRE +", ctrl, "| id")), d, cluster = ~id, fixef.rm = "none")
m7 <- feols(as.formula(paste("lng_ele ~ TT202 + lnPRE +", ctrl, "| id")), d, cluster = ~id, fixef.rm = "none")

# ---- LIML (k-class) estimator, no constant (ivreg2 ... liml nocons)
liml <- function(y, endog, X1, Z2) {
  Z <- cbind(X1, Z2)
  W <- cbind(y, endog)
  eZ <- qr.resid(qr(Z), W)
  e1 <- qr.resid(qr(X1), W)
  kappa <- min(Re(eigen(solve(crossprod(eZ)) %*% crossprod(e1))$values))
  X <- cbind(endog = endog, X1)
  MzX <- qr.resid(qr(Z), X)
  Mzy <- qr.resid(qr(Z), y)
  A <- crossprod(X) - kappa * crossprod(MzX)
  b <- crossprod(X, y) - kappa * crossprod(MzX, y)
  beta <- drop(solve(A, b))
  names(beta) <- colnames(X)
  list(beta = beta, kappa = kappa)
}

# cols 2, 6: pooled IV with dummies as in the do-file (no trim dummies, iyear7-9, nocons)
x1n <- c("TT202","lny","lny2","dist", paste0("itam",2:5), paste0("iccaa",2:19), "CAPROV",
         "NMIEMB","NHABIT","SUPERF", paste0("iestud",2:4), paste0("isitu",2:3),
         "mayores","alqui","urban","edif25", paste0("iyear",7:9))
X1 <- as.matrix(d[, x1n])
Z2 <- as.matrix(d[, c("lnPRE_aguav_","lnPRE_papas_","lnPRE_gascar_")])
iv2 <- liml(d$lnc_ele, d$lnPRE, X1, Z2)
iv6 <- liml(d$lng_ele, d$lnPRE, X1, Z2)

# cols 4, 8: within-transformed (household-demeaned) IV, nocons
wv <- c("lnc_ele","lng_ele","TT202","lnPRE","lnPRE_aguav_","lnPRE_papas_","lnPRE_gascar_",
        "lny","lny2","dist","NMIEMB","iestud1","iestud2","iestud3","isitu2","isitu3",
        "mayores","alqui","edif25","iyear7","iyear8","iyear9")
dw <- d %>% group_by(id) %>% mutate(across(all_of(wv), ~ .x - mean(.x))) %>% ungroup()
wx1n <- c("TT202","lny","lny2","dist","NMIEMB","iestud1","iestud2","iestud3","isitu2","isitu3",
          "mayores","alqui","edif25","iyear7","iyear8","iyear9")
WX1 <- as.matrix(dw[, wx1n])
WZ2 <- as.matrix(dw[, c("lnPRE_aguav_","lnPRE_papas_","lnPRE_gascar_")])
iv4 <- liml(dw$lnc_ele, dw$lnPRE, WX1, WZ2)
iv8 <- liml(dw$lng_ele, dw$lnPRE, WX1, WZ2)

cat("kappa:", iv2$kappa, iv4$kappa, iv6$kappa, iv8$kappa, "\n")
cat("lnPRE coefs IV cols 2,4,6,8:", iv2$beta["endog"], iv4$beta["endog"], iv6$beta["endog"], iv8$beta["endog"], "\n")
print(etable(m1, m3, m5, m7, keep = c("TT202","lnPRE","lny","dist")))

nobs_all <- c(nobs(m1), nobs(m3), nobs(m5), nobs(m7), nrow(d))
cat("nobs:", nobs_all, "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("reform_consumption_ols_col1", coef(m1)["TT202"])
r("reform_consumption_iv_col2", iv2$beta["TT202"])
r("reform_consumption_fe_col3", coef(m3)["TT202"])
r("reform_consumption_fe_iv_col4", iv4$beta["TT202"])
r("reform_expenditure_ols_col5", coef(m5)["TT202"])
r("reform_expenditure_iv_col6", iv6$beta["TT202"])
r("reform_expenditure_fe_col7", coef(m7)["TT202"])
r("reform_expenditure_fe_iv_col8", iv8$beta["TT202"])
r("price_elasticity_consumption_ols_col1", coef(m1)["lnPRE"])
r("price_elasticity_consumption_fe_col3", coef(m3)["lnPRE"])
r("n_obs_table2", nobs(m1))
r("n_households_table2", length(unique(d$id[obs(m3)])))
