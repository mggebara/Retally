# Reproduction of Table 2 (weighted OLS, public goods game) and Table 3 (weighted Poisson, cross-level ties)
# Follows Molina-Garzon et al.2020_Nov16.do (Table 2) and clanalysis_replication_vNov16.R (Table 3).
suppressPackageStartupMessages({library(haven); library(fixest); library(sandwich); library(lmtest)})
set.seed(42)
dd <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/seeded/2026-11-06-b/mount/molina_garzon_2022_decentralization_cooperation"

## Table 2: reg contribution $xlist [pweight=weights_games_full_scaled], vce(cluster publicid)
pg <- as.data.frame(zap_labels(read_dta(file.path(dd, "publicgoodgame_dataAug27.dta"))))
cat("contribution range:", range(pg$contribution, na.rm = TRUE), " rows:", nrow(pg), "\n")
print(table(pg$p_type, useNA = "ifany"))
ctrl <- "i(p_type) + round + lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base"
m1 <- feols(as.formula(paste("contribution ~ decentralized + communication +", ctrl)), data = pg,
            weights = ~weights_games_full_scaled, cluster = ~publicid)
m2 <- feols(as.formula(paste("contribution ~ decentralized*communication +", ctrl)), data = pg,
            weights = ~weights_games_full_scaled, cluster = ~publicid)
print(coeftable(m1)); print(coeftable(m2))

## Table 3: weighted Poisson with log offset; SEs clustered by municipality (clse.f: CR1 factor M/(M-1)*(N-1)/(N-K))
cl <- read.csv(file.path(dd, "clanalysis_anondata_vNov16.csv"))
fit <- function(f) {
  m <- suppressWarnings(glm(f, family = poisson, weights = weights_games_full_scaled, data = cl))
  used <- as.integer(rownames(model.frame(m)))
  print(coeftest(m, vcovCL(m, cluster = cl$publicid_muni[used], type = "HC1", cadjust = TRUE)))
  m
}
full <- "+ Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R"
kb <- fit(net_crosslevel_propnumknown ~ decentralized + offset(log(net_crosslevel_propdenomknown)))
kf <- fit(as.formula(paste("net_crosslevel_propnumknown ~ decentralized", full, "+ offset(log(net_crosslevel_propdenomknown))")))
fb <- fit(net_crosslevel_propnumfriends ~ decentralized + offset(log(net_crosslevel_propdenomfriends)))
ff <- fit(as.formula(paste("net_crosslevel_propnumfriends ~ decentralized", full, "+ offset(log(net_crosslevel_propdenomfriends))")))
cat("Table 3 N:", nobs(kb), nobs(kf), nobs(fb), nobs(ff), "\n")

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("decentralized_table2_col1", coef(m1)["decentralized"])
r("communication_table2_col1", coef(m1)["communication"])
r("decentralized_table2_col2", coef(m2)["decentralized"])
r("communication_table2_col2", coef(m2)["communication"])
r("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
r("n_obs_table2", nobs(m1))
r("decentralized_table3_allties_base", coef(kb)["decentralized"])
r("decentralized_table3_allties_full", coef(kf)["decentralized"])
r("decentralized_table3_strongties_base", coef(fb)["decentralized"])
r("decentralized_table3_strongties_full", coef(ff)["decentralized"])
r("n_obs_table3_base", nobs(kb))
r("n_obs_table3_full", nobs(kf))
