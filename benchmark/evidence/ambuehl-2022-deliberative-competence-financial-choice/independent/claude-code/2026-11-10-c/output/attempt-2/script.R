# Exploratory 2: identify Exp A arms, completion, MPL coding (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D,f), col_types=cols(.default="c"), name_repair="minimal", progress=FALSE)
A <- lapply(1:8, function(i) {x <- rd(sprintf("expAbatch%d.csv",i)); names(x)[1] <- "V1"; x <- x[-1,]; x$batch <- i; x})
Aall <- bind_rows(A)
Aall$done <- !is.na(Aall$test1)
cat("completed A:", sum(Aall$done), "\n")
Ac <- Aall[Aall$done,]
print(table(Ac$batch, Ac$treatment))
for(k in c("code treat","codeWT","codeWC","Q124","Q125","Q127","Q130","Q133_1","Q134_1","TimeTreat_1","TimeContro_1","Q120","Q123","Q18","Q108","Q109","Q95","P1","Q99","Q100","test_payment","V7")) if(k %in% names(Ac)) {
  cat("\n==", k, " (non-NA by batch x treatment)\n"); print(table(Ac$batch, Ac$treatment, !is.na(Ac[[k]]) & Ac[[k]]!=""))
  v <- tolower(trimws(Ac[[k]])); tt <- table(v, paste0(Ac$batch,"_",Ac$treatment)); if(nrow(tt) < 40) print(tt)
}
# duplicates of worker id
wid <- if ("amt_id" %in% names(Ac)) toupper(trimws(Ac$amt_id)) else NA
cat("\namt_id dup count:", sum(duplicated(wid)), "\n"); print(Ac[wid %in% wid[duplicated(wid)], c("amt_id","batch","treatment","V8")])
# MPL parsing
first_cols <- function(r, pre) sprintf("%s%d_1_%d: 1", pre, r, 1:11)
sec_cols <- function(r, pre) sprintf("%s%d_2_%d: 1", pre, r, 3:12)
show <- function(df, r, pre) {
  f <- as.matrix(df[, first_cols(r,pre)]); s <- as.matrix(df[, sec_cols(r,pre)])
  fs <- apply(f, 1, paste, collapse=""); ss <- apply(s, 1, function(z) paste(ifelse(is.na(z),".",z), collapse=""))
  list(fs=fs, ss=ss)
}
for (r in c(1,2,11,14)) {
  z <- show(Ac, r, "iMPL")
  cat("\nround", r, "first-list patterns\n"); print(head(sort(table(z$fs), decreasing=TRUE), 25))
  cat("second-list patterns\n"); print(head(sort(table(z$ss), decreasing=TRUE), 25))
  cat("switch var vs first pattern\n"); print(head(table(z$fs, Ac[[paste0("switch",r)]]), 30))
  cat("T text:", Ac[[paste0("T",r)]][1], "\n")
}
cat("\nT1..T20 texts\n"); for(r in 1:20) cat(r, Ac[[paste0("T",r)]][1], "\n")
# B
B <- lapply(1:2, function(i) {x <- rd(sprintf("expBbatch%d.csv",i)); x <- x[-(1:2),]; x$batch <- i; x})
Ball <- bind_rows(B); Ball$done <- !is.na(Ball$test1)
cat("\ncompleted B:", sum(Ball$done), "\n"); Bc <- Ball[Ball$done,]
print(table(Bc$batch, Bc$treatment)); print(table(Bc$Finished, Bc$DistributionChannel))
wid <- toupper(trimws(Bc$amt_id)); cat("B amt_id dups:", sum(duplicated(wid)), "\n")
z <- show(Bc |> rename_with(function(n) sub("^iMPL(\\d+)-(\\d)#1_iMPL\\d+-\\d_(\\d+)$", "iMPL\\1_\\2_\\3: 1", n)), 1, "iMPL")
cat("B round1 first\n"); print(head(sort(table(z$fs), decreasing=TRUE), 15)); cat("B round1 second\n"); print(head(sort(table(z$ss), decreasing=TRUE), 15))
cat("\nB T texts\n"); for(r in 1:20) cat(r, Bc[[paste0("T",r)]][1], "\n")
for(k in c("Q142","Q146","Q156","Q166","Q178","Q361","Q364","Q370","Q373","codeWT","codeWC")) {cat("\n== B", k, "\n"); v <- tolower(trimws(Bc[[k]])); tt <- table(v, Bc$treatment, useNA="ifany"); if(nrow(tt)<30) print(tt) else print(table(is.na(v), Bc$treatment))}
