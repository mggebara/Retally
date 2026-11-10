D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=200)
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names=FALSE, stringsAsFactors=FALSE, fileEncoding="UTF-8-BOM")
  cat("batch", b, dim(x), "\n")
  x$batch <- b
  A[[b]] <- x
}
x <- A[[5]]
print(head(x[, 1:23], 4))
print(head(x[, c("T1","T2","T3","T10","T11","T20","switch1","switch2","excluded","treat","code","test1","test2","test6","test10")], 6))
for (b in 1:8) { cat("B", b, "\n"); print(table(A[[b]]$treatment, useNA="ifany")); print(table(A[[b]]$treat, useNA="ifany")); if (!is.null(A[[b]]$excluded)) print(table(A[[b]]$excluded, useNA="ifany")); print(table(A[[b]]$V10, useNA="ifany"))}
im <- grep("^iMPL1_", names(x), value=TRUE)
print(head(x[, im], 8))
print(head(x[, grep("^iMPL11_", names(x), value=TRUE)], 8))
for (v in c("test1","test2","test3","test4","test5","test6","test7","test8","test9","test10")) {cat(v,"\n"); print(table(x[[v]], useNA="ifany"))}
print(table(x$switch1)); print(summary(x$T1)); print(summary(x$T11))
B1 <- read.csv(file.path(D, "expBbatch1.csv"), check.names=FALSE, stringsAsFactors=FALSE)
cat("B1", dim(B1), "\n")
print(names(B1))
print(B1[1:3, 1:30])
