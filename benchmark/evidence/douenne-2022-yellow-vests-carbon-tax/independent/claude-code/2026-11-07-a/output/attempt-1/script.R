D <- "<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/independent/2026-11-07-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData"
e <- new.env(); load(D, envir=e)
for (n in ls(e)) { o <- get(n, e); cat("==", n, class(o)[1], length(o), "\n"); if (is.character(o)) print(o) }
s <- e$s
cat(paste(names(s), collapse=" "), "\n")
