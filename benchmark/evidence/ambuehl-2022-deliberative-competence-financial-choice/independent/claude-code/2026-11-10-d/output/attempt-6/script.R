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
getmat <- function(df, cf, k, l) { rr <- if (l == 1) 1:11 else 3:12; m <- sapply(rr, function(r) as.numeric(df[[cf(k, l, r)]])); if (!is.matrix(m)) m <- matrix(m, nrow=1); m }
nchg <- function(m) rowSums(m[, -1, drop=FALSE] != m[, -ncol(m), drop=FALSE])
nonmono <- function(m) rowSums(m[, -ncol(m), drop=FALSE] > m[, -1, drop=FALSE]) > 0
proc <- function(df, cf) {
  n <- nrow(df); ms1 <- ms2 <- nm1 <- nm2 <- matrix(FALSE, n, 20); val <- matrix(NA, n, 20); s0 <- matrix(NA, n, 20); k0 <- s0
  for (k in 1:20) {
    m1 <- getmat(df, cf, k, 1); m2 <- getmat(df, cf, k, 2)
    ms1[, k] <- nchg(m1) >= 2; ms2[, k] <- nchg(m2) >= 2
    nm1[, k] <- nonmono(m1); nm2[, k] <- nonmono(m2)
    s <- rowSums(m1); kk <- rowSums(m2); s0[, k] <- s; k0[, k] <- kk
    val[, k] <- 2 * s - 2.1 + 0.2 * kk
  }
  list(ms1=ms1, ms2=ms2, nm1=nm1, nm2=nm2, val=val, s=s0, k=k0)
}
for (nm in c("A", "B")) {
  df <- if (nm == "A") a else b; cf <- if (nm == "A") colA else colB
  p <- proc(df, cf); cat("==", nm, "\n")
  L1nm <- rowSums(p$nm1) > 0; L2nm <- rowSums(p$nm2) > 0; L1ms <- rowSums(p$ms1) > 0; L2ms <- rowSums(p$ms2) > 0
  edge <- (p$s == 0 | p$s == 11)
  L2nm_noedge <- rowSums(p$nm2 & !edge) > 0
  cand <- list(L1nm=L1nm, L2nm=L2nm, L1ms=L1ms, L2ms=L2ms, L1nm_or_L2ms=L1nm|L2ms, L1ms_or_L2nm=L1ms|L2nm, any_nm=L1nm|L2nm,
               nm_ge2tasks=(rowSums(p$nm1|p$nm2) >= 2), L1nm_or_L2nm_noedge=L1nm|L2nm_noedge)
  tc <- if (nm == "A") df$batch %in% c(1,2,4,5) else rep(TRUE, nrow(df))
  for (n in names(cand)) cat(sprintf("%-25s total %3d  keptTC %3d\n", n, sum(cand[[n]]), sum(!cand[[n]] & tc)))
  nmt <- rowSums(p$nm1 | p$nm2)
  cat("nonmono task count dist among flagged:\n"); print(table(nmt[nmt > 0]))
  for (i in which(nmt == 1)) { k <- which(p$nm1[i, ] | p$nm2[i, ]); cat(i, "task", k, " L1:", paste(getmat(df[i, ], cf, k, 1), collapse=""), " L2:", paste(getmat(df[i, ], cf, k, 2), collapse=""), "\n") }
}
