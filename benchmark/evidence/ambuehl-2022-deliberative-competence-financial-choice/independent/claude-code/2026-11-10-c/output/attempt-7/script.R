# Exploratory 7: search multiple-switching rule combos against the paper's counts (49/504 A, 53/401 B)
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
revpos <- function(z) which(diff(z) < 0)  # positions of 1->0
feat <- function(df) {
  n <- nrow(df); M <- matrix(FALSE, n, 12, dimnames=list(NULL, c("fsw2","ssw2","frevmid","frevedge","srevmid","srevedge","comb","fdev2","sdev2","frevtop","frevbot","n1ext_s")))
  for (r in 1:20) {
    f <- sapply(1:11, function(k) as.integer(df[[sprintf("iMPL%d_1_%d: 1", r, k)]]))
    s <- sapply(3:12, function(k) as.integer(df[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
    for (i in 1:n) {
      fi <- f[i,]; si <- s[i,]; n1 <- sum(fi)
      M[i,"fsw2"] <- M[i,"fsw2"] | nsw(fi) >= 2
      M[i,"ssw2"] <- M[i,"ssw2"] | nsw(si) >= 2
      rp <- revpos(fi); rs <- revpos(si)
      if (nsw(fi) == 1 && length(rp)) { edge <- rp %in% c(1, 10); M[i,"frevedge"] <- M[i,"frevedge"] | any(edge); M[i,"frevmid"] <- M[i,"frevmid"] | any(!edge)
        M[i,"frevtop"] <- M[i,"frevtop"] | any(rp == 1); M[i,"frevbot"] <- M[i,"frevbot"] | any(rp == 10) }
      if (nsw(si) == 1 && length(rs)) { edge <- rs %in% c(1, 9); M[i,"srevedge"] <- M[i,"srevedge"] | any(edge); M[i,"srevmid"] <- M[i,"srevmid"] | any(!edge)
        if (n1 %in% c(0, 11)) M[i,"n1ext_s"] <- TRUE }
      comb <- c(rep(0, 11 - n1), si, rep(1, n1)); M[i,"comb"] <- M[i,"comb"] | nsw(comb) >= 2
      M[i,"fdev2"] <- M[i,"fdev2"] | sum(fi != c(rep(0, 11 - n1), rep(1, n1))) >= 2
      n1s <- sum(si); M[i,"sdev2"] <- M[i,"sdev2"] | sum(si != c(rep(0, 10 - n1s), rep(1, n1s))) >= 2
    }
  }
  as.data.frame(M)
}
FA <- feat(A); FB <- feat(B)
cat("A feature sums:\n"); print(colSums(FA)); cat("B feature sums:\n"); print(colSums(FB))
comps <- c("frevmid","frevtop","frevbot","srevmid","srevedge","comb")
res <- list()
for (m in 0:(2^length(comps)-1)) {
  use <- comps[bitwAnd(m, 2^(0:(length(comps)-1))) > 0]
  ea <- FA$fsw2 | FA$ssw2; eb <- FB$fsw2 | FB$ssw2
  for (u in use) { ea <- ea | FA[[u]]; eb <- eb | FB[[u]] }
  res[[length(res)+1]] <- data.frame(rule=paste(c("sw2", use), collapse="+"), A_excl=sum(ea), A_TC=sum(!ea & A$arm %in% c("T","C")), B_excl=sum(eb))
}
res <- bind_rows(res); print(res[order(abs(res$A_excl-49) + abs(res$B_excl-53)),], row.names=FALSE)
ea <- FA$fdev2 | FA$sdev2; eb <- FB$fdev2 | FB$sdev2
cat("dev2 rule: A", sum(ea), " A_TC", sum(!ea & A$arm %in% c("T","C")), " B", sum(eb), "\n")
w <- toupper(trimws(A$amt_id)); d <- w %in% w[duplicated(w)]; cat("A dup flagged:\n"); print(FA[d,])
w <- toupper(trimws(B$amt_id)); d <- w %in% w[duplicated(w)]; cat("B dup flagged:\n"); print(FB[d,])
