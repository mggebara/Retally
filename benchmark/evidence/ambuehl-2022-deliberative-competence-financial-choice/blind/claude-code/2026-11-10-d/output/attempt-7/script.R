suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tests <- paste0("test",1:10)
A <- list()
for (b in 1:8) {
  d <- suppressMessages(read_csv(file.path(D, sprintf("expAbatch%d.csv", b)), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="minimal"))
  names(d)[1] <- "V1"; d <- d[, names(d) != ""]
  d <- d[-1,]; d$batch <- b; A[[b]] <- d
}
A <- bind_rows(A)
A <- A[!is.na(A[["iMPL1_1_1: 1"]]) & rowSums(!is.na(A[,tests])) >= 9, ]
B <- list()
for (b in 1:2) {
  d <- read_csv(file.path(D, sprintf("expBbatch%d.csv", b)), col_types=cols(.default="c"), show_col_types=FALSE)
  d <- d[-(1:2),]; d$batch <- b; B[[b]] <- d
}
B <- bind_rows(B)
cat("B rows with MPL1 nonNA:", sum(!is.na(B[["iMPL1-1#1_iMPL1-1_1"]])), " with >=9 tests:", sum(rowSums(!is.na(B[,tests]))>=9), "\n")
B <- B[!is.na(B[["iMPL1-1#1_iMPL1-1_1"]]) & rowSums(!is.na(B[,tests])) >= 9, ]
cat("A n", nrow(A), " B n", nrow(B), "\n")
colA <- function(k, l, j) sprintf("iMPL%d_%d_%d: 1", k, l, j)
colB <- function(k, l, j) sprintf("iMPL%d-%d#1_iMPL%d-%d_%d", k, l, k, l, j)
proc <- function(d, colf) {
  n <- nrow(d); val <- matrix(NA, n, 20); nsw <- matrix(NA, n, 40); nonmono <- matrix(NA, n, 40); n1m <- matrix(NA,n,20)
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) as.numeric(d[[colf(k,1,j)]]))
    L2 <- sapply(3:12, function(j) as.numeric(d[[colf(k,2,j)]]))
    nsw[,2*k-1] <- rowSums(L1[,-1] != L1[,-11]); nsw[,2*k] <- rowSums(L2[,-1] != L2[,-10])
    nonmono[,2*k-1] <- rowSums(L1[,-11]==1 & L1[,-1]==0) > 0; nonmono[,2*k] <- rowSums(L2[,-10]==1 & L2[,-1]==0) > 0
    n1 <- rowSums(L1); m2 <- rowSums(L2==0); n1m[,k] <- n1
    val[,k] <- 2*n1 - 0.1 - 0.2*m2
  }
  list(val=val, nsw=nsw, nonmono=nonmono, n1=n1m)
}
pA <- proc(A, colA); pB <- proc(B, colB)
diag <- function(d, colf, p, nm) {
  n <- nrow(d)
  s1 <- matrix("", n, 20); s2 <- matrix("", n, 20)
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) d[[colf(k,1,j)]]); L2 <- sapply(3:12, function(j) d[[colf(k,2,j)]])
    s1[,k] <- apply(L1,1,paste,collapse=""); s2[,k] <- apply(L2,1,paste,collapse="")
  }
  nm1 <- p$nonmono[,seq(1,39,2)]; nm2 <- p$nonmono[,seq(2,40,2)]
  t1 <- p$nsw[,seq(1,39,2)]; t2 <- p$nsw[,seq(2,40,2)]
  cat("==", nm, "\n")
  cat("nonmono list1 any:", sum(rowSums(nm1)>0), " list2 any:", sum(rowSums(nm2)>0), "\n")
  cat("ge2 trans list1:", sum(rowSums(t1>=2)>0), " list2:", sum(rowSums(t2>=2)>0), "\n")
  cat("list2 all-zero (inconsistent) any:", sum(rowSums(matrix(s2=="0000000000",n))>0), "\n")
  cat("list1 starts with 1:", sum(rowSums(matrix(substr(s1,1,1)=="1",n))>0), "\n")
  nmc <- rowSums(nm1) + rowSums(nm2)
  cat("dist of #nonmono lists among flagged:\n"); print(table(nmc[nmc>0]))
  nmx <- sapply(1:20, function(k) grepl("10", substr(s1[,k],2,11)))
  cat("nonmono list1 ignoring line1, or list2 nonmono:", sum(rowSums(nmx)>0 | rowSums(nm2)>0), "\n")
  rev1 <- (t1==1 & nm1); rev2 <- (t2==1 & nm2)
  cat("subjects whose only violations are single reverse switches:", sum((rowSums(rev1)+rowSums(rev2))>0 & rowSums(t1>=2)==0 & rowSums(t2>=2)==0), "\n")
  dup <- which(d$amt_id %in% d$amt_id[duplicated(d$amt_id)])
  cat("dup rows nonmono counts:", nmc[dup], "\n")
  fl <- which(nmc>0)
  cat("examples of flagged sequences:\n")
  for (i in head(fl, 40)) { ks <- which(nm1[i,]|nm2[i,]); cat(i, d$treatment[i], ":", paste(sprintf("k%d %s|%s", ks, s1[i,ks], s2[i,ks]), collapse="  "), "\n") }
}
variants <- function(d, colf, nm) {
  n <- nrow(d); res <- list()
  ctr <- matrix(0, n, 20); cnm <- matrix(FALSE, n, 20); c01 <- matrix(0, n, 20); s01_1 <- matrix(0,n,20); s01_2 <- matrix(0,n,20)
  tr1 <- matrix(0,n,20); tr2 <- matrix(0,n,20); nm1 <- matrix(FALSE,n,20); nm2 <- matrix(FALSE,n,20); nm1x <- matrix(FALSE,n,20)
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) as.numeric(d[[colf(k,1,j)]])); L2 <- sapply(3:12, function(j) as.numeric(d[[colf(k,2,j)]]))
    n1 <- rowSums(L1)
    for (i in 1:n) {
      pos <- 11 - n1[i]  # insert list2 after list1 line 'pos' (amount 2*n1)
      seqc <- c(if (pos>=1) L1[i,1:pos] else NULL, L2[i,], if (pos<11) L1[i,(pos+1):11] else NULL)
      dd <- diff(seqc); ctr[i,k] <- sum(dd!=0); cnm[i,k] <- any(dd < 0); c01[i,k] <- sum(dd>0)
    }
    d1 <- t(apply(L1,1,diff)); d2 <- t(apply(L2,1,diff))
    tr1[,k] <- rowSums(d1!=0); tr2[,k] <- rowSums(d2!=0); nm1[,k] <- rowSums(d1<0)>0; nm2[,k] <- rowSums(d2<0)>0
    s01_1[,k] <- rowSums(d1>0); s01_2[,k] <- rowSums(d2>0)
    nm1x[,k] <- rowSums(d1[,-1,drop=FALSE]<0)>0
  }
  a <- function(m) sum(rowSums(m)>0)
  cat("==", nm, " n=", n, "\n")
  cat("combined trans>=2:", a(ctr>=2), " combined nonmono:", a(cnm), " combined 0->1 >=2:", a(c01>=2), " combined trans>=3:", a(ctr>=3), "\n")
  cat("sep trans>=2:", a(tr1>=2 | tr2>=2), " sep nonmono:", a(nm1|nm2), " sep 0->1>=2:", a(s01_1>=2 | s01_2>=2), "\n")
  cat("list1 nonmono only:", a(nm1), " list1 trans>=2 only:", a(tr1>=2), " list1 nonmono excl line1:", a(nm1x), "\n")
  cat("sep trans>=2 or list1 nonmono:", a(tr1>=2|tr2>=2|nm1), " list1 nonmono or list2 trans>=2:", a(nm1|tr2>=2), "\n")
  cat("combined trans>=2 or sep nonmono list1:", a(ctr>=2|nm1), "\n")
  dup <- which(d$amt_id %in% d$amt_id[duplicated(d$amt_id)])
  cat("dup rows combined trans>=2:", rowSums(ctr>=2)[dup], "\n")
  cat("Va list1 trans>=2 or list2 nonmono:", a(tr1>=2|nm2), "  Vb list1 nonmono excl line1 or list2 nonmono:", a(nm1x|nm2), "\n")
  cat("Vg list1 nonmono or list2 trans>=2 :", a(nm1|tr2>=2), " Vh list1 nonmono excl line1 or list2 trans>=2:", a(nm1x|tr2>=2), "\n")
  s1 <- matrix("", n, 20); s2 <- matrix("", n, 20)
  for (k in 1:20) { s1[,k] <- apply(sapply(1:11, function(j) d[[colf(k,1,j)]]),1,paste,collapse=""); s2[,k] <- apply(sapply(3:12, function(j) d[[colf(k,2,j)]]),1,paste,collapse="") }
  f1 <- rowSums(nm1|nm2)>0; f2 <- rowSums(ctr>=2)>0
  cat("nonmono but not combined>=2:\n"); for (i in which(f1 & !f2)) { ks <- which(nm1[i,]|nm2[i,]); cat(" ", i, ":", paste(sprintf("k%d %s|%s c%d", ks, s1[i,ks], s2[i,ks], ctr[i,ks]), collapse="  "), "\n") }
  cat("combined>=2 but not nonmono:\n"); for (i in which(!f1 & f2)) { ks <- which(ctr[i,]>=2); cat(" ", i, ":", paste(sprintf("k%d %s|%s", ks, s1[i,ks], s2[i,ks]), collapse="  "), "\n") }
  cat("subjects with exactly one nonmono list:\n"); for (i in which(rowSums(nm1|nm2)==1)) { ks <- which(nm1[i,]|nm2[i,]); cat(" ", i, ":", sprintf("k%d %s|%s c%d", ks, s1[i,ks], s2[i,ks], ctr[i,ks]), "\n") }
}
variants(A, colA, "A"); variants(B, colB, "B")
