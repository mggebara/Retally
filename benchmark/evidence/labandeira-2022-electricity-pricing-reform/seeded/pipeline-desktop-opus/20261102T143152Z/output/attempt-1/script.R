suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform"
path <- file.path(base, "3 Replication package", "analysis data", "data_to_run_DOFILE3.dta")

need <- c("lnc_ele", "lng_ele", "TT202", "lnPRE", "lny", "lny2", "dist", "TAMAMU", "CCAA",
          "CAPROV", "NMIEMB", "NHABIT", "SUPERF", "ESTUDRED", "SITUACTHOG_j", "mayores",
          "alqui", "urban", "edif25", "year", "trim", "month", "time", "dup", "id",
          "lnPRE_papas_", "lnPRE_aguav_", "lnPRE_gascar_",
          "lnPRE_papas", "lnPRE_aguav", "lnPRE_gascar", "c_ele", "g_ele")

d <- read_dta(path, col_select = any_of(need))
d <- as.data.frame(zap_labels(d))
for (v in names(d)) {
  if (!is.numeric(d[[v]])) d[[v]] <- suppressWarnings(as.numeric(d[[v]]))
  d[[v]][!is.finite(d[[v]])] <- NA
}
d <- as.data.table(d)
cat("Loaded rows:", nrow(d), " cols:", ncol(d), "\n")

# ---- fallbacks for variables possibly absent ----
if (!"trim" %in% names(d) && "month" %in% names(d)) {
  d[, trim := fifelse(month < 4, 1, fifelse(month < 7, 2, fifelse(month < 10, 3, 4)))]
}
if (!"lnc_ele" %in% names(d) && "c_ele" %in% names(d)) d[, lnc_ele := log(c_ele)]
if (!"lng_ele" %in% names(d) && "g_ele" %in% names(d)) d[, lng_ele := log(g_ele)]
if (!"TT202" %in% names(d)) {
  d[, TT202 := fifelse(year > 2010 & time < 215, 0, NA_real_)]
  d[time > 202 & dup == 2 & time < 215, TT202 := 1]
  d[time > 202 & dup == 1 & time < 215, TT202 := NA_real_]
}
for (g in c("papas", "aguav", "gascar")) {
  nm <- paste0("lnPRE_", g, "_")
  raw <- paste0("lnPRE_", g)
  if (!nm %in% names(d) && raw %in% names(d)) {
    d[, (nm) := get(raw)]
    if ("month" %in% names(d)) {
      d[, tmpm := mean(get(raw), na.rm = TRUE), by = .(year, month)]
      d[is.na(get(nm)), (nm) := tmpm]
      d[, tmpm := NULL]
    }
  }
}
d[, lny2 := lny^2]

# ---- dummies as in Stata's tabulate, generate() on full data ----
mkd <- function(x, k) {
  lv <- sort(unique(x[!is.na(x)]))
  if (k > length(lv)) return(NULL)
  as.numeric(x == lv[k])
}
add_dummies <- function(var, prefix) {
  lv <- sort(unique(d[[var]][!is.na(d[[var]])]))
  for (k in seq_along(lv)) d[, (paste0(prefix, k)) := mkd(d[[var]], k)]
}
add_dummies("TAMAMU", "itam")
add_dummies("CCAA", "iccaa")
add_dummies("ESTUDRED", "iestud")
add_dummies("SITUACTHOG_j", "isitu")
add_dummies("year", "iyear")

# ---- sample1: estimation sample of the column 1 regression ----
vars1 <- c("lnc_ele", "TT202", "lnPRE", "lny", "dist", "TAMAMU", "CCAA", "CAPROV", "NMIEMB",
           "NHABIT", "SUPERF", "ESTUDRED", "SITUACTHOG_j", "mayores", "alqui", "urban",
           "edif25", "year", "trim", "id")
s <- d[complete.cases(d[, ..vars1])]
rm(d); invisible(gc())
cat("sample1 N:", nrow(s), " households:", uniqueN(s$id), "\n")

ctrl <- "TT202 + lnPRE + lny + lny2 + dist + CAPROV + NMIEMB + NHABIT + SUPERF + mayores + alqui + urban + edif25"
fe_pool <- "TAMAMU + CCAA + ESTUDRED + SITUACTHOG_j + year + trim"

# ---- OLS (cols 1, 5) and household FE (cols 3, 7) ----
m1 <- feols(as.formula(paste("lnc_ele ~", ctrl, "|", fe_pool)), data = s, cluster = ~id, fixef.rm = "none")
m5 <- feols(as.formula(paste("lng_ele ~", ctrl, "|", fe_pool)), data = s, cluster = ~id, fixef.rm = "none")
m3 <- feols(as.formula(paste("lnc_ele ~", ctrl, "| id +", fe_pool)), data = s, cluster = ~id, fixef.rm = "none")
m7 <- feols(as.formula(paste("lng_ele ~", ctrl, "| id +", fe_pool)), data = s, cluster = ~id, fixef.rm = "none")

