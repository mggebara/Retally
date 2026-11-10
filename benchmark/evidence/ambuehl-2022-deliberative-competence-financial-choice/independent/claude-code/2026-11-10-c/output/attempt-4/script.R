# Exploratory 4: multiple-switching definitions and sample sizes (no estimates of listed quantities)
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
defs <- function(df) {
  n <- nrow(df); res <- matrix(FALSE, n, 6, dimnames=list(NULL, c("f2","s2","frev","srev","comb2","comb2_only_s")))
  for (r in 1:20) {
    f <- sapply(1:11, function(k) as.integer(df[[sprintf("iMPL%d_1_%d: 1", r, k)]]))
    s <- sapply(3:12, function(k) as.integer(df[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
    for (i in 1:n) {
      fi <- f[i,]; si <- s[i,]
      res[i,"f2"] <- res[i,"f2"] | nsw(fi) >= 2
      res[i,"s2"] <- res[i,"s2"] | nsw(si) >= 2
      res[i,"frev"] <- res[i,"frev"] | any(diff(fi) < 0)
      res[i,"srev"] <- res[i,"srev"] | any(diff(si) < 0)
      n1 <- sum(fi); a <- 11 - n1  # immediate lines on top
      comb <- c(rep(0, a), si, rep(1, n1))
      res[i,"comb2"] <- res[i,"comb2"] | nsw(comb) >= 2 | nsw(fi) >= 2
      res[i,"comb2_only_s"] <- res[i,"comb2_only_s"] | nsw(comb) >= 2
    }
  }
  as.data.frame(res)
}
for (nm in c("A","B")) {
  df <- get(nm); m <- defs(df)
  cat("\n=====", nm, "N =", nrow(df), "\n")
  v <- list(any2 = m$f2 | m$s2, any2_or_rev = m$f2 | m$s2 | m$frev | m$srev,
            f2_or_s_nonmono = m$f2 | m$s2 | m$srev, comb2 = m$comb2, comb2_only_s = m$comb2_only_s,
            f_nonmono_or_s2 = m$f2 | m$frev | m$s2)
  for (k in names(v)) { cat(k, ": excluded", sum(v[[k]]), " kept by arm:"); print(table(df$arm[!v[[k]]])) }
}
w <- toupper(trimws(A$amt_id)); cat("A dup:\n"); print(A[w %in% w[duplicated(w)], c("amt_id","batch","arm")])
w <- toupper(trimws(B$amt_id)); cat("B dup:\n"); print(B[w %in% w[duplicated(w)], c("amt_id","batch","arm","StartDate")])
