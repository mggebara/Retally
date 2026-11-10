D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/seeded/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read.csv(file.path(D, f), colClasses = "character", check.names = FALSE, na.strings = character(0), fileEncoding = "UTF-8-BOM")
for (b in 1:8) {
  x <- rd(sprintf("expAbatch%d.csv", b))
  cat("A", b, "nrow", nrow(x), "lines", length(readLines(file.path(D, sprintf("expAbatch%d.csv", b)), warn = FALSE)), "\n")
  cat("  first col1:", substr(x[[1]][1:3], 1, 30), "\n")
  cat("  treatment:"); print(table(x$treatment[-1], useNA = "ifany"))
  cat("  help_test blank:", sum(x$help_test[-1] == ""), " SC0_0:"); print(table(x$SC0_0[-1]))
  im <- grep("^iMPL", names(x), value = TRUE)
  cat("  n impl cols", length(im), " impl values:"); print(table(unlist(x[-1, im]), useNA = "ifany"))
  cat("  test1:"); print(table(x$test1[-1]))
}
for (b in 1:2) {
  x <- rd(sprintf("expBbatch%d.csv", b))
  cat("B", b, "nrow", nrow(x), "lines", length(readLines(file.path(D, sprintf("expBbatch%d.csv", b)), warn = FALSE)), "\n")
  for (r in 1:4) cat("  row", r, ":", substr(x[[1]][r], 1, 40), "|", substr(x$Status[r], 1, 30), "|", substr(x$treatment[r], 1, 30), "|", substr(x$test10[r], 1, 30), "\n")
  cat("  treatment:"); print(table(x$treatment[-(1:3)], useNA = "ifany"))
  cat("  status:"); print(table(x$Status[-(1:2)]))
  im <- grep("^iMPL", names(x), value = TRUE)
  cat("  n impl cols", length(im), " impl values:"); print(table(unlist(x[-(1:3), im]), useNA = "ifany"))
  cat("  test10 blank:", sum(x$test10[-(1:3)] == ""), "\n")
  cat("  test6:"); print(table(x$test6[-(1:3)]))
}
