suppressPackageStartupMessages({library(haven); library(fixest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/seeded/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians"
cn <- as.data.frame(zap_labels(read_dta(file.path(D, "cross-national-data.dta"))))
cn$gini <- cn$gini / 100
cat("cl values:", paste(sort(unique(cn$cl)), collapse=","), " system values:", paste(sort(unique(cn$system)), collapse=","), " pr:", paste(sort(unique(cn$pr)), collapse=","), "\n")
cn$cl_f <- relevel(factor(cn$cl), ref = "3")
cn$sys_f <- relevel(factor(cn$system), ref = "1")
cn$pr_f <- factor(cn$pr)
ctrl <- "partysize + unions + business + religious + pluralty + pr_f + cl_f + mdmh + sys_f + demsys + polity + gdppc + gini + ethfrac"
pct <- function(x, p) as.numeric(quantile(x, p, type = 2))  # Stata summarize, detail
fit <- function(f) feols(as.formula(f), data = cn, cluster = ~ccode)

res <- list()
## Table 1, top panel (Overall)
for (y in c("personal", "programmatic")) {
  m <- fit(paste(y, "~ ev_total +", ctrl))
  es <- cn[obs(m), ]
  lov <- pct(es$ev_total, .25); hiv <- pct(es$ev_total, .75)
  d <- unname(coef(m)["ev_total"] * (hiv - lov))
  cat(y, "overall: N =", nobs(m), " clusters =", length(unique(es$ccode)), " lov/hiv =", lov, hiv, " diff =", d, " se =", se(m)["ev_total"] * (hiv - lov), "\n")
  res[[paste0(y, "_overall")]] <- d
  res[[paste0("n_", y)]] <- nobs(m)
}
## Table 1, interaction panels (margins at z = 0 / p90(z), ev_total = p25 / p75)
gm <- function(y, z) {
  m <- fit(paste0(y, " ~ ", z, " * ev_total + ", ctrl))
  es <- cn[obs(m), ]
  hia <- pct(es[[z]], .90); lov <- pct(es$ev_total, .25); hiv <- pct(es$ev_total, .75)
  b <- coef(m); bz <- b[z]; bx <- b["ev_total"]; bi <- b[paste0(z, ":ev_total")]
  out <- c(lowz_volDiff = unname(bx * (hiv - lov)),
           highz_volDiff = unname((bx + bi * hia) * (hiv - lov)),
           zDiff_low = unname(bz * hia + bi * hia * lov),
           zDiff_high = unname(bz * hia + bi * hia * hiv))
  cat(y, z, ": N =", nobs(m), " hia =", hia, " lov/hiv =", lov, hiv, "\n"); print(round(out, 4))
  out
}
e1 <- gm("personal", "ethnic"); e2 <- gm("programmatic", "ethnic")
x1 <- gm("personal", "extremist2"); x2 <- gm("programmatic", "extremist2")

## Table 2: RD, open-seat sample, rdrobust defaults
rd <- as.data.frame(zap_labels(read_dta(file.path(D, "brazil-RD-data.dta"))))
idx <- rd$dlameduck_runs == 0 & !is.na(rd$dlameduck_runs)
r1 <- rdrobust(y = rd$youngF_inc_for1[idx], x = rd$mv_incparty[idx])
r2 <- rdrobust(y = rd$outyg1F_inc_for1[idx], x = rd$mv_incparty[idx])
cat("RD young: est", r1$Estimate[1], " h", r1$bws["h",1], " b", r1$bws["b",1], " N", r1$N_h, "\n")
cat("RD young outsider: est", r2$Estimate[1], " h", r2$bws["h",1], " b", r2$bws["b",1], " N", r2$N_h, "\n")

out <- c(
  personalism_volatility_difference_overall = res$personal_overall,
  programmaticness_volatility_difference_overall = res$programmatic_overall,
  personalism_volatility_difference_nonethnic = e1[["lowz_volDiff"]],
  programmaticness_volatility_difference_nonethnic = e2[["lowz_volDiff"]],
  personalism_ethnic_minus_nonethnic_low_volatility = e1[["zDiff_low"]],
  programmaticness_ethnic_minus_nonethnic_high_volatility = e2[["zDiff_high"]],
  personalism_volatility_difference_moderate = x1[["lowz_volDiff"]],
  programmaticness_volatility_difference_moderate = x2[["lowz_volDiff"]],
  personalism_extremist_minus_moderate_low_volatility = x1[["zDiff_low"]],
  programmaticness_extremist_minus_moderate_high_volatility = x2[["zDiff_high"]],
  n_obs_table1 = res$n_personal,
  rd_effect_young = r1$Estimate[1],
  rd_effect_young_outsider = r2$Estimate[1])
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, unname(out[[n]])))
