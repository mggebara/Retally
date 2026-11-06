suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
f_dta <- file.path(base, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")
f_csv <- file.path(base, "3 Replication package/analysis data/Data_to run_DOFILE3.csv")

if (file.exists(f_dta)) {
  df <- haven::read_dta(f_dta)
  df <- haven::zap_labels(df)
} else {
  df <- readr::read_csv(f_csv, show_col_types = FALSE, guess_max = 50000)
}
df <- as.data.frame(df)
cat(sprintf("SAMPLE:table2:loaded=%d\n", nrow(df)))

nm <- names(df)
find_col <- function(cands) {
  for (cc in cands) {
    hit <- nm[tolower(nm) == tolower(cc)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---- interview date -------------------------------------------------------
df$yr <- num(df[[find_col(c("year", "ANOENC"))]])
mcol <- find_col(c("month"))
if (!is.na(mcol)) {
  df$mo <- num(df[[mcol]])
} else {
  bcol <- find_col(c("BIS", "BISEMANA"))
  df$mo <- ceiling(num(df[[bcol]]) / 26 * 12)
}
bcol <- find_col(c("BIS", "BISEMANA"))
if (any(is.na(df$mo)) && !is.na(bcol)) {
  idx <- is.na(df$mo)
  df$mo[idx] <- ceiling(num(df[[bcol]][idx]) / 26 * 12)
}
df$ym <- df$yr * 12 + (df$mo - 1)
R_ym <- 2013 * 12 + (8 - 1)          # August 2013
start_ym <- 2011 * 12 + (8 - 1)      # August 2011
end_ym <- 2014 * 12 + (4 - 1)        # April 2014 (price cut) - excluded

idcol <- find_col(c("id"))
df$hid <- df[[idcol]]

# ---- restriction 1: interview window Aug 2011 - before Apr 2014 -----------
d <- df[!is.na(df$ym) & df$ym >= start_ym & df$ym < end_ym, ]
cat(sprintf("SAMPLE:table2:window_aug2011_apr2014=%d\n", nrow(d)))

# remove duplicated household-interview records
d <- d[!duplicated(d[, c("hid", "yr", "mo")]), ]
cat(sprintf("SAMPLE:table2:unique_household_interviews=%d\n", nrow(d)))

# ---- restriction 2: treatment/control definition (drop households first interviewed after R)
d <- d %>% group_by(hid) %>% mutate(first_ym = min(ym), n_int = n()) %>% ungroup() %>% as.data.frame()
d <- d[d$first_ym < R_ym, ]
cat(sprintf("SAMPLE:table2:first_interview_pre_reform=%d\n", nrow(d)))

d$T <- as.integer(d$ym >= R_ym)
d$msr <- ifelse(d$T == 1, d$ym - R_ym + 1, 0)
d$quarter <- factor(ceiling(d$mo / 3))

# ---- outcome and price -----------------------------------------------------
ce <- num(d[[find_col(c("c_ele"))]])
ge <- num(d[[find_col(c("g_ele"))]])
d$lq <- ifelse(ce > 0, log(ce), NA)
d$lexp <- ifelse(ge > 0, log(ge), NA)
d$lp <- ifelse(ce > 0 & ge > 0, log(ge / ce), NA)

# ---- income ---------------------------------------------------------------
inccol <- find_col(c("income", "ingresos", "IMPEXAC", "IMPEXACPOND", "renta", "INGRESO", "ingreso", "IMPEXACPON"))
if (is.na(inccol)) inccol <- find_col(c("TotExp", "GH", "gh"))
inc <- num(d[[inccol]])
d$linc <- ifelse(inc > 0, log(inc), NA)
d$linc2 <- d$linc^2

# ---- instruments: effective prices of potatoes, water, fuel ----------------
mkp <- function(g, q) {
  g <- num(d[[find_col(g)]]); q <- num(d[[find_col(q)]])
  ifelse(!is.na(g) & !is.na(q) & g > 0 & q > 0, log(g / q), NA)
}
d$z_pot <- mkp("g_papas", "c_papas")
d$z_wat <- mkp("g_aguav", "c_aguav")
d$z_fue <- mkp("g_car", "c_car")
ccaacol <- find_col(c("CCAA"))
d$ccaa <- if (!is.na(ccaacol)) factor(d[[ccaacol]]) else factor(1)
impute <- function(z) {
  m1 <- ave(z, d$ccaa, d$yr, d$quarter, FUN = function(v) mean(v, na.rm = TRUE))
  m2 <- ave(z, d$yr, FUN = function(v) mean(v, na.rm = TRUE))
  out <- z
  out[is.na(out)] <- m1[is.na(out)]
  out[is.na(out) | is.nan(out)] <- m2[is.na(out) | is.nan(out)]
  out[is.na(out) | is.nan(out)] <- mean(z, na.rm = TRUE)
  out
}
# trim implausible unit prices before imputation
trimz <- function(z) {
  q <- quantile(z, c(0.005, 0.995), na.rm = TRUE)
  z[!is.na(z) & (z < q[1] | z > q[2])] <- NA
  z
}
d$z_pot <- impute(trimz(d$z_pot))
d$z_wat <- impute(trimz(d$z_wat))
d$z_fue <- impute(trimz(d$z_fue))

# ---- controls --------------------------------------------------------------
ctrl_terms <- c()
addnum <- function(name, cands) {
  cc <- find_col(cands)
  if (!is.na(cc)) { d[[name]] <<- num(d[[cc]]); ctrl_terms <<- c(ctrl_terms, name) }
}
addfac <- function(name, cands, recode = NULL) {
  cc <- find_col(cands)
  if (!is.na(cc)) {
    v <- num(d[[cc]])
    if (!is.null(recode)) v <- recode(v)
    d[[name]] <<- factor(v)
    ctrl_terms <<- c(ctrl_terms, name)
  }
}
addnum("hhsize", c("NMIEMB"))
addnum("rooms", c("NHABIT", "rooms", "NUMHAB"))
addnum("surface", c("SUPERF", "surface", "superficie"))
mc <- find_col(c("mayores_count"))
if (!is.na(mc)) { d$elderly <- as.integer(num(d[[mc]]) > 0); ctrl_terms <- c(ctrl_terms, "elderly") }
addfac("educ", c("educ", "education", "ESTUDREDSP", "ESTUDIOSSP", "ESTUDIOS", "NIVEST"),
       recode = function(v) { if (length(unique(na.omit(v))) > 4) as.integer(cut(v, 4)) else v })
addfac("nact", c("NUMACTI"), recode = function(v) pmin(v, 2))
rc <- find_col(c("renting", "alquiler", "rent"))
if (!is.na(rc)) {
  d$renting <- num(d[[rc]]); ctrl_terms <- c(ctrl_terms, "renting")
} else {
  tc <- find_col(c("REGTEN"))
  if (!is.na(tc)) { d$renting <- as.integer(num(d[[tc]]) %in% c(3, 4)); ctrl_terms <- c(ctrl_terms, "renting") }
}
oc <- find_col(c("old25", "old", "building_old", "antiguedad"))
if (!is.na(oc)) {
  d$oldbld <- num(d[[oc]]); ctrl_terms <- c(ctrl_terms, "oldbld")
} else {
  ac <- find_col(c("ANNOCON", "ANOCON"))
  if (!is.na(ac)) {
    v <- num(d[[ac]])
    if (median(v, na.rm = TRUE) > 1800) {
      d$oldbld <- as.integer((d$yr - v) > 25)
      ctrl_terms <- c(ctrl_terms, "oldbld")
    } else {
      d$oldbld <- factor(v); ctrl_terms <- c(ctrl_terms, "oldbld")
    }
  }
}
addfac("munsize", c("TAMAMU"))
uc <- find_col(c("urban"))
if (!is.na(uc)) { d$urb <- num(d[[uc]]); ctrl_terms <- c(ctrl_terms, "urb") }
addnum("capprov", c("CAPROV"))
if (!is.na(ccaacol)) ctrl_terms <- c(ctrl_terms, "ccaa")
ctrl_terms <- c(ctrl_terms, "quarter")

# ---- complete cases (common sample across all columns) --------------------
need <- c("lq", "lexp", "lp", "linc", "linc2", "T", "msr", "z_pot", "z_wat", "z_fue", ctrl_terms, "hid", "yr")
cc_ok <- complete.cases(d[, need]) & is.finite(d$lq) & is.finite(d$lp) & is.finite(d$linc)
d <- d[cc_ok, ]
cat(sprintf("SAMPLE:table2:complete_regression_variables=%d\n", nrow(d)))

d$yr_f <- factor(d$yr)
rhs_exo <- paste(c("T", "linc", "linc2", "msr", ctrl_terms), collapse = " + ")

# ---- OLS / FE --------------------------------------------------------------
f_ols_q <- as.formula(paste("lq ~ lp +", rhs_exo, "| yr_f"))
f_fe_q  <- as.formula(paste("lq ~ lp +", rhs_exo, "| hid + yr_f"))
f_ols_e <- as.formula(paste("lexp ~ lp +", rhs_exo, "| yr_f"))
f_fe_e  <- as.formula(paste("lexp ~ lp +", rhs_exo, "| hid + yr_f"))
m1 <- feols(f_ols_q, data = d, cluster = ~hid)
m3 <- feols(f_fe_q, data = d, cluster = ~hid)
m5 <- feols(f_ols_e, data = d, cluster = ~hid)
m7 <- feols(f_fe_e, data = d, cluster = ~hid)
cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m1)))

# ---- LIML ------------------------------------------------------------------
liml <- function(yvar, fe_vars) {
  W <- model.matrix(as.formula(paste("~", rhs_exo)), data = d)
  W <- W[, colnames(W) != "(Intercept)", drop = FALSE]
  Z <- as.matrix(d[, c("z_pot", "z_wat", "z_fue")])
  M <- cbind(y = d[[yvar]], x = d$lp, Z, W)
  fl <- lapply(fe_vars, function(v) d[[v]])
  names(fl) <- fe_vars
  Md <- fixest::demean(M, fl, tol = 1e-10, iter = 50000)
  # drop observations that carry no within-variation (FE singletons)
  if ("hid" %in% fe_vars) {
    nper <- ave(rep(1, nrow(d)), d$hid, FUN = length)
    Md <- Md[nper > 1, , drop = FALSE]
  }
  y <- Md[, 1]; x <- Md[, 2]
  Zd <- Md[, 3:5, drop = FALSE]
  Wd <- Md[, -(1:5), drop = FALSE]
  # relative variation filter: drop columns absorbed by the fixed effects
  sd_orig <- apply(M[, -(1:5), drop = FALSE], 2, sd)
  sd_dm <- apply(Wd, 2, sd)
  keep <- is.finite(sd_dm) & sd_dm > 1e-6 * pmax(sd_orig, 1e-12) & sd_dm > 1e-10
  Wd <- Wd[, keep, drop = FALSE]
  # remove collinear columns jointly with the endogenous regressor (keep lp and T first)
  ord <- c(which(colnames(Wd) == "T"), which(colnames(Wd) != "T"))
  Wd <- Wd[, ord, drop = FALSE]
  Xall <- cbind(lp = x, Wd)
  Xs <- scale(Xall, center = FALSE, scale = sqrt(colSums(Xall^2)))
  qx <- qr(Xs, tol = 1e-7)
  kcols <- sort(qx$pivot[seq_len(qx$rank)])
  if (!(1 %in% kcols)) kcols <- c(1, kcols)
  Xall <- Xall[, kcols, drop = FALSE]
  Wd <- Xall[, -1, drop = FALSE]
  Yb <- cbind(y, x)
  qW <- qr(Wd); qWZ <- qr(cbind(Wd, Zd))
  YW <- qr.resid(qW, Yb); YWZ <- qr.resid(qWZ, Yb)
  kappa <- min(Re(eigen(solve(crossprod(YWZ)) %*% crossprod(YW))$values))
  X <- Xall
  MX <- qr.resid(qWZ, X)
  My <- YWZ[, 1]
  A <- crossprod(X) - kappa * crossprod(X, MX)
  b <- crossprod(X, y) - kappa * crossprod(X, My)
  beta <- tryCatch(drop(solve(A, b)),
                   error = function(e) drop(MASS::ginv(A) %*% b))
  names(beta) <- colnames(X)
  beta
}
b2 <- liml("lq", "yr_f")
b4 <- liml("lq", c("hid", "yr_f"))
b6 <- liml("lexp", "yr_f")
b8 <- liml("lexp", c("hid", "yr_f"))

getT <- function(b) if ("T" %in% names(b)) b[["T"]] else NA_real_

n_hh <- length(unique(d$hid[obs(m3)]))
if (!is.null(m3$fixef_sizes) && "hid" %in% names(m3$fixef_sizes)) n_hh <- as.integer(m3$fixef_sizes["hid"])

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", coef(m1)["T"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", getT(b2)))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", coef(m3)["T"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", getT(b4)))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", coef(m5)["T"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", getT(b6)))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", coef(m7)["T"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", getT(b8)))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", coef(m1)["lp"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", coef(m3)["lp"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", n_hh))
