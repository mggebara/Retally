```r
suppressPackageStartupMessages({
  library(haven)
  library(survival)
  library(dplyr)
})

set.seed(42)

base_path <- "<repo>/.cache/datasets/grier_2023_sugar_roll_call_voting"

prep <- function(df) {
  df$yesvote <- ifelse(df$vote == "Aye", 1, 0)
  df$rsugcont <- ifelse(df$cong == 115, df$totalcont / 1.103, df$totalcont)
  df
}

# Use clogit (conditional logit) with id as the stratum to match Stata's logit with i.id FE
# For units that don't switch, clogit drops them automatically — matching the paper's identification

fit_clogit <- function(df) {
  clogit(yesvote ~ rsugcont + ncu + tenure + poverty + bach + medincome + over65 + agcom + strata(id),
         data = df, method = "efron")
}

# ---- Table 1 ----
d1 <- prep(read_dta(file.path(base_path, "SugarReplicate.dta")))

# District FE
m1_dist <- fit_clogit(d1)
# Incumbent FE: keep both==1
d1_inc <- d1 %>% filter(both == 1)
m1_inc <- fit_clogit(d1_inc)

# Observations: full sample size used in the Stata logit (not just switchers)
# Stata reports N as full sample fed to logit
n_dist <- nrow(d1)
n_inc <- nrow(d1_inc)

# ---- Table 3 Row 1 (calendar year) ----
d2 <- prep(read_dta(file.path(base_path, "SugarReplicate_iter1.dta")))
m2_dist <- fit_clogit(d2)
d2_inc <- d2 %>% filter(both == 1)
m2_inc <- fit_clogit(d2_inc)

# ---- Table 3 Row 2 (12 months before) ----
d3 <- prep(read_dta(file.path(base_path, "SugarReplicate_iter2.dta")))
m3_dist <- fit_clogit(d3)
d3_inc <- d3 %>% filter(both == 1)
m3_inc <- fit_clogit(d3_inc)

getc <- function(m, v) as.numeric(coef(m)[v])

cat(sprintf("RESULT:sugar_contributions_district_fe=%.6f\n", getc(m1_dist, "rsugcont")))
cat(sprintf("RESULT:sugar_contributions_incumbent_fe=%.6f\n", getc(m1_inc, "rsugcont")))
cat(sprintf("RESULT:acu_ideology_district_fe=%.6f\n", getc(m1_dist, "ncu")))
cat(sprintf("RESULT:tenure_district_fe=%.6f\n", getc(m1_dist, "tenure")))
cat(sprintf("RESULT:tenure_incumbent_fe=%.6f\n", getc(m1_inc, "tenure")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_district_fe=%.6f\n", getc(m2_dist, "rsugcont")))
cat(sprintf("RESULT:sugar_contributions_calendar_year_incumbent_fe=%.6f\n", getc(m2_inc, "rsugcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_district_fe=%.6f\n", getc(m3_dist, "rsugcont")))
cat(sprintf("RESULT:sugar_contributions_12_months_incumbent_fe=%.6f\n", getc(m3_inc, "rsugcont")))
cat(sprintf("RESULT:observations_district_fe=%d\n", m1_dist$n))
cat(sprintf("RESULT:observations_incumbent_fe=%d\n", m1_inc$n))
```