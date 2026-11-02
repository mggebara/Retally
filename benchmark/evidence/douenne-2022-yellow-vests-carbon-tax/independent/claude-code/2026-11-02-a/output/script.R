set.seed(42)
suppressPackageStartupMessages(library(fixest))
load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
# columns are memisc 'item' objects / labelled vectors: strip to base vectors
cl <- function(x){ lv <- attr(x, "levels"); if (!is.null(lv)) { y <- x; attributes(y) <- NULL; return(lv[y]) }
  y <- tryCatch({attributes(x) <- NULL; x}, error=function(e) rep(NA, length(x))); if (isS4(y)) y <- unclass(y); y }
g <- function(v) cl(s[[v]])
num <- function(x) { if (is.character(x) && all(x %in% c("TRUE","FALSE",NA))) x <- as.logical(x); as.numeric(x) }

d <- data.frame(
  fb = g("variante_taxe_info") == "f",
  sg = as.numeric(g("simule_gain")),
  winner = num(g("simule_gagnant")),
  GF = as.numeric(g("gagnant_feedback_categorie") != "Perdant"),
  GFwin = as.numeric(g("gagnant_feedback_categorie") == "Gagnant"),
  A0 = num(g("tax_acceptance")),
  A0dot = num(g("tax_approval")),
  G0 = as.numeric(g("gagnant_categorie") != "Perdant"),
  G0cat = factor(g("gagnant_categorie")),
  yv = as.numeric(as.numeric(g("gilets_jaunes")) > 0),
  AT = num(g("tax_cible_acceptance")),
  GT = num(g("win_cible_category")),
  T1 = num(g("traite_cible")),
  T2 = num(g("traite_cible_conjoint")),
  cible = factor(g("cible")),
  single = num(g("single")),
  eff = as.numeric(g("taxe_efficace") == "Oui"),
  effcat = factor(g("taxe_efficace")),
  prog = factor(g("prog_na")),
  ZE = num(g("apres_modifs")),
  ZCC = num(g("info_CC")),
  p1 = as.numeric(g("percentile_revenu")),
  p2 = as.numeric(g("percentile_revenu_conjoint")),
  sexe = factor(g("sexe")), statut = factor(g("statut_emploi")), csp = factor(g("csp")),
  region = factor(g("region")), dipl = factor(g("diplome4")), agglo = factor(g("taille_agglo")),
  nb_adultes = as.numeric(g("nb_adultes")), taille_menage = as.numeric(g("taille_menage")),
  nb14 = as.numeric(g("nb_14_et_plus")), fume = factor(g("fume")), actu = factor(g("actualite")),
  a1 = as.numeric(g("age_18_24")), a2 = as.numeric(g("age_25_34")), a3 = as.numeric(g("age_35_49")), a4 = as.numeric(g("age_50_64"))
)
# incomes: continuous piecewise linear in percentiles, kinks at 20 and 70, for both adults
d$p1_20 <- pmin(d$p1 - 20, 0); d$p1_70 <- pmin(d$p1 - 70, 0)
d$p2_20 <- pmin(d$p2 - 20, 0); d$p2_70 <- pmin(d$p2 - 70, 0)
d$sg2 <- d$sg^2

inc <- "p1 + p1_20 + p1_70 + p2 + p2_20 + p2_70"
gains <- "sg + sg2"
demo <- "sexe + a1 + a2 + a3 + a4 + statut + csp + region + dipl + agglo + nb_adultes + taille_menage + nb14 + fume + actu"
motives <- "effcat + prog"
ctrl <- paste(inc, gains, demo, motives, sep = " + ")
ctrl4 <- paste(inc, gains, demo, "prog", sep = " + ")

rd <- subset(d, fb & abs(sg) < 50)
full <- subset(d, fb)

m1 <- feols(as.formula(paste("GF ~ winner + A0 +", ctrl4)), data = rd, vcov = "hetero")
m2 <- feols(as.formula(paste("GF ~ winner + A0 +", ctrl4)), data = full, vcov = "hetero")
m3 <- feols(as.formula(paste("GF ~ winner + A0 + yv + winner:A0 + winner:yv + winner:G0 + G0cat +", ctrl4)), data = rd, vcov = "hetero")
m4 <- feols(as.formula(paste("GFwin ~ winner + A0 +", ctrl4)), data = rd, vcov = "hetero")

# Table 6 col 1: 2SLS targeted dividend, households with an adult in [p10; p60]
sub6 <- subset(d, (p1 >= 10 & p1 <= 60) | (p2 >= 10 & p2 <= 60))
m6 <- feols(as.formula(paste("AT ~ cible + single + A0 +", ctrl, "| GT ~ T1 + T2 + T1:T2")), data = sub6, vcov = "hetero")

# Table 8 col 1: 2SLS approval on effectiveness belief; other motive = initial win/lose category
# (progressivity belief omitted: only asked in the apres_modifs half, collinear with Z_E)
ctrl8 <- paste(inc, gains, demo, "G0cat", sep = " + ")
m8 <- feols(as.formula(paste("A0dot ~", ctrl8, "| eff ~ ZE + ZCC")), data = d, vcov = "hetero")

cf <- function(m, n) unname(coef(m)[n])
cat("NA check ZE:", sum(is.na(d$ZE)), " A0:", sum(is.na(d$A0)), "\n")
cat("N col1:", nobs(m1), " N col2:", nobs(m2), " N t6:", nobs(m6), " N t8:", nobs(m8), "\n")
cat("RESULT:predicted_winner_believes_not_lose_table4_col1=", cf(m1, "winner"), "\n", sep = "")
cat("RESULT:initial_acceptance_believes_not_lose_table4_col1=", cf(m1, "A0"), "\n", sep = "")
cat("RESULT:predicted_winner_believes_not_lose_full_sample_table4_col2=", cf(m2, "winner"), "\n", sep = "")
cat("RESULT:predicted_winner_heterogeneity_table4_col3=", cf(m3, "winner"), "\n", sep = "")
cat("RESULT:initial_acceptance_heterogeneity_table4_col3=", cf(m3, "A0"), "\n", sep = "")
cat("RESULT:yellow_vests_supporter_heterogeneity_table4_col3=", cf(m3, "yv"), "\n", sep = "")
cat("RESULT:winner_x_initial_acceptance_table4_col3=", cf(m3, "winner:A0"), "\n", sep = "")
cat("RESULT:winner_x_yellow_vests_supporter_table4_col3=", cf(m3, "winner:yv"), "\n", sep = "")
cat("RESULT:winner_x_initial_win_belief_table4_col3=", cf(m3, "winner:G0"), "\n", sep = "")
cat("RESULT:predicted_winner_believes_wins_table4_col4=", cf(m4, "winner"), "\n", sep = "")
cat("RESULT:n_obs_table4_col1=", nobs(m1), "\n", sep = "")
cat("RESULT:believes_not_lose_on_acceptance_iv_table6_col1=", cf(m6, "fit_GT"), "\n", sep = "")
cat("RESULT:believes_effective_on_approval_iv_table8_col1=", cf(m8, "fit_eff"), "\n", sep = "")
