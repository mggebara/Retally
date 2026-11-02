# Montero (2022), Table 5: earnings levels and within-property interquartile range
# Independent, blind reproduction from the paper's description.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)

# Running variable: former owner's cumulative landholdings minus 500 ha
d <- d %>% mutate(
  dist   = own_amt - 500,
  above  = as.integer(own_amt >= 500),          # Above500
  dist_a = dist * above,                         # separate slope above the cutoff
  owner  = Expropretario_ISTA,                   # former owner (cluster)
  prop   = match_id,                             # matched cooperative / hacienda
  yr     = year                                  # survey round
)
stopifnot(all(d$above == d$Above500))

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(dist) < bw)

  # Columns 1-2: worker-level household earnings per capita (previous month)
  m1 <- feols(hh_income_pc ~ above + dist + dist_a | yr, data = s, cluster = ~owner)
  # Columns 3-4: interquartile range of household earnings per capita within
  # each property and survey round (Stata-style percentiles, R type 2)
  p <- s %>% group_by(prop, yr) %>%
    summarise(iqr = unname(quantile(hh_income_pc, 0.75, type = 2) - quantile(hh_income_pc, 0.25, type = 2)),
              n_workers = n(), above = first(above), dist = first(dist), dist_a = first(dist_a),
              owner = first(owner), .groups = "drop")
  m2 <- feols(iqr ~ above + dist + dist_a | yr, data = p, cluster = ~owner)

  cat(sprintf("\n=== bandwidth %d ===\n", bw)); print(summary(m1)); print(summary(m2))
  cat(sprintf("levels: N=%d properties(prop-year)=%d clusters=%d meanDV=%.2f\n", nobs(m1),
              nrow(distinct(s, prop, yr)), n_distinct(s$owner), mean(s$hh_income_pc)))
  cat(sprintf("iqr:    N=%d clusters=%d meanDV=%.2f  (cells with >=5 workers: %d)\n", nobs(m2),
              n_distinct(p$owner), mean(p$iqr), sum(p$n_workers >= 5)))
  res[[as.character(bw)]] <- list(b1 = coef(m1)[["above"]], b2 = coef(m2)[["above"]],
    n1 = nobs(m1), n2 = nobs(m2), cl = n_distinct(s$owner))
}

cat("DEVIATION: IQR sample uses every property-survey-round cell inside the bandwidth (the paper's 'at least five members' filter, applied literally per cell, would leave far fewer units than the properties the paper reports); bandwidth inclusion is strict (|dist| < bw).\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", res[["300"]]$b1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", res[["150"]]$b1))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", res[["300"]]$b2))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", res[["150"]]$b2))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", res[["300"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", res[["150"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", res[["300"]]$n2))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", res[["150"]]$n2))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", res[["300"]]$cl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", res[["150"]]$cl))
