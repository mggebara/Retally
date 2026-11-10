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
      s1 = apply(L1, 1, paste, collapse = ""), s2 = apply(L2, 1, paste, collapse = ""),
      sw = num(x[[paste0("switch", k)]]),
      nm1 = apply(L1, 1, function(r) any(diff(r) < 0)), nm2 = apply(L2, 1, function(r) any(diff(r) < 0)),
      comp = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
for (e in c("A", "B")) {
  p <- if (e == "A") pa else pb; ok <- if (e == "A") okA else okB
  p <- p[p$id %in% which(ok), ]
  fl <- p %>% group_by(id) %>% summarise(n1 = sum(nm1), n2 = sum(nm2), .groups = "drop") %>% filter(n1 + n2 > 0)
  cat("\n=====", e, "flagged subjects", nrow(fl), "\n")
  print(as.data.frame(fl %>% arrange(n1 + n2)))
  bad <- p[(p$nm1 | p$nm2), ]
  bad <- bad[bad$id %in% fl$id[fl$n1 + fl$n2 <= 2], ]
  print(bad[, c("id", "task", "s1", "s2", "o1", "sw", "nm1", "nm2")], row.names = FALSE)
  cat("switch var mismatches with o1 (non-NA):", sum(p$sw != p$o1, na.rm = TRUE), " non-NA sw:", sum(!is.na(p$sw)), "\n")
}
# per-delay stats, baseline definitions
for (e in c("A", "B")) {
  p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
  fl <- tapply(p$nm1 | p$nm2, p$id, any)
  keep <- which(ok & !fl)
  q <- p[p$id %in% keep, ]
  q$r <- 100 * (2 * q$o1 - 2 + 0.2 * q$o2 - 0.1) / q$R
  w <- q %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
  w$d <- -abs(w$c - w$s); w$cond <- X$cond[w$id]
  print(as.data.frame(w %>% group_by(cond, t) %>% summarise(d = mean(d), c = mean(c), s = mean(s), .groups = "drop")))
  print(as.data.frame(w %>% group_by(cond, R, t) %>% summarise(d = mean(d), c = mean(c), s = mean(s), .groups = "drop") %>% filter(cond == "C")))
}
