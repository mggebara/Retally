D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/seeded/2026-11-02-b/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read.csv(file.path(D,f), stringsAsFactors=FALSE, check.names=FALSE, encoding="UTF-8")
  cat("====", f, nrow(x), ncol(x), "\n")
  print(names(x))
  print(x[1:3, c("ResponseId","force_choice","Q184","Status","Finished")])
  print(table(x$force_choice[-(1:2)], useNA="ifany"))
  print(table(x$Q198[-(1:2)], useNA="ifany"))
  fc <- grep("^F-", names(x), value=TRUE); cat(length(fc), "F cols\n"); print(head(fc, 30))
  print(x[3:5, fc[1:12]])
  print(table(x$Status[-(1:2)])); print(table(x$Finished[-(1:2)]))
  cat("nonempty ResponseId:", sum(x$ResponseId[-(1:2)]!=""), "\n")
  cat("rows with any choice:", sum(rowSums(x[-(1:2), c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")] != "") > 0), "\n")
  print(head(x$ResponseId[-(1:2)], 8))
}
