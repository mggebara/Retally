#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

cat("Columns of interest:\n")
print(intersect(c("Work_Income","Above500","own_amt","Land_Size","Land_Size_ha",
                  "survey_year","Reform_Coop_id","Hacienda_id","Land_Owner",
                  "norm_dist_Above","match_id","Landholding_Type_Factor"), names(df)))

if ("own_amt" %in% names(df)) {
  df$dist <- df$own_amt - 500
} else if ("norm_dist_Above" %in% names(df)) {
  df$dist <- df$norm_dist_Above
}

df$property_id <- ifelse(!is.na(df$Reform_Coop_id) & df$Reform_Coop_id != "",
                         as.character(df$Reform_Coop_id),
                         as.character(df$Hacienda_id))

cluster_var <- "Land_Owner"
if (!("Land_Owner" %in% names(df))) {
  cluster_var <- "own_amt"
}

df$Above500 <- as.numeric(df$Above500)

df_est <- df %>% filter(!is.na(dist), !is.na(Above500), !is.na(Work_Income))

run_level <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw)
  d <- d %>% filter(!is.na(.data[[cluster_var]]))
  d$dist_above <- d$Above500 * d$dist
  m <- tryCatch(
    feols(Work_Income ~ Above500 + dist + dist_above | survey_year,
          data = d, cluster = as.formula(paste0("~", cluster_var))),
    error = function(e) NULL
  )
  if (is.null(m)) {
    m <- tryCatch(
      feols(Work_Income ~ Above500 + dist + dist_above | survey_year,
            data = d, se = "hetero"),
      error = function(e) NULL
    )
  }
  if (is.null(m)) {
    m <- feols(Work_Income ~ Above500 + dist + dist_above, data = d, se = "hetero")
  }
  coefs <- coef(m)
  list(coef = if ("Above500" %in% names(coefs)) coefs["Above500"] else NA_real_,
       n = nobs(m),
       nclust = length(unique(d[[cluster_var]][!is.na(d[[cluster_var]])])) )
}

build_iqr <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw, !is.na(property_id), property_id != "")
  prop_counts <- d %>% group_by(property_id) %>% summarise(n_workers = n())
  valid_props <- prop_counts$property_id[prop_counts$n_workers >= 5]
  d2 <- d %>% filter(property_id %in% valid_props)
  prop_data <- d2 %>%
    group_by(property_id) %>%
    summarise(iqr = IQR(Work_Income, na.rm = TRUE),
              Above500 = first(Above500),
              dist = first(dist),
              owner = first(.data[[cluster_var]]),
              survey_year = first(survey_year),
              .groups = "drop")
  prop_data
}

run_iqr <- function(bw) {
  pd <- build_iqr(bw)
  pd <- pd %>% filter(!is.na(owner), !is.na(iqr), !is.na(Above500), !is.na(dist))
  pd$dist_above <- pd$Above500 * pd$dist
  m <- tryCatch(
    feols(iqr ~ Above500 + dist + dist_above, data = pd, cluster = ~owner),
    error = function(e) NULL
  )
  if (is.null(m)) {
    m <- feols(iqr ~ Above500 + dist + dist_above, data = pd, se = "hetero")
  }
  coefs <- coef(m)
  list(coef = if ("Above500" %in% names(coefs)) coefs["Above500"] else NA_real_,
       n = nobs(m),
       nclust = length(unique(pd$owner[!is.na(pd$owner)])) )
}

r_lvl_300 <- run_level(300)
r_lvl_150 <- run_level(150)
r_iqr_300 <- run_iqr(300)
r_iqr_150 <- run_iqr(150)

cat(sprintf("RESULT:earnings_level_above500_bw300=%.4f\n", r_lvl_300$coef))
cat(sprintf("RESULT:earnings_level_above500_bw150=%.4f\n", r_lvl_150$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw300=%.4f\n", r_iqr_300$coef))
cat(sprintf("RESULT:earnings_iqr_above500_bw150=%.4f\n", r_iqr_150$coef))
cat(sprintf("RESULT:n_obs_earnings_level_bw300=%d\n", as.integer(r_lvl_300$n)))
cat(sprintf("RESULT:n_obs_earnings_level_bw150=%d\n", as.integer(r_lvl_150$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw300=%d\n", as.integer(r_iqr_300$n)))
cat(sprintf("RESULT:n_obs_earnings_iqr_bw150=%d\n", as.integer(r_iqr_150$n)))
cat(sprintf("RESULT:n_clusters_bw300=%d\n", as.integer(r_lvl_300$nclust)))
cat(sprintf("RESULT:n_clusters_bw150=%d\n", as.integer(r_lvl_150$nclust)))