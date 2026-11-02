#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(fixest)
})

set.seed(42)

data_path <- "<repo>/.cache/datasets/montero_2022_cooperative_property_rights.script-free/ehpm_incomemodule_wreform.dta"
df <- read_dta(data_path)

# Inspect key variables
cat("Columns of interest:\n")
print(intersect(c("Work_Income","Above500","own_amt","Land_Size","Land_Size_ha",
                  "survey_year","Reform_Coop_id","Hacienda_id","Land_Owner",
                  "norm_dist_Above","match_id","Landholding_Type_Factor"), names(df)))

# Running variable: owner's total prereform landholdings (own_amt)
# Distance from 500 cutoff
if ("own_amt" %in% names(df)) {
  df$dist <- df$own_amt - 500
} else if ("norm_dist_Above" %in% names(df)) {
  df$dist <- df$norm_dist_Above
}

# Property identifier - try Reform_Coop_id or Hacienda_id, prefer a combined one
df$property_id <- ifelse(!is.na(df$Reform_Coop_id) & df$Reform_Coop_id != "",
                         as.character(df$Reform_Coop_id),
                         as.character(df$Hacienda_id))

# Cluster: former owner
cluster_var <- "Land_Owner"
if (!("Land_Owner" %in% names(df))) {
  cluster_var <- "own_amt"
}

# Make Above500 numeric
df$Above500 <- as.numeric(df$Above500)

# Filter: in risk set (non-missing dist, Above500, Work_Income)
df_est <- df %>% filter(!is.na(dist), !is.na(Above500), !is.na(Work_Income))

run_level <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw)
  m <- feols(Work_Income ~ Above500 + dist + I(Above500*dist) | survey_year,
             data = d, cluster = as.formula(paste0("~", cluster_var)))
  list(coef = coef(m)["Above500"],
       n = nobs(m),
       nclust = length(unique(d[[cluster_var]][!is.na(d[[cluster_var]])])) )
}

# IQR analysis: collapse to property level
build_iqr <- function(bw) {
  d <- df_est %>% filter(abs(dist) <= bw, !is.na(property_id), property_id != "")
  # count workers per property
  prop_counts <- d %>% group_by(property_id) %>% summarise(n_workers = n())
  valid_props <- prop_counts$property_id[prop_counts$n_workers >= 5]
  d2 <- d %>% filter(property_id %in% valid_props)
  # IQR per property
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
  m <- feols(iqr ~ Above500 + dist + I(Above500*dist),
             data = pd, cluster = ~owner)
  list(coef = coef(m)["Above500"],
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