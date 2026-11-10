D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=250)
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names=FALSE, stringsAsFactors=FALSE, fileEncoding="UTF-8-BOM", colClasses="character")
  A[[b]] <- x
}
x <- A[[5]]
desc <- unlist(x[1, ])
nm <- names(x)
keep <- !grepl("^iMPL", nm)
for (i in which(keep)) cat(sprintf("%-20s | %s\n", nm[i], substr(gsub("\n"," ",desc[i]), 1, 300)))
cat("---- iMPL1 / iMPL11 desc\n")
for (i in grep("^iMPL(1|11)_", nm)) cat(sprintf("%-20s | %s\n", nm[i], substr(gsub("\n"," ",desc[i]), 1, 400)))
x <- x[-1, ]
cols <- intersect(c("treatment","line1","line2","amt1","amt2","decision_index","T1","T2","T3","T10","T11","T20","switch1","switch2","excluded","treat","code","codeWT","codeWC","test1","test2","test6","test10","V10","V7"), names(x))
print(head(x[, cols], 10))
for (b in 1:8) { y <- A[[b]][-1,]; cat("B", b, nrow(y), "\n"); for (v in intersect(c("treatment","treat","excluded","V10","V7"), names(y))) {cat(v,": "); print(table(y[[v]], useNA="ifany"))}}
print(head(x[, grep("^iMPL1_", names(x))], 10))
print(head(x[, grep("^iMPL11_", names(x))], 10))
for (v in paste0("test",1:10)) {cat(v,"\n"); print(table(x[[v]], useNA="ifany"))}
for (v in paste0("T",1:20)) {cat(v,"\n"); print(summary(as.numeric(x[[v]])))}
for (v in paste0("switch",1:3)) {cat(v,"\n"); print(table(x[[v]], useNA="ifany"))}
