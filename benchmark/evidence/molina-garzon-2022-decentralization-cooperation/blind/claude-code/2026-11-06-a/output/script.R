# Independent blind reproduction: Molina-Garzon et al. (2022), Tables 2 and 3
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest); library(sandwich); library(lmtest)})
M <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/blind/2026-11-06-a/mount/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS of per-round contributions ----------------
g <- zap_labels(read_dta(file.path(M, "publicgoodgame_dataAug27.dta")))
# p_type: 1=A (mayor's office, reference), 2=C (health center), 3=G (admin intermediary), 4=R (regional)
g <- g %>% mutate(
  player_hc = as.numeric(p_type == 2),
  player_ai = as.numeric(p_type == 3),
  player_r  = as.numeric(p_type == 4))
vars2 <- c("contribution","decentralized","communication","player_hc","player_ai","player_r",
           "round","lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
           "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
d2 <- g[complete.cases(g[vars2]), ]
f1 <- contribution ~ decentralized + communication + player_hc + player_ai + player_r + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion +
  Q3_YrsSalud + Q5_Trust1Base
f2 <- update(f1, . ~ . + decentralized:communication)
m1 <- lm(f1, data = d2, weights = weights_games_full_scaled)
m2 <- lm(f2, data = d2, weights = weights_games_full_scaled)
cat("Table 2 model 1 (HC1 robust SEs):\n"); print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))
cat("Table 2 model 2 (HC1 robust SEs):\n"); print(coeftest(m2, vcov = vcovHC(m2, type = "HC1")))
cat("Model 2 municipality-clustered SEs:\n"); print(coeftest(m2, vcov = vcovCL(m2, cluster = ~publicid_muni, type = "HC1")))
cat("N =", nobs(m1), nobs(m2), " R2 =", summary(m1)$r.squared, summary(m2)$r.squared, "\n")

## ---------------- Table 3: weighted Poisson of cross-level ties with offset ----------------
c3 <- read.csv(file.path(M, "clanalysis_anondata_vNov16.csv"))
c3 <- c3 %>% mutate(
  player_hc = as.numeric(ParticipantType == "C"),
  player_ai = as.numeric(ParticipantType == "G"),
  player_r  = as.numeric(ParticipantType == "R"))
base_vars <- c("decentralized","weights_games_full_scaled","publicid_muni",
               "net_crosslevel_propnumknown","net_crosslevel_propdenomknown",
               "net_crosslevel_propnumfriends","net_crosslevel_propdenomfriends")
full_vars <- c(base_vars, "Mujer","Q2_Educacion","Q1_Edad","Q3_YrsSalud","gen_trust",
               "player_hc","player_ai","player_r")
db <- c3[complete.cases(c3[base_vars]), ]
df <- c3[complete.cases(c3[full_vars]), ]
ctrl <- "+ Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + player_hc + player_ai + player_r"
fit_p <- function(y, denom, data, full) {
  fml <- as.formula(paste(y, "~ decentralized", if (full) ctrl else ""))
  fepois(fml, data = data, weights = ~weights_games_full_scaled,
         offset = as.formula(paste("~ log(", denom, ")")), cluster = ~publicid_muni)
}
ak_b <- fit_p("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   db, FALSE)
ak_f <- fit_p("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   df, TRUE)
sf_b <- fit_p("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", db, FALSE)
sf_f <- fit_p("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", df, TRUE)
print(etable(ak_b, ak_f, sf_b, sf_f))
# cross-check with glm (same point estimates)
gchk <- glm(net_crosslevel_propnumfriends ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud +
              gen_trust + player_hc + player_ai + player_r + offset(log(net_crosslevel_propdenomfriends)),
            family = quasipoisson, data = df, weights = weights_games_full_scaled)
cat("glm check strong full decentralized:", coef(gchk)["decentralized"], "\n")

## ---------------- Results ----------------
out <- c(
  decentralized_table2_col1 = unname(coef(m1)["decentralized"]),
  communication_table2_col1 = unname(coef(m1)["communication"]),
  decentralized_table2_col2 = unname(coef(m2)["decentralized"]),
  communication_table2_col2 = unname(coef(m2)["communication"]),
  decentralized_x_communication_table2_col2 = unname(coef(m2)["decentralized:communication"]),
  n_obs_table2 = nobs(m1),
  decentralized_table3_allties_base = unname(coef(ak_b)["decentralized"]),
  decentralized_table3_allties_full = unname(coef(ak_f)["decentralized"]),
  decentralized_table3_strongties_base = unname(coef(sf_b)["decentralized"]),
  decentralized_table3_strongties_full = unname(coef(sf_f)["decentralized"]),
  n_obs_table3_base = nobs(ak_b),
  n_obs_table3_full = nobs(ak_f))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
