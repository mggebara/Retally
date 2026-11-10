suppressPackageStartupMessages({library(readr); library(dplyr)})
R <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/seeded/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
for (b in 1:2) {
  d <- read_csv(file.path(R, sprintf("expBbatch%d.csv", b)), col_types = cols(.default = "c"),
                name_repair = "minimal")
  nl <- apply(d, 1, function(r) sum(lengths(regmatches(r[!is.na(r)], gregexpr("\n", r[!is.na(r)])))))
  cols_nl <- apply(d[-(1:2), ], 2, function(x) any(grepl("\n", x)))
  cat("B batch", b, "records", nrow(d), "\n")
  cat("newlines in first 4 records:", nl[1:4], "\n")
  cat("data records with newline:", sum(nl[-(1:2)] > 0), "\n")
  cat("columns with newline in data rows:", names(d)[cols_nl], "\n")
  w <- which(nl[-(1:2)] > 0) + 2
  if (length(w)) print(data.frame(rec = w, nl = nl[w], test10 = d$test10[w], tr = d$treatment[w]))
  cat("first 3 data recs treatment/test10/Finished/Progress:\n")
  print(as.data.frame(d[3:5, c("treatment","test10","Finished","Progress","FinLit3")]))
}
