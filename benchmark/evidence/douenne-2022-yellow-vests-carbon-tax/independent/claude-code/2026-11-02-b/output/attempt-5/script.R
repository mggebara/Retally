load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
labs <- sapply(s, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else as.character(l)[1] })
d <- s
for (n in names(d)) { x <- d[[n]]; if (!("factor" %in% oldClass(x))) { r <- try({ attributes(x) <- NULL; x }, silent=TRUE); if (!inherits(r, "try-error")) d[[n]] <- r else cat("strip failed", n, "\n") } }
d <- as.data.frame(d)
v <- c("simule_gain","simule_gagnant","Simule_gain","Simule_gain2","simule_gain_interaction","gain","gagnant_categorie","gagnant_feedback_categorie",
       "gagnant_info_categorie","gagnant_cible_categorie","winning_category","winning_feedback_category","win_cible_category",
       "taxe_approbation","taxe_feedback_approbation","taxe_info_approbation","taxe_cible_approbation","tax_approval","tax_acceptance","tax_cible_acceptance",
       "gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","variante_taxe_info","info_CC","info_PM","taxe_efficace",
       "cible","categorie_cible","traite_cible","traite_cible_conjoint","percentile_revenu","percentile_revenu_conjoint","single","Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","revenu","revenu_conjoint",
       "sexe","age","csp","diplome4","taille_agglo","region","statut_emploi","Gauche_droite","gauche_droite","ecologiste","progressivite","prog_na","prog_not_no",
       "uc","nb_adultes","taille_menage","nb_14_et_plus","fume","actualite","interet_politique","retraites","actifs","etudiants","inactif","weight","sample","feedback_confirme","variante_progressivite","info_progressivite","apres_modifs","variante_partielle","variante_monetaire","hausse_depenses_par_uc","niveau_vie","versement","versement_cible","Mode_chauffage","Chauffage","diesel","essence","gaz","fioul","nb_vehicules","biais_sur","conservateur","liberal","humaniste","patriote","apolitique","indeterminate","gauche_droite_na","hausse_depenses","hausse_chauffage","hausse_carburants")
for (x in v) { y <- d[[x]]; if (is.null(y)) { cat("\n=====", x, "MISSING\n"); next }
  cat("\n=====", x, "|", substr(labs[x], 1, 250), "| class", class(y)[1], " NA:", sum(is.na(y)), "\n")
  if (is.numeric(y) && length(unique(y)) > 15) print(summary(as.numeric(y))) else print(table(y, useNA="ifany")) }
cat("\nfeedback received:\n"); print(table(is.na(d$gagnant_feedback_categorie)))
print(table(d$variante_taxe_info, is.na(d$gagnant_feedback_categorie), useNA="ifany"))
fb <- !is.na(d$gagnant_feedback_categorie)
for (g in c("simule_gain","Simule_gain","simule_gain_interaction","Simule_gain2")) cat(g, "abs<50 among feedback:", sum(abs(d[[g]]) < 50 & fb, na.rm=TRUE), "\n")
print(table(d$simule_gagnant, d$simule_gain > 0, useNA="ifany"))
