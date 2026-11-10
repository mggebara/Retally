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


## ---------- variants of the multiple-switching rule ----------
flags <- function(df, get) {
  n <- nrow(df)
  init <- function() matrix(FALSE, n, 20)
  f1sw2 <- init(); f1rev <- init(); f2sw2 <- init(); f2rev <- init(); fcomb <- init(); s0 <- init(); s11 <- init()
  for (k in 1:20) {
    l1 <- sapply(1:11, function(j) as.integer(df[[get(k, 1, j)]]))
    l2 <- sapply(3:12, function(j) as.integer(df[[get(k, 2, j)]]))
    nsw <- function(m) rowSums(m[, -1, drop = FALSE] != m[, -ncol(m), drop = FALSE])
    rev1 <- function(m) rowSums(m[, -ncol(m), drop = FALSE] == 1 & m[, -1, drop = FALSE] == 0) > 0
    f1sw2[, k] <- nsw(l1) >= 2; f1rev[, k] <- rev1(l1)
    f2sw2[, k] <- nsw(l2) >= 2; f2rev[, k] <- rev1(l2)
    s <- rowSums(l1 == 1)
    s0[, k] <- s == 0; s11[, k] <- s == 11
    comb <- t(sapply(1:n, function(i) { L <- 2 * s[i]; amt1 <- seq(20, 0, -2)
      c(l1[i, amt1 >= L], l2[i, ], l1[i, amt1 < L]) }))
    fcomb[, k] <- rowSums(comb[, -1] != comb[, -ncol(comb)]) >= 2
  }
  r <- function(m) rowSums(m) > 0
  data.frame(l1sw2 = r(f1sw2), l1rev = r(f1rev), l2sw2 = r(f2sw2), l2rev = r(f2rev), comb = r(fcomb), s0 = r(s0), s11 = r(s11),
             n_l1rev = rowSums(f1rev), n_l2rev = rowSums(f2rev))
}
fa <- flags(a, getA); fb <- flags(bb, getB)
fa$cond <- a$cond; fb$cond <- bb$cond
fa$id <- a$amt_id; fb$id <- bb$amt_id
show <- function(f, lab) {
  cat("\n####", lab, "N =", nrow(f), "\n")
  print(colSums(f[, 1:7]))
  cat("l1sw2|l2sw2:", sum(f$l1sw2 | f$l2sw2), " l1 any:", sum(f$l1sw2 | f$l1rev),
      " l1(sw2|rev)|l2sw2:", sum(f$l1sw2 | f$l1rev | f$l2sw2), " comb:", sum(f$comb), " comb|l1rev:", sum(f$comb | f$l1rev),
      " all:", sum(f$l1sw2 | f$l1rev | f$l2sw2 | f$l2rev), " all|s0:", sum(f$l1sw2 | f$l1rev | f$l2sw2 | f$l2rev | f$s0), "\n")
  m <- f$l1sw2 | f$l1rev | f$l2sw2 | f$l2rev
  print(table(f$cond, m))
  print(table(l1 = f$l1sw2 | f$l1rev, l2 = f$l2sw2 | f$l2rev))
  print(table(f$n_l1rev[m])); print(table(f$n_l2rev[m]))
}
show(fa, "A"); show(fb, "B")
print(fa[fa$id == "A63759KWVJ94F", ]); print(fb[fb$id == "A3AY0315YWWNXY", ])
