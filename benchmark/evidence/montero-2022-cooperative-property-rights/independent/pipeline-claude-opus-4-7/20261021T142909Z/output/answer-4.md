#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_path <- "/Users/matthew/dev/Retally/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

cat("Columns in data:\n")
print(names(df))
cat("\nNrow:", nrow(df), "\n")

# Explore key vars
for (v in c("Work_Income","Above500","own_amt","Land_Size","Land_Size_ha",
            "survey_year","Reform_Coop_id","Hacienda_id","Land_Owner",
            "norm_dist_Above","match_id","Landholding_Type_Factor")) {
  if (v %in% names(df)) {
    cat(sprintf("%s: class=%s, non-NA=%d, unique=%d\n", v, class(df[[v]])[1],
                sum(!is.na(df[[v]])), length(unique(df[[v]]))))
  }
}

# The running variable - try norm_dist_Above first since it's named "distance"
if ("norm_dist_Above" %in% names(df)) {
  df$dist <- as.numeric(df$norm_dist_Above)
  cat("Using norm_dist_Above as dist\n")
} else if ("own_amt" %in% names(df)) {
  df$dist <- as.numeric(df$own_amt) - 500
  cat("Using own_amt - 500 as dist\n")
}

cat("dist summary:\n"); print(summary(df$dist))
cat("Above500 table:\n"); print(table(df$Above500, useNA="ifany"))

# property identifier
df$property_id <- NA_character_
if ("Reform_Coop_id" %in% names(df)) {
  rc <- as.character(df$Reform_Coop_id)
  df$property_id <- ifelse(!is.na(rc) & rc != "" & rc != "0", rc, df$property_id)
}
if ("Hacienda_id" %in% names(df)) {
  hc <- as.character(df$Hacienda_id)
  df$property_id <- ifelse(is.na(df$property_id), hc, df$property_id)
}

# cluster var - former landholder
cluster_var <- "Land_Owner"
if (!("Land_Owner" %in% names(df))) {
  if ("match_id" %in% names(df)) cluster_var <- "match_id"
  else cluster_var <- "own_amt"
}
cat("Cluster var:", cluster_var, "\n")

df$Above500 <- as.numeric(df$Above500)

df_est <- df %>% filter(!is.na(dist), !is.na(Above500), !is.na(Work_Income))
cat("df_est nrow:", nrow(df_est), "\n")
cat("df_est dist summary:\n"); print(summary(df_est$dist))

safe_coef <- function(m, name) {
  if (is.null(m)) return(NA_real_)
  cfs <- coef(m)
  if (name %in% names(cfs)) cfs[name] else NA_real_
}

run_level <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw)
  cat(sprintf("  level bw=%g: n=%d, clusters=%d\n", bw, nrow(d),
              length(unique(d[[cluster_var]][!is.na(d[[cluster_var]])]))))
  d$dist_above <- d$Above500 * d$dist
  m <- tryCatch(
    feols(Work_Income ~ Above500 + dist + dist_above | survey_year,
          data = d, cluster = as.formula(paste0("~", cluster_var))),
    error = function(e) { cat("err:", conditionMessage(e), "\n"); NULL }
  )
  if (is.null(m)) {
    m <- tryCatch(
      feols(Work_Income ~ Above500 + dist + dist_above, data = d,
            cluster = as.formula(paste0("~", cluster_var))),
      error = function(e) NULL
    )
  }
  list(coef = safe_coef(m, "Above500"),
       n = if (is.null(m)) nrow(d) else nobs(m),
       nclust = length(unique(d[[cluster_var]][!is.na(d[[cluster_var]])])) )
}

build_iqr <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw, !is.na(property_id))
  prop_data <- d %>%
    group_by(property_id) %>%
    summarise(iqr = IQR(Work_Income, na.rm = TRUE),
              Above500 = first(Above500),
              dist = first(dist),
              owner = first(.data[[cluster_var]]),
              n_workers = n(),
              .groups = "drop")
  prop_data
}

run_iqr <- function(bw) {
  pd <- build_iqr(bw)
  pd <- pd %>% filter(!is.na(iqr), !is.na(Above500), !is.na(dist))
  cat(sprintf("  iqr bw=%g: nprops=%d\n", bw, nrow(pd)))
  pd$dist_above <- pd$Above500 * pd$dist
  m <- tryCatch(
    feols(iqr ~ Above500 + dist + dist_above, data = pd, cluster = ~owner),
    error = function(e) NULL
  )
  if (is.null(m)) {
    m <- tryCatch(feols(iqr ~ Above500 + dist + dist_above, data = pd, se = "hetero"),
                  error = function(e) NULL)
  }
  list(coef = safe_coef(m, "Above500"),
       n = if (is.null(m)) nrow(pd) else nobs(m),
       nclust = length(unique(pd$owner[!is.na(pd$owner)])) )
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