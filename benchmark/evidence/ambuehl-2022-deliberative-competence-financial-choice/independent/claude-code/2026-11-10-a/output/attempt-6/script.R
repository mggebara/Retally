D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width=250)
B <- list()
for (b in 1:2) {
  x <- read.csv(file.path(D, sprintf("expBbatch%d.csv", b)), check.names=FALSE, stringsAsFactors=FALSE, colClasses="character")
  cat("batch", b, dim(x), "\n")
  print(x[1:3, 1:10])
  x <- x[-(1:2), ]
  x$batch <- b
  x <- x[, names(x) != "" & !duplicated(names(x))]
  B[[b]] <- x
}
cat("same names:", identical(names(B[[1]]), names(B[[2]])), "\n")
b <- rbind(B[[1]], B[[2]][, names(B[[1]])])
im <- grep("^iMPL", names(b), value=TRUE)
cat("n iMPL cols", length(im), "\n"); print(head(im, 3)); print(grep("#2", im, value=TRUE)[1:5])
b$has_mpl <- apply(b[, im], 1, function(r) sum(r != ""))
b$has_test <- b$test1 != ""
print(table(b$has_mpl, b$Finished))
print(table(treatment=b$treatment, has_test=b$has_test, fin=b$Finished))
print(table(b$Status))
ok <- b[b$has_test & b$has_mpl > 0, ]
cat("complete-ish:", nrow(ok), "\n"); print(table(ok$treatment)); print(table(ok$has_mpl))
cat("dup amt_id:", sum(duplicated(ok$amt_id)), "\n")
print(table(unlist(ok[, im])))
for (v in paste0("test", 1:10)) { cat("\n", v, "\n"); print(table(ok$treatment, ok[[v]])) }
r <- ok[1:6, ]
for (k in c(1, 11)) {
  cols <- grep(paste0("^iMPL", k, "-"), names(r), value=TRUE)
  m <- r[, cols]; names(m) <- sub(paste0("^iMPL", k, "-.#1_iMPL", k, "-"), "", names(m))
  print(cbind(m, sw=r[[paste0("switch", k)]]))
}
# treatment-specific columns
print(table(ok$treatment, ok$Q142 != ""))
print(table(ok$treatment, ok$Q361 != ""))
cat("Progress:\n"); print(table(ok$Progress))
