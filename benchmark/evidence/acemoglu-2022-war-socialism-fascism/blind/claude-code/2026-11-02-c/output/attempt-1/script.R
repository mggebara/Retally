library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-02-c/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
cat(dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
pref <- sub("_?[0-9]+$", "", nm)
tb <- table(pref)
cat("Prefix groups with >5 members:\n"); print(tb[tb > 5])
single <- nm[pref %in% names(tb[tb <= 5])]
for (v in single) cat(v, "|", lab[v], "| NA:", sum(is.na(d[[v]])), "| mean:", suppressWarnings(mean(as.numeric(d[[v]]), na.rm=TRUE)), "\n")
for (p in names(tb[tb > 5])) { v <- nm[pref == p][1:3]; cat("GROUP", p, ":", v, "|", lab[v[1]], "\n") }
