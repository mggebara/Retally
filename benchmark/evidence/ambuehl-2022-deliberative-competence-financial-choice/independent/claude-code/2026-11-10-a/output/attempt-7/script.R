## Ambuehl, Bernheim & Lusardi (2022) -- independent reproduction of Table 4 and Table 7 (cols 1-2)
suppressPackageStartupMessages({ library(fixest) })
set.seed(42)
EMIT <- FALSE   # exploratory run: no RESULT lines
options(width = 200)
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-a/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"

## ---------------- read Experiment A (old Qualtrics export: 1 description row) -------------
A <- list()
for (b in 1:8) {
  x <- read.csv(file.path(D, sprintf("expAbatch%d.csv", b)), check.names = FALSE,
                stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM", colClasses = "character")
  x <- x[-1, ]
  x <- x[, names(x) != "" & !duplicated(names(x)) & names(x) != "excluded"]
  x$batch <- b
  A[[b]] <- x
}
common <- Reduce(intersect, lapply(A, names))
a <- do.call(rbind, lapply(A, function(x) x[, common]))
# list columns: iMPLk_1_j: 1 / iMPLk_2_j: 1
getA <- function(k, l, j) paste0("iMPL", k, "_", l, "_", j, ": 1")
## ---------------- read Experiment B (new Qualtrics export: 2 description rows) -------------
B <- list()
for (b in 1:2) {
  x <- read.csv(file.path(D, sprintf("expBbatch%d.csv", b)), check.names = FALSE,
                stringsAsFactors = FALSE, colClasses = "character")
  x <- x[-(1:2), ]
  x <- x[, names(x) != "" & !duplicated(names(x))]
  x$batch <- b
  B[[b]] <- x
}
bb <- rbind(B[[1]], B[[2]][, names(B[[1]])])
getB <- function(k, l, j) paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)

## ---------------- task structure ----------------
# T1..T10 simple (72d: R=20,18,16,14,12; 36d: same); T11..T20 complex
tasks <- data.frame(k = 1:20,
  frame = rep(c("s", "c"), each = 10),
  R = c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12),
  t = c(rep(72, 5), rep(36, 5), 36, 72, 36, 72, 36, 72, 36, 72, 36, 72))

## valuation & switching from raw choices (0 = immediate/left, 1 = future/right)
process <- function(df, get) {
  n <- nrow(df)
  V <- matrix(NA_real_, n, 20); MS_a <- matrix(FALSE, n, 20); MS_b <- matrix(FALSE, n, 20)
  S <- matrix(NA_integer_, n, 20)
  for (k in 1:20) {
    l1 <- sapply(1:11, function(j) as.integer(df[[get(k, 1, j)]]))
    l2 <- sapply(3:12, function(j) as.integer(df[[get(k, 2, j)]]))
    nsw <- function(m) rowSums(m[, -1, drop = FALSE] != m[, -ncol(m), drop = FALSE])
    rev1 <- function(m) rowSums(m[, -ncol(m), drop = FALSE] == 1 & m[, -1, drop = FALSE] == 0) > 0
    MS_a[, k] <- nsw(l1) >= 2 | nsw(l2) >= 2
    MS_b[, k] <- rev1(l1) | rev1(l2)
    s <- rowSums(l1 == 1); n2 <- rowSums(l2 == 0)
    S[, k] <- s
    V[, k] <- 2 * s - 0.2 * n2 - 0.1
  }
  list(V = V, MS_a = rowSums(MS_a) > 0, MS_b = rowSums(MS_b) > 0, S = S)
}

## ---------------- Experiment A sample ----------------
im <- grep("^iMPL", names(a), value = TRUE)
a$has_mpl <- rowSums(a[, im] != "")
a <- a[a$test1 != "" & a$has_mpl == length(im), ]
a$cond <- ifelse(a$batch %in% c(1, 2, 4, 5),
                 ifelse(a[["code treat"]] != "", "Treatment", ifelse(a$Q130 != "", "Control", NA)),
                 ifelse(a[["code treat"]] != "", "SubstanceOnly", ifelse(a$Q130 != "", "RhetoricOnly", NA)))
