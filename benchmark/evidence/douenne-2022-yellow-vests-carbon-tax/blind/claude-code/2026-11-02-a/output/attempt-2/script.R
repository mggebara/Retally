load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
s <- as.data.frame(s)
tb <- function(v) { cat("\n###", v, " class:", class(s[[v]])[1], "\n"); x <- s[[v]]; if (is.numeric(x) && length(unique(x)) > 15) print(summary(x)) else print(table(x, useNA = "ifany")) }
vars <- c("variante_taxe_info","info_progressivite","variante_progressivite","simule_gagnant","simule_gagnant_interaction",
 "gagnant_categorie","gagnant_feedback_categorie","gagnant_progressif_categorie","gagnant_info_categorie","winning_category","winning_feedback_category",
 "taxe_approbation","taxe_feedback_approbation","taxe_info_approbation","tax_approval","tax_acceptance","taxe_cible_approbation","tax_cible_acceptance",
 "gagnant_cible_categorie","win_cible_category","cible","categorie_cible","traite_cible","traite_cible_conjoint","single","nb_adultes",
 "gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","taxe_efficace","info_CC","info_PM","apres_modifs","variante_monetaire",
 "simule_gain","simule_gain_interaction","simule_gain_menage","simule_gain_repondant","Simule_gain","Simule_gain2","simule_gain_inelastique","gain","uc",
 "percentile_revenu","percentile_revenu_conjoint","revenu","revenu_conjoint","Revenu","Revenu2","rev_tot","sexe","age","statut_emploi","csp","diplome4",
 "taille_agglo","region","Gauche_droite","gauche_droite","fume","actualite","taille_menage","nb_14_et_plus","niveau_vie","retraites","actifs","etudiants","inactif",
 "progressivite","prog_na","prog_not_no","sample","weight","exclu","mauvaise_qualite","biais_sur","variante_partielle","Diplome","interet_politique","ecologiste","conservateur",
 "Mode_chauffage","Chauffage","diesel","essence","hausse_depenses","hausse_depenses_par_uc","versement","versement_cible","feedback_confirme","update_correct","duree_info_courte","variante_transferts_inter")
for (v in vars) if (v %in% names(s)) tb(v) else cat("\nMISSING", v, "\n")
cat("\nnrow s", nrow(s), " sa", nrow(sa), " sl", nrow(sl), " sq", nrow(sq), " ss", nrow(ss), "\n")
cat("\ncor simule_gain vs simule_gain_interaction:", cor(s$simule_gain, s$simule_gain_interaction, use="complete.obs"), "\n")
print(with(s, table(simule_gain > 0, simule_gagnant, useNA="ifany")))
print(with(s, table(simule_gain_interaction > 0, simule_gagnant_interaction, useNA="ifany")))
print(with(s, table(is.na(gagnant_feedback_categorie), variante_taxe_info, useNA="ifany")))
print(with(s, table(winning_feedback_category, gagnant_feedback_categorie, useNA="ifany")))
print(with(s, table(tax_acceptance, taxe_approbation, useNA="ifany")))
print(with(s, table(win_cible_category, gagnant_cible_categorie, useNA="ifany")))
print(with(s, table(tax_cible_acceptance, taxe_cible_approbation, useNA="ifany")))
print(with(s, table(traite_cible, percentile_revenu <= cible, useNA="ifany")))
