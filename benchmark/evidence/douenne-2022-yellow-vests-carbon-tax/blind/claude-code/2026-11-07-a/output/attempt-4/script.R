load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
strip <- function(d) { L <- unclass(d); out <- vector("list", length(L)); for (i in seq_along(L)) { x <- L[[i]]; oc <- oldClass(x); if (identical(oc, "factor")) { out[[i]] <- as.character(x) } else { lv <- attr(x, "labels", exact=TRUE); attributes(x) <- NULL; out[[i]] <- x } }; names(out) <- names(L); data.frame(out, stringsAsFactors=FALSE) }
s <- strip(s)
v <- c("variante_taxe_info","gagnant_feedback_categorie","gagnant_categorie","gagnant_cible_categorie","gagnant_info_categorie","taxe_approbation","taxe_feedback_approbation","taxe_info_approbation","taxe_cible_approbation","tax_approval","tax_acceptance","tax_cible_acceptance","winning_category","winning_feedback_category","win_cible_category","simule_gagnant","gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","taxe_efficace","info_CC","info_PM","apres_modifs","cible","categorie_cible","traite_cible","traite_cible_conjoint","single","sexe","csp","diplome4","taille_agglo","region","statut_emploi","Gauche_droite","progressivite","prog_na","variante_progressivite","info_progressivite","nb_adultes","feedback_confirme","sample","fume","actualite","interet_politique","ecologiste","Diplome","revenu_decile")
for (x in v) { cat("== ", x, typeof(s[[x]]), "\n"); print(head(sort(table(s[[x]], useNA="ifany"), decreasing=TRUE), 25)) }
num <- c("simule_gain","Simule_gain","Simule_gain2","simule_gain_cible","Simule_gain_cible","Simule_gain_cible2","percentile_revenu","percentile_revenu_conjoint","Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","revenu","rev_tot","revenu_conjoint","uc","niveau_vie","weight","age","taille_menage","nb_14_et_plus","gain","simule_gain_repondant","versement_cible","hausse_depenses","hausse_depenses_par_uc","simule_gain_interaction","score_climate_call","score_ges")
for (x in num) { cat("== ", x, typeof(s[[x]]), "\n"); print(summary(as.numeric(s[[x]]))) }
print(table(s$variante_taxe_info, is.na(s$gagnant_feedback_categorie)))
print(table(s$cible, s$traite_cible, useNA="ifany"))
print(head(s[, c("percentile_revenu","Revenu","Revenu2","percentile_revenu_conjoint","Revenu_conjoint","Simule_gain","Simule_gain2","simule_gain","cible","traite_cible","traite_cible_conjoint")], 15))
print(table(s$gilets_jaunes, s$Gilets_jaunes, useNA="ifany"))
print(table(s$gilets_jaunes_dedans, s$gilets_jaunes_soutien))
print(cor(s$simule_gain, s$simule_gagnant))
print(table(s$simule_gain > 0, s$simule_gagnant))
