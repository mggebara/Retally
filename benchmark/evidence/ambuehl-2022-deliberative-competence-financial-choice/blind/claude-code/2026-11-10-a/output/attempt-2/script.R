D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read.csv(file.path(D, f), check.names = FALSE, colClasses = "character", encoding = "UTF-8", fileEncoding = "UTF-8-BOM")
A <- NULL
for (i in 1:8) {
  x <- rd(sprintf("expAbatch%d.csv", i))[-1, ]
  x$excluded <- NULL
  x$batch <- i
  A <- if (is.null(A)) x else rbind(A[, intersect(names(A), names(x))], x[, intersect(names(A), names(x))])
}
A$done <- A$test1 != "" & A$V10 == "1"
cat("A rows", nrow(A), "done", sum(A$done), " test1 nonempty", sum(A$test1 != ""), "\n")
print(table(batch = A$batch, treat = A$treatment, done = A$done))
Ad <- A[A$done, ]
show <- function(v) {
  cat("\n#### ", v, "\n")
  for (b in 1:8) for (t in c("0", "1")) {
    z <- tolower(trimws(Ad[[v]][Ad$batch == b & Ad$treatment == t]))
    if (length(z)) { tb <- sort(table(z), decreasing = TRUE)[1:min(4, length(unique(z)))]; cat("b", b, "t", t, ":", paste(names(tb), tb, sep = "=", collapse = " ; "), "\n") }
  }
}
for (v in c("Q124", "code treat", "Q125", "Q130", "codeWT", "codeWC", "Q122", "Q127")) if (v %in% names(Ad)) show(v)
num <- function(v) suppressWarnings(as.numeric(v))
cat("\nMedian page-submit times by batch x treat\n")
for (v in c("TimeTreat_3", "TimeContro_3", "TimeInstr1_3", "TimeInstr2_3", "TimeInstr3_3", "Q133_3", "Q134_3")) {
  if (!v %in% names(Ad)) next
  m <- tapply(num(Ad[[v]]), list(Ad$batch, Ad$treatment), function(z) round(median(z, na.rm = TRUE), 1))
  cat(v, "\n"); print(m)
}
cat("\nNon-missing counts TimeTreat_3 / TimeContro_3 by batch x treat\n")
print(tapply(!is.na(num(Ad$TimeTreat_3)), list(Ad$batch, Ad$treatment), sum))
print(tapply(!is.na(num(Ad$TimeContro_3)), list(Ad$batch, Ad$treatment), sum))
cat("dates by batch\n"); print(tapply(substr(Ad$V8, 1, 10), Ad$batch, function(z) paste(range(z), collapse = " to ")))
# score key: mean Score-sum by option
sc <- num(Ad$SC0_0)
cat("\nA: mean SC0_0 by option and question (n)\n")
for (q in 1:10) { z <- Ad[[paste0("test", q)]]; m <- tapply(sc, z, mean); n <- table(z); cat("test", q, ":", paste0(names(m), "=", round(m, 2), "(", n, ")", collapse = " "), "\n") }
fit <- lm(sc ~ 0 + ., data = data.frame(sc = sc, lapply(setNames(1:10, paste0("q", 1:10)), function(q) factor(Ad[[paste0("test", q)]]))))
print(round(coef(fit), 2))
# choice coding examples
for (r in which(Ad$batch == 2)[1:3]) {
  cat("\n-- A subj", r, "treat", Ad$treatment[r], "line1", Ad$line1[r], "amt1", Ad$amt1[r], "line2", Ad$line2[r], "amt2", Ad$amt2[r], "dec", Ad$decision_index[r], "\n")
  for (k in 1:20) {
    c1 <- paste0("iMPL", k, "_1_", 1:11, ": 1"); c2 <- paste0("iMPL", k, "_2_", 3:12, ": 1")
    cat(k, substr(Ad[[paste0("T", k)]][r], 1, 60), "| L1:", paste(unlist(Ad[r, c1]), collapse = ""), "| L2:", paste(unlist(Ad[r, c2]), collapse = ""), "| sw", Ad[[paste0("switch", k)]][r], "\n")
  }
}
cat("\nA value sets in list cols:", paste(unique(unlist(Ad[, grep("^iMPL", names(Ad))])), collapse = ","), "\n")
# B
B <- rbind(cbind(rd("expBbatch1.csv")[-(1:2), ], batch = 1), cbind(rd("expBbatch2.csv")[-(1:2), ], batch = 2))
B$done <- B$test1 != "" & B$Finished == "1"
cat("\nB rows", nrow(B), "done", sum(B$done), "test1 nonempty", sum(B$test1 != ""), "\n")
print(table(batch = B$batch, treat = B$treatment, done = B$done))
print(table(Finished = B$Finished, Progress = B$Progress, test1ne = B$test1 != "")[, , ])
Bd <- B[B$done, ]
cat("B value sets in list cols:", paste(unique(unlist(Bd[, grep("^iMPL", names(Bd))])), collapse = ","), "\n")
cat("ID dupes A:", sum(duplicated(Ad$amt_id)), " B:", sum(duplicated(Bd$amt_id)), "\n")
sc <- num(Bd$SC0)
cat("\nB: mean SC0 by option\n")
for (q in 1:10) { z <- Bd[[paste0("test", q)]]; m <- tapply(sc, z, mean); n <- table(z); cat("test", q, ":", paste0(names(m), "=", round(m, 2), "(", n, ")", collapse = " "), "\n") }
fit <- lm(sc ~ 0 + ., data = data.frame(sc = sc, lapply(setNames(1:10, paste0("q", 1:10)), function(q) factor(Bd[[paste0("test", q)]]))))
print(round(coef(fit), 2))
for (r in 1:3) {
  cat("\n-- B subj", r, "treat", Bd$treatment[r], "line1", Bd$line1[r], "amt1", Bd$amt1[r], "line2", Bd$line2[r], "amt2", Bd$amt2[r], "dec", Bd$decision_index[r], "\n")
  for (k in 1:20) {
    c1 <- grep(paste0("^iMPL", k, "-1#"), names(Bd), value = TRUE); c2 <- grep(paste0("^iMPL", k, "-2#"), names(Bd), value = TRUE)
    cat(k, substr(Bd[[paste0("T", k)]][r], 1, 60), "| L1:", paste(unlist(Bd[r, c1]), collapse = ""), "| L2:", paste(unlist(Bd[r, c2]), collapse = ""), "| sw", Bd[[paste0("switch", k)]][r], "\n")
  }
}
cat("B T-text uniqueness:", sapply(1:20, function(k) length(unique(Bd[[paste0("T", k)]]))), "\n")
cat("A T-text uniqueness:", sapply(1:20, function(k) length(unique(Ad[[paste0("T", k)]]))), "\n")
