suppressMessages(library(readr))
D <- "<repo>/benchmark/.cache/claude-code/arias-2022-changing-tides-climate-migration/independent/2026-11-01-a/mount/arias_2022_changing_tides_climate_migration"
chv <- c("force_choice","Q184","Q186","Q188","Q190","Q192","Q194","Q196","Q198")
for (f in c("Climate Migration 2_ Conjoint- USA_September 10, 2019_08.56.csv","Climate Migration 2_ Conjoint- Germany_September 11, 2019_02.58.csv")) {
  y <- suppressWarnings(read_csv(file.path(D,f), col_types=cols(.default="c")))[-(1:2),]
  cat("\n====", f, "\n")
  nch <- rowSums(!is.na(y[,chv]))
  print(table(Status=y$Status, nchoices=nch))
  print(table(Finished=y$Finished, nchoices=nch))
  # gaps: a later task answered while an earlier missing?
  gaps <- apply(!is.na(y[,chv]), 1, function(r) any(diff(as.integer(r)) > 0))
  cat("rows with gaps", sum(gaps), "\n")
  cat("pairs by status: "); print(tapply(nch, y$Status, sum))
  # check whether ratings exist w/o choice
  cat("RATE_MIG1 nonNA", sum(!is.na(y$RATE_MIG1)), " Q168 nonNA", sum(!is.na(y$Q168)), "\n")
  # duplicates by IP or psid
  cat("dup psid", sum(duplicated(y$psid[!is.na(y$psid) & nch>0])), " dup IP", sum(duplicated(y$IPAddress[nch>0])), " psid NA among answered", sum(is.na(y$psid[nch>0])), "\n")
  cat("DistributionChannel:"); print(table(y$DistributionChannel, nch>0))
  # attribute order constant within respondent across tasks?
  same <- sapply(2:9, function(k) mean(y[[paste0("F-",k,"-1")]] == y[["F-1-1"]]))
  print(round(same,3))
}
