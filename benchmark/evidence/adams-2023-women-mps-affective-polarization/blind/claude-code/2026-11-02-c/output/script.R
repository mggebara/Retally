# Adams et al. (2023 APSR) -- Table 1, independent blind reproduction
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-02-c/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))        # -> updated_data
g <- as.data.frame(readRDS(file.path(D, "gender_disagregated_8-8-21.rds")))
d <- as.data.frame(updated_data)

# Sample: directed dyads where both parties held >= 4 MPs in the year before the survey.
# (US parties carry a 999 placeholder seat count; they clearly have >= 4 MPs and are kept.)
keep <- function(x) subset(x, to_prior_seats >= 4 & from_prior_seats >= 4)
d <- keep(d)
g <- keep(g)

# DV: mean 0-10 thermometer (10 = like) from party i's partisans toward out-party j.
d$therm <- d$party_like
# gender file only has the "dislike" rescaling (0 = like, 10 = dislike); invert back to the thermometer
g$therm <- 10 - g$dislike

# Controls: rile_distance_s (CMP left-right distance, standardized; mean 22.4 / SD 17.6 on raw scale),
# govern_together (coalition partners), opposition_together (both in opposition); baseline = one gov, one opp.
# Country-year fixed effects; SEs clustered by election (country-year).
m1 <- feols(therm ~ to_pfeml | cntryyr, data = d, cluster = ~cntryyr)
m2 <- feols(therm ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = d, cluster = ~cntryyr)
m3 <- feols(therm ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = subset(g, gender == 2), cluster = ~cntryyr)
m4 <- feols(therm ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = subset(g, gender == 1), cluster = ~cntryyr)

etable(m1, m2, m3, m4, fitstat = ~ n + ar2)

n_cy <- length(unique(d$cntryyr[obs(m2)]))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["to_pfeml"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_distance_s"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["govern_together"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["opposition_together"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_cy))
