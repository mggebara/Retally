suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d) %>% mutate(owner = Expropretario_ISTA, prop = match_id, round = year)
f <- y ~ Above500 + norm_dist + Above500:norm_dist | round
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) < bw) %>%
    mutate(tri = 1 - abs(norm_dist)/bw, epa = 1 - (norm_dist/bw)^2)
  p <- s %>% group_by(prop, round, owner, Above500, norm_dist, tri, epa) %>%
    summarise(y = unname(quantile(hh_income_pc, .75, type = 2) - quantile(hh_income_pc, .25, type = 2)),
              yr = unname(quantile(hh_inc_pc_real, .75, type = 2) - quantile(hh_inc_pc_real, .25, type = 2)),
              n = n(), .groups = "drop")
  for (k in c("tri", "epa")) {
    m1 <- feols(f, data = mutate(s, y = hh_income_pc), weights = s[[k]], cluster = ~owner)
    m1r <- feols(f, data = mutate(s, y = hh_inc_pc_real), weights = s[[k]], cluster = ~owner)
    m2 <- feols(f, data = p, weights = p[[k]], cluster = ~owner)
    m2r <- feols(f, data = mutate(p, y = yr), weights = p[[k]], cluster = ~owner)
    cat(sprintf("bw%d %s level %8.3f (%6.3f) real %8.3f | iqr %8.3f (%6.3f) real %8.3f\n", bw, k,
      coef(m1)[1], se(m1)[1], coef(m1r)[1], coef(m2)[1], se(m2)[1], coef(m2r)[1]))
  }
  m2r <- feols(f, data = mutate(p, y = yr), cluster = ~owner)
  cat(sprintf("bw%d unif iqr real %8.3f (%6.3f)\n", bw, coef(m2r)[1], se(m2r)[1]))
}