# ---- LIML (no constant), as ivreg2 ..., liml nocons ----
liml <- function(df, yv, endog, exog, inst) {
  exog <- exog[exog %in% names(df)]
  df <- df[complete.cases(df[, c(yv, endog, exog, inst), with = FALSE])]
  y <- df[[yv]]
  Y2 <- as.matrix(df[, endog, with = FALSE])
  X1 <- as.matrix(df[, exog, with = FALSE])
  # drop collinear / all-zero exogenous columns
  q1 <- qr(X1)
  keep <- sort(q1$pivot[seq_len(q1$rank)])
  X1 <- X1[, keep, drop = FALSE]
  Zx <- as.matrix(df[, inst, with = FALSE])
  Z <- cbind(X1, Zx)
  Q1 <- qr(X1); Qz <- qr(Z)
  W <- cbind(y, Y2)
  e1 <- qr.resid(Q1, W); ez <- qr.resid(Qz, W)
  A <- crossprod(e1); B <- crossprod(ez)
  kap <- min(Re(eigen(solve(B, A), only.values = TRUE)$values))
  X <- cbind(Y2, X1)
  MzX <- cbind(qr.resid(Qz, Y2), matrix(0, nrow(X1), ncol(X1)))
  Mzy <- qr.resid(Qz, y)
  XX <- crossprod(X) - kap * crossprod(MzX)
  Xy <- crossprod(X, y) - kap * crossprod(MzX, Mzy)
  b <- as.vector(solve(XX, Xy))
  names(b) <- colnames(X)
  list(coef = b, n = nrow(df), kappa = kap)
}

inst <- c("lnPRE_aguav_", "lnPRE_papas_", "lnPRE_gascar_")
exog2 <- c("TT202", "lny", "lny2", "dist", paste0("itam", 2:5), paste0("iccaa", 2:19),
           "CAPROV", "NMIEMB", "NHABIT", "SUPERF", paste0("iestud", 2:4), paste0("isitu", 2:3),
           "mayores", "alqui", "urban", "edif25", paste0("iyear", 7:9))
for (v in exog2) if (!v %in% names(s)) s[, (v) := 0]

iv2 <- tryCatch(liml(s, "lnc_ele", "lnPRE", exog2, inst), error = function(e) { message(e$message); NULL })
iv6 <- tryCatch(liml(s, "lng_ele", "lnPRE", exog2, inst), error = function(e) { message(e$message); NULL })

# ---- within-transformed LIML (cols 4, 8) ----
wvars <- c("lnc_ele", "lng_ele", "TT202", "lnPRE", inst, "lny", "lny2", "dist", "NMIEMB",
           "iestud1", "iestud2", "iestud3", "isitu2", "isitu3", "mayores", "alqui", "edif25",
           "iyear7", "iyear8", "iyear9")
for (v in wvars) {
  if (!v %in% names(s)) s[, (v) := 0]
  s[, (paste0("w", v)) := get(v) - mean(get(v), na.rm = TRUE), by = id]
}
exog4 <- paste0("w", c("TT202", "lny", "lny2", "dist", "NMIEMB", "iestud1", "iestud2", "iestud3",
                       "isitu2", "isitu3", "mayores", "alqui", "edif25", "iyear7", "iyear8", "iyear9"))
winst <- paste0("w", inst)
iv4 <- tryCatch(liml(s, "wlnc_ele", "wlnPRE", exog4, winst), error = function(e) { message(e$message); NULL })
iv8 <- tryCatch(liml(s, "wlng_ele", "wlnPRE", exog4, winst), error = function(e) { message(e$message); NULL })

g <- function(m, v) unname(coef(m)[v])
gi <- function(r, v) if (is.null(r)) NA_real_ else unname(r$coef[v])

out <- c(
  reform_consumption_ols_col1 = g(m1, "TT202"),
  reform_consumption_iv_col2 = gi(iv2, "TT202"),
  reform_consumption_fe_col3 = g(m3, "TT202"),
  reform_consumption_fe_iv_col4 = gi(iv4, "wTT202"),
  reform_expenditure_ols_col5 = g(m5, "TT202"),
  reform_expenditure_iv_col6 = gi(iv6, "TT202"),
  reform_expenditure_fe_col7 = g(m7, "TT202"),
  reform_expenditure_fe_iv_col8 = gi(iv8, "wTT202"),
  price_elasticity_consumption_ols_col1 = g(m1, "lnPRE"),
  price_elasticity_consumption_fe_col3 = g(m3, "lnPRE"),
  n_obs_table2 = nobs(m1),
  n_households_table2 = uniqueN(s$id)
)

cat("SE col1 TT202:", sqrt(diag(vcov(m1)))["TT202"], " col3:", sqrt(diag(vcov(m3)))["TT202"], "\n")
if (!is.null(iv2)) cat("IV col2 N:", iv2$n, " kappa:", iv2$kappa, "\n")
if (!is.null(iv4)) cat("IV col4 N:", iv4$n, " kappa:", iv4$kappa, "\n")

for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))