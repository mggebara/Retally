# Independent reproduction: Molina-Garzon et al. (2022), Tables 2 and 3
suppressPackageStartupMessages({library(haven); library(fixest); library(sandwich); library(lmtest)})
set.seed(42)
d <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/independent/2026-11-06-b/mount/molina_garzon_2022_decentralization_cooperation"

## ---- Table 2: weighted OLS of per-round contributions ----
raw <- read_dta(file.path(d, "publicgoodgame_dataAug27.dta"))
pg <- as.data.frame(zap_labels(raw))
pg$ptype_chr <- as.character(as_factor(raw$p_type))
pg$pHC <- as.numeric(grepl("^C", pg$ptype_chr))
pg$pAI <- as.numeric(grepl("^G", pg$ptype_chr))
pg$pR  <- as.numeric(grepl("^R", pg$ptype_chr))
cat("p_type values:\n"); print(table(pg$ptype_chr, useNA = "ifany"))
vars <- c("contribution","decentralized","communication","pHC","pAI","pR","round",
          "lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
          "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
s2 <- pg[complete.cases(pg[, vars]), ]
f1 <- contribution ~ decentralized + communication + pHC + pAI + pR + round + lag_groupcontribution +
  num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- contribution ~ decentralized * communication + pHC + pAI + pR + round + lag_groupcontribution +
  num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
m1 <- feols(f1, data = s2, weights = ~weights_games_full_scaled, vcov = "hetero")
m2 <- feols(f2, data = s2, weights = ~weights_games_full_scaled, vcov = "hetero")
print(summary(m1)); print(summary(m2))

## ---- Table 3: weighted Poisson with offset, SE clustered by municipality ----
cl <- read.csv(file.path(d, "clanalysis_anondata_vNov16.csv"))
cat("clanalysis rows:", nrow(cl), "\n")
print(summary(cl[, c("net_crosslevel_propdenomknown","net_crosslevel_propnumknown",
                     "net_crosslevel_propnumfriends","weights_games_full_scaled")]))
cl <- cl[!is.na(cl$net_crosslevel_propdenomknown) & cl$net_crosslevel_propdenomknown > 0 &
         !is.na(cl$net_crosslevel_propnumknown) & !is.na(cl$net_crosslevel_propnumfriends) &
         !is.na(cl$weights_games_full_scaled), ]
fitp <- function(y, denom, rhs, data) {
  data <- data[complete.cases(data[, all.vars(rhs), drop = FALSE]), ]
  data$y <- data[[y]]; data$off <- log(data[[denom]])
  f <- as.formula(paste("y ~", paste(attr(terms(rhs), "term.labels"), collapse = " + ")))
  m <- glm(f, family = quasipoisson(), data = data, weights = weights_games_full_scaled, offset = off)
  ct <- coeftest(m, vcov = vcovCL(m, cluster = ~publicid_muni, type = "HC1"))
  print(ct)
  list(b = unname(coef(m)["decentralized"]), n = nrow(data))
}
rb <- ~ decentralized
rf <- ~ decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust +
  Participant_C + Participant_G + Participant_R
ab <- fitp("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   rb, cl)
af <- fitp("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   rf, cl)
sb <- fitp("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", rb, cl)
sf <- fitp("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", rf, cl)

r <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
r("decentralized_table2_col1", coef(m1)["decentralized"])
r("communication_table2_col1", coef(m1)["communication"])
r("decentralized_table2_col2", coef(m2)["decentralized"])
r("communication_table2_col2", coef(m2)["communication"])
r("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
r("n_obs_table2", nobs(m1))
r("decentralized_table3_allties_base", ab$b)
r("decentralized_table3_allties_full", af$b)
r("decentralized_table3_strongties_base", sb$b)
r("decentralized_table3_strongties_full", sf$b)
r("n_obs_table3_base", ab$n)
r("n_obs_table3_full", af$n)
