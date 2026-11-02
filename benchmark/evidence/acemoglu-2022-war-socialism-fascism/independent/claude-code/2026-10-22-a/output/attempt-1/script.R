library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-10-22-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
cat(dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
nn <- sapply(d, function(x) sum(!is.na(x)))
base <- sub("_?[0-9]+$", "", nm)
for (b in unique(base)) {
  idx <- which(base == b)
  if (length(idx) > 3) cat(sprintf("FAMILY %s (%d): e.g. %s | %s | n=%d\n", b, length(idx), nm[idx[1]], lab[idx[1]], nn[idx[1]]))
  else for (i in idx) cat(sprintf("%s | %s | n=%d\n", nm[i], lab[i], nn[i]))
}
