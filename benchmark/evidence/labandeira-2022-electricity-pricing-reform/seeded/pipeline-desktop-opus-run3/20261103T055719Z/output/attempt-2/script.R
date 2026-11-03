suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

base <- "<repo>/.cache/datasets/labandeira_2022_electricity_pricing_reform"
f_dta <- file.path(base, "3 Replication package/analysis data/data_to_run_DOFILE3.dta")

want <- c("id", "year", "time", "month", "BIS", "BISEMANA", "trim", "dup", "T2",
          "lnc_ele", "lng_ele", "c_ele", "g_ele", "TT202", "lnPRE", "lny", "dist",
          "TAMAMU", "CCAA", "CAPROV", "NMIEMB", "NHABIT", "SUPERF", "ESTUDRED",
          "SITUACTHOG_j", "mayores", "alqui", "urban", "edif25",
          "lnPRE_papas_", "lnPRE_aguav_", "lnPRE_gascar_")

# match wanted names case-insensitively against what is in the file
all_names <- names(haven::read_dta(f_dta, n_max = 0))
file_sel <- character(0); new_names <- character(0)
for (w in want) {
  hit <- all_names[tolower(all_names) == tolower(w)]
  if (length(hit) > 0) { file_sel <- c(file_sel, hit[1]); new_names <- c(new_names, w) }
}
df <- haven::read_dta(f_dta, col_select = tidyselect::all_of(file_sel))
df <- haven::zap_labels(df)
df <- as.data.frame(df)
names(df) <- new_names[match(names(df), file_sel)]
for (v in names(df)) df[[v]] <- as.numeric(df[[v]])

# ---- fallbacks for variables possibly absent ----
if (!"lnc_ele" %in% names(df)) df$lnc_ele <- log(df$c_ele)
if (!"lng_ele" %in% names(df)) df$lng_ele <- log(df$g_ele)
if (!"trim" %in% names(df)) {
  df$trim <- ifelse(df$month < 4, 1, ifelse(df$month < 7, 2, ifelse(df$month < 10, 3, 4)))
}
if (!"TT202" %in% names(df)) {
  df$TT202 <- ifelse(df$year > 2010 & df$time < 215, 0, NA)
  df$TT202[which(df$time > 202 & df$dup == 2 & df$time < 215)] <- 1
  df$TT202[which(df$time > 202 & df$dup == 1 & df$time < 215)] <- NA
}

# drop variables that are absent or entirely missing
usable <- function(v) v %in% names(df) && any(!is.na(df[[v]]))
for (v in names(df)) if (!any(!is.na(df[[v]]))) df[[v]] <- NULL

# ---- dummies as Stata's -tabulate, generate()- on the full data ----
mkidx <- function(x) match(x, sort(unique(x[!is.na(x)])))
mkdum <- function(var, prefix) {
  if (!usable(var)) return(invisible(NULL))
  idx <- mkidx(df[[var]])
  for (k in seq_len(max(idx, na.rm = TRUE))) df[[paste0(prefix, k)]] <<- as.numeric(idx == k)
}
mkdum("year", "iyear"); mkdum("TAMAMU", "itam"); mkdum("CCAA", "iccaa")
mkdum("ESTUDRED", "iestud"); mkdum("SITUACTHOG_j", "isitu")
yrs <- sort(unique(df$year[!is.na(df$year)]))
getiyear <- function(y) paste0("iyear", match(y, yrs))
iy_names <- c(getiyear(2012), getiyear(2013), getiyear(2014))  # iyear7-9 in Stata
iy_names <- iy_names[iy_names %in% names(df)]
df$lny2 <- df$lny^2

# ---- sample1: complete cases of the column (1) regression ----
s1vars <- c("lnc_ele", "TT202", "lnPRE", "lny", "dist", "TAMAMU", "CCAA", "CAPROV",
            "NMIEMB", "NHABIT", "SUPERF", "ESTUDRED", "SITUACTHOG_j", "mayores",
            "alqui", "urban", "edif25", "year", "trim", "id")
s1vars <- s1vars[s1vars %in% names(df)]
keep <- complete.cases(df[, s1vars])
d <- df[keep, ]
rm(df); invisible(gc())

n_obs <- nrow(d)
n_hh <- length(unique(d$id))

# ---- within (demeaned) variables computed on sample1 ----
dm <- function(x, g) x - ave(x, g, FUN = function(z) mean(z, na.rm = TRUE))
wvars <- c("lnc_ele", "lng_ele", "TT202", "lnPRE", "lnPRE_papas_", "lnPRE_aguav_",
           "lnPRE_gascar_", "lny", "lny2", "dist", "NMIEMB", "iestud1", "iestud2",
           "iestud3", "isitu2", "isitu3", "mayores", "alqui", "edif25", iy_names)
wvars <- wvars[wvars %in% names(d)]
for (v in wvars) d[[paste0("w", v)]] <- dm(d[[v]], d$id)

