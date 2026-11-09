# Montero (2022, JPE) "Cooperative Property Rights and Development", Table 5.
# RD at the 500 ha cumulative-landholding threshold of the 1980 El Salvador land reform.
# y = a + g*Above500 + f(norm_dist) + survey-round FE, local linear f estimated separately
# on each side of the cutoff, uniform kernel, |norm_dist| < bandwidth (300 / 150 ha),
# SEs clustered by former owner.
# Cols 1-2: worker-level household earnings per capita (hh_inc_pc_real).
# Cols 3-4: interquartile range of household earnings per capita within each
#           property x survey round (one observation per property-round).
suppressPackageStartupMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)
d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d) %>%
  mutate(owner = Expropretario_ISTA,  # former owner (cluster)
         prop  = match_id,            # matched cooperative / hacienda
         round = year,                # survey round
         y     = hh_inc_pc_real)
f <- y ~ Above500 + norm_dist + Above500:norm_dist | round

out <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) < bw, !is.na(y))
  m1 <- feols(f, data = s, cluster = ~owner)
  p <- s %>% group_by(prop, round, owner, Above500, norm_dist) %>%
    summarise(n = n(),
              y = unname(quantile(y, .75, type = 2) - quantile(y, .25, type = 2)),  # Stata-style percentiles
              .groups = "drop")
  m2 <- feols(f, data = p, cluster = ~owner)
  cat(sprintf("Levels bw%d: b=%.3f se=%.3f N=%d properties=%d clusters=%d\n", bw,
              coef(m1)["Above500"], se(m1)["Above500"], nobs(m1),
              nrow(distinct(s, prop, round)), length(unique(s$owner))))
  cat(sprintf("IQR    bw%d: b=%.3f se=%.3f N=%d clusters=%d\n", bw,
              coef(m2)["Above500"], se(m2)["Above500"], nobs(m2), length(unique(p$owner))))
  out[[as.character(bw)]] <- list(b1 = coef(m1)["Above500"], b2 = coef(m2)["Above500"],
                                  n1 = nobs(m1), n2 = nobs(m2), cl = length(unique(s$owner)))
}
cat("DEVIATION: earnings measured with the deflated variable hh_inc_pc_real; IQR sample is every property-round in the bandwidth (the >=5-worker filter is not applied, it does not reproduce the reported N)\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", out[["300"]]$b1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", out[["150"]]$b1))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", out[["300"]]$b2))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", out[["150"]]$b2))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", out[["300"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", out[["150"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", out[["300"]]$n2))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", out[["150"]]$n2))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", out[["300"]]$cl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", out[["150"]]$cl))
