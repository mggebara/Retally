# Independent, blind reproduction of Molina-Garzon et al. (2022), Tables 2 and 3.
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/blind/2026-11-07-a/mount/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS of per-round contributions ----------------
g <- zap_labels(read_dta(file.path(D, "publicgoodgame_dataAug27.dta")))
# p_type numeric codes 1..4 = A (mayor's office, reference), C (health center),
# G (administrative intermediary), R (regional office) -- alphabetical order of the
# codebook letters; row counts (C largest, A smallest) are consistent with this.
g <- g %>% mutate(pt_C = as.numeric(p_type == 2), pt_G = as.numeric(p_type == 3),
                  pt_R = as.numeric(p_type == 4))
vars2 <- c("contribution","decentralized","communication","pt_C","pt_G","pt_R","round",
           "lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
           "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
d2 <- g[complete.cases(g[, vars2]), ]
f1 <- contribution ~ decentralized + communication + pt_C + pt_G + pt_R + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- update(f1, . ~ . + decentralized:communication)
m1 <- lm(f1, data = d2, weights = weights_games_full_scaled)
m2 <- lm(f2, data = d2, weights = weights_games_full_scaled)
print(coeftest(m1, vcov = vcovCL(m1, cluster = ~publicid_muni, type = "HC1")))
print(coeftest(m2, vcov = vcovCL(m2, cluster = ~publicid_muni, type = "HC1")))
cat("municipalities in Table 2 sample:", length(unique(d2$publicid_muni)), "\n")

## ---------------- Table 3: weighted Poisson with offset ----------------
cl <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
cl <- cl[!is.na(cl$weights_games_full_scaled), ]
fitp <- function(fml, dat) {
  # quasipoisson gives the identical point estimates to a weighted Poisson
  # without warnings about non-integer weights
  m <- glm(fml, data = dat, family = quasipoisson(link = "log"),
           weights = weights_games_full_scaled)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = dat$publicid_muni, type = "HC0"))
  print(ct); m
}
ctrl <- "+ Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R"
fk_b <- as.formula("net_crosslevel_propnumknown ~ decentralized + offset(log(net_crosslevel_propdenomknown))")
fk_f <- as.formula(paste("net_crosslevel_propnumknown ~ decentralized", ctrl, "+ offset(log(net_crosslevel_propdenomknown))"))
ff_b <- as.formula("net_crosslevel_propnumfriends ~ decentralized + offset(log(net_crosslevel_propdenomfriends))")
ff_f <- as.formula(paste("net_crosslevel_propnumfriends ~ decentralized", ctrl, "+ offset(log(net_crosslevel_propdenomfriends))"))
full_vars <- c("Mujer","Q2_Educacion","Q1_Edad","Q3_YrsSalud","gen_trust")
clf <- cl[complete.cases(cl[, full_vars]), ]
mkb <- fitp(fk_b, cl); mkf <- fitp(fk_f, clf); mfb <- fitp(ff_b, cl); mff <- fitp(ff_f, clf)

cat(sprintf("RESULT:decentralized_table2_col1=%.6f\n", coef(m1)["decentralized"]))
cat(sprintf("RESULT:communication_table2_col1=%.6f\n", coef(m1)["communication"]))
cat(sprintf("RESULT:decentralized_table2_col2=%.6f\n", coef(m2)["decentralized"]))
cat(sprintf("RESULT:communication_table2_col2=%.6f\n", coef(m2)["communication"]))
cat(sprintf("RESULT:decentralized_x_communication_table2_col2=%.6f\n", coef(m2)["decentralized:communication"]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:decentralized_table3_allties_base=%.6f\n", coef(mkb)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_allties_full=%.6f\n", coef(mkf)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_strongties_base=%.6f\n", coef(mfb)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_strongties_full=%.6f\n", coef(mff)["decentralized"]))
cat(sprintf("RESULT:n_obs_table3_base=%d\n", nrow(cl)))
cat(sprintf("RESULT:n_obs_table3_full=%d\n", nrow(clf)))
