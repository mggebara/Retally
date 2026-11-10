suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 250)
rd <- function(f) {
  x <- read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE)
  x
}
for (b in 1:8) {
  x <- rd(sprintf("expAbatch%d.csv", b))
  cat("\n==== A batch", b, nrow(x), "rows\n")
  cat("row1 V1..V10:", unlist(x[1, 1:10]), "\n")
  x <- x[-1, ]
  cat("V7 (status?) table:"); print(table(x$V7, useNA = "a"))
  cat("V10 finished:"); print(table(x$V10, useNA = "a"))
  cat("treatment:"); print(table(x$treatment, useNA = "a"))
  if (b %in% c(1, 8)) {
    for (k in 1:20) cat("T", k, ":", paste(unique(x[[paste0("T", k)]]), collapse = " | "), "\n")
  } else {
    same <- all(sapply(1:20, function(k) length(unique(x[[paste0("T", k)]])) == 1))
    cat("T constant within batch:", same, "\n")
    cat("T1", unique(x$T1), " T11", unique(x$T11), "\n")
  }
  cat("switch1 sample:", head(x$switch1, 15), "\n")
  cat("switch11 sample:", head(x$switch11, 15), "\n")
  cat("excluded sample:", substr(head(x$excluded, 2), 1, 60), "\n")
  m1 <- grep("^iMPL1_", names(x), value = TRUE)
  print(head(x[, m1], 6))
  m11 <- grep("^iMPL11_", names(x), value = TRUE)
  print(head(x[, m11], 6))
  tc <- grep("^test[0-9]+$", names(x), value = TRUE)
  print(head(x[, tc], 6))
  print(head(x[, c("SC0_0", "SC0_1", "SC0_2", "payment_test", "payment_for_test", "test_payment", "consent", "amt_id")], 6))
  if (b == 1) {
    lab <- read_csv(file.path(D, "expAbatch1.csv"), col_types = cols(.default = "c"), n_max = 1)
    for (cc in c(tc, "SC0_0", "SC0_1", "SC0_2", "iMPL1_1_1: 1", "iMPL1_2_3: 1", "iMPL1_1_11: 1")) cat(cc, "=>", substr(lab[[cc]][1], 1, 400), "\n")
  }
}
for (b in 1:2) {
  x <- read_csv(file.path(D, sprintf("expBbatch%d.csv", b)), col_types = cols(.default = "c"), show_col_types = FALSE)
  cat("\n==== B batch", b, nrow(x), "rows,", ncol(x), "cols\n")
  print(names(x))
  cat("first 2 rows (labels) for first 60 cols:\n")
  for (j in seq_len(ncol(x))) {
    v <- x[[j]][1:5]
    cat(j, names(x)[j], "|", substr(paste(v, collapse = " || "), 1, 300), "\n")
  }
  if (b == 2) break
}
