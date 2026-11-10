D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=250)
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names=FALSE, stringsAsFactors=FALSE, fileEncoding="UTF-8-BOM", colClasses="character")
  x <- x[-1, ]
  x$batch <- b
  x$excluded <- NULL; x <- x[, names(x) != "" & !duplicated(names(x))]
  A[[b]] <- x
}
common <- Reduce(intersect, lapply(A, names))
cat("noncommon:", setdiff(unique(unlist(lapply(A, names))), common), "\n")
a <- do.call(rbind, lapply(A, function(x) x[, common]))
cat("rows", nrow(a), "\n")
a$has_mpl <- apply(a[, grep("^iMPL", names(a))], 1, function(r) sum(r != ""))
a$has_test <- a$test1 != ""
a$grp <- ifelse(a$batch %in% c(1,2,4,5), "TC", "SR")
a$arm <- paste(a$grp, ifelse(a[["code treat"]] != "", "codetreat", ifelse(a$Q130 != "", "q130", "none")))
print(table(a$arm, a$has_mpl))
print(table(a$arm, a$has_test, a$V10))
print(table(a$arm, a$treatment))
ok <- a[a$has_test & a$has_mpl > 0, ]
cat("complete-ish:", nrow(ok), "\n")
print(table(ok$arm))
print(table(ok$has_mpl))
# answer distribution by arm
for (v in paste0("test", 1:10)) { cat("\n", v, "\n"); print(table(ok$arm, ok[[v]])) }
# coding of iMPL
r <- ok[1:6, ]
for (k in c(1, 6, 11, 12)) {
  cols <- grep(paste0("^iMPL", k, "_"), names(r), value=TRUE)
  m <- r[, cols]; names(m) <- sub(": 1$", "", sub(paste0("^iMPL", k, "_"), "", names(m)))
  print(cbind(m, sw=r[[paste0("switch", k)]]))
}
# duplicates of amt_id
cat("dup amt_id among ok:", sum(duplicated(ok$amt_id)), "\n")
print(ok$amt_id[duplicated(ok$amt_id) | duplicated(ok$amt_id, fromLast=TRUE)])
print(table(ok$V7)); print(summary(as.numeric(ok$age)))

B1 <- read.csv(file.path(D, "expBbatch1.csv"), check.names=FALSE, stringsAsFactors=FALSE, colClasses="character")
cat("B1", dim(B1), "\n")
nm <- names(B1)
for (i in seq_along(nm)) cat(sprintf("%-28s | %s | %s\n", nm[i], substr(gsub("[\r\n]"," ",B1[1, i]), 1, 160), substr(B1[5, i], 1, 60)))
