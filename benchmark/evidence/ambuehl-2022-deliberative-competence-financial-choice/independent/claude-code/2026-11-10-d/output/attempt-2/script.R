suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="unique"))
cl <- function(s, n=70) { s <- gsub("[\r\n\t]+", " ", s); ifelse(is.na(s), "NA", substr(s, 1, n)) }
dump <- function(x, rows) {
  for (j in seq_along(names(x))) {
    v <- sapply(rows, function(r) cl(x[[j]][r], 25))
    cat(sprintf("%4d %-22s | %s | %s\n", j, names(x)[j], cl(x[[j]][1], 90), paste(v, collapse=" | ")))
  }
}
a2 <- rd("expAbatch2.csv")
cat("##### A batch2\n"); dump(a2, 2:4)
b <- rd("expBbatch1.csv")
cat("##### B batch1 nrow", nrow(b), "\n"); dump(b, 3:5)
