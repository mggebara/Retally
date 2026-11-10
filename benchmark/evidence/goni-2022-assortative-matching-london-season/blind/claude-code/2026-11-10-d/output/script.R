# Goni (2022), Table 2: Season's interruption and marriage outcomes.
# Independent, blind reproduction from the paper's description.
suppressMessages({
  library(haven); library(dplyr); library(fixest); library(sandwich)
})
set.seed(42)
P <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-d/mount/goni_2022_assortative_matching_london_season"
d <- zap_labels(read_dta(file.path(P, "data/final-data.dta")))

# ---- Diagnostic: rebuild the synthetic probability T from the benchmark cohort
# (peers' daughters born 1815-1830, first marriages / never married, excluding
# those who married after 1861 and those who died before age 30).
bc <- d %>% filter(wom == 1, byear >= 1815, byear <= 1830, nthismarriage <= 1) %>%
  filter(is.na(myear) | myear <= 1861) %>%
  filter(is.na(dage) | dage >= 30)
N <- nrow(bc)
p <- sapply(0:60, function(a) 100 * sum(bc$mage == a, na.rm = TRUE) / N)
Tmine <- function(a) p[a + 1] + p[a + 2] + p[a + 3]
chk <- d %>% filter(base_sample == 1) %>% distinct(age1861, syntheticT) %>% arrange(age1861) %>%
  mutate(T_rebuilt = sapply(age1861, Tmine))
cat("Diagnostic: benchmark cohort N =", N, "\n")
print(as.data.frame(chk))
cat("Diagnostic: corr(dataset syntheticT, rebuilt T) =", cor(chk$syntheticT, chk$T_rebuilt), "\n")

# ---- Samples (pre-built flags in the data, checked against paper's definitions)
b <- d %>% filter(base_sample == 1)          # married peers' daughters aged 15-35 in 1861
m <- d %>% filter(marital_rates_sample == 1) # incl. never married, excl. died < 35
m$never <- as.numeric(m$nthismarriage == 0)
cat("Diagnostic: base", nrow(b), "| landholdings", sum(!is.na(b$fmissmatch)),
    "| marital", nrow(m), "| min dage marital", min(m$dage, na.rm = TRUE), "\n")

ctrl <- "pr4 + hengpee + biorder"

probit_ame <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  data <- data[complete.cases(data[, all.vars(f)]), ]
  g <- glm(f, data = data, family = binomial(link = "probit"))
  # average marginal effect of the treatment (Stata margins, dydx default)
  X <- model.matrix(g); bcoef <- coef(g)
  xb <- as.vector(X %*% bcoef)
  ame <- mean(dnorm(xb)) * bcoef["syntheticT"]
  # delta-method SE with birth-year clustered vcov
  V <- vcovCL(g, cluster = data$byear, type = "HC0")
  grad <- colMeans(dnorm(xb) * (-xb) * X) * bcoef["syntheticT"]
  grad["syntheticT"] <- grad["syntheticT"] + mean(dnorm(xb))
  se <- sqrt(as.numeric(t(grad) %*% V %*% grad))
  list(ame = unname(ame), se = se, n = nrow(data), coef = unname(bcoef["syntheticT"]))
}
ols_b <- function(y, data, extra = "") {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, extra))
  r <- feols(f, data = data, cluster = ~byear)
  list(b = unname(coef(r)["syntheticT"]), se = unname(se(r)["syntheticT"]), n = nobs(r))
}

bl <- b %>% filter(!is.na(fmissmatch))

A1 <- probit_ame("cOut", b)
A2 <- probit_ame("mheir", b)
A3 <- ols_b("fmissmatch", bl)
A4 <- ols_b("fmissmatch2", bl)
A5 <- probit_ame("fdown", bl)
A6 <- probit_ame("never", m)

B1 <- probit_ame("cOut", b, "+ distlondon")
B2 <- probit_ame("mheir", b, "+ distlondon")
B3 <- ols_b("fmissmatch", bl, "+ distlondon")
B4 <- ols_b("fmissmatch2", bl, "+ distlondon")
B5 <- probit_ame("fdown", bl, "+ distlondon")
B6 <- probit_ame("never", m, "+ distlondon")

pr <- function(nm, x) cat(sprintf("%s: est=%.5f se=%.5f n=%d\n", nm, ifelse(is.null(x$ame), x$b, x$ame), x$se, x$n))
for (nm in c("A1","A2","A3","A4","A5","A6","B1","B2","B3","B4","B5","B6")) pr(nm, get(nm))

cat(sprintf("RESULT:treatment_married_commoner_table2_panelA_col1=%.6f\n", A1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelA_col2=%.6f\n", A2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelA_col3=%.6f\n", A3$b))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4=%.6f\n", A4$b))
cat(sprintf("RESULT:treatment_married_down_table2_panelA_col5=%.6f\n", A5$ame))
cat(sprintf("RESULT:treatment_never_married_table2_panelA_col6=%.6f\n", A6$ame))
cat(sprintf("RESULT:treatment_married_commoner_table2_panelB_col1=%.6f\n", B1$ame))
cat(sprintf("RESULT:treatment_married_heir_table2_panelB_col2=%.6f\n", B2$ame))
cat(sprintf("RESULT:treatment_landholdings_diff_abs_table2_panelB_col3=%.6f\n", B3$b))
cat(sprintf("RESULT:treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4=%.6f\n", B4$b))
cat(sprintf("RESULT:n_obs_table2_panelA_baseline=%d\n", A1$n))
cat(sprintf("RESULT:n_obs_table2_panelA_landholdings=%d\n", A3$n))
cat(sprintf("RESULT:n_obs_table2_panelA_never_married=%d\n", A6$n))
