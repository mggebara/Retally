suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="unique"))
cl <- function(s) gsub("[\r\n\t]+", " ", s)
options(width=200)
# ---- key search helper
keysearch <- function(df, qs, score) {
  key <- sapply(qs, function(q) { t <- table(df[[q]]); names(t)[which.max(t)] })
  ok <- !is.na(score)
  for (it in 1:5) for (q in qs) {
    best <- key[q]; bm <- -1
    for (c in unique(na.omit(df[[q]]))) {
      k2 <- key; k2[q] <- c
      s <- rowSums(sapply(qs, function(qq) !is.na(df[[qq]]) & df[[qq]] == k2[qq]))
      m <- sum(s[ok] == score[ok]); if (m > bm) { bm <- m; best <- c }
    }
    key[q] <- best
  }
  s <- rowSums(sapply(qs, function(qq) !is.na(df[[qq]]) & df[[qq]] == key[qq]))
  cat("key:", paste(qs, key, sep="=", collapse=" "), " exact matches", sum(s[ok]==score[ok]), "of", sum(ok), "\n")
  print(table(score - s))
  key
}
A <- list()
for (i in 1:8) { x <- rd(sprintf("expAbatch%d.csv", i)); x <- x[-1,]; x$batch <- i; A[[i]] <- x }
cn <- Reduce(intersect, lapply(A, names))
a <- bind_rows(lapply(A, function(x) x[, cn]))
fin <- a[!is.na(a$test1), ]
keysearch(fin, paste0("test", 1:10), as.numeric(fin$SC0_0))
keysearch(fin, paste0("test", 1:5), as.numeric(fin$SC0_0))
# ---- B
B1 <- rd("expBbatch1.csv"); B2 <- rd("expBbatch2.csv")
lab <- B1[1:2, ]
cat("B names:\n"); print(names(B1)[!grepl("Timing|First Click|Last Click|Page Submit|Click Count|RANK|GROUP", names(B1))])
cat("row2 sample:", unlist(B1[2, 1:20]), "\n")
for (q in c("iMPL1-1#1_iMPL1-1_1", "iMPL1-2#1_iMPL1-2_3", "iMPL1-2#1_iMPL1-2_12")) if (q %in% names(B1)) cat("LABEL", q, ":", substr(cl(lab[[q]][1]), 1, 1500), "\n")
b <- bind_rows(B1[-(1:2), ], B2[-(1:2), ])
b$file <- rep(1:2, c(nrow(B1)-2, nrow(B2)-2))
cat("B rows", nrow(b), "\n")
print(table(b$file, b$Finished, useNA="a")); print(table(b$DistributionChannel, useNA="a")); print(table(b$Status, useNA="a"))
print(table(b$treatment, !is.na(b$test1), useNA="a"))
fb <- b[!is.na(b$test1), ]
cat("B with test", nrow(fb), "unique ids", length(unique(fb$amt_id)), "\n")
print(table(fb$DistributionChannel, fb$treatment, useNA="a"))
for (q in paste0("test", 1:10)) { cat(q, "\n"); print(table(fb$treatment, fb[[q]], useNA="a")) }
for (q in paste0("test", 1:10)) cat("LABEL", q, ":", substr(cl(lab[[q]][1]), 1, 300), "\n")
keysearch(fb, paste0("test", 1:10), as.numeric(fb$SC0))
impl <- grep("^iMPL", names(fb), value=TRUE); cat("n iMPL cols", length(impl), "\n"); print(head(impl, 30)); print(tail(impl, 5))
v <- unlist(fb[, impl]); print(table(v, useNA="a"))
print(table(sapply(fb[, impl], function(z) sum(!is.na(z)))))
print(as.data.frame(t(fb[1:3, c(impl[1:21], "switch1")])))
