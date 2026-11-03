suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"

hdr <- read_dta(path, n_max = 5)
nm <- names(hdr)
cat("Number of columns:", length(nm), "\n")
print(nm)

fc <- function(cands) {
  for (c in cands) { i <- which(nm == c); if (length(i)) return(nm[i[1]]) }
  for (c in cands) { i <- which(tolower(nm) == tolower(c)); if (length(i)) return(nm[i[1]]) }
  NA_character_
}

v <- list(
  id = fc(c("id")),
  year = fc(c("year")),
  anoenc = fc(c("ANOENC")),
  month = fc(c("month")),
  bis = fc(c("BISEMANA", "BIS")),
  c_ele = fc(c("c_ele")), g_ele = fc(c("g_ele")),
  c_ele2 = fc(c("c_ele2")), g_ele2 = fc(c("g_ele2")),
  pvar = fc(c("p_ele", "price", "precio", "p", "pele", "price_ele", "precio_ele", "lnp", "lp", "lprice", "ln_p", "lnprice", "lpele", "lnp_ele")),
  c_pap = fc(c("c_papas")), g_pap = fc(c("g_papas")),
  c_agu = fc(c("c_aguav")), g_agu = fc(c("g_aguav")),
  c_car = fc(c("c_car")), g_car = fc(c("g_car")),
  inc = fc(c("IMPEXAC", "IMPEXACPOND", "INGRESOS", "income", "INCOME", "ingreso", "renta")),
  totexp = fc(c("TotExp", "GASTOT", "GH")),
  hsize = fc(c("NMIEMB")),
  rooms = fc(c("NHABIT", "NUMHABIT", "habitaciones", "rooms")),
  surf = fc(c("SUPERF", "SUPERFICIE", "surface")),
  eld = fc(c("mayores_count")),
  edu = fc(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDIOS_SP", "NIVESTSP", "ESTUDIOS", "educ", "education", "edu")),
  econ = fc(c("NUMACTI", "NACTIVOS", "NUMACTIV", "nactivos", "activos", "NUMOCUP", "NUMOCU")),
  tenure = fc(c("REGTEN", "tenencia")),
  build = fc(c("ANNOCON", "ANOCON", "edad_edif")),
  tamamu = fc(c("TAMAMU")),
  urban = fc(c("urban")),
  densi = fc(c("DENSI")),
  caprov = fc(c("CAPROV")),
  ccaa = fc(c("CCAA")),
  T2 = fc(c("T2")),
  dup = fc(c("dup"))
)
cat("Variable mapping:\n"); print(unlist(v))

sel <- unique(na.omit(unlist(v)))
raw <- read_dta(path, col_select = dplyr::all_of(sel))
raw <- zap_labels(raw)
dt <- as.data.table(raw)
rm(raw); invisible(gc())
setnames(dt, old = unlist(v)[!is.na(unlist(v))], new = names(v)[!is.na(unlist(v))], skip_absent = TRUE)
cat("Rows:", nrow(dt), "\n")
num <- function(x) suppressWarnings(as.numeric(x))

# ---- interview date ----
yr <- NULL
if ("year" %in% names(dt)) { yy <- num(dt$year); if (mean(yy >= 2000 & yy <= 2020, na.rm = TRUE) > 0.9) yr <- yy }
if (is.null(yr) && "anoenc" %in% names(dt)) yr <- num(dt$anoenc)
dt[, yr := yr]
mo <- NULL
if ("month" %in% names(dt)) { mm <- num(dt$month); if (mean(mm >= 1 & mm <= 12, na.rm = TRUE) > 0.9) mo <- mm }
if (is.null(mo) && "bis" %in% names(dt)) { b <- num(dt$bis); mo <- pmin(12, floor((b - 1) / 26 * 12) + 1) }
dt[, mo := mo]
cat("Year table:\n"); print(table(dt$yr, useNA = "ifany"))
cat("Month table:\n"); print(table(dt$mo, useNA = "ifany"))
dt[, ym := yr * 12 + mo]
ref <- 2013 * 12 + 8
lo <- 2011 * 12 + 8
hi <- 2014 * 12 + 4
if ("dup" %in% names(dt)) { cat("dup table:\n"); print(table(dt$dup, useNA = "ifany")) }

build <- function(excl_summer, need2, dropdup = FALSE) {
  s <- dt[!is.na(ym) & ym >= lo & ym <= hi]
  if (dropdup && "dup" %in% names(s)) s <- s[is.na(num(dup)) | num(dup) == 0]
  if (excl_summer) s <- s[!(mo %in% 5:7)]
  s[, post := as.integer(ym >= ref)]
  s[, has_pre := any(post == 0), by = id]
  s <- s[has_pre == TRUE]
  s[, nid := .N, by = id]
  if (need2) s <- s[nid >= 2]
  s
}
variants <- expand.grid(excl = c(FALSE, TRUE), need2 = c(TRUE, FALSE))
best <- NULL; bestdiff <- Inf
for (i in seq_len(nrow(variants))) {
  s <- build(variants$excl[i], variants$need2[i])
  cat(sprintf("Variant excl_summer=%s need2=%s: obs=%d households=%d\n",
              variants$excl[i], variants$need2[i], nrow(s), uniqueN(s$id)))
  d <- abs(nrow(s) - 25775)
  if (d < bestdiff) { bestdiff <- d; best <- i }
}
cat("Chosen variant:", best, "\n")
s_all <- build(variants$excl[best], variants$need2[best], FALSE)
s_nodup <- if ("dup" %in% names(dt)) build(variants$excl[best], variants$need2[best], TRUE) else NULL
rm(dt); invisible(gc())

# ---- prepare a sample: returns estimation data ----
prep <- function(s, quiet = FALSE) {
  s <- copy(s)
  s[, Tr := post]
  s[, msr := ifelse(Tr == 1, ym - ref, 0)]
  s[, c_ele := num(c_ele)][, g_ele := num(g_ele)]
  s[, lnq := ifelse(c_ele > 0 & g_ele > 0, log(c_ele), NA_real_)]
  s[, lnexp := ifelse(c_ele > 0 & g_ele > 0, log(g_ele), NA_real_)]
  s[, lnp_own := ifelse(c_ele > 0 & g_ele > 0, log(g_ele / c_ele), NA_real_)]
  # price: prefer an explicit price variable from the replication data; otherwise
  # the alternative bill-based price (c_ele2/g_ele2); avoids the mechanical identity
  # ln(exp) = ln(q) + ln(p) that makes expenditure models identical to consumption models
  ptype <- "own"
  s[, lnp := lnp_own]
  if ("pvar" %in% names(s)) {
    pv <- num(s$pvar)
    if (mean(!is.na(pv)) > 0.5) {
      if (grepl("^l", v$pvar, ignore.case = TRUE) && !(v$pvar %in% c("p", "price"))) s[, lnp := pv] else s[, lnp := ifelse(pv > 0, log(pv), NA_real_)]
      ptype <- paste("var", v$pvar)
    }
  } else if (all(c("c_ele2", "g_ele2") %in% names(s))) {
    c2 <- num(s$c_ele2); g2 <- num(s$g_ele2)
    lp2 <- ifelse(c2 > 0 & g2 > 0, log(g2 / c2), NA_real_)
    if (mean(!is.na(lp2)) > 0.5 && mean(abs(lp2 - s$lnp_own) > 1e-8, na.rm = TRUE) > 0.05) {
      s[, lnp := lp2]; ptype <- "ele2"
    }
  }
  if (!quiet) cat("Price definition used:", ptype, "\n")

  if ("inc" %in% names(s)) s[, yinc := num(inc) * 12] else s[, yinc := num(totexp)]
  s[, lny := ifelse(yinc > 0, log(yinc), NA_real_)]
  if (mean(is.na(s$lny)) > 0.2 && "totexp" %in% names(s)) {
    s[, yinc := num(totexp)]
    s[, lny := ifelse(yinc > 0, log(yinc), NA_real_)]
  }
  s[, lny2 := lny^2]

  mkz <- function(g, c) { g <- num(g); c <- num(c); ifelse(!is.na(g) & !is.na(c) & g > 0 & c > 0, log(g / c), NA_real_) }
  s[, z_pap := if ("g_pap" %in% names(s)) mkz(g_pap, c_pap) else NA_real_]
  s[, z_agu := if ("g_agu" %in% names(s)) mkz(g_agu, c_agu) else NA_real_]
  s[, z_car := if ("g_car" %in% names(s)) mkz(g_car, c_car) else NA_real_]
  insts <- c("z_pap", "z_agu", "z_car")
  insts <- insts[sapply(insts, function(z) mean(is.na(s[[z]])) < 0.98)]

  s[, quarter := ceiling(mo / 3)]
  num_ctrl <- c(); fe_ctrl <- c()
  if ("hsize" %in% names(s)) { s[, x_hsize := num(hsize)]; num_ctrl <- c(num_ctrl, "x_hsize") }
  if ("rooms" %in% names(s)) { s[, x_rooms := num(rooms)]; num_ctrl <- c(num_ctrl, "x_rooms") }
  if ("surf" %in% names(s)) { s[, x_surf := num(surf)]; num_ctrl <- c(num_ctrl, "x_surf") }
  if ("eld" %in% names(s)) { s[, x_elderly := as.numeric(num(eld) > 0)]; num_ctrl <- c(num_ctrl, "x_elderly") }
  if ("tenure" %in% names(s)) { s[, x_rent := as.numeric(num(tenure) %in% c(3, 4))]; num_ctrl <- c(num_ctrl, "x_rent") }
  if ("urban" %in% names(s)) { s[, x_urban := num(urban)]; num_ctrl <- c(num_ctrl, "x_urban") } else if ("densi" %in% names(s)) { s[, f_densi := as.character(densi)]; fe_ctrl <- c(fe_ctrl, "f_densi") }
  if ("edu" %in% names(s)) { s[, f_edu := as.character(edu)]; fe_ctrl <- c(fe_ctrl, "f_edu") }
  if ("econ" %in% names(s)) { s[, f_econ := as.character(pmin(num(econ), 2))]; fe_ctrl <- c(fe_ctrl, "f_econ") }
  if ("build" %in% names(s)) { s[, f_build := as.character(build)]; fe_ctrl <- c(fe_ctrl, "f_build") }
  if ("tamamu" %in% names(s)) { s[, f_tamamu := as.character(tamamu)]; fe_ctrl <- c(fe_ctrl, "f_tamamu") }
  if ("caprov" %in% names(s)) { s[, f_caprov := as.character(caprov)]; fe_ctrl <- c(fe_ctrl, "f_caprov") }
  s[, f_year := as.character(yr)]
  s[, f_ccaaq := paste(ccaa, quarter, sep = "_")]
  fe_base <- c("f_year", "f_ccaaq", fe_ctrl)
  for (cc in c(num_ctrl, fe_ctrl)) {
    sh <- mean(is.na(s[[cc]]) | s[[cc]] == "NA")
    if (sh > 0.10) { num_ctrl <- setdiff(num_ctrl, cc); fe_base <- setdiff(fe_base, cc) }
  }
  for (cc in fe_base) s[is.na(get(cc)) | get(cc) == "NA", (cc) := NA_character_]
  base_vars <- c("lnq", "lnexp", "lnp", "lny", "lny2", "Tr", "msr", num_ctrl, fe_base, "id")
  cc_base <- complete.cases(s[, ..base_vars])
  cc_inst <- cc_base & complete.cases(s[, ..insts])
  if (sum(cc_inst) < 0.9 * sum(cc_base)) {
    for (z in insts) {
      s[, tmpm := mean(get(z), na.rm = TRUE), by = .(ccaa, yr)]
      s[is.na(get(z)), (z) := tmpm]
      s[is.na(get(z)), (z) := mean(s[[z]], na.rm = TRUE)]
      s[, tmpm := NULL]
    }
    cc_inst <- cc_base & complete.cases(s[, ..insts])
  }
  d <- s[cc_inst]
  list(d = d, insts = insts, num_ctrl = num_ctrl, fe_base = fe_base)
}

P <- prep(s_all)
if (!is.null(s_nodup)) {
  P2 <- prep(s_nodup, quiet = TRUE)
  cat("Estimation N all:", nrow(P$d), " N excluding dup:", nrow(P2$d), "\n")
  if (abs(nrow(P2$d) - 20872) < abs(nrow(P$d) - 20872)) {
    cat("DEVIATION: excluding observations flagged dup==1 (duplicate records) to match the paper's estimation sample size\n")
    P <- P2
  }
}
d <- P$d; insts <- P$insts; num_ctrl <- P$num_ctrl; fe_base <- P$fe_base
cat("Estimation sample N =", nrow(d), " households =", uniqueN(d$id), "\n")
cat("T table:\n"); print(table(d$Tr))

exog <- c("lny", "lny2", "Tr", "msr", num_ctrl)
fe_ols <- fe_base
fe_hh <- c("id", fe_base)

run_ols <- function(dep, fes) {
  f <- as.formula(paste(dep, "~", paste(c("lnp", exog), collapse = " + "), "|", paste(fes, collapse = " + ")))
  feols(f, data = d, cluster = ~id)
}

liml <- function(dep, fes) {
  vars <- c(dep, "lnp", exog, insts)
  M <- as.matrix(d[, ..vars])
  storage.mode(M) <- "double"
  fdf <- as.data.frame(d[, ..fes])
  M <- as.matrix(fixest::demean(M, fdf))
  colnames(M) <- vars
  y <- M[, dep]
  ex <- exog
  ex <- ex[apply(M[, ex, drop = FALSE], 2, function(x) var(x) > 1e-10)]
  q0 <- qr(M[, ex, drop = FALSE]); ex <- ex[q0$pivot[seq_len(q0$rank)]]
  if (!("Tr" %in% ex)) ex <- unique(c("Tr", ex))
  X <- M[, c("lnp", ex), drop = FALSE]
  W <- M[, ex, drop = FALSE]
  Z <- M[, c(ex, insts), drop = FALSE]
  Y0 <- cbind(y, M[, "lnp"])
  qW <- qr(W); qZ <- qr(Z)
  MW <- qr.resid(qW, Y0); MZ <- qr.resid(qZ, Y0)
  A <- crossprod(MW); B <- crossprod(MZ)
  k <- min(Re(eigen(solve(B, A))$values))
  MZX <- qr.resid(qZ, X)
  XX <- crossprod(X) - k * crossprod(MZX, X)
  Xy <- crossprod(X, y) - k * crossprod(MZX, y)
  b <- drop(solve(XX, Xy)); names(b) <- colnames(X)
  u <- y - drop(X %*% b)
  Xh <- X - k * MZX
  bread <- solve(crossprod(Xh, X))
  sc <- rowsum(Xh * u, d$id)
  V <- bread %*% crossprod(sc) %*% t(bread)
  G <- nrow(sc)
  V <- V * G / (G - 1)
  se <- sqrt(diag(V)); names(se) <- colnames(X)
  list(coef = b, se = se, kappa = k)
}

safe <- function(expr) tryCatch(expr, error = function(e) { cat("ERROR:", conditionMessage(e), "\n"); NULL })

m1 <- safe(run_ols("lnq", fe_ols))
m2 <- safe(liml("lnq", fe_ols))
m3 <- safe(run_ols("lnq", fe_hh))
m4 <- safe(liml("lnq", fe_hh))
m5 <- safe(run_ols("lnexp", fe_ols))
m6 <- safe(liml("lnexp", fe_ols))
m7 <- safe(run_ols("lnexp", fe_hh))
m8 <- safe(liml("lnexp", fe_hh))

pr_f <- function(m, lab) {
  if (is.null(m)) return(invisible())
  cat("==== ", lab, " ====\n")
  if (inherits(m, "fixest")) print(coeftable(m)[c("lnp", "Tr", "msr", "lny"), , drop = FALSE])
  else { cat("kappa:", m$kappa, "\n"); print(cbind(coef = m$coef, se = m$se)[intersect(c("lnp", "Tr", "msr", "lny"), names(m$coef)), , drop = FALSE]) }
}
pr_f(m1, "col1 OLS cons"); pr_f(m2, "col2 LIML cons"); pr_f(m3, "col3 FE cons"); pr_f(m4, "col4 FE-LIML cons")
pr_f(m5, "col5 OLS exp"); pr_f(m6, "col6 LIML exp"); pr_f(m7, "col7 FE exp"); pr_f(m8, "col8 FE-LIML exp")

gc_ <- function(m, var) {
  if (is.null(m)) return(NA_real_)
  if (inherits(m, "fixest")) return(unname(coef(m)[var]))
  unname(m$coef[var])
}
out <- c(
  reform_consumption_ols_col1 = gc_(m1, "Tr"),
  reform_consumption_iv_col2 = gc_(m2, "Tr"),
  reform_consumption_fe_col3 = gc_(m3, "Tr"),
  reform_consumption_fe_iv_col4 = gc_(m4, "Tr"),
  reform_expenditure_ols_col5 = gc_(m5, "Tr"),
  reform_expenditure_iv_col6 = gc_(m6, "Tr"),
  reform_expenditure_fe_col7 = gc_(m7, "Tr"),
  reform_expenditure_fe_iv_col8 = gc_(m8, "Tr"),
  price_elasticity_consumption_ols_col1 = gc_(m1, "lnp"),
  price_elasticity_consumption_fe_col3 = gc_(m3, "lnp"),
  n_obs_table2 = if (!is.null(m1)) nobs(m1) else nrow(d),
  n_households_table2 = uniqueN(d$id)
)
for (nmx in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nmx, out[[nmx]]))
