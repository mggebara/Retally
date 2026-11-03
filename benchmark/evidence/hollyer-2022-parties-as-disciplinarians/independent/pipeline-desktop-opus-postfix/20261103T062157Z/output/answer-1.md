suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})
set.seed(42)

base <- "<repo>/.cache/datasets/hollyer_2022_parties_as_disciplinarians.script-free"

strip <- function(d) {
  d <- as.data.frame(zap_labels(zap_formats(d)))
  d
}

# ------------------------------------------------------------------
# Cross-national analysis (Table 1)
# ------------------------------------------------------------------
cn <- strip(read_dta(file.path(base, "cross-national-data.dta")))
cat(sprintf("SAMPLE:table1:loaded=%d\n", nrow(cn)))

# Volatility rescaled to 0-1
if (max(cn$ev_total, na.rm = TRUE) > 1.5) cn$ev_total <- cn$ev_total / 100
cn$vol <- cn$ev_total

# Ethnic party: binary (majority of experts report ethnic ties)
eth_vals <- unique(na.omit(cn$ethnic))
if (all(eth_vals %in% c(0, 1))) {
  cn$ethnic_party <- cn$ethnic
} else if (max(eth_vals) <= 1) {
  cn$ethnic_party <- as.numeric(cn$ethnic > 0.5)
} else {
  # 1-4 scale style item: majority -> above midpoint
  cn$ethnic_party <- as.numeric(cn$ethnic > 2.5)
}
cn$ethnic_party[is.na(cn$ethnic)] <- NA

cn$extreme <- cn$extremist2

# Economic development (log GDP per capita if in levels)
if (all(cn$gdppc > 0, na.rm = TRUE) && max(cn$gdppc, na.rm = TRUE) > 100) {
  cn$lgdppc <- log(cn$gdppc)
} else {
  cn$lgdppc <- cn$gdppc
}

# Categorical controls: ballot rules and separation-of-powers
mk_factor <- function(x) {
  u <- sort(unique(na.omit(x)))
  if (length(u) > 2) factor(x) else x
}
cn$cl_f <- mk_factor(cn$cl)
cn$system_f <- mk_factor(cn$system)

party_ctrl <- c("partysize", "unions", "business", "religious")
country_ctrl <- c("pluralty", "pr", "cl_f", "mdmh", "polity", "demsys",
                  "system_f", "lgdppc", "gini", "ethfrac")
ctrl <- c(party_ctrl, country_ctrl)

need <- c("personal", "programmatic", "vol", party_ctrl,
          "pluralty", "pr", "cl", "mdmh", "polity", "demsys", "system",
          "lgdppc", "gini", "ethfrac", "ccode")
d1 <- cn[complete.cases(cn[, need]), ]
cat(sprintf("SAMPLE:table1:complete_outcomes_volatility_covariates=%d\n", nrow(d1)))
d1 <- d1[complete.cases(d1[, c("ethnic_party", "extreme")]), ]
cat(sprintf("SAMPLE:table1:complete_group_attachments=%d\n", nrow(d1)))
if (nrow(d1) != 431) {
  cat(sprintf("DEVIATION: complete-case sample has %d parties, paper reports 431\n", nrow(d1)))
}

rhs <- paste(ctrl, collapse = " + ")
f_base <- function(y) as.formula(paste(y, "~ vol +", rhs))
f_eth <- function(y) as.formula(paste(y, "~ vol * ethnic_party +", rhs))
f_ext <- function(y) as.formula(paste(y, "~ vol * extreme +", rhs))

fit <- function(f) feols(f, data = d1, cluster = ~ccode)

m_p  <- fit(f_base("personal"))
m_g  <- fit(f_base("programmatic"))
me_p <- fit(f_eth("personal"))
me_g <- fit(f_eth("programmatic"))
mx_p <- fit(f_ext("personal"))
mx_g <- fit(f_ext("programmatic"))

cat(sprintf("SAMPLE:table1:estimation=%d\n", nobs(m_p)))
cat(sprintf("SAMPLE:table1_ethnic:loaded=%d\n", nrow(cn)))
cat(sprintf("SAMPLE:table1_ethnic:estimation=%d\n", nobs(me_p)))
cat(sprintf("SAMPLE:table1_ideology:loaded=%d\n", nrow(cn)))
cat(sprintf("SAMPLE:table1_ideology:estimation=%d\n", nobs(mx_p)))

q25 <- as.numeric(quantile(d1$vol, 0.25))
q75 <- as.numeric(quantile(d1$vol, 0.75))
dq <- q75 - q25
ext_level <- 3

