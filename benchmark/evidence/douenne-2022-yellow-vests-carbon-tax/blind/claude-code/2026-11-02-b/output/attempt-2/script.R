load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
tab <- function(v) { cat("\n### ", v, " class=", class(s[[v]])[1], "\n"); x <- s[[v]]
  if (is.numeric(x) && length(unique(x)) > 15) print(summary(x)) else print(table(x, useNA="ifany")) }
vars <- c("variante_taxe_info","info_progressivite","variante_progressivite","gagnant_info_categorie","gagnant_categorie",
 "gagnant_feedback_categorie","gagnant_progressif_categorie","simule_gagnant","simule_gain","simule_gain_menage","simule_gain_repondant",
 "simule_gain_interaction","simule_gagnant_interaction","Simule_gain","Simule_gain2",
 "tax_acceptance","tax_approval","taxe_approbation","taxe_info_approbation","taxe_feedback_approbation","taxe_cible_approbation","tax_cible_acceptance",
 "gagnant_cible_categorie","win_cible_category","winning_category","winning_feedback_category",
 "gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","taxe_efficace","info_CC","info_PM","apres_modifs",
 "cible","categorie_cible","traite_cible","traite_cible_conjoint","versement_cible","percentile_revenu","percentile_revenu_conjoint",
 "Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","revenu","revenu_conjoint","rev_tot","single","nb_adultes","sample","weight",
 "variante_monetaire","variante_partielle","cible20","cible30","cible40","cible50","sexe","age","statut_emploi","csp","diplome4","region","taille_agglo",
 "taille_menage","nb_14_et_plus","uc","niveau_vie","fume","actualite","Gauche_droite","gauche_droite","interet_politique","ecologiste","conservateur",
 "liberal","humaniste","patriote","apolitique","progressivite","prog_na","prog_not_no","hausse_depenses","hausse_chauffage","hausse_carburants",
 "nb_vehicules","diesel","essence","gaz","fioul","Mode_chauffage","Chauffage","surface","km","conso","taille_agglo","age_18_24","age_65_plus",
 "retraites","actifs","etudiants","inactif","convaincu_feedback","biais_sur","Elasticite_partielle","elasticite_partielle","mauvaise_qualite","exclu","duree")
for (v in vars) if (v %in% names(s)) tab(v) else cat("\n### MISSING", v, "\n")
cat("\n### crosstab variante_taxe_info x gagnant_info_categorie NA\n"); print(table(s$variante_taxe_info, is.na(s$gagnant_info_categorie), useNA="ifany"))
cat("\n### simule_gagnant vs simule_gain>0\n"); print(table(s$simule_gagnant, s$simule_gain > 0, useNA="ifany"))
cat("\n### Simule_gain vs simule_gain cor\n"); print(cor(s$Simule_gain, s$simule_gain, use="c")); print(head(cbind(s$simule_gain, s$Simule_gain, s$Simule_gain2, s$simule_gain_interaction),10))
cat("\n### percentile vs Revenu\n"); print(head(cbind(s$revenu, s$Revenu, s$Revenu2, s$percentile_revenu, s$revenu_conjoint, s$Revenu_conjoint, s$percentile_revenu_conjoint),15))
cat("\n### cible x traite_cible\n"); print(table(s$cible, s$traite_cible, useNA="ifany"))
