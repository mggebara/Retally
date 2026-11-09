suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

root <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
path <- file.path(root, "3 Replication package", "analysis data", "data_to_run_DOFILE3.dta")

d <- read_dta(path)
d <- as.data.frame(zap_labels(d))
message("Columns: ", paste(names(d), collapse = " "))
message("Rows: ", nrow(d))

num <- function(x) suppressWarnings(as.numeric(x))
pick <- function(pats) {
  for (p in pats) {
    m <- grep(p, names(d), ignore.case = TRUE, value = TRUE)
    if (length(m)) return(m[1])
  }
  NA_character_
}

# ---- interview date ----
yr <- if ("year" %in% names(d)) num(d$year) else rep(NA_real_, nrow(d))
if ("ANOENC" %in% names(d)) yr[is.na(yr)] <- num(d$ANOENC)[is.na(yr)]
mo <- if ("month" %in% names(d)) num(d$month) else rep(NA_real_, nrow(d))
bis_var <- pick(c("^BISEMANA$", "^BIS$"))
if (!is.na(bis_var)) {
  bis <- num(d[[bis_var]])
  fill <- is.na(mo) & !is.na(bis)
  mo[fill] <- pmin(12, pmax(1, ceiling(bis[fill] * 12 / 26)))
}
d$yr <- yr
d$mo <- mo
d$ym <- yr * 12 + mo
d$id <- d$id

# one record per household-year
if ("dup" %in% names(d)) d <- d[order(num(d$dup)), ]
d <- d[!is.na(d$id) & !is.na(d$ym), ]
d <- d[!duplicated(d[, c("id", "yr")]), ]

# ---- sample window: Aug 2011 - before Apr 2014 ----
R <- 2013 * 12 + 8
d <- d[d$ym >= 2011 * 12 + 8 & d$ym <= 2014 * 12 + 3, ]

# households whose first (in-window) interview is before the reform
d <- d %>% group_by(id) %>% arrange(ym, .by_group = TRUE) %>%
  mutate(first_ym = min(ym), nobs_h = row_number()) %>% ungroup() %>% as.data.frame()
d <- d[d$first_ym < R & d$nobs_h <= 2, ]

d$treat <- as.numeric(d$ym >= R)
d$msr <- ifelse(d$treat == 1, d$ym - R, 0)
d$quarter <- factor(ceiling(d$mo / 3))
d$yearf <- factor(d$yr)

# ---- outcomes, price, instruments ----
q <- num(d$c_ele); e <- num(d$g_ele)
d$lq <- ifelse(q > 0, log(q), NA)
d$le <- ifelse(e > 0, log(e), NA)
d$lp <- ifelse(q > 0 & e > 0, log(e / q), NA)
up <- function(g, c) { g <- num(g); c <- num(c); ifelse(g > 0 & c > 0, log(g / c), NA) }
d$z_pot <- up(d$g_papas, d$c_papas)
d$z_wat <- up(d$g_aguav, d$c_aguav)
d$z_fuel <- up(d$g_car, d$c_car)

# ---- income ----
inc_var <- pick(c("^IMPEXAC$", "^income$", "^ingresos?$", "^renta$", "^INTERIN$", "ingres", "income"))
if (is.na(inc_var)) {
  message("No income variable found; using total expenditure as income proxy")
  inc_var <- pick(c("^TotExp$", "^GHE$", "^GH$"))
}
message("Income variable: ", inc_var)
inc <- num(d[[inc_var]])
d$ly <- ifelse(inc > 0, log(inc), NA)
d$ly2 <- d$ly^2

