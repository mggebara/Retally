suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 200)
rd <- function(f) read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet")
for (f in c("expAbatch1.csv", "expAbatch5.csv", "expAbatch8.csv", "expBbatch1.csv")) {
  x <- rd(f)
  cat("\n=====", f, "\n")
  cn <- grep("^iMPL", names(x), value = TRUE)
  for (k in c(1, 2, 3, 4, 10, 11, 12, 20)) {
    ck <- cn[grepl(paste0("^iMPL", k, "[_-]"), cn)]
    lab <- sapply(ck, function(cc) { s <- gsub("\\s+", " ", x[[cc]][1]); substr(s, max(1, nchar(s) - 45), nchar(s)) })
    cat("task", k, "\n"); for (i in seq_along(ck)) cat("   ", ck[i], "=>", lab[i], "\n")
  }
}
