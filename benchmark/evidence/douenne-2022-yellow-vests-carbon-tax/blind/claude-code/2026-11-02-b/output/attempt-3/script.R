load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
g <- function(v){x<-s[[v]]; if(isS4(x)) x@.Data else x}
tab <- function(v) { x <- s[[v]]; cl <- class(x)[1]; if (isS4(x)) x <- x@.Data; cat("\n### ", v, " class=", cl, "\n")
  if (is.numeric(x) && length(unique(x)) > 15) print(summary(x)) else print(table(x, useNA="ifany")) }
vars <- c("gagnant_progressif_categorie","simule_gagnant","simule_gain","simule_gain_menage","simule_gain_repondant",
 "simule_gain_interaction","simule_gagnant_interaction","Simule_gain","Simule_gain2",
 "tax_acceptance","tax_approval","taxe_approbation","taxe_info_approbation","taxe_feedback_approbation","taxe_cible_approbation","tax_cible_acceptance",
 "gagnant_cible_categorie","win_cible_category","winning_category","winning_feedback_category",
 "gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","taxe_efficace","info_CC","info_PM","apres_modifs",
 "cible","categorie_cible","traite_cible","traite_cible_conjoint","versement_cible","percentile_revenu","percentile_revenu_conjoint",
 "Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","revenu","revenu_conjoint","rev_tot","single","nb_adultes","sample","weight",
 "variante_monetaire","variante_partielle","cible20","cible30","cible40","cible50","sexe","age","statut_emploi","csp","diplome4","region","taille_agglo",
 "taille_menage","nb_14_et_plus","uc","niveau_vie","fume","actualite","Gauche_droite","gauche_droite","interet_politique","ecologiste","conservateur",
 "liberal","humaniste","patriote","apolitique","progressivite","prog_na","prog_not_no","hausse_depenses","hausse_chauffage","hausse_carburants",
 "nb_vehicules","diesel","essence","gaz","fioul","Mode_chauffage","Chauffage","surface","km","conso","age_18_24","age_65_plus",
 "retraites","actifs","etudiants","inactif","convaincu_feedback","biais_sur","Elasticite_partielle","elasticite_partielle","mauvaise_qualite","exclu","duree")
for (v in vars) if (v %in% names(s)) tryCatch(tab(v), error=function(e) cat("ERR", v, conditionMessage(e), "\n")) else cat("\n### MISSING", v, "\n")
cat("\n### crosstab variante_taxe_info x gagnant_feedback_categorie NA\n"); print(table(g("variante_taxe_info"), is.na(g("gagnant_feedback_categorie")), useNA="ifany"))
cat("\n### simule_gagnant vs simule_gain>0\n"); print(table(g("simule_gagnant"), g("simule_gain") > 0, useNA="ifany"))
cat("\n### gain columns\n"); print(head(cbind(g("simule_gain"), g("Simule_gain"), g("Simule_gain2"), g("simule_gain_interaction"), g("simule_gain_menage")),10))
cat("\n### income columns\n"); print(head(cbind(g("revenu"), g("Revenu"), g("Revenu2"), g("percentile_revenu"), g("revenu_conjoint"), g("Revenu_conjoint"), g("percentile_revenu_conjoint")),15))
cat("\n### cible x traite_cible\n"); print(table(g("cible"), g("traite_cible"), useNA="ifany"))
cat("\n### cible x traite_cible_conjoint\n"); print(table(g("cible"), g("traite_cible_conjoint"), useNA="ifany"))
cat("\n### winning_category x gagnant_categorie\n"); print(table(g("winning_category"), g("gagnant_categorie"), useNA="ifany"))
