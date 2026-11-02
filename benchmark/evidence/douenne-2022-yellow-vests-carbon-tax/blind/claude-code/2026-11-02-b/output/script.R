# Retally blind/independent reproduction: Douenne & Fabre (2022, AEJ:EP)
# "Yellow Vests, Pessimistic Beliefs, and Carbon Tax Aversion" - Tables 4, 6, 8.
set.seed(42)
suppressPackageStartupMessages(library(fixest))

load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")

# Columns carry memisc item classes (package not installed): strip to plain vectors.
conv <- function(x) { lv <- attr(x, "levels"); cl <- as.vector(attr(x, "class")); attributes(x) <- NULL; x <- unclass(x)
  if (!is.null(lv) && any(cl == "factor")) x <- as.vector(lv)[x]; x }
vv <- c("variante_taxe_info", "gagnant_feedback_categorie", "gagnant_categorie", "simule_gagnant", "simule_gain",
        "tax_acceptance", "taxe_approbation", "taxe_efficace", "gilets_jaunes", "prog_na",
        "percentile_revenu", "percentile_revenu_conjoint", "traite_cible", "traite_cible_conjoint", "cible", "single",
        "gagnant_cible_categorie", "tax_cible_acceptance", "info_CC", "apres_modifs",
        "sexe", "age", "statut_emploi", "csp", "region", "diplome4", "taille_agglo", "taille_menage", "nb_14_et_plus")
d <- as.data.frame(setNames(lapply(vv, function(v) conv(s[[v]])), vv), stringsAsFactors = FALSE)
cat("Rows:", nrow(d), "\n")

# ---- Variable construction ----
tonum <- function(x) as.numeric(as.character(x) %in% c("TRUE", "1"))
cat("ZE mean:", mean(tonum(d$apres_modifs)), " A0 mean:", mean(tonum(d$tax_acceptance)), "\n")
d$GF_not_lose <- as.numeric(d$gagnant_feedback_categorie != "Perdant")   # belief after feedback: does not lose
d$GF_win      <- as.numeric(d$gagnant_feedback_categorie == "Gagnant")   # belief after feedback: wins
d$G0_not_lose <- as.numeric(d$gagnant_categorie != "Perdant")            # initial win/lose belief (G)
d$winner      <- tonum(d$simule_gagnant)                            # predicted winner feedback (Gamma-hat)
d$gain        <- d$simule_gain                                           # estimated net gain (gamma-hat)
d$gain2       <- d$simule_gain^2
d$A0          <- tonum(d$tax_acceptance)                            # initial acceptance (not "No")
d$A0_approve  <- as.numeric(d$taxe_approbation == "Oui")                 # initial approval ("Yes")
d$E_yes       <- as.numeric(d$taxe_efficace == "Oui")                    # believes effective ("Yes")
d$yv          <- as.numeric(d$gilets_jaunes >= 1)                        # part of / supports Yellow Vests
d$GT          <- as.numeric(d$gagnant_cible_categorie != "Perdant")      # targeted: does not lose
d$AT          <- tonum(d$tax_cible_acceptance)                      # targeted: acceptance
d$T1 <- tonum(d$traite_cible); d$T2 <- tonum(d$traite_cible_conjoint); d$T12 <- d$T1 * d$T2
d$ZE <- tonum(d$apres_modifs)   # info on scientific consensus on effectiveness (displayed in the post-modification wave)
d$ZCC <- tonum(d$info_CC)
d$prog_f <- factor(d$prog_na); d$eff_f <- factor(d$taxe_efficace); d$G0cat <- factor(d$gagnant_categorie)
# incomes: piecewise linear in respondent & second-adult income percentiles, kinks at 20 and 70
d$I1 <- d$percentile_revenu; d$I2 <- d$percentile_revenu_conjoint
d$I1_20 <- pmin(d$I1 - 20, 0); d$I1_70 <- pmin(d$I1 - 70, 0)
d$I2_20 <- pmin(d$I2 - 20, 0); d$I2_70 <- pmin(d$I2 - 70, 0)
for (v in c("sexe", "age", "statut_emploi", "csp", "region", "diplome4", "taille_agglo", "cible")) d[[paste0(v, "_f")]] <- factor(d[[v]])

