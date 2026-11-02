suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"

full <- read_dta(path)
nm <- names(full)
has <- function(x) x %in% nm
cat("Candidate expenditure/price variables:", grep("ele|kwh|gast|exp", nm, value = TRUE, ignore.case = TRUE), "\n")

want <- c("id", "ANOENC", "year", "month", "BISEMANA", "T2", "time", "dup", "trim",
          "c_ele", "g_ele", "lnc_ele", "lng_ele", "lnp_kwh", "p_kwh",
          "lny", "lny2", "IMPEXAC", "y",
          "lnp_papas", "lnp_aguav", "lnp_gascar", "c_papas", "g_papas", "c_aguav", "g_aguav", "c_car", "g_car",
          "NMIEMB", "NHABIT", "SUPERF", "mayores", "mayores_count", "ESTUDREDSP",
          "SITUACTHOG_j", "NUMACTI", "alqui", "REGTEN", "edif25", "ANNOCON",
          "TAMAMU", "urban", "CAPROV", "CCAA")
want <- want[has(want)]
d <- as.data.frame(full[, want])
rm(full); invisible(gc())
d[] <- lapply(d, function(x) suppressWarnings(as.numeric(zap_labels(x))))
g <- function(k) if (k %in% names(d)) d[[k]] else rep(NA_real_, nrow(d))

df <- data.frame(id = g("id"))
df$yr <- if (has("ANOENC")) g("ANOENC") else g("year")
mo <- g("month")
if (all(is.na(mo)) || max(mo, na.rm = TRUE) > 12) {
  b <- g("BISEMANA"); mo <- pmin(12, floor((b - 1) * 14 / 30.44) + 1)
}
df$mo <- mo
df$T2 <- g("T2"); df$dup <- g("dup")

# ---- outcome and price: use the authors' constructed variables ----
df$lnq <- if (has("lnc_ele")) g("lnc_ele") else ifelse(g("c_ele") > 0, log(g("c_ele")), NA)
df$lng <- if (has("lng_ele")) g("lng_ele") else ifelse(g("g_ele") > 0, log(g("g_ele")), NA)
df$lnp <- if (has("lnp_kwh")) g("lnp_kwh") else ifelse(g("c_ele") > 0 & g("g_ele") > 0, log(g("g_ele") / g("c_ele")), NA)

# ---- income ----
if (has("lny")) {
  df$lny <- g("lny")
  df$lny2 <- if (has("lny2")) g("lny2") else df$lny^2
} else {
  inc <- g("IMPEXAC"); df$lny <- ifelse(inc > 0, log(inc), NA); df$lny2 <- df$lny^2
}

# ---- instruments: authors' log unit prices ----
uvl <- function(gk, ck) { gg <- g(gk); qq <- g(ck); ifelse(gg > 0 & qq > 0, log(gg / qq), NA) }
df$z1 <- if (has("lnp_papas")) g("lnp_papas") else uvl("g_papas", "c_papas")
df$z2 <- if (has("lnp_aguav")) g("lnp_aguav") else uvl("g_aguav", "c_aguav")
df$z3 <- if (has("lnp_gascar")) g("lnp_gascar") else uvl("g_car", "c_car")

# ---- controls ----
df$hhsize  <- g("NMIEMB")
df$rooms   <- g("NHABIT")
df$surface <- g("SUPERF")
el <- if (has("mayores_count")) g("mayores_count") else g("mayores")
df$elderly <- ifelse(is.na(el), NA, as.numeric(el > 0))
df$educ    <- g("ESTUDREDSP")
if (has("SITUACTHOG_j")) {
  df$active <- g("SITUACTHOG_j")
} else {
  ac <- g("NUMACTI"); df$active <- ifelse(is.na(ac), NA, pmin(ac, 2))
}
df$tenure  <- if (has("alqui")) g("alqui") else g("REGTEN")
df$old     <- if (has("edif25")) g("edif25") else g("ANNOCON")
df$tamamu  <- g("TAMAMU")
df$urban   <- g("urban")
df$caprov  <- g("CAPROV")
df$ccaa    <- g("CCAA")
df$quarter <- if (has("trim") && all(g("trim") %in% c(1:4, NA))) g("trim") else ceiling(df$mo / 3)
rm(d); invisible(gc())

