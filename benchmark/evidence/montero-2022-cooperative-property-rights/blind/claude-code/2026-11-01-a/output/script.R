# Montero (2022) Table 5 -- independent, blind reproduction
# RD at the 500 ha cumulative-landholding threshold:
#   y = a + g*Above500 + b1*dist + b2*dist*Above500 + survey-round FE + e,
#   |dist| <= bandwidth, SEs clustered by former owner.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-11-01-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d <- d %>% mutate(dist = norm_dist,            # own_amt - 500
                  dist_above = dist * Above500,
                  owner = as.character(Expropretario_ISTA),
                  prop = as.character(match_id),
                  y = hh_income_pc) %>%
  filter(!is.na(y), !is.na(year))

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(dist) <= bw)
  m <- feols(y ~ Above500 + dist + dist_above | year, data = s, cluster = ~owner)
  cat(sprintf("Levels bw=%d: coef=%.4f se=%.4f N=%d props=%d clusters=%d meanY=%.2f\n",
              bw, coef(m)["Above500"], se(m)["Above500"], nobs(m),
              n_distinct(s$prop), n_distinct(s$owner), mean(s$y)))
  res[[paste0("lev", bw)]] <- m
  res[[paste0("ncl", bw)]] <- n_distinct(s$owner)

  # IQR of household earnings per capita within each property (pooled over
  # survey rounds), properties with >= 5 surveyed workers; one obs per property.
  # Survey-round FE at the property level: the property's modal survey round.
  p <- s %>% group_by(prop) %>%
    summarise(n = n(),
              iqr = as.numeric(quantile(y, 0.75, type = 2) - quantile(y, 0.25, type = 2)),
              Above500 = first(Above500), dist = first(dist), dist_above = first(dist_above),
              owner = first(owner),
              year_mode = as.numeric(names(which.max(table(year)))), .groups = "drop") %>%
    filter(n >= 5)
  mi <- feols(iqr ~ Above500 + dist + dist_above | year_mode, data = p, cluster = ~owner)
  mi0 <- feols(iqr ~ Above500 + dist + dist_above, data = p, cluster = ~owner)
  cat(sprintf("IQR bw=%d: coef=%.4f se=%.4f N=%d clusters=%d meanY=%.2f | no-FE variant coef=%.4f\n",
              bw, coef(mi)["Above500"], se(mi)["Above500"], nobs(mi), n_distinct(p$owner), mean(p$iqr),
              coef(mi0)["Above500"]))
  res[[paste0("iqr", bw)]] <- mi
}

cat("DEVIATION: IQR computed per property pooling all survey rounds (Stata-style type-2 quantiles); survey-round FE in columns 3-4 enter as the property's modal survey round\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", coef(res$lev300)["Above500"]))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", coef(res$lev150)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", coef(res$iqr300)["Above500"]))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", coef(res$iqr150)["Above500"]))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", nobs(res$lev300)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", nobs(res$lev150)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", nobs(res$iqr300)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", nobs(res$iqr150)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", res$ncl300))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", res$ncl150))
