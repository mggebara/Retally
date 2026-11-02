suppressMessages(library(tidyverse))
f <- "<repo>/benchmark/.cache/claude-code/dertwinkel-kalt-2022-concentration-bias/blind/2026-11-02-c/mount/dertwinkel_kalt_2022_concentration_bias/Consumption Experiment/Stata/Consumption_Experiment.csv"
d <- read_csv(f, show_col_types = FALSE)
e <- c(129,132,143,115,121,117,135,127)
bal <- d %>% filter(decision_number <= 8)
fin <- d %>% filter(decision_number == 9, pap_sample == 1)
xw <- bal %>% select(tn, utility_point, indifference_point) %>% arrange(tn, utility_point) %>% pivot_wider(names_from = utility_point, values_from = indifference_point, names_prefix = "x")
s <- fin %>% left_join(xw, by = "tn")
X <- as.matrix(s[, paste0("x", 1:8)])
jj <- s$utility_point
s$mine_all <- rowMeans(1 / sweep(X, 2, e, "+"))
s$mine_j <- 1 / (e[jj] + X[cbind(seq_len(nrow(X)), jj)])
s$imp <- s$qe_rad / s$avg_id_stage2
c1 <- s %>% filter(control == 1, abs(avg_id_stage2) > 3)
print(summary(c1$imp / c1$mine_all)); print(summary(c1$imp / c1$mine_j))
print(head(as.data.frame(c1 %>% select(tn, utility_point, avg_id_stage2, imp, mine_all, mine_j, x1, x4, x8)), 10))
# Treatment arm: ratio vs avg x
t1 <- s %>% filter(control == 0, abs(avg_id_stage2) > 3) %>% mutate(ratio = imp / mine_all, avgx = rowMeans(cbind(x1,x2,x3,x4,x5,x6,x7,x8)))
print(summary(lm(ratio ~ avgx, data = t1)))
# implied constant: if imp = mean(1/(e+c+x)), solve for c per subject
solve_c <- function(i) { x <- X[s$tn == t1$tn[i], ]; tryCatch(uniroot(function(cc) mean(1/(e + cc + x)) - t1$imp[i], c(-50, 50))$root, error = function(err) NA) }
cs <- sapply(seq_len(nrow(t1)), solve_c)
print(summary(cs))
