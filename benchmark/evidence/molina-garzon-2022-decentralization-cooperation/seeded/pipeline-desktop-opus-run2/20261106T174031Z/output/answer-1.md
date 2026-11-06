suppressPackageStartupMessages({
  library(haven)
  library(fixest)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

base_dir <- "<repo>/.cache/datasets/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS of PGG contributions ----------------
pg <- haven::read_dta(file.path(base_dir, "publicgoodgame_dataAug27.dta"))
pg <- as.data.frame(haven::zap_labels(pg))

num_vars <- c("contribution", "decentralized", "communication", "round",
              "lag_groupcontribution", "num_players", "knownpeople", "Q2_female",
              "Q1_Edad", "Q2_Educacion", "Q3_YrsSalud", "Q5_Trust1Base",
              "weights_games_full_scaled", "p_type", "publicid")
for (v in num_vars) pg[[v]] <- as.numeric(pg[[v]])

cat("PGG rows:", nrow(pg), "\n")
cat("Contribution range:", range(pg$contribution, na.rm = TRUE), "\n")
cat("p_type table:\n"); print(table(pg$p_type, useNA = "ifany"))

# Stata i.p_type: lowest level is the base category
pg$p_type_f <- factor(pg$p_type, levels = sort(unique(pg$p_type[!is.na(pg$p_type)])))

f1 <- contribution ~ decentralized + p_type_f + communication + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- contribution ~ decentralized * communication + p_type_f + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base

m1 <- feols(f1, data = pg, weights = ~weights_games_full_scaled, cluster = ~publicid)
m2 <- feols(f2, data = pg, weights = ~weights_games_full_scaled, cluster = ~publicid)
print(summary(m1))
print(summary(m2))

b1 <- coef(m1); b2 <- coef(m2)
int_name <- grep("decentralized:communication|communication:decentralized", names(b2), value = TRUE)[1]

## ---------------- Table 3: weighted Poisson of cross-level ties ----------------
clse.f <- function(dat, fm, cluster) {
  not <- attr(fm$model, "na.action")
  if (!is.null(not)) {
    cluster <- cluster[-not]
    dat <- dat[-not, ]
  }
  M <- length(unique(cluster))
  N <- length(cluster)
  K <- fm$rank
  dfc <- (M / (M - 1)) * ((N - 1) / (N - K))
  uj <- apply(estfun(fm), 2, function(x) tapply(x, cluster, sum))
  vc <- dfc * sandwich(fm, meat = crossprod(uj) / N)
  coeftest(fm, vc)
}

cl <- read.csv(file.path(base_dir, "clanalysis_anondata_vNov16.csv"))

mk.base <- glm(net_crosslevel_propnumknown ~ decentralized + offset(log(net_crosslevel_propdenomknown)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mf.base <- glm(net_crosslevel_propnumfriends ~ decentralized + offset(log(net_crosslevel_propdenomfriends)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mk.full <- glm(net_crosslevel_propnumknown ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud +
                 gen_trust + Participant_C + Participant_G + Participant_R +
                 offset(log(net_crosslevel_propdenomknown)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)
mf.full <- glm(net_crosslevel_propnumfriends ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud +
                 gen_trust + Participant_C + Participant_G + Participant_R +
                 offset(log(net_crosslevel_propdenomfriends)),
               family = "poisson", weights = weights_games_full_scaled, data = cl)

for (m in list(mk.base, mk.full, mf.base, mf.full)) {
  print(tryCatch(clse.f(cl, m, cl$publicid_muni), error = function(e) conditionMessage(e)))
}

n_glm <- function(m) nrow(m$model)

## ---------------- Results ----------------
cat(sprintf("RESULT:decentralized_table2_col1=%.6f\n", b1["decentralized"]))
cat(sprintf("RESULT:communication_table2_col1=%.6f\n", b1["communication"]))
cat(sprintf("RESULT:decentralized_table2_col2=%.6f\n", b2["decentralized"]))
cat(sprintf("RESULT:communication_table2_col2=%.6f\n", b2["communication"]))
cat(sprintf("RESULT:decentralized_x_communication_table2_col2=%.6f\n", b2[int_name]))
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
cat(sprintf("RESULT:decentralized_table3_allties_base=%.6f\n", coef(mk.base)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_allties_full=%.6f\n", coef(mk.full)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_strongties_base=%.6f\n", coef(mf.base)["decentralized"]))
cat(sprintf("RESULT:decentralized_table3_strongties_full=%.6f\n", coef(mf.full)["decentralized"]))
cat(sprintf("RESULT:n_obs_table3_base=%d\n", n_glm(mk.base)))
cat(sprintf("RESULT:n_obs_table3_full=%d\n", n_glm(mk.full)))
