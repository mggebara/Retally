suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- '<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free'

## ---------------------------------------------------------------
## Cross-national analysis (Table 1)
## ---------------------------------------------------------------
cn <- haven::read_dta(file.path(base, 'cross-national-data.dta'))
cn <- as.data.frame(lapply(cn, function(x) { attributes(x) <- NULL; x }))
cat(sprintf('SAMPLE:table1:loaded=%d\n', nrow(cn)))

# Volatility rescaled to 0-1 (Pedersen index stored in percent if > 1)
if (max(cn$ev_total, na.rm = TRUE) > 1) cn$vol <- cn$ev_total / 100 else cn$vol <- cn$ev_total

# Ethnic party dummy: 1 if most experts report ethnic/linguistic ties
eth <- cn$ethnic
ue <- unique(na.omit(eth))
if (all(ue %in% c(0, 1))) {
  cn$ethnic_d <- eth
} else if (max(eth, na.rm = TRUE) <= 1) {
  cn$ethnic_d <- as.numeric(eth > 0.5)
} else {
  cn$ethnic_d <- as.numeric(eth > 2.5)
}

cn$extrem <- cn$extremist2

# Categorical country controls
mkfac <- function(x) if (length(unique(na.omit(x))) <= 4 && length(unique(na.omit(x))) > 2) factor(x) else x
cn$cl_f <- mkfac(cn$cl)
cn$system_f <- factor(cn$system)

ctrl_vars <- c('partysize', 'unions', 'business', 'religious',
               'pluralty', 'pr', 'cl', 'mdmh', 'polity', 'demsys', 'system',
               'gdppc', 'gini', 'ethfrac')
needed <- c('personal', 'programmatic', 'vol', 'ethnic_d', 'extrem', 'ccode', ctrl_vars)

cn_s <- cn[complete.cases(cn[, c('personal', 'programmatic')]), ]
cat(sprintf('SAMPLE:table1:nonmissing_outcomes=%d\n', nrow(cn_s)))
cn_s <- cn_s[!is.na(cn_s$vol), ]
cat(sprintf('SAMPLE:table1:nonmissing_volatility=%d\n', nrow(cn_s)))
cn_s <- cn_s[complete.cases(cn_s[, needed]), ]
cat(sprintf('SAMPLE:table1:nonmissing_covariates=%d\n', nrow(cn_s)))

ctrl_rhs <- 'partysize + unions + business + religious + pluralty + pr + cl_f + mdmh + polity + demsys + system_f + gdppc + gini + ethfrac'

fit <- function(dv, extra) {
  f <- as.formula(paste(dv, '~', extra, '+', ctrl_rhs))
  feols(f, data = cn_s, cluster = ~ccode)
}

m_p0 <- fit('personal', 'vol')
m_g0 <- fit('programmatic', 'vol')
m_pe <- fit('personal', 'vol * ethnic_d')
m_ge <- fit('programmatic', 'vol * ethnic_d')
m_px <- fit('personal', 'vol * extrem')
m_gx <- fit('programmatic', 'vol * extrem')

cat(sprintf('SAMPLE:table1:estimation=%d\n', nobs(m_p0)))
cat(sprintf('SAMPLE:table1_ethnic:loaded=%d\n', nrow(cn)))
cat(sprintf('SAMPLE:table1_ethnic:estimation=%d\n', nobs(m_pe)))
cat(sprintf('SAMPLE:table1_ideology:loaded=%d\n', nrow(cn)))
cat(sprintf('SAMPLE:table1_ideology:estimation=%d\n', nobs(m_px)))

q25 <- as.numeric(quantile(cn_s$vol, 0.25))
q75 <- as.numeric(quantile(cn_s$vol, 0.75))
dq <- q75 - q25
ext_val <- 3

b <- function(m, n) unname(coef(m)[n])

