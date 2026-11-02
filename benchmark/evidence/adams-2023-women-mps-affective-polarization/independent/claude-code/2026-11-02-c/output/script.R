# Independent reproduction: Adams et al. (2023), Table 1
# OLS on directed party dyads, country-year FE, SEs clustered by election (country-year).
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-02-c/mount/adams_2023_women_mps_affective_polarization"

load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
g <- as.data.frame(readRDS(file.path(D, "gender_disagregated_8-8-21.rds")))

# Sample restriction. The paper restricts to parties with at least four MPs in the
# year before the survey. Requiring this of both parties (prior_seats) leaves far too
# few dyads; applying it to the evaluated out-party j (to_prior_seats >= 4, the 999
# code retained) reproduces the stated sample, so that is what is used here.
prep <- function(x) {
  x$election <- paste(x$country, x$year)
  x[x$to_prior_seats >= 4, ]
}
cat("Seat code 999 rows (dyadic):", sum(d$from_prior_seats >= 999 | d$to_prior_seats >= 999), "\n")
ds <- prep(d)
# DV: mean 0-10 thermometer (like) of party i's partisans toward out-party j
ds$therm <- ds$party_like

f1 <- therm ~ to_pfeml | election
f2 <- therm ~ to_pfeml + rile_distance_s + govern_together + opposition_together | election
m1 <- feols(f1, data = ds, cluster = ~election)
m2 <- feols(f2, data = ds, cluster = ~election)
print(etable(m1, m2))

# Gender-disaggregated: dislike is 0-10 reversed; convert to like = 10 - dislike
gs <- prep(g)
gs$therm <- 10 - gs$dislike
mw <- feols(f2, data = gs[gs$gender == 2, ], cluster = ~election)
mm <- feols(f2, data = gs[gs$gender == 1, ], cluster = ~election)
print(etable(mw, mm))

n_elec <- length(unique(ds$election[!is.na(ds$to_pfeml) & !is.na(ds$therm)]))
cat(sprintf("RESULT:women_mps_coef_bivariate=%.4f\n", coef(m1)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_full=%.4f\n", coef(m2)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.4f\n", coef(mw)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.4f\n", coef(mm)["to_pfeml"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.4f\n", coef(m2)["rile_distance_s"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.4f\n", coef(m2)["govern_together"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.4f\n", coef(m2)["opposition_together"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(mw)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(mm)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elec))
