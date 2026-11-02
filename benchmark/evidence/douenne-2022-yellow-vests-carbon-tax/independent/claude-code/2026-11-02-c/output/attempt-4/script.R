set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-c/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(base, envir = e); s <- e$s
pl <- function(x) { cl <- oldClass(x); if (!is.null(cl) && "factor" %in% cl) { lv <- attr(x, "levels"); oldClass(x) <- NULL; return(lv[x]) }; if (typeof(x) == "S4") x <- x@.Data; oldClass(x) <- NULL; attributes(x) <- NULL; x }
cat("classes:\n"); print(table(sapply(s, function(z) paste(oldClass(z), collapse="/"))))
tab <- function(v) { cat("\n==", v, "\n"); x <- pl(s[[v]]); if (is.numeric(x) && length(unique(x)) > 15) print(summary(x)) else print(table(as.character(x), useNA = "ifany")) }
for (v in c("taxe_approbation","taxe_feedback_approbation","taxe_info_approbation","tax_approval","tax_acceptance","taxe_efficace","progressivite","gilets_jaunes","Gilets_jaunes","gilets_jaunes_dedans","gilets_jaunes_soutien","cible","categorie_cible","traite_cible","traite_cible_conjoint","single","gagnant_cible_categorie","taxe_cible_approbation","tax_cible_acceptance","win_cible_category","winning_category","winning_feedback_category","gain","percentile_revenu","percentile_revenu_conjoint","Revenu","Revenu_conjoint","revenu","revenu_conjoint","weight","sexe","age","statut_emploi","csp","region","diplome4","taille_menage","nb_14_et_plus","nb_adultes","fume","actualite","taille_agglo","uc","niveau_vie","Gauche_droite","gauche_droite","interet_politique","sample","exclu","mauvaise_qualite","Simule_gain","Simule_gain2","Revenu2","biais_sur","hausse_depenses_par_uc","retraites","actifs","etudiants","inactif","convaincu_feedback")) tab(v)
cat("\ncross feedback x variante\n"); print(table(s$variante_monetaire, is.na(s$gagnant_feedback_categorie), useNA="ifany"))
print(table(s$apres_modifs, s$variante_taxe_info, useNA="ifany"))
cat("abs simule_gain<50 & feedback nonNA: ", sum(abs(s$simule_gain) < 50 & !is.na(s$gagnant_feedback_categorie)), "\n")
for (v in names(s)) s[[v]] <- pl(s[[v]])
cat("eff by apres_modifs/variante_monetaire/info_CC\n"); print(tapply(s$taxe_efficace=="Oui", s$apres_modifs, mean)); print(tapply(s$taxe_efficace=="Oui", s$variante_monetaire, mean)); print(tapply(s$taxe_efficace=="Oui", s$info_CC, mean))
print(head(s[, c("percentile_revenu","percentile_revenu_conjoint","revenu","revenu_conjoint","cible","traite_cible","traite_cible_conjoint","simule_gain","Simule_gain","simule_gagnant")], 15))
