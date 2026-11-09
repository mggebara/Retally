suppressPackageStartupMessages({
  library(haven)
  library(data.table)
  library(fixest)
})
set.seed(42)

base_dir <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free"
dta_path <- file.path(base_dir, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")

# ---------------------------------------------------------------------------
# Discover columns and load only what is needed
# ---------------------------------------------------------------------------
all_names <- names(read_dta(dta_path, n_max = 0))
cat("Number of columns:", length(all_names), "\n")
cat("Columns:", paste(all_names, collapse = ", "), "\n")

pick <- function(cands) {
  for (c in cands) if (c %in% all_names) return(c)
  low <- tolower(all_names)
  for (c in cands) {
    w <- which(low == tolower(c))
    if (length(w)) return(all_names[w[1]])
  }
  NA_character_
}

v <- list(
  id      = pick(c("id")),
  year    = pick(c("year", "ANOENC")),
  month   = pick(c("month")),
  bis     = pick(c("BISEMANA", "BIS")),
  c_ele   = pick(c("c_ele")),
  g_ele   = pick(c("g_ele")),
  c_pap   = pick(c("c_papas")),
  g_pap   = pick(c("g_papas")),
  c_agu   = pick(c("c_aguav")),
  g_agu   = pick(c("g_aguav")),
  c_car   = pick(c("c_car")),
  g_car   = pick(c("g_car")),
  income  = pick(c("IMPEXAC", "impexac", "income", "ingreso", "ingresos", "renta", "INTERIN")),
  totexp  = pick(c("TotExp", "GASTOT", "gh")),
  hhsize  = pick(c("NMIEMB")),
  rooms   = pick(c("NHABIT", "rooms", "habitaciones")),
  surface = pick(c("SUPERF", "surface", "superficie")),
  elderly = pick(c("mayores_count", "elderly", "mayores")),
  educ    = pick(c("ESTUDREDSP", "ESTUDIOSSP", "ESTUDIOS", "NIVESTSP", "educ", "education")),
  nactive = pick(c("NUMACTI", "NACTIVOS", "NUMACTIVOS", "NACTIV", "nactivos", "activos")),
  tenure  = pick(c("REGTEN", "renting", "alquiler")),
  bldage  = pick(c("ANNOCON", "ANOCON", "old_building", "building_age")),
  munsize = pick(c("TAMAMU")),
  urban   = pick(c("urban", "DENSI")),
  capital = pick(c("CAPROV")),
  region  = pick(c("CCAA")),
  T2      = pick(c("T2"))
)
cat("Variable mapping:\n")
for (n in names(v)) cat("  ", n, "->", v[[n]], "\n")

need <- unique(na.omit(unlist(v)))
raw <- read_dta(dta_path, col_select = all_of(need))
raw <- zap_labels(raw)
dt <- as.data.table(raw)
rm(raw); invisible(gc())
setnames(dt, unlist(v[!is.na(unlist(v))]), names(v)[!is.na(unlist(v))])
for (n in names(dt)) dt[[n]] <- suppressWarnings(as.numeric(dt[[n]]))
cat("Rows loaded:", nrow(dt), "\n")

# ---------------------------------------------------------------------------
# Interview date, reform timing
# ---------------------------------------------------------------------------
if (!"month" %in% names(dt) || all(is.na(dt$month))) {
  dt[, month := pmin(12, ceiling(bis / (26 / 12)))]
  cat("DEVIATION: month derived from two-week period\n")
}
dt[, date := year * 12 + month]
R_date   <- 2013 * 12 + 8
win_lo   <- 2011 * 12 + 8
win_hi   <- 2014 * 12 + 4

# Check id is a panel identifier
cnt_full <- dt[, .N, by = id]
cat("id count distribution (full data):\n"); print(table(cnt_full$N))

d <- dt[!is.na(date) & date >= win_lo & date <= win_hi]
cat("Obs in window Aug2011-Apr2014:", nrow(d), "\n")

# Households interviewed twice, in consecutive years, both within the window
d[, n_id := .N, by = id]
d[, yr_span := max(year) - min(year), by = id]
d[, first_date := min(date), by = id]
cat("Per-id obs counts in window:\n"); print(table(d$n_id))
d <- d[n_id == 2 & yr_span == 1 & first_date < R_date]
cat("Panel obs (two interviews in window):", nrow(d), " households:", uniqueN(d$id), "\n")

d[, T := as.numeric(date >= R_date)]
d[, D := as.numeric(max(T) == 1), by = id]
d[, msr := pmax(0, date - R_date)]
d[, quarter := ceiling(month / 3)]
if ("T2" %in% names(d)) { cat("Cross-tab constructed T vs T2:\n"); print(table(d$T, d$T2, useNA = "ifany")) }
cat("Treated households:", uniqueN(d[D == 1]$id), " control:", uniqueN(d[D == 0]$id), "\n")

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
pos_log <- function(x) ifelse(!is.na(x) & x > 0, log(x), NA_real_)
d[, lnq := pos_log(c_ele)]
d[, lne := pos_log(g_ele)]
d[, lnp := pos_log(g_ele / c_ele)]
d[, lp_pap := pos_log(g_pap / c_pap)]
d[, lp_agu := pos_log(g_agu / c_agu)]
d[, lp_car := pos_log(g_car / c_car)]
if ("income" %in% names(d)) {
  d[, lny := pos_log(income)]
} else {
  d[, lny := pos_log(totexp)]
  cat("DEVIATION: no income variable found; log total expenditure used as income proxy\n")
}
d[, lny2 := lny^2]

num_ctrl <- c()
fe_ctrl  <- c("year", "quarter")
if ("hhsize" %in% names(d))  num_ctrl <- c(num_ctrl, "hhsize")
if ("rooms" %in% names(d))   num_ctrl <- c(num_ctrl, "rooms")
if ("surface" %in% names(d)) num_ctrl <- c(num_ctrl, "surface")
if ("elderly" %in% names(d)) { d[, elderly_d := as.numeric(elderly > 0)]; num_ctrl <- c(num_ctrl, "elderly_d") }
if ("nactive" %in% names(d)) { d[, nact3 := pmin(nactive, 2)]; fe_ctrl <- c(fe_ctrl, "nact3") }
for (f in c("educ", "tenure", "bldage", "munsize", "urban", "capital", "region")) {
  if (f %in% names(d)) fe_ctrl <- c(fe_ctrl, f)
}
cat("Numeric controls:", paste(num_ctrl, collapse = ", "), "\n")
cat("Categorical controls (as FE):", paste(fe_ctrl, collapse = ", "), "\n")

core <- c("id", "lnq", "lne", "lnp", "T", "msr", "lny", "lny2",
          "lp_pap", "lp_agu", "lp_car", num_ctrl, fe_ctrl)
est <- d[complete.cases(d[, ..core])]
est <- est[is.finite(lnq) & is.finite(lne) & is.finite(lnp)]
N_obs <- nrow(est)
N_hh  <- uniqueN(est$id)
cat("Estimation sample:", N_obs, " households:", N_hh, "\n")

# ---------------------------------------------------------------------------
# Estimation helpers
# ---------------------------------------------------------------------------
exo <- c("T", "msr", "lny", "lny2", num_ctrl)
insts <- c("lp_pap", "lp_agu", "lp_car")

ols_fit <- function(y, fes) {
  f <- as.formula(paste0(y, " ~ lnp + ", paste(exo, collapse = " + "),
                         " | ", paste(fes, collapse = " + ")))
  feols(f, data = est, cluster = ~id)
}

liml_fit <- function(y, fes) {
  lhs <- c(y, "lnp", insts)
  f <- as.formula(paste0("c(", paste(lhs, collapse = ","), ") ~ ",
                         paste(exo, collapse = " + "), " | ", paste(fes, collapse = " + ")))
  m <- feols(f, data = est)
  Rm <- sapply(seq_along(lhs), function(i) resid(m[[i]]))
  yt <- Rm[, 1]; pt <- Rm[, 2]; Zt <- Rm[, 3:ncol(Rm), drop = FALSE]
  ey <- resid(lm.fit(Zt, yt)); ep <- resid(lm.fit(Zt, pt))
  W  <- cbind(yt, pt); WM <- cbind(ey, ep)
  kap <- min(Re(eigen(solve(crossprod(WM)) %*% crossprod(W))$values))
  beta <- (sum(pt * yt) - kap * sum(ep * ey)) / (sum(pt^2) - kap * sum(ep^2))
  est[, ystar__ := get(y) - beta * lnp]
  f2 <- as.formula(paste0("ystar__ ~ ", paste(exo, collapse = " + "),
                          " | ", paste(fes, collapse = " + ")))
  m2 <- feols(f2, data = est, cluster = ~id)
  list(beta_p = beta, kappa = kap, coefT = unname(coef(m2)["T"]), m2 = m2)
}

fe_pool <- fe_ctrl
fe_hh   <- c("id", fe_ctrl)

res <- list()
spec <- list(
  list(col = 1, y = "lnq", type = "ols",  fes = fe_pool),
  list(col = 2, y = "lnq", type = "liml", fes = fe_pool),
  list(col = 3, y = "lnq", type = "ols",  fes = fe_hh),
  list(col = 4, y = "lnq", type = "liml", fes = fe_hh),
  list(col = 5, y = "lne", type = "ols",  fes = fe_pool),
  list(col = 6, y = "lne", type = "liml", fes = fe_pool),
  list(col = 7, y = "lne", type = "ols",  fes = fe_hh),
  list(col = 8, y = "lne", type = "liml", fes = fe_hh)
)
for (s in spec) {
  if (s$type == "ols") {
    m <- ols_fit(s$y, s$fes)
    se <- sqrt(diag(vcov(m)))
    res[[s$col]] <- list(T = unname(coef(m)["T"]), p = unname(coef(m)["lnp"]),
                         seT = unname(se["T"]), nobs = nobs(m))
    cat(sprintf("Col %d OLS (%s): T=%.4f (se %.4f), lnp=%.4f, N=%d\n", s$col, s$y,
                res[[s$col]]$T, res[[s$col]]$seT, res[[s$col]]$p, nobs(m)))
  } else {
    r <- tryCatch(liml_fit(s$y, s$fes), error = function(e) { cat("LIML error:", conditionMessage(e), "\n"); NULL })
    if (is.null(r)) {
      f <- as.formula(paste0(s$y, " ~ ", paste(exo, collapse = " + "), " | ",
                             paste(s$fes, collapse = " + "), " | lnp ~ ", paste(insts, collapse = " + ")))
      m <- feols(f, data = est, cluster = ~id)
      res[[s$col]] <- list(T = unname(coef(m)["T"]), p = unname(coef(m)["fit_lnp"]))
      cat("DEVIATION: 2SLS used instead of LIML for column", s$col, "\n")
    } else {
      res[[s$col]] <- list(T = r$coefT, p = r$beta_p)
      cat(sprintf("Col %d LIML (%s): T=%.4f, lnp=%.4f, kappa=%.5f\n", s$col, s$y, r$coefT, r$beta_p, r$kappa))
    }
    # 2SLS comparison
    f <- as.formula(paste0(s$y, " ~ ", paste(exo, collapse = " + "), " | ",
                           paste(s$fes, collapse = " + "), " | lnp ~ ", paste(insts, collapse = " + ")))
    m <- tryCatch(feols(f, data = est, cluster = ~id), error = function(e) NULL)
    if (!is.null(m)) cat(sprintf("   (2SLS check: T=%.4f, lnp=%.4f)\n", coef(m)["T"], coef(m)["fit_lnp"]))
  }
}

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", res[[1]]$T))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", res[[2]]$T))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", res[[3]]$T))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", res[[4]]$T))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", res[[5]]$T))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", res[[6]]$T))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", res[[7]]$T))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", res[[8]]$T))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", res[[1]]$p))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", res[[3]]$p))
cat(sprintf("RESULT:n_obs_table2=%d\n", N_obs))
cat(sprintf("RESULT:n_households_table2=%d\n", N_hh))
