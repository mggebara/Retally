# Reproduction of Goni (2022, AEJ: Applied), Table 2 Panels A and B
# Probit average marginal effects (Stata: probit ..., cluster(byear); margins, dydx(*) predict(pr))
# and OLS coefficients (Stata: reg ..., cluster(byear)).

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(sandwich)
})

set.seed(42)

root <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season"
fpath <- file.path(root, "data", "final-data.dta")

needed <- c("base_sample", "marital_rates_sample", "cOut", "mheir", "fmissmatch",
            "fmissmatch2", "fdown", "celibacy", "syntheticT", "pr4", "biorder",
            "hengpee", "distlondon", "byear")

dat <- haven::read_dta(fpath, col_select = tidyselect::any_of(needed))
dat <- haven::zap_labels(dat)
dat <- as.data.frame(dat)
for (v in intersect(needed, names(dat))) dat[[v]] <- as.numeric(dat[[v]])

controls <- c("pr4", "biorder", "hengpee")

# Probit with average marginal effect of syntheticT (continuous regressor)
probit_ame <- function(df, y, xvars) {
  vars <- c(y, "syntheticT", xvars)
  d <- df[stats::complete.cases(df[, c(vars, "byear")]), , drop = FALSE]
  f <- as.formula(paste(y, "~", paste(c("syntheticT", xvars), collapse = " + ")))
  m <- glm(f, data = d, family = binomial(link = "probit"))
  xb <- predict(m, type = "link")
  b <- coef(m)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # clustered SE of the AME via delta method (cluster by birth year)
  V <- tryCatch(sandwich::vcovCL(m, cluster = d$byear, type = "HC1"), error = function(e) NULL)
  se <- NA
  if (!is.null(V)) {
    X <- model.matrix(m)
    phi <- dnorm(xb)
    k <- which(names(b) == "syntheticT")
    # gradient of mean(phi(xb))*b_k wrt b
    g <- colMeans(-xb * phi * X) * b[k]
    g[k] <- g[k] + mean(phi)
    se <- sqrt(as.numeric(t(g) %*% V %*% g))
  }
  list(ame = unname(ame), se = se, n = nobs(m))
}

ols_coef <- function(df, y, xvars) {
  vars <- c(y, "syntheticT", xvars)
  d <- df[stats::complete.cases(df[, c(vars, "byear")]), , drop = FALSE]
  f <- as.formula(paste(y, "~", paste(c("syntheticT", xvars), collapse = " + ")))
  m <- lm(f, data = d)
  V <- tryCatch(sandwich::vcovCL(m, cluster = d$byear, type = "HC1"), error = function(e) NULL)
  se <- if (!is.null(V)) sqrt(diag(V))["syntheticT"] else NA
  list(coef = unname(coef(m)["syntheticT"]), se = unname(se), n = nobs(m))
}

base <- dat[!is.na(dat$base_sample) & dat$base_sample == 1, , drop = FALSE]
marit <- dat[!is.na(dat$marital_rates_sample) & dat$marital_rates_sample == 1, , drop = FALSE]

res <- list()
for (panel in c("A", "B")) {
  xv <- if (panel == "A") controls else c(controls, "distlondon")
  r1 <- probit_ame(base, "cOut", xv)
  r2 <- probit_ame(base, "mheir", xv)
  r3 <- ols_coef(base, "fmissmatch", xv)
  r4 <- ols_coef(base, "fmissmatch2", xv)
  r5 <- probit_ame(base, "fdown", xv)
  r6 <- probit_ame(marit, "celibacy", xv)
  res[[panel]] <- list(r1 = r1, r2 = r2, r3 = r3, r4 = r4, r5 = r5, r6 = r6)
  cat(sprintf("Panel %s: cOut AME=%.5f (se %.5f, N=%d); mheir AME=%.5f (se %.5f, N=%d)\n",
              panel, r1$ame, r1$se, r1$n, r2$ame, r2$se, r2$n))
  cat(sprintf("Panel %s: fmissmatch b=%.4f (se %.4f, N=%d); fmissmatch2 b=%.4f (se %.4f, N=%d)\n",
              panel, r3$coef, r3$se, r3$n, r4$coef, r4$se, r4$n))
  cat(sprintf("Panel %s: fdown AME=%.5f (se %.5f, N=%d); celibacy AME=%.5f (se %.5f, N=%d)\n",
              panel, r5$ame, r5$se, r5$n, r6$ame, r6$se, r6$n))
}

A <- res[["A"]]; B <- res[["B"]]
cat(sprintf("RESULT:treatment_married_commoner_table2_panelA_col1=%.6f\n", A$r1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelA_col2=%.6f\n", A$r2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=%.6f\n", A$r3$coef))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=%.6f\n", A$r4$coef))
cat(sprintf("RESULT:treatment_married_down_table2_panelA_col5=%.6f\n", A$r5$ame))
cat(sprintf("RESULT:treatment_never_married_table2_panelA_col6=%.6f\n", A$r6$ame))
cat(sprintf("RESULT:treatment_married_commoner_table2_panelB_col1=%.6f\n", B$r1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelB_col2=%.6f\n", B$r2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=%.6f\n", B$r3$coef))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=%.6f\n", B$r4$coef))
cat(sprintf("RESULT:n_obs_table2_panelA_baseline=%d\n", as.integer(A$r1$n)))
cat(sprintf("RESULT:n_obs_table2_panelA_landholdings=%d\n", as.integer(A$r3$n)))
cat(sprintf("RESULT:n_obs_table2_panelA_never_married=%d\n", as.integer(A$r6$n)))