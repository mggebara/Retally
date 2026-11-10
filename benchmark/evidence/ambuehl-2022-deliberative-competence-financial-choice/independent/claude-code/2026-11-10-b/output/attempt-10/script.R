suppressMessages(library(readr)); suppressMessages(library(dplyr)); suppressMessages(library(tidyr))
D <- "<repo>/benchmark/.cache/claude-code/ambuehl-2022-deliberative-competence-financial-choice/independent/2026-11-10-b/mount/ambuehl_2022_deliberative_competence_financial_choice/data/raw"
options(width = 250)
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
      two = apply(L1, 1, function(r) sum(abs(diff(r)))) >= 2 | apply(L2, 1, function(r) sum(abs(diff(r)))) >= 2,
      comp = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
base <- function(p) 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1
vars <- list(
  V0 = base,
  o2zero_xp1 = function(p) ifelse(p$o2 == 0, 2 * p$o1 - 1, base(p)),
  o2zero_xp01 = function(p) ifelse(p$o2 == 0, 2 * p$o1 - 2 + 0.1, base(p)),
  o2zero_xp19 = function(p) ifelse(p$o2 == 0, 2 * p$o1 - 2 + 1.9, base(p)),
  o2ten_xp21 = function(p) ifelse(p$o2 == 10, 2 * p$o1 + 0.1, base(p)),
  edges_floor0 = function(p) pmax(base(p), 0),
  cap_o1_11_20 = function(p) ifelse(p$o1 == 11, 20, base(p)))
samples <- list(nm = function(p) p$nm1 | p$nm2, two = function(p) p$two)
for (sn in names(samples)) for (vn in names(vars)) {
  out <- c()
  for (e in c("A", "B")) {
    p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
    fl <- tapply(samples[[sn]](p), p$id, any)
    q <- p[p$id %in% which(ok & !fl), ]
    q$r <- 100 * vars[[vn]](q) / q$R
    w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
    w$d <- -abs(w$c - w$s); w$cond <- X$cond[w$id]
    g1 <- w %>% group_by(cond) %>% summarise(d = mean(d), c = mean(c), s = mean(s))
    out <- c(out, sprintf("%s%s d=%.3f c=%.2f s=%.2f", e, g1$cond, g1$d, g1$c, g1$s))
  }
  cat(sprintf("%-4s %-14s | %s\n", sn, vn, paste(out, collapse = " ; ")))
}
cat("TARGET d: AC -24.448 AR -19.797 AS -22.012 AT -22.864 BC -25.673 BT -18.569\n")
