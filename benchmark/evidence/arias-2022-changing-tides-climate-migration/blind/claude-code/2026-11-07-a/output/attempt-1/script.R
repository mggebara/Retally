suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-07-a/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read_csv(file.path(D,f), col_types=cols(.default="c"), show_col_types=FALSE)
  cat("=====", f, nrow(x), "\n")
  nm <- names(x)
  print(nm[!grepl("^F-", nm)])
  keep <- intersect(c("Status","Progress","Finished","DistributionChannel","RATE_MIG1","RATE_MIG2","force_choice","Q168","Q169","Q184","Q89","SURVEY_HISTORY","psid","F-1-1","F-1-1-1","pid","TREATMENT"), nm)
  print(as.data.frame(t(x[1:2, keep])))
  x <- x[-(1:2),]
  cat("nrow data", nrow(x), "\n")
  for (v in intersect(c("Status","Finished","DistributionChannel","Q184","Q198","force_choice","Q168","Q89","TREATMENT","F-1-1","F-1-3","F-1-1-1","F-9-2-7"), nm)) { cat("--", v, "\n"); print(table(x[[v]], useNA="a")) }
  print(table(is.na(x$`F-1-1-1`), is.na(x$Q184)))
  print(head(sort(table(x$Progress),decreasing=TRUE),10))
  cat("dup psid", sum(duplicated(x$psid[!is.na(x$psid)])), " dup RespId", sum(duplicated(x$ResponseId)), "\n")
  ch <- c("Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
  ch <- intersect(ch, nm)
  print(table(rowSums(!is.na(x[,ch]))))
}
