load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
d <- s
cl <- function(x){ lv <- attr(x, "levels"); if (!is.null(lv)) { y <- x; attributes(y) <- NULL; return(lv[y]) }; y <- tryCatch({attributes(x) <- NULL; x}, error=function(e) rep(NA, length(x))); if (isS4(y)) y <- unclass(y); y }
tabs <- c("variante_taxe_info","gagnant_feedback_categorie","gagnant_categorie","gagnant_info_categorie","gagnant_cible_categorie",
  "taxe_approbation","taxe_info_approbation","taxe_feedback_approbation","taxe_cible_approbation","tax_approval","tax_acceptance","tax_cible_acceptance",
  "win_cible_category","winning_category","winning_feedback_category","simule_gagnant","simule_gagnant_interaction","gilets_jaunes","Gilets_jaunes",
  "info_CC","info_PM","apres_modifs","variante_progressivite","info_progressivite","cible","categorie_cible","traite_cible","traite_cible_conjoint",
  "taxe_efficace","single","sexe","statut_emploi","csp","diplome4","region","taille_agglo","Gauche_droite","gauche_droite","ecologiste","fume","actualite",
  "variante_monetaire","variante_partielle","sample","exclu","mauvaise_qualite","nb_adultes","taille_menage","nb_14_et_plus","Mode_chauffage","Chauffage",
  "progressivite","prog_na","biais_sur","retraites","actifs","etudiants","inactif","interet_politique","Diplome","diplome","gilets_jaunes_dedans","gilets_jaunes_soutien",
  "gaz","fioul","diesel","essence","nb_vehicules","convaincu_feedback")
for (v in tabs) if (v %in% names(d)) { cat("\n####", v, "attr:", paste(names(attributes(d[[v]])), collapse=","), "\n"); x <- cl(d[[v]]); print(table(x, useNA="ifany")) }
nums <- c("simule_gain","simule_gain_interaction","simule_gain_repondant","simule_gain_menage","Simule_gain","Simule_gain2","simule_gain_cible","Simule_gain_cible","Simule_gain_cible2",
 "revenu","rev_tot","revenu_conjoint","Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","percentile_revenu","percentile_revenu_conjoint","uc","niveau_vie","age","weight",
 "hausse_depenses","hausse_depenses_par_uc","gain","surface","km","conso","versement","versement_cible","hausse_chauffage","hausse_carburants","depense_carburants","depense_chauffage","duree")
for (v in nums) if (v %in% names(d)) { cat("\n####", v, "\n"); print(summary(as.numeric(cl(d[[v]])))) }
cat("\nabs(simule_gain)<50:", sum(abs(as.numeric(cl(d$simule_gain)))<50, na.rm=TRUE), "\n")
for (v in c("taxe_approbation","gilets_jaunes","taxe_efficace")) { a <- attributes(d[[v]]); cat(v, names(a), "\n"); for (n in setdiff(names(a), c("class","names"))) { cat(" -", n, ":\n"); print(tryCatch(cl(a[[n]]), error=function(e) "err")) } }
