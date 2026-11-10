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
    cat("batch", b, "iMPL3 labels (tail):\n"); print(sapply(lab, function(s) substr(s, nchar(s) - 25, nchar(s))))
  }
  d <- d[-1, ]; d$batch <- b
  A[[b]] <- d[, c("V1", "treatment", "amt_id", "batch", "SC0_0", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
A <- bind_rows(A)
dB <- list()
for (b in 1:2) {
  d <- rd(file.path(base, sprintf("expBbatch%d.csv", b)))
  if (b == 1) { lab <- unlist(d[1, grep("^iMPL3-", names(d))]); cat("B iMPL3 labels (tail):\n"); print(sapply(lab, function(s) substr(s, nchar(s) - 25, nchar(s)))) }
  d <- d[-(1:2), ]; d$batch <- b
  dB[[b]] <- d[, c("ResponseId", "DistributionChannel", "treatment", "amt_id", "batch", "SC0", paste0("test", 1:10), grep("^iMPL", names(d), value = TRUE))]
}
B <- bind_rows(dB)
l1 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_1_%d: 1", k, j) else sprintf("iMPL%d-1#1_iMPL%d-1_%d", k, k, j)
l2 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_2_%d: 1", k, j) else sprintf("iMPL%d-2#1_iMPL%d-2_%d", k, k, j)
mat <- function(d, cols) { m <- sapply(d[, cols], as.numeric); if (is.null(dim(m))) m <- matrix(m, nrow = 1); m }
defs <- function(d, exp) {
  d <- d[rowSums(!is.na(d[, paste0("test", 1:10)])) > 0, ]
  n <- nrow(d)
  res <- matrix(FALSE, n, 7, dimnames = list(NULL, c("chg2_any", "chg2_or_rev_any", "chg2_or_rev_l1", "merged_chg2", "chg2_l1", "l2_contra", "rev_l2only")))
  for (k in 1:20) {
    m1 <- mat(d, l1(exp, k, 1:11)); m2 <- mat(d, l2(exp, k, 3:12))
    c1 <- rowSums(m1[, -1] != m1[, -11]); c2 <- rowSums(m2[, -1] != m2[, -10])
    r1 <- rowSums(m1[, -11] > m1[, -1]) > 0; r2 <- rowSums(m2[, -10] > m2[, -1]) > 0
    n1 <- rowSums(m1)
    # merged: list1 amounts strictly above x+1.8 (i.e. >= x+2), then list2, then list1 amounts <= x
    mg <- sapply(1:n, function(i) {
      x <- 2 * n1[i] - 2
      amts1 <- 22 - 2 * (1:11)
      hi <- m1[i, amts1 >= x + 2]; lo <- m1[i, amts1 <= x]
      s <- c(hi, m2[i, ], lo); sum(diff(s) != 0)
    })
    res[, 1] <- res[, 1] | c1 >= 2 | c2 >= 2
    res[, 2] <- res[, 2] | c1 >= 2 | c2 >= 2 | r1 | r2
    res[, 3] <- res[, 3] | c1 >= 2 | c2 >= 2 | r1
    res[, 4] <- res[, 4] | mg >= 2
    res[, 5] <- res[, 5] | c1 >= 2
    res[, 6] <- res[, 6] | (n1 < 11 & rowSums(m2) == 0)
    res[, 7] <- res[, 7] | r2
  }
  cat("\n#### Experiment", exp, "completes", n, "\n")
  print(colSums(res))
  cat("merged_chg2 or rev any:", sum(res[, 4] | res[, 2]), "\n")
  dup <- d$amt_id[duplicated(d$amt_id) & !is.na(d$amt_id)]
  cat("dup id rows defs:\n"); print(res[d$amt_id %in% dup, , drop = FALSE])
  # number of lists with reversals per subject among those flagged only by reversal
  invisible(res)
}
defs(A, "A")
defs(B %>% filter(is.na(DistributionChannel) | DistributionChannel != "preview"), "B")
# answer key checks vs Qualtrics score sums
chk <- function(d, sc, key, lab) {
  d <- d[rowSums(!is.na(d[, paste0("test", 1:10)])) > 0, ]
  cor <- sapply(1:10, function(q) as.numeric(!is.na(d[[paste0("test", q)]]) & d[[paste0("test", q)]] == as.character(key[q])))
  s <- rowSums(cor); y <- as.numeric(d[[sc]])
  cat(lab, ": share score==sum:", mean(s == y, na.rm = TRUE), " mean diff:", mean(y - s, na.rm = TRUE), "\n")
  # leave-one-out: which question's inclusion explains mismatch
  for (q in 1:10) cat("  drop q", q, ":", round(mean(s - cor[, q] == y, na.rm = TRUE), 3))
  cat("\n")
}
kA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3)
chk(A, "SC0_0", kA, "A key")
chk(A, "SC0_0", replace(kA, 9, 4), "A key q9=4")
chk(A, "SC0_0", replace(kA, 2, 5), "A key q2=5")
kB <- c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1)
Bc <- B %>% filter(is.na(DistributionChannel) | DistributionChannel != "preview")
chk(Bc, "SC0", kB, "B key")
chk(Bc, "SC0", c(kB[1:5], rep(0, 5)), "B key compounding only")
