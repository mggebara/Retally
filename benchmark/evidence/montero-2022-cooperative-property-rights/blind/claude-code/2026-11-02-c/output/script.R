# Montero (2022), Table 5: earnings levels and within-property IQR at the 500 ha threshold
# Independent, blind reproduction from the paper's description.
suppressMessages({library(haven); library(dplyr); library(fixest)})
set.seed(42)

d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-11-02-c/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d$row_order <- seq_len(nrow(d))

# Variables:
#  outcome: hh_income_pc = household earnings per capita, previous month, dollars
#  running variable: norm_dist = own_amt - 500 (former owner's cumulative landholdings minus 500 ha)
#  treatment: Above500
#  property: match_id ; former owner (cluster): Expropretario_ISTA ; survey round: year
d <- d %>% filter(!is.na(hh_income_pc), !is.na(norm_dist))
d$owner <- as.character(d$Expropretario_ISTA)

# Linear in the running variable separately on each side of the cutoff
fml_lvl <- hh_income_pc ~ Above500 + norm_dist + Above500:norm_dist | year

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) <= bw)
  m <- feols(fml_lvl, data = s, cluster = ~owner, fixef.rm = "none")
  print(summary(m))
  res[[paste0("earnings_level_above500_bw", bw)]] <- unname(coef(m)["Above500"])
  res[[paste0("n_obs_earnings_level_bw", bw)]] <- nobs(m)
  res[[paste0("n_clusters_bw", bw)]] <- length(unique(s$owner[obs(m)]))

  # Within-property interquartile range of household earnings per capita,
  # properties with at least five surveyed members; one observation per property.
  # Percentiles follow Stata's egen pctile convention (R quantile type 2).
  p <- s %>% arrange(row_order) %>% group_by(match_id) %>%
    summarise(n_members = n(),
              iqr = unname(quantile(hh_income_pc, 0.75, type = 2) - quantile(hh_income_pc, 0.25, type = 2)),
              Above500 = first(Above500), norm_dist = first(norm_dist),
              owner = first(owner), year = first(year), .groups = "drop") %>%
    filter(n_members >= 5)
  # keep singleton survey rounds, as Stata's reg with i.year would
  mi <- feols(iqr ~ Above500 + norm_dist + Above500:norm_dist | year, data = p, cluster = ~owner,
              fixef.rm = "none")
  print(summary(mi))
  res[[paste0("earnings_iqr_above500_bw", bw)]] <- unname(coef(mi)["Above500"])
  res[[paste0("n_obs_earnings_iqr_bw", bw)]] <- nobs(mi)
  cat(sprintf("DIAG: bw%d IQR-sample clusters = %d\n", bw, length(unique(p$owner))))
}

cat("DEVIATION: survey-round FE in the one-observation-per-property IQR regressions use the survey year of each property's first row in the file (paper does not say how rounds are assigned when a property's workers span several rounds)\n")
for (nm in c("earnings_level_above500_bw300", "earnings_level_above500_bw150",
             "earnings_iqr_above500_bw300", "earnings_iqr_above500_bw150",
             "n_obs_earnings_level_bw300", "n_obs_earnings_level_bw150",
             "n_obs_earnings_iqr_bw300", "n_obs_earnings_iqr_bw150",
             "n_clusters_bw300", "n_clusters_bw150")) {
  cat(sprintf("RESULT:%s=%s\n", nm, format(res[[nm]], digits = 10)))
}
