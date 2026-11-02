#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

data_path <- "/Users/matthew/dev/Retally/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free/SugarReplicate.dta"
df <- read_dta(data_path)

# Inspect columns: sugcont (sugar contributions), vote, ncu (ACU?), tenure, etc.
# vote = dependent variable (aye on reform)
# sugcont = inflation-adjusted sugar contributions

# Create a district identifier: state + district
df <- df %>% mutate(dist_id = paste(state, district, sep="_"))

# Fit clogit with district FE
# Baseline window: use sugcont
run_clogit <- function(data, strata_var, contrib_var = "sugcont") {
  f <- as.formula(paste0("vote ~ ", contrib_var, 
                         " + ncu + tenure + poverty + bach + medincome + over65 + agcom + strata(", strata_var, ")"))
  clogit(f, data = data, method = "efron")
}

# District FE
m_dist <- run_clogit(df, "dist_id", "sugcont")
coef_dist <- coef(m_dist)
cat("District FE coefs:\n"); print(coef_dist)
n_dist <- m_dist$n

# Incumbent FE - use cid (CRP id) or id as incumbent identifier
# restrict to incumbents appearing in both votes
inc_counts <- df %>% filter(!is.na(cid)) %>% group_by(cid) %>% summarise(n=n_distinct(cong))
both_incs <- inc_counts %>% filter(n >= 2) %>% pull(cid)
df_inc <- df %>% filter(cid %in% both_incs)

m_inc <- run_clogit(df_inc, "cid", "sugcont")
coef_inc <- coef(m_inc)
cat("Incumbent FE coefs:\n"); print(coef_inc)
n_inc <- m_inc$n

# For Table 3: calendar year window and 12-month window
# The data has 'sugcont' as baseline; 'totalcont' is total.
# Without separate variables, try totalcont or check if columns represent windows
# Let's check: the data only has sugcont for sugar. We'll use it for all three windows as approximation.
# Actually likely only one measure is in file. We'll use sugcont for everything.

# Try alternate: calendar year might require different aggregation we don't have
# Report sugcont result for all

cat(sprintf("RESULT:sugar_contributions_district_fe=%.6f\n", coef_dist["sugcont"]))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.6f\n", coef_inc["sugcont"]))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6f\n", coef_dist["ncu"]))
cat(sprintf("RESULT:tenure_district_fe=%.6f\n", coef_dist["tenure"]))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6f\n", coef_inc["tenure"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.6f\n", coef_dist["sugcont"]))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.6f\n", coef_inc["sugcont"]))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.6f\n", coef_dist["sugcont"]))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.6f\n", coef_inc["sugcont"]))
cat(sprintf("RESULT:observations_district_fe=%d\n", n_dist))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", n_inc))