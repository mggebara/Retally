set.seed(42)
library(haven); library(sandwich); library(rdrobust)
D <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-07-a/mount/hollyer_2022_parties_as_disciplinarians"
x <- as.data.frame(read_dta(file.path(D, "cross-national-data.dta")))
# Ethnic party: majority of expert coders report ethnic/linguistic linkages
x$ethnic_d <- as.numeric(x$ethnic > 0.5)
x$cl <- factor(x$cl); x$system <- factor(x$system)
# Party-level: size, unions, business, religious. Country-level: electoral system
# (plurality / PR dummies, mixed omitted), ballot rule (closed/open/non-list),
# district magnitude, polity, democratic tenure, regime system, GDP pc, Gini, ethfrac.
covs <- "partysize + unions + business + religious + pluralty + pr + cl + mdmh + polity + demsys + system + gdppc + gini + ethfrac"
base <- c("personal","programmatic","ev_total","partysize","unions","business","religious","pluralty","pr","cl","mdmh","polity","demsys","system","gdppc","gini","ethfrac","ccode")
d <- x[complete.cases(x[, c(base, "ethnic_d")]), ]
cat("N =", nrow(d), " countries =", length(unique(d$ccode)), "\n")
q <- quantile(d$ev_total, c(.25, .75)); lo <- unname(q[1]); hi <- unname(q[2])
# Linear model: predicted-value differences are linear combinations of coefficients
lc <- function(m, w) {
  b <- coef(m); V <- vcovCL(m, cluster = ~ccode, type = "HC1")
  ww <- setNames(rep(0, length(b)), names(b)); ww[names(w)] <- w
  c(est = sum(ww * b), se = sqrt(drop(t(ww) %*% V %*% ww)))
}
out <- list()
for (y in c("personal", "programmatic")) {
  m0 <- lm(as.formula(paste(y, "~ ev_total +", covs)), data = d)
  out[[paste0(y, "_overall")]] <- lc(m0, c(ev_total = hi - lo))
  m1 <- lm(as.formula(paste(y, "~ ev_total*ethnic_d +", covs)), data = d)
  out[[paste0(y, "_nonethnic")]] <- lc(m1, c(ev_total = hi - lo))
  out[[paste0(y, "_eth_lo")]] <- lc(m1, c(ethnic_d = 1, "ev_total:ethnic_d" = lo))
  out[[paste0(y, "_eth_hi")]] <- lc(m1, c(ethnic_d = 1, "ev_total:ethnic_d" = hi))
  de <- d[!is.na(d$extremist2), ]
  m2 <- lm(as.formula(paste(y, "~ ev_total*extremist2 +", covs)), data = de)
  out[[paste0(y, "_moderate")]] <- lc(m2, c(ev_total = hi - lo))
  out[[paste0(y, "_ext_lo")]] <- lc(m2, c(extremist2 = 3, "ev_total:extremist2" = 3 * lo))
  out[[paste0(y, "_ext_hi")]] <- lc(m2, c(extremist2 = 3, "ev_total:extremist2" = 3 * hi))
  cat(y, "N overall", nobs(m0), "ethnic", nobs(m1), "ideology", nobs(m2), "\n")
}
for (n in names(out)) cat(sprintf("%-25s %7.3f (%.3f)\n", n, out[[n]][1], out[[n]][2]))
# RD, Brazil mayoral elections, open-seat sample (incumbent mayor not running)
r <- as.data.frame(read_dta(file.path(D, "brazil-RD-data.dta")))
r <- r[!is.na(r$dlameduck_runs) & r$dlameduck_runs == 0, ]
rd1 <- rdrobust(r$youngF_inc_for1, r$mv_incparty, c = 0); summary(rd1)
rd2 <- rdrobust(r$outyg1F_inc_for1, r$mv_incparty, c = 0); summary(rd2)
f <- function(v) format(round(unname(v), 4), nsmall = 4)
cat("RESULT:personalism_volatility_difference_overall=", f(out$personal_overall[1]), "\n", sep = "")
cat("RESULT:programmaticness_volatility_difference_overall=", f(out$programmatic_overall[1]), "\n", sep = "")
cat("RESULT:personalism_volatility_difference_nonethnic=", f(out$personal_nonethnic[1]), "\n", sep = "")
cat("RESULT:programmaticness_volatility_difference_nonethnic=", f(out$programmatic_nonethnic[1]), "\n", sep = "")
cat("RESULT:personalism_ethnic_minus_nonethnic_low_volatility=", f(out$personal_eth_lo[1]), "\n", sep = "")
cat("RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=", f(out$programmatic_eth_hi[1]), "\n", sep = "")
cat("RESULT:personalism_volatility_difference_moderate=", f(out$personal_moderate[1]), "\n", sep = "")
cat("RESULT:programmaticness_volatility_difference_moderate=", f(out$programmatic_moderate[1]), "\n", sep = "")
cat("RESULT:personalism_extremist_minus_moderate_low_volatility=", f(out$personal_ext_lo[1]), "\n", sep = "")
cat("RESULT:programmaticness_extremist_minus_moderate_high_volatility=", f(out$programmatic_ext_hi[1]), "\n", sep = "")
cat("RESULT:n_obs_table1=", nrow(d), "\n", sep = "")
cat("RESULT:rd_effect_young=", f(rd1$coef[1]), "\n", sep = "")
cat("RESULT:rd_effect_young_outsider=", f(rd2$coef[1]), "\n", sep = "")
