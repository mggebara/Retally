#!/usr/bin/env Rscript

set.seed(42)

suppressPackageStartupMessages({
  library(fixest)
  library(dplyr)
  library(haven)
})

base <- "<repo>/.cache/datasets/adams_2023_women_mps_affective_polarization.script-free"

# Load dyadic data
load(file.path(base, "dyadic_data_1-4-22.Rdata"))
df <- as.data.frame(updated_data)

# DV: party_like (thermometer-style like rating of out-party)
# Key regressor: to_pfeml (proportion female MPs of target/out party)
# Controls: rile_distance_s (standardized abs left-right distance), govern_together, opposition_together

# Check available variables
needed <- c("party_like","to_pfeml","rile_distance_s","govern_together","opposition_together",
            "country","year","party_from","party_to","cntryyr")
cat("Missing:", setdiff(needed, colnames(df)), "\n")

# Drop missing
dsub <- df[complete.cases(df[, c("party_like","to_pfeml","rile_distance_s",
                                  "govern_together","opposition_together")]), ]

cat("N =", nrow(dsub), "\n")
cat("Mean party_like:", mean(dsub$party_like), "\n")
cat("Mean to_pfeml:", mean(dsub$to_pfeml), "\n")

# Baseline regression with country-year and dyad-type fixed effects, clustered SE
m1 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together,
            data = dsub, cluster = ~cntryyr)
print(summary(m1))

# With fixed effects for country-year and party dyad
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together
            | cntryyr, data = dsub, cluster = ~cntryyr)
print(summary(m2))

m3 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together
            | cntryyr + party_to, data = dsub, cluster = ~cntryyr)
print(summary(m3))

# Extract coefficients
b1_pfeml <- coef(m1)[["to_pfeml"]]
se1_pfeml <- se(m1)[["to_pfeml"]]
b1_rile <- coef(m1)[["rile_distance_s"]]
b1_gov <- coef(m1)[["govern_together"]]
b1_opp <- coef(m1)[["opposition_together"]]

b2_pfeml <- coef(m2)[["to_pfeml"]]
se2_pfeml <- se(m2)[["to_pfeml"]]

b3_pfeml <- coef(m3)[["to_pfeml"]]
se3_pfeml <- se(m3)[["to_pfeml"]]

cat(sprintf("RESULT:n_obs=%d\n", nrow(dsub)))
cat(sprintf("RESULT:ols_to_pfeml_coef=%.6f\n", b1_pfeml))
cat(sprintf("RESULT:ols_to_pfeml_se=%.6f\n", se1_pfeml))
cat(sprintf("RESULT:ols_rile_distance_s_coef=%.6f\n", b1_rile))
cat(sprintf("RESULT:ols_govern_together_coef=%.6f\n", b1_gov))
cat(sprintf("RESULT:ols_opposition_together_coef=%.6f\n", b1_opp))
cat(sprintf("RESULT:fe_cntryyr_to_pfeml_coef=%.6f\n", b2_pfeml))
cat(sprintf("RESULT:fe_cntryyr_to_pfeml_se=%.6f\n", se2_pfeml))
cat(sprintf("RESULT:fe_cntryyr_partyto_to_pfeml_coef=%.6f\n", b3_pfeml))
cat(sprintf("RESULT:fe_cntryyr_partyto_to_pfeml_se=%.6f\n", se3_pfeml))