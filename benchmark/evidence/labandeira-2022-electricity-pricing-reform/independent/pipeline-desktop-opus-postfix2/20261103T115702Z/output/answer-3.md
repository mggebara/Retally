suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})
set.seed(42)

path <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform.script-free/3 Replication package/analysis data/data_to_run_DOFILE3.dta"
raw <- haven::read_dta(path)
raw <- haven::zap_labels(raw)
df <- as.data.frame(raw)
rm(raw); invisible(gc())
cat(sprintf("SAMPLE:table2:loaded=%d\n", nrow(df)))

nm <- names(df)
pick <- function(cands) {
  for (c in cands) {
    hit <- nm[tolower(nm) == tolower(c)]
    if (length(hit) > 0) return(hit[1])
  }
  NA_character_
}
num <- function(x) suppressWarnings(as.numeric(x))

df$year <- num(df$year)
df$month <- num(df$month)
df$ym <- df$year * 12 + df$month

# ---- Restriction 1: interview window August 2011 - April 2014 ----
lo <- 2011 * 12 + 8
hi <- 2014 * 12 + 4
df <- df[!is.na(df$ym) & df$ym >= lo & df$ym <= hi, ]
cat(sprintf("SAMPLE:table2:interviewed_aug2011_apr2014=%d\n", nrow(df)))

# drop exact duplicate household-year records if any
df <- df[!duplicated(df[, c("id", "year")]), ]
cat(sprintf("SAMPLE:table2:unique_household_year=%d\n", nrow(df)))

reform <- 2013 * 12 + 8
df$post <- as.integer(df$ym >= reform)

# ---- Restriction 2: rotating two-year panel -- households interviewed twice
# (consecutive years) inside the window ----
df <- df %>% group_by(id) %>%
  mutate(first_ym = min(ym), n_int = n(), yspan = max(year) - min(year)) %>%
  ungroup() %>% as.data.frame()
df <- df[df$n_int == 2 & df$yspan == 1, ]
cat(sprintf("SAMPLE:table2:panel_two_interviews=%d\n", nrow(df)))

# ---- Restriction 3: groups defined by interview dates (first interview pre-reform) ----
df <- df[df$first_ym < reform, ]
cat(sprintf("SAMPLE:table2:first_interview_pre_reform=%d\n", nrow(df)))
df <- df %>% group_by(id) %>%
  mutate(D = as.integer(max(post) == 1)) %>% ungroup() %>% as.data.frame()

# Treatment and months since reform
df$T <- as.integer(df$post == 1)
df$months_since_reform <- ifelse(df$post == 1, df$ym - reform, 0)
df$quarter <- ceiling(df$month / 3)

# ---- Variables ----
ele_q <- pick(c("c_ele", "c_ele2"))
ele_g <- pick(c("g_ele", "g_ele2"))
df$q_ele <- num(df[[ele_q]])
df$e_ele <- num(df[[ele_g]])
df$p_ele <- df$e_ele / df$q_ele
pos_log <- function(x) ifelse(!is.na(x) & is.finite(x) & x > 0, log(x), NA_real_)
df$lq <- pos_log(df$q_ele)
df$le <- pos_log(df$e_ele)
df$lp <- pos_log(df$p_ele)

# Instruments: household effective prices of potatoes, water, fuel.
# Effective prices exist only for purchasing households; as in the paper's
# estimation (Stata drops observations with missing instruments), households
# without an effective price are not in the estimation sample (no imputation).
df$lp_pap <- pos_log(num(df$g_papas) / num(df$c_papas))
df$lp_agu <- pos_log(num(df$g_aguav) / num(df$c_aguav))
df$lp_car <- pos_log(num(df$g_car) / num(df$c_car))
for (v in c("lp_pap", "lp_agu", "lp_car")) {
  cat(sprintf("NOTE: %s missing (non-purchasers) = %d\n", v, sum(is.na(df[[v]]))))
}

if (!"CCAA" %in% names(df)) df$CCAA <- 1
df$CCAA <- num(df$CCAA)

# Income
inc_var <- pick(c("IMPEXAC", "INGRESOS", "income", "ingreso", "renta", "IMPEXACPC", "TotExp", "GH"))
cat(sprintf("NOTE: income variable used = %s\n", inc_var))
df$linc <- pos_log(num(df[[inc_var]]))
df$linc2 <- df$linc^2

