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
cat("Vars:\n"); print(names(df))

# Running variable: own_amt - 500
df$dist <- as.numeric(df$own_amt) - 500
df$Above500 <- as.numeric(df$Above500)

# Outcome: household earnings per capita
if ("hh_inc_pc_real" %in% names(df)) {
  df$y_level <- as.numeric(df$hh_inc_pc_real)
} else {
  df$y_level <- as.numeric(df$hh_income_pc)
}

# Cluster at former-landholder level
df$cluster_id <- as.character(df$match_id)

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

# IQR: compute IQR of worker earnings per CANTON-YEAR (paper matches at canton level)
# then regress at the property level. Try canton-year aggregation.
run_iqr <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw, !is.na(cluster_id))
  
  # Try canton-year as unit of observation
  group_vars <- c()
  if ("canton" %in% names(d)) group_vars <- c(group_vars, "canton")
  if ("r4" %in% names(d) && length(group_vars)==0) group_vars <- c(group_vars, "r4")
  if ("year" %in% names(d)) group_vars <- c(group_vars, "year")
  if ("ano" %in% names(d) && !"year" %in% group_vars) group_vars <- c(group_vars, "ano")
  
  cat("  iqr grouping vars:", paste(group_vars, collapse=","), "\n")
  
  if (length(group_vars) >= 2) {
    prop_data <- d %>%
      group_by(across(all_of(group_vars))) %>%
      summarise(iqr = IQR(y_level, na.rm = TRUE),
                Above500 = first(Above500),
                dist = first(dist),
                cluster_id = first(cluster_id),
                n_workers = n(),
                .groups = "drop") %>%
      filter(!is.na(iqr), n_workers >= 2)
  } else {
    prop_data <- d %>%
      group_by(cluster_id) %>%
      summarise(iqr = IQR(y_level, na.rm = TRUE),
                Above500 = first(Above500),
                dist = first(dist),
                n_workers = n(),
                .groups = "drop") %>%
      filter(!is.na(iqr))
  }
  prop_data$dist_above <- prop_data$Above500 * prop_data$dist
  nclust <- length(unique(prop_data$cluster_id))
  cat(sprintf("  iqr bw=%g: nprops=%d nclust=%d\n", bw, nrow(prop_data), nclust))
  m <- tryCatch(
    feols(iqr ~ Above500 + dist + dist_above, data = prop_data, cluster = ~cluster_id),
    error = function(e) NULL
  )
  list(coef = safe_coef(m, "Above500"),
       n = if (is.null(m)) nrow(prop_data) else nobs(m),
       nclust = nclust)
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
cat(sprintf("RESULT:n_clusters_bw300=%d\n", fmt_n(r_iqr_300$nclust)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", fmt_n(r_iqr_150$nclust)))

cat('DEVIATION: IQR aggregated at canton-year level to approximate paper 327/118 obs counts; outcome hh_inc_pc_real; running variable own_amt-500.\n')