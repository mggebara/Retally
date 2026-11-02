suppressPackageStartupMessages({library(haven); library(fixest); library(rdrobust)})
set.seed(42)
dd <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-b/mount/hollyer_2022_parties_as_disciplinarians"

## ---------- Table 1 (cross-national) ----------
d <- zap_labels(read_dta(file.path(dd, "cross-national-data.dta")))
d <- as.data.frame(d)
d$gini <- d$gini / 100
d$pr_f <- factor(d$pr)
d$cl_f <- relevel(factor(d$cl), ref = "3")
d$system_f <- relevel(factor(d$system), ref = "1")
ctrl <- "partysize + unions + business + religious + pluralty + pr_f + cl_f + mdmh + system_f + demsys + polity + gdppc + gini + ethfrac"
# Stata `summarize, detail` percentiles == R quantile type 2
sp <- function(x, p) unname(quantile(x, p, type = 2))

fit <- function(f) feols(as.formula(f), data = d, cluster = ~ccode)
esamp <- function(m) d[obs(m), ]

res <- list()
## overall: margins at ev_total = (p25, p75); linear model -> difference = b_ev * (p75 - p25)
for (y in c("personal", "programmatic")) {
  m <- fit(paste(y, "~ ev_total +", ctrl))
  s <- esamp(m); lov <- sp(s$ev_total, .25); hiv <- sp(s$ev_total, .75)
  res[[paste0(y, "_overall")]] <- unname(coef(m)["ev_total"] * (hiv - lov))
  if (y == "personal") { n1 <- nobs(m); cat("N =", nobs(m), " countries =", length(unique(s$ccode)), " lov/hiv =", lov, hiv, "\n") }
}
## interactions: margins at z=(0, p90(z)), ev=(p25, p75); linear model -> contrasts of coefficients
inter <- function(y, z) {
  m <- fit(paste0(y, " ~ ", z, " * ev_total + ", ctrl))
  s <- esamp(m); hia <- sp(s[[z]], .90); lov <- sp(s$ev_total, .25); hiv <- sp(s$ev_total, .75)
  b <- coef(m); bi <- b[paste0(z, ":ev_total")]
  cat(y, z, ": N =", nobs(m), " hia =", hia, " lov/hiv =", lov, hiv, "\n")
  c(low_diff = unname(b["ev_total"] * (hiv - lov)),
    high_diff = unname((b["ev_total"] + bi * hia) * (hiv - lov)),
    grp_low = unname(b[z] * hia + bi * hia * lov),
    grp_high = unname(b[z] * hia + bi * hia * hiv))
}
e_p <- inter("personal", "ethnic"); e_g <- inter("programmatic", "ethnic")
x_p <- inter("personal", "extremist2"); x_g <- inter("programmatic", "extremist2")
print(rbind(e_p, e_g, x_p, x_g))

## ---------- Table 2 (Brazil RD) ----------
b <- zap_labels(read_dta(file.path(dd, "brazil-RD-data.dta")))
idx <- b$dlameduck_runs == 0 & !is.na(b$dlameduck_runs)
r1 <- rdrobust(y = b$youngF_inc_for1[idx], x = b$mv_incparty[idx])
r2 <- rdrobust(y = b$outyg1F_inc_for1[idx], x = b$mv_incparty[idx])
cat("RD young: est", r1$Estimate[1], "h", r1$bws["h",1], "N", r1$N_h, "\n")
cat("RD young outsider: est", r2$Estimate[1], "h", r2$bws["h",1], "N", r2$N_h, "\n")

out <- list(
  personalism_volatility_difference_overall = res$personal_overall,
  programmaticness_volatility_difference_overall = res$programmatic_overall,
  personalism_volatility_difference_nonethnic = e_p[["low_diff"]],
  programmaticness_volatility_difference_nonethnic = e_g[["low_diff"]],
  personalism_ethnic_minus_nonethnic_low_volatility = e_p[["grp_low"]],
  programmaticness_ethnic_minus_nonethnic_high_volatility = e_g[["grp_high"]],
  personalism_volatility_difference_moderate = x_p[["low_diff"]],
  programmaticness_volatility_difference_moderate = x_g[["low_diff"]],
  personalism_extremist_minus_moderate_low_volatility = x_p[["grp_low"]],
  programmaticness_extremist_minus_moderate_high_volatility = x_g[["grp_high"]],
  n_obs_table1 = n1,
  rd_effect_young = r1$Estimate[1],
  rd_effect_young_outsider = r2$Estimate[1])
for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(out[[k]])))
