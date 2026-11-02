suppressPackageStartupMessages({
  library(haven)
  library(sandwich)
  library(lmtest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians"

# ---------------- Cross-national (Table 1) ----------------
cn <- as.data.frame(zap_labels(read_dta(file.path(base, "cross-national-data.dta"))))
for (v in names(cn)) if (!is.numeric(cn[[v]])) suppressWarnings(cn[[v]] <- as.numeric(cn[[v]]))
cn$gini <- cn$gini / 100

# Stata summarize, detail percentile definition
stata_pct <- function(x, p) {
  x <- sort(x[!is.na(x)]); n <- length(x)
  np <- n * p / 100
  i <- floor(np); h <- np - i
  if (h > 1e-12) return(x[i + 1])
  if (i <= 0) return(x[1])
  if (i >= n) return(x[n])
  (x[i] + x[i + 1]) / 2
}

pvars <- c("partysize", "unions", "business", "religious")
cvars <- c("pluralty", "pr", "cl", "mdmh", "system", "demsys", "polity", "gdppc", "gini", "ethfrac")
ctrl_str <- "partysize + unions + business + religious + pluralty + factor(pr) + relevel(factor(cl), ref = '3') + mdmh + relevel(factor(system), ref = '1') + demsys + polity + gdppc + gini + ethfrac"

fit_model <- function(dv, extra_vars, rhs_key) {
  need <- unique(c(dv, "ev_total", extra_vars, pvars, cvars, "ccode"))
  d <- cn[complete.cases(cn[, need]), need]
  if (!"3" %in% as.character(d$cl)) {
    ctrl <- sub("relevel\\(factor\\(cl\\), ref = '3'\\)", "factor(cl)", ctrl_str)
  } else ctrl <- ctrl_str
  if (!"1" %in% as.character(d$system)) {
    ctrl <- sub("relevel\\(factor\\(system\\), ref = '1'\\)", "factor(system)", ctrl)
  }
  f <- as.formula(paste(dv, "~", rhs_key, "+", ctrl))
  m <- lm(f, data = d)
  V <- tryCatch(vcovCL(m, cluster = d$ccode, type = "HC1"), error = function(e) vcov(m))
  list(m = m, d = d, V = V)
}

res <- list()

# Overall
for (dv in c("personal", "programmatic")) {
  fm <- fit_model(dv, character(0), "ev_total")
  b <- coef(fm$m)
  lov <- stata_pct(fm$d$ev_total, 25); hiv <- stata_pct(fm$d$ev_total, 75)
  res[[paste0(dv, "_overall")]] <- b["ev_total"] * (hiv - lov)
  if (dv == "personal") res$n_obs <- nobs(fm$m)
}

# Ethnicity
for (dv in c("personal", "programmatic")) {
  fm <- fit_model(dv, "ethnic", "ethnic * ev_total")
  b <- coef(fm$m); b[is.na(b)] <- 0
  lov <- stata_pct(fm$d$ev_total, 25); hiv <- stata_pct(fm$d$ev_total, 75)
  hia <- stata_pct(fm$d$ethnic, 90)
  bint <- b["ethnic:ev_total"]
  res[[paste0(dv, "_eth_nonethnic_diff")]] <- b["ev_total"] * (hiv - lov)
  res[[paste0(dv, "_eth_lowvol")]] <- (b["ethnic"] + bint * lov) * hia
  res[[paste0(dv, "_eth_highvol")]] <- (b["ethnic"] + bint * hiv) * hia
}

# Ideology
for (dv in c("personal", "programmatic")) {
  fm <- fit_model(dv, "extremist2", "extremist2 * ev_total")
  b <- coef(fm$m); b[is.na(b)] <- 0
  lov <- stata_pct(fm$d$ev_total, 25); hiv <- stata_pct(fm$d$ev_total, 75)
  hia <- stata_pct(fm$d$extremist2, 90)
  bint <- b["extremist2:ev_total"]
  res[[paste0(dv, "_ideo_moderate_diff")]] <- b["ev_total"] * (hiv - lov)
  res[[paste0(dv, "_ideo_lowvol")]] <- (b["extremist2"] + bint * lov) * hia
  res[[paste0(dv, "_ideo_highvol")]] <- (b["extremist2"] + bint * hiv) * hia
}

# ---------------- Brazil RD (Table 2) ----------------
rd <- as.data.frame(zap_labels(read_dta(file.path(base, "brazil-RD-data.dta"))))
idx <- !is.na(rd$dlameduck_runs) & rd$dlameduck_runs == 0
x <- rd$mv_incparty[idx]
rr1 <- rdrobust(y = rd$youngF_inc_for1[idx], x = x)
rr2 <- rdrobust(y = rd$outyg1F_inc_for1[idx], x = x)
rd_young <- rr1$Estimate[1]
rd_yo <- rr2$Estimate[1]

out <- function(name, val) cat(sprintf("RESULT:%s=%.6f\n", name, as.numeric(val)))
out("personalism_volatility_difference_overall", res$personal_overall)
out("programmaticness_volatility_difference_overall", res$programmatic_overall)
out("personalism_volatility_difference_nonethnic", res$personal_eth_nonethnic_diff)
out("programmaticness_volatility_difference_nonethnic", res$programmatic_eth_nonethnic_diff)
out("personalism_ethnic_minus_nonethnic_low_volatility", res$personal_eth_lowvol)
out("programmaticness_ethnic_minus_nonethnic_high_volatility", res$programmatic_eth_highvol)
out("personalism_volatility_difference_moderate", res$personal_ideo_moderate_diff)
out("programmaticness_volatility_difference_moderate", res$programmatic_ideo_moderate_diff)
out("personalism_extremist_minus_moderate_low_volatility", res$personal_ideo_lowvol)
out("programmaticness_extremist_minus_moderate_high_volatility", res$programmatic_ideo_highvol)
out("n_obs_table1", res$n_obs)
out("rd_effect_young", rd_young)
out("rd_effect_young_outsider", rd_yo)