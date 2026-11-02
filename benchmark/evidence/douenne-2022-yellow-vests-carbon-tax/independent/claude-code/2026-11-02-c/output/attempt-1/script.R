set.seed(42)
base <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-02-c/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env()
load(base, envir = e)
objs <- ls(e)
for (o in objs) {
  x <- get(o, envir = e)
  cat("OBJ", o, class(x)[1], if (is.data.frame(x)) paste(dim(x), collapse="x") else length(x), "\n")
  if (is.character(x) && length(x) < 300) cat("   ", paste(x, collapse=" "), "\n")
}
s <- e$s
cat("\nCOLUMNS of s:\n")
print(names(s))
