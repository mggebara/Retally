# Independent blind reproduction: Molina-Garzon et al. (2022) Tables 2 and 3
set.seed(42)
suppressPackageStartupMessages({library(haven); library(sandwich); library(lmtest)})
D <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/blind/2026-11-06-b/mount/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2: weighted OLS of per-round contribution ----------------
g <- read_dta(file.path(D, "publicgoodgame_dataAug27.dta"))
print(attr(g$p_type, "labels"))
g$ptype <- as.character(as_factor(g$p_type))
g <- zap_labels(g)
print(table(g$ptype, g$p_type))
# player-type dummies by letter; mayor's office (A) is the reference
lab <- toupper(substr(trimws(g$ptype), 1, 1))
if (!all(lab %in% c("A", "C", "G", "R"))) lab <- c("A", "C", "G", "R")[g$p_type]
g$pt_C <- as.numeric(lab == "C"); g$pt_G <- as.numeric(lab == "G"); g$pt_R <- as.numeric(lab == "R")
print(table(lab, g$p_type))
vars2 <- c("contribution","decentralized","communication","pt_C","pt_G","pt_R","round",
           "lag_groupcontribution","num_players","knownpeople","Q2_female","Q1_Edad",
           "Q2_Educacion","Q3_YrsSalud","Q5_Trust1Base","weights_games_full_scaled","publicid_muni")
d2 <- as.data.frame(g[complete.cases(g[, vars2]), ])
f1 <- contribution ~ decentralized + communication + pt_C + pt_G + pt_R + round +
  lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad +
  Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base
f2 <- update(f1, . ~ . + decentralized:communication)
m1 <- lm(f1, data = d2, weights = weights_games_full_scaled)
m2 <- lm(f2, data = d2, weights = weights_games_full_scaled)
print(coeftest(m1, vcov = vcovHC(m1, type = "HC1")))
print(coeftest(m2, vcov = vcovHC(m2, type = "HC1")))
print(coeftest(m2, vcov = vcovCL(m2, cluster = ~publicid_muni)))

## ---------------- Table 3: weighted Poisson with offset ----------------
cl <- read.csv(file.path(D, "clanalysis_anondata_vNov16.csv"))
cl <- cl[!is.na(cl$weights_games_full_scaled) & cl$net_crosslevel_propdenomknown > 0, ]
pfit <- function(y, denom, rhs, data) {
  f <- as.formula(paste0(y, " ~ ", rhs, " + offset(log(", denom, "))"))
  vv <- unique(c(all.vars(f), "weights_games_full_scaled", "publicid_muni"))
  dd <- data[complete.cases(data[, vv]), ]
  m <- suppressWarnings(glm(f, family = poisson(link = "log"), data = dd,
                            weights = weights_games_full_scaled))
  print(coeftest(m, vcov = vcovCL(m, cluster = ~publicid_muni)))
  list(b = unname(coef(m)["decentralized"]), nrow = nrow(dd))
}
full_rhs <- "decentralized + Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R"
a_b <- pfit("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   "decentralized", cl)
a_f <- pfit("net_crosslevel_propnumknown",   "net_crosslevel_propdenomknown",   full_rhs, cl)
s_b <- pfit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", "decentralized", cl)
s_f <- pfit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", full_rhs, cl)
stopifnot(a_b$nrow == s_b$nrow, a_f$nrow == s_f$nrow)

out <- function(n, v) cat(sprintf("RESULT:%s=%.6f\n", n, v))
out("decentralized_table2_col1", coef(m1)["decentralized"])
out("communication_table2_col1", coef(m1)["communication"])
out("decentralized_table2_col2", coef(m2)["decentralized"])
out("communication_table2_col2", coef(m2)["communication"])
out("decentralized_x_communication_table2_col2", coef(m2)["decentralized:communication"])
cat(sprintf("RESULT:n_obs_table2=%d\n", nobs(m1)))
out("decentralized_table3_allties_base", a_b$b)
out("decentralized_table3_allties_full", a_f$b)
out("decentralized_table3_strongties_base", s_b$b)
out("decentralized_table3_strongties_full", s_f$b)
cat(sprintf("RESULT:n_obs_table3_base=%d\n", a_b$nrow))
cat(sprintf("RESULT:n_obs_table3_full=%d\n", a_f$nrow))
