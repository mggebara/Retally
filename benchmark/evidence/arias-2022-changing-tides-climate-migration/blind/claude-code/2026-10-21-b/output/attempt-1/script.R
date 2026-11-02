suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-10-21-b/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read_csv(file.path(D,f), col_types=cols(.default="c"))
  cat("====", f, nrow(x), "\n")
  print(as.data.frame(t(x[1:2, c("Status","Progress","Finished","DistributionChannel","Q168","Q169","Q184","force_choice","RATE_MIG1","F-1-1","F-1-2","F-1-1-1","F-1-2-1","TREATMENT")])))
  x <- x[-(1:2),]
  cat("rows after header:", nrow(x), "\n")
  print(table(x$Status, useNA="a")); print(table(x$Finished, useNA="a")); print(table(x$DistributionChannel, useNA="a"))
  print(summary(as.numeric(x$Progress)))
  for (v in c("Q184","Q186","Q198","Q168","force_choice","RATE_MIG1","TREATMENT")) {cat(v,"\n"); print(table(x[[v]], useNA="a"))}
  cat("F-1-1 table\n"); print(table(x[["F-1-1"]], useNA="a")); print(table(x[["F-3-4"]], useNA="a"))
  cat("F-1-1-1 table\n"); print(head(sort(table(x[["F-1-1-1"]], useNA="a"),decreasing=TRUE),12))
  ch <- c("Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
  cat("nonmissing F-1-1-1:", sum(!is.na(x[["F-1-1-1"]])), " nonmissing Q184:", sum(!is.na(x$Q184)), " all 8 Q choices:", sum(rowSums(!is.na(x[,ch]))==8), " force_choice nonmiss:", sum(!is.na(x$force_choice)), "\n")
  cat("unique ResponseId", length(unique(x$ResponseId)), " psid uniq", length(unique(x$psid)), " pid uniq", length(unique(x$pid)),"\n")
  print(table(rowSums(!is.na(x[,c("force_choice",ch)]))))
}
x <- read_csv(file.path(D,"usclimate_exp1.csv"), col_types=cols(.default="c"))
cat("usclimate_exp1", nrow(x), ncol(x), "\n"); print(names(x)[1:30]); print(tail(names(x),60))
