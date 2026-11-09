load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
strip <- function(d) { L <- unclass(d); out <- vector("list", length(L)); for (i in seq_along(L)) { x <- L[[i]]; oc <- oldClass(x); if (identical(oc, "factor")) { out[[i]] <- as.character(x) } else { attributes(x) <- NULL; out[[i]] <- x } }; names(out) <- names(L); data.frame(out, stringsAsFactors=FALSE) }
s <- strip(s)
print(table(s$apres_modifs, s$variante_monetaire, useNA="ifany"))
print(tapply(s$date, s$apres_modifs, range))
print(table(s$apres_modifs, s$sample))
print(summary(lm(I(taxe_efficace=="Oui") ~ apres_modifs + info_CC + info_PM, data=s))$coef)
print(summary(lm(I(taxe_efficace=="Oui") ~ variante_monetaire + info_CC, data=s))$coef)
print(table(s$simule_gagnant, s$simule_gain > 0))
f <- s$variante_taxe_info=="f"
print(sum(f & abs(s$simule_gain) < 50))
print(sum((s$percentile_revenu >= 10 & s$percentile_revenu <= 60) | (s$percentile_revenu_conjoint >= 10 & s$percentile_revenu_conjoint <= 60)))
print(table(s$single, s$nb_adultes))
print(table(s$age))
