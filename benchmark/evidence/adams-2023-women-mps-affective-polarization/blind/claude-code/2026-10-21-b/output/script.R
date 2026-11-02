# Adams et al. (2023 APSR) Table 1 -- independent, blind reproduction.
# Directed party dyads; OLS with country-year (election) fixed effects,
# SEs clustered by election (country-year).
suppressPackageStartupMessages(library(fixest))
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-21-b/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))   # -> updated_data
d <- as.data.frame(updated_data)
g <- as.data.frame(readRDS(file.path(D, "gender_disagregated_8-8-21.rds")))

# Sample rule from the paper: both parties i and j had at least four MPs in the
# year before the election survey (prior lower-chamber seats >= 4).
keep_rule <- function(x) x$from_prior_seats >= 4 & x$to_prior_seats >= 4

# Dependent variable: mean 0-10 thermometer (higher = warmer) that i's partisans
# give out-party j.  Regressor: j's proportion of women MPs at t-1 (to_pfeml).
# Controls: standardized |left-right (CMP rile)| distance (rile_distance_s),
# coalition partners / opposition partners at the time of the survey
# (prior_coalition / prior_opposition, the variables the codebook lists as used).
d$evaluation <- d$party_like
ds <- d[keep_rule(d), ]

f_biv  <- evaluation ~ to_pfeml | cntryyr
f_full <- evaluation ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr

m1 <- feols(f_biv,  data = ds, cluster = ~cntryyr)
m2 <- feols(f_full, data = ds, cluster = ~cntryyr)

# Gender-disaggregated data: gender 1 = male, 2 = female; `dislike` is the
# reversed thermometer (0 = positive, 10 = negative), so evaluation = 10 - dislike.
g$evaluation <- 10 - g$dislike
gs <- g[keep_rule(g), ]
m3 <- feols(f_full, data = gs[gs$gender == 2, ], cluster = ~cntryyr)
m4 <- feols(f_full, data = gs[gs$gender == 1, ], cluster = ~cntryyr)

etable(m1, m2, m3, m4, se.below = TRUE)

est_sample <- ds[obs(m2), ]
n_elec <- length(unique(est_sample$cntryyr))

cat(sprintf("Bivariate N = %d; full N = %d\n", nobs(m1), nobs(m2)))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)[["to_pfeml"]]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)[["to_pfeml"]]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)[["to_pfeml"]]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)[["to_pfeml"]]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)[["rile_distance_s"]]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)[["prior_coalition"]]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)[["prior_opposition"]]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))
