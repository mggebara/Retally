d <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/seeded/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/"
e1 <- new.env(); load(paste0(d, "after_preparation.RData"), envir = e1)
e2 <- new.env(); load(paste0(d, "after_papier.RData"), envir = e2)
s <- e1$s
vars <- unique(c("gagnant_feedback_categorie", "simule_gagnant", "tax_acceptance", "taxe_approbation", "gagnant_categorie", "gilets_jaunes",
  e2$variables_reg_effect_feedback[!grepl("^I\\(", e2$variables_reg_effect_feedback)], e2$variables_reg_ee,
  "gagnant_cible_categorie", "traite_cible", "traite_cible_conjoint", "cible", "taxe_cible_approbation", "apres_modifs", "info_CC", "taxe_efficace", "variante_taxe_info", "simule_gain", "weight"))
for (v in vars) {
  x <- s[[v]]
  a <- attributes(x)
  cat("==", v, "| class:", paste(class(x), collapse = "/"), "| typeof:", typeof(x), "| S4:", isS4(x), "\n")
  if (isS4(x)) {
    cat("  measurement:", as.character(a$measurement), "\n")
    vf <- a$value.filter; if (!is.null(vf)) { cat("  filter class:", class(vf), "\n"); print(unclass(asS4(vf, FALSE))); print(attributes(vf)[setdiff(names(attributes(vf)), "class")]) }
    vl <- a$value.labels; if (!is.null(vl)) { cat("  labels:\n"); print(attributes(vl)$values); print(unclass(asS4(vl, FALSE))) }
  }
  y <- x; attributes(y) <- NULL
  cat("  NA:", sum(is.na(y)), "\n")
  if (is.numeric(y) && length(unique(y)) > 12) print(summary(y)) else print(table(y, useNA = "ifany"))
}
sub <- s$variante_taxe_info == "f" & abs(s$simule_gain) < 50
cat("subset size:", sum(sub, na.rm = TRUE), "\n")
