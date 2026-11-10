suppressMessages(library(readr)); suppressMessages(library(dplyr)); suppressMessages(library(fixest))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 200)
rd <- function(f) read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet")
num <- function(v) suppressWarnings(as.numeric(v))
tst <- paste0("test", 1:10)

A <- list()
for (b in 1:8) { x <- rd(sprintf("expAbatch%d.csv", b))[-1, ]; x$batch <- b; A[[b]] <- x }
common <- Reduce(intersect, lapply(A, names))
A <- bind_rows(lapply(A, function(x) x[, common]))
A$Status <- A$V7; A$Finished <- A$V10; A$exp <- "A"
B <- bind_rows(lapply(1:2, function(b) { x <- rd(sprintf("expBbatch%d.csv", b))[-(1:2), ]; x$batch <- b; x }))
B$exp <- "B"

colname <- function(k, l, j, exp) if (exp == "A") paste0("iMPL", k, "_", l, "_", j, ": 1") else paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)
build <- function(x, exp) {
  res <- list()
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) num(x[[colname(k, 1, j, exp)]]))
    L2 <- sapply(3:12, function(j) num(x[[colname(k, 2, j, exp)]]))
    ch <- function(M) apply(M, 1, function(r) sum(abs(diff(r))))
    nm <- function(M) apply(M, 1, function(r) any(diff(r) < 0))
    ones1 <- rowSums(L1 == 1); ones2 <- rowSums(L2 == 1)
    res[[k]] <- data.frame(id = seq_len(nrow(x)), task = k, ones1, ones2,
      ch1 = ch(L1), ch2 = ch(L2), nm1 = nm(L1), nm2 = nm(L2),
      first1 = L1[, 1], last1 = L1[, 11], first2 = L2[, 1], last2 = L2[, 10],
      complete = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  bind_rows(res)
}
pa <- build(A, "A"); pb <- build(B, "B")

subj <- function(x, p) {
  s <- p %>% group_by(id) %>% summarise(allc = all(complete), nm = any(nm1 | nm2, na.rm = TRUE), nmL1 = any(nm1, na.rm = TRUE), nmL2 = any(nm2, na.rm = TRUE),
    two = any(ch1 >= 2 | ch2 >= 2, na.rm = TRUE), two1 = any(ch1 >= 2, na.rm = TRUE), two2 = any(ch2 >= 2, na.rm = TRUE),
    rev1 = any(ch1 == 1 & nm1, na.rm = TRUE), rev2 = any(ch2 == 1 & nm2, na.rm = TRUE),
    two_or_rev1 = any(ch1 >= 2 | ch2 >= 2 | (ch1 == 1 & nm1), na.rm = TRUE), .groups = "drop")
  cbind(x, s[match(seq_len(nrow(x)), s$id), -1])
}
A2 <- subj(A, pa); B2 <- subj(B, pb)
A2$testNA <- rowSums(is.na(sapply(tst, function(t) num(A2[[t]]))))
B2$testNA <- rowSums(is.na(sapply(tst, function(t) num(B2[[t]]))))
for (nmx in c("A", "B")) {
  X <- if (nmx == "A") A2 else B2
  cat("\n=====", nmx, "\n")
  cat("allc:", sum(X$allc), " allc by Status/Finished:\n"); print(table(X$Status[X$allc], X$Finished[X$allc]))
  cat("allc & testNA dist:\n"); print(table(X$testNA[X$allc]))
  S <- X[X$allc, ]
  for (cr in c("nm", "nmL1", "nmL2", "two", "two1", "two2", "rev1", "rev2", "two_or_rev1")) cat(cr, sum(S[[cr]]), "; ")
  cat("\n")
  if (nmx == "B") { cat("Distribution channel among allc:\n"); print(table(S$DistributionChannel, S$Status)) }
  cat("dup ids among allc:", S$amt_id[duplicated(S$amt_id)], "\n")
}

# conditions for A
A2$cond <- ifelse(A2$batch %in% c(1, 2, 4, 5), ifelse(A2$treatment == "1", "T", "C"), ifelse(A2$treatment == "1", "G1", "G0"))
keyA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3)
TA <- sapply(tst, function(t) num(A2[[t]]))
A2$comp <- rowSums(sweep(TA[, 1:5], 2, keyA[1:5], "==") * 1, na.rm = TRUE)
A2$ctrl <- rowSums(sweep(TA[, 6:10], 2, keyA[6:10], "==") * 1, na.rm = TRUE)
for (cr in c("nm", "two")) {
  S <- A2[A2$allc & !A2[[cr]], ]
  cat("\nA sample excl", cr, ": N =", nrow(S), "\n"); print(table(S$cond))
  print(S %>% group_by(cond) %>% summarise(comp = mean(comp), ctrl = mean(ctrl), n = n()))
}
# B test: regress SC0 on answer dummies to learn what SC0 scores
TB <- sapply(tst, function(t) num(B2[[t]]))
SB <- B2$allc & B2$testNA == 0
dfb <- data.frame(SC0 = num(B2$SC0)[SB], TB[SB, ])
for (t in tst) dfb[[t]] <- factor(dfb[[t]])
m <- lm(SC0 ~ ., data = dfb)
cf <- coef(m); cat("\nB SC0 regression coefs > 0.5:\n"); print(round(cf[abs(cf) > 0.5], 2)); cat("R2", summary(m)$r.squared, "\n")
for (k7 in 1:5) {
  keyB <- c(2, 4, 4, 7, 6, 4, k7, 5, 5, 1)
  B2$comp <- rowSums(sweep(TB[, 1:5], 2, keyB[1:5], "==") * 1, na.rm = TRUE)
  B2$ctrl <- rowSums(sweep(TB[, 6:10], 2, keyB[6:10], "==") * 1, na.rm = TRUE)
  for (cr in c("nm", "two")) {
    S <- B2[B2$allc & !B2[[cr]], ]
    cat("B key7=", k7, "excl", cr, "N=", nrow(S), ":")
    print(as.data.frame(S %>% group_by(treatment) %>% summarise(comp = mean(comp), ctrl = mean(ctrl), n = n())))
  }
}

# valuations / deliberative competence
Rv <- c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
tv <- c(72, 72, 72, 72, 72, 36, 36, 36, 36, 36, 36, 72, 36, 72, 36, 72, 36, 72, 36, 72)
dc <- function(p, X, cr, condvar) {
  p$val <- 2 * p$ones1 - 2 + 0.2 * p$ones2 - 0.1
  p$R <- Rv[p$task]; p$t <- tv[p$task]; p$frame <- ifelse(p$task <= 10, "s", "c")
  p$r <- 100 * p$val / p$R
  keep <- which(X$allc & !X[[cr]])
  p <- p[p$id %in% keep, ]
  w <- p %>% select(id, R, t, frame, r) %>% tidyr::pivot_wider(names_from = frame, values_from = r)
  w$d <- -abs(w$c - w$s)
  w$cond <- X[[condvar]][w$id]
  w
}
A2$condv <- A2$cond; B2$condv <- ifelse(B2$treatment == "1", "T", "C")
for (cr in c("nm", "two")) {
  wa <- dc(pa, A2, cr, "condv"); wb <- dc(pb, B2, cr, "condv")
  cat("\nDC excl", cr, " A nobs", nrow(wa), "\n")
  print(as.data.frame(wa %>% group_by(cond) %>% summarise(d = mean(d), c = mean(c), s = mean(s), n = n())))
  print(as.data.frame(wb %>% group_by(cond) %>% summarise(d = mean(d), c = mean(c), s = mean(s), n = n())))
}
