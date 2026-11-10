# Exploratory: inspect raw Qualtrics files (no estimates)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D,f), col_types=cols(.default="c"), name_repair="minimal", progress=FALSE)
A <- lapply(1:8, function(i) rd(sprintf("expAbatch%d.csv",i)))
for(i in 1:8) names(A[[i]])[1] <- "V1"
cat("A rows per batch:", sapply(A,nrow), "\n")
a1 <- A[[6]]
key <- c("V1","V2","V3","V7","V8","V9","V10","SC0_0","SC0_1","SC0_2","test_payment","treatment","line1","line2","amt1","amt2","decision_index","one","T1","T2","T11","switch1","switch2","excluded","test1","test2","test3","test4","test5","test6","test7","test8","test9","test10","iMPL1_1_1: 1","iMPL1_1_11: 1","iMPL1_2_3: 1","iMPL1_2_12: 1","Q117","Q122")
for(k in key) if(k %in% names(a1)) cat(k, " || ", substr(a1[[k]][1],1,250), "\n")
cat("\n--- rows 2-6 of batch6, key cols\n")
print(as.data.frame(a1[2:6, intersect(key,names(a1))]), width=250)
Aall <- bind_rows(lapply(1:8, function(i) {x <- A[[i]][-1,]; x$batch <- i; x}))
cat("total A rows (excl label row):", nrow(Aall), "\n")
for(k in c("V7","V10","treatment","SC0_0","SC0_1","SC0_2","excluded","switch1","T1","T2","T11","one","test1","test2","test3","test4","test5","test6","test7","test8","test9","test10")) {cat("\n==",k,"\n"); print(table(Aall[[k]], useNA="ifany"))}
cat("\nbatch x treatment\n"); print(table(Aall$batch, Aall$treatment, useNA="ifany"))
cat("\nexcluded by batch\n"); print(table(Aall$batch, Aall$excluded, useNA="ifany"))
cat("\niMPL1 sample rows\n"); cols <- grep("^iMPL1_", names(Aall), value=TRUE); print(as.data.frame(Aall[1:8, c(cols,"T1","switch1")]), width=300)
cat("\niMPL2 sample rows\n"); cols <- grep("^iMPL2_", names(Aall), value=TRUE); print(as.data.frame(Aall[1:8, c(cols,"T2","switch2")]), width=300)
for(r in 1:20){ cn <- sprintf("iMPL%d_1_1: 1", r); cat(r, ":", substr(a1[[cn]][1],1,300), "\n")}
cn <- sprintf("iMPL%d_2_3: 1", 1); cat("second list item:", substr(a1[[cn]][1],1,300), "\n")
cn <- sprintf("iMPL%d_2_12: 1", 1); cat("second list last item:", substr(a1[[cn]][1],1,300), "\n")
for(t in 1:10) cat("test",t,":", substr(a1[[paste0("test",t)]][1],1,200), "\n")
# ===== B
B <- lapply(1:2, function(i) rd(sprintf("expBbatch%d.csv",i)))
b1 <- B[[1]]
cat("\nB rows:", sapply(B,nrow), " ncol:", sapply(B,ncol), "\n")
cat("identical names:", identical(names(B[[1]]),names(B[[2]])), "\n")
nb <- names(b1)
cat("B names (non-timing):\n"); print(nb[!grepl("First Click|Last Click|Page Submit|Click Count", nb)])
keyb <- c("Finished","Progress","SC0","treatment","T1","T2","switch1","exclude2","exclude3","exclude4","exclude5","test1","test2","test3","test4","test5","test6","test7","test8","test9","test10","line1","amt1")
for(k in keyb) if(k %in% nb) cat(k, " || ", substr(b1[[k]][1],1,250), " || ", substr(b1[[k]][2],1,80),"\n")
Ball <- bind_rows(lapply(1:2, function(i) {x <- B[[i]][-(1:2),]; x$batch <- i; x}))
cat("total B rows:", nrow(Ball), "\n")
for(k in c("Finished","Status","DistributionChannel","treatment","SC0","exclude2","exclude3","exclude4","exclude5","switch1","T1","T2","test1","test2","test3","test4","test5","test6","test7","test8","test9","test10")) if(k %in% nb) {cat("\n== B",k,"\n"); print(table(Ball[[k]], useNA="ifany"))}
