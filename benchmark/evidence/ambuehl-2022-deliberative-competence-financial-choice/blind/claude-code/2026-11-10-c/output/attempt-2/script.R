# Exploratory run 2: arms, completion, price-list coding, test answer keys (no estimates)
suppressPackageStartupMessages({library(readr); library(dplyr)})
base <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressWarnings(suppressMessages(read_csv(f, col_types = cols(.default = "c"), progress = FALSE, name_repair = "minimal")))
A <- list(); labsA <- NULL
for (b in 1:8) {
  d <- rd(file.path(base, sprintf("expAbatch%d.csv", b)))
  names(d)[1] <- "V1"
  if (b == 1) labsA <- unlist(d[1, paste0("test", 1:10)])
  d <- d[-1, ]
  d$batch <- b
  keep <- c("V1", "V7", "V10", "treatment", "amt_id", "batch", "rule72", "rule72_inv", "SC0_0", "test_payment", "payment_for_test",
            paste0("test", 1:10), paste0("switch", 1:20),
            grep("^iMPL", names(d), value = TRUE))
  A[[b]] <- d[, keep]
}
A <- bind_rows(A)
cat("A test labels:\n"); print(substr(labsA, 1, 90))
dB <- list(); labsB <- NULL
for (b in 1:2) {
  d <- rd(file.path(base, sprintf("expBbatch%d.csv", b)))
  if (b == 1) labsB <- unlist(d[1, paste0("test", 1:10)])
  d <- d[-(1:2), ]
  d$batch <- b
  keep <- c("ResponseId", "Status", "Finished", "Progress", "DistributionChannel", "treatment", "amt_id", "batch", "rule72", "rule72_inv", "SC0", "test_payment",
            paste0("test", 1:10), paste0("switch", 1:20), grep("^iMPL", names(d), value = TRUE))
  dB[[b]] <- d[, keep]
}
B <- bind_rows(dB)
cat("B test labels:\n"); print(substr(gsub("\n", " ", labsB), 1, 110))

l1 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_1_%d: 1", k, j) else sprintf("iMPL%d-1#1_iMPL%d-1_%d", k, k, j)
l2 <- function(exp, k, j) if (exp == "A") sprintf("iMPL%d_2_%d: 1", k, j) else sprintf("iMPL%d-2#1_iMPL%d-2_%d", k, k, j)
nchg <- function(m) { m <- as.matrix(m); apply(m, 1, function(r) { r <- as.numeric(r); r <- r[!is.na(r)]; if (length(r) < 2) 0 else sum(diff(r) != 0) }) }
explore <- function(d, exp) {
  cat("\n######## Experiment", exp, "rows", nrow(d), "\n")
  stopifnot(all(sapply(1:20, function(k) all(c(l1(exp, k, 1:11), l2(exp, k, 3:12)) %in% names(d)))))
  anytest <- rowSums(!is.na(d[, paste0("test", 1:10)])) > 0
  alltest <- rowSums(!is.na(d[, paste0("test", 1:10)])) == 10
  alllist <- sapply(1:20, function(k) !is.na(d[[l1(exp, k, 1)]]))
  cat("any test:", sum(anytest), " all test:", sum(alltest), " all 20 list1 answered:", sum(rowSums(alllist) == 20), "\n")
  print(table(anytest = anytest, all20 = rowSums(alllist) == 20))
  comp <- d[anytest, ]
  cat("completes:", nrow(comp), " dup amt_id among completes:", sum(duplicated(comp$amt_id[!is.na(comp$amt_id)])), "\n")
  print(comp$amt_id[duplicated(comp$amt_id) & !is.na(comp$amt_id)])
  ms1 <- sapply(1:20, function(k) nchg(comp[, l1(exp, k, 1:11)]))
  ms2 <- sapply(1:20, function(k) nchg(comp[, l2(exp, k, 3:12)]))
  cat("subjects with >=2 changes in some list1:", sum(apply(ms1 >= 2, 1, any)), "\n")
  cat("subjects with >=2 changes in some list1 or list2:", sum(apply(ms1 >= 2 | ms2 >= 2, 1, any)), "\n")
  # reverse single switch (1 then 0)
  rev1 <- sapply(1:20, function(k) { m <- sapply(comp[, l1(exp, k, 1:11)], as.numeric); apply(m, 1, function(r) { r <- r[!is.na(r)]; any(diff(r) < 0) }) })
  rev2 <- sapply(1:20, function(k) { m <- sapply(comp[, l2(exp, k, 3:12)], as.numeric); apply(m, 1, function(r) { r <- r[!is.na(r)]; any(diff(r) < 0) }) })
  cat("subjects with any 1->0 in list1:", sum(apply(rev1, 1, any)), " in list1 or 2:", sum(apply(rev1 | rev2, 1, any)), "\n")
  cat("subjects with >=2 changes OR any 1->0 (list1/2):", sum(apply(ms1 >= 2 | ms2 >= 2 | rev1 | rev2, 1, any)), "\n")
  # list2 missingness and switch var consistency
  n1 <- sapply(1:20, function(k) rowSums(sapply(comp[, l1(exp, k, 1:11)], as.numeric), na.rm = TRUE))
  sw <- sapply(1:20, function(k) as.numeric(comp[[paste0("switch", k)]]))
  cat("switch == number of 1s in list1 (share):", mean(sw == n1, na.rm = TRUE), " NA switch:", sum(is.na(sw)), "\n")
  na2 <- sapply(1:20, function(k) rowSums(is.na(comp[, l2(exp, k, 3:12)])))
  cat("list2 NA counts table:\n"); print(table(na2))
  cat("list1 n ones table:\n"); print(table(n1))
  cat("list2 n ones when list1 all ones (11):\n"); n2 <- sapply(1:20, function(k) rowSums(sapply(comp[, l2(exp, k, 3:12)], as.numeric), na.rm = TRUE)); print(table(n2[n1 == 11]))
  cat("list2 n ones when list1 no ones (0):\n"); print(table(n2[n1 == 0])); print(table(na2[n1 == 0]))
  cat("treatment:\n"); print(table(comp$treatment, comp$batch))
  for (q in 1:10) { cat("test", q, "by treatment:\n"); print(table(comp[[paste0("test", q)]], comp$treatment, useNA = "ifany")) }
  cat("rule72 by batch x treatment:\n"); print(table(comp$rule72, paste(comp$batch, comp$treatment)))
  sc <- if (exp == "A") comp$SC0_0 else comp$SC0
  cat("score var table:\n"); print(table(sc, useNA = "ifany")); cat("test_payment:\n"); print(table(comp$test_payment, useNA = "ifany"))
  # infer answer key: lm of score on option dummies
  y <- as.numeric(sc)
  for (q in 1:10) { v <- comp[[paste0("test", q)]]; cat("mean score var by option, test", q, ":\n"); print(round(tapply(y, v, mean, na.rm = TRUE), 2)) }
  invisible(comp)
}
explore(A, "A")
explore(B %>% filter(DistributionChannel != "preview" | is.na(DistributionChannel)), "B")
cat("B preview rows:", sum(B$DistributionChannel == "preview", na.rm = TRUE), " B status table:\n"); print(table(B$Status, !is.na(B$test1)))
cat("A status x anytest:\n"); print(table(A$V7, !is.na(A$test1)))
