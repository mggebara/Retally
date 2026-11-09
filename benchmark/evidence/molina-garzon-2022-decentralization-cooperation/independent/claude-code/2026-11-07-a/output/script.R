# Independent reproduction: Molina-Garzon et al. (2022), Tables 2 and 3
set.seed(42)
suppressMessages({library(haven); library(fixest)})
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/independent/2026-11-07-a/mount/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS of per-round contributions ----------
g <- as.data.frame(zap_labels(read_dta(file.path(D, "publicgoodgame_dataAug27.dta"))))
# p_type: 1=A (mayor's office, reference), 2=C (health center), 3=G (admin intermediary), 4=R (regional office)
g$player_hc <- as.integer(g$p_type == 2)
g$player_ai <- as.integer(g$p_type == 3)
g$player_r  <- as.integer(g$p_type == 4)
vars <- c("contribution","decentralized","communication","player_hc","player_ai","player_r",
          "round","lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
          "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
g2 <- g[complete.cases(g[, vars]), ]
rhs <- "player_hc + player_ai + player_r + round + lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base"
m1 <- feols(as.formula(paste("contribution ~ decentralized + communication +", rhs)),
            data = g2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
m2 <- feols(as.formula(paste("contribution ~ decentralized * communication +", rhs)),
            data = g2, weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
print(summary(m1)); print(summary(m2))

## ---------------- Table 3: weighted Poisson of cross-level ties -------------
n <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
n$player_hc <- n$Participant_C; n$player_ai <- n$Participant_G; n$player_r <- n$Participant_R
nb <- n[!is.na(n$weights_games_full_scaled), ]
ctrl <- c("Mujer","Q2_Educacion","Q1_Edad","Q3_YrsSalud","gen_trust","player_hc","player_ai","player_r")
nf <- nb[complete.cases(nb[, ctrl]), ]
pois <- function(y, denom, dat, full) {
  f <- if (full) paste(y, "~ decentralized +", paste(ctrl, collapse = " + ")) else paste(y, "~ decentralized")
  fepois(as.formula(f), data = dat, offset = as.formula(paste0("~log(", denom, ")")),
         weights = ~weights_games_full_scaled, cluster = ~publicid_muni)
}
k_b <- pois("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", nb, FALSE)
k_f <- pois("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", nf, TRUE)
s_b <- pois("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", nb, FALSE)
s_f <- pois("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", nf, TRUE)
for (m in list(k_b, k_f, s_b, s_f)) print(summary(m))

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("decentralized_table2_col1", coef(m1)[["decentralized"]])
r("communication_table2_col1", coef(m1)[["communication"]])
r("decentralized_table2_col2", coef(m2)[["decentralized"]])
r("communication_table2_col2", coef(m2)[["communication"]])
r("decentralized_x_communication_table2_col2", coef(m2)[["decentralized:communication"]])
r("n_obs_table2", nobs(m1))
r("decentralized_table3_allties_base", coef(k_b)[["decentralized"]])
r("decentralized_table3_allties_full", coef(k_f)[["decentralized"]])
r("decentralized_table3_strongties_base", coef(s_b)[["decentralized"]])
r("decentralized_table3_strongties_full", coef(s_f)[["decentralized"]])
r("n_obs_table3_base", nobs(k_b))
r("n_obs_table3_full", nobs(k_f))
