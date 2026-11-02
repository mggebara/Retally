suppressMessages({library(haven); library(dplyr)})
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
cat("norm_dist_Above vs norm_dist*Above500 max diff:", max(abs(d$norm_dist_Above - d$norm_dist*d$Above500)), "\n")
cat("rows with |norm_dist| in [149,151]:", sum(abs(abs(d$norm_dist)-150) < 1), " in [299,301]:", sum(abs(abs(d$norm_dist)-300) < 1), "\n")
cat("NA hh_income_pc:", sum(is.na(d$hh_income_pc)), "\n")
g <- d %>% group_by(match_id) %>% summarise(nm = n_distinct(num_members), n = n(), num = first(num_members), .groups="drop")
cat("num_members constant within match_id:", all(g$nm==1), "; equals rows per match_id:", mean(g$n==g$num), "\n")
g2 <- d %>% group_by(match_id, year) %>% summarise(nm = n_distinct(num_members), n = n(), num = first(num_members), .groups="drop")
cat("num_members constant within match_id-year:", all(g2$nm==1), "; equals rows per cell:", mean(g2$n==g2$num), "\n")
print(head(as.data.frame(g2), 20))
for (bw in c(300,150)) {
  s <- d[abs(d$norm_dist) <= bw, ]
  c2 <- s %>% group_by(match_id, year) %>% summarise(n=n(), num=first(num_members), .groups="drop")
  cat(sprintf("bw %d: cells %d, cells num_members>=5 %d, cells n>=5 %d, cells n>=2 %d\n", bw, nrow(c2), sum(c2$num>=5), sum(c2$n>=5), sum(c2$n>=2)))
}
