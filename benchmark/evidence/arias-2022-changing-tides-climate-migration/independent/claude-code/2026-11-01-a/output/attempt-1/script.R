suppressMessages(library(readr))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- suppressWarnings(read_csv(file.path(D,f), col_types=cols(.default="c")))
  cat("\n====", f, nrow(x), "rows\n")
  print(names(x)[50:120])
  print(as.character(x[1,c("Finished","Status","RATE_MIG1","force_choice","Q168","Q169","Q184","F-1-1","F-1-1-1","TREATMENT")]))
  print(as.character(x[2,c("Finished","Status","RATE_MIG1","force_choice","Q168","Q169","Q184","F-1-1","F-1-1-1")]))
  y <- x[-(1:2),]
  cat("Status:"); print(table(y$Status)); cat("Finished:"); print(table(y$Finished))
  cat("Q184:"); print(table(y$Q184, useNA="a")); cat("Q168:"); print(table(y$Q168, useNA="a"))
  cat("force_choice:"); print(table(y$force_choice, useNA="a"))
  ch <- grep("^Q1[0-9][0-9]$", names(y), value=TRUE)
  nn <- sapply(ch, function(v) sum(!is.na(y[[v]])))
  print(nn)
  cat("F-1-1 table:"); print(table(y$`F-1-1`, useNA="a"))
  cat("F-1-1-1 table:"); print(table(y$`F-1-1-1`, useNA="a"))
  cat("F-1-2-3:"); print(table(y$`F-1-2-3`, useNA="a"))
  cat("TREATMENT:"); print(table(y$TREATMENT, useNA="a"))
  cat("dup ResponseId", sum(duplicated(y$ResponseId)), " nonNA F-1-1-1", sum(!is.na(y$`F-1-1-1`)), "\n")
  cat("Progress:"); print(head(sort(table(y$Progress), decreasing=TRUE), 10))
}
