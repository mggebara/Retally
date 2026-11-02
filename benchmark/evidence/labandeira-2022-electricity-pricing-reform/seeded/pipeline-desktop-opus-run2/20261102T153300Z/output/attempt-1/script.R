suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform/3 Replication package/analysis data"
dta_path <- file.path(base, "data_to_run_DOFILE3.dta")
csv_path <- file.path(base, "Data_to run_DOFILE3.csv")

want <- c("id", "year", "month", "BIS", "BISEMANA", "time", "dup", "T2", "TT202",
          "lnc_ele", "c_ele", "lng_ele", "g_ele", "lnPRE", "lnp_kwh", "p_kwh", "IP",
          "lny", "y", "lny2", "dist", "TAMAMU", "CCAA", "CAPROV", "NMIEMB", "NHABIT",
          "SUPERF", "ESTUDRED", "SITUACTHOG_j", "SITUACTHOG", "mayores", "alqui",
          "urban", "edif25", "trim", "lnPRE_papas_", "lnPRE_aguav_", "lnPRE_gascar_",
          paste0("itam", 1:5), paste0("iccaa", 1:19), paste0("iestud", 1:4),
          paste0("isitu", 1:3), paste0("iyear", 1:10))

raw <- tryCatch(read_dta(dta_path, col_select = tidyselect::any_of(want)),
                error = function(e) { message("dta read failed: ", conditionMessage(e)); NULL })
if (is.null(raw)) {
  hdr <- names(fread(csv_path, nrows = 0))
  raw <- fread(csv_path, select = intersect(want, hdr))
}
dt <- as.data.table(zap_labels(raw))
rm(raw); invisible(gc())
for (v in names(dt)) {
  if (!is.numeric(dt[[v]])) dt[[v]] <- suppressWarnings(as.numeric(as.character(dt[[v]])))
}
cat("Loaded rows:", nrow(dt), " cols:", ncol(dt), "\n")

has <- function(v) v %in% names(dt)

## ---- construct anything missing (following 2_Dataset.do) ----
if (!has("lnc_ele")) dt[, lnc_ele := log(c_ele)]
if (!has("lng_ele")) dt[, lng_ele := log(g_ele)]
if (!has("lnPRE")) {
  if (has("lnp_kwh")) dt[, lnPRE := lnp_kwh - IP] else dt[, lnPRE := log(p_kwh) - IP]
}
if (!has("lny")) dt[, lny := log(y) - IP]
dt[, lny2 := lny^2]
if (!has("trim")) {
  dt[, trim := fifelse(month < 4, 1, fifelse(month < 7, 2, fifelse(month < 10, 3, 4)))]
}
if (!has("dist")) {
  dt[, dist := NA_real_]
  dt[T2 == 0, dist := 0]
  mm <- c(9, 10, 11, 12, 1, 2, 3, 4, 5, 6, 7, 8)
  yy <- c(rep(2013, 4), rep(2014, 8))
  for (k in 1:12) dt[T2 == 1 & month == mm[k] & year == yy[k], dist := k]
}
if (!has("TT202")) {
  dt[, TT202 := NA_real_]
  dt[year > 2010 & time < 215, TT202 := 0]
  dt[time > 202 & dup == 2 & time < 215, TT202 := 1]
  dt[time > 202 & dup == 1 & time < 215, TT202 := NA_real_]
}

# Stata "tabulate var, generate(prefix)" dummies on the full data
mk_dummies <- function(var, prefix, need) {
  nms <- paste0(prefix, need)
  if (all(nms %in% names(dt))) return(invisible(NULL))
  levs <- sort(unique(na.omit(dt[[var]])))
  for (k in seq_along(levs)) {
    dt[, (paste0(prefix, k)) := as.numeric(get(var) == levs[k])]
  }
  cat("Constructed", prefix, "dummies from", var, ": levels", paste(levs, collapse = ","), "\n")
}
mk_dummies("TAMAMU", "itam", 1:5)
mk_dummies("CCAA", "iccaa", 2:19)
mk_dummies("ESTUDRED", "iestud", 1:4)
mk_dummies("SITUACTHOG_j", "isitu", 1:3)
mk_dummies("year", "iyear", 7:9)
for (v in c(paste0("iccaa", 2:19), paste0("iestud", 1:4), paste0("isitu", 1:3),
            paste0("itam", 1:5), paste0("iyear", 7:9))) {
  if (!has(v)) dt[, (v) := 0]
}

