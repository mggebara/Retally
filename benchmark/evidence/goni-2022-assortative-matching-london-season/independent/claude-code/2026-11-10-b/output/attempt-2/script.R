# Independent reproduction of Goni (2022), Table 2 Panels A and B.
# Probit (average marginal effects) and OLS with SEs clustered by birth year.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich)})
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-b/mount/goni_2022_assortative_matching_london_season/data/final-data.dta"
keep <- c("refno","byear","wom","base_sample","marital_rates_sample","cOut","mheir","fdown",
          "fmissmatch","fmissmatch2","syntheticT","distlondon","biorder","pr4","hengpee",
          "celibacy","age1861","nthismarriage","dage")
d <- read_dta(D, col_select = all_of(keep))
d <- zap_labels(d) %>% mutate(across(everything(), as.numeric))

base <- d %>% filter(base_sample == 1)
mar  <- d %>% filter(marital_rates_sample == 1)
cat("base N:", nrow(base), " marital N:", nrow(mar), "\n")
cat("base: distinct byear", length(unique(base$byear)), " age1861 range", range(base$age1861, na.rm=TRUE), "\n")
cat("base NA counts:\n"); print(colSums(is.na(base)))
cat("marital NA counts:\n"); print(colSums(is.na(mar)))
cat("celibacy in marital sample:\n"); print(table(mar$celibacy, useNA = "ifany"))
cat("biorder dist base:\n"); print(table(base$biorder, useNA = "ifany"))

ctrl <- c("pr4", "hengpee", "biorder")

cl_vcov <- function(m, cl) sandwich::vcovCL(m, cluster = cl, type = "HC1")

probit_ame <- function(y, data, extra = NULL) {
  f <- as.formula(paste(y, "~", paste(c("syntheticT", ctrl, extra), collapse = " + ")))
  dd <- data[complete.cases(data[, all.vars(f)]), ]
  m <- glm(f, data = dd, family = binomial(link = "probit"))
  X <- model.matrix(m); b <- coef(m)
  V <- cl_vcov(m, dd$byear)
  xb <- as.vector(X %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # delta method gradient of AME wrt b
  g <- colMeans((-xb * dnorm(xb)) * b["syntheticT"] * X)
  g["syntheticT"] <- g["syntheticT"] + mean(dnorm(xb))
  se <- sqrt(as.numeric(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (dd[[y]] == 1)) * 100
  cat(sprintf("probit %-12s extra=%-10s N=%d AME=%.5f (se %.5f) coef=%.5f meanY=%.3f pctcorrect=%.0f\n",
              y, paste(extra, collapse=","), nrow(dd), ame, se, b["syntheticT"], mean(dd[[y]]), pc))
  list(ame = unname(ame), se = se, n = nrow(dd))
}
ols_fit <- function(y, data, extra = NULL) {
  f <- as.formula(paste(y, "~", paste(c("syntheticT", ctrl, extra), collapse = " + ")))
  dd <- data[complete.cases(data[, all.vars(f)]), ]
  m <- lm(f, data = dd)
  V <- cl_vcov(m, dd$byear)
  b <- coef(m)["syntheticT"]; se <- sqrt(V["syntheticT", "syntheticT"])
  cat(sprintf("ols    %-12s extra=%-10s N=%d b=%.4f (se %.4f) meanY=%.2f\n",
              y, paste(extra, collapse=","), nrow(dd), b, se, mean(dd[[y]])))
  list(b = unname(b), se = se, n = nrow(dd))
}

A1 <- probit_ame("cOut", base)
A2 <- probit_ame("mheir", base)
A3 <- ols_fit("fmissmatch", base)
A4 <- ols_fit("fmissmatch2", base)
A5 <- probit_ame("fdown", base)
A6 <- probit_ame("celibacy", mar)
B1 <- probit_ame("cOut", base, "distlondon")
B2 <- probit_ame("mheir", base, "distlondon")
B3 <- ols_fit("fmissmatch", base, "distlondon")
B4 <- ols_fit("fmissmatch2", base, "distlondon")
B5 <- probit_ame("fdown", base, "distlondon")
B6 <- probit_ame("celibacy", mar, "distlondon")