cat("Exp A completed:", nrow(a), "\n"); print(table(a$cond, useNA = "ifany"))
pa <- process(a, getA)
cat("A multiple switchers (>=2 switches):", sum(pa$MS_a), " (any reversal):", sum(pa$MS_b), "\n")
print(table(a$cond, pa$MS_a))
## ---------------- Experiment B sample ----------------
imb <- grep("^iMPL", names(bb), value = TRUE)
bb$has_mpl <- rowSums(bb[, imb] != "")
bb <- bb[bb$test1 != "" & bb$has_mpl == length(imb), ]
bb$cond <- ifelse(bb$treatment == "1", "Treatment", "Control")
cat("Exp B completed:", nrow(bb), "\n"); print(table(bb$cond)); print(table(bb$Finished, bb$Progress))
pb <- process(bb, getB)
cat("B multiple switchers (>=2 switches):", sum(pb$MS_a), " (any reversal):", sum(pb$MS_b), "\n")
print(table(bb$cond, pb$MS_a))
d <- bb$amt_id[duplicated(bb$amt_id)]
print(cbind(bb[bb$amt_id %in% d, c("amt_id", "Finished", "Progress", "StartDate", "cond")], MS = pb$MS_a[bb$amt_id %in% d]))
d <- a$amt_id[duplicated(a$amt_id)]
print(cbind(a[a$amt_id %in% d, c("amt_id", "batch", "cond")], MS = pa$MS_a[a$amt_id %in% d]))

## ---------------- test scores ----------------
scoreA <- function(x) {
  comp <- (x$test1 == "2") + (x$test2 == "4") + (x$test3 %in% c("4", "10")) + (x$test4 == "7") + (x$test5 == "6")
  ctrl <- (x$test6 == "3") + (x$test7 == "4") + (x$test8 == "2") + (x$test9 == "3") + (x$test10 == "3")
  ctrl2 <- (x$test6 == "3") + (x$test7 == "4") + (x$test8 == "2") + (x$test9 == "3") + (x$test10 == "2")
  data.frame(comp = comp, ctrl = ctrl, ctrl2 = ctrl2)
}
scoreB <- function(x) {
  comp <- (x$test1 == "2") + (x$test2 == "4") + (x$test3 %in% c("4", "10")) + (x$test4 == "7") + (x$test5 == "6")
  ctrl <- (x$test6 == "4") + (x$test7 == "5") + (x$test8 == "5") + (x$test9 == "5") + (x$test10 == "1")
  data.frame(comp = comp, ctrl = ctrl, ctrl2 = ctrl)
}
for (ms in c("MS_a", "MS_b")) {
  cat("\n==== exclusion rule", ms, "\n")
  ka <- !pa[[ms]]; kb <- !pb[[ms]]
  sa <- cbind(a[ka, c("amt_id", "cond")], scoreA(a[ka, ]))
  sb <- cbind(bb[kb, c("amt_id", "cond")], scoreB(bb[kb, ]))
  print(table(sa$cond)); print(table(sb$cond))
  sa4 <- sa[sa$cond %in% c("Control", "Treatment"), ]
  print(aggregate(cbind(comp, ctrl, ctrl2) ~ cond, sa4, mean))
  print(aggregate(cbind(comp, ctrl) ~ cond, sb, mean))
  ## deliberative competence
  mk <- function(df, p, keep) {
    out <- list()
    for (R in c(20, 18, 16, 14, 12)) for (t in c(36, 72)) {
      ks <- tasks$k[tasks$frame == "s" & tasks$R == R & tasks$t == t]
      kc <- tasks$k[tasks$frame == "c" & tasks$R == R & tasks$t == t]
      out[[length(out) + 1]] <- data.frame(id = df$amt_id[keep], rid = which(keep), cond = df$cond[keep], R = R, t = t,
        vs = p$V[keep, ks], vc = p$V[keep, kc])
    }
    o <- do.call(rbind, out)
    o$dc <- -100 * abs(o$vc - o$vs) / o$R
    o
  }
  da <- mk(a, pa, ka); db <- mk(bb, pb, kb)
  cat("obs A", nrow(da), "B", nrow(db), "\n")
  print(aggregate(dc ~ cond, da, mean)); print(aggregate(dc ~ cond, db, mean))
  cat("vals <0 or >20: A", sum(da$vs < 0 | da$vc < 0 | da$vs > 20 | da$vc > 20), " B", sum(db$vs < 0 | db$vc < 0 | db$vs > 20 | db$vc > 20), "\n")
}
