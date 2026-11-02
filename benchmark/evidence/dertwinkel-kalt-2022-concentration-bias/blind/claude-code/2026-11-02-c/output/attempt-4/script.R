suppressMessages(library(tidyverse))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-02-c/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE)
e <- c(129,132,143,115,121,117,135,127)
bal <- d %>% filter(decision_number <= 8)
fin <- d %>% filter(decision_number == 9, pap_sample == 1)
xw <- bal %>% select(tn, utility_point, indifference_point) %>% arrange(tn, utility_point) %>% pivot_wider(names_from = utility_point, values_from = indifference_point, names_prefix = "x")
s <- fin %>% left_join(xw, by = "tn")
X <- as.matrix(s[, paste0("x", 1:8)])
tr <- s$control == 0
perms <- function(v) { if (length(v) == 1) return(list(v)); out <- list(); for (i in seq_along(v)) for (p in perms(v[-i])) out[[length(out)+1]] <- c(v[i], p); out }
P <- perms(1:8)
err <- sapply(P, function(p) { r <- s$avg_id_stage2 * rowMeans(1 / sweep(X, 2, e[p], "+")); max(abs(r - s$qe_rad)[tr]) })
cat("best perm err", min(err), "perm", P[[which.min(err)]], "\n")
for (k in c(-1, 0, 0.5, 1, 2)) { r <- s$avg_id_stage2 * rowMeans(1 / sweep(X + k, 2, e, "+")); cat("k", k, max(abs(r - s$qe_rad)[tr]), "\n") }
for (a in c(0.5, 1)) { r <- rowMeans(s$avg_id_stage2 / (sweep(X, 2, e, "+") + a * s$avg_id_stage2)); cat("a", a, max(abs(r - s$qe_rad)[tr]), "\n") }
s$imp <- s$qe_rad / s$avg_id_stage2
s$mine <- rowMeans(1 / sweep(X, 2, e, "+"))
print(head(as.data.frame(s %>% filter(control == 0, avg_id_stage2 != 0) %>% transmute(tn, d = avg_id_stage2, imp, mine, ratio = imp / mine, x1, x2, x3, x4, x5, x6, x7, x8)), 15))
print(summary(lm(I(1/imp) ~ I(1/mine), data = s %>% filter(control == 0, abs(avg_id_stage2) > 3))))
