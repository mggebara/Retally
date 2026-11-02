load("<repo>/benchmark/.cache/claude-code/douenne-2022-yellow-vests-carbon-tax/blind/2026-11-02-a/mount/douenne_2022_yellow_vests_carbon_tax/yellow_vests_aej_ep-0faf9e7121ba1f67b1f5b327ed55efcc1665daec/code/after_preparation.RData")
print(ls())
cat(names(s), sep="\n")
for (o in ls()) if (is.character(get(o)) && length(get(o))<200) {cat("==",o,"\n"); print(get(o))}
