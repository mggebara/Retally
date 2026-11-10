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
a1 <- 20 - 2 * (0:10)
chg <- function(v) sum(abs(diff(v)))
merged <- function(c1, c2, o1, rule) {
  x <- 2 * o1 - 2
  a2 <- x + 1.8 - 0.2 * (0:9)
  if (rule == "L2first") { am <- c(a1, a2); ch <- c(c1, c2); pri <- c(rep(2, 11), rep(1, 10)) }
  if (rule == "L1first") { am <- c(a1, a2); ch <- c(c1, c2); pri <- c(rep(1, 11), rep(2, 10)) }
  if (rule == "dropL2x") { am <- c(a1, a2[1:9]); ch <- c(c1, c2[1:9]); pri <- rep(1, 20) }
  if (rule == "dropL1x") { keep <- abs(a1 - x) > 1e-9; am <- c(a1[keep], a2); ch <- c(c1[keep], c2); pri <- rep(1, length(am)) }
  o <- order(-round(am, 2), pri)
  chg(ch[o])
}
build <- function(x, exp) {
  res <- list()
  for (k in 1:20) {
    L1 <- sapply(1:11, function(j) num(x[[colname(k, 1, j, exp)]]))
    L2 <- sapply(3:12, function(j) num(x[[colname(k, 2, j, exp)]]))
    comp <- rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0
    o1 <- rowSums(L1 == 1); o2 <- rowSums(L2 == 1)
    df <- data.frame(id = seq_len(nrow(x)), task = k, o1, o2, comp,
      nm = apply(L1, 1, function(r) any(diff(r) < 0)) | apply(L2, 1, function(r) any(diff(r) < 0)),
      two = apply(L1, 1, chg) >= 2 | apply(L2, 1, chg) >= 2)
    for (rule in c("L2first", "L1first", "dropL2x", "dropL1x")) {
      df[[rule]] <- sapply(seq_len(nrow(x)), function(i) if (comp[i]) merged(L1[i, ], L2[i, ], o1[i], rule) >= 2 else NA)
    }
    res[[k]] <- df
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
for (rule in c("nm", "two", "L2first", "L1first", "dropL2x", "dropL1x", "u")) {
  for (e in c("A", "B")) {
    p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
    if (rule == "u") p$u <- p$L2first & p$L1first
    fl <- tapply(p[[rule]], p$id, function(v) any(v, na.rm = TRUE))
    keep <- which(ok & !fl)
    q <- p[p$id %in% keep, ]
    q$r <- 100 * (2 * q$o1 - 2 + 0.2 * q$o2 - 0.1) / q$R
    w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
    w$d <- -abs(w$c - w$s); w$cond <- X$cond[w$id]
    g <- w %>% group_by(cond) %>% summarise(d = mean(d), c = mean(c), s = mean(s), n = n() / 10)
    cat(sprintf("%-8s %s flagged %d of %d | %s\n", rule, e, sum(fl[ok]), sum(ok),
      paste(sprintf("%s n=%d d=%.3f c=%.2f s=%.2f", g$cond, g$n, g$d, g$c, g$s), collapse = " ; ")))
  }
}
cat("targets A: C n109 d-24.448 c58.95 s72.26; T n106 d-22.864 c73.26 s72.66; S n128 d-22.012 c62.97 s72.27; R n112 d-19.797 c77.54 s77.62\n")
cat("targets B: C d-25.673 c60.24 s72.52; T d-18.569 c75.38 s80.35; N=348\n")