# ---- impute missing instrument unit values (households that did not buy the good)
#      with the median unit value in the same region x year x quarter cell (full survey as donors)
cellmed <- function(v, grp) {
  ave(v, grp, FUN = function(x) if (all(is.na(x))) NA_real_ else median(x, na.rm = TRUE))
}
fillz <- function(v) {
  v[!is.finite(v)] <- NA
  out <- v
  for (grp in list(interaction(df$ccaa, df$yr, df$quarter, drop = TRUE),
                   interaction(df$yr, df$quarter, drop = TRUE),
                   factor(df$yr))) {
    m <- cellmed(v, grp)
    idx <- is.na(out) & is.finite(m)
    out[idx] <- m[idx]
  }
  out[is.na(out)] <- median(v, na.rm = TRUE)
  out
}
for (k in c("z1", "z2", "z3")) {
  cat("Instrument", k, "raw coverage (all rows):", mean(is.finite(df[[k]])), "\n")
  df[[k]] <- fillz(df[[k]])
}
cat("DEVIATION: Missing instrument unit values (potatoes, water, fuel) imputed with the region x year x quarter median unit value; the paper's estimation sample (20,872 obs) is far larger than the complete-case instrument sample, so some imputation must have been used\n")

# ---- sample: the authors' analysis sample is defined by T2 (25,775 obs, Aug 2011 - Apr 2014) ----
df <- df[!is.na(df$T2) & !is.na(df$id), ]
cat("Obs with T2 defined:", nrow(df), "\n")
df <- df[!duplicated(df[, c("id", "yr")]), ]
cat("Obs after id-year dedup:", nrow(df), "\n")
df$dm <- df$yr * 12 + df$mo
R <- 2013 * 12 + 8
df$reform <- as.integer(df$T2 == 1)
df$msr <- ifelse(df$reform == 1, pmax(df$dm - R, 0), 0)
print(table(df$reform, useNA = "ifany"))

cont_c <- c("hhsize", "rooms", "surface", "elderly")
cat_c  <- c("educ", "active", "tenure", "old", "tamamu", "urban", "caprov", "ccaa", "quarter")
usable <- function(x) sum(!is.na(x)) > 0.5 * length(x) && length(unique(na.omit(x))) > 1
cont_c <- cont_c[sapply(cont_c, function(k) usable(df[[k]]))]
cat_c  <- cat_c[sapply(cat_c, function(k) usable(df[[k]]))]
cat("Continuous controls:", cont_c, "\nCategorical controls:", cat_c, "\n")
for (k in c("lnq", "lnp", "lny", cont_c, cat_c)) cat("Missing share", k, ":", mean(is.na(df[[k]])), "\n")

allv <- c("id", "yr", "lnq", "lng", "lnp", "lny", "lny2", "reform", "msr", "z1", "z2", "z3", cont_c, cat_c)
est <- df[complete.cases(df[, allv]), allv]
for (k in c("z1", "z2", "z3", "lnq", "lng", "lnp", "lny")) est <- est[is.finite(est[[k]]), ]
cat("Estimation sample:", nrow(est), " households:", length(unique(est$id)), "\n")

cont_c <- cont_c[sapply(cont_c, function(k) length(unique(est[[k]])) > 1)]
cat_c  <- cat_c[sapply(cat_c, function(k) length(unique(est[[k]])) > 1)]

exog_terms <- c("reform", "msr", "lny", "lny2", cont_c, if (length(cat_c)) paste0("factor(", cat_c, ")"))
rhs <- paste(c("reform", "msr", "lnp", exog_terms[-(1:2)]), collapse = " + ")

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

# ---- OLS and FE ----
m1 <- safe(feols(as.formula(paste("lnq ~", rhs, "| yr")), data = est, cluster = ~id))
m3 <- safe(feols(as.formula(paste("lnq ~", rhs, "| id + yr")), data = est, cluster = ~id))
m5 <- safe(feols(as.formula(paste("lng ~", rhs, "| yr")), data = est, cluster = ~id))
m7 <- safe(feols(as.formula(paste("lng ~", rhs, "| id + yr")), data = est, cluster = ~id))
for (m in list(m1, m3, m5, m7)) if (!is.null(m)) print(coeftable(m)[c("reform", "msr", "lnp"), ])

