## Reproduction of Labandeira, Labeaga & Teixido: Table 2 (DiD effect of the Aug-2013 Spanish
## electricity pricing reform). OLS, LIML-IV, household FE, household FE LIML-IV.
suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base  <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
f_dta <- file.path(base, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")
f_csv <- file.path(base, "3 Replication package/analysis data/Data_to run_DOFILE3.csv")

res <- list(
  reform_consumption_ols_col1 = NA_real_, reform_consumption_iv_col2 = NA_real_,
  reform_consumption_fe_col3 = NA_real_, reform_consumption_fe_iv_col4 = NA_real_,
  reform_expenditure_ols_col5 = NA_real_, reform_expenditure_iv_col6 = NA_real_,
  reform_expenditure_fe_col7 = NA_real_, reform_expenditure_fe_iv_col8 = NA_real_,
  price_elasticity_consumption_ols_col1 = NA_real_, price_elasticity_consumption_fe_col3 = NA_real_,
  n_obs_table2 = NA_real_, n_households_table2 = NA_real_
)
emit <- function() {
  for (k in names(res)) cat(sprintf("RESULT:%s=%s\n", k, format(res[[k]], digits = 10)))
}

main <- function() {
  raw <- tryCatch(haven::read_dta(f_dta), error = function(e) { message("dta read failed: ", conditionMessage(e)); NULL })
  if (is.null(raw)) {
    raw <- data.table::fread(f_csv, showProgress = FALSE)
  } else {
    raw <- haven::zap_labels(raw)
  }
  dt <- as.data.table(raw)
  rm(raw); invisible(gc())
  nm <- names(dt)
  cat("Rows:", nrow(dt), " Cols:", ncol(dt), "\n")
  cat("Columns:", paste(nm, collapse = " "), "\n")

  pick <- function(cands) {
    for (x in cands) { i <- which(tolower(nm) == tolower(x)); if (length(i)) return(nm[i[1]]) }
    NA_character_
  }
  num <- function(x) suppressWarnings(as.numeric(x))
  getv <- function(v, d = dt) if (is.na(v)) rep(NA_real_, nrow(d)) else num(d[[v]])

  ## ---------------- interview dates ----------------
  v_id <- pick(c("id"))
  dt[, hid := getv(v_id)]
  yr <- getv(pick("year"))
  if (all(is.na(yr))) yr <- getv(pick("ANOENC"))
  yr2 <- getv(pick("ANOENC"))
  yr[is.na(yr)] <- yr2[is.na(yr)]
  yr[!is.na(yr) & yr < 100] <- yr[!is.na(yr) & yr < 100] + 2000
  mo <- getv(pick("month"))
  bis <- getv(pick(c("BIS", "BISEMANA")))
  if (all(is.na(mo)) || max(mo, na.rm = TRUE) > 12) mo <- pmin(12, ceiling(bis * 12 / 26))
  mo[is.na(mo) & !is.na(bis)] <- pmin(12, ceiling(bis[is.na(mo) & !is.na(bis)] * 12 / 26))
  dt[, yr := yr]; dt[, mo := mo]; dt[, bis := bis]
  dt[, ym := yr * 12 + mo]
  cat("Year table:\n"); print(table(dt$yr, useNA = "ifany"))
  if (!is.na(pick("T2"))) { cat("T2 by year:\n"); print(table(dt$yr, getv(pick("T2")), useNA = "ifany")) }
  if (!is.na(pick("dup"))) { cat("dup table:\n"); print(table(getv(pick("dup")), useNA = "ifany")) }

  lo <- 2011 * 12 + 8; hi <- 2014 * 12 + 4; R <- 2013 * 12 + 8
  w <- dt[!is.na(hid) & !is.na(ym) & ym >= lo & ym <= hi]
  rm(dt); invisible(gc())
  setorder(w, hid, ym)
  w <- unique(w, by = c("hid", "yr"))
  cnt <- w[, .(n = .N, dy = max(yr) - min(yr), sameb = (length(unique(bis)) == 1)), by = hid]
  cat("Households in window:", nrow(cnt), " with 2 obs in consecutive years:",
      sum(cnt$n == 2 & cnt$dy == 1), " (same BIS among those:",
      sum(cnt$n == 2 & cnt$dy == 1 & cnt$sameb, na.rm = TRUE), ")\n")
  keep <- cnt[n == 2 & dy == 1, hid]
  if (length(keep) < 2000) {
    cat("WARNING: few panel pairs found; using all window observations\n")
    pan <- w
  } else {
    pan <- w[hid %in% keep]
  }
  rm(w); invisible(gc())
  cat("Pooled panel observations:", nrow(pan), "\n")

  pan[, Tpost := as.numeric(ym >= R)]
  pan[, msr := pmax(0, ym - R)]
  pan[, quarter := ceiling(mo / 3)]
  pan[, D := max(Tpost), by = hid]
  cat("Obs by D x Tpost:\n"); print(table(pan$D, pan$Tpost))

  ## ---------------- electricity q, expenditure, price ----------------
  epairs <- list(c("c_ele", "g_ele"), c("c_ele2", "g_ele2"))
  chosen <- NULL
  for (pp in epairs) {
    vc <- pick(pp[1]); vg <- pick(pp[2])
    if (is.na(vc) || is.na(vg)) next
    cc <- getv(vc, pan); gg <- getv(vg, pan)
    ok <- !is.na(cc) & !is.na(gg) & cc > 0 & gg > 0
    medp <- if (any(ok)) median(gg[ok] / cc[ok]) else NA
    cat(sprintf("Electricity pair %s/%s: positive share %.3f, median price %.4f, median q %.1f, median exp %.1f\n",
                vc, vg, mean(ok), medp, median(cc[ok]), median(gg[ok])))
    if (is.null(chosen) && !is.na(medp) && medp > 0.05 && medp < 0.5) chosen <- c(vc, vg)
  }
  if (is.null(chosen)) chosen <- c(pick("c_ele"), pick("g_ele"))
  cat("Using electricity variables:", chosen, "\n")
  q <- getv(chosen[1], pan); e <- getv(chosen[2], pan)
  okE <- !is.na(q) & !is.na(e) & q > 0 & e > 0
  pan[, lnq := ifelse(okE, log(q), NA_real_)]
  pan[, lnexp := ifelse(okE, log(e), NA_real_)]
  pan[, lnp := ifelse(okE, log(e / q), NA_real_)]

  ## ---------------- income ----------------
  v_inc <- pick(c("IMPEXAC", "impexac", "income", "ingresos", "ingreso", "renta", "INGHOG", "hhincome", "inc", "IMPEXACPSP"))
  if (is.na(v_inc)) {
    g <- grep("impex|renta|ingres|income", nm, ignore.case = TRUE, value = TRUE)
    if (length(g)) v_inc <- g[1]
  }
  if (is.na(v_inc)) {
    v_inc <- pick(c("TotExp", "GH", "gh"))
    cat("WARNING: no income variable found; using total expenditure as income proxy:", v_inc, "\n")
  }
  cat("Income variable:", v_inc, "\n")
  inc <- getv(v_inc, pan)
  print(summary(inc))
  pan[, lny := ifelse(!is.na(inc) & inc > 0, log(inc), NA_real_)]
  pan[, lny2 := lny^2]

  ## ---------------- controls ----------------
  numctl <- function(cands) { v <- pick(cands); x <- getv(v, pan); x[!is.na(x) & x < 0] <- NA; list(v = v, x = x) }
  ctl_num <- c(); ctl_fac <- c()
  addnum <- function(name, obj) {
    if (!is.na(obj$v) && sum(!is.na(obj$x)) > 0.5 * nrow(pan)) { pan[, (name) := obj$x]; ctl_num <<- c(ctl_num, name) }
    cat("control", name, "<-", obj$v, "\n")
  }
  addfac <- function(name, obj) {
    if (!is.na(obj$v) && sum(!is.na(obj$x)) > 0.5 * nrow(pan) && length(unique(na.omit(obj$x))) > 1) {
      pan[, (name) := obj$x]; ctl_fac <<- c(ctl_fac, name)
    }
    cat("factor control", name, "<-", obj$v, "\n")
  }
  addnum("hhsize", numctl(c("NMIEMB")))
  addnum("rooms", numctl(c("NHABIT", "NUMHAB", "NHAB", "rooms", "habitaciones")))
  addnum("surface", numctl(c("SUPERF", "superficie", "surface")))
  el <- numctl(c("mayores_count"))
  if (!is.na(el$v)) { el$x <- as.numeric(el$x > 0) }
  addnum("elderly", el)
  ten <- numctl(c("REGTEN", "tenencia"))
  if (!is.na(ten$v)) ten$x <- as.numeric(ten$x %in% c(3, 4))
  addnum("rent", ten)
  addfac("educ", numctl(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDREDSUS", "NIVESTUDSP", "ESTUDIOS", "educ", "EDUC")))
  act <- numctl(c("NUMACTI", "NACTIVOS", "NUMACT", "NMIEMACT", "NUMOCU"))
  if (!is.na(act$v)) act$x <- pmin(act$x, 2)
  addfac("econ", act)
  addfac("oldbld", numctl(c("ANNOCON", "ANOCON")))
  addfac("munsize", numctl(c("TAMAMU")))
  addfac("urb", numctl(c("urban", "DENSI")))
  addfac("capprov", numctl(c("CAPROV")))
  addfac("region", numctl(c("CCAA")))
  pan[, region_imp := getv(pick("CCAA"), pan)]

  ## ---------------- instruments: effective prices of potatoes, water, fuel ----------------
  inst <- c()
  for (pp in list(c("c_papas", "g_papas", "z_pot"), c("c_aguav", "g_aguav", "z_wat"), c("c_car", "g_car", "z_fuel"))) {
    vc <- pick(pp[1]); vg <- pick(pp[2])
    if (is.na(vc) || is.na(vg)) next
    cc <- getv(vc, pan); gg <- getv(vg, pan)
    pr <- ifelse(!is.na(cc) & !is.na(gg) & cc > 0 & gg > 0, gg / cc, NA_real_)
    tmp <- data.table(pr = pr, r = pan$region_imp, y = pan$yr, qq = pan$quarter)
    tmp[, m1 := median(pr, na.rm = TRUE), by = .(r, y, qq)]
    tmp[, m2 := median(pr, na.rm = TRUE), by = .(y)]
    cat(sprintf("Instrument %s: household price observed for %.3f of obs\n", pp[3], mean(!is.na(pr))))
    pr2 <- ifelse(is.na(pr), tmp$m1, pr)
    pr2 <- ifelse(is.na(pr2), tmp$m2, pr2)
    pan[, (pp[3]) := log(pr2)]
    inst <- c(inst, pp[3])
  }
  cat("Instruments:", inst, "\n")

  ## ---------------- estimation sample ----------------
  vars <- c("hid", "yr", "lnq", "lnexp", "lnp", "lny", "lny2", "Tpost", "msr", "quarter", ctl_num, ctl_fac, inst)
  df <- as.data.frame(pan[, ..vars])
  df <- df[complete.cases(df) & is.finite(rowSums(as.matrix(df[, c("lnq", "lnexp", "lnp", "lny", inst)]))), ]
  for (f in c(ctl_fac, "quarter", "yr")) df[[f]] <- factor(df[[f]])
  ctl_fac <- ctl_fac[sapply(ctl_fac, function(f) nlevels(droplevels(df[[f]])) > 1)]
  cat("Estimation sample:", nrow(df), " households:", length(unique(df$hid)), "\n")
  res$n_obs_table2 <<- nrow(df)
  res$n_households_table2 <<- length(unique(df$hid))

  rhs_terms <- c("lnp", "lny", "lny2", "Tpost", "msr", ctl_num,
                 paste0("factor(", ctl_fac, ")"), "factor(quarter)")
  rhs_ols <- paste(c(rhs_terms, "factor(yr)"), collapse = " + ")
  rhs_fe  <- paste(rhs_terms, collapse = " + ")

  ## ---------------- OLS and FE ----------------
  for (dv in c("lnq", "lnexp")) {
    m1 <- tryCatch(feols(as.formula(paste(dv, "~", rhs_ols)), data = df, cluster = ~hid),
                   error = function(e) { message("OLS fail: ", conditionMessage(e)); NULL })
    m3 <- tryCatch(feols(as.formula(paste(dv, "~", rhs_fe, "| hid + yr")), data = df, cluster = ~hid),
                   error = function(e) { message("FE fail: ", conditionMessage(e)); NULL })
    if (!is.null(m1)) { cat("\nOLS", dv, "\n"); print(coeftable(m1)[c("lnp", "lny", "lny2", "Tpost", "msr"), ]) }
    if (!is.null(m3)) { cat("\nFE", dv, "N =", nobs(m3), "\n"); print(coeftable(m3)[intersect(c("lnp", "lny", "lny2", "Tpost", "msr"), names(coef(m3))), ]) }
    if (dv == "lnq") {
      if (!is.null(m1)) { res$reform_consumption_ols_col1 <<- unname(coef(m1)["Tpost"]); res$price_elasticity_consumption_ols_col1 <<- unname(coef(m1)["lnp"]) }
      if (!is.null(m3)) { res$reform_consumption_fe_col3 <<- unname(coef(m3)["Tpost"]); res$price_elasticity_consumption_fe_col3 <<- unname(coef(m3)["lnp"]) }
    } else {
      if (!is.null(m1)) res$reform_expenditure_ols_col5 <<- unname(coef(m1)["Tpost"])
      if (!is.null(m3)) res$reform_expenditure_fe_col7 <<- unname(coef(m3)["Tpost"])
    }
  }

  ## ---------------- LIML ----------------
  liml <- function(y, Yend, X1, Z2) {
    keepc <- apply(X1, 2, function(v) max(abs(v)) > 1e-8)
    X1 <- X1[, keepc, drop = FALSE]
    q1 <- qr(X1, tol = 1e-9)
    X1 <- X1[, q1$pivot[seq_len(q1$rank)], drop = FALSE]
    q1 <- qr(X1, tol = 1e-9)
    Z <- cbind(X1, Z2); qz <- qr(Z, tol = 1e-9)
    W <- cbind(y, Yend)
    MzW <- qr.resid(qz, W); Mx1W <- qr.resid(q1, W)
    A <- crossprod(Mx1W); B <- crossprod(MzW)
    k <- min(Re(eigen(solve(B, A), only.values = TRUE)$values))
    X <- cbind(Yend, X1); colnames(X)[1] <- "lnp"
    MzX <- qr.resid(qz, X)
    lhs <- crossprod(X) - k * crossprod(MzX)
    rh  <- crossprod(X, y) - k * crossprod(MzX, y)
    b <- drop(solve(lhs, rh)); names(b) <- colnames(X)
    # first-stage F on excluded instruments (homoskedastic, info only)
    r_r <- qr.resid(q1, Yend); r_u <- qr.resid(qz, Yend)
    Fst <- ((sum(r_r^2) - sum(r_u^2)) / ncol(Z2)) / (sum(r_u^2) / (length(y) - ncol(Z)))
    list(b = b, kappa = k, F = Fst)
  }
  exo_f <- as.formula(paste("~", paste(c(setdiff(rhs_terms, "lnp"), "factor(yr)"), collapse = " + ")))
  X1 <- model.matrix(exo_f, data = df)
  Z2 <- as.matrix(df[, inst, drop = FALSE])
  Yend <- df$lnp
  ## demeaned versions for household FE
  dm <- tryCatch({
    M <- cbind(lnq = df$lnq, lnexp = df$lnexp, lnp = df$lnp, X1[, colnames(X1) != "(Intercept)", drop = FALSE], Z2)
    fixest::demean(M, f = df$hid)
  }, error = function(e) { message("demean fail: ", conditionMessage(e)); NULL })

  for (dv in c("lnq", "lnexp")) {
    r2 <- tryCatch(liml(df[[dv]], Yend, X1, Z2), error = function(e) { message("LIML fail: ", conditionMessage(e)); NULL })
    r4 <- NULL
    if (!is.null(dm)) {
      xc <- setdiff(colnames(X1), "(Intercept)")
      r4 <- tryCatch(liml(dm[, dv], dm[, "lnp"], dm[, xc, drop = FALSE], dm[, inst, drop = FALSE]),
                     error = function(e) { message("FE LIML fail: ", conditionMessage(e)); NULL })
    }
    if (!is.null(r2)) cat(sprintf("\nLIML %s: Tpost=%.5f lnp=%.5f kappa=%.5f firstF=%.2f\n", dv, r2$b["Tpost"], r2$b["lnp"], r2$kappa, r2$F))
    if (!is.null(r4)) cat(sprintf("FE-LIML %s: Tpost=%.5f lnp=%.5f kappa=%.5f firstF=%.2f\n", dv, r4$b["Tpost"], r4$b["lnp"], r4$kappa, r4$F))
    if (dv == "lnq") {
      if (!is.null(r2)) res$reform_consumption_iv_col2 <<- unname(r2$b["Tpost"])
      if (!is.null(r4)) res$reform_consumption_fe_iv_col4 <<- unname(r4$b["Tpost"])
    } else {
      if (!is.null(r2)) res$reform_expenditure_iv_col6 <<- unname(r2$b["Tpost"])
      if (!is.null(r4)) res$reform_expenditure_fe_iv_col8 <<- unname(r4$b["Tpost"])
    }
  }
  invisible(NULL)
}

tryCatch(main(), error = function(e) message("Fatal error: ", conditionMessage(e)))
emit()