## ---- sample1: e(sample) of column 1 regression ----
s1vars <- c("lnc_ele", "TT202", "lnPRE", "lny", "dist", "TAMAMU", "CCAA", "CAPROV",
            "NMIEMB", "NHABIT", "SUPERF", "ESTUDRED", "SITUACTHOG_j", "mayores", "alqui",
            "urban", "edif25", "year", "trim", "id")
d <- dt[complete.cases(dt[, ..s1vars])]
d <- d[is.finite(lnc_ele) & is.finite(lnPRE) & is.finite(lny)]
rm(dt); invisible(gc())
cat("sample1 N =", nrow(d), " households =", uniqueN(d$id), "\n")

rhs <- paste("TT202 + lnPRE + lny + lny2 + dist + factor(TAMAMU) + factor(CCAA) + CAPROV +",
             "NMIEMB + NHABIT + SUPERF + factor(ESTUDRED) + factor(SITUACTHOG_j) +",
             "mayores + alqui + urban + edif25 + factor(year) + factor(trim)")

safe <- function(expr) tryCatch(expr, error = function(e) { message("ERROR: ", conditionMessage(e)); NULL })
getc <- function(m, nm) if (is.null(m)) NA_real_ else unname(coef(m)[nm])

## ---- OLS (cols 1, 5) ----
m1 <- safe(feols(as.formula(paste("lnc_ele ~", rhs)), data = d, cluster = ~id))
m5 <- safe(feols(as.formula(paste("lng_ele ~", rhs)), data = d[is.finite(lng_ele)], cluster = ~id))
## ---- Household FE (cols 3, 7) ----
m3 <- safe(feols(as.formula(paste("lnc_ele ~", rhs, "| id")), data = d, cluster = ~id, fixef.rm = "none"))
m7 <- safe(feols(as.formula(paste("lng_ele ~", rhs, "| id")), data = d[is.finite(lng_ele)],
                 cluster = ~id, fixef.rm = "none"))
for (m in list(m1, m3, m5, m7)) if (!is.null(m)) print(coeftable(m)[c("TT202", "lnPRE"), ])

## ---- LIML k-class estimator ----
liml <- function(y, Y2, X1, Z2, cl) {
  ok <- complete.cases(cbind(y, Y2, X1, Z2, cl))
  y <- y[ok]; Y2 <- as.matrix(Y2)[ok, , drop = FALSE]; X1 <- as.matrix(X1)[ok, , drop = FALSE]
  Z2 <- as.matrix(Z2)[ok, , drop = FALSE]; cl <- cl[ok]
  # drop all-zero / collinear exogenous columns
  X1 <- X1[, colSums(abs(X1)) > 0, drop = FALSE]
  q1 <- qr(X1, tol = 1e-9)
  X1 <- X1[, q1$pivot[seq_len(q1$rank)], drop = FALSE]
  Z <- cbind(X1, Z2)
  qZ <- qr(Z, tol = 1e-9)
  qX1 <- qr(X1, tol = 1e-9)
  W <- cbind(y, Y2)
  MzW <- qr.resid(qZ, W)
  Mx1W <- qr.resid(qX1, W)
  ev <- eigen(solve(crossprod(MzW), crossprod(Mx1W)))$values
  k <- min(Re(ev))
  X <- cbind(Y2, X1)
  MzX <- qr.resid(qZ, X)
  Xhat <- X - k * MzX
  A <- crossprod(Xhat, X)
  b <- drop(solve(A, crossprod(Xhat, y)))
  names(b) <- colnames(X)
  u <- drop(y - X %*% b)
  S <- rowsum(Xhat * u, cl)
  Ai <- solve(A)
  V <- Ai %*% crossprod(S) %*% Ai
  se <- sqrt(diag(V)); names(se) <- colnames(X)
  list(coef = b, se = se, kappa = k, n = length(y))
}

