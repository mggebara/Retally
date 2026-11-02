#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(survival)
  library(sandwich)
  library(lmtest)
})

set.seed(42)

data_path <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting.script-free/SugarReplicate.dta"
df <- read_dta(data_path)

# Ensure vote is numeric
df$vote <- suppressWarnings(as.numeric(df$vote))

# Create a district identifier: state + district
df <- df %>% mutate(dist_id = paste(state, district, sep="_"))

covars <- c("sugcont", "ncu", "tenure", "poverty", "bach", "medincome", "over65", "agcom")

run_clogit <- function(data, strata_var, contrib_var = "sugcont") {
  needed <- c("vote", covars, strata_var)
  needed <- intersect(needed, names(data))
  d <- as.data.frame(data)
  d <- d[complete.cases(d[, needed]), ]
  d <- d[!is.na(d[["vote"]]), ]
  # Keep only strata with variation in vote
  tab <- tapply(d$vote, d[[strata_var]], function(x) length(unique(x)) > 1)
  keep_strata <- names(tab)[tab]
  d <- d[d[[strata_var]] %in% keep_strata, ]
  f <- as.formula(paste0("vote ~ ", contrib_var, 
                         " + ncu + tenure + poverty + bach + medincome + over65 + agcom + strata(", strata_var, ")"))
  clogit(f, data = d, method = "efron")
}

m_dist <- run_clogit(df, "dist_id", "sugcont")
coef_dist <- coef(m_dist)
cat("District FE coefs:\n"); print(coef_dist)
n_dist <- m_dist$n

inc_counts <- df %>% filter(!is.na(cid)) %>% group_by(cid) %>% summarise(n=n_distinct(cong))
both_incs <- inc_counts %>% filter(n >= 2) %>% pull(cid)
df_inc <- df %>% filter(cid %in% both_incs)

m_inc <- run_clogit(df_inc, "cid", "sugcont")
coef_inc <- coef(m_inc)
cat("Incumbent FE coefs:\n"); print(coef_inc)
n_inc <- m_inc$n

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