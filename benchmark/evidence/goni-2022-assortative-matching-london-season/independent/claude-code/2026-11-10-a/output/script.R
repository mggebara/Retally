# Goni (2022) Table 2, Panels A and B: independent reproduction from the paper text.
# Probit (eq. 2) with average marginal effects of the treatment; OLS (eq. 3).
# Controls: Duke/Marquess/Earl daughter (pr4), English peerage (hengpee), birth order excl. heirs (biorder).
# Panel B adds distance from family seat to London (distlondon); sample = non-missing distance.
# Standard errors clustered by birth year (byear).
suppressMessages({library(haven); library(sandwich)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/goni-2022-assortative-matching-london-season/independent/2026-11-10-a/mount/goni_2022_assortative_matching_london_season/data/final-data.dta"
keep <- c("base_sample","marital_rates_sample","syntheticT","cOut","mheir","fdown","celibacy",
          "fmissmatch","fmissmatch2","pr4","hengpee","biorder","distlondon","byear","nmarriages")
d <- as.data.frame(zap_labels(read_dta(D, col_select = tidyselect::all_of(keep))))

base <- d[d$base_sample == 1, ]
land <- base[!is.na(base$fmissmatch), ]
nev  <- d[d$marital_rates_sample == 1, ]
cat("N base:", nrow(base), " N land:", nrow(land), " N never-married sample:", nrow(nev), "\n")
cat("celibacy in never-married sample:\n"); print(table(nev$celibacy, useNA = "a"))
if (!all(nev$celibacy %in% c(0, 1))) { cat("celibacy not 0/1; using nmarriages==0\n"); nev$celibacy <- as.numeric(nev$nmarriages == 0) }
print(table(celib = nev$celibacy, nm0 = nev$nmarriages == 0, useNA = "a"))

ctrl <- "pr4 + hengpee + biorder"

ame_probit <- function(y, dat, dist = FALSE) {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, if (dist) "+ distlondon" else ""))
  vars <- all.vars(f); dat <- dat[complete.cases(dat[, c(vars, "byear")]), ]
  m <- glm(f, family = binomial(link = "probit"), data = dat)
  X <- model.matrix(m); b <- coef(m); xb <- drop(X %*% b)
  ame <- mean(dnorm(xb)) * b["syntheticT"]
  # delta-method SE with clustered vcov
  V <- vcovCL(m, cluster = dat$byear, type = "HC1")
  g <- mean(dnorm(xb)) * (names(b) == "syntheticT") - b["syntheticT"] * colMeans(xb * dnorm(xb) * X)
  se <- sqrt(drop(t(g) %*% V %*% g))
  pc <- mean((fitted(m) > 0.5) == (dat[[y]] == 1)) * 100
  list(est = unname(ame), se = se, n = nrow(dat), pc = pc, mean = mean(dat[[y]]))
}
ols <- function(y, dat, dist = FALSE) {
  f <- as.formula(paste(y, "~ syntheticT +", ctrl, if (dist) "+ distlondon" else ""))
  vars <- all.vars(f); dat <- dat[complete.cases(dat[, c(vars, "byear")]), ]
  m <- lm(f, data = dat)
  V <- vcovCL(m, cluster = dat$byear, type = "HC1")
  list(est = unname(coef(m)["syntheticT"]), se = sqrt(V["syntheticT", "syntheticT"]), n = nrow(dat),
       pc = NA, mean = mean(dat[[y]]))
}

res <- list(
  A1 = ame_probit("cOut", base), A2 = ame_probit("mheir", base),
  A3 = ols("fmissmatch", land), A4 = ols("fmissmatch2", land),
  A5 = ame_probit("fdown", land), A6 = ame_probit("celibacy", nev),
  B1 = ame_probit("cOut", base, TRUE), B2 = ame_probit("mheir", base, TRUE),
  B3 = ols("fmissmatch", land, TRUE), B4 = ols("fmissmatch2", land, TRUE),
  B5 = ame_probit("fdown", land, TRUE), B6 = ame_probit("celibacy", nev, TRUE))
for (k in names(res)) with(res[[k]], cat(sprintf("%s: est=%.4f se=%.4f N=%d pctcorrect=%s mean=%.3f\n",
  k, est, se, n, ifelse(is.na(pc), "-", sprintf("%.0f", pc)), mean)))

out <- c(
  treatment_married_commoner_table2_panelA_col1 = res$A1$est,
  treatment_married_heir_table2_panelA_col2 = res$A2$est,
  treatment_landholdings_diff_abs_table2_panelA_col3 = res$A3$est,
  treatment_landholdings_diff_husband_minus_wife_table2_panelA_col4 = res$A4$est,
  treatment_married_down_table2_panelA_col5 = res$A5$est,
  treatment_never_married_table2_panelA_col6 = res$A6$est,
  treatment_married_commoner_table2_panelB_col1 = res$B1$est,
  treatment_married_heir_table2_panelB_col2 = res$B2$est,
  treatment_landholdings_diff_abs_table2_panelB_col3 = res$B3$est,
  treatment_landholdings_diff_husband_minus_wife_table2_panelB_col4 = res$B4$est,
  n_obs_table2_panelA_baseline = res$A1$n,
  n_obs_table2_panelA_landholdings = res$A3$n,
  n_obs_table2_panelA_never_married = res$A6$n)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, out[[k]]))
