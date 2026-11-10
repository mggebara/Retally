# Reproduction of Goni (2022, AEJ: Applied), Table 2, Panels A and B
# Follows programs/02_analysis/master-analysis.do (Table 2 section):
#   probit cOut/mheir/fdown/celibacy syntheticT pr4 biorder hengpee [distlondon], cluster(byear)
#     followed by margins, dydx(*) predict(pr)  -> average marginal effects
#   reg fmissmatch/fmissmatch2 syntheticT pr4 biorder hengpee [distlondon], cluster(byear)
# Samples: base_sample==1 (cols 1-5), marital_rates_sample==1 (col 6).

suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(fixest)
})

set.seed(42)

root <- "<repo>/.cache/datasets/goni_2022_assortative_matching_london_season"
fpath <- file.path(root, "data", "final-data.dta")

needed <- c("base_sample", "marital_rates_sample", "cOut", "mheir", "fmissmatch",
            "fmissmatch2", "fdown", "celibacy", "syntheticT", "pr4", "biorder",
            "hengpee", "distlondon", "byear")

dat <- tryCatch(
  haven::read_dta(fpath, col_select = dplyr::any_of(needed)),
  error = function(e) haven::read_dta(fpath)
)
dat <- as.data.frame(haven::zap_labels(haven::zap_formats(dat)))
dat <- dat[, intersect(needed, names(dat)), drop = FALSE]
for (v in names(dat)) dat[[v]] <- as.numeric(dat[[v]])
cat("Loaded final-data.dta:", nrow(dat), "rows,", ncol(dat), "cols\n")

controls <- c("pr4", "biorder", "hengpee")

emit <- function(name, value) {
  if (is.null(value) || length(value) == 0 || is.na(value)) {
    cat(sprintf("RESULT:%s=NA\n", name))
  } else {
    cat(sprintf("RESULT:%s=%.6f\n", name, value))
  }
}

# Probit with birth-year clustered SEs (Stata: G/(G-1) adjustment) and
# average marginal effect of syntheticT with delta-method SE.
probit_ame <- function(df, y, extra = NULL) {
  rhs <- c("syntheticT", controls, extra)
  d <- df[, c(y, rhs, "byear")]
  d <- d[complete.cases(d), ]
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- glm(fml, data = d, family = binomial(link = "probit"))
  V <- sandwich::vcovCL(m, cluster = ~byear, type = "HC0", cadjust = TRUE)
  X <- model.matrix(m)
  b <- coef(m)
  xb <- as.vector(X %*% b)
  phi <- dnorm(xb)
  k <- "syntheticT"
  ame <- mean(phi) * b[k]
  # gradient of AME wrt beta
  grad <- colMeans(phi * (-xb) * X) * b[k]
  grad[k] <- grad[k] + mean(phi)
  se <- sqrt(as.numeric(t(grad) %*% V %*% grad))
  pred <- as.numeric(fitted(m) >= 0.5)
  pcp <- mean(pred == d[[y]]) * 100
  list(ame = unname(ame), se = se, n = nrow(d), coef = unname(b[k]),
       se_coef = sqrt(V[k, k]), pcp = pcp, mean_y = mean(d[[y]]),
       G = length(unique(d$byear)))
}

ols_cl <- function(df, y, extra = NULL) {
  rhs <- c("syntheticT", controls, extra)
  d <- df[, c(y, rhs, "byear")]
  d <- d[complete.cases(d), ]
  fml <- as.formula(paste(y, "~", paste(rhs, collapse = " + ")))
  m <- fixest::feols(fml, data = d, cluster = ~byear)
  list(coef = unname(coef(m)["syntheticT"]),
       se = unname(sqrt(diag(vcov(m)))["syntheticT"]),
       n = nobs(m), mean_y = mean(d[[y]]))
}

base <- dat[!is.na(dat$base_sample) & dat$base_sample == 1, ]
mrs  <- dat[!is.na(dat$marital_rates_sample) & dat$marital_rates_sample == 1, ]
cat("Baseline sample rows:", nrow(base), " Marital-rates sample rows:", nrow(mrs), "\n")

res <- list()
for (panel in c("A", "B")) {
  extra <- if (panel == "B") "distlondon" else NULL
  r1 <- probit_ame(base, "cOut", extra)
  r2 <- probit_ame(base, "mheir", extra)
  r3 <- ols_cl(base, "fmissmatch", extra)
  r4 <- ols_cl(base, "fmissmatch2", extra)
  r5 <- probit_ame(base, "fdown", extra)
  r6 <- probit_ame(mrs, "celibacy", extra)
  res[[panel]] <- list(r1 = r1, r2 = r2, r3 = r3, r4 = r4, r5 = r5, r6 = r6)
  cat(sprintf("\nPanel %s\n", panel))
  cat(sprintf("  (1) cOut   AME=%.4f (%.4f) N=%d pcp=%.0f mean=%.2f G=%d\n", r1$ame, r1$se, r1$n, r1$pcp, r1$mean_y, r1$G))
  cat(sprintf("  (2) mheir  AME=%.4f (%.4f) N=%d pcp=%.0f mean=%.2f\n", r2$ame, r2$se, r2$n, r2$pcp, r2$mean_y))
  cat(sprintf("  (3) |diff| b=%.3f (%.3f) N=%d mean=%.0f\n", r3$coef, r3$se, r3$n, r3$mean_y))
  cat(sprintf("  (4) h-w    b=%.3f (%.3f) N=%d mean=%.0f\n", r4$coef, r4$se, r4$n, r4$mean_y))
  cat(sprintf("  (5) fdown  AME=%.4f (%.4f) N=%d pcp=%.0f mean=%.2f\n", r5$ame, r5$se, r5$n, r5$pcp, r5$mean_y))
  cat(sprintf("  (6) celib  AME=%.4f (%.4f) N=%d pcp=%.0f mean=%.2f\n", r6$ame, r6$se, r6$n, r6$pcp, r6$mean_y))
}
cat("\n")

A <- res[["A"]]; B <- res[["B"]]
emit("treatment_married_commoner_table2_panelA_col1", A$r1$ame)
emit("treatment_married_heir_table2_panelA_col2", A$r2$ame)
emit("treatment_landholdings_diff_abs_table2_panelA_col3", A$r3$coef)
emit("treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4", A$r4$coef)
emit("treatment_married_down_table2_panelA_col5", A$r5$ame)
emit("treatment_never_married_table2_panelA_col6", A$r6$ame)
emit("treatment_married_commoner_table2_panelB_col1", B$r1$ame)
emit("treatment_married_heir_table2_panelB_col2", B$r2$ame)
emit("treatment_landholdings_diff_abs_table2_panelB_col3", B$r3$coef)
emit("treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4", B$r4$coef)
emit("n_obs_table2_panelA_baseline", A$r1$n)
emit("n_obs_table2_panelA_landholdings", A$r3$n)
emit("n_obs_table2_panelA_never_married", A$r6$n)