incomes  <- "I1 + I1_20 + I1_70 + I2 + I2_20 + I2_70"
gains    <- "gain + gain2"
sociodemo <- "sexe_f + age_f + statut_emploi_f + csp_f + region_f + diplome4_f + taille_agglo_f + taille_menage + nb_14_et_plus"
motives_T4 <- "eff_f + prog_f"   # other motives: effectiveness and progressivity beliefs

# ---- Table 4 ----
fb <- d[d$variante_taxe_info == "f", ]
fb50 <- fb[abs(fb$gain) < 50, ]
cat("Feedback sample:", nrow(fb), " |gain|<50:", nrow(fb50), "\n")
f1 <- as.formula(paste("GF_not_lose ~ winner + A0 +", gains, "+", incomes, "+", sociodemo, "+", motives_T4))
m1 <- feols(f1, data = fb50, vcov = "hetero")
m2 <- feols(f1, data = fb, vcov = "hetero")
f3 <- as.formula(paste("GF_not_lose ~ winner + A0 + yv + G0_not_lose + winner:A0 + winner:yv + winner:G0_not_lose + G0cat +",
                       gains, "+", incomes, "+", sociodemo, "+", motives_T4))
m3 <- feols(f3, data = fb50, vcov = "hetero")
f4 <- as.formula(paste("GF_win ~ winner + A0 +", gains, "+", incomes, "+", sociodemo, "+", motives_T4))
m4 <- feols(f4, data = fb50, vcov = "hetero")
print(coeftable(m1)[1:3, ]); print(coeftable(m3)[c("winner","A0","yv","winner:A0","winner:yv","winner:G0_not_lose"), ])
cat("R2:", r2(m1, "r2"), r2(m2, "r2"), r2(m3, "r2"), r2(m4, "r2"), " N:", nobs(m1), nobs(m2), nobs(m3), nobs(m4), "\n")

# ---- Table 6, column 1 ----
t6 <- d[(d$I1 >= 10 & d$I1 <= 60) | (d$I2 >= 10 & d$I2 <= 60), ]
f6 <- as.formula(paste("AT ~ cible_f + single + A0 +", gains, "+", incomes, "+", sociodemo, "+", motives_T4, "| 0 | GT ~ T1 + T2 + T12"))
m6 <- feols(f6, data = t6, vcov = "hetero")
print(coeftable(m6)["fit_GT", ]); cat("T6 N:", nobs(m6), "\n"); print(fitstat(m6, ~ ivf))

# ---- Table 8, column 1 ----
# other motives here: initial win/lose belief (progressivity belief is only observed in the ZE=1 wave, so it is collinear with ZE)
f8 <- as.formula(paste("A0_approve ~ G0cat +", gains, "+", incomes, "+", sociodemo, "| 0 | E_yes ~ ZE + ZCC"))
m8 <- feols(f8, data = d, vcov = "hetero")
print(coeftable(m8)["fit_E_yes", ]); cat("T8 N:", nobs(m8), "\n"); print(fitstat(m8, ~ ivf))

out <- c(
  predicted_winner_believes_not_lose_table4_col1 = unname(coef(m1)["winner"]),
  initial_acceptance_believes_not_lose_table4_col1 = unname(coef(m1)["A0"]),
  predicted_winner_believes_not_lose_full_sample_table4_col2 = unname(coef(m2)["winner"]),
  predicted_winner_heterogeneity_table4_col3 = unname(coef(m3)["winner"]),
  initial_acceptance_heterogeneity_table4_col3 = unname(coef(m3)["A0"]),
  yellow_vests_supporter_heterogeneity_table4_col3 = unname(coef(m3)["yv"]),
  winner_x_initial_acceptance_table4_col3 = unname(coef(m3)["winner:A0"]),
  winner_x_yellow_vests_supporter_table4_col3 = unname(coef(m3)["winner:yv"]),
  winner_x_initial_win_belief_table4_col3 = unname(coef(m3)["winner:G0_not_lose"]),
  predicted_winner_believes_wins_table4_col4 = unname(coef(m4)["winner"]),
  n_obs_table4_col1 = nobs(m1),
  believes_not_lose_on_acceptance_iv_table6_col1 = unname(coef(m6)["fit_GT"]),
  believes_effective_on_approval_iv_table8_col1 = unname(coef(m8)["fit_E_yes"])
)
for (n in names(out)) cat(sprintf("RESULT:%s=%.6f\n", n, out[[n]]))
