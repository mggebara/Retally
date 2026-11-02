# Hollyer, Klasnja & Titiunik (2022) -- independent, blind reproduction of Table 1 and Table 2
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest); library(rdrobust) })
d <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-c/mount/hollyer_2022_parties_as_disciplinarians"

## ---------------- Table 1: cross-national OLS ----------------
x <- as.data.frame(zap_labels(read_dta(file.path(d, "cross-national-data.dta"))))
x$demsys[x$demsys == -999] <- NA

# Party-level: party size, links to unions/business/religious orgs.
# Country-level: plurality & PR (mixed omitted), ballot rule (closed list cl=1 omitted; open & mixed
# dummies), mean district magnitude, Polity, length of democracy, separation of powers (system),
# GDP pc, Gini, ethnic fractionalization.
ctrl <- "partysize + unions + business + religious + pluralty + pr + i(cl, ref = 1) + mdmh + polity + demsys + i(system, ref = 0) + gdppc + gini + ethfrac"
basevars <- c("personal", "programmatic", "ev_total", "partysize", "unions", "business", "religious",
              "pluralty", "pr", "cl", "mdmh", "polity", "demsys", "system", "gdppc", "gini", "ethfrac", "ccode")
s <- x[complete.cases(x[, basevars]), ]
cat("Base sample:", nrow(s), "parties,", length(unique(s$ccode)), "countries\n")

# Stata-style percentiles (_pctile default definition = R type 2), party-level estimation sample
pct <- function(v) quantile(v, c(.25, .75), type = 2, names = FALSE)

fit <- function(y, extra, data) feols(as.formula(paste(y, "~", extra, "+", ctrl)), data = data, cluster = ~ccode)

out <- list()
for (y in c("personal", "programmatic")) {
  nm <- if (y == "personal") "personalism" else "programmaticness"
  # Upper panel
  m <- fit(y, "ev_total", s); q <- pct(s$ev_total)
  out[[paste0(nm, "_volatility_difference_overall")]] <- coef(m)["ev_total"] * (q[2] - q[1])
  cat(y, "overall: N =", nobs(m), " vol p25/p75 =", q, "\n")
  # Ethnicity panel
  se <- s[!is.na(s$ethnic), ]
  me <- fit(y, "ev_total * ethnic", se); qe <- pct(se$ev_total); b <- coef(me)
  out[[paste0(nm, "_volatility_difference_nonethnic")]] <- b["ev_total"] * (qe[2] - qe[1])
  eth_diff <- b["ethnic"] + b["ev_total:ethnic"] * qe
  if (y == "personal") out[["personalism_ethnic_minus_nonethnic_low_volatility"]] <- eth_diff[1]
  else out[["programmaticness_ethnic_minus_nonethnic_high_volatility"]] <- eth_diff[2]
  cat(y, "ethnic: N =", nobs(me), "\n")
  # Ideology panel: extremist2 = absolute distance from country mean left-right placement
  sx <- s[!is.na(s$extremist2), ]
  mx <- fit(y, "ev_total * extremist2", sx); qx <- pct(sx$ev_total); b <- coef(mx)
  out[[paste0(nm, "_volatility_difference_moderate")]] <- b["ev_total"] * (qx[2] - qx[1])
  ext_diff <- 3 * (b["extremist2"] + b["ev_total:extremist2"] * qx)
  if (y == "personal") out[["personalism_extremist_minus_moderate_low_volatility"]] <- ext_diff[1]
  else out[["programmaticness_extremist_minus_moderate_high_volatility"]] <- ext_diff[2]
  cat(y, "ideology: N =", nobs(mx), "\n")
}
out[["n_obs_table1"]] <- nrow(s)

## ---------------- Table 2: Brazil RD ----------------
r <- as.data.frame(zap_labels(read_dta(file.path(d, "brazil-RD-data.dta"))))
# Winner at t not term-limited at t+1: incumbent mayor did not run for a second term at t
ro <- r[!is.na(r$dlameduck_runs) & r$dlameduck_runs == 0, ]
rd1 <- rdrobust(ro$youngF_inc_for1, ro$mv_incparty, c = 0, p = 1, bwselect = "mserd")
rd2 <- rdrobust(ro$outyg1F_inc_for1, ro$mv_incparty, c = 0, p = 1, bwselect = "mserd")
print(summary(rd1)); print(summary(rd2))
out[["rd_effect_young"]] <- rd1$coef[1, 1]
out[["rd_effect_young_outsider"]] <- rd2$coef[1, 1]

for (k in names(out)) cat(sprintf("RESULT:%s=%.6f\n", k, as.numeric(out[[k]])))
