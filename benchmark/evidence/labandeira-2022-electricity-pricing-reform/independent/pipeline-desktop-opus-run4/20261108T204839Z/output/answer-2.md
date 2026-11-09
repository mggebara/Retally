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

want <- c(id = "id", year = "year", month = "month", bis = "BISEMANA", T2 = "T2", Tm = "Tm",
          c_ele = "c_ele", g_ele = "g_ele",
          lnc_ele_r = "lnc_ele", lng_ele_r = "lng_ele", lnp_kwh_r = "lnp_kwh",
          lny_r = "lny", lny2_r = "lny2",
          pre_pap = "lnPRE_papas", pre_agu = "lnPRE_aguav", pre_car = "lnPRE_gascar",
          hp_pap = "lnp_papas", hp_agu = "lnp_aguav", hp_car = "lnp_gascar",
          income = "IMPEXAC", hhsize = "NMIEMB", rooms = "NHABIT", surface = "SUPERF",
          mayores = "mayores", mayores_count = "mayores_count",
          alqui = "alqui", tenure = "REGTEN", edif25 = "edif25", bldage = "ANNOCON",
          urban = "urban", capital = "CAPROV", region = "CCAA", munsize = "TAMAMU",
          nactive = "NUMACTI", educ = "ESTUDREDSP", trim = "trim",
          iestud1 = "iestud1", iestud2 = "iestud2", iestud3 = "iestud3", iestud4 = "iestud4",
          isitu1 = "isitu1", isitu2 = "isitu2", isitu3 = "isitu3",
          itam1 = "itam1", itam2 = "itam2", itam3 = "itam3", itam4 = "itam4", itam5 = "itam5")
present <- want[want %in% all_names]
cat("Variable mapping:\n")
for (n in names(present)) cat("  ", n, "->", present[[n]], "\n")
cat("Missing from data:", paste(want[!want %in% all_names], collapse = ", "), "\n")

raw <- read_dta(dta_path, col_select = all_of(unname(present)))
raw <- zap_labels(raw)
dt <- as.data.table(raw)
rm(raw); invisible(gc())
setnames(dt, unname(present), names(present))
for (n in names(dt)) set(dt, j = n, value = suppressWarnings(as.numeric(dt[[n]])))
cat("Rows loaded:", nrow(dt), "\n")
has <- function(x) x %in% names(dt)

# ---------------------------------------------------------------------------
# Interview date, reform timing, sample
# ---------------------------------------------------------------------------
if (!has("month") || all(is.na(dt$month))) {
  dt[, month := pmin(12, ceiling(bis / (26 / 12)))]
  cat("DEVIATION: month derived from two-week period\n")
}
dt[, date := year * 12 + month]
R_date   <- 2013 * 12 + 8
win_lo   <- 2011 * 12 + 8
win_hi   <- 2014 * 12 + 4

if (has("T2")) cat("Non-missing T2 in full data:", sum(!is.na(dt$T2)), "\n")

d <- dt[!is.na(date) & date >= win_lo & date <= win_hi]
cat("Obs in window Aug2011-Apr2014:", nrow(d), "\n")
d[, n_id := .N, by = id]
d[, yr_span := max(year) - min(year), by = id]
d[, first_date := min(date), by = id]
d <- d[n_id == 2 & yr_span == 1 & first_date < R_date]
cat("Two-interview panel obs:", nrow(d), "\n")

# Treatment: use the authors' T2 indicator (counts from the first reformed bill);
# rows with T2 missing are outside the paper's panel (25,775 obs)
if (has("T2")) {
  d <- d[!is.na(T2)]
  d[, T := T2]
} else {
  d[, T := as.numeric(date >= R_date + 1)]
}
cat("Panel obs (paper: 25,775):", nrow(d), " households:", uniqueN(d$id), "\n")
d[, D := as.numeric(max(T) == 1), by = id]
d[, msr := pmax(0, date - R_date) * T]
if (has("Tm")) { cat("Tm summary:\n"); print(summary(d$Tm)); cat("cor(msr, Tm):", suppressWarnings(cor(d$msr, d$Tm, use = "complete.obs")), "\n") }
cat("Treated households:", uniqueN(d[D == 1]$id), " control:", uniqueN(d[D == 0]$id), "\n")

