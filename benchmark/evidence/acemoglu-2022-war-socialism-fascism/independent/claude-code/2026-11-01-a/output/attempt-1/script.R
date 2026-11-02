library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-01-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
lab <- sapply(d, function(x) { l <- attr(x,"label"); if (is.null(l)) "" else l })
nn <- sapply(d, function(x) sum(!is.na(x)))
nm <- names(d)
base <- sub("_?[0-9]+$","",nm)
tb <- table(base)
for (i in seq_along(nm)) {
  if (tb[base[i]] > 5 && grepl("[0-9]$", nm[i])) next
  cat(nm[i], "|", lab[i], "| n=", nn[i], "| mean=", if (is.numeric(d[[i]])) signif(mean(d[[i]],na.rm=TRUE),4) else "", "\n")
}
cat("\nFAMILIES:\n"); big <- tb[tb>5]; for (b in names(big)) { ex <- nm[base==b]; cat(b, length(ex), head(ex,3), "|", lab[match(ex[1],nm)], "\n") }
