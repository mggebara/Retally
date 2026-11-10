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
      comp = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
aa <- c(10, 10, 4.5, 4.5, 2, 2, 0.9, 0.9, 2, 2); xx <- c(.02, .01, .04, .02, .06, .03, .08, .04, .05, .025)
E <- c(Rv[1:10], aa * (1 + xx)^tv[11:20])
cat("exact:", round(E[11:20], 3), "\n")
cat("o2 distribution by frame (A):\n"); print(table(pa$frame, pa$o2))
vars <- list(
  V0 = function(p) list(v = 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1, den = p$R),
  V1_T18exact = function(p) list(v = 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1, den = ifelse(p$task == 18, E[18], p$R)),
  V2_allexact = function(p) list(v = 2 * p$o1 - 2 + 0.2 * p$o2 - 0.1, den = E[p$task]),
  V3_revL2 = function(p) list(v = 2 * p$o1 - 2 + 2.1 - 0.2 * p$o2 - 0.2, den = p$R),
  V4_L1only = function(p) list(v = 2 * p$o1 - 1, den = p$R))
for (vn in names(vars)) {
  cat("\n####", vn, "\n")
  for (e in c("A", "B")) {
    p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
    fl <- tapply(p$nm1 | p$nm2, p$id, any)
    q <- p[p$id %in% which(ok & !fl), ]
    z <- vars[[vn]](q); q$r <- 100 * z$v / z$den
    w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
    w$d <- -abs(w$c - w$s); w$cond <- X$cond[w$id]
    g1 <- w %>% group_by(cond) %>% summarise(d = mean(d))
    g2 <- w %>% group_by(cond, t) %>% summarise(d = mean(d), c = mean(c), s = mean(s), .groups = "drop")
    cat(e, "both:", paste(sprintf("%s %.3f", g1$cond, g1$d), collapse = "; "), "\n")
    cat(paste(sprintf("   %s t=%d d=%.3f c=%.3f s=%.3f", g2$cond, g2$t, g2$d, g2$c, g2$s), collapse = "\n"), "\n")
  }
}
cat("\nTARGETS A both: C -24.448 T -22.864 S -22.012 R -19.797 | 72: C -24.076 T -22.959 S -21.257 R -20.191 | 36: C -24.820 T -22.769 S -22.767 R -19.403\n")
cat("complex A 72: C 56.401 T 70.629 ; 36: C 61.496 T 75.893 ; simple A 72: C 68.637 T 69.513; 36: C 75.874 T 75.801\n")
cat("TARGETS B both: C -25.673 T -18.569 | 72: C -25.945 T -18.441 | 36: C -25.401 T -18.697\n")
cat("complex B 72: C 58.181 T 71.747 ; 36: C 62.308 T 79.010 ; simple B 72: C 69.698 T 77.908; 36: C 75.343 T 82.791\n")
