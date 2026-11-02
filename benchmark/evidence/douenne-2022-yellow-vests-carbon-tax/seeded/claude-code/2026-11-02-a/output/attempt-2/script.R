D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code"
e0 <- new.env(); load(file.path(D,"after_preparation.RData"), envir=e0)
s <- e0$s
strip <- function(x) { attr(x, "label") <- NULL; cl <- setdiff(oldClass(x), "labelled"); if (length(cl)==0) x <- unclass(x) else class(x) <- cl; x }
s[] <- lapply(s, strip)
vars <- c("gagnant_feedback_categorie","simule_gagnant","tax_acceptance","taxe_approbation","prog_na","Simule_gain","Simule_gain2","taxe_efficace","single","hausse_depenses_par_uc","percentile_revenu","percentile_revenu_conjoint","variante_taxe_info","simule_gain","weight","gilets_jaunes","gagnant_categorie","gagnant_cible_categorie","traite_cible","traite_cible_conjoint","cible","taxe_cible_approbation","apres_modifs","info_CC","Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","taxe_feedback_approbation","sexe","statut_emploi","csp","region","diplome4","taille_menage","nb_14_et_plus","nb_adultes","fume","actualite","taille_agglo","uc","niveau_vie","age_18_24","age_50_64")
for (v in vars) { cat("==", v, paste(class(s[[v]]),collapse="/"), "NA:", sum(is.na(s[[v]])), "\n"); if (!is.numeric(s[[v]]) || length(unique(s[[v]]))<8) print(head(table(s[[v]], useNA="ifany"),12)) else print(summary(s[[v]])) }
cat("n f:", sum(s$variante_taxe_info=='f'), " f&|g|<50:", sum(s$variante_taxe_info=='f' & abs(s$simule_gain)<50, na.rm=T), "\n")
