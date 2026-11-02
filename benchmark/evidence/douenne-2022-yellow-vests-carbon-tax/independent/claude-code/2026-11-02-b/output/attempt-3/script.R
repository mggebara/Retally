load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
y <- s[["simule_gain_interaction"]]
cat("isS4:", isS4(y), " typeof:", typeof(y), "\n")
r1 <- try({ z <- y; attributes(z) <- NULL; head(z) }); print(r1)
r2 <- try({ z <- y; z <- unclass(z); head(z) }); print(r2)
cat("attr names:", paste(names(attributes(y)), collapse=","), "\n")
strip <- function(y) { lab <- NULL
  a <- attributes(y)
  z <- y; attributes(z) <- NULL
  if (is.character(z) || is.numeric(z) || is.logical(z) || is.integer(z)) {}
  list(z = z, a = names(a)) }
cls <- sapply(s, function(x) class(x)[1]); print(table(cls))
st <- strip(s[["gagnant_categorie"]]); print(head(st$z)); print(st$a)
a <- attributes(s[["gagnant_categorie"]]); for (n in names(a)) if (n != ".Data") { cat("--", n, "\n"); try(print(utils::head(a[[n]], 20))) }
