d <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/"
e1 <- new.env(); load(paste0(d, "after_preparation.RData"), envir = e1)
s <- e1$s
cls <- sapply(s, function(x) paste(class(x), collapse = "/"))
print(table(cls))
s4 <- names(s)[sapply(s, isS4)]
cat("S4 cols:", length(s4), "\n"); print(head(s4, 60))
x <- s$taxe_approbation
cat("typeof:", typeof(x), "\n"); print(names(attributes(x)))
y <- x; attributes(y) <- NULL; y <- unclass(y)
cat("isS4 after strip:", isS4(y), "\n")
print(table(y, useNA = "ifany"))
vl <- attr(x, "value.labels"); if (!is.null(vl)) { print(str(vl)) }
strip <- function(v) { if (isS4(v) || inherits(v, "item")) { a <- attributes(v); out <- v; attributes(out) <- NULL; out <- asS4(out, FALSE); out } else v }
for (v in c("taxe_approbation", "taxe_efficace", "simule_gagnant", "tax_acceptance", "gilets_jaunes", "gagnant_cible_categorie", "taxe_cible_approbation", "cible", "traite_cible", "traite_cible_conjoint", "apres_modifs", "info_CC", "prog_na", "single", "sexe", "statut_emploi", "csp", "region", "diplome4", "fume", "actualite", "taille_agglo", "Revenu", "Simule_gain", "simule_gain", "hausse_depenses_par_uc", "percentile_revenu", "percentile_revenu_conjoint", "weight", "niveau_vie", "uc", "taille_menage", "nb_adultes", "nb_14_et_plus", "age_18_24", "Revenu_conjoint")) {
  z <- strip(s[[v]])
  cat("==", v, paste(class(s[[v]]), collapse = "/"), "->", class(z), "NA:", sum(is.na(z)), "\n")
  if (is.numeric(z) && length(unique(z)) > 12) print(summary(z)) else print(table(z, useNA = "ifany"))
}
