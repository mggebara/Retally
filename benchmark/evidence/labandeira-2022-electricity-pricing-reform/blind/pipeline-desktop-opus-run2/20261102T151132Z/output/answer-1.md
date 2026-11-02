suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"

nm <- names(read_dta(path, n_max = 1))
cat("Columns in data:\n", paste(nm, collapse = " "), "\n", file = stderr())

pick <- function(cands) {
  for (x in cands) {
    i <- which(tolower(nm) == tolower(x))
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}

v <- list(
  id      = pick(c("id")),
  year    = pick(c("year", "ANOENC")),
  month   = pick(c("month", "MES")),
  bis     = pick(c("BISEMANA", "BIS")),
  T2      = pick(c("T2")),
  c_ele   = pick(c("c_ele")),
  g_ele   = pick(c("g_ele")),
  c_pap   = pick(c("c_papas")),
  g_pap   = pick(c("g_papas")),
  c_agu   = pick(c("c_aguav")),
  g_agu   = pick(c("g_aguav")),
  c_car   = pick(c("c_car")),
  g_car   = pick(c("g_car")),
  hsize   = pick(c("NMIEMB", "hsize", "size")),
  rooms   = pick(c("NHABIT", "NHAB", "HABIT", "rooms", "NUMHAB")),
  surf    = pick(c("SUPERF", "superficie", "surface", "SUPERFICIE")),
  elder   = pick(c("mayores_count", "mayores")),
  edu     = pick(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDIOS", "educ", "education")),
  act     = pick(c("NUMACTI", "NACTIVOS", "NMIEMACT", "NUMACT", "activos", "SITUACT")),
  tenure  = pick(c("REGTEN", "tenure", "rent")),
  bldg    = pick(c("ANNOCON", "ANOCON", "old25", "antiguedad")),
  tamamu  = pick(c("TAMAMU")),
  urban   = pick(c("urban", "DENSI")),
  caprov  = pick(c("CAPROV")),
  ccaa    = pick(c("CCAA", "NUTS1")),
  income  = pick(c("IMPEXAC", "income", "ingresos", "INGRESOS", "renta", "INGRESO", "IMPEXACPC")),
  incalt  = pick(c("TotExp", "GH", "GASTOT", "gh"))
)
cat("Variable mapping:\n", file = stderr())
for (k in names(v)) cat("  ", k, "->", v[[k]], "\n", file = stderr())

sel <- unique(na.omit(unlist(v)))
raw <- read_dta(path, col_select = dplyr::all_of(sel))
raw <- zap_labels(raw)
dt <- as.data.table(raw)
rm(raw); invisible(gc())
for (cc in names(dt)) {
  if (!is.numeric(dt[[cc]])) dt[[cc]] <- suppressWarnings(as.numeric(as.character(dt[[cc]])))
}
g <- function(key) if (is.na(v[[key]])) rep(NA_real_, nrow(dt)) else as.numeric(dt[[v[[key]]]])

d <- data.table(id = g("id"), year = g("year"), month = g("month"))
if (all(is.na(d$month)) || max(d$month, na.rm = TRUE) > 12) {
  d$month <- pmin(12, ceiling(g("bis") / 26 * 12))
}
d[, `:=`(c_ele = g("c_ele"), g_ele = g("g_ele"),
         c_pap = g("c_pap"), g_pap = g("g_pap"),
         c_agu = g("c_agu"), g_agu = g("g_agu"),
         c_car = g("c_car"), g_car = g("g_car"),
         hsize = g("hsize"), rooms = g("rooms"), surf = g("surf"),
         elder_n = g("elder"), edu = g("edu"), act = g("act"),
         tenure = g("tenure"), bldg = g("bldg"), tamamu = g("tamamu"),
         urban = g("urban"), caprov = g("caprov"), ccaa = g("ccaa"),
         T2 = g("T2"), inc = g("income"), incalt = g("incalt"))]
rm(dt); invisible(gc())

d <- d[!is.na(id) & !is.na(year) & !is.na(month)]
# one record per household-interview date
d <- unique(d, by = c("id", "year", "month"))
d[, date := year * 12 + month]

R <- 2013 * 12 + 8          # 1 August 2013
w0 <- 2011 * 12 + 8         # August 2011
w1 <- 2014 * 12 + 4         # April 2014

# household first interview date (over full panel) -> D defined only if first interview before R
d[, fd := min(date), by = id]
s <- d[date >= w0 & date <= w1]
cat("Obs in window:", nrow(s), "\n", file = stderr())
s <- s[fd < R]
cat("Obs in window with first interview before reform:", nrow(s), "\n", file = stderr())

# Treatment: post-reform with one-month billing lag
s[, treat_c := as.numeric(date >= R + 1)]
use_T2 <- FALSE
if (!all(is.na(s$T2))) {
  t2 <- s$T2
  if (all(t2[!is.na(t2)] %in% c(0, 1)) && mean(is.na(t2)) < 0.01 &&
      all(t2[s$date < R & !is.na(t2)] == 0) &&
      mean(t2[s$date >= R + 1], na.rm = TRUE) > 0.5) use_T2 <- TRUE
}
s[, treat := if (use_T2) T2 else treat_c]
cat("Using T2 as treatment:", use_T2, "\n", file = stderr())
s[, msr := pmax(0, date - R)]
s[, quarter := ceiling(month / 3)]

# Outcomes, price, income
s[, lnq := ifelse(c_ele > 0 & g_ele > 0, log(c_ele), NA_real_)]
s[, lnx := ifelse(c_ele > 0 & g_ele > 0, log(g_ele), NA_real_)]
s[, lnp := ifelse(c_ele > 0 & g_ele > 0, log(g_ele / c_ele), NA_real_)]
incv <- if (all(is.na(s$inc))) s$incalt else s$inc
s[, lny := ifelse(incv > 0, log(incv), NA_real_)]
s[, lny2 := lny^2]

# Controls
s[, elderly := as.numeric(elder_n > 0)]
s[, act3 := pmin(act, 2)]
ctrl_map <- list(
  hsize = "hsize", rooms = "rooms", surf = "surf", elderly = "elderly",
  edu = "factor(edu)", act3 = "factor(act3)", tenure = "factor(tenure)",
  bldg = "factor(bldg)", tamamu = "factor(tamamu)", urban = "urban",
  caprov = "factor(caprov)", ccaa = "factor(ccaa)"
)
core <- c("lnq", "lnx", "lnp", "lny", "treat", "msr", "quarter", "year", "id")
base_ok <- complete.cases(s[, ..core])
nb <- sum(base_ok)
ctrl_terms <- character(0); ctrl_vars <- character(0)
for (k in names(ctrl_map)) {
  x <- s[[k]]
  if (all(is.na(x))) next
  if (length(unique(na.omit(x))) < 2) next
  ok <- base_ok & !is.na(x)
  if (sum(ok) < 0.9 * nb) { cat("Dropping control", k, "(too many missing)\n", file = stderr()); next }
  ctrl_terms <- c(ctrl_terms, ctrl_map[[k]]); ctrl_vars <- c(ctrl_vars, k)
  base_ok <- ok; nb <- sum(base_ok)
}
cat("Controls:", paste(ctrl_terms, collapse = ", "), "\n", file = stderr())

# Instruments: log effective prices of potatoes, water, fuel
s[, lz1 := ifelse(c_pap > 0 & g_pap > 0, log(g_pap / c_pap), NA_real_)]
s[, lz2 := ifelse(c_agu > 0 & g_agu > 0, log(g_agu / c_agu), NA_real_)]
s[, lz3 := ifelse(c_car > 0 & g_car > 0, log(g_car / c_car), NA_real_)]
for (z in c("lz1", "lz2", "lz3")) {
  x <- s[[z]]; f <- is.finite(x); x[!f] <- NA; s[[z]] <- x
}
cc_iv <- base_ok & complete.cases(s[, .(lz1, lz2, lz3)])
cat("Base sample:", nb, " complete with raw instruments:", sum(cc_iv), "\n", file = stderr())
if (sum(cc_iv) >= 0.85 * nb) {
  s[, keep := cc_iv]
} else {
  cat("Imputing missing instrument prices by region-year-quarter means\n", file = stderr())
  for (z in c("lz1", "lz2", "lz3")) {
    s[, tmp := get(z)]
    s[, m1 := mean(tmp, na.rm = TRUE), by = .(ccaa, year, quarter)]
    s[, m2 := mean(tmp, na.rm = TRUE), by = .(ccaa, year)]
    s[, m3 := mean(tmp, na.rm = TRUE), by = .(year)]
    s[, tmp := fifelse(is.na(tmp), m1, tmp)]
    s[, tmp := fifelse(is.na(tmp) | !is.finite(tmp), m2, tmp)]
    s[, tmp := fifelse(is.na(tmp) | !is.finite(tmp), m3, tmp)]
    s[, tmp := fifelse(is.na(tmp) | !is.finite(tmp), mean(get(z), na.rm = TRUE), tmp)]
    s[[z]] <- s$tmp
    s[, c("tmp", "m1", "m2", "m3") := NULL]
  }
  s[, keep := base_ok & complete.cases(s[, .(lz1, lz2, lz3)])]
}
est <- s[keep == TRUE]
cat("Estimation sample:", nrow(est), " households:", uniqueN(est$id), "\n", file = stderr())

rhs <- paste(c("lnp", "lny", "lny2", "treat", "msr", ctrl_terms, "factor(quarter)", "factor(year)"), collapse = " + ")
f_q <- as.formula(paste("lnq ~", rhs))
f_x <- as.formula(paste("lnx ~", rhs))
f_qfe <- as.formula(paste("lnq ~", rhs, "| id"))
f_xfe <- as.formula(paste("lnx ~", rhs, "| id"))

m1 <- feols(f_q, data = est, cluster = ~id)
m3 <- feols(f_qfe, data = est, cluster = ~id)
m5 <- feols(f_x, data = est, cluster = ~id)
m7 <- feols(f_xfe, data = est, cluster = ~id)

# LIML (k-class) estimator
liml <- function(y, w, X, Zex) {
  q <- qr(X, tol = 1e-9)
  X <- X[, q$pivot[seq_len(q$rank)], drop = FALSE]
  qx <- qr(X)
  Z <- cbind(X, Zex)
  qz <- qr(Z)
  Y <- cbind(y, w)
  S1 <- crossprod(Y, qr.resid(qz, Y))
  S0 <- crossprod(Y, qr.resid(qx, Y))
  k <- min(Re(eigen(solve(S1, S0))$values))
  W <- cbind(lnp = w, X)
  MzW <- qr.resid(qz, W)
  A <- crossprod(W) - k * crossprod(MzW)
  b <- crossprod(W, y) - k * crossprod(MzW, y)
  beta <- as.vector(solve(A, b))
  names(beta) <- colnames(W)
  attr(beta, "k") <- k
  beta
}

fX <- as.formula(paste("~", paste(c("lny", "lny2", "treat", "msr", ctrl_terms, "factor(quarter)", "factor(year)"), collapse = " + ")))
X <- model.matrix(fX, data = est)
Zex <- as.matrix(est[, .(lz1, lz2, lz3)])

iv_fallback <- function(fml) {
  m <- feols(fml, data = est, cluster = ~id)
  coef(m)
}

b2 <- tryCatch(liml(est$lnq, est$lnp, X, Zex), error = function(e) {
  cat("LIML col2 failed:", conditionMessage(e), "\n", file = stderr())
  iv_fallback(as.formula(paste("lnq ~", sub("lnp \\+ ", "", rhs), "| lnp ~ lz1 + lz2 + lz3")))
})
b6 <- tryCatch(liml(est$lnx, est$lnp, X, Zex), error = function(e) {
  cat("LIML col6 failed:", conditionMessage(e), "\n", file = stderr())
  iv_fallback(as.formula(paste("lnx ~", sub("lnp \\+ ", "", rhs), "| lnp ~ lz1 + lz2 + lz3")))
})

# Household FE IV: within-transform then LIML
Xn <- X[, colnames(X) != "(Intercept)", drop = FALSE]
allm <- cbind(lnq = est$lnq, lnx = est$lnx, lnp = est$lnp, Zex, Xn)
dm <- fixest::demean(allm, f = est$id)
dm <- as.matrix(dm)
colnames(dm) <- colnames(allm)
Xd <- dm[, colnames(Xn), drop = FALSE]
sdv <- apply(Xd, 2, sd)
Xd <- Xd[, sdv > 1e-8, drop = FALSE]
Zd <- dm[, c("lz1", "lz2", "lz3"), drop = FALSE]
b4 <- tryCatch(liml(dm[, "lnq"], dm[, "lnp"], Xd, Zd), error = function(e) {
  cat("LIML col4 failed:", conditionMessage(e), "\n", file = stderr())
  iv_fallback(as.formula(paste("lnq ~", sub("lnp \\+ ", "", rhs), "| id | lnp ~ lz1 + lz2 + lz3")))
})
b8 <- tryCatch(liml(dm[, "lnx"], dm[, "lnp"], Xd, Zd), error = function(e) {
  cat("LIML col8 failed:", conditionMessage(e), "\n", file = stderr())
  iv_fallback(as.formula(paste("lnx ~", sub("lnp \\+ ", "", rhs), "| id | lnp ~ lz1 + lz2 + lz3")))
})

gt <- function(b, nmv) {
  if (nmv %in% names(b)) return(unname(b[nmv]))
  alt <- grep(paste0("^", nmv), names(b), value = TRUE)
  if (length(alt)) return(unname(b[alt[1]]))
  NA_real_
}
fit_lnp <- function(b) { x <- gt(b, "lnp"); if (is.na(x)) x <- gt(b, "fit_lnp"); x }

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", gt(coef(m1), "treat")))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", gt(b2, "treat")))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", gt(coef(m3), "treat")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", gt(b4, "treat")))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", gt(coef(m5), "treat")))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", gt(b6, "treat")))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", gt(coef(m7), "treat")))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", gt(b8, "treat")))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", gt(coef(m1), "lnp")))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", gt(coef(m3), "lnp")))
cat(sprintf("RESULT:n_obs_table2=%d\n", as.integer(nobs(m1))))
cat(sprintf("RESULT:n_households_table2=%d\n", as.integer(uniqueN(est$id))))
