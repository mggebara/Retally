# Independent reproduction: Molina-Garzon et al. (2022), Tables 2 and 3
suppressPackageStartupMessages({library(haven); library(fixest)})
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/independent/2026-11-06-c/mount/molina_garzon_2022_decentralization_cooperation"

## ---- Table 2: weighted OLS of per-round contributions ----
g <- as.data.frame(zap_labels(read_dta(file.path(D, "publicgoodgame_dataAug27.dta"))))
# p_type: 1=A (mayor's office, reference), 2=C (health center), 3=G (admin intermediary), 4=R (regional office)
g$pt_HC <- as.numeric(g$p_type == 2)
g$pt_AI <- as.numeric(g$p_type == 3)
g$pt_R  <- as.numeric(g$p_type == 4)
vars2 <- c("contribution","decentralized","communication","pt_HC","pt_AI","pt_R","round",
           "lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
           "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
g2 <- g[complete.cases(g[, vars2]), ]
rhs <- "pt_HC + pt_AI + pt_R + round + lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base"
m1 <- feols(as.formula(paste("contribution ~ decentralized + communication +", rhs)),
            data = g2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
m2 <- feols(as.formula(paste("contribution ~ decentralized * communication +", rhs)),
            data = g2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
print(summary(m1)); print(summary(m2))

## ---- Table 3: weighted Poisson with offset, municipality-clustered SEs ----
cl <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
cl$pt_HC <- as.numeric(cl$ParticipantType == "C")
cl$pt_AI <- as.numeric(cl$ParticipantType == "G")
cl$pt_R  <- as.numeric(cl$ParticipantType == "R")
base <- cl[!is.na(cl$weights_games_full_scaled), ]
ctrl3 <- c("Mujer","Q2_Educacion","Q1_Edad","Q3_YrsSalud","gen_trust")
full <- base[complete.cases(base[, ctrl3]), ]
rhs3 <- "Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + pt_HC + pt_AI + pt_R"
pfit <- function(y, den, rhs, d) {
  fepois(as.formula(paste(y, "~ decentralized", rhs)), data = d,
         offset = as.formula(paste0("~log(", den, ")")),
         weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
}
a_b <- pfit("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", "", base)
a_f <- pfit("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", paste("+", rhs3), full)
s_b <- pfit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", "", base)
s_f <- pfit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", paste("+", rhs3), full)
print(etable(a_b, a_f, s_b, s_f))

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("decentralized_table2_col1", coef(m1)["decentralized"])
r("communication_table2_col1", coef(m1)["communication"])
r("decentralized_table2_col2", coef(m2)["decentralized"])
r("communication_table2_col2", coef(m2)["communication"])
r("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
r("n_obs_table2", nobs(m1))
r("decentralized_table3_allties_base", coef(a_b)["decentralized"])
r("decentralized_table3_allties_full", coef(a_f)["decentralized"])
r("decentralized_table3_strongties_base", coef(s_b)["decentralized"])
r("decentralized_table3_strongties_full", coef(s_f)["decentralized"])
r("n_obs_table3_base", nobs(a_b))
r("n_obs_table3_full", nobs(a_f))
