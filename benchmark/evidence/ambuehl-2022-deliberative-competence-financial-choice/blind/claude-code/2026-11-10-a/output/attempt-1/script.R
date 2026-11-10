D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/blind/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read.csv(file.path(D, f), check.names = FALSE, colClasses = "character", encoding = "UTF-8", fileEncoding = "UTF-8-BOM")
A <- lapply(1:8, function(i) rd(sprintf("expAbatch%d.csv", i)))
a1 <- A[[1]]
cat("Row1 descriptions (A batch1):\n")
for (v in c("V7","V10","SC0_0","SC0_1","SC0_2","test_payment","treatment","line1","line2","amt1","amt2","decision_index","payment_test","payment_for_test","one","switch1","Q108", paste0("test",1:10),"Q95","attention","attn_video","rule72","calculate","help_test")) {
  if (v %in% names(a1)) cat(v, ":", substr(a1[1, v], 1, 400), "\n")
}
a5 <- A[[5]]; cat("batch5 excluded desc:", substr(a5[1,"excluded"],1,300), "\n")
for (i in 1:8) {
  x <- A[[i]][-1, ]
  cat("\n== batch", i, "rows", nrow(x), "\n")
  print(table(treatment = x$treatment, useNA = "ifany"))
  if ("excluded" %in% names(x)) print(table(excluded = x$excluded, useNA = "ifany"))
  print(table(finished = x$V10, useNA = "ifany"))
  print(table(switch1 = x$switch1, useNA = "ifany"))
  print(table(T1 = x$T1, useNA = "ifany"))
  print(table(T11 = substr(x$T11, 1, 60), useNA = "ifany"))
  for (t in 1:10) { cat("test", t, ": "); print(table(x[[paste0("test", t)]], useNA = "ifany")) }
  print(table(payment_test = x$payment_test, useNA = "ifany"))
  print(table(SC0_0 = x$SC0_0, useNA = "ifany"))
}
x <- A[[5]][-1, ]
mpl1 <- function(x, k) grep(paste0("^iMPL", k, "_1_"), names(x), value = TRUE)
mpl2 <- function(x, k) grep(paste0("^iMPL", k, "_2_"), names(x), value = TRUE)
cat("list1 cols task1:", mpl1(x,1), "\nlist2 cols task3:", mpl2(x,3), "\n")
for (r in 1:6) {
  cat("\n-- subject", r, "treat", x$treatment[r], "line1", x$line1[r], "amt1", x$amt1[r], "line2", x$line2[r], "amt2", x$amt2[r], "dec", x$decision_index[r], "\n")
  for (k in 1:20) cat(k, substr(x[[paste0("T",k)]][r], 1, 75), "| L1:", paste(unlist(x[r, mpl1(x,k)]), collapse=""), "| L2:", paste(unlist(x[r, mpl2(x,k)]), collapse=""), "| sw", x[[paste0("switch",k)]][r], "\n")
}
B1 <- rd("expBbatch1.csv")
cat("\nB rows (incl header rows):", nrow(B1), "\n")
for (v in c("Progress","Finished","SC0","test_payment","treatment","exclude2","exclude3","exclude4","exclude5","switch1",paste0("test",1:10),"T1","T11", names(B1)[203:223])) cat(v, ":", substr(B1[1, v], 1, 300), " || ", substr(B1[2, v], 1, 120), "\n")
for (f in c("expBbatch1.csv","expBbatch2.csv")) {
  x <- rd(f); x <- x[-(1:2), ]
  cat("\n==", f, nrow(x), "\n")
  print(table(treatment = x$treatment, useNA = "ifany"))
  print(table(finished = x$Finished, progress = x$Progress == "100", useNA = "ifany"))
  for (v in c("exclude2","exclude3","exclude4","exclude5","switch1")) { cat(v, ":"); print(table(x[[v]], useNA = "ifany")) }
  for (t in 1:10) { cat("test", t, ": "); print(table(x[[paste0("test", t)]], useNA = "ifany")) }
  print(table(SC0 = x$SC0, useNA = "ifany"))
  print(table(T1 = x$T1, useNA = "ifany"))
}
x <- rd("expBbatch1.csv")[-(1:2), ]
for (r in 1:3) {
  cat("\n-- B subject", r, "treat", x$treatment[r], "line1", x$line1[r], "amt1", x$amt1[r], "line2", x$line2[r], "amt2", x$amt2[r], "dec", x$decision_index[r], "\n")
  for (k in 1:20) {
    c1 <- grep(paste0("^iMPL", k, "-1#"), names(x), value = TRUE); c2 <- grep(paste0("^iMPL", k, "-2#"), names(x), value = TRUE)
    cat(k, substr(x[[paste0("T",k)]][r], 1, 75), "| L1:", paste(unlist(x[r, c1]), collapse=","), "| L2:", paste(unlist(x[r, c2]), collapse=","), "| sw", x[[paste0("switch",k)]][r], "\n")
  }
}
