library(readr); library(dplyr)
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-02-c/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  x <- read_csv(file.path(D,f), col_types=cols(.default="c"))
  cat("=====", f, nrow(x), "\n")
  print(unlist(x[1,grep("^Q1[0-9][0-9]$|^Q89$|force_choice|RATE_MIG|^F-1-1$|^F-1-1-1$|psid|TREATMENT", names(x))]))
  print(unlist(x[2,grep("^Q1[0-9][0-9]$|^F-1-1|Status|Finished|Progress", names(x))]))
  x <- x[-(1:2),]
  cat("Status:\n"); print(table(x$Status, useNA="a")); print(table(x$Finished, useNA="a"))
  for (v in c("force_choice","Q184","Q186","Q198","Q168","Q169","TREATMENT")) {cat(v,"\n"); print(table(x[[v]], useNA="a"))}
  cat("nonmissing F-1-1-1:", sum(!is.na(x$`F-1-1-1`)), "\n")
  ch <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
  ch <- ch[ch %in% names(x)]
  cat("n with any choice:", sum(rowSums(!is.na(x[,ch]))>0), " total choices:", sum(!is.na(x[,ch])), "\n")
  print(table(rowSums(!is.na(x[,ch]))))
  print(table(x$Q89, useNA="a"))
  print(table(x$`F-1-1`)); print(table(x$`F-1-1-1`))
  cat("dup psid:", sum(duplicated(x$psid[!is.na(x$psid)])), "\n")
}
