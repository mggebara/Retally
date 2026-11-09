D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(D, envir=e)
s <- e$s
memi <- names(s)[sapply(s, isS4)]
cat("S4 columns:", memi, "\n")
v <- c("taxe_approbation","gilets_jaunes","taxe_efficace","age","diplome4","taille_agglo","gauche_droite","interet_politique","taxe_feedback_approbation","taxe_info_approbation","progressivite","prog_na","prog_not_no","gain","gagnant_categorie","update_correct","feedback_confirme","Revenu","percentile_revenu","revenu_conjoint","nb_adultes","Simule_gain","simule_gain_interaction","simule_gagnant_interaction")
for (x in v) tryCatch({
  y <- s[[x]]; if (is.null(y)) stop("missing")
  cat("\n####", x, if (isS4(y)) "S4" else class(y)[1], "\n")
  if (isS4(y)) {
    vl <- attr(y, "value.labels"); vals <- attr(vl, "values"); lab <- vl; attributes(lab) <- NULL
    cat("labels:\n"); print(data.frame(value=vals, label=lab))
    attributes(y) <- NULL
  } else { y <- unclass(y) }
  if (is.numeric(y) && length(unique(y))>15) print(summary(as.numeric(y))) else print(table(y, useNA="ifany"))
}, error=function(e) cat("ERR", x, conditionMessage(e), "\n"))
# a few cross checks
y <- s$gilets_jaunes; attributes(y) <- NULL; print(table(y, s$Gilets_jaunes))
print(table(s$tax_acceptance, { z <- s$taxe_approbation; attributes(z) <- NULL; z }))
print(summary(lm(Revenu ~ I(revenu/1000), data=data.frame(Revenu=as.numeric(s$Revenu), revenu=as.numeric(s$revenu)))))
print(head(cbind(as.numeric(s$revenu), as.numeric(s$percentile_revenu), as.numeric(s$revenu_conjoint), as.numeric(s$percentile_revenu_conjoint), as.numeric(s$nb_adultes), as.numeric(s$traite_cible), as.numeric(s$traite_cible_conjoint), as.numeric(s$cible)), 20))
f <- !is.na(s$gagnant_feedback_categorie)
print(table(f, s$variante_taxe_info))
