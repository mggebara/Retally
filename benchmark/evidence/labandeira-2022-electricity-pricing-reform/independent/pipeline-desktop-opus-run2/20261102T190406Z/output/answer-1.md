suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"

nm <- tryCatch(names(read_dta(path, n_max = 0)), error = function(e) NULL)
full <- NULL
if (is.null(nm) || length(nm) == 0) {
  full <- read_dta(path)
  nm <- names(full)
}
cat("Number of columns:", length(nm), "\n")
cat("Columns:", paste(nm, collapse = ", "), "\n")

find_var <- function(exact, pattern = NULL, exclude = NULL) {
  low <- tolower(nm)
  for (e in exact) {
    i <- which(low == tolower(e))
    if (length(i)) return(nm[i[1]])
  }
  if (!is.null(pattern)) {
    i <- grep(pattern, nm, ignore.case = TRUE)
    if (!is.null(exclude) && length(i)) i <- i[!grepl(exclude, nm[i], ignore.case = TRUE)]
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}

v <- list()
v$id      <- find_var(c("id"))
v$yr      <- find_var(c("ANOENC", "year"))
v$month   <- find_var(c("month", "mes"))
v$bis     <- find_var(c("BISEMANA", "BIS"))
v$c_ele   <- find_var(c("c_ele"))
v$g_ele   <- find_var(c("g_ele"))
v$c_ele2  <- find_var(c("c_ele2"))
v$g_ele2  <- find_var(c("g_ele2"))
v$c_pap   <- find_var(c("c_papas"))
v$g_pap   <- find_var(c("g_papas"))
v$c_agu   <- find_var(c("c_aguav"))
v$g_agu   <- find_var(c("g_aguav"))
v$c_car   <- find_var(c("c_car"))
v$g_car   <- find_var(c("g_car"))
v$factor  <- find_var(c("FACTOR"))
v$income  <- find_var(c("IMPEXAC", "income", "ingresos", "renta", "ingreso", "inc", "y"),
                      "impexac|income|ingres", "imput|interin|^ln|^log|_ln|2$|sq")
v$interin <- find_var(c("INTERIN"))
v$totexp  <- find_var(c("TotExp", "GH", "gh"))
v$hhsize  <- find_var(c("NMIEMB", "hhsize", "hh_size"))
v$rooms   <- find_var(c("NHABIT", "rooms", "nhab", "numhab"), "habit|rooms", "habitual")
v$surface <- find_var(c("SUPERF", "surface", "superficie", "m2"), "superf|surface")
v$elder   <- find_var(c("mayores_count", "elderly", "mayores"))
v$educ    <- find_var(c("ESTUDREDSP", "educ", "educ4", "ESTUDIOSSP", "NIVESTUD", "ESTUDIOS"), "estudred|educ|estudios")
v$active  <- find_var(c("NUMACTIVOS", "numactivos", "nactivos", "activos", "NUMACT", "SITUACT"), "activ")
v$tenure  <- find_var(c("REGTEN", "renting", "rent", "tenencia"), "regten|tenen")
v$old     <- find_var(c("ANNOCON", "ANOCON", "old25", "older25"), "annocon|anocon|antig")
v$tamamu  <- find_var(c("TAMAMU"))
v$urban   <- find_var(c("urban", "DENSI"))
v$caprov  <- find_var(c("CAPROV"))
v$ccaa    <- find_var(c("CCAA"))
print(unlist(v))

needed <- unique(na.omit(unlist(v)))
if (is.null(full)) {
  d <- read_dta(path, col_select = all_of(needed))
} else {
  d <- full[, needed]
  rm(full)
}
d <- as.data.frame(d)
d[] <- lapply(d, function(x) suppressWarnings(as.numeric(zap_labels(x))))
gc()

getv <- function(key) if (!is.na(v[[key]])) d[[v[[key]]]] else rep(NA_real_, nrow(d))

df <- data.frame(id = getv("id"), yr = getv("yr"))
mo <- getv("month")
if (all(is.na(mo)) || max(mo, na.rm = TRUE) > 12) {
  b <- getv("bis")
  mo <- pmin(12, floor((b - 1) * 14 / 30.44) + 1)
}
df$mo <- mo

# ---- electricity quantity / expenditure: choose plausible pair ----
cands <- list(c("c_ele", "g_ele"), c("c_ele2", "g_ele2"), c("c_ele2", "g_ele"), c("c_ele", "g_ele2"))
chosen <- NULL
for (cc in cands) {
  if (is.na(v[[cc[1]]]) || is.na(v[[cc[2]]])) next
  q <- getv(cc[1]); g <- getv(cc[2])
  ok <- !is.na(q) & !is.na(g) & q > 0 & g > 0
  if (sum(ok) < 1000) next
  mp <- median(g[ok] / q[ok])
  cat("Candidate", cc, "median price", mp, "n", sum(ok), "\n")
  if (is.null(chosen)) chosen <- cc
  if (mp > 0.06 && mp < 0.45) { chosen <- cc; break }
}
cat("Chosen electricity vars:", chosen, "\n")
df$q <- getv(chosen[1]); df$g <- getv(chosen[2])
fac <- getv("factor")
# if quantities/expenditures are population-elevated, undo the elevation
if (!all(is.na(fac)) && median(df$g[df$g > 0], na.rm = TRUE) > 20000) {
  cat("Expenditures appear elevated by FACTOR; dividing.\n")
  df$q <- df$q / fac; df$g <- df$g / fac
}

# ---- income ----
inc <- getv("income")
if (all(is.na(inc)) || sum(inc > 0, na.rm = TRUE) < 1000) {
  ii <- getv("interin")
  if (!all(is.na(ii))) {
    mids <- c(250, 750, 1250, 1750, 2250, 2750, 4000, 6000, 8000, 10000)
    inc <- ifelse(ii >= 1 & ii <= 10, mids[pmax(1, pmin(10, ii))], NA)
    cat("Using INTERIN midpoints for income\n")
  } else {
    inc <- getv("totexp")
    cat("Using total expenditure as income proxy\n")
  }
}
df$inc <- inc

# ---- instruments: unit values ----
uv <- function(gk, ck) {
  g <- getv(gk); q <- getv(ck)
  ifelse(!is.na(g) & !is.na(q) & g > 0 & q > 0, g / q, NA)
}
df$uv_pap <- uv("g_pap", "c_pap")
df$uv_agu <- uv("g_agu", "c_agu")
df$uv_car <- uv("g_car", "c_car")

# ---- controls ----
df$hhsize  <- getv("hhsize")
df$rooms   <- getv("rooms")
df$surface <- getv("surface")
el <- getv("elder"); df$elderly <- ifelse(is.na(el), NA, as.numeric(el > 0))
df$educ    <- getv("educ")
ac <- getv("active"); df$active <- ifelse(is.na(ac), NA, pmin(ac, 2))
df$tenure  <- getv("tenure")
df$old     <- getv("old")
df$tamamu  <- getv("tamamu")
df$urban   <- getv("urban")
df$caprov  <- getv("caprov")
df$ccaa    <- getv("ccaa")
df$quarter <- ceiling(df$mo / 3)
rm(d); gc()

# ---- sample: interviews Aug 2011 - Apr 2014, paired households ----
df$dm <- df$yr * 12 + df$mo
lo <- 2011 * 12 + 8; hi <- 2014 * 12 + 4; R <- 2013 * 12 + 8
df <- df[!is.na(df$dm) & df$dm >= lo & df$dm <= hi & !is.na(df$id), ]
df <- df[!duplicated(df[, c("id", "yr")]), ]
cat("Obs in window:", nrow(df), "\n")

pairinfo <- df %>% group_by(id) %>% summarise(n = n(), dy = max(yr) - min(yr), .groups = "drop")
good_ids <- pairinfo$id[pairinfo$n == 2 & pairinfo$dy == 1]
cat("Paired households:", length(good_ids), "\n")
if (length(good_ids) > 1000) {
  df <- df[df$id %in% good_ids, ]
} else {
  cat("Few paired households found; using all in-window observations\n")
}
cat("Obs after pairing:", nrow(df), "\n")

df$reform <- as.integer(df$dm >= R)
df$msr <- ifelse(df$reform == 1, df$dm - R, 0)

df$lnq <- ifelse(df$q > 0, log(df$q), NA)
df$lng <- ifelse(df$g > 0, log(df$g), NA)
df$lnp <- ifelse(df$q > 0 & df$g > 0, log(df$g / df$q), NA)
df$lny <- ifelse(!is.na(df$inc) & df$inc > 0, log(df$inc), NA)
df$lny2 <- df$lny^2

# impute missing instrument unit values with local medians if coverage is low
impute_uv <- function(x) {
  share <- mean(!is.na(x))
  cat("Instrument coverage:", share, "\n")
  if (share >= 0.95) return(x)
  tmp <- data.frame(x = x, ccaa = df$ccaa, yr = df$yr, qt = df$quarter)
  m1 <- ave(tmp$x, tmp$ccaa, tmp$yr, tmp$qt, FUN = function(z) median(z, na.rm = TRUE))
  m2 <- ave(tmp$x, tmp$ccaa, tmp$yr, FUN = function(z) median(z, na.rm = TRUE))
  m3 <- ave(tmp$x, tmp$yr, FUN = function(z) median(z, na.rm = TRUE))
  out <- x
  out[is.na(out)] <- m1[is.na(out)]
  out[is.na(out)] <- m2[is.na(out)]
  out[is.na(out)] <- m3[is.na(out)]
  out
}
df$z1 <- log(impute_uv(df$uv_pap))
df$z2 <- log(impute_uv(df$uv_agu))
df$z3 <- log(impute_uv(df$uv_car))

cont_c <- c("hhsize", "rooms", "surface", "elderly")
cat_c  <- c("educ", "active", "tenure", "old", "tamamu", "urban", "caprov", "ccaa", "quarter")
usable <- function(x) sum(!is.na(x)) > 0.5 * length(x) && length(unique(na.omit(x))) > 1
cont_c <- cont_c[sapply(cont_c, function(k) usable(df[[k]]))]
cat_c  <- cat_c[sapply(cat_c, function(k) usable(df[[k]]))]
cat("Continuous controls:", cont_c, "\nCategorical controls:", cat_c, "\n")

allv <- c("id", "yr", "lnq", "lng", "lnp", "lny", "lny2", "reform", "msr", "z1", "z2", "z3", cont_c, cat_c)
est <- df[complete.cases(df[, allv]), allv]
for (k in c("z1", "z2", "z3")) est <- est[is.finite(est[[k]]), ]
cat("Estimation sample:", nrow(est), " households:", length(unique(est$id)), "\n")

cont_c <- cont_c[sapply(cont_c, function(k) length(unique(est[[k]])) > 1)]
cat_c  <- cat_c[sapply(cat_c, function(k) length(unique(est[[k]])) > 1)]

exog_terms <- c("reform", "msr", "lny", "lny2", cont_c, if (length(cat_c)) paste0("factor(", cat_c, ")"))
rhs <- paste(c("reform", "msr", "lnp", exog_terms[-(1:2)]), collapse = " + ")

res <- list()
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
  # first stage F (non-robust) for diagnostics
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

# fallback to 2SLS if LIML failed
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
