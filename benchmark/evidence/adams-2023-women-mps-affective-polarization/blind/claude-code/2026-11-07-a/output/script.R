# Independent, blind reproduction of Adams et al. (2023), Table 1
# OLS on directed party dyads; country-year (election) FE; SEs clustered by election.
set.seed(42)
suppressPackageStartupMessages(library(fixest))

base <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/blind/2026-11-07-a/mount/adams_2023_women_mps_affective_polarization"

# ---- Dyadic data (all partisans) ----
load(file.path(base, "dyadic_data_1-4-22.Rdata"))   # -> updated_data
d <- as.data.frame(updated_data)

# Seat counts: 999 treated as a missing-value code
clean_seats <- function(x) ifelse(x >= 999, NA, x)
d$to_seats   <- clean_seats(d$to_prior_seats)
d$from_seats <- clean_seats(d$from_prior_seats)
cat("dyads with seat code 999 (from or to):",
    sum(d$to_prior_seats >= 999 | d$from_prior_seats >= 999, na.rm = TRUE), "\n")

# Sample: both parties with at least four MPs in the year before the survey
s <- subset(d, !is.na(to_seats) & !is.na(from_seats) & to_seats >= 4 & from_seats >= 4)
s$election <- s$cntryyr
cat("rows after >=4 MPs restriction:", nrow(s), "\n")

# DV: mean 0-10 thermometer (higher = warmer) that i's partisans give out-party j
m1 <- feols(party_like ~ to_pfeml | election, data = s, cluster = ~election)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | election,
            data = s, cluster = ~election)
print(summary(m1)); print(summary(m2))
cat("adj R2 m1 (within FE model, full):", r2(m1, "ar2"), " m2:", r2(m2, "ar2"), "\n")
cat("nobs m1:", nobs(m1), " nobs m2:", nobs(m2), "\n")

# Robustness diagnostic (not scored): concurrent governing-status dummies
m2b <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together | election,
             data = s, cluster = ~election)
cat("diagnostic, concurrent gov dummies, to_pfeml coef:", coef(m2b)["to_pfeml"], "\n")

# ---- Gender-disaggregated data ----
g <- readRDS(file.path(base, "gender_disagregated_8-8-21.rds"))
g <- as.data.frame(g)
g$to_seats   <- clean_seats(g$to_prior_seats)
g$from_seats <- clean_seats(g$from_prior_seats)
gs <- subset(g, !is.na(to_seats) & !is.na(from_seats) & to_seats >= 4 & from_seats >= 4)
gs$election <- gs$cntryyr
gs$like_g <- 10 - gs$dislike   # rescale dislike (0 = positive) back to 0-10 liking
# gender: 1 = male, 2 = female (codebook)
m3 <- feols(like_g ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | election,
            data = subset(gs, gender == 2), cluster = ~election)
m4 <- feols(like_g ~ to_pfeml + rile_distance_s + prior_coalition + prior_opposition | election,
            data = subset(gs, gender == 1), cluster = ~election)
print(summary(m3)); print(summary(m4))

n_elections <- length(unique(s$election[obs(m2)]))

cat(sprintf("RESULT:women_mps_coef_bivariate=%.6f\n", coef(m1)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_full=%.6f\n", coef(m2)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.6f\n", coef(m3)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.6f\n", coef(m4)["to_pfeml"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.6f\n", coef(m2)["rile_distance_s"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.6f\n", coef(m2)["prior_coalition"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.6f\n", coef(m2)["prior_opposition"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(m2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(m3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(m4)))
cat(sprintf("RESULT:n_election_studies=%d\n", n_elections))
