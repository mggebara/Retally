# Exploratory 5: second-list item order (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D,f), col_types=cols(.default="c"), name_repair="minimal", progress=FALSE)
for (i in c(1,3,6,8)) {
  x <- rd(sprintf("expAbatch%d.csv",i)); names(x)[1] <- "V1"
  cat("\n== A batch", i, "\n")
  for (r in c(1,3,10,11)) {
    cn <- grep(sprintf("^iMPL%d_2_", r), names(x), value=TRUE)
    cat("round", r, "col order:", sub(": 1","",sub(sprintf("iMPL%d_2_", r), "", cn)), "\n")
    lab <- x[1, cn, drop=TRUE]; for (k in seq_along(cn)) cat("   ", cn[k], "->", gsub("\n"," ", substr(lab[[k]], nchar(lab[[k]])-30, nchar(lab[[k]]))), "\n")
  }
}
x <- rd("expBbatch1.csv")
for (r in c(1,3)) { cn <- grep(sprintf("^iMPL%d-2#", r), names(x), value=TRUE)
  cat("B round", r, "\n"); for (k in cn) cat("   ", k, "->", gsub("\n"," ", substr(x[[k]][1], nchar(x[[k]][1])-30, nchar(x[[k]][1]))), " | ", x[[k]][2], "\n") }
for (r in c(1)) { cn <- grep(sprintf("^iMPL%d-1#", r), names(x), value=TRUE)
  for (k in cn) cat("   ", k, "->", gsub("\n"," ", substr(x[[k]][1], nchar(x[[k]][1])-30, nchar(x[[k]][1]))), "\n") }
# monotonicity of second list under code order vs csv order, A rounds
A <- bind_rows(lapply(1:8, function(i) {x <- rd(sprintf("expAbatch%d.csv",i)); names(x)[1] <- "V1"; x <- x[-1,]; x$batch <- i; x}))
A <- A[!is.na(A$test1),]
mono <- function(z) all(diff(z) >= 0)
for (r in 1:20) {
  code <- sapply(3:12, function(k) as.integer(A[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
  csvn <- grep(sprintf("^iMPL%d_2_", r), names(A), value=TRUE)
  csv <- sapply(csvn, function(k) as.integer(A[[k]]))
  cat("round", r, " csv order:", paste(sub(": 1","",sub(sprintf("iMPL%d_2_", r), "", csvn)), collapse=","), " monotone code-order:", sum(apply(code,1,mono)), " csv-order:", sum(apply(csv,1,mono)), "\n")
}
