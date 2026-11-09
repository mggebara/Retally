# Hollyer, Klasnja & Titiunik (2022) -- independent blind reproduction of Table 1 and Table 2
set.seed(42)
suppressPackageStartupMessages({ library(haven); library(fixest); library(rdrobust) })
D <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-07-a/mount/hollyer_2022_parties_as_disciplinarians"

## ---------------- Table 1: cross-national OLS ----------------
x <- as.data.frame(zap_labels(read_dta(file.path(D, "cross-national-data.dta"))))
x$eth_party <- as.numeric(x$ethnic > 0.5)          # majority of experts report ethnic/linguistic ties
x$closed    <- as.numeric(x$cl == 1)               # closed list
x$open      <- as.numeric(x$cl == 2)               # open list (non-list PR omitted)
x$sys_ae    <- as.numeric(x$system == 1)           # assembly-elected (presidential omitted)
x$sys_parl  <- as.numeric(x$system == 2)           # parliamentary
ctrl <- "partysize + unions + business + religious + pluralty + pr + closed + open + mdmh + polity + demsys + sys_ae + sys_parl + gdppc + gini + ethfrac"
base_vars <- c("personal","programmatic","ev_total","partysize","unions","business","religious",
               "pluralty","pr","cl","mdmh","polity","demsys","system","gdppc","gini","ethfrac")
s0 <- x[complete.cases(x[, base_vars]), ]
N <- nrow(s0); cat("Overall sample:", N, "parties,", length(unique(s0$ccode)), "countries\n")

# 25th / 75th percentile of volatility in the (party-level) estimation sample, Stata _pctile definition
vlo <- unname(quantile(s0$ev_total, .25, type = 2)); vhi <- unname(quantile(s0$ev_total, .75, type = 2))
cat("Volatility p25 =", vlo, " p75 =", vhi, "\n")
dv <- vhi - vlo

fitm <- function(y, extra = "", data) feols(as.formula(paste(y, "~ ev_total", extra, "+", ctrl)), data = data, cluster = ~ccode)
lincom <- function(m, w) { b <- coef(m); V <- vcov(m); w <- w[names(b)]; w[is.na(w)] <- 0
  c(est = sum(w * b), se = sqrt(drop(t(w) %*% V %*% w))) }
W <- function(...) { a <- c(...); a }

res <- list()
for (y in c("personal", "programmatic")) {
  # Overall
  m0 <- fitm(y, "", s0)
  r0 <- lincom(m0, W(ev_total = dv))
  # Ethnicity
  se <- s0[!is.na(s0$eth_party), ]
  m1 <- fitm(y, "+ eth_party + ev_total:eth_party", se)
  r1_non  <- lincom(m1, W(ev_total = dv))
  r1_lo   <- lincom(m1, W(eth_party = 1, `ev_total:eth_party` = vlo))
  r1_hi   <- lincom(m1, W(eth_party = 1, `ev_total:eth_party` = vhi))
  # Ideology (extremist at distance 3, moderate at 0)
  sx <- s0[!is.na(s0$extremist2), ]
  m2 <- fitm(y, "+ extremist2 + ev_total:extremist2", sx)
  r2_mod <- lincom(m2, W(ev_total = dv))
  r2_lo  <- lincom(m2, W(extremist2 = 3, `ev_total:extremist2` = 3 * vlo))
  r2_hi  <- lincom(m2, W(extremist2 = 3, `ev_total:extremist2` = 3 * vhi))
  cat(sprintf("\n%s: N overall=%d, ethnic=%d, ideology=%d\n", y, nobs(m0), nobs(m1), nobs(m2)))
  print(rbind(overall = r0, nonethnic = r1_non, eth_minus_non_low = r1_lo, eth_minus_non_high = r1_hi,
              moderate = r2_mod, ext_minus_mod_low = r2_lo, ext_minus_mod_high = r2_hi))
  res[[y]] <- list(r0 = r0, r1_non = r1_non, r1_lo = r1_lo, r1_hi = r1_hi, r2_mod = r2_mod, r2_lo = r2_lo, r2_hi = r2_hi)
}

## ---------------- Table 2: Brazil RD ----------------
r <- as.data.frame(zap_labels(read_dta(file.path(D, "brazil-RD-data.dta"))))
ro <- r[!is.na(r$dlameduck_runs) & r$dlameduck_runs == 0, ]   # open-seat sample
rd1 <- rdrobust(ro$youngF_inc_for1,  ro$mv_incparty, c = 0, p = 1)
rd2 <- rdrobust(ro$outyg1F_inc_for1, ro$mv_incparty, c = 0, p = 1)
summary(rd1); summary(rd2)

## ---------------- RESULTS ----------------
out <- c(
  personalism_volatility_difference_overall = res$personal$r0["est"],
  programmaticness_volatility_difference_overall = res$programmatic$r0["est"],
  personalism_volatility_difference_nonethnic = res$personal$r1_non["est"],
  programmaticness_volatility_difference_nonethnic = res$programmatic$r1_non["est"],
  personalism_ethnic_minus_nonethnic_low_volatility = res$personal$r1_lo["est"],
  programmaticness_ethnic_minus_nonethnic_high_volatility = res$programmatic$r1_hi["est"],
  personalism_volatility_difference_moderate = res$personal$r2_mod["est"],
  programmaticness_volatility_difference_moderate = res$programmatic$r2_mod["est"],
  personalism_extremist_minus_moderate_low_volatility = res$personal$r2_lo["est"],
  programmaticness_extremist_minus_moderate_high_volatility = res$programmatic$r2_hi["est"],
  n_obs_table1 = N,
  rd_effect_young = rd1$coef[1, 1],
  rd_effect_young_outsider = rd2$coef[1, 1])
names(out) <- sub("\\.est$", "", names(out))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