# Controls (use those present)
ctrl_num_c <- list(
  hsize = c("NMIEMB", "TAMAÑO"),
  rooms = c("NHABIT", "NUMHABIT", "rooms"),
  surface = c("SUPERF", "superficie", "surface"),
  elderly = c("mayores_count")
)
ctrl_fac_c <- list(
  educ = c("ESTUDIOSSP", "ESTUDIOS", "ESTUDRED", "educ"),
  active = c("NUMACTI"),
  tenure = c("REGTEN", "TENENCIA"),
  oldbld = c("ANNOCON", "ANOCON"),
  munsize = c("TAMAMU"),
  urban = c("urban", "ZONARES"),
  capital = c("CAPROV"),
  region = c("CCAA")
)
ctrl_terms <- c()
for (k in names(ctrl_num_c)) {
  v <- pick(ctrl_num_c[[k]])
  if (!is.na(v)) {
    x <- num(df[[v]])
    if (k == "elderly") x <- as.integer(x > 0)
    df[[paste0("c_", k)]] <- x
    ctrl_terms <- c(ctrl_terms, paste0("c_", k))
  } else cat(sprintf("DEVIATION: control %s not found in data\n", k))
}
for (k in names(ctrl_fac_c)) {
  v <- pick(ctrl_fac_c[[k]])
  if (!is.na(v)) {
    x <- num(df[[v]])
    if (k == "active") x <- pmin(x, 2)
    if (k == "tenure") x <- as.integer(x %in% c(2))  # renting
    if (k == "oldbld") x <- as.integer(x %in% c(1, 2, 3))  # older constructions
    df[[paste0("f_", k)]] <- x
    ctrl_terms <- c(ctrl_terms, if (k %in% c("tenure", "oldbld", "urban")) paste0("f_", k) else paste0("factor(f_", k, ")"))
  } else cat(sprintf("DEVIATION: control %s not found in data\n", k))
}

base_vars <- c("lq", "le", "lp", "linc", "linc2", "T", "months_since_reform",
               "lp_pap", "lp_agu", "lp_car", "year", "quarter", "CCAA", "id",
               gsub("^factor\\((.*)\\)$", "\\1", ctrl_terms))
cc <- complete.cases(df[, intersect(base_vars, names(df))])
est <- df[cc, ]
cat(sprintf("SAMPLE:table2:complete_regression_variables=%d\n", nrow(est)))
cat(sprintf("SAMPLE:table2:households=%d\n", length(unique(est$id))))
if (nrow(est) != 20872) cat(sprintf("DEVIATION: Table 2 sample is %d, paper reports 20872\n", nrow(est)))
est$cq <- paste(est$CCAA, est$quarter, sep = "_")

rhs_ctrl <- paste(ctrl_terms, collapse = " + ")
exo <- paste(c("linc", "linc2", "T", "months_since_reform", rhs_ctrl), collapse = " + ")
exo_fe <- paste(c("linc", "linc2", "T", "months_since_reform",
                  setdiff(ctrl_terms, c("factor(f_region)"))), collapse = " + ")

fit <- function(dep, fe = FALSE, price = TRUE) {
  fes <- if (fe) "id + year + CCAA^quarter" else "year + CCAA^quarter"
  rhs <- if (fe) exo_fe else exo
  if (!price) {
    f <- as.formula(sprintf("%s ~ %s | %s", dep, rhs, fes))
  } else {
    f <- as.formula(sprintf("%s ~ lp + %s | %s", dep, rhs, fes))
  }
  feols(f, data = est, cluster = ~id, warn = FALSE, notes = FALSE, fixef.rm = "none")
}

