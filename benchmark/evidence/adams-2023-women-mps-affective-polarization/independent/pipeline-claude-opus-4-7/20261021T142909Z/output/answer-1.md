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
# object: updated_data

df <- as.data.frame(updated_data)

# Inspect candidate variable names
# The DV is mean 0-10 thermometer evaluation of out-party j by partisans of i
# Likely variable: thermometer_score / like / mean_like
# Key regressor: lagged proportion women MPs of out-party (to_)
# Controls: standardized abs left-right distance, govern_together, opposition_together

cat("Columns:\n")
print(colnames(df))

# Try to find thermometer variable
dv_candidates <- c("thermometer_score","mean_therm","like","mean_like","therm","to_therm","out_therm")
dv <- intersect(dv_candidates, colnames(df))
cat("DV candidates found:", dv, "\n")

# Women MP share lagged - candidate names
wmp_candidates <- c("to_women_mp_share_lag","to_women_mp_lag","to_prop_women_lag",
                    "to_women_mps","to_prop_women","to_femaleprop","to_femshare",
                    "to_women_share","prop_women_to","women_mp_to","to_femmp",
                    "to_women_mp_prop","to_pct_women","to_femaleMPs")
wmp <- intersect(wmp_candidates, colnames(df))
cat("WMP candidates found:", wmp, "\n")

# Left-right distance
lr_candidates <- c("rile_dist","rile_distance","lr_dist","abs_rile_dist",
                   "elite_distance","elite_lr_dist","left_right_distance",
                   "rile_diff","abs_rile_diff","std_rile_dist")
lr <- intersect(lr_candidates, colnames(df))
cat("LR candidates found:", lr, "\n")

# Print to find them
grep("therm|like|dislike|rating|eval", colnames(df), value=TRUE, ignore.case=TRUE)
grep("women|female|femmp|fem_mp|wmp", colnames(df), value=TRUE, ignore.case=TRUE)
grep("rile|left|right|lr_|dist", colnames(df), value=TRUE, ignore.case=TRUE)

cat("\nAll column names:\n")
for (nm in colnames(df)) cat(nm, "\n")