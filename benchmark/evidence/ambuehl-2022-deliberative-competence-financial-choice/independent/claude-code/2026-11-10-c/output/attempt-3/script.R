# Exploratory 3: arms, answer keys, MPL coding checks (no estimates of listed quantities)
suppressMessages(library(readr)); suppressMessages(library(dplyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-c/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
rd <- function(f) read_csv(file.path(D,f), col_types=cols(.default="c"), name_repair="minimal", progress=FALSE)
A <- bind_rows(lapply(1:8, function(i) {x <- rd(sprintf("expAbatch%d.csv",i)); names(x)[1] <- "V1"; x <- x[-1,]; x$batch <- i; x}))
A <- A[!is.na(A$test1),]
A$arm <- ifelse(A$batch %in% c(1,2,4,5), ifelse(A$treatment=="1","T","C"), ifelse(A$treatment=="1","X_interest","Y_compounding"))
print(table(A$arm))
B <- bind_rows(lapply(1:2, function(i) {x <- rd(sprintf("expBbatch%d.csv",i)); x <- x[-(1:2),]; x$batch <- i; x}))
B <- B[!is.na(B$test1),]
names(B) <- sub("^iMPL(\\d+)-(\\d)#1_iMPL\\d+-\\d_(\\d+)$", "iMPL\\1_\\2_\\3: 1", names(B))
B$arm <- ifelse(B$treatment=="1","T","C")
cat("B DistributionChannel:\n"); print(table(B$DistributionChannel, B$arm))
cat("B Status:\n"); print(table(B$Status, B$arm))
# answers by arm
for (q in 1:10) { cat("\nA test", q, "\n"); print(table(A[[paste0("test",q)]], A$arm)) }
for (q in 1:10) { cat("\nB test", q, "\n"); print(table(B[[paste0("test",q)]], B$arm)) }
# MPL parse
parse <- function(df) {
  out <- list()
  for (r in 1:20) {
    f <- sapply(1:11, function(k) as.integer(df[[sprintf("iMPL%d_1_%d: 1", r, k)]]))
    s <- sapply(3:12, function(k) as.integer(df[[sprintf("iMPL%d_2_%d: 1", r, k)]]))
    if (is.null(dim(f))) f <- matrix(f, nrow=1)
    if (is.null(dim(s))) s <- matrix(s, nrow=1)
    nsw <- function(m) apply(m, 1, function(z) {z <- z[!is.na(z)]; if (length(z) < 2) 0 else sum(diff(z) != 0)})
    rev <- function(m) apply(m, 1, function(z) {z <- z[!is.na(z)]; any(diff(z) < 0)})
    out[[r]] <- data.frame(row=seq_len(nrow(df)), round=r, n1=rowSums(f, na.rm=TRUE), naf=rowSums(is.na(f)), n0s=rowSums(s==0, na.rm=TRUE), nas=rowSums(is.na(s)),
      swf=nsw(f), sws=nsw(s), revf=rev(f), revs=rev(s), swvar=as.integer(df[[paste0("switch", r)]]))
  }
  bind_rows(out)
}
for (nm in c("A","B")) {
  df <- get(nm); p <- parse(df)
  cat("\n=====", nm, "\nNA counts first/second:\n"); print(table(p$naf)); print(table(p$nas))
  cat("switch var == n1:", mean(p$swvar == p$n1, na.rm=TRUE), "\n")
  cat("second list patterns when n1==0 (n0s, nas):\n"); print(table(p$n0s[p$n1==0], p$nas[p$n1==0]))
  cat("second list n0s when n1==11:\n"); print(table(p$n0s[p$n1==11]))
  # multi-switch definitions per subject
  subj <- p |> group_by(row) |> summarise(m2 = any(swf >= 2 | sws >= 2), mrev = any(revf | revs), m2f = any(swf>=2), m2s=any(sws>=2))
  cat("subjects:", nrow(subj), " any >=2 switches:", sum(subj$m2), " any reverse:", sum(subj$mrev), " >=2 first only:", sum(subj$m2f), " >=2 second only:", sum(subj$m2s), " union:", sum(subj$m2 | subj$mrev), "\n")
  print(table(df$arm, subj$m2))
  print(table(df$arm, subj$m2 | subj$mrev))
  # verify x via payment decision
  di <- as.integer(df$decision_index); l2 <- as.numeric(df$line2); a2 <- as.numeric(df$amt2); l1 <- as.numeric(df$line1); a1 <- as.numeric(df$amt1)
  cat("decision_index table:\n"); print(table(di, useNA="ifany"))
  pp <- p[p$round == pmin(pmax(ifelse(is.na(di),1,di),1),20) , ]
  pp <- p[cbind(seq_len(nrow(df)))[,1] + 0 > 0, ][0,]
  chk <- data.frame(di=di, l1=l1, a1=a1, l2=l2, a2=a2)
  chk$n1 <- sapply(seq_len(nrow(df)), function(i) if (is.na(di[i]) || di[i] < 1 || di[i] > 20) NA else p$n1[p$row==i & p$round==di[i]])
  chk$xa <- a2 - 0.2*(l2-1); chk$xf <- 2*chk$n1 - 2
  cat("head chk:\n"); print(head(chk, 15))
  cat("xa==xf:\n"); print(table(abs(chk$xa-chk$xf) < 1e-6, useNA="ifany"))
  print(head(chk[!is.na(chk$xa) & abs(chk$xa-chk$xf) > 1e-6,], 20))
}
cat("\nA dup amt ids:\n"); w <- toupper(trimws(A$amt_id)); print(A[w %in% w[duplicated(w)], c("amt_id","batch","arm")])
w <- toupper(trimws(B$amt_id)); print(B[w %in% w[duplicated(w)], c("amt_id","batch","arm","DistributionChannel","StartDate")])
