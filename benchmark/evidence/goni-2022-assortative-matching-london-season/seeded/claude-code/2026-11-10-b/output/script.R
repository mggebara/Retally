# Goni (2022) Table 2, Panels A and B: translation of master-analysis.do (Table 2 block)
# Probits: average marginal effect of syntheticT (Stata margins, dydx(*) predict(pr));
# OLS: coefficient. Controls pr4 biorder hengpee (+ distlondon in Panel B).
# SEs clustered by byear do not affect the point estimates reported here.
suppressPackageStartupMessages({library(haven)})
set.seed(42)
dd <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/seeded/2026-11-10-b/mount/goni_2022_assortative_matching_london_season"
vars <- c("base_sample","marital_rates_sample","cOut","mheir","fmissmatch","fmissmatch2",
          "fdown","celibacy","syntheticT","pr4","biorder","hengpee","distlondon","byear")
d <- as.data.frame(zap_labels(read_dta(file.path(dd, "data/final-data.dta"), col_select = dplyr::all_of(vars))))
controls <- c("pr4","biorder","hengpee")

probit_ame <- function(y, data, extra = NULL) {
  f <- reformulate(c("syntheticT", controls, extra), y)
  m <- glm(f, family = binomial(link = "probit"), data = data)
  X <- model.matrix(m); b <- coef(m)
  ame <- mean(dnorm(drop(X %*% b))) * b["syntheticT"]
  list(ame = unname(ame), n = nobs(m))
}
ols_b <- function(y, data, extra = NULL) {
  f <- reformulate(c("syntheticT", controls, extra), y)
  m <- lm(f, data = data)
  list(b = unname(coef(m)["syntheticT"]), n = nobs(m))
}

base <- d[!is.na(d$base_sample) & d$base_sample == 1, ]
mr   <- d[!is.na(d$marital_rates_sample) & d$marital_rates_sample == 1, ]

res <- list()
for (p in c("A","B")) {
  ex <- if (p == "B") "distlondon" else NULL
  r <- list(c1 = probit_ame("cOut", base, ex),
            c2 = probit_ame("mheir", base, ex),
            c3 = ols_b("fmissmatch", base, ex),
            c4 = ols_b("fmissmatch2", base, ex),
            c5 = probit_ame("fdown", base, ex),
            c6 = probit_ame("celibacy", mr, ex))
  res[[p]] <- r
  cat(sprintf("Panel %s: N = %s\n", p, paste(sapply(r, `[[`, "n"), collapse = " ")))
}
A <- res$A; B <- res$B
out <- c(
  treatment_married_commoner_table2_panelA_col1 = A$c1$ame,
  treatment_married_heir_table2_panelA_col2 = A$c2$ame,
  treatment_landholdings_diff_abs_table2_panelA_col3 = A$c3$b,
  treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4 = A$c4$b,
  treatment_married_down_table2_panelA_col5 = A$c5$ame,
  treatment_never_married_table2_panelA_col6 = A$c6$ame,
  treatment_married_commoner_table2_panelB_col1 = B$c1$ame,
  treatment_married_heir_table2_panelB_col2 = B$c2$ame,
  treatment_landholdings_diff_abs_table2_panelB_col3 = B$c3$b,
  treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4 = B$c4$b,
  n_obs_table2_panelA_baseline = A$c1$n,
  n_obs_table2_panelA_landholdings = A$c3$n,
  n_obs_table2_panelA_never_married = A$c6$n)
for (nm in names(out)) cat(sprintf("RESULT:%s=%.6f\n", nm, out[[nm]]))
