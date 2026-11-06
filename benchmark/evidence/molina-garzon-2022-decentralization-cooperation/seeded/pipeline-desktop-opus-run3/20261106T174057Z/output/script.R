suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: public goods game, weighted OLS ----------------
pg <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
pg <- as.data.frame(haven::zap_labels(pg))

num_vars <- c("contribution", "decentralized", "communication", "round",
              "lag_groupcontribution", "num_players", "knownpeople",
              "Q2_female", "Q1_Edad", "Q2_Educacion", "Q3_YrsSalud",
              "Q5_Trust1Base", "weights_games_full_scaled", "p_type", "publicid")
for (v in num_vars) pg[[v]] <- as.numeric(pg[[v]])

# exclude late arrivals / invalid contributions (coded negative), as in the R replication file
pg <- pg[!is.na(pg$contribution) & pg$contribution >= 0, ]

pg$p_type_f <- factor(pg$p_type)  # lowest level is the base, as with Stata's i.p_type

needed <- c("contribution", "decentralized", "communication", "p_type_f", "round",
            "lag_groupcontribution", "num_players", "knownpeople", "Q2_female",
            "Q1_Edad", "Q2_Educacion", "Q3_YrsSalud", "Q5_Trust1Base",
            "weights_games_full_scaled", "publicid")
pg_cc <- pg[complete.cases(pg[, needed]), ]

f1 <- contribution ~ decentralized + i(p_type_f) + communication + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- contribution ~ decentralized * communication + i(p_type_f) + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base

m1 <- feols(f1, data = pg_cc, weights = ~weights_games_full_scaled, cluster = ~publicid)
m2 <- feols(f2, data = pg_cc, weights = ~weights_games_full_scaled, cluster = ~publicid)

print(summary(m1))
print(summary(m2))

b1 <- coef(m1)
b2 <- coef(m2)
int_name <- grep("decentralized:communication|communication:decentralized", names(b2), value = TRUE)[1]

## ---------------- Table 3: cross-level ties, weighted Poisson ----------------
cl <- read.csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"))

clse_f <- function(fm, cluster) {
  not <- attr(fm$model, "na.action")
  if (!is.null(not)) cluster <- cluster[-not]
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- fm$rank
  dfc <- (M / (M - 1)) * ((N - 1) / (N - K))
  uj <- apply(estfun(fm), 2, function(x) tapply(x, cluster, sum))
  V <- dfc * sandwich(fm, meat = crossprod(uj) / N)
  coeftest(fm, V)
}

mk_base <- glm(net_crosslevel_propnumknown ~ decentralized + offset(log(net_crosslevel_propdenomknown)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mf_base <- glm(net_crosslevel_propnumfriends ~ decentralized + offset(log(net_crosslevel_propdenomfriends)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mk_full <- glm(net_crosslevel_propnumknown ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud +
                 gen_trust + Participant_C + Participant_G + Participant_R +
                 offset(log(net_crosslevel_propdenomknown)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mf_full <- glm(net_crosslevel_propnumfriends ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud +
                 gen_trust + Participant_C + Participant_G + Participant_R +
                 offset(log(net_crosslevel_propdenomfriends)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)

for (m in list(mk_base, mk_full, mf_base, mf_full)) {
  print(tryCatch(clse_f(m, cl$publicid_muni), error = function(e) summary(m)$coefficients))
}

## ---------------- Output ----------------
fmt <- function(x) format(unname(x), digits = 10)

cat(sprintf("RESULT:decentralized_table2_col1=%s\n", fmt(b1["decentralized"])))
cat(sprintf("RESULT:communication_table2_col1=%s\n", fmt(b1["communication"])))
cat(sprintf("RESULT:decentralized_table2_col2=%s\n", fmt(b2["decentralized"])))
cat(sprintf("RESULT:communication_table2_col2=%s\n", fmt(b2["communication"])))
cat(sprintf("RESULT:decentralized_x_communication_table2_col2=%s\n", fmt(b2[int_name])))
cat(sprintf("RESULT:n_obs_table2=%s\n", fmt(nobs(m1))))
cat(sprintf("RESULT:decentralized_table3_allties_base=%s\n", fmt(coef(mk_base)["decentralized"])))
cat(sprintf("RESULT:decentralized_table3_allties_full=%s\n", fmt(coef(mk_full)["decentralized"])))
cat(sprintf("RESULT:decentralized_table3_strongties_base=%s\n", fmt(coef(mf_base)["decentralized"])))
cat(sprintf("RESULT:decentralized_table3_strongties_full=%s\n", fmt(coef(mf_full)["decentralized"])))
cat(sprintf("RESULT:n_obs_table3_base=%s\n", fmt(nrow(mk_base$model))))
cat(sprintf("RESULT:n_obs_table3_full=%s\n", fmt(nrow(mk_full$model))))