suppressMessages(library(haven))
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-07-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
cat(dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
pref <- sub("[_0-9]+$", "", nm)
tb <- table(pref)
cat("Prefix groups with >5 members:\n"); print(tb[tb > 5])
small <- nm[pref %in% names(tb[tb <= 5])]
for (v in small) cat(v, "|", lab[v], "| nNA=", sum(is.na(d[[v]])), "| mean=", tryCatch(signif(mean(as.numeric(d[[v]]), na.rm=TRUE),4), error=function(e) NA), "\n")
for (p in names(tb[tb > 5])) { v <- nm[pref == p]; cat("GROUP", p, ":", head(v, 4), "... label of first:", lab[v[1]], "\n") }
