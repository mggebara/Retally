## Montero (2022) Table 5: RD at 500 ha on household earnings per capita (levels and within-property IQR)
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-10-21-b/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d$rv <- d$own_amt - 500                 # running variable: former owner's cumulative holdings minus 500 ha
stopifnot(all((d$rv >= 0) == (d$Above500 == 1)))
d$owner <- d$Expropretario_ISTA          # former-owner id (cluster)
d$prop  <- paste(d$match_id, d$year)     # property x survey round

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(rv) < bw)
  # Levels: worker-level regression
  m1 <- feols(hh_income_pc ~ Above500 + rv + rv:Above500 | year, data = s, cluster = ~owner)
  cat(sprintf("bw %d levels: b=%.3f se=%.3f N=%d props=%d clusters=%d mean=%.2f\n", bw, coef(m1)["Above500"], se(m1)["Above500"],
              nobs(m1), n_distinct(s$prop), n_distinct(s$owner), mean(s$hh_income_pc)))
  # IQR of household earnings per capita within property x survey round
  g <- s %>% group_by(match_id, year, owner, rv, Above500) %>%
    summarise(n = n(), iqr = quantile(hh_income_pc, .75, type = 2) - quantile(hh_income_pc, .25, type = 2), .groups = "drop")
  m2 <- feols(iqr ~ Above500 + rv + rv:Above500 | year, data = g, cluster = ~owner)
  cat(sprintf("bw %d IQR: b=%.3f se=%.3f N=%d clusters=%d mean=%.2f\n", bw, coef(m2)["Above500"], se(m2)["Above500"],
              nobs(m2), n_distinct(g$owner), mean(g$iqr)))
  res[[as.character(bw)]] <- list(b1 = coef(m1)["Above500"], n1 = nobs(m1), b2 = coef(m2)["Above500"], n2 = nobs(m2), cl = n_distinct(s$owner))
}
cat("DEVIATION: IQR computed over all surveyed workers per property-survey round (Stata-style percentiles, R type 2); the 'at least five members' restriction is not applied as a filter because applying it (num_members>=5 or >=5 surveyed workers) does not reproduce the reported 327/118 observations\n")
cat("DEVIATION: bandwidth implemented as strict |own_amt-500| < bw (matches reported N of 4770 at 300 ha)\n")
r3 <- res[["300"]]; r1 <- res[["150"]]
cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", r3$b1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", r1$b1))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", r3$b2))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", r1$b2))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", r3$n1))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", r1$n1))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", r3$n2))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", r1$n2))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", r3$cl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", r1$cl))
