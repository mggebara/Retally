D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=250)
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names=FALSE, stringsAsFactors=FALSE, fileEncoding="UTF-8-BOM", colClasses="character")
  A[[b]] <- x
}
for (b in 1:8) {
  x <- A[[b]]; d <- x[1, ]; x <- x[-1, ]
  cat("\n######## batch", b, "nrow", nrow(x), "\n")
  for (v in c("Q122","Q124","Q125","code treat","Q130","Q120")) cat(v, ":", substr(gsub("\n"," ",d[[v]]),1,1500), "\n")
  fin <- x$V10 == "1"
  cat("finished", sum(fin), "\n")
  print(table(treatment=x$treatment[fin], codetreat=x[["code treat"]][fin] != "", useNA="ifany"))
  print(table(treatment=x$treatment[fin], Q130=x$Q130[fin] != "", useNA="ifany"))
  print(head(unique(x[["code treat"]][fin]), 10)); print(head(unique(x$Q130[fin]), 10))
  # T strings unique
  for (k in 1:20) { u <- unique(x[[paste0("T",k)]]); if (length(u) > 1 || b %in% c(1,8)) cat("T", k, ":", paste(u, collapse=" || "), "\n") }
  print(table(x$test_payment[fin]))
}
x <- A[[5]][-1, ]; x <- x[x$V10 == "1", ]
for (k in c(1, 11)) {
  cols <- grep(paste0("^iMPL", k, "_"), names(x), value=TRUE)
  m <- x[1:12, cols]; names(m) <- sub(": 1$", "", sub(paste0("^iMPL", k, "_"), "", names(m)))
  print(m)
  print(x[1:12, paste0("switch", k)])
}
print(head(x[, paste0("switch", 1:20)], 12))
print(head(x[, c("line1","line2","amt1","amt2","decision_index","payment_test","payment_for_test")], 12))
cat("all values in iMPL cols:\n"); print(table(unlist(x[, grep("^iMPL", names(x))])))