# LIML (k-class) with fixed effects partialled out and household-clustered SEs
liml <- function(dep, fe = FALSE) {
  fes <- if (fe) c("id", "year", "cq") else c("year", "cq")
  rhs <- if (fe) exo_fe else exo
  W <- model.matrix(as.formula(paste("~", rhs)), data = est)[, -1, drop = FALSE]
  Zx <- as.matrix(est[, c("lp_pap", "lp_agu", "lp_car")])
  allv <- cbind(est[[dep]], est$lp, W, Zx)
  dm <- fixest::demean(X = allv, f = est[, fes, drop = FALSE])
  dm <- as.matrix(dm)
  kW <- ncol(W)
  y <- dm[, 1]
  lp <- dm[, 2]
  Wd <- dm[, 3:(2 + kW), drop = FALSE]
  Zd <- dm[, (3 + kW):(5 + kW), drop = FALSE]
  qW <- qr(Wd, tol = 1e-7)
  keep <- sort(qW$pivot[seq_len(qW$rank)])
  Wd <- Wd[, keep, drop = FALSE]
  wn <- colnames(W)[keep]
  X <- cbind(lp, Wd); colnames(X) <- c("lp", wn)
  Zf <- cbind(Wd, Zd)
  qWk <- qr(Wd); qZ <- qr(Zf)
  Yt <- cbind(y, lp)
  A <- crossprod(qr.resid(qWk, Yt))
  B <- crossprod(qr.resid(qZ, Yt))
  kappa <- min(Re(eigen(solve(B, A))$values))
  MX <- qr.resid(qZ, X)
  Xh <- X - kappa * MX
  XhX <- crossprod(Xh, X)
  bread <- solve(XhX)
  b <- drop(bread %*% crossprod(Xh, y))
  e <- drop(y - X %*% b)
  S <- rowsum(Xh * e, est$id)
  G <- nrow(S); N <- length(y); K <- ncol(X)
  adj <- (G / (G - 1)) * ((N - 1) / (N - K))
  V <- bread %*% crossprod(S) %*% t(bread) * adj
  names(b) <- colnames(X)
  se <- sqrt(diag(V)); names(se) <- colnames(X)
  cat(sprintf("NOTE: LIML kappa (%s, fe=%s) = %.6f\n", dep, fe, kappa))
  list(coef = b, se = se, n = N)
}

m1 <- fit("lq"); m3 <- fit("lq", fe = TRUE)
m2 <- liml("lq"); m4 <- liml("lq", fe = TRUE)
# With ln(expenditure) = ln(p) + ln(q), including ln(p) as a regressor makes the
# reform coefficient identical to the consumption model; the paper's expenditure
# coefficients differ, so the expenditure models omit ln(price).
cat("DEVIATION: expenditure models (cols 5-8) omit ln(price), which otherwise makes the T coefficient mechanically identical to cols 1-4; IV/FE-IV expenditure columns therefore coincide with OLS/FE\n")
m5 <- fit("le", price = FALSE); m6 <- fit("le", price = FALSE)
m7 <- fit("le", fe = TRUE, price = FALSE); m8 <- fit("le", fe = TRUE, price = FALSE)

cat(sprintf("SAMPLE:table2:estimation=%d\n", nobs(m1)))
cat(sprintf("SAMPLE:table2_fe:estimation=%d\n", nobs(m3)))

gc_ <- function(m, v) {
  cf <- if (is.list(m) && !is.null(m$coef) && !inherits(m, "fixest")) m$coef else coef(m)
  n <- names(cf)
  hit <- n[n == v | n == paste0("fit_", v)]
  if (length(hit) == 0) return(NA_real_)
  unname(cf[hit[1]])
}
gse <- function(m, v) {
  s <- if (is.list(m) && !is.null(m$se) && !inherits(m, "fixest")) m$se else sqrt(diag(vcov(m)))
  n <- names(s)
  hit <- n[n == v | n == paste0("fit_", v)]
  if (length(hit) == 0) return(NA_real_)
  unname(s[hit[1]])
}

nhh <- length(unique(est$id[obs(m1)]))

cat(sprintf("RESULT:reform_consumption_ols_col1=%.6f\n", gc_(m1, "T")))
cat(sprintf("RESULT:reform_consumption_ols_col1_se=%.6f\n", gse(m1, "T")))
cat(sprintf("RESULT:reform_consumption_iv_col2=%.6f\n", gc_(m2, "T")))
cat(sprintf("RESULT:reform_consumption_iv_col2_se=%.6f\n", gse(m2, "T")))
cat(sprintf("RESULT:reform_consumption_fe_col3=%.6f\n", gc_(m3, "T")))
cat(sprintf("RESULT:reform_consumption_fe_col3_se=%.6f\n", gse(m3, "T")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4=%.6f\n", gc_(m4, "T")))
cat(sprintf("RESULT:reform_consumption_fe_iv_col4_se=%.6f\n", gse(m4, "T")))
cat(sprintf("RESULT:reform_expenditure_ols_col5=%.6f\n", gc_(m5, "T")))
cat(sprintf("RESULT:reform_expenditure_iv_col6=%.6f\n", gc_(m6, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_col7=%.6f\n", gc_(m7, "T")))
cat(sprintf("RESULT:reform_expenditure_fe_iv_col8=%.6f\n", gc_(m8, "T")))
cat(sprintf("RESULT:price_elasticity_consumption_ols_col1=%.6f\n", gc_(m1, "lp")))
cat(sprintf("RESULT:price_elasticity_consumption_fe_col3=%.6f\n", gc_(m3, "lp")))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:n_households_table2=%d\n", nhh))
