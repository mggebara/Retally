load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
cl <- function(x){ lv <- attr(x, "levels"); if (!is.null(lv)) { y <- x; attributes(y) <- NULL; return(lv[y]) }; y <- tryCatch({attributes(x) <- NULL; x}, error=function(e) rep(NA, length(x))); if (isS4(y)) y <- unclass(y); y }
lab <- function(v) { a <- attr(s[[v]], "label"); if (is.null(a)) a <- attr(s[[v]], "annotation"); tryCatch(as.character(cl(a)), error=function(e) "?") }
for (v in c("variante_monetaire","apres_modifs","variante_taxe_info","variante_partielle","info_CC","traite_cible","traite_cible_conjoint","win_cible_category","tax_cible_acceptance",
  "simule_gain","simule_gain_cible","simule_gain_interaction","percentile_revenu","percentile_revenu_conjoint","revenu_conjoint","single","Revenu","Revenu2","Simule_gain","Simule_gain2","biais_sur","simule_gagnant","cible","categorie_cible","versement_cible","sample","mauvaise_qualite","taxe_info_approbation","gagnant_info_categorie","convaincu_cible"))
  cat(v, ":", lab(v), "\n")
d <- data.frame(sg = as.numeric(cl(s$simule_gain)), fb = cl(s$variante_taxe_info), eff = cl(s$taxe_efficace) == "Oui",
  vm = cl(s$variante_monetaire), am = cl(s$apres_modifs), cc = cl(s$info_CC), pm = cl(s$info_PM), single = cl(s$single),
  p1 = as.numeric(cl(s$percentile_revenu)), p2 = as.numeric(cl(s$percentile_revenu_conjoint)), nad = cl(s$nb_adultes), rc = as.numeric(cl(s$revenu_conjoint)))
cat("\nfb & |sg|<50:", sum(d$fb=="f" & abs(d$sg) < 50), " <=50:", sum(d$fb=="f" & abs(d$sg) <= 50), "\n")
cat("eff by vm:\n"); print(tapply(d$eff, d$vm, mean)); cat("eff by am:\n"); print(tapply(d$eff, d$am, mean)); cat("eff by cc:\n"); print(tapply(d$eff, d$cc, mean))
print(table(d$vm, d$am))
cat("\np2 for single:\n"); print(summary(d$p2[d$single==1])); print(summary(d$rc[d$single==1]))
in1 <- d$p1 >= 10 & d$p1 <= 60; in2 <- d$p2 >= 10 & d$p2 <= 60
cat("p10-60 any:", sum(in1 | in2), " any w/ single excl:", sum(in1 | (in2 & d$single==0)), "\n")
for (lo in c(10)) for (hi in c(60)) { cat("strict:", sum((d$p1>lo & d$p1<hi) | (d$p2>lo & d$p2<hi)), sum((d$p1>lo & d$p1<hi) | (d$p2>lo & d$p2<hi & d$single==0)), "\n") }
print(table(cl(s$categorie_cible), cl(s$cible)))
