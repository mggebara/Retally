# Labandeira, Labeaga & Teixido (2022) -- Table 2 reproduction (independent, blind)
# Equation (4): ln(q_it) = a + b ln(p_it) + ln(y_it) + ln(y_it)^2 + g X_it + d T_it + months-since-reform
#               + quarter dummies + regional dummies + year FE (+ household FE), SE clustered by household.
# IV: ln(p) instrumented by effective prices of potatoes, water and fuel; LIML.
set.seed(42)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})

f <- "<repo>/benchmark/.cache/claude-code/labandeira-2022-electricity-pricing-reform/blind/2026-11-02-b/mount/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
dummies <- c(paste0("iestud",1:4), paste0("isitu",1:3), paste0("itam",1:5), paste0("iccaa",1:19), paste0("itrim",1:4), paste0("iyear",1:10))
keep <- c("T2","id","year","month","BIS","lnc_ele","lng_ele","lnPRE","lny","lny2","dist",
          "lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_",
          "NMIEMB","NHABIT","SUPERF","mayores","alqui","edif25","urban","CAPROV", dummies)
d <- zap_labels(read_dta(f, col_select = all_of(keep)))

# Sample: Sept 2011 - March 2014 panel window, where the reform dummy T (T2 in the data) is defined
d <- d %>% filter(!is.na(T2))
cat("Panel window observations:", nrow(d), " households:", n_distinct(d$id), "\n")

# Controls (eq. 4): household size, rooms, m2, elderly, education of head, economic situation,
# housing tenure (renting), building >25 yrs, municipality size, urban, province capital, region; quarter dummies
cont <- c("NMIEMB","NHABIT","SUPERF","mayores","alqui","edif25","urban","CAPROV",
          paste0("iestud",2:4), paste0("isitu",2:3), paste0("itam",2:5), paste0("iccaa",2:19), paste0("itrim",2:4))
yrs  <- paste0("iyear",7:9)   # year FE (2011 base)
core <- c("T2","lnPRE","lny","lny2","dist")
inst <- c("lnPRE_papas_","lnPRE_aguav_","lnPRE_gascar_")
need <- c("lnc_ele","lng_ele", core, cont, yrs, inst, "id")
s <- d[complete.cases(d[, need]), ]
cat("Estimation sample:", nrow(s), " households:", n_distinct(s$id), "\n")
# drop dummies with no variation in the sample
cont <- cont[sapply(cont, function(v) var(s[[v]]) > 0)]

rhs <- paste(c(core, cont, yrs), collapse = " + ")

# ---- OLS (cols 1, 5) and household FE (cols 3, 7) ----
m1 <- feols(as.formula(paste("lnc_ele ~", rhs)), data = s, cluster = ~id)
m5 <- feols(as.formula(paste("lng_ele ~", rhs)), data = s, cluster = ~id)
m3 <- feols(as.formula(paste("lnc_ele ~", rhs, "| id")), data = s, cluster = ~id)
m7 <- feols(as.formula(paste("lng_ele ~", rhs, "| id")), data = s, cluster = ~id)

# ---- LIML (cols 2, 4, 6, 8) ----
liml <- function(y, endo, X, Z, cl) {
  # drop collinear exogenous columns
  q <- qr(X); X <- X[, q$pivot[seq_len(q$rank)], drop = FALSE]
  ZZ <- cbind(X, Z)
  resid <- function(A, B) A - B %*% qr.coef(qr(B), A)
  W <- cbind(y, endo)
  MxW <- resid(W, X); MzW <- resid(W, ZZ)
  kap <- min(Re(eigen(solve(crossprod(MzW)) %*% crossprod(MxW))$values))
  R <- cbind(endo, X)
  MzR <- resid(R, ZZ)
  A <- crossprod(R) - kap * crossprod(MzR)
  b <- crossprod(R, y) - kap * crossprod(MzR, y)
  beta <- drop(solve(A, b)); names(beta) <- c("endo", colnames(X))
  # cluster-robust SE (k-class sandwich)
  e <- drop(y - R %*% beta)
  Rt <- R - kap * MzR
  Ainv <- solve(A)
  sc <- rowsum(Rt * e, cl)
  G <- nrow(sc); n <- length(y); K <- ncol(R)
  V <- Ainv %*% crossprod(sc) %*% Ainv * (G/(G-1)) * ((n-1)/(n-K))
  se <- sqrt(diag(V)); names(se) <- names(beta)
  list(beta = beta, se = se, kappa = kap)
}

