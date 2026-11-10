# Exploratory run 16: locate the endline bribe variable/sample (counts only; no estimates)
suppressPackageStartupMessages({library(haven); library(dplyr)})
B <- "<repo>/benchmark/.cache/claude-code/balan-2022-local-elites-state-capacity/independent/2026-11-10-d/mount/balan_2022_local_elites_state_capacity/Replication Materials - Updated October 2025/Data/01_base"
ra <- zap_labels(read_dta(file.path(B, "admin_data/randomization_assignment.dta")))
ra$trt <- ra$treatment; ra$trt[ra$a7 == 654] <- 2
scan <- function(f, lo, hi) {
  d <- read_dta(file.path(B, f))
  cat("\n=====", f, nrow(d), "rows\n")
  a7 <- as.numeric(d$a7); trt <- ra$trt[match(a7, ra$a7)]
  cl <- trt %in% c(1, 2)
  cat("C+L rows:", sum(cl), "\n")
  for (v in names(d)) {
    x <- d[[v]]
    nn <- sum(!is.na(x[cl]) & !(is.character(x[cl]) & x[cl] == ""))
    if (nn >= lo & nn <= hi) {
      lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
      tb <- if (length(unique(x)) <= 6) paste(names(table(zap_labels(x[cl]))), table(zap_labels(x[cl])), sep = ":", collapse = " ") else "many"
      cat(sprintf("%-30s nn=%d  %s  [%s]\n", v, nn, substr(lab, 1, 90), tb))
    }
  }
  invisible(d)
}
e16 <- scan("survey_data/endline_2016campaign_noPII.dta", 1100, 1250)
e1 <- scan("survey_data/endline_round1_noPII.dta", 1100, 1250)
# other payments ~2407
cat("\n--- ~2407 candidates in endline_2016campaign\n")
a7 <- as.numeric(e16$a7); trt <- ra$trt[match(a7, ra$a7)]; cl <- trt %in% c(1,2)
for (v in grep("bribe|transport|pay|fee|other", names(e16), value = TRUE)) {
  x <- e16[[v]]; nn <- sum(!is.na(x[cl]))
  lab <- attr(x, "label"); if (is.null(lab)) lab <- ""
  cat(sprintf("%-30s nn=%d  %s\n", v, nn, substr(lab, 1, 100)))
}
cat("\nendline_2016campaign key vars:\n")
for (v in grep("^code|treat|tmt|dup|resp|round|survey|stratum", names(e16), value = TRUE)) { x <- e16[[v]]; lab <- attr(x, "label"); cat(v, ":", if (is.null(lab)) "" else substr(lab, 1, 80), " nonNA C+L:", sum(!is.na(x[cl])), " nu:", length(unique(x)), "\n") }
