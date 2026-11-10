suppressMessages(library(readr)); suppressMessages(library(dplyr)); suppressMessages(library(tidyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 200)
rd <- function(f) read_csv(file.path(D, f), col_types = cols(.default = "c"), show_col_types = FALSE, name_repair = "unique_quiet")
num <- function(v) suppressWarnings(as.numeric(v))
A <- list()
for (b in 1:8) { x <- rd(sprintf("expAbatch%d.csv", b))[-1, ]; x$batch <- b; A[[b]] <- x }
common <- Reduce(intersect, lapply(A, names))
A <- bind_rows(lapply(A, function(x) x[, common]))
B <- bind_rows(lapply(1:2, function(b) { x <- rd(sprintf("expBbatch%d.csv", b))[-(1:2), ]; x$batch <- b; x }))
A$cond <- ifelse(A$batch %in% c(1, 2, 4, 5), ifelse(A$treatment == "1", "T", "C"), ifelse(A$treatment == "1", "S", "R"))
B$cond <- ifelse(B$treatment == "1", "T", "C")
colname <- function(k, l, j, exp) if (exp == "A") paste0("iMPL", k, "_", l, "_", j, ": 1") else paste0("iMPL", k, "-", l, "#1_iMPL", k, "-", l, "_", j)
Rv <- c(20, 18, 16, 14, 12, 20, 18, 16, 14, 12, 20, 20, 18, 18, 16, 16, 14, 14, 12, 12)
tv <- c(72, 72, 72, 72, 72, 36, 36, 36, 36, 36, 36, 72, 36, 72, 36, 72, 36, 72, 36, 72)
build <- function(x, exp) {
  res <- list()
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) num(x[[colname(k, 1, j, exp)]]))
    L2 <- sapply(3:12, function(j) num(x[[colname(k, 2, j, exp)]]))
    res[[k]] <- data.frame(id = seq_len(nrow(x)), task = k, o1 = rowSums(L1 == 1), o2 = rowSums(L2 == 1),
      nm1 = apply(L1, 1, function(r) any(diff(r) < 0)), nm2 = apply(L2, 1, function(r) any(diff(r) < 0)),
      ch1 = apply(L1, 1, function(r) sum(abs(diff(r)))), ch2 = apply(L2, 1, function(r) sum(abs(diff(r)))),
      comp = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
cat("N complete A", sum(okA), " B", sum(okB), "\n")
msdefs <- list(
  all = function(p) p$nm1 | p$nm2,
  L2noedge = function(p) p$nm1 | (p$nm2 & !(p$o1 %in% c(0, 11))),
  L2no0 = function(p) p$nm1 | (p$nm2 & p$o1 != 0),
  L2no11 = function(p) p$nm1 | (p$nm2 & p$o1 != 11),
  ch2plus = function(p) p$ch1 >= 2 | p$ch2 >= 2,
  L1only = function(p) p$nm1,
  nm1_or_ch2 = function(p) p$nm1 | p$ch2 >= 2,
  ch1_or_nm2 = function(p) p$ch1 >= 2 | p$nm2)
ms <- list()
for (nmx in names(msdefs)) {
  fa <- tapply(msdefs[[nmx]](pa), pa$id, any); fb <- tapply(msdefs[[nmx]](pb), pb$id, any)
  cat(sprintf("%-12s A: %d of %d   B: %d of %d\n", nmx, sum(fa[okA]), sum(okA), sum(fb[okB]), sum(okB)))
  ms[[nmx]] <- list(A = fa, B = fb)
}
cat("Edge frequency (o1==0, o1==11) by frame A:\n"); print(table(pa$frame[pa$id %in% which(okA)], pa$o1[pa$id %in% which(okA)]))

valdefs <- list(
  mid = function(p) 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1,
  mid_clip0_20 = function(p) pmin(pmax(2 * p$o1 - 2 + 0.2 * p$o2 - 0.1, 0), 20),
  mid_rclip = function(p) pmin(pmax(2 * p$o1 - 2 + 0.2 * p$o2 - 0.1, 0), p$R),
  edge_fixed = function(p) ifelse(p$o1 == 0, 0, ifelse(p$o1 == 11, 20, 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1)),
  lower = function(p) 2 * p$o1 - 2 + 0.2 * p$o2 - 0.2,
  o2zero_fix = function(p) ifelse(p$o2 == 0, 2 * p$o1 - 2 + 0.1, 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1))
targ <- list(A = c(dC = -24.448, dT = -22.864, dS = -22.012, dR = -19.797, cC = 58.949, cT = 73.261, cS = 62.969, cR = 77.538, sC = 72.255, sT = 72.657, sS = 72.273, sR = 77.623),
             B = c(dC = -25.673, dT = -18.569, cC = 60.244, cT = 75.378, sC = 72.52, sT = 80.35))
for (msn in c("all", "L2noedge", "L2no0", "L2no11")) for (vn in names(valdefs)) {
  out <- c()
  for (e in c("A", "B")) {
    p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
    keep <- which(ok & !ms[[msn]][[e]])
    q <- p[p$id %in% keep, ]
    q$r <- 100 * valdefs[[vn]](q) / q$R
    w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
    w$d <- -abs(w$c - w$s); w$cond <- X$cond[w$id]
    g <- w %>% group_by(cond) %>% summarise(d = mean(d), c = mean(c), s = mean(s), n = n() / 10)
    for (i in seq_len(nrow(g))) out <- c(out, sprintf("%s%s: d=%.3f c=%.3f s=%.3f n=%d", e, g$cond[i], g$d[i], g$c[i], g$s[i], g$n[i]))
  }
  cat("\n--", msn, vn, "\n"); cat(paste(out, collapse = "\n"), "\n")
}
print(targ)
