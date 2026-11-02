#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
  library(rdrobust)
})

set.seed(42)

data_path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

cat("Nrow:", nrow(df), "\n")

# The paper uses household earnings per capita as outcome
# Use hh_inc_pc_real (real household income per capita)
# Running variable: own_amt (owner's total prereform landholdings) - 500
# Cluster: former landholder (match_id since Land_Owner is very sparse)

df$dist <- as.numeric(df$own_amt) - 500
df$Above500 <- as.numeric(df$Above500)

# Outcome: household earnings per capita (real)
if ("hh_inc_pc_real" %in% names(df)) {
  df$y_level <- as.numeric(df$hh_inc_pc_real)
} else {
  df$y_level <- as.numeric(df$hh_income_pc)
}

cat("y_level non-NA:", sum(!is.na(df$y_level)), "\n")
cat("dist summary:\n"); print(summary(df$dist))
cat("Above500 table:\n"); print(table(df$Above500, useNA="ifany"))

# Cluster at former-landholder level. match_id has 111 unique values which
# is closer to the paper's 98 clusters at bw300.
cluster_var <- "match_id"
cat("Cluster var:", cluster_var, "\n")

df$cluster_id <- as.character(df[[cluster_var]])

df_est <- df %>% filter(!is.na(dist), !is.na(Above500), !is.na(y_level))
cat("df_est nrow:", nrow(df_est), "\n")

safe_coef <- function(m, name) {
  if (is.null(m)) return(NA_real_)
  cfs <- coef(m)
  if (name %in% names(cfs)) cfs[name] else NA_real_
}

run_level <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw)
  d$dist_above <- d$Above500 * d$dist
  nclust <- length(unique(d$cluster_id[!is.na(d$cluster_id)]))
  cat(sprintf("  level bw=%g: n=%d, clusters=%d\n", bw, nrow(d), nclust))
  m <- tryCatch(
    feols(y_level ~ Above500 + dist + dist_above,
          data = d, cluster = ~cluster_id),
    error = function(e) { cat("err:", conditionMessage(e), "\n"); NULL }
  )
  list(coef = safe_coef(m, "Above500"),
       n = if (is.null(m)) nrow(d) else nobs(m),
       nclust = nclust)
}

# IQR analysis - compute IQR of worker earnings per property (match_id)
run_iqr <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw, !is.na(cluster_id))
  prop_data <- d %>%
    group_by(cluster_id) %>%
    summarise(iqr = IQR(y_level, na.rm = TRUE),
              Above500 = first(Above500),
              dist = first(dist),
              n_workers = n(),
              .groups = "drop") %>%
    filter(!is.na(iqr))
  prop_data$dist_above <- prop_data$Above500 * prop_data$dist
  cat(sprintf("  iqr bw=%g: nprops=%d\n", bw, nrow(prop_data)))
  m <- tryCatch(
    feols(iqr ~ Above500 + dist + dist_above, data = prop_data, se = "hetero"),
    error = function(e) NULL
  )
  list(coef = safe_coef(m, "Above500"),
       n = if (is.null(m)) nrow(prop_data) else nobs(m),
       nclust = nrow(prop_data))
}

cat("\n--- Running ---\n")
r_lvl_300 <- run_level(300)
r_lvl_150 <- run_level(150)
r_iqr_300 <- run_iqr(300)
r_iqr_150 <- run_iqr(150)

fmt_n <- function(x) if (is.na(x)) 0L else as.integer(x)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", r_lvl_300$coef))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", r_lvl_150$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", r_iqr_300$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", r_iqr_150$coef))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", fmt_n(r_lvl_300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", fmt_n(r_lvl_150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", fmt_n(r_iqr_300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", fmt_n(r_iqr_150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", fmt_n(r_lvl_300$nclust)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", fmt_n(r_lvl_150$nclust)))

cat('DEVIATION: Changed cluster var from Land_Owner (only 7 unique non-NA) to match_id to match paper cluster counts; outcome changed to hh_inc_pc_real; running variable to own_amt-500 since norm_dist_Above was mostly 0.\n')