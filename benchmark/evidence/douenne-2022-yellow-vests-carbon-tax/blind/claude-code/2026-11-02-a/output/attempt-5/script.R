load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
s <- as.data.frame(s)
strip <- function(x) { if (!isS4(x)) return(x); y <- x; attributes(y) <- NULL; y }
s[] <- lapply(s, strip)
s$cible_n <- as.numeric(as.character(s$cible))
f <- s[s$variante_taxe_info == "f", ]
cat("feedback n", nrow(f), "\n")
cat("share lose feedback simule_gagnant:", mean(f$simule_gagnant == 0), " interaction:", mean(f$simule_gagnant_interaction == 0), "\n")
cat("n |simule_gain|<50:", sum(abs(f$simule_gain) < 50), " |interaction|<50:", sum(abs(f$simule_gain_interaction) < 50), "\n")
print(with(f[abs(f$simule_gain) < 50, ], table(simule_gagnant, simule_gain > 0)))
print(with(s, table(traite_cible, percentile_revenu <= cible_n)))
print(with(s, table(traite_cible_conjoint, single)))
print(with(s, table(traite_cible_conjoint, percentile_revenu_conjoint <= cible_n, single)))
print(with(s, summary(percentile_revenu_conjoint[single == 1])))
print(with(s, summary(revenu_conjoint[single == 1])))
cat("p10-p60 subsample (either adult, non-single conj):", sum((s$percentile_revenu >= 10 & s$percentile_revenu <= 60) | (s$single == 0 & s$percentile_revenu_conjoint >= 10 & s$percentile_revenu_conjoint <= 60)), "\n")
cat("p10-p60 subsample (either adult, any):", sum((s$percentile_revenu >= 10 & s$percentile_revenu <= 60) | (s$percentile_revenu_conjoint >= 10 & s$percentile_revenu_conjoint <= 60)), "\n")
eff <- s$taxe_efficace == "Oui"
for (v in c("apres_modifs", "variante_monetaire", "info_CC", "info_PM", "info_progressivite", "variante_partielle")) { cat(v, ":\n"); print(tapply(eff, s[[v]], mean)) }
print(summary(lm(eff ~ apres_modifs + variante_monetaire + info_CC + info_PM, data = s))$coefficients)
print(with(s, table(apres_modifs, variante_monetaire)))
print(with(s, table(Gilets_jaunes, gilets_jaunes_soutien)))
cat("NA counts:\n"); for (v in c("sexe","age","statut_emploi","csp","diplome4","taille_agglo","region","Gauche_droite","taille_menage","uc","Chauffage","prog_na","taxe_efficace","percentile_revenu","percentile_revenu_conjoint","simule_gain","tax_acceptance","winning_category","win_cible_category","tax_cible_acceptance","tax_approval","fume","actualite","diesel","essence","nb_vehicules","km","surface")) cat(v, sum(is.na(s[[v]])), "\n")
