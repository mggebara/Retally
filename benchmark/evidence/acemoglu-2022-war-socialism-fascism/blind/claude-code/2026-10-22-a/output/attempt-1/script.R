suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-10-22-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
cat("dims", dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
nn <- sapply(d, function(x) sum(!is.na(x)))
pref <- sub("_?[0-9]+$", "", nm)
tab <- table(pref)
big <- names(tab)[tab > 20]
cat("Large families:\n"); print(tab[big])
for (i in seq_along(nm)) if (!(pref[i] %in% big)) cat(sprintf("%-35s n=%5d %s\n", nm[i], nn[i], lab[i]))
for (b in big) { idx <- which(pref == b)[1:3]; for (i in idx) cat(sprintf("FAM %-30s n=%5d %s\n", nm[i], nn[i], lab[i])) }
