# Montero (2022) Table 5: RD at 500 ha cumulative-landholding threshold,
# household earnings per capita (levels and within-property IQR).
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
# running variable: norm_dist = own_amt - 500 (former owner's cumulative holdings, centred)
# property id: match_id; former owner (cluster): Expropretario_ISTA; survey round: year
d <- d %>% mutate(owner = Expropretario_ISTA, prop = match_id, round = year)

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) < bw, !is.na(hh_income_pc))
  m <- feols(hh_income_pc ~ Above500 + norm_dist + Above500:norm_dist | round,
             data = s, cluster = ~owner)
  cat(sprintf("Levels bw%d: b=%.3f se=%.3f N=%d props=%d clusters=%d mean=%.2f\n", bw,
              coef(m)["Above500"], se(m)["Above500"], nobs(m),
              nrow(distinct(s, prop, round)), length(unique(s$owner)), mean(s$hh_income_pc)))
  # IQR within property x survey round; keep property-rounds with >= 5 surveyed workers
  p <- s %>% group_by(prop, round, owner, Above500, norm_dist) %>%
    summarise(n = n(),
              iqr = unname(quantile(hh_income_pc, .75, type = 2) - quantile(hh_income_pc, .25, type = 2)),
              .groups = "drop")
  cat(sprintf("  property-rounds=%d, with n>=5: %d\n", nrow(p), sum(p$n >= 5)))
  p5 <- p %>% filter(n >= 5)
  m2 <- feols(iqr ~ Above500 + norm_dist + Above500:norm_dist | round, data = p5, cluster = ~owner)
  cat(sprintf("IQR bw%d (n>=5): b=%.3f se=%.3f N=%d clusters=%d mean=%.2f\n", bw,
              coef(m2)["Above500"], se(m2)["Above500"], nobs(m2), length(unique(p5$owner)), mean(p5$iqr)))
  m3 <- feols(iqr ~ Above500 + norm_dist + Above500:norm_dist | round, data = p, cluster = ~owner)
  cat(sprintf("IQR bw%d (all property-rounds): b=%.3f se=%.3f N=%d clusters=%d mean=%.2f\n", bw,
              coef(m3)["Above500"], se(m3)["Above500"], nobs(m3), length(unique(p$owner)), mean(p$iqr)))
  res[[as.character(bw)]] <- list(m = m, m2 = m2, s = s, p5 = p5)
}
