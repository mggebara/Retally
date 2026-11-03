suppressMessages(load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-03-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"))
v <- c("variante_taxe_info", "variante_monetaire", "apres_modifs", "info_CC", "info_PM", "variante_progressivite", "info_progressivite",
       "simule_gagnant", "simule_gain", "simule_gain_interaction", "simule_gain_inelastique", "simule_gain_cible", "traite_cible", "traite_cible_conjoint",
       "percentile_revenu", "percentile_revenu_conjoint", "gilets_jaunes", "gilets_jaunes_soutien", "gilets_jaunes_dedans", "taxe_efficace",
       "tax_acceptance", "tax_approval", "tax_cible_acceptance", "gagnant_feedback_categorie", "gagnant_cible_categorie", "progressivite", "prog_not_no",
       "cible", "categorie_cible", "single", "revenu_conjoint", "taxe_info_approbation", "gagnant_info_categorie", "weight")
for (x in v) {
  y <- s[[x]]
  if (isS4(y)) y <- asS4(y, FALSE, complete = FALSE)
  a <- attributes(y)
  cat("\n====", x, "\n")
  for (k in setdiff(names(a), c("names", "row.names", "levels", "class"))) { cat(" [", k, "] "); str(a[[k]], nchar.max = 600, vec.len = 20) }
}
d <- s
for (nm in names(d)) { x <- d[[nm]]; if (isS4(x)) x <- asS4(x, FALSE, complete = FALSE); if (is.factor(x)) x <- as.character(x); attributes(x) <- NULL; d[[nm]] <- x }
cat("\nmatch simule_gagnant with sign of candidates\n")
for (g in c("simule_gain", "simule_gain_interaction", "simule_gain_inelastique", "simule_gain_menage", "simule_gain_elast_perso")) print(c(g, sum((d[[g]] > 0) != (d$simule_gagnant == "1"), na.rm = TRUE)))
print(table(d$variante_taxe_info, d$variante_progressivite))
print(table(d$variante_monetaire, d$apres_modifs))
print(table(gj = d$gilets_jaunes, sout = d$gilets_jaunes_soutien))
in1060 <- function(p) !is.na(p) & p >= 10 & p <= 60
cat("p10-p60 resp or spouse (non-single):", sum(in1060(d$percentile_revenu) | (d$nb_adultes > 1 & in1060(d$percentile_revenu_conjoint))), "\n")
cat("p10-p60 resp or spouse (any):", sum(in1060(d$percentile_revenu) | in1060(d$percentile_revenu_conjoint)), "\n")
cat("feedback & |gain|<50 & simule_gain_interaction:", sum(d$variante_taxe_info == "f" & abs(d$simule_gain) < 50), "\n")
print(table(d$traite_cible, d$percentile_revenu <= as.numeric(d$cible)))
print(table(d$traite_cible_conjoint, d$percentile_revenu_conjoint <= as.numeric(d$cible), d$nb_adultes > 1))
