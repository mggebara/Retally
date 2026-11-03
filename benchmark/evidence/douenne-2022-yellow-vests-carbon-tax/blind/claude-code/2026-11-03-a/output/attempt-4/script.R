suppressMessages(load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-03-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"))
d <- s
for (nm in names(d)) { x <- d[[nm]]
  if (isS4(x)) x <- asS4(x, FALSE, complete = FALSE)
  if (is.factor(x)) x <- as.character(x)
  attributes(x) <- NULL
  d[[nm]] <- x }
v <- c("gagnant_categorie", "gagnant_feedback_categorie", "gagnant_info_categorie", "gagnant_cible_categorie",
       "winning_category", "winning_feedback_category", "win_cible_category", "simule_gagnant",
       "taxe_approbation", "taxe_feedback_approbation", "taxe_info_approbation", "taxe_cible_approbation",
       "tax_approval", "tax_acceptance", "tax_cible_acceptance", "taxe_efficace", "progressivite", "prog_not_no", "prog_na",
       "info_CC", "info_PM", "variante_taxe_info", "variante_progressivite", "info_progressivite", "variante_monetaire",
       "cible", "categorie_cible", "traite_cible", "traite_cible_conjoint", "single", "nb_adultes",
       "gilets_jaunes", "Gilets_jaunes", "gilets_jaunes_dedans", "gilets_jaunes_soutien",
       "sexe", "age", "csp", "diplome4", "taille_agglo", "region", "statut_emploi", "Gauche_droite", "gauche_droite",
       "retraites", "actifs", "etudiants", "inactif", "fume", "actualite", "apres_modifs", "sample", "exclu", "Diplome", "Chauffage", "Mode_chauffage", "feedback_confirme")
for (x in v) { cat("\n====", x, " class:", paste(class(d[[x]]), collapse = ","), "\n"); print(table(d[[x]], useNA = "ifany")) }
num <- c("simule_gain", "Simule_gain", "Simule_gain2", "simule_gain_menage", "simule_gain_repondant", "simule_gain_cible", "Simule_gain_cible",
         "simule_gain_interaction", "percentile_revenu", "percentile_revenu_conjoint", "revenu", "revenu_conjoint", "Revenu", "Revenu_conjoint", "Revenu2",
         "rev_tot", "uc", "niveau_vie", "weight", "gain", "taille_menage", "nb_14_et_plus", "hausse_depenses", "hausse_depenses_par_uc")
for (x in num) { cat("\n====", x, " class:", paste(class(d[[x]]), collapse = ","), "\n"); print(summary(as.numeric(as.vector(d[[x]])))) }
cat("\nfeedback received (non-NA gagnant_feedback_categorie):", sum(!is.na(d$gagnant_feedback_categorie)), "\n")
cat("abs(simule_gain)<50 & feedback:", sum(!is.na(d$gagnant_feedback_categorie) & abs(d$simule_gain) < 50), "\n")
print(table(simgag = d$simule_gagnant, pos = d$simule_gain > 0, useNA = "ifany"))
print(table(d$cible, d$traite_cible, useNA = "ifany"))
print(head(d[, c("percentile_revenu", "percentile_revenu_conjoint", "cible", "traite_cible", "traite_cible_conjoint", "nb_adultes", "single")], 20))
print(table(d$gagnant_categorie, d$winning_category, useNA = "ifany"))
print(table(d$gagnant_feedback_categorie, d$winning_feedback_category, useNA = "ifany"))
print(table(d$taxe_approbation, d$tax_acceptance, useNA = "ifany"))
print(table(d$taxe_cible_approbation, d$tax_cible_acceptance, useNA = "ifany"))