## ---- IV (cols 2, 6): ivreg2 ... liml nocons cluster(id) ----
x1_iv <- c("TT202", "lny", "lny2", "dist", paste0("itam", 2:5), paste0("iccaa", 2:19), "CAPROV",
           "NMIEMB", "NHABIT", "SUPERF", paste0("iestud", 2:4), paste0("isitu", 2:3),
           "mayores", "alqui", "urban", "edif25", paste0("iyear", 7:9))
z_iv <- c("lnPRE_aguav_", "lnPRE_papas_", "lnPRE_gascar_")
X1m <- as.matrix(d[, ..x1_iv]); Z2m <- as.matrix(d[, ..z_iv])
m2 <- safe(liml(d$lnc_ele, cbind(lnPRE = d$lnPRE), X1m, Z2m, d$id))
lng_ok <- ifelse(is.finite(d$lng_ele), d$lng_ele, NA_real_)
m6 <- safe(liml(lng_ok, cbind(lnPRE = d$lnPRE), X1m, Z2m, d$id))

## ---- FE-IV (cols 4, 8): within-transformed, liml nocons robust ----
wvars <- c("lnc_ele", "lng_ele", "TT202", "lnPRE", "lnPRE_papas_", "lnPRE_aguav_", "lnPRE_gascar_",
           "lny", "lny2", "dist", "NMIEMB", "iestud1", "iestud2", "iestud3", "isitu2", "isitu3",
           "mayores", "alqui", "edif25", "iyear7", "iyear8", "iyear9")
dw <- copy(d)
dw[!is.finite(lng_ele), lng_ele := NA_real_]
for (v in wvars) {
  dw[, (paste0("w", v)) := get(v) - mean(get(v), na.rm = TRUE), by = id]
}
x1_w <- paste0("w", c("TT202", "lny", "lny2", "dist", "NMIEMB", "iestud1", "iestud2", "iestud3",
                      "isitu2", "isitu3", "mayores", "alqui", "edif25", "iyear7", "iyear8", "iyear9"))
z_w <- paste0("w", z_iv)
X1w <- as.matrix(dw[, ..x1_w]); Z2w <- as.matrix(dw[, ..z_w])
obs_id <- seq_len(nrow(dw))
m4 <- safe(liml(dw$wlnc_ele, cbind(wlnPRE = dw$wlnPRE), X1w, Z2w, obs_id))
m8 <- safe(liml(dw$wlng_ele, cbind(wlnPRE = dw$wlnPRE), X1w, Z2w, obs_id))

for (nm in c("m2", "m4", "m6", "m8")) {
  m <- get(nm)
  if (!is.null(m)) cat(nm, ": N =", m$n, " kappa =", m$kappa, "\n  coef:",
                       round(m$coef[1:3], 4), "\n  se:", round(m$se[1:3], 4), "\n")
}
gl <- function(m, nm) if (is.null(m)) NA_real_ else unname(m$coef[nm])

r <- list(
  reform_consumption_ols_col1 = getc(m1, "TT202"),
  reform_consumption_iv_col2 = gl(m2, "TT202"),
  reform_consumption_fe_col3 = getc(m3, "TT202"),
  reform_consumption_fe_iv_col4 = gl(m4, "wTT202"),
  reform_expenditure_ols_col5 = getc(m5, "TT202"),
  reform_expenditure_iv_col6 = gl(m6, "TT202"),
  reform_expenditure_fe_col7 = getc(m7, "TT202"),
  reform_expenditure_fe_iv_col8 = gl(m8, "wTT202"),
  price_elasticity_consumption_ols_col1 = getc(m1, "lnPRE"),
  price_elasticity_consumption_fe_col3 = getc(m3, "lnPRE"),
  n_obs_table2 = if (!is.null(m1)) nobs(m1) else nrow(d),
  n_households_table2 = uniqueN(d$id)
)
for (nm in names(r)) cat(sprintf("RESULT:%s=%.6f\n", nm, r[[nm]]))