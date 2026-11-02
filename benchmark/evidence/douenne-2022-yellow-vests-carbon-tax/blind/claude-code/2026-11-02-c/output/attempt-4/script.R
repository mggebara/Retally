load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-c/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
cv <- function(x){ a <- attributes(x); v <- x; attributes(v) <- NULL; if (isS4(v)) v <- asS3(v, complete=FALSE)
  if (!is.null(a$levels)) v <- factor(a$levels[v], levels=a$levels); v }
lab <- function(nm) { a <- attributes(s[[nm]]); cat("\n## attrs of", nm, ":\n"); for (k in setdiff(names(a), c("levels","class","names"))) { cat(k, ": "); print(tryCatch(a[[k]], error=function(e) "ERR")) } }
for (nm in c("apres_modifs","variante_monetaire","info_CC","info_PM","taxe_efficace","tax_approval","simule_gagnant","simule_gain","win_cible_category","traite_cible","gilets_jaunes")) tryCatch(lab(nm), error=function(e) cat("labfail", nm, conditionMessage(e), "\n"))
for (nm in names(s)) s[[nm]] <- tryCatch(cv(s[[nm]]), error=function(e) NA)
d <- as.Date(substr(as.character(s$date), 1, 10))
cat("\ndate range\n"); print(range(d, na.rm=TRUE))
print(table(d, s$apres_modifs))
print(table(d, s$variante_monetaire))
eff <- s$taxe_efficace == "Oui"
print(summary(lm(eff ~ apres_modifs + variante_monetaire + info_CC + info_PM, data=s))$coefficients)
print(table(s$apres_modifs, s$variante_monetaire))
print(table(s$sample, s$apres_modifs))
