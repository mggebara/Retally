d <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/"
e1 <- new.env(); load(paste0(d, "after_preparation.RData"), envir = e1)
e2 <- new.env(); load(paste0(d, "after_papier.RData"), envir = e2)
for (v in c("variables_demo", "variables_reg_effect_feedback", "variables_reg_self_interest", "variables_reg_ee")) {
  cat(v, "prep:", exists(v, envir = e1, inherits = FALSE), "pap:", exists(v, envir = e2, inherits = FALSE), "\n")
  if (exists(v, envir = e2, inherits = FALSE)) print(get(v, envir = e2)) else if (exists(v, envir = e1, inherits = FALSE)) print(get(v, envir = e1))
}
s <- e1$s
for (v in c("gagnant_feedback_categorie", "gagnant_categorie", "variante_taxe_info", "taxe_approbation", "taxe_efficace", "simule_gagnant", "tax_acceptance", "gilets_jaunes", "gagnant_cible_categorie", "taxe_cible_approbation", "cible", "traite_cible", "traite_cible_conjoint", "apres_modifs", "info_CC", "prog_na", "single")) {
  cat("==", v, class(s[[v]]), "\n"); print(head(table(s[[v]], useNA = "ifany"), 12))
}
cat("weight NA:", sum(is.na(s$weight)), "\n")
print(sum(s$variante_taxe_info == "f" & abs(s$simule_gain) < 50, na.rm = TRUE))
cat("identical s cols:", identical(dim(e1$s), dim(e2$s)), "\n")
print(R.version.string)
print(packageVersion("fixest"))