personalism_volatility_difference_overall <- b(m_p0, 'vol') * dq
programmaticness_volatility_difference_overall <- b(m_g0, 'vol') * dq
personalism_volatility_difference_nonethnic <- b(m_pe, 'vol') * dq
programmaticness_volatility_difference_nonethnic <- b(m_ge, 'vol') * dq
personalism_ethnic_minus_nonethnic_low_volatility <- b(m_pe, 'ethnic_d') + b(m_pe, 'vol:ethnic_d') * q25
programmaticness_ethnic_minus_nonethnic_high_volatility <- b(m_ge, 'ethnic_d') + b(m_ge, 'vol:ethnic_d') * q75
personalism_volatility_difference_moderate <- b(m_px, 'vol') * dq
programmaticness_volatility_difference_moderate <- b(m_gx, 'vol') * dq
personalism_extremist_minus_moderate_low_volatility <- ext_val * (b(m_px, 'extrem') + b(m_px, 'vol:extrem') * q25)
programmaticness_extremist_minus_moderate_high_volatility <- ext_val * (b(m_gx, 'extrem') + b(m_gx, 'vol:extrem') * q75)
n_obs_table1 <- nobs(m_p0)

## ---------------------------------------------------------------
## Brazil RD (Table 2)
## ---------------------------------------------------------------
rd <- haven::read_dta(file.path(base, 'brazil-RD-data.dta'))
rd <- as.data.frame(lapply(rd, function(x) { attributes(x) <- NULL; x }))
cat(sprintf('SAMPLE:table2_young:loaded=%d\n', nrow(rd)))
cat(sprintf('SAMPLE:table2_young_outsider:loaded=%d\n', nrow(rd)))

rd_open <- rd[!is.na(rd$dlameduck_runs) & rd$dlameduck_runs == 0, ]
cat(sprintf('SAMPLE:table2_young:open_seat=%d\n', nrow(rd_open)))
cat(sprintf('SAMPLE:table2_young_outsider:open_seat=%d\n', nrow(rd_open)))

d1 <- rd_open[!is.na(rd_open$youngF_inc_for1) & !is.na(rd_open$mv_incparty), ]
r1 <- rdrobust(y = d1$youngF_inc_for1, x = d1$mv_incparty, c = 0)
cat(sprintf('SAMPLE:table2_young:estimation=%d\n', sum(r1$N_h)))

d2 <- rd_open[!is.na(rd_open$outyg1F_inc_for1) & !is.na(rd_open$mv_incparty), ]
r2 <- rdrobust(y = d2$outyg1F_inc_for1, x = d2$mv_incparty, c = 0)
cat(sprintf('SAMPLE:table2_young_outsider:estimation=%d\n', sum(r2$N_h)))

rd_effect_young <- unname(r1$coef[1, 1])
rd_effect_young_outsider <- unname(r2$coef[1, 1])

## ---------------------------------------------------------------
## Results
## ---------------------------------------------------------------
out <- c(
  personalism_volatility_difference_overall = personalism_volatility_difference_overall,
  programmaticness_volatility_difference_overall = programmaticness_volatility_difference_overall,
  personalism_volatility_difference_nonethnic = personalism_volatility_difference_nonethnic,
  programmaticness_volatility_difference_nonethnic = programmaticness_volatility_difference_nonethnic,
  personalism_ethnic_minus_nonethnic_low_volatility = personalism_ethnic_minus_nonethnic_low_volatility,
  programmaticness_ethnic_minus_nonethnic_high_volatility = programmaticness_ethnic_minus_nonethnic_high_volatility,
  personalism_volatility_difference_moderate = personalism_volatility_difference_moderate,
  programmaticness_volatility_difference_moderate = programmaticness_volatility_difference_moderate,
  personalism_extremist_minus_moderate_low_volatility = personalism_extremist_minus_moderate_low_volatility,
  programmaticness_extremist_minus_moderate_high_volatility = programmaticness_extremist_minus_moderate_high_volatility,
  n_obs_table1 = n_obs_table1,
  rd_effect_young = rd_effect_young,
  rd_effect_young_outsider = rd_effect_young_outsider
)
for (nm in names(out)) cat(sprintf('RESULT:%s=%.6f\n', nm, out[[nm]]))