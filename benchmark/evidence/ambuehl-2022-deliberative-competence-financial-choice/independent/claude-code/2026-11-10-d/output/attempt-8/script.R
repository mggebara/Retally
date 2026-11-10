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
# task parameters: tasks 1-10 simple, 11-20 complex
R72 <- c(20,18,16,14,12, 20,18,16,14,12)
tdays <- c(rep(72,5), rep(36,5))
cx <- data.frame(task=11:20, a=c(10,10,4.5,4.5,2,2,0.9,0.9,2,2), rate=c(.02,.01,.04,.02,.06,.03,.08,.04,.05,.025), t=c(36,72,36,72,36,72,36,72,36,72))
cx$exact <- cx$a * (1 + cx$rate)^cx$t
cx$R72 <- c(20,20,18,18,16,16,14,14,12,12)
cx$simple <- c(6,1,7,2,8,3,9,4,10,5)  # matching simple task (same R, same t)
print(cx)
keyC <- c(test1="2", test2="4", test3="4", test4="7", test5="6")
keyA <- c(test6="3", test7="4", test8="2", test9="3", test10="2")
keyB <- c(test6="4", test7="5", test8="5", test9="5", test10="1")
sc <- function(df, key) rowSums(sapply(names(key), function(q) !is.na(df[[q]]) & df[[q]] == key[[q]]))
build <- function(df, cf, keyCtl, exp) {
  p <- proc(df, cf)
  flag <- (rowSums(p$nm1) > 0) | (rowSums(p$nm2 & !(p$s == 11)) > 0)
  df$flag <- flag
  df$score_c <- sc(df, keyC); df$score_ctl <- sc(df, keyCtl)
  df$id <- paste0(exp, seq_len(nrow(df)))
  list(df=df, p=p)
}
oa <- build(a, colA, keyA, "A"); ob <- build(b, colB, keyB, "B")
a2 <- oa$df; b2 <- ob$df
a2$grp <- ifelse(a2$batch %in% c(1,2,4,5), ifelse(a2$treatment == "1", "Treatment", "Control"), ifelse(a2$treatment == "1", "X1", "X0"))
cat("A groups (all / kept):\n"); print(table(a2$grp, a2$flag))
print(aggregate(cbind(score_c, score_ctl) ~ grp, data=a2[!a2$flag, ], FUN=mean))
b2$grp <- ifelse(b2$treatment == "1", "Treatment", "Control")
print(table(b2$grp, b2$flag))
print(aggregate(cbind(score_c, score_ctl) ~ grp, data=b2[!b2$flag, ], FUN=mean))
# valuations
mkpanel <- function(o, grp, topv) {
  p <- o$p; v <- p$val; v[p$s == 0] <- 0
  if (topv == "top20") v[p$s == 11] <- 20
  out <- NULL
  for (j in 1:10) {
    kc <- cx$task[j]; ks <- cx$simple[j]
    out <- rbind(out, data.frame(id=o$df$id, grp=grp, flag=o$df$flag, t=cx$t[j], R=cx$R72[j], vs=v[, ks], vc=v[, kc], exact=cx$exact[j]))
  }
  out
}
tcols <- paste0("T", 1:20)
cat("T constant across A subjects:", all(sapply(tcols, function(t) length(unique(a[[t]])) == 1)), " B:", all(sapply(tcols, function(t) length(unique(b[[t]])) == 1)), "\n")
print(sapply(tcols, function(t) length(unique(a[[t]]))))
print(table(a2$grp[!a2$flag], a2$test10[!a2$flag]))
print(table(a2$grp[!a2$flag], a2$test6[!a2$flag]))
print(table(a2$grp[!a2$flag], a2$test8[!a2$flag]))
p <- oa$p
for (i in which(a2$flag & a2$grp %in% c("X0", "X1"))) {
  v1 <- which(p$nm1[i, ]); v2 <- which(p$nm2[i, ] & p$s[i, ] != 11)
  cat(i, a2$grp[i], "L1 tasks:", paste(v1, collapse=","), " L2 tasks:", paste(v2, collapse=","), " s at L2:", paste(p$s[i, v2], collapse=","), "\n")
  if (length(v1) + length(v2) <= 2) for (k in unique(c(v1, v2))) cat("     task", k, "L1", paste(getmat(a[i, ], colA, k, 1), collapse=""), "L2", paste(getmat(a[i, ], colA, k, 2), collapse=""), "\n")
}
for (topv in c("formula", "top20")) {
  pa <- mkpanel(oa, a2$grp, topv); pb <- mkpanel(ob, b2$grp, topv)
  for (norm in c("exact", "R72")) {
    for (nm in c("A", "B")) {
      pp <- if (nm == "A") pa else pb
      pp <- pp[!pp$flag, ]
      pp$rs <- 100 * pp$vs / pp$R
      pp$rc <- 100 * pp$vc / (if (norm == "exact") pp$exact else pp$R)
      pp$d <- -abs(pp$rc - pp$rs)
      m <- aggregate(cbind(rs, rc, d) ~ grp, data=pp, FUN=mean)
      cat(sprintf("--- %s norm=%s top=%s nobs=%d\n", nm, norm, topv, nrow(pp))); print(m)
    }
  }
}
