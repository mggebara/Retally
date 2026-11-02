suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-10-22-a/mount/arias_2022_changing_tides_climate_migration"
ch <- c("Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
for (fn in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  cat("=====", fn, "\n")
  raw <- read_csv(file.path(D, fn), col_types = cols(.default="c"), show_col_types=FALSE)
  cat("nrow raw:", nrow(raw), "\n")
  print(t(raw[1:2, intersect(names(raw), c("Status","Finished","Progress","RATE_MIG1","RATE_MIG2","force_choice","Q168","Q169","Q184","Q182","Q183","Q198","TREATMENT","F-1-1","F-1-1-1","Q89"))]))
  d <- raw[-(1:2),]
  cat("rows data:", nrow(d), "\n")
  print(table(d$Status, useNA="ifany")); print(table(d$Finished, useNA="ifany"))
  print(head(sort(table(d$Progress)),15))
  for (v in intersect(names(d), c("Q168","Q169","Q184","Q182","Q183","Q198","RATE_MIG1","RATE_MIG2","force_choice","TREATMENT"))) {cat(v,"\n"); print(table(d[[v]], useNA="ifany"))}
  print(table(d$`F-1-1`, useNA="ifany")); print(table(d$`F-1-3`, useNA="ifany"))
  print(table(d$`F-1-1-1`, useNA="ifany"))
  cat("non-missing F-1-1-1:", sum(!is.na(d$`F-1-1-1`)), " F-9-2-7:", sum(!is.na(d$`F-9-2-7`)), "\n")
  cat("dup ResponseId:", sum(duplicated(d$ResponseId)), " dup psid:", sum(duplicated(d$psid[!is.na(d$psid)])), " na psid:", sum(is.na(d$psid)), "\n")
  cc <- intersect(names(d), c("force_choice", ch))
  cat("choice cols:", cc, "\n")
  print(table(rowSums(!is.na(d[, cc]))))
  print(table(Finished=d$Finished, nchoice=rowSums(!is.na(d[, cc]))))
}
