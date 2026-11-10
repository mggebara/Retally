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
  L1nm <- rowSums(p$nm1) > 0
  tc <- if (nm == "A") df$batch %in% c(1,2,4,5) else rep(TRUE, nrow(df))
  dup <- df$amt_id %in% df$amt_id[duplicated(df$amt_id)]
  vars <- list(
    noedge = rowSums(p$nm2 & !(p$s == 0 | p$s == 11)) > 0,
    no_s0 = rowSums(p$nm2 & !(p$s == 0)) > 0,
    no_s11 = rowSums(p$nm2 & !(p$s == 11)) > 0,
    all = rowSums(p$nm2) > 0,
    noedge_plus_k0 = rowSums((p$nm2 | p$k == 0) & !(p$s == 0 | p$s == 11)) > 0,
    noedge_ms2 = rowSums(p$ms2 & !(p$s == 0 | p$s == 11)) > 0,
    none = rep(FALSE, nrow(df)))
  for (n in names(vars)) {
    f1 <- L1nm | vars[[n]]
    f2 <- (rowSums(p$ms1) > 0) | vars[[n]]
    cat(sprintf("L2 %-16s | L1nm: total %3d keptTC %3d dup %s | L1ms: total %3d keptTC %3d\n", n, sum(f1), sum(!f1 & tc), paste(f1[dup], collapse=","), sum(f2), sum(!f2 & tc)))
  }
  cat("table of s values (all cells):\n"); print(table(p$s))
}
