# Independent reproduction: Adams et al. (2023), Table 1
# OLS on directed party dyads, country-year FE, SEs clustered by election (country-year).
suppressPackageStartupMessages(library(fixest))
set.seed(42)
P <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-11-01-a/mount/adams_2023_women_mps_affective_polarization"

load(file.path(P, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)

# Sample: out-party j had at least four MPs in the year before the election
# (to_prior_seats; 999 = US two-party code, large parties, kept), and
# non-missing DV / lagged women-MP share.
prep <- function(x, dv) {
  x <- x[!is.na(x[[dv]]) & !is.na(x$to_pfeml) & !is.na(x$to_prior_seats) & x$to_prior_seats >= 4 &
           !is.na(x$rile_distance) & !is.na(x$prior_coalition) & !is.na(x$prior_opposition), ]
  x$y <- x[[dv]]
  # standardize the absolute CMP rile distance over the estimation cases
  x$rl_dist_std <- (x$rile_distance - mean(x$rile_distance)) / sd(x$rile_distance)
  x
}

m <- prep(d, "party_like")
cat("Main sample: n =", nrow(m), " elections =", length(unique(m$cntryyr)),
    " rile mean/sd =", round(mean(m$rile_distance), 2), round(sd(m$rile_distance), 2), "\n")

f1 <- feols(y ~ to_pfeml | cntryyr, data = m, cluster = ~cntryyr)
f2 <- feols(y ~ to_pfeml + rl_dist_std + prior_coalition + prior_opposition | cntryyr,
            data = m, cluster = ~cntryyr)

g <- readRDS(file.path(P, "gender_disagregated_8-8-21.rds"))
g$like_g <- 10 - g$dislike   # dislike is rescaled 0 = positive; convert back to 0-10 liking
gw <- prep(g[g$gender == 2, ], "like_g")  # 2 = female
gm <- prep(g[g$gender == 1, ], "like_g")  # 1 = male
f3 <- feols(y ~ to_pfeml + rl_dist_std + prior_coalition + prior_opposition | cntryyr,
            data = gw, cluster = ~cntryyr)
f4 <- feols(y ~ to_pfeml + rl_dist_std + prior_coalition + prior_opposition | cntryyr,
            data = gm, cluster = ~cntryyr)

etable(f1, f2, f3, f4, fitstat = ~ n + ar2)

cat(sprintf("RESULT:women_mps_coef_bivariate=%.4f\n", coef(f1)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_full=%.4f\n", coef(f2)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_women_partisans=%.4f\n", coef(f3)["to_pfeml"]))
cat(sprintf("RESULT:women_mps_coef_men_partisans=%.4f\n", coef(f4)["to_pfeml"]))
cat(sprintf("RESULT:right_left_distance_coef_full=%.4f\n", coef(f2)["rl_dist_std"]))
cat(sprintf("RESULT:coalition_partners_coef_full=%.4f\n", coef(f2)["prior_coalition"]))
cat(sprintf("RESULT:opposition_partners_coef_full=%.4f\n", coef(f2)["prior_opposition"]))
cat(sprintf("RESULT:n_directed_dyads=%d\n", nobs(f2)))
cat(sprintf("RESULT:n_obs_women_partisans=%d\n", nobs(f3)))
cat(sprintf("RESULT:n_obs_men_partisans=%d\n", nobs(f4)))
cat(sprintf("RESULT:n_election_studies=%d\n", length(unique(m$cntryyr))))
