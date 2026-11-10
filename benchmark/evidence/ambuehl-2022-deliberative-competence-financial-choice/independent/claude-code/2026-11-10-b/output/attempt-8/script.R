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
tst <- paste0("test", 1:10)
keyA <- c(2, 4, 4, 7, 6, 3, 4, 2, 3, 3); keyB <- c(2, 4, 4, 7, 6, 4, 5, 5, 5, 1)
sc <- function(X, key) { M <- sapply(tst, function(t) num(X[[t]])); list(comp = rowSums(sweep(M[, 1:5], 2, key[1:5], "==") * 1, na.rm = TRUE), ctrl = rowSums(sweep(M[, 6:10], 2, key[6:10], "==") * 1, na.rm = TRUE)) }
s <- sc(A, keyA); A$comp <- s$comp; A$ctrl <- s$ctrl
s <- sc(B, keyB); B$comp <- s$comp; B$ctrl <- s$ctrl
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
      nm1 = apply(L1, 1, function(r) any(diff(r) < 0)), nm2 = apply(L2, 1, function(r) any(diff(r) < 0)),
      comp = rowSums(is.na(L1)) == 0 & rowSums(is.na(L2)) == 0)
  }
  r <- bind_rows(res); r$R <- Rv[r$task]; r$t <- tv[r$task]; r$frame <- ifelse(r$task <= 10, "s", "c"); r
}
pa <- build(A, "A"); pb <- build(B, "B")
okA <- pa %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)
okB <- (pb %>% group_by(id) %>% summarise(ok = all(comp)) %>% pull(ok)) & B$Status != "1"
for (e in c("A", "B")) {
  p <- if (e == "A") pa else pb; X <- if (e == "A") A else B; ok <- if (e == "A") okA else okB
  p <- p[p$id %in% which(ok), ]
  p$r <- 100 * (2 * p$o1 - 2 + 0.2 * p$o2 - 0.1) / p$R
  w <- p %>% select(id, R, t, frame, r) %>% pivot_wider(names_from = frame, values_from = r)
  w$d <- -abs(w$c - w$s)
  dm <- w %>% group_by(id) %>% summarise(d = mean(d), c = mean(c), s = mean(s))
  fl <- p %>% group_by(id) %>% summarise(n1 = sum(nm1), n2 = sum(nm2), n11 = sum(o1 == 11), n0 = sum(o1 == 0),
     off = paste(ifelse(nm1 | nm2, paste0(task, ":", s1, "/", s2), ""), collapse = " "), .groups = "drop") %>% filter(n1 + n2 > 0)
  fl$off <- gsub("\\s+", " ", trimws(fl$off))
  fl <- left_join(fl, dm, by = "id")
  fl$cond <- X$cond[fl$id]; fl$compS <- X$comp[fl$id]; fl$ctrlS <- X$ctrl[fl$id]; fl$amt <- X$amt_id[fl$id]
  cat("\n=====", e, "\n")
  fl <- fl %>% arrange(cond, n1 + n2)
  for (i in seq_len(nrow(fl))) cat(sprintf("%s id%d n1=%d n2=%d n11=%d n0=%d comp=%d ctrl=%d d=%.1f c=%.1f s=%.1f | %s\n", fl$cond[i], fl$id[i], fl$n1[i], fl$n2[i], fl$n11[i], fl$n0[i], fl$compS[i], fl$ctrlS[i], fl$d[i], fl$c[i], fl$s[i], substr(fl$off[i], 1, 150)))
  keep <- setdiff(which(ok), fl$id)
  g <- data.frame(id = keep, cond = X$cond[keep], comp = X$comp[keep], ctrl = X$ctrl[keep]) %>% left_join(dm, by = "id")
  print(as.data.frame(g %>% group_by(cond) %>% summarise(n = n(), comp = sum(comp), ctrl = sum(ctrl), dsum = sum(d), d = mean(d), c = mean(c), s = mean(s))))
}
