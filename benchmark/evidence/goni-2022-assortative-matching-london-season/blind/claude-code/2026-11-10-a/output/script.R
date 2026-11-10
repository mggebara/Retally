# Goni (2022), Table 2 Panels A and B: blind independent reproduction.
suppressMessages({library(haven); library(dplyr); library(fixest); library(sandwich)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-a/mount/goni_2022_assortative_matching_london_season"
d <- zap_labels(read_dta(file.path(D, "data/final-data.dta")))

# Samples (flags shipped in the data file; checked against the paper's text:
# 484 baseline women with a family seat, 260 landholdings couples with a seat, 565 marital-rates women with a seat)
base <- d %>% filter(base_sample == 1)                 # peers' daughters aged 15-35 in 1861, ever married, first marriages, no foreigners/royals
land <- base %>% filter(!is.na(fmissmatch), !is.na(fmissmatch2), !is.na(fdown))  # both spouses' landholdings in Bateman
mar  <- d %>% filter(marital_rates_sample == 1)        # incl. never married, excl. died before 35
mar$nevermarried <- mar$celibacy

# Treatment: syntheticT (percent); controls: duke/marquess/earl daughter (pr4), English peerage (hengpee), birth order excl. heirs (biorder)
ctrl <- "pr4 + hengpee + biorder"

probit_ame <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  data <- data[complete.cases(data[, all.vars(f)]), ]
  m <- glm(f, data = data, family = binomial(link = "probit"))
  X <- model.matrix(m); b <- coef(m); xb <- drop(X %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # delta-method SE with birth-year clustered vcov
  V <- vcovCL(m, cluster = data$byear, type = "HC1")
  g <- colMeans(-xb * dnorm(xb) * X) * b["syntheticT"]
  g["syntheticT"] <- g["syntheticT"] + mean(dnorm(xb))
  se <- sqrt(drop(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (data[[y]] == 1))
  cat(sprintf("  probit %-14s %-18s N=%d coef=%.5f AME=%.5f (cl.se %.5f) pct_correct=%.0f mean_y=%.3f\n",
              y, extra, nrow(data), b["syntheticT"], ame, se, 100 * pc, mean(data[[y]])))
  list(ame = unname(ame), n = nrow(data))
}
ols <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  m <- feols(f, data = data, cluster = ~byear)
  cat(sprintf("  OLS    %-14s %-18s N=%d coef=%.5f (cl.se %.5f) mean_y=%.3f\n",
              y, extra, nobs(m), coef(m)["syntheticT"], se(m)["syntheticT"], mean(data[[y]], na.rm = TRUE)))
  list(b = unname(coef(m)["syntheticT"]), n = nobs(m))
}

cat("Panel A\n")
a1 <- probit_ame("cOut", base)
a2 <- probit_ame("mheir", base)
a3 <- ols("fmissmatch", land)
a4 <- ols("fmissmatch2", land)
a5 <- probit_ame("fdown", land)
a6 <- probit_ame("nevermarried", mar)
cat("Panel B\n")
dx <- "+ distlondon"
b1 <- probit_ame("cOut", base, dx)
b2 <- probit_ame("mheir", base, dx)
b3 <- ols("fmissmatch", land, dx)
b4 <- ols("fmissmatch2", land, dx)
b5 <- probit_ame("fdown", land, dx)
b6 <- probit_ame("nevermarried", mar, dx)

cat(sprintf("RESULT:treatment_married_commoner_table2_panelA_col1=%.6f\n", a1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelA_col2=%.6f\n", a2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=%.6f\n", a3$b))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=%.6f\n", a4$b))
cat(sprintf("RESULT:treatment_married_down_table2_panelA_col5=%.6f\n", a5$ame))
cat(sprintf("RESULT:treatment_never_married_table2_panelA_col6=%.6f\n", a6$ame))
cat(sprintf("RESULT:treatment_married_commoner_table2_panelB_col1=%.6f\n", b1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelB_col2=%.6f\n", b2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=%.6f\n", b3$b))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=%.6f\n", b4$b))
cat(sprintf("RESULT:n_obs_table2_panelA_baseline=%d\n", a1$n))
cat(sprintf("RESULT:n_obs_table2_panelA_landholdings=%d\n", a3$n))
cat(sprintf("RESULT:n_obs_table2_panelA_never_married=%d\n", a6$n))
