# Montero (2022, JPE) "Cooperative Property Rights and Development", Table 5
# Independent, blind reproduction.  Data: ehpm_incomemodule_wreform.dta
#
# Specification (from the paper text):
#   y = a + g*Above500 + f(holdings) + survey-round FE + e
#   f(): local linear in former owner's cumulative landholdings minus 500 ha,
#        estimated separately on each side (Above500 x norm_dist interaction)
#   sample: properties within 300 / 150 ha of the 500 ha threshold
#   household surveys 2002-2013 (as stated in the paper)
#   SEs clustered by former owner (Expropretario_ISTA)
# Cols 1-2: worker-level household earnings per capita (hh_income_pc, $/month)
# Cols 3-4: property-level IQR (p75 - p25) of hh_income_pc, properties with >= 5
#           surveyed workers; survey FE enter as the property's shares of
#           observations in each survey round (collapsed year dummies).
set.seed(42)
suppressMessages({library(haven); library(dplyr); library(fixest)})

d <- read_dta("<repo>/benchmark/.cache/claude-code/montero-2022-cooperative-property-rights/blind/2026-11-07-a/mount/montero_2022_cooperative_property_rights/ehpm_incomemodule_wreform.dta")
d <- zap_labels(d)

d <- d %>%
  filter(year >= 2002, year <= 2013, !is.na(hh_income_pc)) %>%
  mutate(owner = as.character(Expropretario_ISTA),
         prop  = as.character(match_id),
         year  = as.integer(year))
cat("Rows 2002-2013:", nrow(d), "\n")

# Stata-style percentiles (summarize / collapse definition) = R type 2
stata_iqr <- function(x) unname(quantile(x, 0.75, type = 2) - quantile(x, 0.25, type = 2))

res <- list()
for (bw in c(300, 150)) {
  s <- d %>% filter(abs(norm_dist) <= bw)

  # ---- Levels (worker-level) ----
  m1 <- feols(hh_income_pc ~ Above500 + norm_dist + Above500:norm_dist | year,
              data = s, cluster = ~owner)
  cat("\n==== Levels, bandwidth", bw, "====\n"); print(summary(m1))
  ss <- s[obs(m1), ]
  cat("Mean dep var:", mean(ss$hh_income_pc), " Properties:", n_distinct(ss$prop),
      " Clusters:", n_distinct(ss$owner), "\n")

  # ---- IQR (property-level) ----
  yrs <- sort(unique(d$year))
  p <- s %>% group_by(prop) %>%
    summarise(owner = first(owner), Above500 = first(Above500), norm_dist = first(norm_dist),
              n_w = n(), iqr = stata_iqr(hh_income_pc),
              .groups = "drop")
  sh <- s %>% count(prop, year) %>% group_by(prop) %>% mutate(share = n / sum(n)) %>%
    ungroup() %>% select(-n) %>%
    tidyr::pivot_wider(names_from = year, values_from = share, values_fill = 0,
                       names_prefix = "sy_")
  p <- p %>% left_join(sh, by = "prop") %>% filter(n_w >= 5)
  sycols <- grep("^sy_", names(p), value = TRUE)
  sycols <- sycols[sapply(sycols, function(v) var(p[[v]]) > 0)]
  sycols <- sycols[-1]  # drop one round as the base
  f2 <- as.formula(paste("iqr ~ Above500 + norm_dist + Above500:norm_dist +",
                         paste(sycols, collapse = " + ")))
  m2 <- feols(f2, data = p, cluster = ~owner)
  cat("\n==== IQR, bandwidth", bw, "====\n"); print(summary(m2))
  cat("Mean dep var:", mean(p$iqr), " Properties:", nrow(p),
      " Clusters:", n_distinct(p$owner), "\n")

  res[[as.character(bw)]] <- list(
    b_lev = unname(coef(m1)["Above500"]), n_lev = nobs(m1), cl = n_distinct(ss$owner),
    b_iqr = unname(coef(m2)["Above500"]), n_iqr = nobs(m2))
}

cat("\n")
cat(sprintf("RESULT:earnings_level_above500_bw300=%.6f\n", res[["300"]]$b_lev))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.6f\n", res[["150"]]$b_lev))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.6f\n", res[["300"]]$b_iqr))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.6f\n", res[["150"]]$b_iqr))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", res[["300"]]$n_lev))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", res[["150"]]$n_lev))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", res[["300"]]$n_iqr))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", res[["150"]]$n_iqr))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", res[["300"]]$cl))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", res[["150"]]$cl))
