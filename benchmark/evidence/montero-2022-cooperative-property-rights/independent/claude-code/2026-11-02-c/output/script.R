# Independent reproduction: Montero (2022), Table 5
# RD at the 500 ha cumulative-landholding threshold; local linear in the running
# variable (norm_dist = own_amt - 500) separately on each side; survey-round (year) FE;
# SEs clustered by former owner (Expropretario_ISTA). Uniform kernel, |norm_dist| < bw.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-02-c/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)

# Stata-style percentile (egen pctile / _pctile default definition) == R quantile type 2
pct <- function(x, p) unname(quantile(x, p, type = 2))

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) < bw, !is.na(hh_income_pc))
  # Columns 1-2: worker-level household earnings per capita
  m1 <- feols(hh_income_pc ~ Above500 + norm_dist + Above500:norm_dist | year, s,
              cluster = ~Expropretario_ISTA)
  # Columns 3-4: within-property (property x survey round) interquartile range
  g <- s %>% group_by(match_id, year, Expropretario_ISTA, norm_dist, Above500) %>%
    summarise(n = n(), iqr = pct(hh_income_pc, .75) - pct(hh_income_pc, .25), .groups = "drop")
  m2 <- feols(iqr ~ Above500 + norm_dist + Above500:norm_dist | year, g,
              cluster = ~Expropretario_ISTA)
  cat(sprintf("bw %d: level b=%.3f se=%.3f N=%d clusters=%d mean=%.2f | iqr b=%.3f se=%.3f N=%d mean=%.2f\n",
              bw, coef(m1)["Above500"], se(m1)["Above500"], nobs(m1), n_distinct(s$Expropretario_ISTA), mean(s$hh_income_pc),
              coef(m2)["Above500"], se(m2)["Above500"], nobs(m2), mean(g$iqr)))
  res[[paste0("earnings_level_above500_bw", bw)]] <- coef(m1)["Above500"]
  res[[paste0("earnings_iqr_above500_bw", bw)]] <- coef(m2)["Above500"]
  res[[paste0("n_obs_earnings_level_bw", bw)]] <- nobs(m1)
  res[[paste0("n_obs_earnings_iqr_bw", bw)]] <- nobs(m2)
  res[[paste0("n_clusters_bw", bw)]] <- n_distinct(s$Expropretario_ISTA)
}
cat("DEVIATION: IQR computed per property x survey round (match_id x year) over all such cells; the 'at least five members' restriction is not applied because the reported observation counts (327/118) equal all property-round cells\n")
for (k in c("earnings_level_above500_bw300", "earnings_level_above500_bw150",
            "earnings_iqr_above500_bw300", "earnings_iqr_above500_bw150",
            "n_obs_earnings_level_bw300", "n_obs_earnings_level_bw150",
            "n_obs_earnings_iqr_bw300", "n_obs_earnings_iqr_bw150",
            "n_clusters_bw300", "n_clusters_bw150"))
  cat(sprintf("RESULT:%s=%s\n", k, format(unname(res[[k]]), digits = 8)))