# ---- controls ----
terms <- c()
add_num <- function(pats, name) {
  v <- pick(pats)
  if (is.na(v)) { message("Missing control: ", name); return(invisible()) }
  message("Control ", name, " <- ", v)
  d[[name]] <<- num(d[[v]])
  terms <<- c(terms, name)
}
add_fac <- function(pats, name, f = identity) {
  v <- pick(pats)
  if (is.na(v)) { message("Missing control: ", name); return(invisible()) }
  message("Control ", name, " <- ", v)
  d[[name]] <<- factor(f(num(d[[v]])))
  terms <<- c(terms, name)
}
add_num(c("^NMIEMB$"), "hhsize")
add_num(c("^NHABIT$", "habit"), "rooms")
add_num(c("^SUPERF$", "superf"), "surface")
if ("mayores_count" %in% names(d)) {
  d$elderly <- as.numeric(num(d$mayores_count) > 0); terms <- c(terms, "elderly")
}
add_fac(c("^ESTUDREDSP$", "^ESTUDIOSSP$", "ESTUD"), "educ")
add_fac(c("^NUMACTI$", "^NACTIVOS$", "^NMIEMACT$", "^NUMACT", "ACTIV"), "nactive", function(x) pmin(x, 2))
v_ten <- pick(c("^REGTEN$", "REGTEN", "tenen"))
if (!is.na(v_ten)) { d$renting <- as.numeric(num(d[[v_ten]]) %in% c(3, 4)); terms <- c(terms, "renting") }
add_fac(c("^ANNOCON$", "ANOCON", "ANNOCON", "EDIF"), "building")
add_fac(c("^TAMAMU$"), "munsize")
add_fac(c("^urban$"), "urbanf")
add_fac(c("^CAPROV$"), "capital")
add_fac(c("^CCAA$"), "region")
terms <- c(terms, "quarter", "yearf")

exog <- c("treat", "msr", "ly", "ly2", terms)
need <- c("id", "lq", "le", "lp", "z_pot", "z_wat", "z_fuel", exog)
s <- d[, need]
s <- s[complete.cases(s), ]
s <- droplevels(s)
for (v in names(s)) if (is.factor(s[[v]]) && nlevels(s[[v]]) < 2) exog <- setdiff(exog, v)
message("Estimation sample: ", nrow(s), " obs, ", length(unique(s$id)), " households")

W0 <- model.matrix(as.formula(paste("~", paste(exog, collapse = " + "))), data = s)
Z0 <- as.matrix(s[, c("z_pot", "z_wat", "z_fuel")])

clean_W <- function(W) {
  keep <- apply(W, 2, function(c) sd(c) > 1e-8) | colnames(W) == "(Intercept)"
  W <- W[, keep, drop = FALSE]
  qw <- qr(W, tol = 1e-9)
  W[, sort(qw$pivot[seq_len(qw$rank)]), drop = FALSE]
}

fit <- function(y, x, W, Z, iv) {
  if (!iv) {
    X <- cbind(lp = x, W)
    b <- qr.coef(qr(X), y)
    return(b)
  }
  Zb <- cbind(Z, W)
  qZ <- qr(Zb); qW <- qr(W)
  Y <- cbind(y, x)
  A <- crossprod(qr.resid(qZ, Y))
  B <- crossprod(qr.resid(qW, Y))
  kappa <- min(Re(eigen(solve(A, B))$values))
  X <- cbind(lp = x, W)
  EX <- qr.resid(qZ, X)
  lhs <- crossprod(X) - kappa * crossprod(EX)
  rhs <- crossprod(X, y) - kappa * crossprod(EX, y)
  b <- as.vector(solve(lhs, rhs)); names(b) <- colnames(X)
  b
}

run <- function(yname, fe, iv) {
  y <- s[[yname]]; x <- s$lp; W <- W0; Z <- Z0
  if (fe) {
    W <- W[, colnames(W) != "(Intercept)", drop = FALSE]
    M <- demean(cbind(y = y, x = x, Z, W), f = s$id)
    y <- M[, "y"]; x <- M[, "x"]
    Z <- M[, colnames(Z0), drop = FALSE]
    W <- M[, colnames(W), drop = FALSE]
  }
  W <- clean_W(W)
  if (!"treat" %in% colnames(W)) stop("treat dropped")
  fit(y, x, W, Z, iv)
}

m1 <- run("lq", FALSE, FALSE)
m2 <- run("lq", FALSE, TRUE)
m3 <- run("lq", TRUE, FALSE)
m4 <- run("lq", TRUE, TRUE)
m5 <- run("le", FALSE, FALSE)
m6 <- run("le", FALSE, TRUE)
m7 <- run("le", TRUE, FALSE)
m8 <- run("le", TRUE, TRUE)

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", m1["treat"]))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", m2["treat"]))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", m3["treat"]))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", m4["treat"]))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", m5["treat"]))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", m6["treat"]))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", m7["treat"]))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", m8["treat"]))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", m1["lp"]))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", m3["lp"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nrow(s)))
cat(sprintf("RESULT:n_households_table2=%d\n", length(unique(s$id))))
