suppressPackageStartupMessages({library(haven); library(fixest); library(rdrobust)})
set.seed(42)
P <- '<repo>/benchmark/.cache/claude-code/hollyer-2022-parties-as-disciplinarians/independent/2026-11-02-b/mount/hollyer_2022_parties_as_disciplinarians/'
d <- as.data.frame(zap_labels(read_dta(paste0(P, 'cross-national-data.dta'))))
d$ethnic_d <- as.numeric(d$ethnic > 0.5)
d$system_f <- factor(d$system); d$cl_f <- factor(d$cl)
covs <- c('partysize','unions','business','religious','pluralty','pr','cl_f','mdmh','polity','demsys','system_f','gdppc','gini','ethfrac')
base <- c('personal','programmatic','ev_total', covs, 'ccode')
s0 <- d[complete.cases(d[, base]), ]
cat('Overall sample N =', nrow(s0), 'countries =', length(unique(s0$ccode)), '\n')
q <- quantile(s0$ev_total, c(.25,.75), type = 2); lo <- q[1]; hi <- q[2]
cat('Volatility p25/p75:', lo, hi, '\n')
rhs <- paste(covs, collapse=' + ')
fit <- function(y, extra, dat) feols(as.formula(paste(y, '~', extra, '+', rhs)), data=dat, cluster=~ccode)
# Overall
res <- list()
for (y in c('personal','programmatic')) {
  m <- fit(y, 'ev_total', s0)
  b <- coef(m)['ev_total']
  res[[paste0(y,'_overall')]] <- b*(hi-lo)
}
# Ethnic
s1 <- d[complete.cases(d[, c(base,'ethnic_d')]), ]
cat('Ethnic sample N =', nrow(s1), '\n')
eth <- list()
for (y in c('personal','programmatic')) {
  m <- fit(y, 'ev_total*ethnic_d', s1); b <- coef(m)
  eth[[y]] <- c(non_diff = unname(b['ev_total']*(hi-lo)),
                diff_lo = unname(b['ethnic_d'] + b['ev_total:ethnic_d']*lo),
                diff_hi = unname(b['ethnic_d'] + b['ev_total:ethnic_d']*hi))
  print(eth[[y]])
}
# Ideology
s2 <- d[complete.cases(d[, c(base,'extremist2')]), ]
cat('Ideology sample N =', nrow(s2), '\n')
ide <- list()
for (y in c('personal','programmatic')) {
  m <- fit(y, 'ev_total*extremist2', s2); b <- coef(m)
  ide[[y]] <- c(mod_diff = unname(b['ev_total']*(hi-lo)),
                diff_lo = unname(3*(b['extremist2'] + b['ev_total:extremist2']*lo)),
                diff_hi = unname(3*(b['extremist2'] + b['ev_total:extremist2']*hi)))
  print(ide[[y]])
}
# Brazil RD, open-seat sample
br <- as.data.frame(zap_labels(read_dta(paste0(P, 'brazil-RD-data.dta'))))
bo <- subset(br, dlameduck_runs == 0)
r1 <- rdrobust(bo$youngF_inc_for1, bo$mv_incparty, c = 0); summary(r1)
r2 <- rdrobust(bo$outyg1F_inc_for1, bo$mv_incparty, c = 0); summary(r2)
f <- function(x) format(round(as.numeric(x), 4), nsmall = 4)
cat('RESULT:personalism_volatility_difference_overall=', f(res$personal_overall), '\n', sep='')
cat('RESULT:programmaticness_volatility_difference_overall=', f(res$programmatic_overall), '\n', sep='')
cat('RESULT:personalism_volatility_difference_nonethnic=', f(eth$personal['non_diff']), '\n', sep='')
cat('RESULT:programmaticness_volatility_difference_nonethnic=', f(eth$programmatic['non_diff']), '\n', sep='')
cat('RESULT:personalism_ethnic_minus_nonethnic_low_volatility=', f(eth$personal['diff_lo']), '\n', sep='')
cat('RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=', f(eth$programmatic['diff_hi']), '\n', sep='')
cat('RESULT:personalism_volatility_difference_moderate=', f(ide$personal['mod_diff']), '\n', sep='')
cat('RESULT:programmaticness_volatility_difference_moderate=', f(ide$programmatic['mod_diff']), '\n', sep='')
cat('RESULT:personalism_extremist_minus_moderate_low_volatility=', f(ide$personal['diff_lo']), '\n', sep='')
cat('RESULT:programmaticness_extremist_minus_moderate_high_volatility=', f(ide$programmatic['diff_hi']), '\n', sep='')
cat('RESULT:n_obs_table1=', nrow(s0), '\n', sep='')
cat('RESULT:rd_effect_young=', f(r1$coef[1]), '\n', sep='')
cat('RESULT:rd_effect_young_outsider=', f(r2$coef[1]), '\n', sep='')
