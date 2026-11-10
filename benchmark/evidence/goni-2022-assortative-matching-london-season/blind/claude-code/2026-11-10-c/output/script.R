# Goni (2022) Table 2, Panels A and B -- independent, blind reproduction.
# Probit (eq. 2) / OLS (eq. 3) of marriage outcomes on the synthetic probability
# to marry in 1861-1863 (syntheticT) with controls: duke/marquess/earl daughter
# (pr4), English peerage (hengpee), birth order excluding heirs (biorder);
# Panel B adds distance from family seat to London (distlondon).
# SEs clustered by birth year. Probit coefficients reported as average marginal
# effects of the treatment.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest); library(marginaleffects)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-c/mount/goni_2022_assortative_matching_london_season/data/"
v <- c("refno","byear","celibacy","base_sample","marital_rates_sample","syntheticT","age1861",
       "cOut","mheir","fmissmatch","fmissmatch2","fdown","distlondon","pr4","hengpee","biorder")
x <- zap_labels(read_dta(paste0(D, "final-data.dta"), col_select = all_of(v)))

base <- filter(x, base_sample == 1)                       # married women aged 15-35 in 1861
land <- filter(base, !is.na(fmissmatch), !is.na(fmissmatch2), !is.na(fdown))
mar  <- filter(x, marital_rates_sample == 1)               # incl. never married, excl. died < 35

ctrl <- "pr4 + hengpee + biorder"
res <- list()

probit_me <- function(y, d, dist = FALSE) {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, if (dist) "+ distlondon" else ""))
  d <- d[complete.cases(d[, all.vars(f)]), ]
  m <- glm(f, family = binomial(link = "probit"), data = d)
  V <- vcovCL(m, cluster = ~byear, type = "HC0")
  ame <- avg_slopes(m, variables = "syntheticT", vcov = V)
  # marginal effect at means (diagnostic only)
  xb <- sum(coef(m) * c(1, colMeans(model.matrix(m)[, -1])))
  mem <- dnorm(xb) * coef(m)["syntheticT"]
  cat(sprintf("  probit %-10s dist=%s N=%d AME=%.5f (se %.5f) MEM=%.5f coef=%.5f meanY=%.3f\n",
              y, dist, nobs(m), ame$estimate, ame$std.error, mem, coef(m)["syntheticT"], mean(d[[y]])))
  list(est = ame$estimate, n = nobs(m))
}
ols_b <- function(y, d, dist = FALSE) {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, if (dist) "+ distlondon" else ""))
  d <- d[complete.cases(d[, all.vars(f)]), ]
  m <- lm(f, data = d)
  V <- vcovCL(m, cluster = ~byear, type = "HC1")
  ct <- coeftest(m, vcov. = V)
  cat(sprintf("  ols    %-10s dist=%s N=%d B=%.5f (se %.5f) meanY=%.3f\n",
              y, dist, nobs(m), coef(m)["syntheticT"], ct["syntheticT", 2], mean(d[[y]])))
  list(est = unname(coef(m)["syntheticT"]), n = nobs(m))
}

cat("Panel A\n")
a1 <- probit_me("cOut", base)
a2 <- probit_me("mheir", base)
a3 <- ols_b("fmissmatch", land)
a4 <- ols_b("fmissmatch2", land)
a5 <- probit_me("fdown", land)
a6 <- probit_me("celibacy", mar)
cat("Panel B\n")
b1 <- probit_me("cOut", base, TRUE)
b2 <- probit_me("mheir", base, TRUE)
b3 <- ols_b("fmissmatch", land, TRUE)
b4 <- ols_b("fmissmatch2", land, TRUE)
b5 <- probit_me("fdown", land, TRUE)
b6 <- probit_me("celibacy", mar, TRUE)
cat("clusters (birth years) in baseline:", length(unique(base$byear)), "\n")

out <- c(
  treatment_married_commoner_table2_panelA_col1 = a1$est,
  treatment_married_heir_table2_panelA_col2 = a2$est,
  treatment_landholdings_diff_abs_table2_panelA_col3 = a3$est,
  treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4 = a4$est,
  treatment_married_down_table2_panelA_col5 = a5$est,
  treatment_never_married_table2_panelA_col6 = a6$est,
  treatment_married_commoner_table2_panelB_col1 = b1$est,
  treatment_married_heir_table2_panelB_col2 = b2$est,
  treatment_landholdings_diff_abs_table2_panelB_col3 = b3$est,
  treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4 = b4$est,
  n_obs_table2_panelA_baseline = a1$n,
  n_obs_table2_panelA_landholdings = a3$n,
  n_obs_table2_panelA_never_married = a6$n)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
