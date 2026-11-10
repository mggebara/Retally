# Exploratory run: inspect raw Qualtrics files (no estimates)
suppressPackageStartupMessages(library(readr))
base <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tb <- function(x, n = 12) { t <- sort(table(x, useNA = "ifany"), decreasing = TRUE); print(head(t, n)) }
for (b in 1:8) {
  f <- file.path(base, sprintf("expAbatch%d.csv", b))
  d <- suppressWarnings(read_csv(f, col_types = cols(.default = "c"), progress = FALSE))
  names(d)[1] <- "V1"
  d <- d[-1, ]
  cat("\n===== A batch", b, "rows", nrow(d), "\n")
  cat("Status:"); tb(d$V7); cat("Finished:"); tb(d$V10)
  cat("treatment:"); tb(d$treatment)
  cat("TimeTreat_3 nonempty:", sum(!is.na(d$TimeTreat_3)), " TimeContro_3 nonempty:", sum(!is.na(d$TimeContro_3)), "\n")
  cat("treatment x TimeTreat nonempty:\n"); print(table(d$treatment, !is.na(d$TimeTreat_3), useNA = "ifany"))
  cat("code treat:"); tb(tolower(trimws(d$`code treat`)), 6)
  cat("Q130:"); tb(tolower(trimws(d$Q130)), 6)
  cat("test1:"); tb(d$test1, 8); cat("test6:"); tb(d$test6, 8)
  cat("T const:", all(sapply(paste0("T", 1:20), function(v) length(unique(na.omit(d[[v]]))) <= 1)), "\n")
  cat("T1/T11/T20:", unique(na.omit(d$T1))[1], "|", unique(na.omit(d$T11))[1], "|", unique(na.omit(d$T20))[1], "\n")
  cat("iMPL1_1_1:"); tb(d$`iMPL1_1_1: 1`); cat("iMPL1_2_5:"); tb(d$`iMPL1_2_5: 1`)
  cat("switch1:"); tb(d$switch1); cat("amt_id dup:", sum(duplicated(na.omit(d$amt_id))), " NA amt:", sum(is.na(d$amt_id)), "\n")
  cat("nonNA test1:", sum(!is.na(d$test1)), " nonNA iMPL20_1_1:", sum(!is.na(d$`iMPL20_1_1: 1`)), "\n")
  if ("excluded" %in% names(d)) { cat("excluded nonNA:", sum(!is.na(d$excluded)), "\n") }
  if (b == 1) { cat("SC0_0:"); tb(d$SC0_0); cat("SC0_1:"); tb(d$SC0_1); cat("SC0_2:"); tb(d$SC0_2); cat("rule72:"); tb(d$rule72) }
}
for (b in 1:2) {
  f <- file.path(base, sprintf("expBbatch%d.csv", b))
  d <- suppressWarnings(read_csv(f, col_types = cols(.default = "c"), progress = FALSE))
  cat("\n===== B batch", b, "rows", nrow(d), "\n")
  print(as.data.frame(d[1:2, c("StartDate", "Status", "Finished", "treatment", "test1")]))
  d <- d[-(1:2), ]
  cat("Status:"); tb(d$Status); cat("Finished:"); tb(d$Finished); cat("Progress:"); tb(d$Progress, 6)
  cat("treatment:"); tb(d$treatment); cat("DistributionChannel:"); tb(d$DistributionChannel)
  cat("treatment x Finished:\n"); print(table(d$treatment, d$Finished, useNA = "ifany"))
  cat("test1:"); tb(d$test1, 8); cat("test6:"); tb(d$test6, 8)
  cat("T const:", all(sapply(paste0("T", 1:20), function(v) length(unique(na.omit(d[[v]]))) <= 1)), "\n")
  for (v in paste0("T", 1:20)) cat(v, ":", unique(na.omit(d[[v]]))[1], "\n")
  cat("iMPL1-1_1:"); tb(d$`iMPL1-1#1_iMPL1-1_1`); cat("iMPL1-2_5:"); tb(d$`iMPL1-2#1_iMPL1-2_5`)
  for (v in c("exclude2","exclude3","exclude4","exclude5","switch1","SC0","amt_id")) { cat(v, ":"); tb(d[[v]], 6) }
  cat("amt_id dup:", sum(duplicated(na.omit(d$amt_id))), "\n")
  cat("Q names:", paste(grep("^Q[0-9]+$", names(d), value = TRUE), collapse = " "), "\n")
  cat("Q142..Q200 nonNA:\n"); print(sapply(d[, intersect(c("Q142","Q146","Q156","Q166","Q178","Q180","Q182","Q186","Q188","Q190","Q192","Q194","Q196","Q198","Q200","Q361","Q364","Q370","Q373"), names(d))], function(z) sum(!is.na(z))))
}
