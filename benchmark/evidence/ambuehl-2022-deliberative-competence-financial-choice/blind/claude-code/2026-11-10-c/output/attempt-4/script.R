# Exploratory run 3: multiple-switching definitions, list-2 labels, answer-key check vs Qualtrics score (no estimates)
suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressWarnings(suppressMessages(read_csv(f, col_types = cols(.default = "c"), progress = FALSE, name_repair = "minimal")))
A <- list()
for (b in 1:8) {
  d <- rd(file.path(base, sprintf("expAbatch%d.csv", b)))
  names(d)[1] <- "V1"
  if (b %in% c(1, 3, 8)) {
    lab <- unlist(d[1, grep("^iMPL3_", names(d))])
  }
  d <- d[-1, ]; d$batch <- b
  A[[b]] <- d[, c("V1", "treatment", "amt_id", "batch", "SC0_0", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
A <- bind_rows(A)
dB <- list()
for (b in 1:2) {
  d <- rd(file.path(base, sprintf("expBbatch%d.csv", b)))
  d <- d[-(1:2), ]; d$batch <- b
  dB[[b]] <- d[, c("ResponseId", "DistributionChannel", "treatment", "amt_id", "batch", "SC0", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
B <- bind_rows(dB)
l1 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_1_%d: 1", k, j) else sprintf("iMPL%d-1#1_iMPL%d-1_%d", k, k, j)
l2 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_2_%d: 1", k, j) else sprintf("iMPL%d-2#1_iMPL%d-2_%d", k, k, j)
mat <- function(d, cols) { m <- sapply(d[, cols], as.numeric); if (is.null(dim(m))) m <- matrix(m, nrow = 1); m }
defs <- function(d, exp) {
  d <- d[rowSums(!is.na(d[, paste0("test", 1:10)])) > 0, ]
  n <- nrow(d); nm <- c("V1_rev2_n1in1to10", "V2_rev2_n1ge1", "V3_rev2_n1le10", "V4_merged_xfirst", "V5_rev2_n2notall", "V6_chg2_rev1_only", "V7_all_rev")
  res <- matrix(FALSE, n, length(nm), dimnames = list(NULL, nm))
  vals <- matrix(NA, n, 20)
  for (k in 1:20) {
    m1 <- mat(d, l1(exp, k, 1:11)); m2 <- mat(d, l2(exp, k, 3:12))
    c1 <- rowSums(m1[, -1] != m1[, -11]); c2 <- rowSums(m2[, -1] != m2[, -10])
    r1 <- rowSums(m1[, -11] > m1[, -1]) > 0; r2 <- rowSums(m2[, -10] > m2[, -1]) > 0
    n1 <- rowSums(m1); n2 <- rowSums(m2)
    base <- c1 >= 2 | c2 >= 2 | r1
    res[, 1] <- res[, 1] | base | (r2 & n1 >= 1 & n1 <= 10)
    res[, 2] <- res[, 2] | base | (r2 & n1 >= 1)
    res[, 3] <- res[, 3] | base | (r2 & n1 <= 10)
    mg <- sapply(1:n, function(i) { x <- 2 * n1[i] - 2; a1 <- 22 - 2 * (1:11); s <- c(m1[i, a1 > x], m2[i, ], m1[i, a1 <= x]); sum(diff(s) != 0) })
    res[, 4] <- res[, 4] | mg >= 2 | r1
    res[, 5] <- res[, 5] | base | (r2 & n2 > 0 & n2 < 10)
    res[, 6] <- res[, 6] | base
    res[, 7] <- res[, 7] | base | r2
    vals[, k] <- 2 * n1 + 0.2 * n2 - 2.1
  }
  cat("\n#### Experiment", exp, "completes", n, "\n"); print(colSums(res))
  ok <- !res[, 7]
  cat("mean simple valuation by list k=1..10 (non-switchers, V7):\n"); print(round(colMeans(vals[ok, 1:10]), 2))
  R <- rep(c(20, 18, 16, 14, 12), 2)
  cat("share simple val > R+0.5 by k:\n"); print(round(colMeans(vals[ok, 1:10] > matrix(R, sum(ok), 10, byrow = TRUE) + 0.5), 3))
  cat("mean complex valuation by list k=11..20:\n"); print(round(colMeans(vals[ok, 11:20]), 2))
}
defs(A, "A")
defs(B %>% filter(is.na(DistributionChannel) | DistributionChannel != "preview"), "B")
