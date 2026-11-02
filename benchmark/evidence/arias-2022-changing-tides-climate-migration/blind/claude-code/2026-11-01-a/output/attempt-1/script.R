suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  cat("=====", f, "\n")
  x <- read_csv(file.path(D,f), col_types=cols(.default="c"), show_col_types=FALSE)
  cat("nrow", nrow(x), "\n")
  lab <- x[1,]
  for (v in names(x)) if (!grepl("^F-|Click|Submit", v)) cat(v, "::", substr(lab[[v]],1,200), "\n")
  d <- x[-(1:2),]
  cat("N data rows", nrow(d), "\n")
  for (v in c("Status","Finished","DistributionChannel","UserLanguage","TREATMENT","Q89","SURVEY_HISTORY")) if (v %in% names(d)) {cat(v,"\n"); print(table(d[[v]], useNA="a"))}
  print(summary(as.numeric(d$Progress)))
  ch <- grep("^(Q1[6-9][0-9]|RATE|force)", names(d), value=TRUE)
  for (v in ch) {cat(v, ":"); print(table(d[[v]], useNA="a"))}
  cat("F-1-1 values\n"); print(table(d[["F-1-1"]], useNA="a")); print(table(d[["F-1-1-1"]], useNA="a"))
  cat("nonmissing F-1-1-1:", sum(!is.na(d[["F-1-1-1"]])), " F-9-2-7:", sum(!is.na(d[["F-9-2-7"]])), "\n")
  cat("unique ResponseId", n_distinct(d$ResponseId), " psid", n_distinct(d$psid), "\n")
}
