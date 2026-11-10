suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-d/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
tr <- function(x, n=150) substr(gsub("\\s+"," ",x),1,n)
A <- list()
for (b in 1:8) {
  f <- file.path(D, sprintf("expAbatch%d.csv", b))
  d <- read_csv(f, col_types=cols(.default="c"), show_col_types=FALSE)
  names(d)[1] <- "V1"
  lab <- d[1,]; d <- d[-1,]
  if (b==1) { cat("LABELS A\n"); for (v in c(paste0("V",1:10),"SC0_0","SC0_1","SC0_2","test_payment","treatment","excluded","decision_index", paste0("test",1:10),"iMPL1_1_1: 1","iMPL1_1_11: 1","iMPL1_2_3: 1","iMPL1_2_12: 1","switch1","one")) if (v %in% names(lab)) cat(v,":",tr(lab[[v]],400),"\n") }
  d$batch <- b
  A[[b]] <- d
}
A <- bind_rows(A)
cat("A rows", nrow(A), "\n")
for (v in c("V7","V10","treatment","excluded","SC0_0","SC0_1","SC0_2","test_payment","batch")) {cat("--",v,"\n"); print(table(A[[v]], useNA="ifany"))}
print(table(A$treatment, A$excluded, useNA="ifany"))
print(table(A$V10, A$treatment, useNA="ifany"))
for (v in paste0("test",1:10)) {cat("--",v,"\n"); print(table(A[[v]], A$treatment, useNA="ifany"))}
for (v in paste0("switch",1:3)) {cat("--",v,"\n"); print(table(A[[v]], useNA="ifany"))}
for (k in c(1,11,20)) {cat("--T",k,"\n"); print(head(sort(table(A[[paste0("T",k)]]),decreasing=TRUE),4))}
cat("-- iMPL1 first list values\n"); for (j in c(1,6,11)) print(table(A[[paste0("iMPL1_1_",j,": 1")]], useNA="ifany"))
cat("-- iMPL1 second list values\n"); for (j in c(3,8,12)) print(table(A[[paste0("iMPL1_2_",j,": 1")]], useNA="ifany"))
cat("-- show first rows all iMPL1 \n"); print(as.data.frame(A[1:5, grep("^iMPL1_", names(A))]))
print(as.data.frame(A[1:5, c("line1","line2","amt1","amt2","decision_index","switch1","switch11")]))
cat("dup ids:", sum(duplicated(A$V1)), " dup amt_id:", sum(duplicated(A$amt_id[!is.na(A$amt_id)])), "\n")
# B
B <- list()
for (b in 1:2) {
  f <- file.path(D, sprintf("expBbatch%d.csv", b))
  d <- read_csv(f, col_types=cols(.default="c"), show_col_types=FALSE)
  if (b==1) {cat("LABELS B rows1-2\n"); for (v in c("Status","Progress","Finished","SC0","treatment","exclude2","exclude3","exclude4","exclude5",paste0("test",1:10),"switch1", grep("MPL",names(d),value=TRUE)[c(1:3,11:14,20:24)])) if (v %in% names(d)) cat(v,":",tr(d[[v]][1],300)," || ", tr(d[[v]][2],120),"\n")}
  d <- d[-(1:2),]; d$batch <- b; B[[b]] <- d
}
B <- bind_rows(B)
cat("B rows", nrow(B), "\n")
for (v in c("Status","Finished","Progress","treatment","exclude2","exclude3","exclude4","exclude5","SC0","test_payment","batch")) {cat("--",v,"\n"); print(table(B[[v]], useNA="ifany"))}
print(table(B$treatment, B$Finished, useNA="ifany"))
for (v in paste0("test",1:10)) {cat("--",v,"\n"); print(table(B[[v]], B$treatment, useNA="ifany"))}
for (v in paste0("switch",1:3)) {cat("--",v,"\n"); print(table(B[[v]], useNA="ifany"))}
mp <- grep("MPL", names(B), value=TRUE); cat("B MPL names:\n"); print(head(mp,60)); print(tail(mp,30))
print(as.data.frame(B[1:3, c("line1","line2","amt1","amt2","decision_index","switch1","switch11")]))
