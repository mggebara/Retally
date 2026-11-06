# Independent, blind reproduction: Molina-Garzon et al. (2022), Tables 2 and 3
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/blind/2026-11-06-c/mount/molina_garzon_2022_decentralization_cooperation"

## ---- Table 2: weighted OLS of per-round contributions ----
g <- read_dta(file.path(D, "publicgoodgame_dataAug27.dta"))
g <- g %>% transmute(contribution = as.numeric(contribution), decentralized = as.numeric(decentralized),
                     communication = as.numeric(communication), round = as.numeric(round),
                     p_type = factor(as.numeric(p_type), levels = 1:4, labels = c("A","C","G","R")),
                     lag_groupcontribution, num_players, knownpeople,
                     female = as.numeric(Q2_female), age = Q1_Edad, educ = as.numeric(Q2_Educacion),
                     yrs_health = Q3_YrsSalud, trust = as.numeric(Q5_Trust1Base),
                     w = weights_games_full_scaled, muni = publicid_muni)
g <- g[complete.cases(g), ]
f1 <- contribution ~ decentralized + communication + p_type + round + lag_groupcontribution +
  num_players + knownpeople + female + age + educ + yrs_health + trust
f2 <- update(f1, . ~ . + decentralized:communication)
m1 <- lm(f1, data = g, weights = w)
m2 <- lm(f2, data = g, weights = w)
cat("Table 2 col 1 (HC1 robust SEs):\n"); print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))
cat("Table 2 col 2 (HC1 robust SEs):\n"); print(coeftest(m2, vcov = vcovHC(m2, type = "HC1")))

## ---- Table 3: weighted Poisson with offset, muni-clustered SEs ----
cl <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
cat("participants with zero possible cross-level ties:", sum(cl$net_crosslevel_propdenomknown == 0), "\n")
cat("participants with missing weight:", sum(is.na(cl$weights_games_full_scaled)), "\n")
cl <- cl %>% filter(!is.na(weights_games_full_scaled), net_crosslevel_propdenomknown > 0)
pois <- function(y, denom, rhs, data) {
  fml <- as.formula(paste(y, "~", rhs, "+ offset(log(", denom, "))"))
  m <- suppressWarnings(glm(fml, data = data, family = poisson(link = "log"), weights = weights_games_full_scaled))
  print(coeftest(m, vcov = vcovCL(m, cluster = ~publicid_muni, type = "HC0")))
  m
}
full_rhs <- "decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R"
full_vars <- c("Mujer","Q2_Educacion","Q1_Edad","Q3_YrsSalud","gen_trust","Participant_C","Participant_G","Participant_R")
clf <- cl[complete.cases(cl[, full_vars]), ]
a_b <- pois("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   "decentralized", cl)
a_f <- pois("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   full_rhs, clf)
s_b <- pois("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", "decentralized", cl)
s_f <- pois("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", full_rhs, clf)

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
r("n_obs_table3_base", nrow(cl))
r("n_obs_table3_full", nrow(clf))
