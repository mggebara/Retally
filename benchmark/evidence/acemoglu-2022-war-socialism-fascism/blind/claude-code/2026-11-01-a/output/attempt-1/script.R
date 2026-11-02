library(haven)
d <- read_dta("<repo>/benchmark/.cache/claude-code/acemoglu-2022-war-socialism-fascism/blind/2026-11-01-a/mount/acemoglu_2022_war_socialism_fascism/fascism_db.dta")
cat("dim", dim(d), "\n")
nm <- names(d)
lab <- sapply(d, function(x) { l <- attr(x, "label"); if (is.null(l)) "" else l })
nn <- sapply(d, function(x) sum(!is.na(x)))
pref <- sub("_?[0-9]+$", "", nm)
tp <- table(pref); big <- names(tp)[tp > 5]
cat("Prefix groups (>5 vars):\n"); print(tp[big])
for (i in seq_along(nm)) if (!(pref[i] %in% big)) cat(sprintf("%s | %s | n=%d | mean=%s\n", nm[i], lab[i], nn[i], if (is.numeric(d[[i]])) format(mean(d[[i]], na.rm=TRUE), digits=4) else "chr"))
for (b in big) { j <- which(pref==b)[1:3]; cat("GROUP", b, ":", paste(nm[j], lab[j], sep="=", collapse=" ; "), "\n") }
