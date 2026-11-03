suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
f_dta <- file.path(base, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")
df <- haven::read_dta(f_dta)
df <- as.data.frame(haven::zap_labels(df))
nm <- names(df)

pick <- function(cands) {
  for (c in cands) {
    hit <- nm[toupper(nm) == toupper(c)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

cat(sprintf("SAMPLE:table2:loaded=%d\n", nrow(df)))

# ---- identifiers and dates ----
v_year  <- pick(c("year", "ANOENC"))
v_month <- pick(c("month", "MES", "MESENC"))
df$yy <- num(df[[v_year]])
df$mm <- num(df[[v_month]])
df$hid <- df[["id"]]
df$ym <- df$yy * 12 + df$mm

# drop exact duplicate household-interview rows
df <- df[!is.na(df$hid) & !is.na(df$ym), ]
df <- df[!duplicated(df[, c("hid", "yy", "mm")]), ]
cat(sprintf("SAMPLE:table2:dedup_household_interview=%d\n", nrow(df)))

# ---- window: August 2011 to before April 2014 ----
start_ym <- 2011 * 12 + 8
end_ym   <- 2014 * 12 + 4
R_ym     <- 2013 * 12 + 8
df <- df[df$ym >= start_ym & df$ym < end_ym, ]
cat(sprintf("SAMPLE:table2:interview_aug2011_apr2014=%d\n", nrow(df)))

# ---- treatment / control definition ----
df$T <- as.integer(df$ym >= R_ym)
first_ym <- ave(df$ym, df$hid, FUN = min)
# households whose first (in-window) interview is after the reform belong to neither group
df <- df[first_ym < R_ym, ]
df$D <- as.integer(ave(df$T, df$hid, FUN = max) == 1)
cat(sprintf("SAMPLE:table2:control_or_treated_household=%d\n", nrow(df)))
df$msr <- pmax(0, df$ym - R_ym)  # months since reform

# ---- electricity variables ----
q <- num(df[["c_ele"]]); e <- num(df[["g_ele"]])
df$lnq <- ifelse(q > 0, log(q), NA)
df$lne <- ifelse(e > 0, log(e), NA)
df$lnp <- ifelse(q > 0 & e > 0, log(e / q), NA)
df <- df[!is.na(df$lnq) & !is.na(df$lne) & !is.na(df$lnp), ]
cat(sprintf("SAMPLE:table2:positive_electricity_consumption_expenditure=%d\n", nrow(df)))

# ---- income ----
v_inc <- pick(c("IMPEXAC", "IMPEXACPSP", "income", "renta", "INGRESOS", "INTERIN"))
if (is.na(v_inc)) {
  g <- grep("ingres|income|renta|impexac", nm, ignore.case = TRUE, value = TRUE)
  v_inc <- if (length(g)) g[1] else NA
}
inc <- if (!is.na(v_inc)) num(df[[v_inc]]) else num(df[["GHE"]])
df$lny <- ifelse(!is.na(inc) & inc > 0, log(inc), NA)
df$lny2 <- df$lny^2

# ---- instruments: effective prices of potatoes, water, fuel ----
mkp <- function(g, c) { g <- num(g); c <- num(c); ifelse(!is.na(g) & !is.na(c) & g > 0 & c > 0, log(g / c), NA) }
df$z_pot <- mkp(df[["g_papas"]], df[["c_papas"]])
df$z_wat <- mkp(df[["g_aguav"]], df[["c_aguav"]])
df$z_fue <- mkp(df[["g_car"]],   df[["c_car"]])

# ---- controls ----
ctrl_terms <- character(0)
add_num <- function(newname, x) { df[[newname]] <<- x; ctrl_terms <<- c(ctrl_terms, newname) }
add_fac <- function(newname, x) { df[[newname]] <<- x; ctrl_terms <<- c(ctrl_terms, sprintf("factor(%s)", newname)) }

v <- pick(c("NMIEMB")); if (!is.na(v)) add_num("c_hhsize", num(df[[v]]))
v <- pick(c("NHABIT", "NUMHABIT", "HABITA")); if (!is.na(v)) add_num("c_rooms", num(df[[v]]))
v <- pick(c("SUPERF", "SUPERFICIE")); if (!is.na(v)) add_num("c_surface", num(df[[v]]))
v <- pick(c("mayores_count")); if (!is.na(v)) add_num("c_elderly", as.integer(num(df[[v]]) > 0))
v <- pick(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDSP")); if (!is.na(v)) add_fac("c_educ", num(df[[v]]))
v <- pick(c("NUMACTI")); if (!is.na(v)) add_fac("c_active", pmin(num(df[[v]]), 2))
v <- pick(c("REGTEN")); if (!is.na(v)) add_num("c_rent", as.integer(num(df[[v]]) %in% c(3, 4)))
v <- pick(c("ANNOCON", "ANOCON")); if (!is.na(v)) add_fac("c_bldage", num(df[[v]]))
v <- pick(c("TAMAMU")); if (!is.na(v)) add_fac("c_munsize", num(df[[v]]))
v <- pick(c("urban")); if (!is.na(v)) add_num("c_urban", num(df[[v]]))
v <- pick(c("CAPROV")); if (!is.na(v)) add_fac("c_capital", num(df[[v]]))
v <- pick(c("CCAA")); if (!is.na(v)) add_fac("c_region", num(df[[v]]))
add_fac("c_quarter", ceiling(df$mm / 3))

# drop controls that are missing for a large share of the sample
keep <- sapply(ctrl_terms, function(t) {
  vn <- sub("^factor\\((.*)\\)$", "\\1", t); mean(is.na(df[[vn]])) < 0.2
})
ctrl_terms <- ctrl_terms[keep]
ctrl_vars <- sub("^factor\\((.*)\\)$", "\\1", ctrl_terms)

# instruments: fill missing household prices with region-year-month median if complete-case loss is severe
inst <- c("z_pot", "z_wat", "z_fue")
base_vars <- c("lnq", "lne", "lnp", "T", "lny", "lny2", "msr", ctrl_vars, "yy", "hid")
cc_base <- complete.cases(df[, base_vars])
cc_all  <- cc_base & complete.cases(df[, inst])
if (sum(cc_all) < 0.5 * sum(cc_base)) {
  reg <- if ("c_region" %in% names(df)) df$c_region else 1
  for (z in inst) {
    med <- ave(df[[z]], reg, df$yy, df$mm, FUN = function(x) median(x, na.rm = TRUE))
    med2 <- ave(df[[z]], df$yy, df$mm, FUN = function(x) median(x, na.rm = TRUE))
    df[[z]] <- ifelse(is.na(df[[z]]), ifelse(is.na(med), med2, med), df[[z]])
  }
  cc_all <- cc_base & complete.cases(df[, inst])
}
df <- df[cc_all, ]
cat(sprintf("SAMPLE:table2:complete_regression_variables=%d\n", nrow(df)))

# ---- formulas ----
rhs <- paste(c("T", "lnp", "lny", "lny2", "msr", ctrl_terms), collapse = " + ")
f_ols <- function(dep) as.formula(sprintf("%s ~ %s | yy", dep, rhs))
f_fe  <- function(dep) as.formula(sprintf("%s ~ %s | hid + yy", dep, rhs))

m1 <- feols(f_ols("lnq"), data = df, cluster = ~hid, fixef.rm = "none")
m3 <- feols(f_fe("lnq"),  data = df, cluster = ~hid, fixef.rm = "none")
m5 <- feols(f_ols("lne"), data = df, cluster = ~hid, fixef.rm = "none")
m7 <- feols(f_fe("lne"),  data = df, cluster = ~hid, fixef.rm = "none")

# ---- LIML ----
exo_rhs <- paste(c("T", "lny", "lny2", "msr", ctrl_terms), collapse = " + ")
Xexo_full <- model.matrix(as.formula(paste("~", exo_rhs)), data = df)[, -1, drop = FALSE]
Zex <- as.matrix(df[, inst])

liml_T <- function(dep, fe) {
  y <- df[[dep]]; x <- df$lnp
  M <- cbind(y = y, x = x, Xexo_full, Zex)
  fl <- if (fe) list(hid = df$hid, yy = df$yy) else list(yy = df$yy)
  Md <- fixest::demean(M, f = fl)
  Md <- as.matrix(Md)
  yd <- Md[, 1]; xd <- Md[, 2]
  Xe <- Md[, 3:(2 + ncol(Xexo_full)), drop = FALSE]
  Zd <- Md[, (3 + ncol(Xexo_full)):ncol(Md), drop = FALSE]
  # drop collinear / empty exogenous columns
  qx <- qr(Xe, tol = 1e-9)
  Xe <- Xe[, qx$pivot[seq_len(qx$rank)], drop = FALSE]
  Zf <- cbind(Xe, Zd)
  res_on <- function(A, B) A - B %*% qr.coef(qr(B), A)
  rq <- function(A, B) { qb <- qr(B); qr.resid(qb, A) }
  W <- cbind(yd, xd)
  Wz <- rq(W, Zf); Wx <- rq(W, Xe)
  k <- min(Re(eigen(solve(crossprod(Wz)) %*% crossprod(Wx))$values))
  Xa <- cbind(lnp = xd, Xe)
  Xr <- rq(Xa, Zf); yr <- rq(matrix(yd), Zf)
  A <- crossprod(Xa) - k * crossprod(Xr)
  b <- crossprod(Xa, yd) - k * crossprod(Xr, yr)
  beta <- solve(A, b)
  rownames(beta) <- colnames(Xa)
  beta["T", 1]
}

r2 <- liml_T("lnq", FALSE)
r4 <- liml_T("lnq", TRUE)
r6 <- liml_T("lne", FALSE)
r8 <- liml_T("lne", TRUE)

cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m1)))

n_hh <- length(unique(df$hid[obs(m3)]))

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", r2))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", r4))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", r6))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", r8))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lnp"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lnp"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", n_hh))
