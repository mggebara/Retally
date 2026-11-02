suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(data.table)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
f <- file.path(base, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")

nm <- tryCatch(names(read_dta(f, n_max = 0)), error = function(e) NULL)
if (is.null(nm) || length(nm) == 0) {
  full <- read_dta(f)
  nm <- names(full)
} else full <- NULL

pick <- function(cands) {
  for (c in cands) {
    if (c %in% nm) return(c)
    i <- which(tolower(nm) == tolower(c))
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}
pick_re <- function(pats, exclude = character(0)) {
  for (p in pats) {
    i <- grep(p, nm, ignore.case = TRUE)
    i <- i[!(nm[i] %in% exclude)]
    if (length(i)) return(nm[i[1]])
  }
  NA_character_
}

v <- list(
  id = pick(c("id", "NUMERO", "IDHOGAR")),
  year = pick(c("year", "ANOENC", "ANOENC")),
  month = pick(c("month", "mes")),
  bis = pick(c("BIS", "BISEMANA")),
  T2 = pick(c("T2")),
  q = pick(c("c_ele")),
  e = pick(c("g_ele")),
  q2 = pick(c("c_ele2")),
  e2 = pick(c("g_ele2")),
  cpap = pick(c("c_papas")), gpap = pick(c("g_papas")),
  cagu = pick(c("c_aguav")), gagu = pick(c("g_aguav")),
  ccar = pick(c("c_car")), gcar = pick(c("g_car")),
  inc = pick(c("IMPEXAC", "income", "ingreso", "ingresos", "renta", "inc", "IMPEXACPC")),
  totexp = pick(c("TotExp", "GASTOT", "GH")),
  size = pick(c("NMIEMB")),
  rooms = pick(c("NHABIT", "rooms", "habitaciones")),
  surf = pick(c("SUPERF", "surface", "superficie")),
  eld = pick(c("mayores_count", "mayores")),
  educ = pick(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDIOS", "educ", "education")),
  act = pick(c("NUMACTI", "NACTIVOS", "NUMACT", "activos", "NACTI")),
  tenure = pick(c("REGTEN", "tenure", "renting", "alquiler")),
  bage = pick(c("ANNOCON", "ANOCON", "building_age")),
  muni = pick(c("TAMAMU")),
  urban = pick(c("urban", "ZONARES")),
  cap = pick(c("CAPROV")),
  reg = pick(c("CCAA"))
)
if (is.na(v$educ)) v$educ <- pick_re(c("^ESTUD"))
if (is.na(v$act)) v$act <- pick_re(c("^NUMACT", "ACTIV"))
# look for a precomputed electricity price variable (paper's price regressor)
v$pv <- pick(c("p_ele", "pele", "precio_ele", "p_elec", "lp_ele", "lnp_ele", "lnpele", "lp_elec",
               "price_ele", "pr_ele", "p_kwh", "precio_kwh", "precio", "price", "lnprice", "lnp"))
if (is.na(v$pv)) v$pv <- pick_re(c("^ln?_?p_?ele", "^p_?ele", "precio_?ele", "price_?ele"),
                                 exclude = unlist(v[!is.na(unlist(v))]))
cat("Variable mapping:\n"); print(unlist(v))

keep <- unique(na.omit(unlist(v)))
if (is.null(full)) {
  raw <- read_dta(f, col_select = tidyselect::all_of(keep))
} else {
  raw <- full[, keep]
  rm(full)
}
raw <- zap_labels(raw)
d <- as.data.table(raw)
rm(raw); invisible(gc())

# standardise names
D <- data.table(id = as.character(d[[v$id]]))
for (k in setdiff(names(v), "id")) {
  if (!is.na(v[[k]])) set(D, j = k, value = suppressWarnings(as.numeric(d[[v[[k]]]])))
}
rm(d); invisible(gc())
D <- copy(D)

if (is.null(D$month) || all(is.na(D$month)) || max(D$month, na.rm = TRUE) > 12) {
  D[, month := pmin(12, floor((bis - 1) * 14 / 30.44) + 1)]
}
D[, ym := year * 12 + month]
cat("Rows in data:", nrow(D), "\n")

# ---- Sample window: Aug 2011 - Apr 2014 ----
D <- D[!is.na(ym) & ym >= 2011 * 12 + 8 & ym <= 2014 * 12 + 4]
cat("Rows in window:", nrow(D), "\n")

# ---- Panel: households interviewed twice, consecutive years, both in window ----
D[, nid := .N, by = id]
D[, yrspan := max(year) - min(year), by = id]
share2 <- mean(D$nid == 2)
cat("Share of window rows with 2 interviews per id:", share2, "\n")
if (share2 > 0.3) {
  D <- D[nid == 2 & yrspan == 1]
}
cat("Panel rows:", nrow(D), " households:", uniqueN(D$id), "\n")

# ---- Treatment ----
R_ym <- 2013 * 12 + 8
D[, T_aug := as.integer(ym >= R_ym)]
D[, T_sep := as.integer(ym >= R_ym + 1)]
useT2 <- FALSE
if (!is.null(D$T2)) {
  t2 <- D$T2
  cat("T2 mean:", mean(t2, na.rm = TRUE), " NA share:", mean(is.na(t2)), "\n")
  if (all(na.omit(t2) %in% c(0, 1)) && mean(is.na(t2)) < 0.05) {
    a1 <- mean(t2 == D$T_aug, na.rm = TRUE); a2 <- mean(t2 == D$T_sep, na.rm = TRUE)
    cat("T2 agreement with Aug onset:", a1, " Sep onset:", a2, "\n")
    if (max(a1, a2) >= 0.9) useT2 <- TRUE
  }
}
D[, Tr := if (useT2) T2 else T_sep]
cat("Using T2:", useT2, " mean T:", mean(D$Tr, na.rm = TRUE), "\n")
D[, msr := pmax(0, ym - R_ym) * Tr]
D[, quarter := ceiling(month / 3)]

# ---- Outcomes and price ----
pos <- function(x) !is.na(x) & x > 0
D[, lq := ifelse(pos(q), log(q), NA_real_)]
D[, le := ifelse(pos(e), log(e), NA_real_)]
D[, lp := ifelse(pos(q) & pos(e), log(e / q), NA_real_)]

# If a separate (precomputed) price variable exists, use it: with lp = le - lq
# exactly, the expenditure and consumption equations give identical T coefficients,
# whereas the paper reports different ones.
sep_price <- FALSE
if (!is.null(D$pv) && sum(!is.na(D$pv)) > 0.5 * nrow(D)) {
  pvv <- D$pv
  cand <- if (median(pvv, na.rm = TRUE) < 0) pvv else ifelse(pvv > 0, log(pvv), NA_real_)
  cc <- suppressWarnings(cor(cand, D$lp, use = "complete.obs"))
  cat("Candidate price var", v$pv, " corr with ln(e/q):", cc, "\n")
  if (is.finite(cc) && cc > 0.3 && cc < 0.9999) {
    D[, lp := cand]
    sep_price <- TRUE
    cat("DEVIATION: Using precomputed price variable", v$pv, "as ln(price) regressor\n")
  }
}

# ---- Instruments: effective unit prices ----
D[, z_pap := ifelse(pos(gpap) & pos(cpap), log(gpap / cpap), NA_real_)]
D[, z_agu := ifelse(pos(gagu) & pos(cagu), log(gagu / cagu), NA_real_)]
D[, z_car := ifelse(pos(gcar) & pos(ccar), log(gcar / ccar), NA_real_)]
cat("Instrument availability: pap", mean(!is.na(D$z_pap)), " agu", mean(!is.na(D$z_agu)),
    " car", mean(!is.na(D$z_car)), "\n")

# ---- Income ----
incvar <- if (!is.null(D$inc)) "inc" else "totexp"
D[, lninc := ifelse(pos(get(incvar)), log(get(incvar)), NA_real_)]
D[, lninc2 := lninc^2]

# ---- Controls ----
if (!is.null(D$eld)) D[, elderly := as.integer(eld > 0)]
if (!is.null(D$act)) D[, act3 := pmin(act, 2)]
ctrl_cands <- list(
  size = "size", rooms = "rooms", surf = "surf", elderly = "factor(elderly)",
  educ = "factor(educ)", act3 = "factor(act3)", tenure = "factor(tenure)",
  bage = "factor(bage)", muni = "factor(muni)", urban = "factor(urban)",
  cap = "factor(cap)", reg = "factor(reg)"
)
core <- c("lq", "le", "lp", "Tr", "msr", "lninc", "quarter", "year", "id")
base_ok <- complete.cases(D[, ..core])
cat("Rows with core vars:", sum(base_ok), "\n")
ctrl_terms <- character(0); ctrl_vars <- character(0)
for (k in names(ctrl_cands)) {
  if (!is.null(D[[k]])) {
    miss <- mean(is.na(D[[k]][base_ok]))
    if (miss < 0.05 && length(unique(na.omit(D[[k]][base_ok]))) > 1) {
      ctrl_terms <- c(ctrl_terms, ctrl_cands[[k]]); ctrl_vars <- c(ctrl_vars, k)
    } else cat("Dropping control", k, "missing share", miss, "\n")
  }
}
cat("Controls:", paste(ctrl_terms, collapse = ", "), "\n")

# ---- Instrument availability: paper builds instrument prices only for buyers ----
# (no imputation; common estimation sample for all Table 2 columns)
zs <- c("z_pap", "z_agu", "z_car")
ok_noz <- base_ok & complete.cases(D[, ..ctrl_vars])
ok_z <- ok_noz & complete.cases(D[, ..zs])
cat("Rows complete without instruments:", sum(ok_noz), " with instruments:", sum(ok_z), "\n")
S <- as.data.frame(D[ok_z])
cat("Estimation sample:", nrow(S), " households:", length(unique(S$id)), "\n")

wterms <- c("Tr", "msr", "lninc", "lninc2", ctrl_terms, "factor(quarter)")
rhs <- paste(wterms, collapse = " + ")

ols <- function(y, fe, with_p = TRUE) {
  pterm <- if (with_p) "lp + " else ""
  feols(as.formula(paste0(y, " ~ ", pterm, rhs, " | ", fe)), data = S, cluster = ~id)
}

liml <- function(y, x, fe) {
  res1 <- function(var) {
    m <- feols(as.formula(paste0(var, " ~ ", rhs, " | ", fe)), data = S, notes = FALSE, warn = FALSE)
    resid(m, na.rm = FALSE)
  }
  yt <- res1(y); xt <- res1(x)
  Zt <- sapply(zs, res1)
  okr <- complete.cases(cbind(yt, xt, Zt))
  yt <- yt[okr]; xt <- xt[okr]; Zt <- as.matrix(Zt)[okr, , drop = FALSE]
  Mz <- function(u) lm.fit(Zt, u)$residuals
  Y <- cbind(yt, xt); MY <- apply(Y, 2, Mz)
  A <- crossprod(Y); B <- crossprod(MY)
  kappa <- min(Re(eigen(solve(B, A))$values))
  beta <- (sum(xt * yt) - kappa * sum(MY[, 2] * yt)) / (sum(xt * xt) - kappa * sum(MY[, 2] * xt))
  fs_r <- lm.fit(Zt, xt)
  rss1 <- sum(fs_r$residuals^2); rss0 <- sum(xt^2)
  Fst <- ((rss0 - rss1) / ncol(Zt)) / (rss1 / (length(xt) - ncol(Zt)))
  S2 <- S
  S2$yadj__ <- S2[[y]] - beta * S2[[x]]
  m2 <- feols(as.formula(paste0("yadj__ ~ ", rhs, " | ", fe)), data = S2, cluster = ~id)
  list(beta = beta, kappa = kappa, delta = unname(coef(m2)["Tr"]), F = Fst)
}

fe_cs <- "year"
fe_hh <- "id + year"

m1 <- ols("lq", fe_cs)
m3 <- ols("lq", fe_hh)
if (sep_price) {
  m5 <- ols("le", fe_cs)
  m7 <- ols("le", fe_hh)
} else {
  cat("DEVIATION: Expenditure OLS/LSDV columns estimated without ln(price) because ln(price)=ln(exp)-ln(kWh) makes the T coefficient mechanically identical to the consumption equation\n")
  m5 <- ols("le", fe_cs, with_p = FALSE)
  m7 <- ols("le", fe_hh, with_p = FALSE)
}
r2 <- liml("lq", "lp", fe_cs)
r4 <- liml("lq", "lp", fe_hh)
r6 <- liml("le", "lp", fe_cs)
r8 <- liml("le", "lp", fe_hh)

cat("OLS col1:\n"); print(coeftable(m1)[c("lp", "Tr", "msr"), ])
cat("FE col3:\n"); print(coeftable(m3)[c("lp", "Tr", "msr"), ])
cat("OLS col5 Tr:", unname(coef(m5)["Tr"]), " FE col7 Tr:", unname(coef(m7)["Tr"]), "\n")
cat("LIML col2 beta:", r2$beta, " kappa:", r2$kappa, " F:", r2$F, "\n")
cat("LIML col4 beta:", r4$beta, " kappa:", r4$kappa, " F:", r4$F, "\n")
cat("LIML col6 beta:", r6$beta, " col8 beta:", r8$beta, "\n")

getc <- function(m, k) unname(coef(m)[k])
n_obs <- nobs(m3)
n_hh <- length(unique(S$id[obs(m3)]))

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", getc(m1, "Tr")))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", r2$delta))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", getc(m3, "Tr")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", r4$delta))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", getc(m5, "Tr")))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", r6$delta))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", getc(m7, "Tr")))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", r8$delta))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", getc(m1, "lp")))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", getc(m3, "lp")))
cat(sprintf("RESULT:n_obs_table2=%d\n", as.integer(n_obs)))
cat(sprintf("RESULT:n_households_table2=%d\n", as.integer(n_hh)))
