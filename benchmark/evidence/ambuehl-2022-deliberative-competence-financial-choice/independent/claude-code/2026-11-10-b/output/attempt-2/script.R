suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 220)
rd <- function(f) read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet")
num <- function(v) suppressWarnings(as.numeric(v))

# ---------- Experiment A: labels of the video-related columns per batch
vidcols <- c("Q117", "Q122", "codeWT", "Q127", "codeWC", "Q124", "code treat", "Q125", "Q130", "Q120", "Q119", "Q121", "Q111", "Q123", "Q18")
A <- list()
for (b in 1:8) {
  x <- rd(sprintf("expAbatch%d.csv", b))
  lab <- x[1, ]
  x <- x[-1, ]
  x$batch <- b
  cat("\n==== A batch", b, "\n")
  for (cc in intersect(vidcols, names(x))) {
    cat(cc, "LABEL:", gsub("\\s+", " ", substr(lab[[cc]], 1, 600)), "\n")
    v <- x[[cc]]; v <- v[!is.na(v)]
    cat("   values (by treatment):\n")
    print(table(x[[cc]][!is.na(x[[cc]])] |> tolower() |> substr(1, 25), x$treatment[!is.na(x[[cc]])]))
  }
  A[[b]] <- x
}
common <- Reduce(intersect, lapply(A, names))
A <- bind_rows(lapply(A, function(x) x[, common]))
cat("\nA total rows", nrow(A), "\n")

mplcols <- function(nm, k, l, j, exp) {
  if (exp == "A") paste0("iMPL", k, "_", l, "_", j, ": 1") else paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)
}
parse_mpl <- function(x, exp) {
  out <- list()
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) num(x[[mplcols(names(x), k, 1, j, exp)]]))
    L2 <- sapply(3:12, function(j) num(x[[mplcols(names(x), k, 2, j, exp)]]))
    if (is.null(dim(L1))) L1 <- matrix(L1, nrow = 1)
    if (is.null(dim(L2))) L2 <- matrix(L2, nrow = 1)
    na1 <- rowSums(is.na(L1)); na2 <- rowSums(is.na(L2))
    nonmono <- function(M) apply(M, 1, function(r) { r <- r[!is.na(r)]; any(diff(r) < 0) })
    ms1 <- nonmono(L1); ms2 <- nonmono(L2)
    nswitch1 <- apply(L1, 1, function(r) sum(abs(diff(r[!is.na(r)]))))
    nswitch2 <- apply(L2, 1, function(r) sum(abs(diff(r[!is.na(r)]))))
    ones1 <- rowSums(L1 == 1, na.rm = TRUE)
    sw <- num(x[[paste0("switch", k)]])
    out[[k]] <- data.frame(row = seq_len(nrow(x)), task = k, na1, na2, ms1, ms2, nswitch1, nswitch2, ones1, sw,
                           l2all0 = rowSums(L2 == 0, na.rm = TRUE) == 10, l2all1 = rowSums(L2 == 1, na.rm = TRUE) == 10,
                           l1all0 = ones1 == 0, l1all1 = ones1 == 11)
  }
  bind_rows(out)
}
pa <- parse_mpl(A, "A")
cat("\nA: switch var vs ones1 agreement (non-NA sw):\n"); print(with(pa[!is.na(pa$sw) & pa$na1 == 0, ], table(sw == ones1)))
cat("A: na1 distribution:\n"); print(table(pa$na1)); print(table(pa$na2))

