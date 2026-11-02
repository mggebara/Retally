suppressMessages({library(haven); library(dplyr)})
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d <- d %>% group_by(match_id) %>% mutate(n_prop = n()) %>% ungroup()
print(sort(unique(abs(d$norm_dist[abs(abs(d$norm_dist)-300) < 1]))))
print(table(d$match_id[abs(abs(d$norm_dist)-300) < 1], d$year[abs(abs(d$norm_dist)-300) < 1]))
for (strict in c(FALSE, TRUE)) for (bw in c(300,150)) {
  s <- if (strict) d[abs(d$norm_dist) < bw, ] else d[abs(d$norm_dist) <= bw, ]
  c2 <- s %>% group_by(match_id, year) %>% summarise(n=n(), num=first(num_members), np=first(n_prop), .groups="drop")
  cat(sprintf("strict %d bw %d: rows %d clusters %d | A all cells %d | B num_members>=5 %d | C prop total rows>=5 %d | D cell n>=5 %d\n",
     strict, bw, nrow(s), n_distinct(s$Expropretario_ISTA), nrow(c2), sum(c2$num>=5), sum(c2$np>=5), sum(c2$n>=5)))
}