# ---- LIML ----
prune <- function(W) {
  W <- W[, colSums(abs(W)) > 1e-10, drop = FALSE]
  qw <- qr(W, tol = 1e-7)
  W[, qw$pivot[seq_len(qw$rank)], drop = FALSE]
}
liml <- function(y, x, W, Z, cl) {
  W <- prune(W)
  Zf <- cbind(W, Z)
  qZ <- qr(Zf); qW <- qr(W)
  Y <- cbind(y, x)
  S1 <- crossprod(qr.resid(qZ, Y)); S0 <- crossprod(qr.resid(qW, Y))
  k <- min(Re(eigen(solve(S1, S0))$values))
  X <- cbind(lnp = x, W)
  MX <- qr.resid(qZ, X); My <- qr.resid(qZ, y)
  A <- crossprod(X) - k * crossprod(MX)
  bv <- crossprod(X, y) - k * crossprod(MX, My)
  b <- drop(solve(A, bv))
  names(b) <- colnames(X)
  u <- drop(y - X %*% b)
  Xt <- X - k * MX
  sc <- rowsum(Xt * u, cl)
  Ai <- solve(A)
  V <- Ai %*% crossprod(sc) %*% Ai
  se <- sqrt(diag(V)); names(se) <- colnames(X)
  list(b = b, se = se, kappa = k)
}

mm <- safe(model.matrix(as.formula(paste("~", paste(c(exog_terms, "factor(yr)"), collapse = " + "))), data = est))
Zm <- as.matrix(est[, c("z1", "z2", "z3")])
iv2 <- iv6 <- iv4 <- iv8 <- NULL
if (!is.null(mm)) {
  iv2 <- safe(liml(est$lnq, est$lnp, mm, Zm, est$id))
  iv6 <- safe(liml(est$lng, est$lnp, mm, Zm, est$id))
  Wfe <- mm[, colnames(mm) != "(Intercept)", drop = FALSE]
  big <- cbind(lnq = est$lnq, lng = est$lng, lnp = est$lnp, Zm, Wfe)
  dm_all <- safe(fixest::demean(X = big, f = est$id))
  if (!is.null(dm_all)) {
    dm_all <- as.matrix(dm_all)
    Wd <- dm_all[, colnames(Wfe), drop = FALSE]
    Zd <- dm_all[, c("z1", "z2", "z3"), drop = FALSE]
    iv4 <- safe(liml(dm_all[, "lnq"], dm_all[, "lnp"], Wd, Zd, est$id))
    iv8 <- safe(liml(dm_all[, "lng"], dm_all[, "lnp"], Wd, Zd, est$id))
  }
}
for (nmv in c("iv2", "iv4", "iv6", "iv8")) {
  o <- get(nmv)
  if (!is.null(o)) cat(nmv, "kappa", o$kappa, "reform", o$b["reform"], "se", o$se["reform"],
                       "lnp", o$b["lnp"], "\n")
}

tsls <- function(dep, fe) {
  f <- if (fe) paste(dep, "~", paste(exog_terms, collapse = " + "), "| id + yr | lnp ~ z1 + z2 + z3")
       else paste(dep, "~", paste(exog_terms, collapse = " + "), "| yr | lnp ~ z1 + z2 + z3")
  m <- safe(feols(as.formula(f), data = est, cluster = ~id))
  if (is.null(m)) return(NULL)
  list(b = coef(m))
}
if (is.null(iv2)) iv2 <- tsls("lnq", FALSE)
if (is.null(iv6)) iv6 <- tsls("lng", FALSE)
if (is.null(iv4)) iv4 <- tsls("lnq", TRUE)
if (is.null(iv8)) iv8 <- tsls("lng", TRUE)

cat("DEVIATION: Used the replication file's constructed variables (lnc_ele, lng_ele, lnp_kwh, lny, lny2, lnp_papas/aguav/gascar, alqui, edif25, SITUACTHOG_j) and its treatment indicator T2 (which also defines the 25,775-obs analysis sample) instead of rebuilding them\n")

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) cat(sprintf("RESULT:%s=%.6f\n", name, val))
}
gc_ <- function(m, k) if (is.null(m)) NULL else unname(coef(m)[k])
gb_ <- function(o, k) if (is.null(o)) NULL else unname(o$b[k])

emit("reform_consumption_ols_col1", gc_(m1, "reform"))
emit("reform_consumption_iv_col2", gb_(iv2, "reform"))
emit("reform_consumption_fe_col3", gc_(m3, "reform"))
emit("reform_consumption_fe_iv_col4", gb_(iv4, "reform"))
emit("reform_expenditure_ols_col5", gc_(m5, "reform"))
emit("reform_expenditure_iv_col6", gb_(iv6, "reform"))
emit("reform_expenditure_fe_col7", gc_(m7, "reform"))
emit("reform_expenditure_fe_iv_col8", gb_(iv8, "reform"))
emit("price_elasticity_consumption_ols_col1", gc_(m1, "lnp"))
emit("price_elasticity_consumption_fe_col3", gc_(m3, "lnp"))
emit("n_obs_table2", if (!is.null(m1)) nobs(m1) else nrow(est))
emit("n_households_table2", length(unique(est$id)))