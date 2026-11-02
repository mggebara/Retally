# Montero (2022) Table 5: RD at 500 ha, earnings levels and within-property IQR
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})
d <- read_dta("/Users/matthew/dev/Retally/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/independent/2026-11-01-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)
d$dist <- d$own_amt - 500                 # former owner's cumulative holdings, centred at cutoff
d$owner <- as.character(d$Expropretario_ISTA)  # former-owner cluster id
d$prop <- as.character(d$match_id)        # property id
d$y <- d$hh_income_pc                     # household earnings per capita, previous month

stata_iqr <- function(x) { x <- x[!is.na(x)]; if (length(x) == 0) return(NA_real_)
  unname(quantile(x, 0.75, type = 2) - quantile(x, 0.25, type = 2)) }

res <- list()
for (bw in c(300, 150)) {
  s <- d[abs(d$dist) < bw & !is.na(d$y), ]
  m1 <- feols(y ~ Above500 + dist + Above500:dist | year, data = s, cluster = ~owner)
  # property x survey-round cells: IQR of earnings within each
  g <- s %>% group_by(prop, year) %>%
    summarise(iqr = stata_iqr(y), n = n(), dist = first(dist), Above500 = first(Above500),
              owner = first(owner), .groups = "drop")
  m2 <- feols(iqr ~ Above500 + dist + Above500:dist | year, data = g, cluster = ~owner)
  cat(sprintf("bw %d: level b=%.3f se=%.3f N=%d clusters=%d props=%d mean=%.2f\n", bw,
      coef(m1)["Above500"], se(m1)["Above500"], nobs(m1), n_distinct(s$owner),
      nrow(g), mean(s$y)))
  cat(sprintf("bw %d: iqr b=%.3f se=%.3f N=%d clusters=%d mean=%.2f cells n>=5: %d\n", bw,
      coef(m2)["Above500"], se(m2)["Above500"], nobs(m2), n_distinct(g$owner), mean(g$iqr), sum(g$n >= 5)))
  res[[as.character(bw)]] <- list(b1 = coef(m1)["Above500"], n1 = nobs(m1), b2 = coef(m2)["Above500"],
                                  n2 = nobs(m2), cl = n_distinct(s$owner))
}
cat("DEVIATION: IQR regressions use all property-by-survey-round cells (the paper's at-least-five-members filter is not applied) because the paper's observation counts (327/118) equal the total number of such cells.\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", res[["300"]]$b1))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", res[["150"]]$b1))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", res[["300"]]$b2))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", res[["150"]]$b2))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", res[["300"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", res[["150"]]$n1))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", res[["300"]]$n2))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", res[["150"]]$n2))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", res[["300"]]$cl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", res[["150"]]$cl))