# ---- LIML (k-class) estimator, no constant ----
liml <- function(data, yv, endog, exog, excl) {
  exog <- exog[exog %in% names(data)]
  excl <- excl[excl %in% names(data)]
  cc <- complete.cases(data[, c(yv, endog, exog, excl)])
  dd <- data[cc, ]
  y <- dd[[yv]]
  X1 <- as.matrix(dd[, exog, drop = FALSE])
  q1 <- qr(X1)
  X1 <- X1[, q1$pivot[seq_len(q1$rank)], drop = FALSE]
  Ye <- as.matrix(dd[, endog, drop = FALSE])
  Z <- cbind(X1, as.matrix(dd[, excl, drop = FALSE]))
  qZ <- qr(Z); qX <- qr(X1)
  W <- cbind(y, Ye)
  MZW <- qr.resid(qZ, W)
  MXW <- qr.resid(qX, W)
  A <- crossprod(MZW); B <- crossprod(MXW)
  kap <- min(Re(eigen(solve(A, B))$values))
  X <- cbind(Ye, X1)
  MZX <- cbind(MZW[, -1, drop = FALSE], matrix(0, nrow(X1), ncol(X1)))
  XtX <- crossprod(X) - kap * crossprod(MZX)
  Xty <- crossprod(X, y) - kap * crossprod(MZX, MZW[, 1])
  b <- solve(XtX, Xty)
  b <- setNames(as.numeric(b), colnames(X))
  list(coef = b, n = nrow(dd), kappa = kap)
}

# ---- regressor list built from available variables ----
rhs_terms <- c("TT202", "lnPRE", "lny", "I(lny^2)", "dist", "factor(TAMAMU)", "factor(CCAA)",
               "CAPROV", "NMIEMB", "NHABIT", "SUPERF", "factor(ESTUDRED)",
               "factor(SITUACTHOG_j)", "mayores", "alqui", "urban", "edif25",
               "factor(year)", "factor(trim)")
term_var <- sub("^I\\((\\w+)\\^2\\)$", "\\1", sub("^factor\\((\\w+)\\)$", "\\1", rhs_terms))
rhs <- paste(rhs_terms[term_var %in% names(d)], collapse = " + ")

# ---- column (1)/(5): OLS ----
fml_ols <- function(dep) as.formula(paste0(dep, " ~ ", rhs))
m1 <- feols(fml_ols("lnc_ele"), data = d, cluster = ~id)
m5 <- feols(fml_ols("lng_ele"), data = d, cluster = ~id)

# ---- column (3)/(7): household FE (within) ----
fml_fe <- function(dep) as.formula(paste0(dep, " ~ ", rhs, " | id"))
m3 <- feols(fml_fe("lnc_ele"), data = d, cluster = ~id, fixef.rm = "none")
m7 <- feols(fml_fe("lng_ele"), data = d, cluster = ~id, fixef.rm = "none")

# ---- column (2)/(6): IV-LIML, nocons ----
itam_n <- paste0("itam", 2:5)
iccaa_n <- paste0("iccaa", 2:19)
iccaa_n <- iccaa_n[iccaa_n %in% names(d)]
exog2 <- c("TT202", "lny", "lny2", "dist", itam_n, iccaa_n, "CAPROV", "NMIEMB",
           "NHABIT", "SUPERF", "iestud2", "iestud3", "iestud4", "isitu2", "isitu3",
           "mayores", "alqui", "urban", "edif25", iy_names)
excl2 <- c("lnPRE_aguav_", "lnPRE_papas_", "lnPRE_gascar_")
m2 <- liml(d, "lnc_ele", "lnPRE", exog2, excl2)
m6 <- liml(d, "lng_ele", "lnPRE", exog2, excl2)

# ---- column (4)/(8): FE + IV-LIML on demeaned data, nocons ----
exog4 <- c("wTT202", "wlny", "wlny2", "wdist", "wNMIEMB", "wiestud1", "wiestud2",
           "wiestud3", "wisitu2", "wisitu3", "wmayores", "walqui", "wedif25",
           paste0("w", iy_names))
excl4 <- c("wlnPRE_aguav_", "wlnPRE_papas_", "wlnPRE_gascar_")
m4 <- liml(d, "wlnc_ele", "wlnPRE", exog4, excl4)
m8 <- liml(d, "wlng_ele", "wlnPRE", exog4, excl4)

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("reform_consumption_ols_col1", coef(m1)["TT202"])
out("reform_consumption_iv_col2", m2$coef["TT202"])
out("reform_consumption_fe_col3", coef(m3)["TT202"])
out("reform_consumption_fe_iv_col4", m4$coef["wTT202"])
out("reform_expenditure_ols_col5", coef(m5)["TT202"])
out("reform_expenditure_iv_col6", m6$coef["TT202"])
out("reform_expenditure_fe_col7", coef(m7)["TT202"])
out("reform_expenditure_fe_iv_col8", m8$coef["wTT202"])
out("price_elasticity_consumption_ols_col1", coef(m1)["lnPRE"])
out("price_elasticity_consumption_fe_col3", coef(m3)["lnPRE"])
out("n_obs_table2", n_obs)
out("n_households_table2", n_hh)