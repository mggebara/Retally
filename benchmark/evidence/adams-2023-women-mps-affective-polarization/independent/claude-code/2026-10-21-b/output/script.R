## Adams et al. (2023) Table 1 -- independent reproduction
suppressPackageStartupMessages(library(fixest))
set.seed(42)
D <- "<repo>/benchmark/.cache/claude-code/adams-2023-women-mps-affective-polarization/independent/2026-10-21-b/mount/adams_2023_women_mps_affective_polarization"
load(file.path(D, "dyadic_data_1-4-22.Rdata"))
d <- as.data.frame(updated_data)
g <- readRDS(file.path(D, "gender_disagregated_8-8-21.rds"))

## Sample: parties with at least four MPs in the year before the survey.
## In the data, the restriction that reproduces the paper's N is on the
## evaluated (to) party's prior seat count; dyads with missing to_pfeml drop.
d4 <- subset(d, to_prior_seats >= 4)
g4 <- subset(g, to_prior_seats >= 4)
g4$like_g <- 10 - g4$dislike          # gender-specific thermometer, 0 = dislike, 10 = like
if (!"cntryyr" %in% names(g4)) g4$cntryyr <- paste(g4$country, g4$year, sep = "_")

m1 <- feols(party_like ~ to_pfeml | cntryyr, data = d4, cluster = ~cntryyr)
m2 <- feols(party_like ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = d4, cluster = ~cntryyr)
m3 <- feols(like_g ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = subset(g4, gender == 2), cluster = ~cntryyr)
m4 <- feols(like_g ~ to_pfeml + rile_distance_s + govern_together + opposition_together | cntryyr,
            data = subset(g4, gender == 1), cluster = ~cntryyr)
etable(m1, m2, m3, m4)

n_elec <- length(unique(d4$cntryyr[obs(m2)]))
out <- c(
  women_mps_coef_bivariate      = unname(coef(m1)["to_pfeml"]),
  women_mps_coef_full           = unname(coef(m2)["to_pfeml"]),
  women_mps_coef_women_partisans = unname(coef(m3)["to_pfeml"]),
  women_mps_coef_men_partisans  = unname(coef(m4)["to_pfeml"]),
  right_left_distance_coef_full = unname(coef(m2)["rile_distance_s"]),
  coalition_partners_coef_full  = unname(coef(m2)["govern_together"]),
  opposition_partners_coef_full = unname(coef(m2)["opposition_together"]),
  n_directed_dyads              = nobs(m2),
  n_obs_women_partisans         = nobs(m3),
  n_obs_men_partisans           = nobs(m4),
  n_election_studies            = n_elec
)
for (k in names(out)) cat(sprintf("RESULT:%s=%.6g\n", k, out[[k]]))
