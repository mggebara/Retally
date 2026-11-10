suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) suppressMessages(read_csv(file.path(D, f), col_types=cols(.default="c"), show_col_types=FALSE, name_repair="unique"))
cl <- function(s) gsub("[\r\n\t]+", " ", s)
options(width=200)
A <- list()
for (i in 1:8) { x <- rd(sprintf("expAbatch%d.csv", i)); lab <- x[1,]; x <- x[-1,]; x$batch <- i; A[[i]] <- x }
labA <- rd("expAbatch2.csv")[1,]
cat("LABEL iMPL1_1_1:", cl(labA[["iMPL1_1_1: 1"]]), "\n\n")
cat("LABEL iMPL1_1_11:", cl(labA[["iMPL1_1_11: 1"]]), "\n\n")
cat("LABEL iMPL1_2_3:", cl(labA[["iMPL1_2_3: 1"]]), "\n\n")
cat("LABEL iMPL1_2_12:", cl(labA[["iMPL1_2_12: 1"]]), "\n\n")
cat("LABEL iMPL11_1_1:", cl(labA[["iMPL11_1_1: 1"]]), "\n\n")
for (q in c("test1","test2","test3","test4","test5","test6","test7","test8","test9","test10","code treat","Q130","Q124","Q125","Q120")) cat("LABEL", q, ":", substr(cl(labA[[q]]), 1, 1500), "\n\n")
cn <- Reduce(intersect, lapply(A, names))
a <- bind_rows(lapply(A, function(x) x[, cn]))
cat("rows", nrow(a), "\n")
print(table(a$batch, a$V10, useNA="a"))
print(table(a$batch, a$treatment, useNA="a"))
a$ct <- tolower(trimws(a[["code treat"]])); a$q130 <- tolower(trimws(a$Q130))
print(table(paste(a$batch, a$treatment), a$ct, useNA="a"))
print(table(paste(a$batch, a$treatment), a$q130, useNA="a"))
print(table(paste(a$batch, a$treatment), is.na(a$test1)))
fin <- a[!is.na(a$test1), ]
cat("finished-test rows", nrow(fin), " unique amt_id", length(unique(fin$amt_id)), "\n")
for (q in paste0("test", 1:10)) { cat(q, "\n"); print(table(paste(fin$batch>=0, fin$treatment), fin[[q]], useNA="a")) }
print(table(fin$SC0_0, fin$payment_test))
m <- fin[1:3, grep("^iMPL1_|^iMPL11_|^switch1$|^switch11$", names(fin))]
print(as.data.frame(t(m)))
# values present
v <- unlist(fin[, grep("^iMPL", names(fin))]); print(table(v, useNA="a"))
