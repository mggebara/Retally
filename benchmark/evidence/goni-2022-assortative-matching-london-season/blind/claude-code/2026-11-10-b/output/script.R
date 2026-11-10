# Goni (2022) Table 2 reproduction (blind, independent).
# Probit marginal effects (average marginal effects of the treatment) and OLS,
# standard errors clustered by birth year.
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/blind/2026-11-10-b/mount/goni_2022_assortative_matching_london_season"
d <- read_dta(file.path(D, "data/final-data.dta"),
              col_select = c(refno, byear, age1861, celibacy, syntheticT, cOut, mheir,
                             fdown, fmissmatch, fmissmatch2, distlondon, pr4, hengpee,
                             biorder, base_sample, marital_rates_sample))
d <- zap_labels(d)

# Treatment: synthetic probability (percent) to marry in 1861-63, as provided in the
# data (a deterministic function of age in 1861, p(t)+p(t+1)+p(t+2) from the
# 1815-1830 benchmark cohort).  Fill any missing value from the age mapping.
map <- d %>% filter(!is.na(syntheticT), !is.na(age1861)) %>% group_by(age1861) %>%
  summarise(Tm = mean(syntheticT), .groups = "drop")
d <- d %>% left_join(map, by = "age1861") %>% mutate(T = ifelse(is.na(syntheticT), Tm, syntheticT))

base <- d %>% filter(base_sample == 1)
mar  <- d %>% filter(marital_rates_sample == 1)
land <- base %>% filter(!is.na(fmissmatch), !is.na(fmissmatch2), !is.na(fdown))

ctrl <- "pr4 + hengpee + biorder"

probit_ame <- function(y, data, extra = NULL) {
  rhs <- paste(c("T", ctrl, extra), collapse = " + ")
  f <- as.formula(paste(y, "~", rhs))
  dd <- data[complete.cases(data[, all.vars(f)]), ]
  m <- glm(f, family = binomial(link = "probit"), data = dd)
  b <- coef(m); X <- model.matrix(m); xb <- drop(X %*% b)
  ame <- mean(dnorm(xb)) * b["T"]
  # delta-method clustered SE for the AME
  V <- vcovCL(m, cluster = dd$byear, type = "HC0")
  g <- colMeans(dnorm(xb) * (-xb) * b["T"] * X); g["T"] <- g["T"] + mean(dnorm(xb))
  se <- sqrt(drop(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (dd[[y]] == 1)) * 100
  cat(sprintf("  probit %-12s extra=%-10s N=%d coefT=%.4f AME=%.5f clSE=%.5f pctcorrect=%.0f meanY=%.3f\n",
              y, paste(extra, collapse=","), nrow(dd), b["T"], ame, se, pc, mean(dd[[y]])))
  list(ame = unname(ame), n = nrow(dd))
}
ols <- function(y, data, extra = NULL) {
  rhs <- paste(c("T", ctrl, extra), collapse = " + ")
  f <- as.formula(paste(y, "~", rhs))
  dd <- data[complete.cases(data[, all.vars(f)]), ]
  m <- lm(f, data = dd)
  V <- vcovCL(m, cluster = dd$byear, type = "HC1")
  cat(sprintf("  ols    %-12s extra=%-10s N=%d coefT=%.4f clSE=%.4f meanY=%.2f\n",
              y, paste(extra, collapse=","), nrow(dd), coef(m)["T"], sqrt(V["T","T"]), mean(dd[[y]])))
  list(b = unname(coef(m)["T"]), n = nrow(dd))
}

cat("Panel A\n")
a1 <- probit_ame("cOut", base)
a2 <- probit_ame("mheir", base)
a3 <- ols("fmissmatch", land)
a4 <- ols("fmissmatch2", land)
a5 <- probit_ame("fdown", land)
a6 <- probit_ame("celibacy", mar)
cat("Panel B\n")
b1 <- probit_ame("cOut", base, "distlondon")
b2 <- probit_ame("mheir", base, "distlondon")
b3 <- ols("fmissmatch", land, "distlondon")
b4 <- ols("fmissmatch2", land, "distlondon")
b5 <- probit_ame("fdown", land, "distlondon")
b6 <- probit_ame("celibacy", mar, "distlondon")

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
