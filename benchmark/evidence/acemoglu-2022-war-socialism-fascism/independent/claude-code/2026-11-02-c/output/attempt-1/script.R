suppressMessages(library(haven))
d <- read_dta('<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/independent/2026-11-02-c/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta')
cat(nrow(d), ncol(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
nna <- sapply(d, function(x) sum(!is.na(x)))
pre <- sub("_?[0-9]+$", "", nm)
tab <- table(pre)
big <- names(tab)[tab > 15]
cat("Large families:\n"); print(tab[big])
for (i in seq_along(nm)) if (!(pre[i] %in% big)) cat(nm[i], "|", nna[i], "|", lab[i], "\n")
for (b in big) { j <- which(pre==b)[1:3]; for (i in j) cat("  ex:", nm[i], "|", nna[i], "|", lab[i], "\n") }
