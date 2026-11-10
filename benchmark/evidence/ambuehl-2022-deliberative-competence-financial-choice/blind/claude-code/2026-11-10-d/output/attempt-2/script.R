suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tr <- function(x, n=150) substr(gsub("\\s+"," ",x),1,n)
A <- list()
for (b in 1:8) {
  d <- suppressMessages(read_csv(file.path(D, sprintf("expAbatch%d.csv", b)), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="minimal"))
  names(d)[1] <- "V1"; d <- d[, names(d) != ""]
  if (b==1) { cat("LABELS A\n"); for (v in c("Q117","Q122","codeWT","Q127","codeWC","info","Q119","Q120","Q124","code treat","Q125","Q130","Q121","Q111","Q123","Q18","Q108","Q95","Q109","Q99","P1","Q100","payment_for_test","payment_test","one")) if (v %in% names(d)) cat(v,":",tr(d[[v]][1],300),"\n") }
  d <- d[-1,]; d$batch <- b; A[[b]] <- d
}
A <- bind_rows(A)
tests <- paste0("test",1:10)
A$ntest <- rowSums(!is.na(A[,tests]))
A$hasmpl <- !is.na(A[["iMPL1_1_1: 1"]])
print(table(A$ntest, A$hasmpl)); print(table(A$batch, A$treatment, A$ntest==10))
cA <- A[A$ntest==10,]
cat("completers", nrow(cA), " dup amt_id among completers:", sum(duplicated(cA$amt_id)), "\n")
print(table(cA$V10, useNA="ifany"))
for (v in c("Q117","Q122","codeWT","Q127","codeWC","Q124","code treat","Q125","Q130","Q121","Q111","Q123","Q18","Q108","Q95","Q109","Q99","P1","Q100")) if (v %in% names(cA)) {
  x <- tolower(trimws(cA[[v]])); x <- substr(x,1,25)
  tb <- table(x, paste(cA$batch, cA$treatment), useNA="ifany")
  if (nrow(tb) < 30) {cat("==", v, "\n"); print(tb)} else cat("==", v, "has", nrow(tb), "levels\n")
}
for (v in c("TimeTreat_3","TimeContro_3","TimeInstr1_3")) { cat("==",v,"\n"); print(tapply(as.numeric(cA[[v]]), paste(cA$batch, cA$treatment), function(z) c(n=sum(!is.na(z)), med=median(z,na.rm=TRUE)))) }
# key inference via regression
inferkey <- function(dd, sc) {
  y <- as.numeric(dd[[sc]])
  X <- NULL; nm <- c()
  for (q in tests) for (cc in sort(unique(dd[[q]]))) { X <- cbind(X, as.numeric(dd[[q]]==cc)); nm <- c(nm, paste(q,cc,sep="=")) }
  colnames(X) <- nm
  m <- lm(y ~ X)
  co <- coef(m)[-1]; names(co) <- nm
  cat("R2:", summary(m)$r.squared, "\n")
  print(round(co[!is.na(co) & abs(co) > 0.3], 3))
}
cat("A key inference (SC0_0)\n"); inferkey(cA, "SC0_0")
B <- list()
for (b in 1:2) {
  d <- read_csv(file.path(D, sprintf("expBbatch%d.csv", b)), col_types=cols(.default="c"), show_col_types=FALSE)
  if (b==1) {cat("LABELS B\n"); for (v in c("Q142","Q146","Q156","Q166","Q178","Q180","Q361","Q364","Q370","Q373","attention","help_test","payment_for_test")) cat(v,":",tr(d[[v]][1],250),"\n")}
  d <- d[-(1:2),]; d$batch <- b; B[[b]] <- d
}
B <- bind_rows(B)
B$ntest <- rowSums(!is.na(B[,tests]))
print(table(B$ntest, B$Finished)); print(table(B$treatment, B$ntest==10))
cB <- B[B$ntest==10,]
cat("B completers", nrow(cB), " dup amt_id:", sum(duplicated(cB$amt_id)), " dup ResponseId:", sum(duplicated(cB$ResponseId)), "\n")
cat("B key inference (SC0)\n"); inferkey(cB, "SC0")
mplA <- grep("^iMPL", names(cA), value=TRUE)
cat("A MPL NA count among completers:", sum(is.na(as.matrix(cA[,mplA]))), " of ", length(mplA)*nrow(cA), "\n")
mplB <- grep("^iMPL", names(cB), value=TRUE)
cat("B MPL NA:", sum(is.na(as.matrix(cB[,mplB]))), "; values:"); print(table(unlist(cB[,mplB[1:21]]), useNA="ifany"))
print(table(unlist(cA[,mplA[1:21]]), useNA="ifany"))
cat("B T columns:\n"); for (k in 1:20) cat(k, names(sort(table(cB[[paste0("T",k)]]),decreasing=TRUE))[1], "\n")
cat("A T columns:\n"); for (k in 1:20) cat(k, length(unique(cA[[paste0("T",k)]])), names(sort(table(cA[[paste0("T",k)]]),decreasing=TRUE))[1], "\n")
