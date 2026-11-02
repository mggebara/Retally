suppressPackageStartupMessages({library(haven); library(sandwich); library(rdrobust)})
set.seed(42)
P <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-c/mount/hollyer_2022_parties_as_disciplinarians"
d <- as.data.frame(zap_labels(read_dta(file.path(P, "cross-national-data.dta"))))
# Table 1: party-level OLS, country-clustered SEs
d$cl_f <- factor(d$cl); d$system_f <- factor(d$system)
d$ethnic_party <- as.numeric(d$ethnic > 0.5)   # majority of experts report ethnic/linguistic ties
d$vol <- d$ev_total
base_vars <- c("personal","programmatic","vol","partysize","unions","business","religious",
               "pluralty","pr","cl_f","mdmh","polity","demsys","system_f","gdppc","gini","ethfrac","ethnic")
s <- d[complete.cases(d[, base_vars]), ]
cat("N =", nrow(s), " countries =", length(unique(s$ccode)), "\n")
q <- quantile(s$vol, c(.25, .75)); lo <- unname(q[1]); hi <- unname(q[2])
cat("volatility p25/p75:", lo, hi, "\n")
covs <- "partysize + unions + business + religious + pluralty + pr + cl_f + mdmh + polity + demsys + system_f + gdppc + gini + ethfrac"

fitm <- function(y, extra, data) {
  f <- as.formula(paste(y, "~", extra, "+", covs))
  m <- lm(f, data = data)
  V <- vcovCL(m, cluster = ~ccode, type = "HC1")
  list(m = m, V = V)
}
# difference in predictions between two configurations = w' b
contr <- function(fit, w) { b <- coef(fit$m); w2 <- setNames(rep(0, length(b)), names(b)); w2[names(w)] <- w
  c(est = sum(w2 * b), se = sqrt(drop(t(w2) %*% fit$V %*% w2))) }
dv <- hi - lo
res <- list()
for (y in c("personal", "programmatic")) {
  f0 <- fitm(y, "vol", s)
  res[[paste0(y, "_overall")]] <- contr(f0, c(vol = dv))
  fe <- fitm(y, "vol * ethnic_party", s)
  res[[paste0(y, "_nonethnic")]] <- contr(fe, c(vol = dv))
  res[[paste0(y, "_eth_lo")]] <- contr(fe, c(ethnic_party = 1, "vol:ethnic_party" = lo))
  res[[paste0(y, "_eth_hi")]] <- contr(fe, c(ethnic_party = 1, "vol:ethnic_party" = hi))
  sx <- s[!is.na(s$extremist2), ]
  fx <- fitm(y, "vol * extremist2", sx)
  res[[paste0(y, "_moderate")]] <- contr(fx, c(vol = dv))
  res[[paste0(y, "_ext_lo")]] <- contr(fx, c(extremist2 = 3, "vol:extremist2" = 3 * lo))
  res[[paste0(y, "_ext_hi")]] <- contr(fx, c(extremist2 = 3, "vol:extremist2" = 3 * hi))
}
for (n in names(res)) cat(sprintf("%-28s %8.4f (%6.4f)\n", n, res[[n]][1], res[[n]][2]))

# Table 2: RD, open-seat sample (incumbent mayor not running at t)
b <- as.data.frame(zap_labels(read_dta(file.path(P, "brazil-RD-data.dta"))))
bo <- b[!is.na(b$dlameduck_runs) & b$dlameduck_runs == 0, ]
r1 <- rdrobust(bo$youngF_inc_for1, bo$mv_incparty, c = 0)
r2 <- rdrobust(bo$outyg1F_inc_for1, bo$mv_incparty, c = 0)
summary(r1); summary(r2)

cat(sprintf("RESULT:personalism_volatility_difference_overall=%.6f\n", res$personal_overall[1]))
cat(sprintf("RESULT:programmaticness_volatility_difference_overall=%.6f\n", res$programmatic_overall[1]))
cat(sprintf("RESULT:personalism_volatility_difference_nonethnic=%.6f\n", res$personal_nonethnic[1]))
cat(sprintf("RESULT:programmaticness_volatility_difference_nonethnic=%.6f\n", res$programmatic_nonethnic[1]))
cat(sprintf("RESULT:personalism_ethnic_minus_nonethnic_low_volatility=%.6f\n", res$personal_eth_lo[1]))
cat(sprintf("RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=%.6f\n", res$programmatic_eth_hi[1]))
cat(sprintf("RESULT:personalism_volatility_difference_moderate=%.6f\n", res$personal_moderate[1]))
cat(sprintf("RESULT:programmaticness_volatility_difference_moderate=%.6f\n", res$programmatic_moderate[1]))
cat(sprintf("RESULT:personalism_extremist_minus_moderate_low_volatility=%.6f\n", res$personal_ext_lo[1]))
cat(sprintf("RESULT:programmaticness_extremist_minus_moderate_high_volatility=%.6f\n", res$programmatic_ext_hi[1]))
cat(sprintf("RESULT:n_obs_table1=%d\n", nrow(s)))
cat(sprintf("RESULT:rd_effect_young=%.6f\n", r1$coef[1]))
cat(sprintf("RESULT:rd_effect_young_outsider=%.6f\n", r2$coef[1]))
