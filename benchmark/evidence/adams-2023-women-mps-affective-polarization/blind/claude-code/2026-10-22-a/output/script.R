# Independent, blind reproduction of Adams et al. (2023, APSR), Table 1.
# OLS on directed party dyads, country-year (election) fixed effects,
# SEs clustered by election (country-year).
suppressPackageStartupMessages(library(fixest))
set.seed(42)

D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-10-22-a/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))            # -> updated_data
g <- as.data.frame(readRDS(file.path(D, "gender_disagregated_8-8-21.rds")))
d <- as.data.frame(updated_data)

# Sample: both parties held at least four seats before the election
# (999 is a missing-seat code used only for the two large US parties, which
# clearly exceed four seats, so it passes the >= 4 test).
keep <- function(x) x[!is.na(x$to_prior_seats) & !is.na(x$from_prior_seats) &
                      x$to_prior_seats >= 4 & x$from_prior_seats >= 4, ]
d <- keep(d)
g <- keep(g)

# Dependent variable: mean 0-10 thermometer (higher = warmer).
d$therm <- d$party_like
g$therm <- 10 - g$dislike      # gender file stores dislike = 10 - like

# Regressors:
#  to_pfeml          out-party j's proportion of women MPs, t-1 (0-1)
#  rile_distance_s   |CMP rile_i - rile_j| standardized (mean 22.4, SD 17.6)
#  prior_coalition   i, j governing partners at the time of the survey
#  prior_opposition  i, j both in opposition at the time of the survey
f1 <- therm ~ to_pfeml | cntryyr
f2 <- therm ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | cntryyr

m1 <- feols(f1, data = d, cluster = ~cntryyr)
m2 <- feols(f2, data = d, cluster = ~cntryyr)
m3 <- feols(f2, data = subset(g, gender == 2), cluster = ~cntryyr)  # women partisans
m4 <- feols(f2, data = subset(g, gender == 1), cluster = ~cntryyr)  # men partisans

etable(m1, m2, m3, m4, fitstat = ~ n + ar2)

n_cy <- length(unique(d$cntryyr[obs(m2)]))
if (n_cy == 0) n_cy <- length(unique(d$cntryyr[!is.na(d$to_pfeml)]))
cat(sprintf("Obs m1=%d m2=%d m3=%d m4=%d; election studies in m2=%d\n",
            nobs(m1), nobs(m2), nobs(m3), nobs(m4), n_cy))

cf <- function(m, v) unname(coef(m)[v])
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", cf(m1, "to_pfeml")))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", cf(m2, "to_pfeml")))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", cf(m3, "to_pfeml")))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", cf(m4, "to_pfeml")))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", cf(m2, "rile_distance_s")))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", cf(m2, "prior_coalition")))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", cf(m2, "prior_opposition")))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_cy))
