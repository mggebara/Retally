# Independent reproduction: Goni (2022), Table 2 Panels A and B
# Probit (average marginal effects) and OLS of marriage outcomes on the synthetic
# probability to marry in 1861-63, controls: Duke/Marquess/Earl daughter (pr4),
# English peerage (hengpee), birth order excluding heirs (biorder); Panel B adds
# distance from family seat to London. SEs clustered by birth year.
set.seed(42)
suppressMessages({library(haven); library(sandwich)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-c/mount/goni_2022_assortative_matching_london_season/data/"
vars <- c("base_sample","marital_rates_sample","cOut","mheir","fmissmatch","fmissmatch2",
          "fdown","celibacy","syntheticT","pr4","hengpee","biorder","distlondon","byear","age1861")
d <- read_dta(paste0(D,"final-data.dta"), col_select = dplyr::all_of(vars))
d <- as.data.frame(lapply(d, function(x) as.numeric(zap_labels(x))))

base <- d[d$base_sample == 1, ]
mrs  <- d[d$marital_rates_sample == 1, ]
cat("baseline N:", nrow(base), " marital-rates N:", nrow(mrs), "\n")
cat("never-married mean (celibacy):", mean(mrs$celibacy, na.rm=TRUE), "\n")

ctrl <- c("syntheticT","pr4","hengpee","biorder")

probit_ame <- function(y, data, x) {
  f <- reformulate(x, y)
  dd <- data[complete.cases(data[, c(y, x, "byear")]), ]
  m <- glm(f, data = dd, family = binomial(link = "probit"))
  V <- vcovCL(m, cluster = dd$byear, type = "HC0")
  X <- model.matrix(m); b <- coef(m); xb <- drop(X %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # delta-method gradient
  g <- mean(dnorm(xb)) * (names(b) == "syntheticT") - b["syntheticT"] * colMeans(xb * dnorm(xb) * X)
  se <- sqrt(drop(t(g) %*% V %*% g))
  list(est = unname(ame), se = se, n = nrow(dd), mean = mean(dd[[y]]))
}
ols <- function(y, data, x) {
  f <- reformulate(x, y)
  dd <- data[complete.cases(data[, c(y, x, "byear")]), ]
  m <- lm(f, data = dd)
  V <- vcovCL(m, cluster = dd$byear, type = "HC1")
  list(est = unname(coef(m)["syntheticT"]), se = sqrt(V["syntheticT","syntheticT"]),
       n = nrow(dd), mean = mean(dd[[y]]))
}

res <- list()
for (panel in c("A","B")) {
  x <- if (panel == "A") ctrl else c(ctrl, "distlondon")
  res[[panel]] <- list(
    c1 = probit_ame("cOut", base, x),
    c2 = probit_ame("mheir", base, x),
    c3 = ols("fmissmatch", base, x),
    c4 = ols("fmissmatch2", base, x),
    c5 = probit_ame("fdown", base, x),
    c6 = probit_ame("celibacy", mrs, x))
  for (k in names(res[[panel]])) {
    r <- res[[panel]][[k]]
    cat(sprintf("Panel %s %s: est %.4f se %.4f N %d mean %.3f\n", panel, k, r$est, r$se, r$n, r$mean))
  }
}

A <- res$A; B <- res$B
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
