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
for (nm in c("A","B")) {
  p <- if (nm=="A") pA else pB; d <- if (nm=="A") A else B
  ms2 <- apply(p$nsw >= 2, 1, any); nm1 <- apply(p$nonmono, 1, any)
  cat(nm, ": multi-switch(>=2 transitions any list):", sum(ms2), " nonmonotone any:", sum(nm1), " either:", sum(ms2|nm1), "\n")
  cat("  list1-only >=2:", sum(apply(p$nsw[,seq(1,39,2)]>=2,1,any)), "\n")
  dup <- d$amt_id %in% d$amt_id[duplicated(d$amt_id)]
  cat("  dup rows:", sum(dup), " their ms2:", ms2[dup], "\n")
  cat("  unique amt_id:", length(unique(d$amt_id)), "\n")
  cat("  n1==0 count:", sum(p$n1==0), " n1==11 count:", sum(p$n1==11), "\n")
  print(summary(as.vector(p$val[!ms2,])))
  # compare switch1 field to n1
  if ("switch1" %in% names(d)) cat("  switch1 == n1 for task1:", mean(as.numeric(d$switch1)==p$n1[,1], na.rm=TRUE), " NA:", sum(is.na(d$switch1)), "\n")
}
key <- c(2,4,4,7,6)
A$tc <- rowSums(sapply(1:5, function(q) as.numeric(A[[tests[q]]]) == key[q]), na.rm=TRUE)
A$grp <- paste0(ifelse(A$batch %in% c(1,2,4,5),"main","sub"), A$treatment)
print(table(A$grp))
print(aggregate(cbind(q1=as.numeric(A$test1)==2, q2=as.numeric(A$test2)==4, tc=A$tc, sc=as.numeric(A$SC0_0), tt=as.numeric(A$TimeTreat_3), tcn=as.numeric(A$TimeContro_3)) ~ grp, data=A, FUN=function(z) mean(z,na.rm=TRUE), na.action=na.pass))
B$tc <- rowSums(sapply(1:5, function(q) as.numeric(B[[tests[q]]]) == key[q]), na.rm=TRUE)
print(aggregate(tc ~ treatment, data=B, FUN=mean)); print(table(B$treatment))
