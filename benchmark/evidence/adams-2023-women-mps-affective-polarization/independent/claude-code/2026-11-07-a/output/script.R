# Independent reproduction of Adams et al. (2023, APSR), Table 1.
# OLS on directed party dyads, country-election (cntryyr) fixed effects,
# SEs clustered by election (cntryyr).
set.seed(42)
suppressMessages(library(fixest))
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-07-a/mount/adams_2023_women_mps_affective_polarization"

load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
# Sample: parties with at least four MPs in the year before the survey.
# In the data, the filter that reproduces the paper's N is on the evaluated
# (to) party's prior seats; to_prior_seats == 999 (US) passes it.
d <- d[d$to_prior_seats >= 4, ]

# DV: mean 0-10 thermometer (party_like); regressor to_pfeml (0-1, t-1);
# controls: standardized CMP rile distance, coalition / opposition partners.
m1 <- feols(party_like ~ to_pfeml | cntryyr, data = d, cluster = ~cntryyr)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = d, cluster = ~cntryyr)

g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))
g <- g[g$to_prior_seats >= 4, ]
g$like <- 10 - g$dislike   # dislike is the reversed 0-10 thermometer
# gender: 1 = male, 2 = female (codebook)
m3 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = g[g$gender == 2, ], cluster = ~cntryyr)
m4 <- feols(like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr,
            data = g[g$gender == 1, ], cluster = ~cntryyr)

etable(m1, m2, m3, m4, fitstat = ~ n + ar2)

r <- function(name, v) cat(sprintf("RESULT:%s=%.6f\n", name, v))
r("women_mps_coef_bivariate", coef(m1)[["to_pfeml"]])
r("women_mps_coef_full", coef(m2)[["to_pfeml"]])
r("women_mps_coef_women_partisans", coef(m3)[["to_pfeml"]])
r("women_mps_coef_men_partisans", coef(m4)[["to_pfeml"]])
r("right_left_distance_coef_full", coef(m2)[["rile_distance_s"]])
r("coalition_partners_coef_full", coef(m2)[["prior_coalition"]])
r("opposition_partners_coef_full", coef(m2)[["prior_opposition"]])
r("n_directed_dyads", nobs(m2))
r("n_obs_women_partisans", nobs(m3))
r("n_obs_men_partisans", nobs(m4))
r("n_election_studies", length(unique(d$cntryyr[obs(m2)])))
