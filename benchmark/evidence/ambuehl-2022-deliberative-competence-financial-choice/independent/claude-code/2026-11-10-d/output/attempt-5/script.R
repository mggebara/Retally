suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="unique"))
options(width=200)
A <- list()
for (i in 1:8) { x <- rd(sprintf("expAbatch%d.csv", i)); x <- x[-1,]; x$batch <- i; A[[i]] <- x }
cn <- Reduce(intersect, lapply(A, names))
a <- bind_rows(lapply(A, function(x) x[, cn]))
a <- a[!is.na(a$test1), ]
B1 <- rd("expBbatch1.csv"); B2 <- rd("expBbatch2.csv")
b <- bind_rows(B1[-(1:2), ], B2[-(1:2), ])
b <- b[!is.na(b$test1) & b$DistributionChannel == "anonymous", ]
cat("A n", nrow(a), " B n", nrow(b), "\n")
colA <- function(k, l, r) sprintf("iMPL%d_%d_%d: 1", k, l, r)
colB <- function(k, l, r) sprintf("iMPL%d-%d#1_iMPL%d-%d_%d", k, l, k, l, r)
getmat <- function(df, cf, k, l) { rr <- if (l == 1) 1:11 else 3:12; sapply(rr, function(r) as.numeric(df[[cf(k, l, r)]])) }
nchg <- function(m) rowSums(m[, -1, drop=FALSE] != m[, -ncol(m), drop=FALSE])
nonmono <- function(m) rowSums(m[, -ncol(m), drop=FALSE] > m[, -1, drop=FALSE]) > 0  # a 1 followed by 0
proc <- function(df, cf) {
  n <- nrow(df); out <- list(); ms1 <- ms2 <- nm1 <- nm2 <- matrix(FALSE, n, 20); val <- matrix(NA, n, 20); swq <- matrix(NA, n, 20)
  for (k in 1:20) {
    m1 <- getmat(df, cf, k, 1); m2 <- getmat(df, cf, k, 2)
    ms1[, k] <- nchg(m1) >= 2; ms2[, k] <- nchg(m2) >= 2
    nm1[, k] <- nonmono(m1); nm2[, k] <- nonmono(m2)
    s <- rowSums(m1); kk <- rowSums(m2)
    swq[, k] <- as.numeric(df[[paste0("switch", k)]]) - s
    val[, k] <- 2 * s - 2.1 + 0.2 * kk
  }
  list(ms1=ms1, ms2=ms2, nm1=nm1, nm2=nm2, val=val, swq=swq)
}
for (nm in c("A", "B")) {
  df <- if (nm == "A") a else b; cf <- if (nm == "A") colA else colB
  p <- proc(df, cf)
  cat("==", nm, "\n")
  cat("switch var minus count of ones: "); print(table(p$swq, useNA="a"))
  cat("multi-switch list1 any:", sum(rowSums(p$ms1) > 0), " list2 any:", sum(rowSums(p$ms2) > 0), " either:", sum(rowSums(p$ms1 | p$ms2) > 0), "\n")
  cat("nonmono list1 any:", sum(rowSums(p$nm1) > 0), " list2 any:", sum(rowSums(p$nm2) > 0), " either:", sum(rowSums(p$nm1 | p$nm2) > 0), "\n")
  cat("either ms OR nonmono:", sum(rowSums(p$ms1 | p$ms2 | p$nm1 | p$nm2) > 0), "\n")
  cat("val range:"); print(summary(as.vector(p$val)))
  ex <- rowSums(p$ms1 | p$ms2) > 0
  cat("val among kept: s==0 cells", sum(p$val[!ex, ] < 0), " >20 cells", sum(p$val[!ex, ] > 20), "\n")
  cat("treatment x excluded\n"); print(table(df$treatment, ex))
  if (nm == "A") { print(table(df$batch, ex)); print(table(df$amt_id[duplicated(df$amt_id)])); print(ex[df$amt_id %in% df$amt_id[duplicated(df$amt_id)]]) }
}
