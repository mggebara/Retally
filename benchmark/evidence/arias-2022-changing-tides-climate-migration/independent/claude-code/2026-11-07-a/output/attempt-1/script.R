suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-07-a/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  d <- read_csv(file.path(D,f), col_types=cols(.default="c"), show_col_types=FALSE)
  cat("=====", f, nrow(d), "\n")
  ch <- c("force_choice", grep("^Q1(8[4-9]|9[0-8])$", names(d), value=TRUE))
  print(ch)
  print(as.data.frame(d[1:3, intersect(c("Status","Finished","Progress","RATE_MIG1",ch,"F-1-1","F-1-1-1","F-1-2-1"), names(d))]))
  dd <- d[-(1:2),]
  print(table(dd$Status)); print(table(dd$Finished)); print(head(table(dd$Progress),10))
  for (c in ch) print(table(dd[[c]], useNA="always"))
  nm <- rowSums(!is.na(dd[,ch]))
  print(table(nm)); cat("sum choices", sum(nm), "\n")
  cat("nonmissing F-1-1-1", sum(!is.na(dd$`F-1-1-1`)), "\n")
  print(sapply(paste0("F-1-",1:7), function(v) paste(names(table(dd[[v]])), collapse="|")))
  for (v in paste0("F-1-1-",1:7)) print(table(dd[[v]], useNA="always"))
  if ("TREATMENT" %in% names(dd)) print(table(dd$TREATMENT, useNA="always"))
  cat("dup ids", sum(duplicated(dd$ResponseId)), "\n")
  print(table(Finished=dd$Finished, nm))
}