cf <- function(m, v) unname(coef(m)[v])
int_name <- function(m, a, b) {
  nm <- names(coef(m))
  c1 <- paste0(a, ":", b); c2 <- paste0(b, ":", a)
  if (c1 %in% nm) c1 else c2
}

pers_overall <- cf(m_p, "vol") * dq
prog_overall <- cf(m_g, "vol") * dq

pers_noneth <- cf(me_p, "vol") * dq
prog_noneth <- cf(me_g, "vol") * dq
pers_eth_low <- cf(me_p, "ethnic_party") + cf(me_p, int_name(me_p, "vol", "ethnic_party")) * q25
prog_eth_high <- cf(me_g, "ethnic_party") + cf(me_g, int_name(me_g, "vol", "ethnic_party")) * q75

pers_mod <- cf(mx_p, "vol") * dq
prog_mod <- cf(mx_g, "vol") * dq
pers_ext_low <- ext_level * (cf(mx_p, "extreme") + cf(mx_p, int_name(mx_p, "vol", "extreme")) * q25)
prog_ext_high <- ext_level * (cf(mx_g, "extreme") + cf(mx_g, int_name(mx_g, "vol", "extreme")) * q75)

# ------------------------------------------------------------------
# Brazil RD (Table 2)
# ------------------------------------------------------------------
br <- strip(read_dta(file.path(base, "brazil-RD-data.dta")))
cat(sprintf("SAMPLE:rd_young:loaded=%d\n", nrow(br)))
br_open <- br[!is.na(br$dlameduck_runs) & br$dlameduck_runs == 0, ]
cat(sprintf("SAMPLE:rd_young:open_seat_incumbent_not_running=%d\n", nrow(br_open)))

run_rd <- function(y, x) {
  ok <- !is.na(y) & !is.na(x)
  rdrobust(y = y[ok], x = x[ok], c = 0, p = 1, kernel = "triangular", bwselect = "mserd")
}

rd_y <- run_rd(br_open$youngF_inc_for1, br_open$mv_incparty)
ny <- sum(rd_y$N_h)
cat(sprintf("SAMPLE:rd_young:nonmissing=%d\n", sum(!is.na(br_open$youngF_inc_for1) & !is.na(br_open$mv_incparty))))
cat(sprintf("SAMPLE:rd_young:estimation=%d\n", ny))

cat(sprintf("SAMPLE:rd_young_outsider:loaded=%d\n", nrow(br)))
cat(sprintf("SAMPLE:rd_young_outsider:open_seat_incumbent_not_running=%d\n", nrow(br_open)))
rd_yo <- run_rd(br_open$outyg1F_inc_for1, br_open$mv_incparty)
cat(sprintf("SAMPLE:rd_young_outsider:nonmissing=%d\n", sum(!is.na(br_open$outyg1F_inc_for1) & !is.na(br_open$mv_incparty))))
cat(sprintf("SAMPLE:rd_young_outsider:estimation=%d\n", sum(rd_yo$N_h)))

tau_y <- unname(rd_y$coef[1, 1])
tau_yo <- unname(rd_yo$coef[1, 1])

# ------------------------------------------------------------------
# Results
# ------------------------------------------------------------------
cat(sprintf("RESULT:personalism_volatility_difference_overall=%.6f\n", pers_overall))
cat(sprintf("RESULT:programmaticness_volatility_difference_overall=%.6f\n", prog_overall))
cat(sprintf("RESULT:personalism_volatility_difference_nonethnic=%.6f\n", pers_noneth))
cat(sprintf("RESULT:programmaticness_volatility_difference_nonethnic=%.6f\n", prog_noneth))
cat(sprintf("RESULT:personalism_ethnic_minus_nonethnic_low_volatility=%.6f\n", pers_eth_low))
cat(sprintf("RESULT:programmaticness_ethnic_minus_nonethnic_high_volatility=%.6f\n", prog_eth_high))
cat(sprintf("RESULT:personalism_volatility_difference_moderate=%.6f\n", pers_mod))
cat(sprintf("RESULT:programmaticness_volatility_difference_moderate=%.6f\n", prog_mod))
cat(sprintf("RESULT:personalism_extremist_minus_moderate_low_volatility=%.6f\n", pers_ext_low))
cat(sprintf("RESULT:programmaticness_extremist_minus_moderate_high_volatility=%.6f\n", prog_ext_high))
cat(sprintf("RESULT:n_obs_table1=%d\n", nobs(m_p)))
cat(sprintf("RESULT:rd_effect_young=%.6f\n", tau_y))
cat(sprintf("RESULT:rd_effect_young_outsider=%.6f\n", tau_yo))
