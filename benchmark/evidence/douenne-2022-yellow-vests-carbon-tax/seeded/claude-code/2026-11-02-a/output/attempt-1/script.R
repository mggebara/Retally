D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code"
ep <- new.env(); load(file.path(D,"after_papier.RData"), envir=ep)
e0 <- new.env(); load(file.path(D,"after_preparation.RData"), envir=e0)
for (v in c("variables_demo","variables_reg_effect_feedback","variables_reg_self_interest","variables_reg_ee")) {
 cat("--", v, " in papier:", exists(v, envir=ep, inherits=FALSE), " in prep:", exists(v, envir=e0, inherits=FALSE), "\n")
 if (exists(v, envir=ep, inherits=FALSE)) print(get(v, envir=ep))
 if (exists(v, envir=e0, inherits=FALSE)) print(get(v, envir=e0))
}
s <- e0$s
vars <- c("gagnant_feedback_categorie","simule_gagnant","tax_acceptance","taxe_approbation","prog_na","Simule_gain","Simule_gain2","taxe_efficace","single","hausse_depenses_par_uc","percentile_revenu","percentile_revenu_conjoint","variante_taxe_info","simule_gain","weight","gilets_jaunes","gagnant_categorie","gagnant_cible_categorie","traite_cible","traite_cible_conjoint","cible","taxe_cible_approbation","apres_modifs","info_CC","Revenu","Revenu2","Revenu_conjoint","Revenu_conjoint2","taxe_feedback_approbation")
for (v in vars) { cat("==", v, class(s[[v]]), "NA:", sum(is.na(s[[v]])), "\n"); if (!is.numeric(s[[v]]) || length(unique(s[[v]]))<8) print(head(table(s[[v]], useNA="ifany"),10)) else print(summary(s[[v]])) }
cat("n f:", sum(s$variante_taxe_info=='f'), " f&|g|<50:", sum(s$variante_taxe_info=='f' & abs(s$simule_gain)<50, na.rm=T), "\n")
cat("dims papier/prep:", dim(ep$s), dim(e0$s), "\n")
print(setdiff(names(ep$s), names(e0$s)))
cat("pkgs: ivreg", requireNamespace("ivreg", quietly=TRUE), " AER", requireNamespace("AER", quietly=TRUE), " Hmisc", requireNamespace("Hmisc", quietly=TRUE), " memisc", requireNamespace("memisc", quietly=TRUE), "\n")
