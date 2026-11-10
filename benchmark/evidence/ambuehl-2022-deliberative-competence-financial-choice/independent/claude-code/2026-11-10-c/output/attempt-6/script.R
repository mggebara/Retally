# Exploratory 6: list offending MPL patterns of reverse-only subjects (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D,f), col_types=cols(.default="c"), name_repair="minimal", progress=FALSE)
A <- bind_rows(lapply(1:8, function(i) {x <- rd(sprintf("expAbatch%d.csv",i)); names(x)[1] <- "V1"; x <- x[-1,]; x$batch <- i; x}))
A <- A[!is.na(A$test1),]
A$arm <- ifelse(A$batch %in% c(1,2,4,5), ifelse(A$treatment=="1","T","C"), ifelse(A$treatment=="1","SO","RO"))
B <- bind_rows(lapply(1:2, function(i) {x <- rd(sprintf("expBbatch%d.csv",i)); x <- x[-(1:2),]; x$batch <- i; x}))
B <- B[!is.na(B$test1) & B$DistributionChannel != "preview",]
names(B) <- sub("^iMPL(\\d+)-(\\d)#1_iMPL\\d+-\\d_(\\d+)$", "iMPL\\1_\\2_\\3: 1", names(B))
B$arm <- ifelse(B$treatment=="1","T","C")
nsw <- function(z) sum(diff(z) != 0)
for (nm in c("A","B")) {
  df <- get(nm); n <- nrow(df)
  rows <- list()
  for (r in 1:20) {
    f <- sapply(1:11, function(k) as.integer(df[[sprintf("iMPL%d_1_%d: 1", r, k)]]))
    s <- sapply(3:12, function(k) as.integer(df[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
    for (i in 1:n) {
      fi <- f[i,]; si <- s[i,]
      bad <- c(f2 = nsw(fi) >= 2, s2 = nsw(si) >= 2, frev = any(diff(fi) < 0), srev = any(diff(si) < 0))
      if (any(bad)) rows[[length(rows)+1]] <- data.frame(i=i, arm=df$arm[i], id=df$amt_id[i], round=r, first=paste(fi, collapse=""), second=paste(si, collapse=""), n1=sum(fi), f2=bad[1], s2=bad[2], frev=bad[3], srev=bad[4])
    }
  }
  bb <- bind_rows(rows)
  subj <- bb |> group_by(i) |> summarise(any2 = any(f2 | s2), nrounds = n())
  cat("\n=====", nm, " flagged subjects:", nrow(subj), " with any2:", sum(subj$any2), "\n")
  ro <- bb[bb$i %in% subj$i[!subj$any2], ]
  print(ro[, c("i","arm","round","first","second","n1","frev","srev")], row.names=FALSE)
  cat("rounds-per-flagged-subject distribution:\n"); print(table(subj$nrounds))
}
