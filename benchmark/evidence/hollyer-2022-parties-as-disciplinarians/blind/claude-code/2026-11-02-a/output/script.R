suppressPackageStartupMessages({library(haven); library(sandwich); library(lmtest); library(rdrobust)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/blind/2026-11-02-a/mount/hollyer_2022_parties_as_disciplinarians"

## ---- Table 1: cross-national DALP analysis ----
cn <- as.data.frame(zap_labels(read_dta(file.path(D, "cross-national-data.dta"))))
vars <- c("personal","programmatic","ev_total","partysize","unions","business","religious",
          "pluralty","pr","cl","mdmh","polity","demsys","system","gdppc","gini","ethfrac",
          "ethnic","extremist2","ccode")
d <- cn[complete.cases(cn[, vars]), ]
d$closed <- as.numeric(d$cl == 1)          # closed list (omitted: non-list)
d$open   <- as.numeric(d$cl == 2)          # open list
d$sys    <- factor(d$system)               # separation of powers (presidential omitted)
d$ethnic_party <- as.numeric(d$ethnic > 0.5)   # majority of experts report ethnic/linguistic ties
d$vol <- d$ev_total
cat("N parties:", nrow(d), " countries:", length(unique(d$ccode)), "\n")
cat("ethnic parties:", sum(d$ethnic_party), "\n")

ctrl <- "partysize + unions + business + religious + pluralty + pr + closed + open + mdmh + polity + demsys + sys + gdppc + gini + ethfrac"
q <- quantile(d$vol, c(.25, .75), type = 2)   # Stata-style percentiles, estimation sample
lo <- q[[1]]; hi <- q[[2]]
cat("volatility p25 =", lo, " p75 =", hi, "\n")

fit <- function(y, extra) {
  m <- lm(as.formula(paste(y, "~", extra, "+", ctrl)), data = d)
  V <- vcovCL(m, cluster = ~ccode, type = "HC1")
  list(m = m, V = V)
}
lincom <- function(f, w) {   # w: named vector of weights on coefficients
  b <- coef(f$m); L <- setNames(rep(0, length(b)), names(b)); L[names(w)] <- w
  est <- sum(L * b); se <- sqrt(drop(t(L) %*% f$V %*% L))
  c(est = est, se = se)
}
res <- list()
# Upper panel
for (y in c("personal","programmatic")) {
  f <- fit(y, "vol")
  r <- lincom(f, c(vol = hi - lo)); res[[paste0(y, "_overall")]] <- r
  cat(y, "overall diff (est, se):", r, "\n")
}
# Ethnicity panel
fe <- list()
for (y in c("personal","programmatic")) {
  f <- fit(y, "vol * ethnic_party"); fe[[y]] <- f
  cat(y, "nonethnic diff:", lincom(f, c(vol = hi - lo)), "\n")
  cat(y, "ethnic diff:", lincom(f, c(vol = hi - lo, `vol:ethnic_party` = hi - lo)), "\n")
  cat(y, "eth-noneth low:", lincom(f, c(ethnic_party = 1, `vol:ethnic_party` = lo)), "\n")
  cat(y, "eth-noneth high:", lincom(f, c(ethnic_party = 1, `vol:ethnic_party` = hi)), "\n")
}
# Ideology panel (extremist = distance 3, moderate = 0)
fx <- list()
for (y in c("personal","programmatic")) {
  f <- fit(y, "vol * extremist2"); fx[[y]] <- f
  cat(y, "moderate diff:", lincom(f, c(vol = hi - lo)), "\n")
  cat(y, "extremist diff:", lincom(f, c(vol = hi - lo, `vol:extremist2` = 3 * (hi - lo))), "\n")
  cat(y, "ext-mod low:", lincom(f, c(extremist2 = 3, `vol:extremist2` = 3 * lo)), "\n")
  cat(y, "ext-mod high:", lincom(f, c(extremist2 = 3, `vol:extremist2` = 3 * hi)), "\n")
}

## ---- Table 2: Brazil RD ----
rd <- as.data.frame(zap_labels(read_dta(file.path(D, "brazil-RD-data.dta"))))
os <- subset(rd, dlameduck_runs == 0)   # open-seat sample: winner at t not term-limited at t+1
r1 <- rdrobust(os$youngF_inc_for1, os$mv_incparty, c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
r2 <- rdrobust(os$outyg1F_inc_for1, os$mv_incparty, c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
summary(r1); summary(r2)

cat(sprintf("RESULT:personalism_volatility_difference_overall=%.6f\n", res$personal_overall["est"]))
cat(sprintf("RESULT:programmaticness_volatility_difference_overall=%.6f\n", res$programmatic_overall["est"]))
cat(sprintf("RESULT:personalism_volatility_difference_nonethnic=%.6f\n", lincom(fe$personal, c(vol = hi - lo))["est"]))
cat(sprintf("RESULT:programmaticness_volatility_difference_nonethnic=%.6f\n", lincom(fe$programmatic, c(vol = hi - lo))["est"]))
cat(sprintf("RESULT:personalism_ethnic_minus_nonethnic_low_volatility=%.6f\n", lincom(fe$personal, c(ethnic_party = 1, `vol:ethnic_party` = lo))["est"]))
cat(sprintf("RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=%.6f\n", lincom(fe$programmatic, c(ethnic_party = 1, `vol:ethnic_party` = hi))["est"]))
cat(sprintf("RESULT:personalism_volatility_difference_moderate=%.6f\n", lincom(fx$personal, c(vol = hi - lo))["est"]))
cat(sprintf("RESULT:programmaticness_volatility_difference_moderate=%.6f\n", lincom(fx$programmatic, c(vol = hi - lo))["est"]))
cat(sprintf("RESULT:personalism_extremist_minus_moderate_low_volatility=%.6f\n", lincom(fx$personal, c(extremist2 = 3, `vol:extremist2` = 3 * lo))["est"]))
cat(sprintf("RESULT:programmaticness_extremist_minus_moderate_high_volatility=%.6f\n", lincom(fx$programmatic, c(extremist2 = 3, `vol:extremist2` = 3 * hi))["est"]))
cat(sprintf("RESULT:n_obs_table1=%d\n", nrow(d)))
cat(sprintf("RESULT:rd_effect_young=%.6f\n", r1$coef[1]))
cat(sprintf("RESULT:rd_effect_young_outsider=%.6f\n", r2$coef[1]))