Xn <- cbind(const = 1, as.matrix(s[, c("T2","lny","lny2","dist", cont, yrs)]))
Zn <- as.matrix(s[, inst])
r2 <- liml(s$lnc_ele, s$lnPRE, Xn, Zn, s$id)
r6 <- liml(s$lng_ele, s$lnPRE, Xn, Zn, s$id)

# household FE: within-transform everything by id (FWL; FE dummies are exogenous)
vars <- c("lnc_ele","lng_ele","lnPRE","T2","lny","lny2","dist", cont, yrs, inst)
dm <- demean(as.matrix(s[, vars]), f = s$id)
colnames(dm) <- vars
Xf <- dm[, c("T2","lny","lny2","dist", cont, yrs)]
Xf <- Xf[, apply(Xf, 2, function(x) sum(x^2) > 1e-8), drop = FALSE]
r4 <- liml(dm[, "lnc_ele"], dm[, "lnPRE"], Xf, dm[, inst], s$id)
r8 <- liml(dm[, "lng_ele"], dm[, "lnPRE"], Xf, dm[, inst], s$id)

cat("\nDiagnostics (not scored):\n")
pr <- function(lab, b, se) cat(sprintf("  %-28s T = %8.4f (%.4f)  lnp = %8.4f (%.4f)\n", lab, b["T2"], se["T2"], b[2], se[2]))
pr("(1) OLS cons", coef(m1)[c("T2","lnPRE")], se(m1)[c("T2","lnPRE")])
pr("(2) LIML cons", c(T2 = r2$beta[["T2"]], lnp = r2$beta[["endo"]]), c(T2 = r2$se[["T2"]], lnp = r2$se[["endo"]]))
pr("(3) FE cons", coef(m3)[c("T2","lnPRE")], se(m3)[c("T2","lnPRE")])
pr("(4) FE-LIML cons", c(T2 = r4$beta[["T2"]], lnp = r4$beta[["endo"]]), c(T2 = r4$se[["T2"]], lnp = r4$se[["endo"]]))
pr("(5) OLS exp", coef(m5)[c("T2","lnPRE")], se(m5)[c("T2","lnPRE")])
pr("(6) LIML exp", c(T2 = r6$beta[["T2"]], lnp = r6$beta[["endo"]]), c(T2 = r6$se[["T2"]], lnp = r6$se[["endo"]]))
pr("(7) FE exp", coef(m7)[c("T2","lnPRE")], se(m7)[c("T2","lnPRE")])
pr("(8) FE-LIML exp", c(T2 = r8$beta[["T2"]], lnp = r8$beta[["endo"]]), c(T2 = r8$se[["T2"]], lnp = r8$se[["endo"]]))
cat("  LIML kappa: no-FE", r2$kappa, " FE", r4$kappa, "\n")
fs  <- feols(as.formula(paste("lnPRE ~", paste(c("T2","lny","lny2","dist", cont, yrs, inst), collapse=" + "))), data = s, cluster = ~id)
fsf <- feols(as.formula(paste("lnPRE ~", paste(c("T2","lny","lny2","dist", cont, yrs, inst), collapse=" + "), "| id")), data = s, cluster = ~id)
cat("  First-stage cluster-robust Wald F on instruments: no-FE", fitstat(fs, ~wald, keep = "PRE_")[[1]]$stat,
    " FE", fitstat(fsf, ~wald, keep = "PRE_")[[1]]$stat, "\n")
cat("  N per model:", nobs(m1), nobs(m3), nobs(m5), nobs(m7), length(s$id), "\n")

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)[["T2"]]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", r2$beta[["T2"]]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)[["T2"]]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", r4$beta[["T2"]]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)[["T2"]]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", r6$beta[["T2"]]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)[["T2"]]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", r8$beta[["T2"]]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)[["lnPRE"]]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)[["lnPRE"]]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(s)))
cat(sprintf("RESULT:n_households_table2=%d\n", n_distinct(s$id)))
