load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-b/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
objs <- ls()
for (o in objs) { x <- get(o); cat("==", o, class(x)[1], if (is.data.frame(x)) paste(dim(x), collapse="x") else length(x), "\n")
  if (is.character(x)) print(x) }
cat("\n== names(s)\n"); print(names(s))
