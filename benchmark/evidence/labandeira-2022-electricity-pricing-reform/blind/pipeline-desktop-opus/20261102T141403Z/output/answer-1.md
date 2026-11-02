suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data"
f_dta <- file.path(base, "data_to_run_DOFILE3.dta")
f_csv <- file.path(base, "Data_to run_DOFILE3.csv")

use_dta <- file.exists(f_dta)
if (use_dta) {
  hdr <- tryCatch(read_dta(f_dta, n_max = 0), error = function(e) NULL)
  if (is.null(hdr)) use_dta <- FALSE
}
if (use_dta) {
  nms <- names(hdr)
} else {
  nms <- names(data.table::fread(f_csv, nrows = 0))
}
cat("Number of columns:", length(nms), "\n")

findv <- function(cands) {
  for (c in cands) {
    i <- which(tolower(nms) == tolower(c))
    if (length(i)) return(nms[i[1]])
  }
  NA_character_
}
findpat <- function(pat) {
  i <- grep(pat, nms, ignore.case = TRUE)
  if (length(i)) return(nms[i[1]])
  NA_character_
}

v <- list()
v$id    <- findv(c("id"))
v$year  <- findv(c("year", "ANOENC"))
v$month <- findv(c("month"))
v$bis   <- findv(c("BISEMANA", "BIS"))
v$c_ele <- findv("c_ele"); v$g_ele <- findv("g_ele")
v$c_ele2 <- findv("c_ele2"); v$g_ele2 <- findv("g_ele2")
v$c_pap <- findv("c_papas"); v$g_pap <- findv("g_papas")
v$c_agu <- findv("c_aguav"); v$g_agu <- findv("g_aguav")
v$c_car <- findv("c_car");   v$g_car <- findv("g_car")

# income
inc_log <- FALSE
v$inc <- findv(c("IMPEXAC", "income", "ingresos", "renta", "inc", "y_hh", "ingreso"))
if (is.na(v$inc)) {
  v$inc <- findv(c("lny", "lninc", "ln_income", "lnincome", "linc", "ly"))
  if (!is.na(v$inc)) inc_log <- TRUE
}
if (is.na(v$inc)) v$inc <- findpat("IMPEX|INGRES|RENTA|INCOME")
if (is.na(v$inc)) v$inc <- findv(c("GASTOT", "TotExp", "GH"))
cat("Income variable:", v$inc, " (log already:", inc_log, ")\n")

