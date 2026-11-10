# Reproduction of Goni (2022) Table 2, following programs/02_analysis/master-analysis.do
suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
})
set.seed(42)

root <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-a/mount/goni_2022_assortative_matching_london_season"
f <- file.path(root, "data", "final-data.dta")

vars <- c("cOut", "mheir", "fmissmatch", "fmissmatch2", "fdown", "celibacy",
          "syntheticT", "pr4", "biorder", "hengpee", "distlondon", "byear",
          "base_sample", "marital_rates_sample")
d <- as.data.frame(haven::zap_labels(haven::read_dta(f, col_select = tidyselect::any_of(vars))))
cat("Columns read:", paste(names(d), collapse = ", "), "\n")

controls <- c("pr4", "biorder", "hengpee")

# Stata-style cluster-robust vcov (CR1 with G/(G-1) * (N-1)/(N-K) for reg,
# G/(G-1) for probit ML); only coefficients are scored, SEs reported for info.
fit_one <- function(dat, y, extra, type) {
  rhs <- c("syntheticT", controls, extra)
  fml <- reformulate(rhs, response = y)
  dd <- dat[complete.cases(dat[, c(y, rhs, "byear")]), ]
  if (type == "probit") {
    m <- glm(fml, data = dd, family = binomial(link = "probit"))
    b <- coef(m)
    X <- model.matrix(m)
    xb <- drop(X %*% b)
    # Average marginal effect (Stata margins, dydx(*) predict(pr)) of syntheticT
    ame <- mean(dnorm(xb)) * b["syntheticT"]
    # Delta-method SE with clustered vcov
    V <- sandwich::vcovCL(m, cluster = dd$byear, type = "HC0", cadjust = TRUE)
    g <- mean(dnorm(xb)) * (seq_along(b) == which(names(b) == "syntheticT")) -
      b["syntheticT"] * colMeans(xb * dnorm(xb) * X)
    se <- sqrt(drop(t(g) %*% V %*% g))
    est <- unname(ame)
  } else {
    m <- lm(fml, data = dd)
    V <- sandwich::vcovCL(m, cluster = dd$byear, type = "HC1")
    est <- unname(coef(m)["syntheticT"])
    se <- sqrt(V["syntheticT", "syntheticT"])
  }
  list(est = est, se = unname(se), n = nrow(dd))
}

base <- d[d$base_sample == 1 & !is.na(d$base_sample), ]
mrs  <- d[d$marital_rates_sample == 1 & !is.na(d$marital_rates_sample), ]

out <- list()
for (panel in c("A", "B")) {
  extra <- if (panel == "B") "distlondon" else character(0)
  out[[panel]] <- list(
    c1 = fit_one(base, "cOut", extra, "probit"),
    c2 = fit_one(base, "mheir", extra, "probit"),
    c3 = fit_one(base, "fmissmatch", extra, "ols"),
    c4 = fit_one(base, "fmissmatch2", extra, "ols"),
    c5 = fit_one(base, "fdown", extra, "probit"),
    c6 = fit_one(mrs, "celibacy", extra, "probit")
  )
  for (k in names(out[[panel]])) {
    r <- out[[panel]][[k]]
    cat(sprintf("Panel %s %s: est=%.5f se=%.5f N=%d\n", panel, k, r$est, r$se, r$n))
  }
}

A <- out$A; B <- out$B
cat(sprintf("RESULT:treatment_married_commoner_table2_panelA_col1=%.6f\n", A$c1$est))
cat(sprintf("RESULT:treatment_married_heir_table2_panelA_col2=%.6f\n", A$c2$est))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=%.6f\n", A$c3$est))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=%.6f\n", A$c4$est))
cat(sprintf("RESULT:treatment_married_down_table2_panelA_col5=%.6f\n", A$c5$est))
cat(sprintf("RESULT:treatment_never_married_table2_panelA_col6=%.6f\n", A$c6$est))
cat(sprintf("RESULT:treatment_married_commoner_table2_panelB_col1=%.6f\n", B$c1$est))
cat(sprintf("RESULT:treatment_married_heir_table2_panelB_col2=%.6f\n", B$c2$est))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=%.6f\n", B$c3$est))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=%.6f\n", B$c4$est))
cat(sprintf("RESULT:n_obs_table2_panelA_baseline=%d\n", A$c1$n))
cat(sprintf("RESULT:n_obs_table2_panelA_landholdings=%d\n", A$c3$n))
cat(sprintf("RESULT:n_obs_table2_panelA_never_married=%d\n", A$c6$n))
