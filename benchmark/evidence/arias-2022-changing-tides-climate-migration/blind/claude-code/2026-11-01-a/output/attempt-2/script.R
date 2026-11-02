suppressMessages(library(tidyverse))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/blind/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
chq <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  cat("=====", f, "\n")
  d <- read_csv(file.path(D,f), col_types=cols(.default="c"), show_col_types=FALSE)[-(1:2),]
  nch <- rowSums(!is.na(d[,chq]))
  cat("n with >=1 choice:", sum(nch>0), "\n")
  print(table(Status=d$Status, anychoice=nch>0))
  print(table(Finished=d$Finished, nch))
  cat("choices answered total:", sum(nch), " profiles:", 2*sum(nch), "\n")
  cat("dup psid among anychoice:", sum(duplicated(d$psid[nch>0 & !is.na(d$psid)])), "\n")
  # levels
  levs <- unlist(d[, grep("^F-[0-9]-[12]-[0-9]$", names(d))])
  print(sort(table(levs)))
  nm <- unlist(d[, grep("^F-[0-9]-[0-9]$", names(d))]); print(table(nm))
  # check whether attribute order constant within respondent across tasks
  same <- sapply(1:nrow(d), function(i) all(sapply(2:9, function(k) all(unlist(d[i, paste0("F-",k,"-",1:7)]) == unlist(d[i, paste0("F-1-",1:7)])))))
  cat("attr order constant within respondent:", mean(same), "\n")
}
