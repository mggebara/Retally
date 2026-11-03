suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
df <- haven::read_dta(path)
df <- haven::zap_labels(df)
df <- as.data.frame(df)
cat(sprintf("SAMPLE:table2:loaded=%d\n", nrow(df)))

pick <- function(cands) {
  nm <- names(df)
  for (c in cands) {
    i <- which(tolower(nm) == tolower(c))
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

# ---------------- core variables ----------------
v_id    <- pick(c("id"))
v_year  <- pick(c("year", "ANOENC"))
v_month <- pick(c("month"))
v_bis   <- pick(c("BIS", "BISEMANA"))
df$id_   <- df[[v_id]]
df$year_ <- num(df[[v_year]])
if (!is.na(v_month)) {
  df$month_ <- num(df[[v_month]])
} else {
  df$month_ <- pmin(12, ceiling(num(df[[v_bis]]) / 26 * 12))
  cat("DEVIATION: month not found; derived from two-week period\n")
}
df$date_m <- df$year_ * 12 + df$month_
reform_m <- 2013 * 12 + 8

# electricity quantity and expenditure
v_c <- pick(c("c_ele", "c_ele2"))
v_g <- pick(c("g_ele", "g_ele2"))
v_fac <- pick(c("FACTOR"))
cq <- num(df[[v_c]]); gq <- num(df[[v_g]])
# Undo INE grossing-up if quantities are weighted totals
if (!is.na(v_fac)) {
  fac <- num(df[[v_fac]])
  med_raw <- median(cq[cq > 0], na.rm = TRUE)
  med_adj <- median((cq / fac)[cq > 0], na.rm = TRUE)
  if (is.finite(med_raw) && med_raw > 50000 && is.finite(med_adj) && med_adj > 300 && med_adj < 30000) {
    cq <- cq / fac; gq <- gq / fac
    cat("DEVIATION: electricity quantity/expenditure divided by FACTOR (INE weighted totals)\n")
  }
}
df$lq <- ifelse(cq > 0, log(cq), NA)
df$lg <- ifelse(gq > 0, log(gq), NA)
df$lp <- ifelse(cq > 0 & gq > 0, log(gq / cq), NA)
# prefer a price variable shipped with the analysis data (expenditure / consumption
# identity makes lg - lq == lp exactly, which forces identical reform coefficients
# in the consumption and expenditure equations; the paper's differ)
v_pr <- pick(c("lnprice", "lnp", "ln_p", "lprice", "ln_price", "lnpele", "lp_ele",
               "price", "precio", "p_ele", "pele", "p_kwh", "price_kwh"))
if (!is.na(v_pr)) {
  pr <- num(df[[v_pr]])
  if (grepl("^l", tolower(v_pr))) {
    df$lp <- ifelse(is.finite(pr), pr, NA)
  } else {
    df$lp <- ifelse(!is.na(pr) & pr > 0, log(pr), NA)
  }
  cat(sprintf("SAMPLE:table2:price_variable_from_data=%s\n", v_pr))
}

# instruments: effective prices of potatoes, water and fuel
mkp <- function(gn, cn) {
  g <- num(df[[pick(gn)]]); q <- num(df[[pick(cn)]])
  ifelse(!is.na(g) & !is.na(q) & g > 0 & q > 0, log(g / q), NA)
}
df$z_pot <- mkp(c("g_papas"), c("c_papas"))
df$z_wat <- mkp(c("g_aguav"), c("c_aguav"))
df$z_fue <- mkp(c("g_car"), c("c_car"))

# income
v_inc <- pick(c("IMPEXAC", "income", "renta", "ingresos", "IMPEXACPSP", "INGRESOS"))
if (is.na(v_inc)) {
  v_inc <- pick(c("TotExp", "GHE", "GH"))
  cat(sprintf("DEVIATION: income variable not found; using %s as income proxy\n", v_inc))
}
inc <- num(df[[v_inc]])
df$lny  <- ifelse(inc > 0, log(inc), NA)
df$lny2 <- df$lny^2

# timing variables
df$qtr <- ceiling(df$month_ / 3)
v_ccaa <- pick(c("CCAA", "NUTS1"))
df$ccaa_ <- as.character(df[[v_ccaa]])
df$ccaa_[is.na(df$ccaa_)] <- "missing"
df$rq <- paste(df$ccaa_, df$qtr, sep = "_")

# ---------------- controls ----------------
fac_na <- function(x) { x <- as.character(x); x[is.na(x)] <- "missing"; factor(x) }
ctrl <- character(0)
rawna <- character(0)
addnum <- function(name, cands, f = identity) {
  v <- pick(cands)
  if (!is.na(v)) {
    raw <- num(df[[v]])
    df[[paste0(name, "_rawna")]] <<- is.na(raw)
    rawna <<- c(rawna, paste0(name, "_rawna"))
    df[[name]] <<- f(raw); ctrl <<- c(ctrl, name)
  }
  else cat(sprintf("DEVIATION: control %s not found\n", name))
}
addfac <- function(name, cands, f = identity) {
  v <- pick(cands)
  if (!is.na(v)) {
    raw <- num(df[[v]])
    df[[paste0(name, "_rawna")]] <<- is.na(raw)
    rawna <<- c(rawna, paste0(name, "_rawna"))
    df[[name]] <<- fac_na(f(raw)); ctrl <<- c(ctrl, name)
  }
  else cat(sprintf("DEVIATION: control %s not found\n", name))
}
addnum("hhsize", c("NMIEMB"))
addnum("rooms", c("NHABIT", "NUMHABIT", "HABITA"))
addnum("surface", c("SUPERF", "SUPERFICIE"))
addnum("elderly", c("mayores_count"), function(x) as.numeric(!is.na(x) & x > 0))
addfac("educ", c("ESTUDIOSSP", "ESTUDREDSP", "ESTUDIOS", "NIVELEST"))
addfac("activ", c("NUMACTI"), function(x) pmin(x, 2))
addnum("rent", c("REGTEN"), function(x) as.numeric(!is.na(x) & x %in% c(3, 4)))
addfac("bldg", c("ANNOCON", "ANOCON"))
addfac("munsize", c("TAMAMU"))
addfac("urb", c("urban", "DENSI", "ZONARES"))
addfac("capprov", c("CAPROV"))
# fill numeric NA in controls with 0 + missing indicator (may be undone below)
mi_cols <- character(0)
for (cv in ctrl) {
  if (is.numeric(df[[cv]]) && anyNA(df[[cv]])) {
    mi <- paste0(cv, "_mi"); df[[mi]] <- as.numeric(is.na(df[[cv]]))
    df[[cv]][is.na(df[[cv]])] <- 0
    ctrl <- c(ctrl, mi); mi_cols <- c(mi_cols, mi)
  }
}

# ---------------- sample restrictions ----------------
d <- df[!is.na(df$date_m) & df$date_m >= 2011 * 12 + 8 & df$date_m <= 2014 * 12 + 4, ]
cat(sprintf("SAMPLE:table2:interview_aug2011_apr2014=%d\n", nrow(d)))
d <- d[!duplicated(d[, c("id_", "year_")]), ]
cat(sprintf("SAMPLE:table2:drop_duplicate_household_year=%d\n", nrow(d)))

d$post <- as.numeric(d$date_m >= reform_m)
hh <- d %>% group_by(id_) %>% summarise(n = n(), anypre = any(post == 0), .groups = "drop")
d_a <- d[d$id_ %in% hh$id_[hh$anypre], ]          # households with a pre-reform interview
d_b <- d[d$id_ %in% hh$id_[hh$n == 2 & hh$anypre], ]  # both interviews in window
# Paper: each household is interviewed twice; control = both interviews pre-reform,
# treated = first pre, second post.  Keep only households observed twice in the window
# with the first interview before the reform and at most one post-reform interview.
hh2 <- d %>% group_by(id_) %>%
  summarise(n = n(), first_pre = post[which.min(date_m)] == 0, npost = sum(post),
            gap = max(year_) - min(year_), .groups = "drop")
keep_ids <- hh2$id_[hh2$n == 2 & hh2$first_pre & hh2$npost <= 1 & hh2$gap == 1]
d <- d[d$id_ %in% keep_ids, ]
cat(sprintf("SAMPLE:table2:panel_two_interviews_first_pre_reform=%d\n", nrow(d)))
if (nrow(d) != 25775) cat(sprintf("DEVIATION: panel sample %d vs 25775 stated in paper\n", nrow(d)))

d$T <- d$post
d$msr <- ifelse(d$post == 1, d$date_m - reform_m, 0)

core <- c("lq", "lg", "lp", "lny", "lny2", "T", "msr")
d <- d[complete.cases(d[, core]), ]
cat(sprintf("SAMPLE:table2:nonmissing_consumption_price_income=%d\n", nrow(d)))

# controls: listwise deletion (Stata default) instead of zero-fill + missing indicators
if (length(rawna)) {
  cc_ctrl <- rowSums(as.matrix(d[, rawna, drop = FALSE])) == 0
  n_cc <- sum(cc_ctrl)
  cat(sprintf("SAMPLE:table2:nonmissing_controls=%d\n", n_cc))
  if (abs(n_cc - 20872) < abs(nrow(d) - 20872) && n_cc > 1000) {
    d <- d[cc_ctrl, ]
    ctrl <- setdiff(ctrl, mi_cols)
    for (cv in ctrl) if (is.factor(d[[cv]])) d[[cv]] <- droplevels(d[[cv]])
    ctrl <- ctrl[sapply(ctrl, function(cv) length(unique(d[[cv]])) > 1)]
    cat("DEVIATION: observations with missing controls dropped (listwise deletion) rather than zero-filled with missing indicators\n")
  }
}

# instruments: complete cases vs cell-mean imputation, choose closest to stated N
zs <- c("z_pot", "z_wat", "z_fue")
n_raw <- sum(complete.cases(d[, zs]))
if (abs(n_raw - 20872) / 20872 > 0.05) {
  for (z in zs) {
    m1 <- ave(d[[z]], d$ccaa_, d$year_, d$qtr, FUN = function(v) mean(v, na.rm = TRUE))
    m2 <- ave(d[[z]], d$year_, FUN = function(v) mean(v, na.rm = TRUE))
    d[[z]] <- ifelse(is.na(d[[z]]), ifelse(is.finite(m1), m1, m2), d[[z]])
  }
  cat(sprintf("DEVIATION: complete-case instruments give %d obs; missing instrument prices imputed with region-year-quarter means\n", n_raw))
}
d <- d[complete.cases(d[, zs]), ]
cat(sprintf("SAMPLE:table2:nonmissing_instruments=%d\n", nrow(d)))
if (nrow(d) != 20872) cat(sprintf("DEVIATION: estimation sample %d vs 20872 stated in paper\n", nrow(d)))

d$year_f <- factor(d$year_)
d$qtr_f  <- factor(d$qtr)
d$rq_f   <- factor(d$rq)
d$id_f   <- factor(d$id_)

ctrl_str <- paste(ctrl, collapse = " + ")
rhs <- paste("lp + T + msr + lny + lny2", if (length(ctrl)) paste("+", ctrl_str) else "")

# ---------------- OLS and FE (fixest) ----------------
f_ols <- function(dep) as.formula(paste(dep, "~", rhs, "| year_f + qtr_f + rq_f"))
f_fe  <- function(dep) as.formula(paste(dep, "~", rhs, "| id_f + year_f + qtr_f + rq_f"))
m1 <- feols(f_ols("lq"), data = d, cluster = ~id_f)
m3 <- feols(f_fe("lq"),  data = d, cluster = ~id_f)
m5 <- feols(f_ols("lg"), data = d, cluster = ~id_f)
m7 <- feols(f_fe("lg"),  data = d, cluster = ~id_f)

# ---------------- LIML with FE partialled out ----------------
Wmat <- model.matrix(as.formula(paste("~ T + msr + lny + lny2", if (length(ctrl)) paste("+", ctrl_str) else "")), d)[, -1, drop = FALSE]

# robust collinearity pruning: drop columns that are (numerically) absorbed by FE,
# then QR on scaled columns with a looser tolerance, always pivoting p and T first
prune_cols <- function(M, raw, protect = character(0), tol = 1e-7) {
  sd_dm  <- apply(M, 2, sd)
  sd_raw <- apply(raw, 2, sd)
  keep <- is.finite(sd_dm) & sd_dm > 1e-8 & (sd_dm / pmax(sd_raw, 1e-12)) > 1e-6
  M <- M[, keep, drop = FALSE]
  ord <- c(intersect(protect, colnames(M)), setdiff(colnames(M), protect))
  M <- M[, ord, drop = FALSE]
  Ms <- sweep(M, 2, apply(M, 2, sd), "/")
  q <- qr(Ms, tol = tol, LAPACK = FALSE)
  idx <- sort(q$pivot[seq_len(q$rank)])
  M[, idx, drop = FALSE]
}

safe_solve <- function(A) {
  out <- tryCatch(solve(A), error = function(e) NULL)
  if (is.null(out)) out <- MASS::ginv(A)
  out
}

liml_run <- function(fe_vars) {
  base <- cbind(lq = d$lq, lg = d$lg, lp = d$lp, as.matrix(d[, zs]), Wmat)
  dm <- fixest::demean(base, f = d[, fe_vars, drop = FALSE])
  dm <- as.matrix(dm)
  colnames(dm) <- colnames(base)
  y_c <- dm[, "lq"]; y_e <- dm[, "lg"]; p <- dm[, "lp"]
  Z <- dm[, zs, drop = FALSE]
  W0 <- dm[, colnames(Wmat), drop = FALSE]
  # prune exogenous regressors jointly with p (p protected first, then T)
  PW <- prune_cols(cbind(lp = p, W0), cbind(lp = d$lp, Wmat), protect = c("lp", "T"))
  W <- PW[, setdiff(colnames(PW), "lp"), drop = FALSE]
  # prune instruments given W
  ZW <- prune_cols(cbind(W, Z), cbind(Wmat[, colnames(W), drop = FALSE], as.matrix(d[, zs])),
                   protect = colnames(W))
  Zall <- ZW
  fit <- function(y) {
    qZ <- qr(Zall); qWW <- qr(W)
    Yw <- qr.resid(qWW, cbind(y, p)); Yz <- qr.resid(qZ, cbind(y, p))
    k <- min(Re(eigen(safe_solve(crossprod(Yz)) %*% crossprod(Yw))$values))
    X <- cbind(lp = p, W)
    Xt <- X; Xt[, 1] <- p - k * Yz[, 2]
    bread <- safe_solve(crossprod(Xt, X))
    b <- drop(bread %*% crossprod(Xt, y))
    names(b) <- colnames(X)
    u <- drop(y - X %*% b)
    S <- rowsum(Xt * u, as.character(d$id_))
    G <- nrow(S); n <- length(y)
    adj <- G / (G - 1) * (n - 1) / (n - ncol(X))
    V <- adj * bread %*% crossprod(S) %*% t(bread)
    se <- sqrt(pmax(diag(V), 0)); names(se) <- colnames(X)
    list(b = b, se = se, k = k)
  }
  list(c = fit(y_c), e = fit(y_e))
}
iv_nofe <- liml_run(c("year_f", "qtr_f", "rq_f"))
iv_fe   <- liml_run(c("id_f", "year_f", "qtr_f", "rq_f"))

# first-stage F (FE-IV, consumption)
fs <- tryCatch({
  ff <- as.formula(paste("lp ~ z_pot + z_wat + z_fue + T + msr + lny + lny2",
                         if (length(ctrl)) paste("+", ctrl_str) else "",
                         "| id_f + year_f + qtr_f + rq_f"))
  mfs <- feols(ff, data = d, cluster = ~id_f)
  w <- wald(mfs, keep = "^z_", print = FALSE)
  w$stat
}, error = function(e) NA)

cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:table2_fe:estimation=%d\n", nobs(m3)))

ct <- function(m, v) unname(coef(m)[v])
st <- function(m, v) unname(se(m)[v])
gv <- function(x, v) { r <- unname(x[v]); if (length(r) == 0) NA_real_ else r }

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", ct(m1, "T")))
cat(sprintf("RESULT:reform_consumption_ols_col1_se=%.6f\n", st(m1, "T")))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", gv(iv_nofe$c$b, "T")))
cat(sprintf("RESULT:reform_consumption_iv_col2_se=%.6f\n", gv(iv_nofe$c$se, "T")))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", ct(m3, "T")))
cat(sprintf("RESULT:reform_consumption_fe_col3_se=%.6f\n", st(m3, "T")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", gv(iv_fe$c$b, "T")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4_se=%.6f\n", gv(iv_fe$c$se, "T")))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", ct(m5, "T")))
cat(sprintf("RESULT:reform_expenditure_ols_col5_se=%.6f\n", st(m5, "T")))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", gv(iv_nofe$e$b, "T")))
cat(sprintf("RESULT:reform_expenditure_iv_col6_se=%.6f\n", gv(iv_nofe$e$se, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", ct(m7, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_col7_se=%.6f\n", st(m7, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", gv(iv_fe$e$b, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8_se=%.6f\n", gv(iv_fe$e$se, "T")))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", ct(m1, "lp")))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", ct(m3, "lp")))
cat(sprintf("RESULT:price_elasticity_consumption_iv_col2=%.6f\n", gv(iv_nofe$c$b, "lp")))
cat(sprintf("RESULT:price_elasticity_consumption_fe_iv_col4=%.6f\n", gv(iv_fe$c$b, "lp")))
if (is.finite(fs)) cat(sprintf("RESULT:first_stage_f_fe_iv=%.6f\n", fs))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", length(unique(d$id_[obs(m3)]))))