# ---------------------------------------------------------------------------
# Variables (use the authors' precomputed constructs where available)
# ---------------------------------------------------------------------------
pos_log <- function(x) ifelse(!is.na(x) & x > 0, log(x), NA_real_)
if (has("lnc_ele_r")) d[, lnq := lnc_ele_r] else d[, lnq := pos_log(c_ele)]
if (has("lng_ele_r")) d[, lne := lng_ele_r] else d[, lne := pos_log(g_ele)]
if (has("lnp_kwh_r")) d[, lnp := lnp_kwh_r] else d[, lnp := pos_log(g_ele / c_ele)]
cat("Check lne - lnq - lnp:\n"); print(summary(d$lne - d$lnq - d$lnp))

if (has("lny_r")) d[, lny := lny_r] else if (has("income")) d[, lny := pos_log(income)] else stop("no income")
d[, lny2 := lny^2]

if (all(c("pre_pap", "pre_agu", "pre_car") %in% names(d))) {
  d[, `:=`(lp_pap = pre_pap, lp_agu = pre_agu, lp_car = pre_car)]
  cat("Instruments: lnPRE_papas, lnPRE_aguav, lnPRE_gascar\n")
} else {
  d[, `:=`(lp_pap = hp_pap, lp_agu = hp_agu, lp_car = hp_car)]
  cat("Instruments: lnp_papas, lnp_aguav, lnp_gascar\n")
}
cat("Instrument coverage:", sum(!is.na(d$lp_pap)), sum(!is.na(d$lp_agu)), sum(!is.na(d$lp_car)), "\n")

dummy_factor <- function(pref, k) {
  cols <- paste0(pref, seq_len(k))
  if (!all(cols %in% names(d))) return(NULL)
  m <- as.matrix(d[, ..cols])
  as.vector(m %*% seq_len(k))
}

num_ctrl <- c()
fe_ctrl  <- c("year", "quarter")
if (has("trim")) d[, quarter := trim] else d[, quarter := ceiling(month / 3)]
if (has("hhsize"))  num_ctrl <- c(num_ctrl, "hhsize")
if (has("rooms"))   num_ctrl <- c(num_ctrl, "rooms")
if (has("surface")) num_ctrl <- c(num_ctrl, "surface")
if (has("mayores")) { d[, elderly_d := as.numeric(mayores > 0)]; num_ctrl <- c(num_ctrl, "elderly_d")
} else if (has("mayores_count")) { d[, elderly_d := as.numeric(mayores_count > 0)]; num_ctrl <- c(num_ctrl, "elderly_d") }
if (has("alqui")) num_ctrl <- c(num_ctrl, "alqui") else if (has("tenure")) fe_ctrl <- c(fe_ctrl, "tenure")
if (has("edif25")) num_ctrl <- c(num_ctrl, "edif25") else if (has("bldage")) fe_ctrl <- c(fe_ctrl, "bldage")
if (has("urban")) num_ctrl <- c(num_ctrl, "urban")
f_ed <- dummy_factor("iestud", 4)
if (!is.null(f_ed)) { d[, educ_f := f_ed]; fe_ctrl <- c(fe_ctrl, "educ_f") } else if (has("educ")) fe_ctrl <- c(fe_ctrl, "educ")
f_si <- dummy_factor("isitu", 3)
if (!is.null(f_si)) { d[, situ_f := f_si]; fe_ctrl <- c(fe_ctrl, "situ_f") } else if (has("nactive")) { d[, situ_f := pmin(nactive, 2)]; fe_ctrl <- c(fe_ctrl, "situ_f") }
f_tm <- dummy_factor("itam", 5)
if (!is.null(f_tm)) { d[, tam_f := f_tm]; fe_ctrl <- c(fe_ctrl, "tam_f") } else if (has("munsize")) fe_ctrl <- c(fe_ctrl, "munsize")
if (has("capital")) fe_ctrl <- c(fe_ctrl, "capital")
if (has("region"))  fe_ctrl <- c(fe_ctrl, "region")
cat("Numeric controls:", paste(num_ctrl, collapse = ", "), "\n")
cat("Categorical controls (as FE):", paste(fe_ctrl, collapse = ", "), "\n")

core <- c("id", "lnq", "lne", "lnp", "T", "msr", "lny", "lny2",
          "lp_pap", "lp_agu", "lp_car", num_ctrl, fe_ctrl)
for (cc in core) cat(sprintf("  NA in %s: %d\n", cc, sum(is.na(d[[cc]]))))
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