summ <- function(x, p, label) {
  per <- p %>% group_by(row) %>% summarise(anyNA = any(na1 > 0 | na2 > 0), allNA = all(na1 == 11), ms_within = any(ms1 | ms2),
                                          ms_l1 = any(ms1), ms_l2 = any(ms2), ms_cross = any(l2all0 & !l1all0),
                                          ms_twoplus = any(nswitch1 >= 2 | nswitch2 >= 2), l1edge0 = sum(l1all0), l1edge1 = sum(l1all1), .groups = "drop")
  x2 <- cbind(x, per[match(seq_len(nrow(x)), per$row), -1])
  x2
}
A2 <- summ(A, pa, "A")
A2$Status <- A2$V7; A2$Finished <- A2$V10
tst <- paste0("test", 1:10)
A2$testNA <- rowSums(is.na(sapply(tst, function(t) num(A2[[t]]))))
cat("\nA crosstab Status x Finished:\n"); print(table(A2$Status, A2$Finished, useNA = "a"))
cat("A Finished==1 & Status==0: anyNA MPL / testNA\n")
f <- A2$Finished == "1" & A2$Status == "0"
print(table(anyNA = A2$anyNA[f], testNA = A2$testNA[f]))
cat("A by batch, f & complete:\n")
cmp <- f & !A2$anyNA & A2$testNA == 0
print(table(A2$batch[cmp], A2$treatment[cmp]))
cat("A complete N =", sum(cmp), " unique amt_id =", length(unique(A2$amt_id[cmp])), "\n")
cat("complete & any test answered & all MPL regardless of status: ", sum(!A2$anyNA & A2$testNA == 0), "\n")
cat("Status values among complete-data rows:\n"); print(table(A2$Status[!A2$anyNA & A2$testNA == 0], A2$Finished[!A2$anyNA & A2$testNA == 0], useNA = "a"))
for (crit in c("ms_within", "ms_l1", "ms_l2", "ms_cross", "ms_twoplus")) {
  cat("A", crit, ":", sum(A2[[crit]][cmp]), " | within ms_within or cross:", sum((A2$ms_within | A2$ms_cross)[cmp]), "\n")
}
dup <- A2$amt_id[cmp][duplicated(A2$amt_id[cmp])]
cat("A duplicated amt_id among complete:", dup, "\n")
print(A2[cmp & A2$amt_id %in% dup, c("batch", "amt_id", "treatment", "ms_within", "ms_cross", "V8")])
cat("A edge cases (list1 all immediate / all future) counts:", sum(A2$l1edge0[cmp]), sum(A2$l1edge1[cmp]), "\n")

# test answer key check vs SC0_0
keyA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3)
TA <- sapply(tst, function(t) num(A2[[t]]))
scA <- rowSums(sweep(TA, 2, keyA, "==") * 1)
cat("A key score vs SC0_0 agreement among complete:\n"); print(table(scA[cmp] == num(A2$SC0_0[cmp])))
print(head(cbind(scA, num(A2$SC0_0))[cmp & scA != num(A2$SC0_0), ], 20))

# ---------- Experiment B
B <- list()
for (b in 1:2) {
  x <- rd(sprintf("expBbatch%d.csv", b))
  x <- x[-(1:2), ]
  x$batch <- b
  B[[b]] <- x
}
cat("\nB names equal:", identical(names(B[[1]])[1:779], names(B[[2]])[1:779]), "\n")
B <- bind_rows(B)
cat("B rows", nrow(B), "\n")
print(table(B$Status, B$Finished, useNA = "a")); print(table(B$DistributionChannel, useNA = "a"))
pb <- parse_mpl(B, "B")
cat("B: switch var vs ones1 agreement:\n"); print(with(pb[!is.na(pb$sw) & pb$na1 == 0, ], table(sw == ones1)))
B2 <- summ(B, pb, "B")
B2$testNA <- rowSums(is.na(sapply(tst, function(t) num(B2[[t]]))))
fB <- B2$Finished == "1" & B2$Status == "0"
print(table(anyNA = B2$anyNA[fB], testNA = B2$testNA[fB]))
cmpB <- fB & !B2$anyNA & B2$testNA == 0
cat("B complete N =", sum(cmpB), " unique amt_id =", length(unique(B2$amt_id[cmpB])), "\n")
print(table(B2$batch[cmpB], B2$treatment[cmpB]))
for (crit in c("ms_within", "ms_l1", "ms_l2", "ms_cross", "ms_twoplus")) cat("B", crit, ":", sum(B2[[crit]][cmpB]), " | within or cross:", sum((B2$ms_within | B2$ms_cross)[cmpB]), "\n")
dupB <- B2$amt_id[cmpB][duplicated(B2$amt_id[cmpB])]
cat("B duplicated amt_id:", dupB, "\n")
cat("A ids also in B:", sum(unique(B2$amt_id[cmpB]) %in% A2$amt_id[cmp]), "\n")
TB <- sapply(tst, function(t) num(B2[[t]]))
for (t in tst) { cat(t, "\n"); print(table(TB[cmpB, t], B2$treatment[cmpB])) }
# brute-force key for B control questions, compounding key assumed as A
sc0 <- num(B2$SC0)
comp <- rowSums(sweep(TB[, 1:5], 2, keyA[1:5], "==") * 1)
resid <- sc0 - comp
grid <- expand.grid(lapply(6:10, function(i) 1:max(TB[, i], na.rm = TRUE)))
best <- sapply(seq_len(nrow(grid)), function(g) { s <- rowSums(sweep(TB[cmpB, 6:10], 2, unlist(grid[g, ]), "==") * 1); mean(s == resid[cmpB]) })
cat("B best control key:", unlist(grid[which.max(best), ]), "match", max(best), "\n")
cat("B SC0 vs comp sum dist:\n"); print(summary(resid[cmpB]))