# controls
v$hhsize <- findv(c("NMIEMB", "TAMANO", "TAMAÑO"))
v$rooms  <- findv(c("NHABIT", "NUMHABIT", "HABITA", "NHAB"))
v$surf   <- findv(c("SUPERF", "SUPERFICIE", "surface"))
v$eld    <- findv(c("mayores_count", "mayores"))
v$educ   <- findv(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDRED", "ESTUDSP", "ESTUDIOS"))
if (is.na(v$educ)) v$educ <- findpat("^ESTUD")
v$nact   <- findv(c("NUMACTI", "NUMACT", "NACTIVOS", "NACTIV", "NMIEMACT", "NUMACTIVOS"))
v$tenure <- findv(c("REGTEN", "REGTENEN"))
v$bage   <- findv(c("ANNOCON", "ANOCON", "ANNOCONS", "ANNOCONST"))
v$tamamu <- findv(c("TAMAMU"))
v$urban  <- findv(c("urban", "ZONARES"))
v$caprov <- findv(c("CAPROV"))
v$ccaa   <- findv(c("CCAA"))
v$T2     <- findv(c("T2"))
v$time   <- findv(c("time"))
v$dup    <- findv(c("dup"))

print(unlist(v))
need <- unique(na.omit(unlist(v)))

if (use_dta) {
  df <- read_dta(f_dta, col_select = all_of(need))
} else {
  df <- as.data.frame(data.table::fread(f_csv, select = need))
}
df <- as.data.frame(zap_labels(df))
cat("Rows read:", nrow(df), "\n")

num <- function(x) suppressWarnings(as.numeric(x))
g <- function(name) if (!is.na(v[[name]])) num(df[[v[[name]]]]) else rep(NA_real_, nrow(df))

d <- data.frame(id = df[[v$id]])
d$year <- g("year")
if (max(d$year, na.rm = TRUE) < 100) d$year <- d$year + 2000
d$month <- g("month")
bis <- g("bis")
if (all(is.na(d$month)) || max(d$month, na.rm = TRUE) > 12) {
  d$month <- pmin(12, pmax(1, ceiling((bis - 0.5) * 14 / 30.44)))
}
cat("Year table:\n"); print(table(d$year, useNA = "ifany"))
cat("Month range:", range(d$month, na.rm = TRUE), "\n")

# electricity quantity/expenditure: pick pair with plausible EUR/kWh price
pairs <- list(c("c_ele", "g_ele"), c("c_ele2", "g_ele2"), c("c_ele", "g_ele2"), c("c_ele2", "g_ele"))
ym <- d$year * 12 + d$month
inwin <- !is.na(ym) & ym >= 2011 * 12 + 8 & ym <= 2014 * 12 + 3
chosen <- NULL
for (p in pairs) {
  if (is.na(v[[p[1]]]) || is.na(v[[p[2]]])) next
  q <- g(p[1]); e <- g(p[2])
  ok <- inwin & q > 0 & e > 0 & !is.na(q) & !is.na(e)
  if (sum(ok) < 100) next
  mp <- median(e[ok] / q[ok])
  cat("Pair", p, "median price:", mp, " n:", sum(ok), "\n")
  if (is.null(chosen) && mp > 0.08 && mp < 0.40) chosen <- p
}
if (is.null(chosen)) chosen <- c("c_ele", "g_ele")
cat("Chosen electricity vars:", chosen, "\n")
d$q <- g(chosen[1]); d$e <- g(chosen[2])

d$inc <- g("inc")
d$c_pap <- g("c_pap"); d$g_pap <- g("g_pap")
d$c_agu <- g("c_agu"); d$g_agu <- g("g_agu")
d$c_car <- g("c_car"); d$g_car <- g("g_car")

negNA <- function(x) { x[!is.na(x) & x < 0] <- NA; x }
d$hhsize <- negNA(g("hhsize"))
d$rooms  <- negNA(g("rooms"))
d$surf   <- negNA(g("surf"))
d$elderly <- ifelse(is.na(g("eld")), NA, as.numeric(g("eld") > 0))
d$educ   <- negNA(g("educ"))
d$nact   <- negNA(g("nact"))
ten <- negNA(g("tenure"))
d$rent   <- ifelse(is.na(ten), NA, as.numeric(ten %in% c(3, 4)))
d$bage   <- negNA(g("bage"))
d$tamamu <- negNA(g("tamamu"))
d$urban  <- negNA(g("urban"))
d$caprov <- negNA(g("caprov"))
d$ccaa   <- negNA(g("ccaa"))
if (!is.na(v$T2)) d$T2 <- g("T2")

# de-duplicate household-year
d <- d[!is.na(d$id) & !is.na(d$year), ]
d <- d[!duplicated(d[, c("id", "year")]), ]

# sample window Aug 2011 - Mar 2014 (before the April 2014 price change)
R <- 2013 * 12 + 8
d$ym <- d$year * 12 + d$month
d <- d[!is.na(d$ym) & d$ym >= 2011 * 12 + 8 & d$ym <= 2014 * 12 + 3, ]
cat("Obs in window:", nrow(d), "\n")

d <- d %>% group_by(id) %>%
  mutate(n_int = n(), first_ym = min(ym), last_ym = max(ym)) %>% ungroup() %>% as.data.frame()
cat("Interviews per id in window:\n"); print(table(d$n_int))
d <- d[d$n_int == 2, ]
d$D <- ifelse(d$first_ym < R & d$last_ym >= R, 1, ifelse(d$last_ym < R, 0, NA))
d <- d[!is.na(d$D), ]
cat("Full panel obs:", nrow(d), " households:", length(unique(d$id)), "\n")

d$T <- as.numeric(d$ym >= R)
d$msr <- ifelse(d$T == 1, d$ym - R, 0)
d$quarter <- ceiling(d$month / 3)
if (!is.null(d$T2)) { cat("T vs T2:\n"); print(table(d$T, d$T2, useNA = "ifany")) }

pos <- function(x) ifelse(!is.na(x) & x > 0, x, NA)
d$lq <- log(pos(d$q))
d$lg <- log(pos(d$e))
d$lp <- d$lg - d$lq
if (inc_log) d$ly <- d$inc else d$ly <- log(pos(d$inc))
d$ly2 <- d$ly^2
d$z1 <- log(pos(d$g_pap) / pos(d$c_pap))
d$z2 <- log(pos(d$g_agu) / pos(d$c_agu))
d$z3 <- log(pos(d$g_car) / pos(d$c_car))
cat("Price summary:\n"); print(summary(exp(d$lp)))

core <- c("lq", "lg", "lp", "ly", "ly2", "z1", "z2", "z3", "T", "msr", "quarter", "year", "id")
cc <- complete.cases(d[, core])
cat("Core complete:", sum(cc), "\n")

ctrl_num <- c("hhsize", "rooms", "surf", "elderly", "rent", "urban")
ctrl_fac <- c("educ", "nact", "bage", "tamamu", "caprov", "ccaa")
keep_ctrl <- c()
for (cv in c(ctrl_num, ctrl_fac)) {
  x <- d[[cv]][cc]
  sh <- mean(is.na(x))
  nun <- length(unique(na.omit(x)))
  cat(sprintf("Control %-8s NA share %.3f, unique %d\n", cv, sh, nun))
  if (sh <= 0.10 && nun > 1) keep_ctrl <- c(keep_ctrl, cv)
}
if ("nact" %in% keep_ctrl) d$nact <- pmin(d$nact, 2)
terms <- c()
for (cv in keep_ctrl) {
  if (cv %in% ctrl_fac) terms <- c(terms, paste0("factor(", cv, ")")) else terms <- c(terms, cv)
}
ctrl_str <- paste(terms, collapse = " + ")

est <- d[complete.cases(d[, c(core, keep_ctrl)]), ]
cat("Estimation sample:", nrow(est), " households:", length(unique(est$id)), "\n")

exo <- paste("T + msr + ly + ly2", if (nchar(ctrl_str)) paste("+", ctrl_str) else "",
             "+ factor(quarter) + factor(year)")

# OLS and FE
fit <- function(dep, fe) {
  f <- as.formula(paste(dep, "~ lp +", exo, if (fe) "| id" else ""))
  feols(f, data = est, cluster = ~id, fixef.rm = "none")
}
m1 <- fit("lq", FALSE); m3 <- fit("lq", TRUE)
m5 <- fit("lg", FALSE); m7 <- fit("lg", TRUE)

# LIML (k-class) with exogenous regressors partialled out
liml <- function(dep, fe) {
  resv <- function(vn) {
    f <- as.formula(paste(vn, "~", exo, if (fe) "| id" else ""))
    m <- feols(f, data = est, fixef.rm = "none", notes = FALSE, warn = FALSE)
    r <- resid(m, na.rm = FALSE)
    if (length(r) != nrow(est)) stop("residual length mismatch")
    r
  }
  ry <- resv(dep); rx <- resv("lp")
  Z <- cbind(resv("z1"), resv("z2"), resv("z3"))
  ok <- complete.cases(cbind(ry, rx, Z))
  ry <- ry[ok]; rx <- rx[ok]; Z <- Z[ok, , drop = FALSE]
  Y <- cbind(ry, rx)
  ZtZi <- solve(crossprod(Z))
  MY <- Y - Z %*% (ZtZi %*% crossprod(Z, Y))
  W1 <- crossprod(Y, MY)
  W0 <- crossprod(Y)
  kap <- min(Re(eigen(solve(W1) %*% W0)$values))
  Mx <- MY[, 2]; My <- MY[, 1]
  b <- (sum(rx * ry) - kap * sum(rx * My)) / (sum(rx * rx) - kap * sum(rx * Mx))
  # first-stage F (partialled)
  fs <- lm(rx ~ Z - 1)
  Fst <- (sum(fitted(fs)^2) / 3) / (sum(resid(fs)^2) / (length(rx) - 3))
  est$ystar__ <- est[[dep]] - b * est$lp
  f2 <- as.formula(paste("ystar__ ~", exo, if (fe) "| id" else ""))
  m2 <- feols(f2, data = est, fixef.rm = "none", notes = FALSE, warn = FALSE)
  cat(sprintf("LIML %s fe=%s: kappa=%.4f, b_lp=%.4f, first-stage F=%.2f\n", dep, fe, kap, b, Fst))
  unname(coef(m2)["T"])
}
t2 <- liml("lq", FALSE); t4 <- liml("lq", TRUE)
t6 <- liml("lg", FALSE); t8 <- liml("lg", TRUE)

cT <- function(m) unname(coef(m)["T"])
cat("OLS col1:\n"); print(coeftable(m1)[c("T", "lp", "ly"), ])
cat("FE col3:\n"); print(coeftable(m3)[c("T", "lp", "ly"), ])

n_obs <- nobs(m1)
n_hh <- length(unique(est$id))

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", cT(m1)))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", t2))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", cT(m3)))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", t4))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", cT(m5)))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", t6))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", cT(m7)))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", t8))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", unname(coef(m1)["lp"])))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", unname(coef(m3)["lp"])))
cat(sprintf("RESULT:n_obs_table2=%d\n", as.integer(n_obs)))
cat(sprintf("RESULT:n_households_table2=%d\n", as.integer(n_hh)))
