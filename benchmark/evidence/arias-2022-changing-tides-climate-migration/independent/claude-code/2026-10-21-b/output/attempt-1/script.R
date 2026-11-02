D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read.csv(file.path(D,f), check.names=FALSE, stringsAsFactors=FALSE, encoding="UTF-8")
  cat("=====", f, nrow(x), ncol(x), "\n")
  print(names(x)[!grepl("^F-", names(x))])
  print(t(x[1:2, !grepl("^F-|Click|Submit", names(x))]))
  q <- grep("^Q1[6-9][0-9]$", names(x), value=TRUE)
  for (v in q) { cat(v, ":\n"); print(table(x[-(1:2), v], useNA="ifany")) }
  print(table(x$Finished[-(1:2)])); print(table(x$Status[-(1:2)])); print(summary(as.numeric(x$Progress[-(1:2)])))
  fc <- grep("^F-", names(x), value=TRUE); cat(length(fc), "F cols; first ones:\n"); print(head(fc, 80)); print(tail(fc, 20))
  print(x[3:5, c("F-1-1","F-1-2","F-1-1-1","F-1-2-1","F-1-1-6")])
  print(table(x[["F-1-1-1"]][-(1:2)]))
  print(table(x[["F-1-1"]][-(1:2)]))
  print(table(x$force_choice[-(1:2)])); print(head(table(x$Q89[-(1:2)]),10))
}
