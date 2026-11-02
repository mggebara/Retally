suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-02-c/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
# counts only (no estimates)
for (bw in c(300,150)) {
  s <- d %>% filter(abs(norm_dist) < bw)
  cat("bw", bw, "N", nrow(s), "ISTA", n_distinct(s$Expropretario_ISTA), "own_amt", n_distinct(s$own_amt),
      "match_id x year", n_distinct(paste(s$match_id, s$year)), "match_id", n_distinct(s$match_id), "\n")
  g <- s %>% group_by(match_id, year) %>% summarise(n = n(), nm = first(num_members), nmu = n_distinct(num_members), .groups = "drop")
  cat(" cells", nrow(g), "n>=5", sum(g$n >= 5), "num_members>=5", sum(g$nm >= 5), "max distinct num_members within cell", max(g$nmu), "\n")
  print(table(cut(g$n, c(0,1,2,4,9,1e6))))
}
