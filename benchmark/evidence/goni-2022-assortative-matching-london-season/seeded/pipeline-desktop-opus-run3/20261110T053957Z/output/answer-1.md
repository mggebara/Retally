suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
  library(fixest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season"
data_path <- file.path(base_dir, "data", "final-data.dta")

needed <- c("base_sample", "marital_rates_sample", "cOut", "mheir", "fmissmatch",
            "fmissmatch2", "fdown", "celibacy", "syntheticT", "pr4", "biorder",
            "hengpee", "distlondon", "byear")

df_all <- haven::read_dta(data_path, col_select = dplyr::any_of(needed))
df_all <- as.data.frame(haven::zap_labels(haven::zap_formats(df_all)))
for (v in names(df_all)) df_all[[v]] <- as.numeric(df_all[[v]])

missing_vars <- setdiff(needed, names(df_all))
if (length(missing_vars) > 0) {
  cat("WARNING: missing variables:", paste(missing_vars, collapse = ", "), "\n")
}

controls <- c("pr4", "biorder", "hengpee")

# ---------------------------------------------------------------------------
# Probit with Stata-style clustered vcov and average marginal effect (margins,
# dydx(*) predict(pr)) of syntheticT, delta-method SE.
# ---------------------------------------------------------------------------
probit_ame <- function(dat, y, extra = NULL, cl = "byear", target = "syntheticT") {
  rhs <- c(target, controls, extra)
  vars <- c(y, rhs, cl)
  d <- dat[complete.cases(dat[, vars]), vars, drop = FALSE]
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- glm(fml, data = d, family = binomial(link = "probit"),
           control = glm.control(epsilon = 1e-12, maxit = 100))
  V <- sandwich::vcovCL(m, cluster = d[[cl]], type = "HC0", cadjust = TRUE)
  X <- model.matrix(m)
  b <- coef(m)
  xb <- as.vector(X %*% b)
  phi <- dnorm(xb)
  j <- which(names(b) == target)
  ame <- mean(phi) * b[j]
  # gradient of ame w.r.t. b
  grad <- b[j] * colMeans(-xb * phi * X)
  grad[j] <- grad[j] + mean(phi)
  se <- sqrt(as.numeric(t(grad) %*% V %*% grad))
  pred <- as.numeric(fitted(m) >= 0.5)
  pcp <- 100 * mean(pred == d[[y]])
  list(ame = unname(ame), se = se, n = nrow(d), coef = unname(b[j]),
       ymean = mean(d[[y]]), pcp = pcp, G = length(unique(d[[cl]])))
}

ols_cl <- function(dat, y, extra = NULL, cl = "byear", target = "syntheticT") {
  rhs <- c(target, controls, extra)
  vars <- c(y, rhs, cl)
  d <- dat[complete.cases(dat[, vars]), vars, drop = FALSE]
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- fixest::feols(fml, data = d, cluster = as.formula(paste0("~", cl)))
  list(coef = unname(coef(m)[target]),
       se = unname(sqrt(diag(vcov(m)))[target]),
       n = nobs(m), ymean = mean(d[[y]]))
}

safe <- function(expr) tryCatch(expr, error = function(e) {
  cat("ERROR:", conditionMessage(e), "\n"); NULL
})

# ---------------------------------------------------------------------------
# Table 2, columns 1-5: baseline sample
# ---------------------------------------------------------------------------
base <- df_all[!is.na(df_all$base_sample) & df_all$base_sample == 1, ]
cat("Baseline sample rows:", nrow(base), "\n")

res <- list()
for (panel in c("A", "B")) {
  extra <- if (panel == "B") "distlondon" else NULL
  res[[panel]] <- list(
    c1 = safe(probit_ame(base, "cOut", extra)),
    c2 = safe(probit_ame(base, "mheir", extra)),
    c3 = safe(ols_cl(base, "fmissmatch", extra)),
    c4 = safe(ols_cl(base, "fmissmatch2", extra)),
    c5 = safe(probit_ame(base, "fdown", extra))
  )
}

# ---------------------------------------------------------------------------
# Table 2, column 6: marital-rates sample (celibacy)
# ---------------------------------------------------------------------------
mrs <- df_all[!is.na(df_all$marital_rates_sample) & df_all$marital_rates_sample == 1, ]
cat("Marital rates sample rows:", nrow(mrs), "\n")
res$A$c6 <- safe(probit_ame(mrs, "celibacy", NULL))
res$B$c6 <- safe(probit_ame(mrs, "celibacy", "distlondon"))

# Diagnostics
for (panel in c("A", "B")) {
  for (cc in names(res[[panel]])) {
    r <- res[[panel]][[cc]]
    if (is.null(r)) next
    est <- if (!is.null(r$ame)) r$ame else r$coef
    cat(sprintf("Panel %s %s: est=%.5f se=%.5f N=%d mean=%.3f%s\n", panel, cc,
                est, r$se, r$n, r$ymean,
                if (!is.null(r$pcp)) sprintf(" pcp=%.1f G=%d", r$pcp, r$G) else ""))
  }
}

emit <- function(name, val) {
  if (!is.null(val) && length(val) == 1 && is.finite(val)) {
    cat(sprintf("RESULT:%s=%.6f\n", name, val))
  }
}

g <- function(panel, cc, field) {
  r <- res[[panel]][[cc]]
  if (is.null(r)) return(NULL)
  r[[field]]
}

emit("treatment_married_commoner_table2_panelA_col1", g("A", "c1", "ame"))
emit("treatment_married_heir_table2_panelA_col2", g("A", "c2", "ame"))
emit("treatment_landholdings_diff_abs_table2_panelA_col3", g("A", "c3", "coef"))
emit("treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4", g("A", "c4", "coef"))
emit("treatment_married_down_table2_panelA_col5", g("A", "c5", "ame"))
emit("treatment_never_married_table2_panelA_col6", g("A", "c6", "ame"))
emit("treatment_married_commoner_table2_panelB_col1", g("B", "c1", "ame"))
emit("treatment_married_heir_table2_panelB_col2", g("B", "c2", "ame"))
emit("treatment_landholdings_diff_abs_table2_panelB_col3", g("B", "c3", "coef"))
emit("treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4", g("B", "c4", "coef"))
emit("n_obs_table2_panelA_baseline", g("A", "c1", "n"))
emit("n_obs_table2_panelA_landholdings", g("A", "c3", "n"))
emit("n_obs_table2_panelA_never_married", g("A", "c6", "n"))
