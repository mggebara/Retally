# Reproduction of Molina-Garzon et al. (2022), Tables 2 and 3 (seeded mode)
# Table 2: translation of the authors' Stata .do file
#   reg contribution $xlist [pweight = weights_games_full_scaled], vce(cluster publicid)
# Table 3: translation of the authors' R script (weighted Poisson glm with offset,
#   SEs clustered by municipality)
suppressPackageStartupMessages({
  library(haven)
  library(fixest)
})
set.seed(42)

dir <- "<repo>/benchmark/.cache/claude-code/molina-garzon-2022-decentralization-cooperation/seeded/2026-11-06-a/mount/molina_garzon_2022_decentralization_cooperation"

## ---------------- Table 2 ----------------
pg <- as.data.frame(read_dta(file.path(dir, "publicgoodgame_dataAug27.dta")))
pg[] <- lapply(pg, function(x) { if (inherits(x, "haven_labelled")) as.numeric(x) else x })
pg$p_type <- factor(pg$p_type)

ctrl <- "i(p_type) + round + lag_groupcontribution + num_players + knownpeople + Q2_female + Q1_Edad + Q2_Educacion + Q3_YrsSalud + Q5_Trust1Base"
f1 <- as.formula(paste("contribution ~ decentralized + communication +", ctrl))
f2 <- as.formula(paste("contribution ~ decentralized * communication +", ctrl))

m1 <- feols(f1, data = pg, weights = ~weights_games_full_scaled, cluster = ~publicid)
m2 <- feols(f2, data = pg, weights = ~weights_games_full_scaled, cluster = ~publicid)
print(summary(m1)); print(summary(m2))

## ---------------- Table 3 ----------------
cl <- read.csv(file.path(dir, "clanalysis_anondata_vNov16.csv"))

clse <- function(fm, cluster) {
  # CR1 with Stata-style small-sample correction, as in authors' clse.f
  not <- attr(fm$model, "na.action")
  if (!is.null(not)) cluster <- cluster[-not]
  M <- length(unique(cluster)); N <- length(cluster); K <- fm$rank
  dfc <- (M / (M - 1)) * ((N - 1) / (N - K))
  uj <- apply(sandwich::estfun(fm), 2, function(x) tapply(x, cluster, sum))
  V <- dfc * sandwich::sandwich(fm, meat = crossprod(uj) / N)
  lmtest::coeftest(fm, V)
}

full <- "+ Mujer + Q2_Educacion + Q1_Edad + Q3_YrsSalud + gen_trust + Participant_C + Participant_G + Participant_R"
fit <- function(y, denom, controls = "") {
  f <- as.formula(paste0(y, " ~ decentralized ", controls, " + offset(log(", denom, "))"))
  suppressWarnings(glm(f, family = poisson, weights = weights_games_full_scaled, data = cl))
}
kb <- fit("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown")
kf <- fit("net_crosslevel_propnumknown", "net_crosslevel_propdenomknown", full)
sb <- fit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends")
sf <- fit("net_crosslevel_propnumfriends", "net_crosslevel_propdenomfriends", full)
for (m in list(kb, kf, sb, sf)) print(suppressWarnings(clse(m, cl$publicid_muni)))

## ---------------- Results ----------------
out <- c(
  decentralized_table2_col1 = unname(coef(m1)["decentralized"]),
  communication_table2_col1 = unname(coef(m1)["communication"]),
  decentralized_table2_col2 = unname(coef(m2)["decentralized"]),
  communication_table2_col2 = unname(coef(m2)["communication"]),
  decentralized_x_communication_table2_col2 = unname(coef(m2)["decentralized:communication"]),
  n_obs_table2 = nobs(m1),
  decentralized_table3_allties_base = unname(coef(kb)["decentralized"]),
  decentralized_table3_allties_full = unname(coef(kf)["decentralized"]),
  decentralized_table3_strongties_base = unname(coef(sb)["decentralized"]),
  decentralized_table3_strongties_full = unname(coef(sf)["decentralized"]),
  n_obs_table3_base = nrow(kb$model),
  n_obs_table3_full = nrow(kf$model)
)
cat(sprintf("N table2 col2 = %d; N table3 strong base = %d, strong full = %d\n", nobs(m2), nrow(sb$model), nrow(sf$model)))
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
