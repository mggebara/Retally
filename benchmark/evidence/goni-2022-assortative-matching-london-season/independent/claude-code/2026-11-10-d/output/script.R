# Goni (2022) Table 2, independent reproduction
# Probit (average marginal effect of the treatment) and OLS, controls:
# duke/marquess/earl daughter (pr4), English peerage (hengpee), birth order excl. heirs (biorder);
# Panel B adds distance from family seat to London. SEs clustered by birth year.
suppressMessages({library(haven); library(dplyr); library(fixest); library(sandwich)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-d/mount/goni_2022_assortative_matching_london_season/data/"
d <- read_dta(paste0(D, "final-data.dta"),
              col_select = c(base_sample, marital_rates_sample, syntheticT, cOut, mheir, fdown,
                             fmissmatch, fmissmatch2, distlondon, pr4, hengpee, biorder, byear,
                             nthismarriage, celibacy))
d <- zap_labels(d)
base <- d %>% filter(base_sample == 1)
mr   <- d %>% filter(marital_rates_sample == 1) %>% mutate(nevmar = as.numeric(nthismarriage == 0))
cat("never-married mean:", mean(mr$nevmar), " celibacy tab:\n"); print(table(mr$celibacy, mr$nevmar, useNA = "a"))

ctrl <- "pr4 + hengpee + biorder"

probit_ame <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  dd <- data[complete.cases(data[, all.vars(f)]), ]
  m <- glm(f, family = binomial(link = "probit"), data = dd)
  b <- coef(m); X <- model.matrix(m); xb <- drop(X %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # delta-method SE with cluster-robust vcov (by birth year)
  V <- vcovCL(m, cluster = dd$byear, type = "HC1")
  g <- b["syntheticT"] * colMeans(-xb * dnorm(xb) * X)
  g["syntheticT"] <- g["syntheticT"] + mean(dnorm(xb))
  se <- sqrt(drop(t(g) %*% V %*% g))
  cat(sprintf("probit %-8s %-15s N=%d AME=%.5f SE=%.5f mean=%.3f\n", y, extra, nrow(dd), ame, se, mean(dd[[y]])))
  list(ame = unname(ame), n = nrow(dd))
}
ols <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  m <- feols(f, data = data, cluster = ~byear)
  cat(sprintf("ols    %-11s %-15s N=%d b=%.4f SE=%.4f\n", y, extra, nobs(m), coef(m)["syntheticT"], se(m)["syntheticT"]))
  list(b = unname(coef(m)["syntheticT"]), n = nobs(m))
}

a1 <- probit_ame("cOut", base); a2 <- probit_ame("mheir", base)
a3 <- ols("fmissmatch", base);   a4 <- ols("fmissmatch2", base)
a5 <- probit_ame("fdown", base); a6 <- probit_ame("nevmar", mr)
b1 <- probit_ame("cOut", base, "+ distlondon"); b2 <- probit_ame("mheir", base, "+ distlondon")
b3 <- ols("fmissmatch", base, "+ distlondon");  b4 <- ols("fmissmatch2", base, "+ distlondon")
b5 <- probit_ame("fdown", base, "+ distlondon"); b6 <- probit_ame("nevmar", mr, "+ distlondon")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("treatment_married_commoner_table2_panelA_col1", a1$ame)
r("treatment_married_heir_table2_panelA_col2", a2$ame)
r("treatment_landholdings_diff_abs_table2_panelA_col3", a3$b)
r("treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4", a4$b)
r("treatment_married_down_table2_panelA_col5", a5$ame)
r("treatment_never_married_table2_panelA_col6", a6$ame)
r("treatment_married_commoner_table2_panelB_col1", b1$ame)
r("treatment_married_heir_table2_panelB_col2", b2$ame)
r("treatment_landholdings_diff_abs_table2_panelB_col3", b3$b)
r("treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4", b4$b)
r("n_obs_table2_panelA_baseline", a1$n)
r("n_obs_table2_panelA_landholdings", a3$n)
r("n_obs_table2_panelA_never_married", a6$n)
