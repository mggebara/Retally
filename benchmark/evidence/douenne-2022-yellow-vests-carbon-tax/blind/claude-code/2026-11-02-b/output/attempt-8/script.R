load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
conv <- function(x) { lv <- attr(x, "levels"); cl <- as.vector(attr(x, "class")); attributes(x) <- NULL; x <- unclass(x)
  if (!is.null(lv) && any(cl == "factor")) x <- as.vector(lv)[x]; x }
for (v in c("taxe_approbation","taxe_info_approbation","taxe_feedback_approbation","gilets_jaunes","taxe_efficace","age","diplome4","taille_agglo","gauche_droite","interet_politique")) {
  x <- s[[v]]; cat("\n###", v, "typeof", typeof(x), "class", paste(class(x), collapse=","), "attrs", paste(names(attributes(x)), collapse=","), "\n")
  print(table(conv(x), useNA="ifany"))
}
vv <- (c("apres_modifs","variante_monetaire","info_CC","info_PM","taxe_efficace","date","single","traite_cible_conjoint","traite_cible",
  "gilets_jaunes_dedans","gilets_jaunes_soutien","Gilets_jaunes","variante_taxe_info","simule_gain","simule_gagnant","percentile_revenu","percentile_revenu_conjoint","cible","nb_adultes","revenu_conjoint"))
d <- as.data.frame(setNames(lapply(vv, function(v) conv(s[[v]])), vv), stringsAsFactors=FALSE)
cat("\n### taxe_efficace x apres_modifs\n"); print(prop.table(table(d$taxe_efficace, d$apres_modifs), 2))
cat("\n### taxe_efficace x variante_monetaire\n"); print(prop.table(table(d$taxe_efficace, d$variante_monetaire), 2))
cat("\n### date range by apres_modifs\n"); print(tapply(d$date, d$apres_modifs, function(z) range(z)))
cat("\n### single x traite_cible_conjoint\n"); print(table(d$single, d$traite_cible_conjoint))
cat("\n### single x nb_adultes\n"); print(table(d$single, d$nb_adultes))
cat("\n### dedans x soutien\n"); print(table(d$gilets_jaunes_dedans, d$gilets_jaunes_soutien)); print(table(d$Gilets_jaunes, d$gilets_jaunes_soutien))
f <- d$variante_taxe_info == "f"
cat("\n### N feedback & |gain|<50:", sum(f & abs(d$simule_gain) < 50), " <=50:", sum(f & abs(d$simule_gain) <= 50), "\n")
p1 <- d$percentile_revenu; p2 <- d$percentile_revenu_conjoint
cat("### N p10-p60 (resp or spouse):", sum((p1>=10 & p1<=60) | (d$single==0 & p2>=10 & p2<=60)), " incl singles spouse:", sum((p1>=10 & p1<=60) | (p2>=10 & p2<=60)), "\n")
cat("### check eligibility recompute: T1 = p1<=cible\n"); print(table(d$traite_cible, p1 <= as.numeric(d$cible)))
print(table(d$traite_cible_conjoint, p2 <= as.numeric(d$cible), d$single))
