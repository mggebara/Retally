suppressPackageStartupMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/independent/2026-11-06-a/mount/molina_garzon_2022_decentralization_cooperation"
# ---- Table 2: weighted OLS of per-round contribution ----
g <- zap_labels(read_dta(file.path(D, "publicgoodgame_dataAug27.dta")))
# p_type: 1=A (mayor's office, reference), 2=C health center, 3=G admin intermediary, 4=R regional
g$ptype <- factor(g$p_type, levels = 1:4, labels = c("A","C","G","R"))
f1 <- contribution ~ decentralized + communication + ptype + round + lag_groupcontribution +
  num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- update(f1, . ~ . + decentralized:communication)
m1 <- lm(f1, data = g, weights = weights_games_full_scaled)
m2 <- lm(f2, data = g, weights = weights_games_full_scaled)
print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))
print(coeftest(m2, vcov = vcovHC(m2, type = "HC1")))
# ---- Table 3: weighted Poisson with offset, municipality-clustered SEs ----
cl <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
cl$ptype <- factor(cl$ParticipantType, levels = c("A","C","G","R"))
cl <- cl[!is.na(cl$weights_games_full_scaled), ]
fitp <- function(y, den, full) {
  rhs <- if (full) "decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + ptype" else "decentralized"
  f <- as.formula(paste0(y, " ~ ", rhs, " + offset(log(", den, "))"))
  m <- suppressWarnings(glm(f, family = poisson, data = cl, weights = weights_games_full_scaled))
  print(coeftest(m, vcov = vcovCL(m, cluster = ~publicid_muni)))
  m
}
kb <- fitp("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", FALSE)
kf <- fitp("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", TRUE)
sb <- fitp("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", FALSE)
sf <- fitp("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", TRUE)
r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("decentralized_table2_col1", coef(m1)["decentralized"])
r("communication_table2_col1", coef(m1)["communication"])
r("decentralized_table2_col2", coef(m2)["decentralized"])
r("communication_table2_col2", coef(m2)["communication"])
r("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
r("n_obs_table2", nobs(m1))
r("decentralized_table3_allties_base", coef(kb)["decentralized"])
r("decentralized_table3_allties_full", coef(kf)["decentralized"])
r("decentralized_table3_strongties_base", coef(sb)["decentralized"])
r("decentralized_table3_strongties_full", coef(sf)["decentralized"])
r("n_obs_table3_base", length(kb$y))
r("n_obs_table3_full", length(kf$y))
