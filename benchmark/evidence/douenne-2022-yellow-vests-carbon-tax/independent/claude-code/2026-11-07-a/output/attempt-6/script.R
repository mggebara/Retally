D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(D, envir=e)
s <- e$s
strip <- function(y) { if (isS4(y)) { attributes(y) <- NULL; y } else { a <- unclass(y); attr(a, "label") <- NULL; a } }
eff <- strip(s$taxe_efficace) == "Oui"
for (z in c("apres_modifs","variante_monetaire","info_CC","info_PM")) { zz <- as.numeric(strip(s[[z]])); cat(z, tapply(eff, zz, mean), "\n") }
print(table(as.numeric(strip(s$apres_modifs)), as.numeric(strip(s$variante_monetaire))))
print(summary(as.Date(s$date)))
print(tapply(as.Date(s$date), strip(s$apres_modifs), range))
p1 <- s$percentile_revenu; p2 <- s$percentile_revenu_conjoint; na <- as.numeric(strip(s$nb_adultes))
k1 <- p1 >= 10 & p1 <= 60; k2 <- na > 1 & p2 >= 10 & p2 <= 60
cat("p10-60 count a:", sum(k1 | k2), " b (no adults cond):", sum(k1 | (p2>=10 & p2<=60)), " single-based:", sum(k1 | (strip(s$single)==0 & p2>=10 & p2<=60)), "\n")
print(table(strip(s$single), na))
